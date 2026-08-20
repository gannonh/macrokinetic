//
//  GLP1ProgramsView.swift
//  JabTracker
//
//  Unified GLP-1 Programs landing page combining Analytics and Medications.
//

import OSLog
import SwiftData
import SwiftUI

struct GLP1ProgramsView: View {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "JabTracker",
        category: "GLP1ProgramsView")

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthenticationManager

    // Services (same pattern as ShotsView)
    @State private var viewModel = AnalyticsViewModel()
    @State private var doseDataService = DoseDataService()
    @State private var chartDataProcessor = ChartDataProcessor()
    @State private var analyticsService = AnalyticsService()
    @State private var chartDatasetService: ChartDatasetService

    // Section selection
    @State private var selectedSection: ProgramSection = .analytics
    @State private var selectedAnalyticsSection: ShotsSection = .concentration
    @State private var selectedTimePeriod: ChartDataProcessor.TimePeriod = .last30Days
    @State private var selectedHistoryMode: HistoryMode = .list

    // Data (manual fetch like ShotsView)
    @State private var currentUser: User?
    @State private var medicationProfiles: [MedicationProfile] = []
    @State private var isLoadingData = true

    /// Top-level section selection for GLP-1 Programs
    enum ProgramSection: String, CaseIterable {
        case analytics = "Analytics"
        case medications = "Medications"
    }

    /// Analytics sub-section selection (reuses ShotsView enum)
    enum ShotsSection: String, CaseIterable {
        case concentration = "Concentration"
        case adherence = "Adherence"
        case history = "History"
    }

    init() {
        self._chartDatasetService = State(wrappedValue: ChartDatasetService())
    }

    // State for adding medication
    @State private var showingAddMedication = false

    // State for medication management
    @State private var profileToDelete: MedicationProfile?
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            // Top-level section picker (Analytics | Medications)
            Picker("Section", selection: $selectedSection) {
                ForEach(ProgramSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 12)
            // Scoped to the picker (not the whole body) so it does not override
            // descendant accessibility identifiers such as dose-history-search.
            .accessibilityIdentifier("glp1-programs-view")

            // Content based on selected section
            switch selectedSection {
            case .analytics:
                analyticsContent
            case .medications:
                medicationsContent
            }
        }
        .background(DesignTokens.Colors.groupedBackground)
        .navigationTitle("GLP-1 Programs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if selectedSection == .medications {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        showingAddMedication = true
                    }
                    .accessibilityIdentifier("add-medication-button")
                }
            }
            if selectedSection == .analytics && selectedAnalyticsSection == .concentration {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Self.logger.info("🔄 Toolbar refresh button tapped - clearing cache")
                        viewModel.clearCache()
                        loadData()
                        forceRegenerateChartDataset()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh chart data")
                    .accessibilityIdentifier("toolbar-refresh-button")
                }
            }
        }
        .onAppear {
            loadData()
            if selectedSection == .analytics && selectedAnalyticsSection == .concentration {
                refreshChartDataset()
            }
        }
        .sheet(isPresented: $showingAddMedication) {
            // Use currentUser from loadData() for consistency with view state
            if let user = currentUser {
                AddMedicationProfileView(
                    medicationManager: MedicationManager(
                        modelContext: DataController.shared.container.mainContext
                    ),
                    currentUser: user
                )
            }
        }
        .onChange(of: showingAddMedication) { _, isShowing in
            if !isShowing {
                // Reload data when sheet is dismissed to reflect any new medication
                loadData()
            }
        }
    }

    // MARK: - Analytics Content

    @ViewBuilder
    private var analyticsContent: some View {
        // Sub-picker for analytics sections
        Picker("Analytics Section", selection: $selectedAnalyticsSection) {
            ForEach(ShotsSection.allCases, id: \.self) { section in
                Text(section.rawValue).tag(section)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .padding(.bottom, 8)
        .accessibilityIdentifier("analytics-section-picker")

        // Sub-controls based on selected analytics section
        analyticsControls

        // Content - History gets full height, others get ScrollView
        if selectedAnalyticsSection == .history {
            HistorySection(selectedMode: selectedHistoryMode)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if isLoadingData {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        analyticsSectionContent
                    }
                }
                .padding()
            }
            .accessibilityIdentifier("analytics-scroll-view")
        }
    }

    @ViewBuilder
    private var analyticsControls: some View {
        switch selectedAnalyticsSection {
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

    @ViewBuilder
    private var analyticsSectionContent: some View {
        switch selectedAnalyticsSection {
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
            // History is handled directly in analyticsContent to avoid ScrollView nesting
            EmptyView()
        }
    }

    // MARK: - Medications Content

    @ViewBuilder
    private var medicationsContent: some View {
        if medicationProfiles.isEmpty {
            // Empty state with add button
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "pills.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("No medication profiles yet")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(.secondary)

                Text("Add your first medication profile to get started with dose tracking and calculations.")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    showingAddMedication = true
                } label: {
                    Label("Add Medication", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
                .accessibilityIdentifier("add-medication-empty-button")

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Medication list
            List {
                Section("Your Medications") {
                    ForEach(medicationProfiles, id: \.id) { profile in
                        NavigationLink {
                            MedicationProfileDetailView(
                                profile: profile,
                                medicationManager: MedicationManager(
                                    modelContext: DataController.shared.container.mainContext
                                )
                            )
                        } label: {
                            MedicationProfileRowContent(profile: profile)
                        }
                        .accessibilityIdentifier(
                            "medication-profile-\(profile.medicationType.lowercased())-"
                                + "\(profile.brandName.lowercased())-"
                                + "\(String(format: "%.2f", profile.currentDose))mg"
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if profile.isActive {
                                Button("Disable") {
                                    disableProfile(profile)
                                }
                                .tint(.orange)
                                .accessibilityIdentifier("disable-medication-profile")

                                Button("Delete", role: .destructive) {
                                    profileToDelete = profile
                                    showingDeleteConfirmation = true
                                }
                                .accessibilityIdentifier("delete-medication-profile")
                            } else {
                                Button("Enable") {
                                    enableProfile(profile)
                                }
                                .tint(.green)
                                .accessibilityIdentifier("enable-medication-profile")

                                Button("Delete", role: .destructive) {
                                    profileToDelete = profile
                                    showingDeleteConfirmation = true
                                }
                                .accessibilityIdentifier("delete-medication-profile")
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog(
                "Delete Medication Profile?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible,
                presenting: profileToDelete
            ) { profile in
                Button("Disable Instead (Recommended)") {
                    disableProfile(profile)
                    profileToDelete = nil
                }
                .accessibilityIdentifier("disable-instead-button")

                Button("Delete Permanently", role: .destructive) {
                    deleteProfile(profile)
                    profileToDelete = nil
                }
                .accessibilityIdentifier("delete-permanently-button")

                Button("Cancel", role: .cancel) {
                    profileToDelete = nil
                }
                .accessibilityIdentifier("cancel-delete-button")
            } message: { profile in
                Text(
                    "Permanently deleting '\(profile.brandName)' will remove ALL data including "
                        + "historical doses and analytics. Disable instead to preserve your historical dose data."
                )
            }
        }
    }

    // MARK: - Medication Actions

    private func disableProfile(_ profile: MedicationProfile) {
        let manager = MedicationManager(modelContext: DataController.shared.container.mainContext)
        do {
            try manager.disableProfile(profile)
            loadData()
        } catch {
            errorMessage = "Failed to disable medication profile: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func enableProfile(_ profile: MedicationProfile) {
        let manager = MedicationManager(modelContext: DataController.shared.container.mainContext)
        do {
            try manager.enableProfile(profile)
            loadData()
        } catch {
            errorMessage = "Failed to enable medication profile: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func deleteProfile(_ profile: MedicationProfile) {
        let manager = MedicationManager(modelContext: DataController.shared.container.mainContext)
        do {
            try manager.deleteProfile(profile)
            loadData()
        } catch {
            errorMessage = "Failed to delete medication profile: \(error.localizedDescription)"
            showingError = true
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

        // Count total doses for staleness check
        var totalDoses = 0
        for profile in medicationProfiles {
            let doses = doseDataService.fetchDoses(for: profile, within: .all, context: modelContext)
            totalDoses += doses.count
        }
        Self.logger.info("📊 refreshChartDataset: Found \(totalDoses) total doses")

        if viewModel.loadFromCache(selectedPeriod: selectedTimePeriod, expectedDoseCount: totalDoses) {
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

    /// Force regenerate chart dataset (bypasses cache)
    /// Called when user taps refresh button to manually clear stale data
    private func forceRegenerateChartDataset() {
        guard let user = currentUser else { return }

        Self.logger.info("🔄 Force regenerating chart dataset (user requested)")

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
    NavigationStack {
        GLP1ProgramsView()
            .modelContainer(DataController.preview.container)
            .environmentObject(AuthenticationManager())
    }
}

// MARK: - Supporting Views

/// Extracted medication row content (without NavigationLink wrapper)
private struct MedicationProfileRowContent: View {
    let profile: MedicationProfile

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(profile.medicationType.capitalized) (\(profile.brandName))")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(profile.isActive ? .primary : .secondary)

                    if profile.isCompounded {
                        Text("Compounded")
                            .font(DesignTokens.Typography.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(DesignTokens.Colors.info.opacity(0.1))
                            .foregroundColor(DesignTokens.Colors.info)
                            .cornerRadius(4)
                    }

                    if !profile.isActive {
                        Text("Disabled")
                            .font(DesignTokens.Typography.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(DesignTokens.Colors.secondaryBackground)
                            .foregroundColor(.secondary)
                            .cornerRadius(4)
                    }
                }

                HStack {
                    Text("\(String(format: "%.2f", profile.currentDose)) mg")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(frequencyDisplay)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .opacity(profile.isActive ? 1.0 : 0.5)
    }

    private var frequencyDisplay: String {
        guard let medication = Medication(rawValue: profile.medicationType) else {
            return "Unknown"
        }

        switch medication.frequency {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        }
    }
}
