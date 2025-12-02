import OSLog
import StoreKit
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var quickDoseViewModel = QuickDoseViewModel()
    @State private var showingQuickDoseSheet = false
    @State private var showingTitrationDialog = false
    @State private var pendingTitration: DoseTitration?
    @State private var showingSuccessMessage = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var selectedTab = "home"
    @State private var pkEngine = PharmacokineticsEngine()
    @State private var doseService: DoseService

    // MARK: - Constants

    private enum SheetTransitionTiming {
        /// Delay required for SwiftUI sheet dismissal before presenting new sheet
        /// Prevents "already presenting" conflicts between titration dialog and quick dose sheet
        static let transitionDelay: TimeInterval = 0.3
    }

    private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "ContentView")

    init() {
        let pkEngine = PharmacokineticsEngine()
        self._pkEngine = State(wrappedValue: pkEngine)
        self._doseService = State(wrappedValue: DoseService(pkEngine: pkEngine))
    }

    var body: some View {
        TabView(selection: self.$selectedTab) {
            DashboardView(doseService: self.doseService)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag("home")

            // Empty view for Add tab - sheet presentation handled by onChange
            Color.clear
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag("add")

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag("history")

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag("analytics")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag("settings")
        }
        .accessibilityIdentifier("main-tab-view")
        .sheet(
            isPresented: self.$showingQuickDoseSheet,
            onDismiss: {
                // Clear pending titration state to avoid stale references
                self.pendingTitration = nil

                // Reset remind-later flag when quick dose sheet is dismissed
                if self.quickDoseViewModel.titrationRemindLater {
                    self.quickDoseViewModel.resetRemindLaterFlag()
                }
            },
            content: {
                QuickDoseSheet(
                    viewModel: self.quickDoseViewModel,
                    doseService: self.doseService,
                    showingSuccessMessage: self.$showingSuccessMessage)
            }
        )
        .sheet(
            isPresented: self.$showingTitrationDialog,
            content: {
                if let titration = pendingTitration {
                    TitrationConfirmationDialog(
                        titration: titration,
                        onComplete: handleTitrationComplete,
                        onReschedule: handleTitrationReschedule,
                        onRemindLater: handleTitrationRemindLater
                    )
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
                }
            }
        )
        .onChange(of: self.selectedTab) { oldValue, newValue in
            logger.debug("Tab changed from \(oldValue) to \(newValue)")
            if newValue == "add" {
                logger.debug("Add tab selected")

                // Check for pending titration using ViewModel business logic
                if quickDoseViewModel.shouldShowTitrationDialog() {
                    pendingTitration = quickDoseViewModel.getPendingTitration()
                    showingTitrationDialog = true
                } else {
                    showingQuickDoseSheet = true
                }

                // Reset tab selection to previous tab so + doesn't stay selected
                self.selectedTab = oldValue
                logger.debug("Reset tab selection back to \(oldValue)")
            }
        }
        .onAppear {
            self.quickDoseViewModel.loadSmartDefaults(context: self.modelContext)

            // Initialize app services with ModelContext
            AppServices.shared.initialize(with: self.modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showQuickDoseSheet)) { notification in
            // Handle deeplink navigation to QuickDoseSheet
            if let scheduledDoseId = notification.userInfo?["scheduledDoseId"] as? UUID {
                logger.info("Received deeplink notification to show QuickDoseSheet for dose: \(scheduledDoseId)")

                // Pre-populate QuickDoseViewModel with scheduled dose data
                quickDoseViewModel.prepareForScheduledDose(scheduledDoseId: scheduledDoseId, context: modelContext)

                // Show the QuickDoseSheet
                showingQuickDoseSheet = true
            }
        }
        .alert("Error", isPresented: self.$showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(self.errorMessage)
        }
        .overlay(alignment: .top) {
            if self.showingSuccessMessage {
                Text("Dose logged successfully!")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.9))
                    .cornerRadius(8)
                    .accessibilityIdentifier("dose-logged-success")
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onAppear {
                        // Auto-dismiss success message after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                self.showingSuccessMessage = false
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Titration Handlers (UI State Only - Business Logic in ViewModel)

    private func handleTitrationComplete() {
        guard let titration = pendingTitration else { return }

        // Business logic in ViewModel with explicit error handling
        do {
            try quickDoseViewModel.completeTitration(titration, context: modelContext)

            // Clear state and dismiss titration dialog first
            pendingTitration = nil
            showingTitrationDialog = false

            // Show quick dose sheet after dialog dismissal to avoid presentation conflict
            DispatchQueue.main.asyncAfter(deadline: .now() + SheetTransitionTiming.transitionDelay) {
                self.showingQuickDoseSheet = true
            }
        } catch {
            logger.error("Failed to complete titration: \(error.localizedDescription)")
            errorMessage = "Failed to complete titration: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }

    private func handleTitrationReschedule(_ newDate: Date) {
        guard let titration = pendingTitration else { return }

        // Business logic in ViewModel with explicit error handling
        do {
            try quickDoseViewModel.rescheduleTitration(titration, to: newDate, context: modelContext)

            // Clear state and dismiss dialog on success
            pendingTitration = nil
            showingTitrationDialog = false
        } catch {
            logger.error("Failed to reschedule titration: \(error.localizedDescription)")
            errorMessage = "Failed to reschedule titration: \(error.localizedDescription)"
            showingErrorAlert = true
        }
    }

    private func handleTitrationRemindLater() {
        // Set flag temporarily to allow correct flow
        quickDoseViewModel.setTitrationRemindLater(true)

        // Dismiss titration dialog first to avoid presentation conflict
        showingTitrationDialog = false

        // Show quick dose sheet after dialog dismissal
        // Note: remind-later flag will be reset in sheet's onDismiss callback
        DispatchQueue.main.asyncAfter(deadline: .now() + SheetTransitionTiming.transitionDelay) {
            self.showingQuickDoseSheet = true
        }
    }
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var pkEngine = PharmacokineticsEngine()
    let doseService: DoseService

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if let currentUser = users.first {
                        self.concentrationSection(for: currentUser)
                    } else {
                        self.noUserSection
                    }
                }
                .padding()
            }
            .accessibilityIdentifier("dashboard-scroll-view")
            .navigationTitle("Home")
        }
        .accessibilityIdentifier("dashboard-view")
    }

    // MARK: - Concentration Section

    @ViewBuilder
    private func concentrationSection(for user: User) -> some View {
        if let medicationProfiles = user.medicationProfiles,
            !medicationProfiles.isEmpty
        {
            ConcentrationList(
                user: user,
                medicationProfiles: medicationProfiles,
                pkEngine: self.pkEngine,
                doseService: self.doseService)
        } else {
            self.noMedicationSection
        }
    }

    // MARK: - Empty States

    private var noUserSection: some View {
        DesignCard {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("Set up your profile")
                    .font(DesignTokens.Typography.headline)

                Text("Complete onboarding to start tracking your medication concentrations")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .accessibilityIdentifier("no-user-message")
    }

    private var noMedicationSection: some View {
        DesignCard {
            VStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("Add medication profiles")
                    .font(DesignTokens.Typography.headline)

                Text("Set up your medications in Settings to view concentration tracking")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .accessibilityIdentifier("no-medication-message")
    }
}

// MARK: - ConcentrationList

struct ConcentrationList: View {
    let user: User
    let medicationProfiles: [MedicationProfile]
    let pkEngine: PharmacokineticsEngine
    let doseService: DoseService

    var body: some View {
        let sortedProfiles = self.medicationProfiles.sorted(by: { $0.startDate > $1.startDate })
        ForEach(Array(sortedProfiles.enumerated()), id: \.element.id) { _, profile in
            ConcentrationCard(
                user: self.user,
                medicationProfile: profile,
                pkEngine: self.pkEngine,
                doseService: self.doseService
            )
            .accessibilityIdentifier("concentration-card-\(profile.genericName)")
        }
    }
}

// HistoryView moved to JabTracker/Views/History/HistoryView.swift

// AnalyticsView moved to JabTracker/Views/Analytics/AnalyticsView.swift

// SettingsView moved to JabTracker/Views/Settings/SettingsView.swift

#Preview {
    ContentView()
        .modelContainer(DataController.preview.container)
}
