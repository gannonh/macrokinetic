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

    init() {
        self._chartDatasetService = State(wrappedValue: ChartDatasetService())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom page header (handles its own padding)
                PageHeader(title: "Shots")

                // Section picker (always visible, not scrolled)
                Picker("Section", selection: $selectedSection) {
                    ForEach(ShotsSection.allCases, id: \.self) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 8)
                .accessibilityIdentifier("shots-section-picker")

                // Sub-controls based on selected section
                sectionControls

                // Content - History gets full height, others get ScrollView
                if selectedSection == .history {
                    HistorySection(selectedMode: selectedHistoryMode)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            if isLoadingData {
                                ProgressView("Loading...")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                sectionContent
                            }
                        }
                        .padding()
                    }
                    .accessibilityIdentifier("shots-scroll-view")
                }
            }
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
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
            ConcentrationSection(
                user: currentUser,
                medicationProfiles: medicationProfiles,
                viewModel: viewModel,
                isLoadingData: isLoadingData
            )
        case .adherence:
            AdherenceSection(
                user: currentUser,
                medicationProfiles: medicationProfiles,
                viewModel: viewModel,
                modelContext: modelContext,
                analyticsService: analyticsService
            )
        case .history:
            // History is handled directly in body to avoid ScrollView nesting
            EmptyView()
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

}

#Preview {
    ShotsView()
        .modelContainer(DataController.preview.container)
}
