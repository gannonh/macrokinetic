//
//  DoseHistoryViewModel.swift
//  JabTracker
//

import Foundation
import SwiftData

/// View model for dose history list with filtering, search, and CRUD operations
/// Handles business logic for displaying and managing dose history data
@MainActor
class DoseHistoryViewModel: ObservableObject {
    // MARK: - Published Properties

    /// All doses fetched from SwiftData
    @Published var allDoses: [Dose] = [] {
        didSet {
            self.applyFiltersAndSearch()
        }
    }

    /// Filtered and sorted doses for display
    @Published var filteredDoses: [Dose] = []

    /// Current search text
    @Published var searchText: String = "" {
        didSet {
            self.applyFiltersAndSearch()
        }
    }

    /// Selected medication filter (nil means show all)
    @Published var selectedMedicationFilter: String? {
        didSet {
            self.applyFiltersAndSearch()
        }
    }

    /// Selected injection site filter (nil means show all)
    @Published var selectedInjectionSiteFilter: String? {
        didSet {
            self.applyFiltersAndSearch()
        }
    }

    /// Date range filter - start date
    @Published var filterStartDate: Date? {
        didSet {
            self.applyFiltersAndSearch()
        }
    }

    /// Date range filter - end date
    @Published var filterEndDate: Date? {
        didSet {
            self.applyFiltersAndSearch()
        }
    }

    /// Whether to show skipped doses
    @Published var showSkippedDoses: Bool = true {
        didSet {
            self.applyFiltersAndSearch()
        }
    }

    /// Loading state
    @Published var isLoading: Bool = false

    /// Error message for display
    @Published var errorMessage: String?

    /// Refresh indicator for pull-to-refresh
    @Published var isRefreshing: Bool = false

    // MARK: - Computed Properties

    /// Whether any filters are currently active
    var hasActiveFilters: Bool {
        !self.searchText.isEmpty ||
            self.selectedMedicationFilter != nil ||
            self.selectedInjectionSiteFilter != nil ||
            self.filterStartDate != nil ||
            self.filterEndDate != nil ||
            !self.showSkippedDoses
    }

    /// Available medications for filtering (extracted from dose data)
    var availableMedications: [String] {
        Array(Set(self.allDoses.compactMap { $0.medication?.genericName })).sorted()
    }

    /// Available injection sites for filtering (extracted from dose data)
    var availableInjectionSites: [String] {
        Array(Set(self.allDoses.compactMap(\.site))).sorted()
    }

    /// Grouped doses by date for section headers
    var groupedDoses: [(String, [Dose])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let grouped = Dictionary(grouping: filteredDoses) { dose in
            formatter.string(from: dose.timestamp)
        }

        return grouped.sorted { first, second in
            guard let firstDate = formatter.date(from: first.key),
                  let secondDate = formatter.date(from: second.key)
            else {
                return first.key > second.key
            }
            return firstDate > secondDate
        }.map { key, doses in
            (key, doses.sorted { $0.timestamp > $1.timestamp })
        }
    }

    /// Grouped doses by date using Date keys for calendar integration
    var groupedDosesByDate: [Date: [Dose]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredDoses) { dose in
            calendar.startOfDay(for: dose.timestamp)
        }
        return grouped
    }

    /// Get doses for a specific date (calendar integration)
    func doses(for date: Date) -> [Dose] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        return self.filteredDoses.filter { dose in
            calendar.isDate(dose.timestamp, inSameDayAs: startOfDay)
        }.sorted { $0.timestamp < $1.timestamp }
    }

    /// Get dose count for a specific date (calendar indicator support)
    func doseCount(for date: Date) -> Int {
        self.doses(for: date).count
    }

    // MARK: - Initialization

    init() {
        // Start with empty state - loadData() will be called from view
    }

    // MARK: - Data Loading

    /// Set doses from @Query for automatic reactivity
    func setDoses(_ doses: [Dose]) {
        self.allDoses = doses
        self.applyFiltersAndSearch()
    }

    /// Load dose data from SwiftData context (fallback method)
    func loadData(context: ModelContext) {
        Task { @MainActor in
            do {
                self.isLoading = true
                self.errorMessage = nil

                // Create fetch descriptor for all doses, sorted by timestamp descending
                let descriptor = FetchDescriptor<Dose>(
                    sortBy: [SortDescriptor(\Dose.timestamp, order: .reverse)]
                )

                // Fetch all doses
                self.allDoses = try context.fetch(descriptor)

                // Apply initial filters
                self.applyFiltersAndSearch()

                self.isLoading = false

            } catch {
                self.errorMessage = "Failed to load dose history: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    /// Refresh data with pull-to-refresh
    func refreshData(context: ModelContext) async {
        await MainActor.run {
            self.isRefreshing = true
        }

        // Add small delay to show refresh animation
        try? await Task.sleep(nanoseconds: 500_000_000)

        await MainActor.run {
            self.loadData(context: context)
            self.isRefreshing = false
        }
    }

    // MARK: - Filtering and Search

    /// Apply current filters and search to dose data
    private func applyFiltersAndSearch() {
        var filtered = self.allDoses

        // Apply search filter
        if !self.searchText.isEmpty {
            filtered = DoseSearchService.searchDoses(
                doses: filtered,
                searchText: self.searchText)
        }

        // Apply medication filter
        if let medicationFilter = selectedMedicationFilter {
            filtered = filtered.filter { dose in
                dose.medication?.genericName == medicationFilter
            }
        }

        // Apply injection site filter
        if let siteFilter = selectedInjectionSiteFilter {
            filtered = filtered.filter { dose in
                dose.site == siteFilter
            }
        }

        // Apply date range filter
        if let startDate = filterStartDate {
            let startOfDay = Calendar.current.startOfDay(for: startDate)
            filtered = filtered.filter { dose in
                dose.timestamp >= startOfDay
            }
        }

        if let endDate = filterEndDate {
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? endDate
            filtered = filtered.filter { dose in
                dose.timestamp < endOfDay
            }
        }

        // Apply skipped dose filter
        if !self.showSkippedDoses {
            filtered = filtered.filter { dose in
                !dose.skipped
            }
        }

        // Update filtered results
        self.filteredDoses = filtered.sorted { $0.timestamp > $1.timestamp }
    }

    /// Clear all active filters
    func clearAllFilters() {
        self.searchText = ""
        self.selectedMedicationFilter = nil
        self.selectedInjectionSiteFilter = nil
        self.filterStartDate = nil
        self.filterEndDate = nil
        self.showSkippedDoses = true
        // applyFiltersAndSearch() is called automatically via didSet
    }

    // MARK: - CRUD Operations

    /// Delete a dose with confirmation
    func deleteDose(_ dose: Dose, context: ModelContext) throws {
        context.delete(dose)
        try context.save()

        // Update local arrays
        if let index = allDoses.firstIndex(where: { $0.id == dose.id }) {
            self.allDoses.remove(at: index)
        }
        self.applyFiltersAndSearch()
    }

    /// Toggle skipped status of a dose
    func toggleSkippedStatus(for dose: Dose, context: ModelContext) throws {
        dose.skipped.toggle()
        try context.save()

        // Refresh filters to reflect changes
        self.applyFiltersAndSearch()
    }

    /// Duplicate a dose (create new dose with same data but current timestamp)
    func duplicateDose(_ dose: Dose, context: ModelContext) throws {
        #if DEBUG
            print("🔍 DoseHistoryViewModel.duplicateDose called!")
            print("🔍 Original dose - amount: [REDACTED], site: [REDACTED], notes: [REDACTED]")
        #endif

        let newDose = Dose(
            amount: dose.amount,
            timestamp: Date(), // Use current timestamp
            site: dose.site,
            notes: dose.notes,
            imageData: dose.imageData,
            skipped: false, // New dose should not be skipped
            user: dose.user,
            medication: dose.medication)

        #if DEBUG
            print("🔍 DoseHistoryViewModel: Creating duplicate dose with ID: \(newDose.id), site: [REDACTED]")
        #endif

        context.insert(newDose)
        #if DEBUG
            print("🔍 DoseHistoryViewModel: Inserted duplicate dose into context")
        #endif

        try context.save()
        #if DEBUG
            print("🔍 DoseHistoryViewModel: Saved duplicate dose to context")
        #endif

        // Add to local array and refresh
        self.allDoses.insert(newDose, at: 0) // Insert at beginning since it has current timestamp
        self.applyFiltersAndSearch()
    }

    /// Get dose for editing - returns dose data that can be used to pre-populate edit form
    func getDoseForEditing(_ dose: Dose) -> DoseEditData? {
        guard let medication = dose.medication else {
            return nil
        }

        return DoseEditData(
            id: dose.id,
            amount: dose.amount,
            timestamp: dose.timestamp,
            site: dose.site,
            notes: dose.notes,
            imageData: dose.imageData,
            skipped: dose.skipped,
            medicationProfile: medication)
    }

    /// Update a dose after editing
    func updateDose(
        _ dose: Dose,
        with editData: DoseEditData,
        context: ModelContext) throws
    {
        dose.amount = editData.amount
        dose.timestamp = editData.timestamp
        dose.site = editData.site
        dose.notes = editData.notes
        dose.imageData = editData.imageData
        dose.skipped = editData.skipped
        dose.medication = editData.medicationProfile

        try context.save()

        // Refresh data to reflect changes and re-sort if timestamp changed
        self.loadData(context: context)
    }
}

// MARK: - Error Types

enum DoseHistoryError: LocalizedError {
    case deleteFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case duplicateFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case let .deleteFailed(error):
            return "Failed to delete dose: \(error.localizedDescription)"
        case let .updateFailed(error):
            return "Failed to update dose: \(error.localizedDescription)"
        case let .duplicateFailed(error):
            return "Failed to duplicate dose: \(error.localizedDescription)"
        }
    }
}
