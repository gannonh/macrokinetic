import OSLog
import StoreKit
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @StateObject private var quickDoseViewModel = QuickDoseViewModel()
    @State private var showingQuickDoseSheet = false
    @State private var showingTitrationDialog = false
    @State private var pendingTitration: DoseTitration?
    @State private var showingSuccessMessage = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var selectedTab: Tab = .dashboard
    @State private var pkEngine = PharmacokineticsEngine()
    @State private var doseService: DoseService
    @State private var showingShortcuts = false
    @State private var activeShortcutSheet: ShortcutDestination?
    /// The currently selected date in FoodLogView, shared for tab bar + button
    @State private var selectedFoodLogDate = Date()
    /// Cached badge state - updated on scene activation and tab changes
    @State private var checkInBadgeVisible = false
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Constants

    private enum SheetTransitionTiming {
        /// Delay required for SwiftUI sheet dismissal before presenting new sheet
        /// Prevents "already presenting" conflicts between titration dialog and quick dose sheet
        static let transitionDelay: TimeInterval = 0.3
    }

    private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "ContentView")

    /// Update the cached check-in badge state
    /// Called on scene activation, tab changes, and check-in completion
    private func updateCheckInBadge() {
        guard let user = users.first,
            let goal = user.activeNutritionGoal,
            goal.program?.style != .manual
        else {
            checkInBadgeVisible = false
            return
        }
        let service = WeeklyCheckInService(context: modelContext)
        checkInBadgeVisible = service.isCheckInDue(for: goal)
    }

    init() {
        let pkEngine = PharmacokineticsEngine()
        self._pkEngine = State(wrappedValue: pkEngine)
        self._doseService = State(wrappedValue: DoseService(pkEngine: pkEngine))
    }

    var body: some View {
        TabView(selection: self.$selectedTab) {
            DashboardView(doseService: self.doseService)
                .tabItem {
                    Label(Tab.dashboard.title, systemImage: Tab.dashboard.icon)
                }
                .tag(Tab.dashboard)

            FoodLogView(selectedDate: $selectedFoodLogDate)
                .tabItem {
                    Label(Tab.foodLog.title, systemImage: Tab.foodLog.icon)
                }
                .tag(Tab.foodLog)

            // Spacer tab - visual icon hidden, replaced by floating button overlay
            Color.clear
                .tabItem {
                    Label {
                        Text("")
                    } icon: {
                        // Invisible placeholder - actual button is overlay
                        Color.clear
                    }
                }
                .tag(Tab.add)

            StrategyView()
                .tabItem {
                    Label(Tab.strategy.title, systemImage: Tab.strategy.icon)
                }
                .tag(Tab.strategy)
                .badge(checkInBadgeVisible ? "!" : nil)

            MoreView()
                .tabItem {
                    Label(Tab.more.title, systemImage: Tab.more.icon)
                }
                .tag(Tab.more)
        }
        .tint(DesignTokens.Colors.accent)
        .accessibilityIdentifier("main-tab-view")
        // Floating Add button overlay - larger icon, no tab animation
        .overlay(alignment: .bottom) {
            Button {
                logger.debug("Add button tapped via overlay")
                if quickDoseViewModel.shouldShowTitrationDialog() {
                    logger.debug("Pending titration found - showing titration dialog")
                    pendingTitration = quickDoseViewModel.getPendingTitration()
                    showingTitrationDialog = true
                } else {
                    logger.debug("No pending titration - showing shortcuts sheet")
                    showingShortcuts = true
                }
            } label: {
                Image(systemName: Tab.add.icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(DesignTokens.Colors.accent)
            }
            .accessibilityIdentifier("add-button")
            .offset(y: 8)
        }
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
            logger.debug("Tab changed from \(oldValue.rawValue) to \(newValue.rawValue)")
            if newValue == .add {
                logger.debug("Add tab selected")

                // Reset tab selection to previous tab so + doesn't stay selected
                self.selectedTab = oldValue
                logger.debug("Reset tab selection back to \(oldValue.rawValue)")

                // Check for pending titration first
                if quickDoseViewModel.shouldShowTitrationDialog() {
                    logger.debug("Pending titration found - showing titration dialog")
                    pendingTitration = quickDoseViewModel.getPendingTitration()
                    showingTitrationDialog = true
                } else {
                    // No pending titration - show shortcuts sheet
                    logger.debug("No pending titration - showing shortcuts sheet")
                    showingShortcuts = true
                }
            }
        }
        .sheet(isPresented: $showingShortcuts) {
            ShortcutsSheet(activeSheet: $activeShortcutSheet)
        }
        .sheet(item: $activeShortcutSheet) { destination in
            switch destination {
            case .foodSearch:
                foodSearchSheet()
            case .quickDose:
                QuickDoseSheet(
                    viewModel: quickDoseViewModel,
                    doseService: doseService,
                    showingSuccessMessage: $showingSuccessMessage
                )
            case .barcodeScan:
                foodSearchSheet(initialMethod: .scan)
            case .foodLibrary:
                foodSearchSheet(initialMethod: .library)
            case .quickAdd:
                foodSearchSheet(initialMethod: .quickAdd)
            case .quickWeight:
                QuickWeightSheet()
            case .quickMetrics:
                QuickMetricsSheet()
            case .quickPhoto:
                QuickPhotoSheet()
            }
        }
        .onAppear {
            self.quickDoseViewModel.loadSmartDefaults(context: self.modelContext)

            // Initialize app services with ModelContext
            AppServices.shared.initialize(with: self.modelContext)

            // Initial badge state
            updateCheckInBadge()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Refresh badge when app becomes active (e.g., after completing check-in)
            if newPhase == .active {
                updateCheckInBadge()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .checkInCompleted)) { _ in
            // Refresh badge immediately after check-in completion
            updateCheckInBadge()
        }
        .onChange(of: users) { _, _ in
            // Refresh badge when user data loads or changes
            updateCheckInBadge()
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

    // MARK: - Helpers

    @ViewBuilder
    private func foodSearchSheet(initialMethod: SearchMethod? = nil) -> some View {
        if let currentUser = users.first {
            FoodSearchSheet(
                user: currentUser,
                foodService: AppServices.shared.foodService,
                mealLogService: AppServices.shared.mealLogService,
                customFoodService: AppServices.shared.customFoodService,
                initialMethod: initialMethod,
                initialDate: selectedFoodLogDate
            ) {
                // On complete - could show success message
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

    init(doseService: DoseService) {
        self.doseService = doseService
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Custom page header (handles its own padding)
                    PageHeader(title: "Dashboard")

                    // Content with standard padding
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if let currentUser = users.first {
                            // Coming soon banner for early testers
                            self.comingSoonCard

                            self.concentrationSection(for: currentUser)

                            // Nutrition summary card
                            NutritionSummaryCard(
                                user: currentUser,
                                mealLogService: AppServices.shared.mealLogService
                            )
                        } else {
                            self.noUserSection
                        }
                    }
                    .padding()
                }
            }
            .accessibilityIdentifier("dashboard-scroll-view")
            .background(DesignTokens.Colors.groupedBackground)
            .toolbar(.hidden, for: .navigationBar)
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

    private var comingSoonCard: some View {
        DesignCard {
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)

                Text("Dashboard Coming Soon")
                    .font(DesignTokens.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .accessibilityIdentifier("coming-soon-card")
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
