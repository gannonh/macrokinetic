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
            applyFiltersAndSearch()
        }
    }
    
    /// Filtered and sorted doses for display
    @Published var filteredDoses: [Dose] = []
    
    /// Current search text
    @Published var searchText: String = "" {
        didSet {
            applyFiltersAndSearch()
        }
    }
    
    /// Selected medication filter (nil means show all)
    @Published var selectedMedicationFilter: String? {
        didSet {
            applyFiltersAndSearch()
        }
    }
    
    /// Selected injection site filter (nil means show all)
    @Published var selectedInjectionSiteFilter: String? {
        didSet {
            applyFiltersAndSearch()
        }
    }
    
    /// Date range filter - start date
    @Published var filterStartDate: Date? {
        didSet {
            applyFiltersAndSearch()
        }
    }
    
    /// Date range filter - end date
    @Published var filterEndDate: Date? {
        didSet {
            applyFiltersAndSearch()
        }
    }
    
    /// Whether to show skipped doses
    @Published var showSkippedDoses: Bool = true {
        didSet {
            applyFiltersAndSearch()
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
        !searchText.isEmpty ||
        selectedMedicationFilter != nil ||
        selectedInjectionSiteFilter != nil ||
        filterStartDate != nil ||
        filterEndDate != nil ||
        !showSkippedDoses
    }
    
    /// Available medications for filtering (extracted from dose data)
    var availableMedications: [String] {
        Array(Set(allDoses.compactMap { $0.medication?.genericName })).sorted()
    }
    
    /// Available injection sites for filtering (extracted from dose data)
    var availableInjectionSites: [String] {
        Array(Set(allDoses.compactMap { $0.site })).sorted()
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
                  let secondDate = formatter.date(from: second.key) else {
                return first.key > second.key
            }
            return firstDate > secondDate
        }.map { (key, doses) in
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

        return filteredDoses.filter { dose in
            calendar.isDate(dose.timestamp, inSameDayAs: startOfDay)
        }.sorted { $0.timestamp < $1.timestamp }
    }

    /// Get dose count for a specific date (calendar indicator support)
    func doseCount(for date: Date) -> Int {
        return doses(for: date).count
    }
    
    // MARK: - Initialization
    
    init() {
        // Start with empty state - loadData() will be called from view
    }
    
    // MARK: - Data Loading

    /// Set doses from @Query for automatic reactivity
    func setDoses(_ doses: [Dose]) {
        self.allDoses = doses
        applyFiltersAndSearch()
    }

    /// Load dose data from SwiftData context (fallback method)
    func loadData(context: ModelContext) {
        Task { @MainActor in
            do {
                isLoading = true
                errorMessage = nil

                // Create fetch descriptor for all doses, sorted by timestamp descending
                let descriptor = FetchDescriptor<Dose>(
                    sortBy: [SortDescriptor(\Dose.timestamp, order: .reverse)]
                )

                // Fetch all doses
                allDoses = try context.fetch(descriptor)

                // Apply initial filters
                applyFiltersAndSearch()

                isLoading = false

            } catch {
                errorMessage = "Failed to load dose history: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    /// Refresh data with pull-to-refresh
    func refreshData(context: ModelContext) async {
        await MainActor.run {
            isRefreshing = true
        }
        
        // Add small delay to show refresh animation
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        await MainActor.run {
            loadData(context: context)
            isRefreshing = false
        }
    }
    
    // MARK: - Filtering and Search
    
    /// Apply current filters and search to dose data
    private func applyFiltersAndSearch() {
        var filtered = allDoses
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = DoseSearchService.searchDoses(
                doses: filtered,
                searchText: searchText
            )
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
        if !showSkippedDoses {
            filtered = filtered.filter { dose in
                !dose.skipped
            }
        }
        
        // Update filtered results
        filteredDoses = filtered.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Clear all active filters
    func clearAllFilters() {
        searchText = ""
        selectedMedicationFilter = nil
        selectedInjectionSiteFilter = nil
        filterStartDate = nil
        filterEndDate = nil
        showSkippedDoses = true
        // applyFiltersAndSearch() is called automatically via didSet
    }
    
    // MARK: - CRUD Operations
    
    /// Delete a dose with confirmation
    func deleteDose(_ dose: Dose, context: ModelContext) throws {
        context.delete(dose)
        try context.save()
        
        // Update local arrays
        if let index = allDoses.firstIndex(where: { $0.id == dose.id }) {
            allDoses.remove(at: index)
        }
        applyFiltersAndSearch()
    }
    
    /// Toggle skipped status of a dose
    func toggleSkippedStatus(for dose: Dose, context: ModelContext) throws {
        dose.skipped.toggle()
        try context.save()
        
        // Refresh filters to reflect changes
        applyFiltersAndSearch()
    }
    
    /// Duplicate a dose (create new dose with same data but current timestamp)
    func duplicateDose(_ dose: Dose, context: ModelContext) throws {
        let newDose = Dose(
            amount: dose.amount,
            timestamp: Date(), // Use current timestamp
            site: dose.site,
            notes: dose.notes,
            imageData: dose.imageData,
            skipped: false, // New dose should not be skipped
            user: dose.user,
            medication: dose.medication
        )
        
        context.insert(newDose)
        try context.save()
        
        // Add to local array and refresh
        allDoses.insert(newDose, at: 0) // Insert at beginning since it has current timestamp
        applyFiltersAndSearch()
    }
    
    /// Get dose for editing - returns dose data that can be used to pre-populate edit form
    func getDoseForEditing(_ dose: Dose) -> DoseEditData {
        DoseEditData(
            id: dose.id,
            amount: dose.amount,
            timestamp: dose.timestamp,
            site: dose.site,
            notes: dose.notes,
            imageData: dose.imageData,
            skipped: dose.skipped,
            medicationProfile: dose.medication
        )
    }
    
    /// Update a dose after editing
    func updateDose(
        _ dose: Dose,
        with editData: DoseEditData,
        context: ModelContext
    ) throws {
        dose.amount = editData.amount
        dose.timestamp = editData.timestamp
        dose.site = editData.site
        dose.notes = editData.notes
        dose.imageData = editData.imageData
        dose.skipped = editData.skipped
        dose.medication = editData.medicationProfile
        
        try context.save()
        
        // Refresh data to reflect changes and re-sort if timestamp changed
        loadData(context: context)
    }
}

// MARK: - Supporting Types

/// Data structure for passing dose edit information
struct DoseEditData: Identifiable {
    let id: UUID
    var amount: Double
    var timestamp: Date
    var site: String?
    var notes: String?
    var imageData: Data?
    var skipped: Bool
    var medicationProfile: MedicationProfile?
}

// MARK: - Error Types

enum DoseHistoryError: LocalizedError {
    case deleteFailed(underlying: Error)
    case updateFailed(underlying: Error)
    case duplicateFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .deleteFailed(let error):
            return "Failed to delete dose: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update dose: \(error.localizedDescription)"
        case .duplicateFailed(let error):
            return "Failed to duplicate dose: \(error.localizedDescription)"
        }
    }
}
