import OSLog
import StoreKit
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var quickDoseViewModel = QuickDoseViewModel()
    @State private var showingQuickDoseSheet = false
    @State private var showingSuccessMessage = false
    @State private var selectedTab = "home"
    @State private var pkEngine = PharmacokineticsEngine()
    @State private var doseService: DoseService

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
            content: {
                QuickDoseSheet(
                    viewModel: self.quickDoseViewModel,
                    doseService: self.doseService,
                    showingSuccessMessage: self.$showingSuccessMessage)
            }
        )
        .onChange(of: self.selectedTab) { oldValue, newValue in
            print("🔍 ContentView: Tab changed from \(oldValue) to \(newValue)")
            if newValue == "add" {
                print("🔍 ContentView: Add tab selected, showing QuickDoseSheet")
                self.showingQuickDoseSheet = true
                // Reset tab selection to previous tab so + doesn't stay selected
                self.selectedTab = oldValue
                print("🔍 ContentView: Reset tab selection back to \(oldValue)")
            }
        }
        .onAppear {
            self.quickDoseViewModel.loadSmartDefaults(context: self.modelContext)
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
            .accessibilityIdentifier("dashboard-view")
        }
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
