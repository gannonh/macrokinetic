//
//  ShotsView.swift
//  JabTracker
//
//  Combined medication analytics and dose history.
//

import OSLog
import SwiftData
import SwiftUI

struct ShotsView: View {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "JabTracker",
        category: "ShotsView")

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AnalyticsViewModel()
    @State private var doseDataService = DoseDataService()
    @State private var chartDataProcessor = ChartDataProcessor()
    @State private var analyticsService = AnalyticsService()
    @State private var chartDatasetService: ChartDatasetService
    @State private var selectedSection: ShotsSection = .concentration
    @State private var selectedTimePeriod: ChartDataProcessor.TimePeriod = .last30Days
    @State private var selectedHistoryMode: HistoryMode = .list

    // Manually fetched data (not @Query to avoid eager loading)
    @State private var currentUser: User?
    @State private var medicationProfiles: [MedicationProfile] = []
    @State private var isLoadingData = true

    enum ShotsSection: String, CaseIterable {
        case concentration = "Concentration"
        case adherence = "Adherence"
        case history = "History"
    }

    enum HistoryMode: String, CaseIterable {
        case list = "List"
        case calendar = "Calendar"

        var systemImage: String {
            switch self {
            case .list: return "list.bullet"
            case .calendar: return "calendar"
            }
        }
    }

    init() {
        self._chartDatasetService = State(wrappedValue: ChartDatasetService())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main section picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(ShotsSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .accessibilityIdentifier("shots-section-picker")

                // Sub-controls based on selected section
                sectionControls

                // Content based on selection
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if isLoadingData && selectedSection != .history {
                            ProgressView("Loading...")
                                .padding()
                        } else {
                            sectionContent
                        }
                    }
                    .padding()
                }
                .accessibilityIdentifier("shots-scroll-view")
            }
            .navigationTitle("Shots")
            .onAppear {
                loadData()
                if selectedSection == .concentration {
                    refreshChartDataset()
                }
            }
        }
        .accessibilityIdentifier("shots-view")
    }

    // MARK: - Section Controls

    @ViewBuilder
    private var sectionControls: some View {
        switch selectedSection {
        case .concentration:
            TimePeriodSelector(selectedPeriod: $selectedTimePeriod)
                .padding(.horizontal)
                .onChange(of: selectedTimePeriod) {
                    Task { @MainActor in
                        viewModel.chartDataset = nil
                        await Task.yield()
                        await viewModel.filterChartDatasetAsync(to: selectedTimePeriod)
                    }
                }
        case .adherence:
            EmptyView()
        case .history:
            Picker("View Mode", selection: $selectedHistoryMode) {
                ForEach(HistoryMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.systemImage)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .accessibilityIdentifier("history-view-mode-picker")
        }
    }

    // MARK: - Section Content

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .concentration:
            concentrationContent
        case .adherence:
            adherenceContent
        case .history:
            historyContent
        }
    }

    @ViewBuilder
    private var concentrationContent: some View {
        if currentUser != nil, !medicationProfiles.isEmpty {
            if let dataset = viewModel.chartDataset {
                ConcentrationTimelineChart(dataset: dataset)
            } else if isLoadingData {
                chartLoadingView()
            } else {
                noDataSection
            }
        } else {
            noDataSection
        }
    }

    @ViewBuilder
    private var adherenceContent: some View {
        if let user = currentUser, !medicationProfiles.isEmpty {
            VStack(spacing: 16) {
                AdherenceMetricsCard(adherenceRate: adherenceRate(for: user, context: modelContext))
                    .accessibilityIdentifier("adherence-metrics-card")

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

                AdherenceProgressIndicator(
                    currentAdherence: adherenceRate(for: user, context: modelContext),
                    targetAdherence: 0.8,
                    periodLabel: "This month"
                )

                AdherenceTrendChart(
                    trendData: viewModel.generateTrendData(
                        for: user,
                        profiles: medicationProfiles,
                        context: modelContext
                    ),
                    timePeriod: .weekly
                )

                MissedDosePatternView(
                    missedDoses: viewModel.generateMissedDosePatterns(
                        for: user,
                        profiles: medicationProfiles,
                        context: modelContext
                    ),
                    style: .calendar
                )
            }
        } else {
            noDataSection
        }
    }

    @ViewBuilder
    private var historyContent: some View {
        switch selectedHistoryMode {
        case .list:
            DoseHistoryView()
                .accessibilityIdentifier("dose-history-list")
        case .calendar:
            DoseCalendarView()
                .accessibilityIdentifier("dose-calendar-view")
        }
    }

    // MARK: - Data Loading

    private func loadData() {
        isLoadingData = true
        defer { isLoadingData = false }

        let userDescriptor = FetchDescriptor<User>()
        guard let user = try? modelContext.fetch(userDescriptor).first else {
            currentUser = nil
            medicationProfiles = []
            return
        }
        currentUser = user

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

    private func refreshChartDataset() {
        guard let user = currentUser else {
            viewModel.fullChartDataset = nil
            viewModel.chartDataset = nil
            return
        }

        if viewModel.loadFromCache(selectedPeriod: selectedTimePeriod) {
            return
        }

        viewModel.chartDataset = nil

        Task {
            await viewModel.refreshChartDataset(
                config: AnalyticsViewModel.RefreshConfig(
                    user: user,
                    profiles: medicationProfiles,
                    doseService: doseDataService,
                    chartService: chartDatasetService,
                    context: modelContext,
                    selectedPeriod: selectedTimePeriod
                )
            )
        }
    }

    private func adherenceRate(for user: User, context: ModelContext) -> Double {
        analyticsService.calculateOverallAdherence(user: user, context: context)
    }

    // MARK: - Empty States

    private var noDataSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Data Yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Start tracking doses to see your analytics")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
        .accessibilityIdentifier("no-shots-data")
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
}

#Preview {
    ShotsView()
        .modelContainer(DataController.preview.container)
}
