//
//  AnalyticsView.swift
//  JabTracker
//
//  Main analytics dashboard with concentration and adherence insights
//

import OSLog
import SwiftData
import SwiftUI

struct AnalyticsView: View {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "JabTracker",
        category: "AnalyticsView")

    @Environment(\.modelContext) private var modelContext
    @State private var doseDataService = DoseDataService()
    @State private var chartDataProcessor = ChartDataProcessor()
    @State private var analyticsService = AnalyticsService()
    @State private var chartDatasetService: ChartDatasetService
    @State private var selectedAnalyticsType: AnalyticsType = .concentration
    @State private var selectedTimePeriod: ChartDataProcessor.TimePeriod = .last30Days

    // Manually fetched data (not @Query to avoid eager loading)
    @State private var currentUser: User?
    @State private var medicationProfiles: [MedicationProfile] = []
    @State private var isLoadingData = true

    // Cached chart dataset (computed once, not during view rendering)
    @State private var chartDataset: ConcentrationChartDataset?

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

                // Time Period Selector (for concentration view)
                if selectedAnalyticsType == .concentration {
                    TimePeriodSelector(selectedPeriod: $selectedTimePeriod)
                        .padding(.horizontal)
                        .onChange(of: selectedTimePeriod) { _, _ in
                            // Regenerate chart dataset when time period changes
                            refreshChartDataset()
                        }
                }

                // Content based on selection
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if isLoadingData {
                            ProgressView("Loading analytics...")
                                .padding()
                        } else if let user = currentUser, !medicationProfiles.isEmpty {
                            switch selectedAnalyticsType {
                            case .concentration:
                                concentrationChartSection(for: user)
                            case .adherence:
                                adherenceInsightsSection(for: user)
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
            .onAppear {
                // Load data only on first appearance
                if currentUser == nil {
                    loadData()
                    refreshChartDataset()
                }
            }
        }
    }

    // MARK: - Data Loading

    /// Manually fetch user and medication profiles without eager-loading all doses
    private func loadData() {
        isLoadingData = true
        defer { isLoadingData = false }

        // Fetch user without relationships
        let userDescriptor = FetchDescriptor<User>()
        guard let user = try? modelContext.fetch(userDescriptor).first else {
            currentUser = nil
            medicationProfiles = []
            return
        }
        currentUser = user

        // Fetch medication profiles for this user (without doses relationship)
        let userId = user.id
        let profilePredicate = #Predicate<MedicationProfile> { profile in
            if let profileUser = profile.user {
                profileUser.id == userId
            } else {
                false
            }
        }
        let profileDescriptor = FetchDescriptor(predicate: profilePredicate)
        medicationProfiles = (try? modelContext.fetch(profileDescriptor)) ?? []
    }

    /// Regenerate chart dataset (called once on load and when time period changes)
    private func refreshChartDataset() {
        guard let user = currentUser else {
            chartDataset = nil
            return
        }

        // Show loading indicator immediately
        chartDataset = nil

        Self.logger.info("🔄 Refreshing chart for: \(String(describing: self.selectedTimePeriod), privacy: .public)")

        let refreshStartTime = Date()

        // Capture values needed for background processing
        let profiles = medicationProfiles
        let period = selectedTimePeriod
        let context = modelContext
        let doseService = doseDataService
        let chartService = chartDatasetService

        // Generate dataset on background thread
        Task.detached(priority: .userInitiated) {
            let doseFetchStart = Date()

            // Fetch doses on background thread
            var profilesWithDoses: [(MedicationProfile, [Dose])] = []

            for profile in profiles {
                let doses = await MainActor.run {
                    doseService.fetchDoses(for: profile, within: period, context: context)
                }
                guard !doses.isEmpty else { continue }
                profilesWithDoses.append((profile, doses))
            }

            let doseFetchEnd = Date()
            let doseFetchTime = doseFetchEnd.timeIntervalSince(doseFetchStart) * 1000
            let totalDoses = profilesWithDoses.reduce(0) { $0 + $1.1.count }

            Self.logger.info("  ⏱️  Dose fetching: \(String(format: "%.1f", doseFetchTime))ms (\(totalDoses) doses)")

            // Generate chart dataset (heavy computation)
            let chartGenStart = Date()
            let dataset = chartService.generateChartDataset(
                for: user,
                profilesWithDoses: profilesWithDoses,
                timePeriod: period
            )
            let chartGenEnd = Date()
            let chartGenTime = chartGenEnd.timeIntervalSince(chartGenStart) * 1000

            Self.logger.info("  ⏱️  Chart generation: \(String(format: "%.1f", chartGenTime))ms")

            // Update UI on main thread
            await MainActor.run {
                self.chartDataset = dataset

                let totalTime = Date().timeIntervalSince(refreshStartTime) * 1000
                Self.logger.info("  ⏱️  Total refresh: \(String(format: "%.1f", totalTime))ms")
                Self.logger.info(
                    "📊 Chart updated: \(dataset?.configuration.timeRange.displayName ?? "nil", privacy: .public)")
            }
        }
    }

    // MARK: - Chart Sections

    @ViewBuilder
    private func concentrationChartSection(for user: User) -> some View {
        // Use cached chart dataset (generated once, chart updates itself via onChange)
        if let dataset = chartDataset {
            ConcentrationTimelineChart(dataset: dataset)
        } else {
            chartLoadingView()
        }
    }

    @ViewBuilder
    private func adherenceInsightsSection(for user: User) -> some View {
        VStack(spacing: 16) {
            // Adherence Metrics Card
            AdherenceMetricsCard(adherenceRate: adherenceRate(for: user, context: modelContext))
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
                currentAdherence: adherenceRate(for: user, context: modelContext),
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

    private func adherenceRate(for user: User, context: ModelContext) -> Double {
        analyticsService.calculateOverallAdherence(user: user, context: context)
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

    /// Generates chart dataset using DoseDataService for efficient dose fetching
    /// Only fetches doses within the selected time period to avoid loading all data
    private func generateChartDataset(for user: User) -> ConcentrationChartDataset? {
        let startTime = Date()
        Self.logger.debug("📈 Generating chart dataset - profiles: \(self.medicationProfiles.count, privacy: .public)")

        // Build tuples of (profile, filteredDoses) without mutating SwiftData relationships
        var profilesWithDoses: [(MedicationProfile, [Dose])] = []

        for profile in medicationProfiles {
            // BEFORE fetch: Check profile.doses relationship state
            let beforeCount = profile.doses?.count ?? 0
            Self.logger.debug("  🔍 BEFORE fetch: profile.doses=\(beforeCount, privacy: .public)")

            // Fetch doses for this profile within the selected time period
            let doses = doseDataService.fetchDoses(
                for: profile,
                within: selectedTimePeriod,
                context: modelContext
            )

            // AFTER fetch: Check if relationship was affected
            let afterCount = profile.doses?.count ?? 0
            Self.logger.debug(
                "  🔍 AFTER fetch: profile.doses=\(afterCount, privacy: .public), fetched=\(doses.count, privacy: .public)"  // swiftlint:disable:this line_length
            )

            Self.logger.debug("  📦 \(profile.genericName, privacy: .public): \(doses.count, privacy: .public) doses")

            // Skip profiles with no doses in the selected period
            guard !doses.isEmpty else { continue }

            // Create tuple WITHOUT mutating profile.doses relationship
            // This prevents SwiftData from tracking unwanted relationship changes
            profilesWithDoses.append((profile, doses))

            // AFTER tuple creation: Verify relationship still intact
            let tupleCount = profile.doses?.count ?? 0
            Self.logger.debug(
                "  🔍 AFTER tuple: profile.doses=\(tupleCount, privacy: .public), tuple=\(doses.count, privacy: .public)"
            )
        }

        let fetchTime = Date().timeIntervalSince(startTime) * 1000
        Self.logger.info("  ⏱️  Dose fetching: \(String(format: "%.1f", fetchTime), privacy: .public)ms")
        Self.logger.debug("  ✅ Profiles with doses: \(profilesWithDoses.count, privacy: .public)")

        guard !profilesWithDoses.isEmpty else { return nil }

        // Generate chart dataset using tuple-based method (no relationship mutation)
        let datasetStartTime = Date()
        let dataset = chartDatasetService.generateChartDataset(
            for: user,
            profilesWithDoses: profilesWithDoses,
            timePeriod: selectedTimePeriod
        )
        let datasetTime = Date().timeIntervalSince(datasetStartTime) * 1000
        Self.logger.info("  ⏱️  Dataset generation: \(String(format: "%.1f", datasetTime), privacy: .public)ms")

        let totalTime = Date().timeIntervalSince(startTime) * 1000
        Self.logger.info("  ⏱️  Total: \(String(format: "%.1f", totalTime), privacy: .public)ms")

        return dataset
    }
}
