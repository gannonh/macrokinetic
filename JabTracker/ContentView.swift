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
            DashboardView()
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
        .sheet(isPresented: self.$showingQuickDoseSheet, content: {
            QuickDoseSheet(
                viewModel: self.quickDoseViewModel,
                doseService: self.doseService,
                showingSuccessMessage: self.$showingSuccessMessage)
        })
        .onChange(of: self.selectedTab) { oldValue, newValue in
            if newValue == "add" {
                self.showingQuickDoseSheet = true
                // Reset tab selection to previous tab so + doesn't stay selected
                self.selectedTab = oldValue
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

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if let currentUser = users.first {
                        concentrationSection(for: currentUser)
                    } else {
                        noUserSection
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .accessibilityIdentifier("dashboard-view")
        }
    }

    // MARK: - Concentration Section

    @ViewBuilder
    private func concentrationSection(for user: User) -> some View {
        if let medicationProfiles = user.medicationProfiles,
           !medicationProfiles.isEmpty {
            ConcentrationList(
                user: user,
                medicationProfiles: medicationProfiles,
                pkEngine: pkEngine
            )
        } else {
            noMedicationSection
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

    var body: some View {
        // Temporarily commented out due to SwiftUI ForEach compilation issue
        // TODO: Fix ForEach binding confusion in ContentView
        Text("Concentration cards temporarily disabled due to SwiftUI compilation issue")
            .foregroundColor(.secondary)
        // let sortedProfiles = medicationProfiles.sorted(by: { $0.startDate > $1.startDate })
        // ForEach(sortedProfiles, id: \.id) { profile in
        //     ConcentrationCard(
        //         user: user,
        //         medicationProfile: profile,
        //         pkEngine: pkEngine
        //     )
        //     .accessibilityIdentifier("concentration-card-\(profile.medicationName)")
        // }
    }
}

// HistoryView moved to JabTracker/Views/History/HistoryView.swift

struct AnalyticsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Analytics")
                    .font(.largeTitle)
                    .bold()
                Text("Concentration levels and insights")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Analytics")
        }
    }
}

// SettingsView moved to JabTracker/Views/Settings/SettingsView.swift

#Preview {
    ContentView()
        .modelContainer(DataController.preview.container)
}
