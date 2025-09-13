//
//  DoseHistoryViewModelUnitTests.swift
//  JabTrackerTests
//
//  Unit tests for DoseHistoryViewModel implementation
//  Tests the actual ViewModel business logic and state management
//

import Testing
import Foundation
import SwiftData
@testable import JabTracker

@MainActor
struct DoseHistoryViewModelUnitTests {
    
    // Create an in-memory model container for testing without CloudKit
    private var modelContainer: ModelContainer {
        let schema = Schema([
            User.self,
            Dose.self,
            MedicationProfile.self,
            DoseTitration.self
        ])
        
        // Check if we're in test environment (should always be true here)
        let isTestEnvironment = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
            ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil
        
        // Disable CloudKit for testing - same logic as DataController
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: isTestEnvironment ? .none : .none // Always none for tests
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Initialization Tests
    
    @Test("ViewModel initializes with correct default state")
    func testViewModelInitialization() throws {
        // When: Creating new view model
        let viewModel = DoseHistoryViewModel()
        
        // Then: Default state is correct
        #expect(viewModel.allDoses.isEmpty)
        #expect(viewModel.filteredDoses.isEmpty)
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.selectedMedicationFilter == nil)
        #expect(viewModel.selectedInjectionSiteFilter == nil)
        #expect(viewModel.filterStartDate == nil)
        #expect(viewModel.filterEndDate == nil)
        #expect(viewModel.showSkippedDoses == true)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isRefreshing == false)
    }
    
    // MARK: - Computed Properties Tests
    
    @Test("hasActiveFilters computed property works correctly")
    func testHasActiveFilters() throws {
        // Given: Fresh view model
        let viewModel = DoseHistoryViewModel()
        
        // Then: No active filters initially
        #expect(viewModel.hasActiveFilters == false)
        
        // When: Setting search text
        viewModel.searchText = "test"
        
        // Then: Has active filters
        #expect(viewModel.hasActiveFilters == true)
        
        // When: Clearing search but setting medication filter
        viewModel.searchText = ""
        viewModel.selectedMedicationFilter = "Semaglutide"
        
        // Then: Still has active filters
        #expect(viewModel.hasActiveFilters == true)
        
        // When: Setting showSkippedDoses to false
        viewModel.selectedMedicationFilter = nil
        viewModel.showSkippedDoses = false
        
        // Then: Still has active filters
        #expect(viewModel.hasActiveFilters == true)
    }
    
    @Test("availableMedications computed property extracts unique medications")
    func testAvailableMedications() throws {
        // Given: ViewModel with test data and model context
        let container = modelContainer
        let context = container.mainContext
        let viewModel = DoseHistoryViewModel()
        
        // Create medication profiles in the context
        let semaProfile = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic"
        )
        context.insert(semaProfile)
        
        let tirzeProfile = MedicationProfile(
            genericName: "Tirzepatide",
            brandName: "Mounjaro"
        )
        context.insert(tirzeProfile)
        
        // Create doses in the context
        let dose1 = Dose(amount: 1.0)
        dose1.medication = semaProfile
        context.insert(dose1)
        
        let dose2 = Dose(amount: 1.5)
        dose2.medication = semaProfile // Duplicate
        context.insert(dose2)
        
        let dose3 = Dose(amount: 2.0)
        dose3.medication = tirzeProfile
        context.insert(dose3)
        
        let dose4 = Dose(amount: 2.5)
        // No medication
        context.insert(dose4)
        
        // Save the context
        try context.save()
        
        viewModel.allDoses = [dose1, dose2, dose3, dose4]
        
        // When: Getting available medications
        let medications = viewModel.availableMedications
        
        // Then: Unique medications are returned, sorted
        #expect(medications.count == 2)
        #expect(medications == ["Semaglutide", "Tirzepatide"])
    }
    
    @Test("availableInjectionSites computed property extracts unique sites")
    func testAvailableInjectionSites() throws {
        // Given: ViewModel with test data
        let viewModel = DoseHistoryViewModel()
        
        let doses = [
            createTestDose(site: "Thigh"),
            createTestDose(site: "Abdomen"),
            createTestDose(site: "Thigh"), // Duplicate
            createTestDose(site: "Upper Arm"),
            createTestDose(site: nil) // No site
        ]
        
        viewModel.allDoses = doses
        
        // When: Getting available injection sites
        let sites = viewModel.availableInjectionSites
        
        // Then: Unique sites are returned, sorted
        #expect(sites.count == 3)
        #expect(sites == ["Abdomen", "Thigh", "Upper Arm"])
    }
    
    @Test("groupedDoses computed property groups by date correctly")
    func testGroupedDoses() throws {
        // Given: ViewModel with doses on different dates
        let viewModel = DoseHistoryViewModel()
        
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let todayMorning = createTestDose(
            timestamp: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)!,
            notes: "morning"
        )
        let todayEvening = createTestDose(
            timestamp: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!,
            notes: "evening"
        )
        let yesterdayDose = createTestDose(
            timestamp: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: yesterday)!,
            notes: "yesterday"
        )
        
        viewModel.filteredDoses = [todayMorning, todayEvening, yesterdayDose]
        
        // When: Getting grouped doses
        let grouped = viewModel.groupedDoses
        
        // Then: Doses are grouped by date, most recent first
        #expect(grouped.count == 2)
        
        // First group should be today (most recent)
        let firstGroup = grouped[0]
        #expect(firstGroup.1.count == 2) // Two doses today
        #expect(firstGroup.1.contains { $0.notes == "morning" })
        #expect(firstGroup.1.contains { $0.notes == "evening" })
        
        // Within day, doses should be sorted by timestamp descending (evening first)
        #expect(firstGroup.1[0].notes == "evening")
        #expect(firstGroup.1[1].notes == "morning")
        
        // Second group should be yesterday
        let secondGroup = grouped[1]
        #expect(secondGroup.1.count == 1)
        #expect(secondGroup.1[0].notes == "yesterday")
    }
    
    // MARK: - Filter Application Tests
    
    @Test("applyFiltersAndSearch handles search text correctly")
    func testApplyFiltersWithSearchText() throws {
        // Given: ViewModel with test data
        let viewModel = DoseHistoryViewModel()
        
        let doses = [
            createTestDose(notes: "morning injection"),
            createTestDose(notes: "evening dose"),
            createTestDose(site: "Thigh"),
            createTestDose(amount: 1.5)
        ]
        
        viewModel.allDoses = doses
        
        // When: Setting search text
        viewModel.searchText = "morning"
        
        // Then: Filtered doses contain only matching dose
        #expect(viewModel.filteredDoses.count == 1)
        #expect(viewModel.filteredDoses[0].notes == "morning injection")
        
        // When: Changing search text
        viewModel.searchText = "1.5"
        
        // Then: Filtered doses contain amount match
        #expect(viewModel.filteredDoses.count == 1)
        #expect(viewModel.filteredDoses[0].amount == 1.5)
    }
    
    @Test("applyFiltersAndSearch handles medication filter correctly")
    func testApplyFiltersWithMedicationFilter() throws {
        // Given: ViewModel with test data and model context
        let container = modelContainer
        let context = container.mainContext
        let viewModel = DoseHistoryViewModel()
        
        // Create medication profiles in the context
        let semaProfile = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic"
        )
        context.insert(semaProfile)
        
        let tirzeProfile = MedicationProfile(
            genericName: "Tirzepatide",
            brandName: "Mounjaro"
        )
        context.insert(tirzeProfile)
        
        // Create doses in the context
        let dose1 = Dose(amount: 1.0)
        dose1.medication = semaProfile
        context.insert(dose1)
        
        let dose2 = Dose(amount: 1.5)
        dose2.medication = tirzeProfile
        context.insert(dose2)
        
        let dose3 = Dose(amount: 2.0)
        // No medication
        context.insert(dose3)
        
        // Save the context
        try context.save()
        
        viewModel.allDoses = [dose1, dose2, dose3]
        
        // When: Setting medication filter
        viewModel.selectedMedicationFilter = "Semaglutide"
        
        // Then: Only semaglutide doses shown
        #expect(viewModel.filteredDoses.count == 1)
        #expect(viewModel.filteredDoses[0].medication?.genericName == "Semaglutide")
        
        // When: Changing medication filter
        viewModel.selectedMedicationFilter = "Tirzepatide"
        
        // Then: Only tirzepatide doses shown
        #expect(viewModel.filteredDoses.count == 1)
        #expect(viewModel.filteredDoses[0].medication?.genericName == "Tirzepatide")
    }
    
    @Test("applyFiltersAndSearch handles date range filter correctly")
    func testApplyFiltersWithDateRange() throws {
        // Given: ViewModel with doses on different dates
        let viewModel = DoseHistoryViewModel()
        
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        let doses = [
            createTestDose(timestamp: today, notes: "today"),
            createTestDose(timestamp: yesterday, notes: "yesterday"),
            createTestDose(timestamp: twoDaysAgo, notes: "two days ago")
        ]
        
        viewModel.allDoses = doses
        
        // When: Setting start date filter
        viewModel.filterStartDate = yesterday
        
        // Then: Only doses from yesterday onwards
        #expect(viewModel.filteredDoses.count == 2)
        #expect(viewModel.filteredDoses.contains { $0.notes == "today" })
        #expect(viewModel.filteredDoses.contains { $0.notes == "yesterday" })
        
        // When: Setting end date filter
        viewModel.filterEndDate = yesterday
        
        // Then: Only yesterday's dose
        #expect(viewModel.filteredDoses.count == 1)
        #expect(viewModel.filteredDoses[0].notes == "yesterday")
    }
    
    @Test("applyFiltersAndSearch handles showSkippedDoses correctly")
    func testApplyFiltersWithSkippedDoses() throws {
        // Given: ViewModel with skipped and regular doses
        let viewModel = DoseHistoryViewModel()
        
        let doses = [
            createTestDose(notes: "regular dose", skipped: false),
            createTestDose(notes: "skipped dose", skipped: true),
            createTestDose(notes: "another regular", skipped: false)
        ]
        
        viewModel.allDoses = doses
        
        // When: showSkippedDoses is true (default)
        #expect(viewModel.showSkippedDoses == true)
        
        // Then: All doses shown
        #expect(viewModel.filteredDoses.count == 3)
        
        // When: Setting showSkippedDoses to false
        viewModel.showSkippedDoses = false
        
        // Then: Only non-skipped doses shown
        #expect(viewModel.filteredDoses.count == 2)
        #expect(viewModel.filteredDoses.allSatisfy { !$0.skipped })
    }
    
    // MARK: - Filter Management Tests
    
    @Test("clearAllFilters resets all filter properties")
    func testClearAllFilters() throws {
        // Given: ViewModel with active filters
        let viewModel = DoseHistoryViewModel()
        
        viewModel.searchText = "test"
        viewModel.selectedMedicationFilter = "Semaglutide"
        viewModel.selectedInjectionSiteFilter = "Thigh"
        viewModel.filterStartDate = Date()
        viewModel.filterEndDate = Date()
        viewModel.showSkippedDoses = false
        
        // Verify filters are active
        #expect(viewModel.hasActiveFilters == true)
        
        // When: Clearing all filters
        viewModel.clearAllFilters()
        
        // Then: All filters are reset
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.selectedMedicationFilter == nil)
        #expect(viewModel.selectedInjectionSiteFilter == nil)
        #expect(viewModel.filterStartDate == nil)
        #expect(viewModel.filterEndDate == nil)
        #expect(viewModel.showSkippedDoses == true)
        #expect(viewModel.hasActiveFilters == false)
    }
    
    // MARK: - CRUD Operations Tests
    
    @Test("getDoseForEditing returns correct DoseEditData")
    func testGetDoseForEditing() throws {
        // Given: ViewModel with test data and model context
        let container = modelContainer
        let context = container.mainContext
        let viewModel = DoseHistoryViewModel()
        
        // Create medication profile in the context
        let medicationProfile = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic"
        )
        context.insert(medicationProfile)
        
        // Create dose in the context
        let dose = Dose(
            amount: 1.5,
            timestamp: Date(),
            site: "Thigh",
            notes: "Test dose",
            skipped: false
        )
        dose.medication = medicationProfile
        context.insert(dose)
        
        // Save the context
        try context.save()
        
        // When: Getting dose for editing
        let editData = viewModel.getDoseForEditing(dose)
        
        // Then: Edit data matches dose
        #expect(editData.id == dose.id)
        #expect(editData.amount == dose.amount)
        #expect(editData.timestamp == dose.timestamp)
        #expect(editData.site == dose.site)
        #expect(editData.notes == dose.notes)
        #expect(editData.skipped == dose.skipped)
        #expect(editData.medicationProfile === dose.medication)
    }
    
    @Test("toggleSkippedStatus updates dose and refreshes filters")
    func testToggleSkippedStatus() throws {
        // Given: ViewModel with test data and model container
        let container = modelContainer
        let context = container.mainContext
        let viewModel = DoseHistoryViewModel()
        
        // Create dose in the context
        let dose = Dose(amount: 1.0, skipped: false)
        context.insert(dose)
        try context.save()
        
        viewModel.allDoses = [dose]
        viewModel.showSkippedDoses = false // So we can test filter refresh
        
        // Initially dose should be visible (not skipped)
        #expect(viewModel.filteredDoses.count == 1)
        
        // When: Toggling skipped status
        try viewModel.toggleSkippedStatus(for: dose, context: context)
        
        // Then: Dose is now skipped and filtered out
        #expect(dose.skipped == true)
        #expect(viewModel.filteredDoses.count == 0)
        
        // When: Toggling back
        try viewModel.toggleSkippedStatus(for: dose, context: context)
        
        // Then: Dose is not skipped and visible again
        #expect(dose.skipped == false)
        #expect(viewModel.filteredDoses.count == 1)
    }
    
    @Test("duplicateDose creates new dose with current timestamp")
    func testDuplicateDose() throws {
        // Given: ViewModel with test data and model container
        let container = modelContainer
        let context = container.mainContext
        let viewModel = DoseHistoryViewModel()
        
        // Create original dose in the context
        let originalDose = Dose(
            amount: 1.5,
            timestamp: Date(timeIntervalSinceNow: -3600), // 1 hour ago
            site: "Thigh",
            notes: "Original dose"
        )
        context.insert(originalDose)
        try context.save()
        
        viewModel.allDoses = [originalDose]
        let originalCount = viewModel.allDoses.count
        
        // When: Duplicating dose
        try viewModel.duplicateDose(originalDose, context: context)
        
        // Then: New dose is created and added
        #expect(viewModel.allDoses.count == originalCount + 1)
        
        let newDose = viewModel.allDoses.first { $0.id != originalDose.id }
        #expect(newDose != nil)
        #expect(newDose?.amount == originalDose.amount)
        #expect(newDose?.site == originalDose.site)
        #expect(newDose?.notes == originalDose.notes)
        #expect(newDose?.skipped == false) // New dose should not be skipped
        #expect(newDose?.timestamp != originalDose.timestamp) // Should have current timestamp
    }
    
    // MARK: - Test Helper Methods
    
    private func createTestDose(
        timestamp: Date = Date(),
        amount: Double = 1.0,
        site: String? = nil,
        notes: String? = nil,
        skipped: Bool = false
    ) -> Dose {
        return Dose(
            amount: amount,
            timestamp: timestamp,
            site: site,
            notes: notes,
            skipped: skipped
        )
    }
    
    private func createTestMedicationProfile(
        genericName: String = "TestMedication",
        brandName: String = "TestBrand"
    ) -> MedicationProfile {
        return MedicationProfile(
            genericName: genericName,
            brandName: brandName
        )
    }
}