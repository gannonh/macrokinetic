// swiftlint:disable file_length
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

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var chartDataProcessor = ChartDataProcessor()
    @State private var analyticsService = AnalyticsService()
    @State private var chartDatasetService: ChartDatasetService
    @State private var selectedAnalyticsType: AnalyticsType = .concentration

    enum AnalyticsType: String, CaseIterable {
        case concentration = "Concentration"
        case adherence = "Adherence"
    }

    init() {
        self._chartDatasetService = State(wrappedValue: ChartDatasetService())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Analytics Type", selection: $selectedAnalyticsType) {
                    ForEach(AnalyticsType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .accessibilityIdentifier("analytics-type-picker")

                // Content based on selection
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if let currentUser = users.first,
                            let medicationProfiles = currentUser.medicationProfiles,
                            !medicationProfiles.isEmpty
                        {
                            switch selectedAnalyticsType {
                            case .concentration:
                                concentrationChartSection(for: currentUser, profiles: medicationProfiles)
                            case .adherence:
                                adherenceInsightsSection(for: currentUser)
                            }
                        } else {
                            noDataSection
                        }
                    }
                    .padding()
                }
                .accessibilityIdentifier("analytics-scroll-view")
            }
            .navigationTitle("Analytics")
        }
    }

    // MARK: - Chart Sections

    @ViewBuilder
    private func concentrationChartSection(for user: User, profiles: [MedicationProfile]) -> some View {
        VStack(spacing: 16) {
            // Generate chart dataset from user data
            if let chartDataset = generateChartDataset(for: user, profiles: profiles) {
                ConcentrationTimelineChart(dataset: chartDataset)
            } else {
                chartLoadingView()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }

    @ViewBuilder
    private func adherenceInsightsSection(for user: User) -> some View {
        VStack(spacing: 16) {
            // Adherence Metrics Card
            AdherenceMetricsCard(adherenceRate: adherenceRate(for: user))
                .accessibilityIdentifier("adherence-metrics-card")

            // Streak Counters Card
            DesignCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Dose Streaks")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(.primary)

                    StreakCounterView(
                        currentStreak: user.currentStreak,
                        bestStreak: user.longestStreak
                    )
                }
            }
            .accessibilityIdentifier("streak-counters-card")

            // Adherence Progress Indicator
            AdherenceProgressIndicator(
                currentAdherence: adherenceRate(for: user),
                targetAdherence: 0.8,
                periodLabel: "This month"
            )

            // Adherence Trend Chart
            AdherenceTrendChart(
                trendData: generateTrendData(for: user),
                timePeriod: .weekly
            )

            // Missed Dose Pattern Visualization
            MissedDosePatternView(
                missedDoses: generateMissedDosePatterns(for: user),
                style: .calendar
            )
        }
    }

    private func adherenceRate(for user: User) -> Double {
        let context = ModelContext(DataController.shared.container)
        return analyticsService.calculateOverallAdherence(user: user, context: context)
    }

    private func generateTrendData(for user: User) -> [AdherenceTrendPoint] {
        // Generate sample trend data for the last 4 weeks
        let calendar = Calendar.current
        let now = Date()
        var trendData: [AdherenceTrendPoint] = []

        for weekOffset in 0..<4 {
            if let weekDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) {
                let adherenceRate = Double.random(in: 0.6...0.95)
                trendData.append(
                    AdherenceTrendPoint(
                        date: weekDate,
                        adherenceRate: adherenceRate,
                        period: "Week \(4 - weekOffset)"
                    ))
            }
        }

        return trendData.sorted { $0.date < $1.date }
    }

    private func generateMissedDosePatterns(for user: User) -> [MissedDosePattern] {
        // Generate sample missed dose patterns
        let calendar = Calendar.current
        let now = Date()

        return [
            MissedDosePattern(
                date: calendar.date(byAdding: .day, value: -6, to: now) ?? now,
                dayOfWeek: "Saturday",
                missedCount: 2
            ),
            MissedDosePattern(
                date: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                dayOfWeek: "Sunday",
                missedCount: 3
            ),
        ]
    }

    // MARK: - Empty States

    private var noDataSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Analytics Data")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                Text("Start tracking doses to see your concentration timeline")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text("Analytics will show medication concentration levels over time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
        .accessibilityIdentifier("no-analytics-data")
    }

    @ViewBuilder
    private func chartLoadingView() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Generating Concentration Chart...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
        .accessibilityIdentifier("chart-loading")
    }

    // MARK: - Data Generation

    /// Generates chart dataset from user medication data
    /// Delegates to ChartDatasetService for safe handling of multiple profiles
    private func generateChartDataset(for user: User, profiles: [MedicationProfile])
        -> ConcentrationChartDataset?
    {
        chartDatasetService.generateChartDataset(for: user, profiles: profiles)
    }
}

// SettingsView moved to JabTracker/Views/Settings/SettingsView.swift

#Preview {
    ContentView()
        .modelContainer(DataController.preview.container)
}
