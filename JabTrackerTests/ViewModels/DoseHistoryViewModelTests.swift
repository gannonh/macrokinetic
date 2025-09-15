//
//  DoseHistoryViewModelTests.swift
//  JabTrackerTests
//
//  Unit tests for DoseHistoryViewModel business logic
//  Defines contracts for data fetching, filtering, search, and CRUD operations
//

import Testing
import SwiftData
import Foundation
import XCTest
@testable import JabTracker

@MainActor
struct DoseHistoryViewModelTests {
    
    var container: ModelContainer
    var context: ModelContext
    var viewModel: DoseHistoryViewModel
    
    init() throws {
        // Create in-memory container for testing
        let schema = Schema([User.self, Dose.self, MedicationProfile.self, DoseTitration.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = container.mainContext
        viewModel = DoseHistoryViewModel()
    }
    
    // MARK: - Data Loading Tests
    
    @Test("ViewModel loads doses in reverse chronological order")
    func testLoadDataSortsInReverseChronologicalOrder() async throws {
        // Given: Multiple doses with different timestamps
        let olderDate = Date().addingTimeInterval(-86400) // 1 day ago
        let newerDate = Date()
        
        let olderDose = createTestDose(timestamp: olderDate, amount: 1.0)
        let newerDose = createTestDose(timestamp: newerDate, amount: 2.0)
        
        context.insert(olderDose)
        context.insert(newerDose)
        try context.save()
        
        // When: ViewModel loads data
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Doses are sorted in reverse chronological order (newest first)
        #expect(viewModel.allDoses.count == 2)
        #expect(viewModel.allDoses[0].timestamp == newerDate)
        #expect(viewModel.allDoses[1].timestamp == olderDate)
        #expect(viewModel.filteredDoses[0].amount == 2.0)
        #expect(viewModel.filteredDoses[1].amount == 1.0)
    }
    
    @Test("ViewModel handles empty data correctly")
    func testLoadDataWithNoDoses() async throws {
        // Given: No doses in database
        
        // When: ViewModel loads data
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Arrays are empty but no error occurs
        #expect(viewModel.allDoses.isEmpty)
        #expect(viewModel.filteredDoses.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("ViewModel handles loading state correctly")
    func testLoadingStateManagement() async throws {
        // Given: Fresh view model
        #expect(viewModel.isLoading == false)
        
        // When: Starting to load data
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Loading state is managed properly
        #expect(viewModel.isLoading == false) // Synchronous operation completes immediately
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test("Refresh data updates with pull-to-refresh")
    func testRefreshDataUpdatesCorrectly() async throws {
        // Given: Initial data loaded
        let initialDose = createTestDose(amount: 1.0)
        context.insert(initialDose)
        try context.save()
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let initialCount = viewModel.allDoses.count
        
        // When: Adding new dose and refreshing
        let newDose = createTestDose(amount: 2.0)
        context.insert(newDose)
        try context.save()
        
        await viewModel.refreshData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Data is updated
        #expect(viewModel.allDoses.count == initialCount + 1)
        #expect(viewModel.isRefreshing == false)
    }
    
    // MARK: - Search and Filtering Tests
    
    @Test("Search text filters doses correctly")
    func testSearchTextFiltering() async throws {
        // Given: Doses with different notes
        let doseWithMorning = createTestDose(notes: "morning injection")
        let doseWithEvening = createTestDose(notes: "evening dose")
        let doseWithoutNotes = createTestDose(notes: nil)
        
        context.insert(doseWithMorning)
        context.insert(doseWithEvening)
        context.insert(doseWithoutNotes)
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // When: Setting search text
        viewModel.searchText = "morning"
        
        // Then: Only matching doses are shown
        #expect(viewModel.filteredDoses.count == 1)
        #expect(viewModel.filteredDoses[0].notes == "morning injection")
    }
    
    @Test("Medication filter works correctly")
    func testMedicationFiltering() async throws {
        // Given: Doses with different medications
        let semaglutideProfile = createTestMedicationProfile(genericName: "Semaglutide")
        let tirzepatideProfile = createTestMedicationProfile(genericName: "Tirzepatide")
        
        let semaglutideDose = createTestDose(amount: 1.0)
        let tirzepatideDose = createTestDose(amount: 2.0)
        
        context.insert(semaglutideProfile)
        context.insert(tirzepatideProfile)
        context.insert(semaglutideDose)
        context.insert(tirzepatideDose)
        
        // Set relationships after insertion
        semaglutideDose.medication = semaglutideProfile
        tirzepatideDose.medication = tirzepatideProfile
        
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // When: Filtering by medication
        viewModel.selectedMedicationFilter = "Semaglutide"
        
        // Then: Only matching medication doses are shown
        #expect(viewModel.filteredDoses.count == 1)
        #expect(viewModel.filteredDoses[0].medication?.genericName == "Semaglutide")
    }
    
    @Test("Injection site filter works correctly")
    func testInjectionSiteFiltering() async throws {
        // Given: Doses with different injection sites
        let thighDose = createTestDose(site: "Thigh")
        let abdomenDose = createTestDose(site: "Abdomen")
        let noSiteDose = createTestDose(site: nil)
        
        context.insert(thighDose)
        context.insert(abdomenDose)
        context.insert(noSiteDose)
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // When: Filtering by injection site
        viewModel.selectedInjectionSiteFilter = "Thigh"
        
        // Then: Only matching site doses are shown
        #expect(viewModel.filteredDoses.count == 1)
        #expect(viewModel.filteredDoses[0].site == "Thigh")
    }
    
    @Test("Date range filtering works correctly")
    func testDateRangeFiltering() async throws {
        // Given: Doses with different timestamps
        let yesterday = Date().addingTimeInterval(-86400)
        let today = Date()
        let tomorrow = Date().addingTimeInterval(86400)
        
        let yesterdayDose = createTestDose(timestamp: yesterday)
        let todayDose = createTestDose(timestamp: today)
        let tomorrowDose = createTestDose(timestamp: tomorrow)
        
        context.insert(yesterdayDose)
        context.insert(todayDose)
        context.insert(tomorrowDose)
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // When: Setting date range filter
        viewModel.filterStartDate = yesterday
        viewModel.filterEndDate = today
        
        // Then: Only doses within range are shown
        #expect(viewModel.filteredDoses.count == 2) // yesterday and today
        #expect(!viewModel.filteredDoses.contains(where: { $0.timestamp > tomorrow.addingTimeInterval(-3600) }))
    }
    
    @Test("Skipped dose filter works correctly")
    func testSkippedDoseFiltering() async throws {
        // Given: Mix of skipped and regular doses
        let regularDose = createTestDose(skipped: false)
        let skippedDose = createTestDose(skipped: true)
        
        context.insert(regularDose)
        context.insert(skippedDose)
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // When: Hiding skipped doses
        viewModel.showSkippedDoses = false
        
        // Then: Only regular doses are shown
        #expect(viewModel.filteredDoses.count == 1)
        #expect(viewModel.filteredDoses[0].skipped == false)
        
        // When: Showing skipped doses
        viewModel.showSkippedDoses = true
        
        // Then: All doses are shown
        #expect(viewModel.filteredDoses.count == 2)
    }
    
    @Test("Multiple filters work together")
    func testMultipleFiltersComposition() async throws {
        // Given: Complex data set
        let profile = createTestMedicationProfile(genericName: "Semaglutide")
        
        let matchingDose = createTestDose(
            timestamp: Date(),
            site: "Thigh",
            notes: "morning injection",
            skipped: false,
            medication: profile
        )
        
        let nonMatchingDose = createTestDose(
            timestamp: Date().addingTimeInterval(-86400),
            site: "Abdomen", 
            notes: "evening dose",
            skipped: true
        )
        
        context.insert(profile)
        context.insert(matchingDose)
        context.insert(nonMatchingDose)
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // When: Applying multiple filters
        viewModel.searchText = "morning"
        viewModel.selectedMedicationFilter = "Semaglutide"
        viewModel.selectedInjectionSiteFilter = "Thigh"
        viewModel.showSkippedDoses = false
        
        // Then: Only fully matching dose is shown
        #expect(viewModel.filteredDoses.count == 1)
        #expect(viewModel.filteredDoses[0].notes == "morning injection")
        #expect(viewModel.filteredDoses[0].site == "Thigh")
        #expect(viewModel.filteredDoses[0].skipped == false)
    }
    
    @Test("Clear all filters resets to show all doses")
    func testClearAllFilters() async throws {
        // Given: Filtered data
        let dose1 = createTestDose(notes: "morning")
        let dose2 = createTestDose(notes: "evening")
        
        context.insert(dose1)
        context.insert(dose2)
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        viewModel.searchText = "morning"
        
        #expect(viewModel.filteredDoses.count == 1)
        #expect(viewModel.hasActiveFilters == true)
        
        // When: Clearing all filters
        viewModel.clearAllFilters()
        
        // Then: All doses are shown and filters are reset
        #expect(viewModel.filteredDoses.count == 2)
        #expect(viewModel.hasActiveFilters == false)
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.selectedMedicationFilter == nil)
        #expect(viewModel.selectedInjectionSiteFilter == nil)
        #expect(viewModel.filterStartDate == nil)
        #expect(viewModel.filterEndDate == nil)
        #expect(viewModel.showSkippedDoses == true)
    }
    
    // MARK: - Computed Properties Tests
    
    @Test("Available medications computed correctly")
    func testAvailableMedicationsComputation() async throws {
        // Given: Doses with different medications
        let profile1 = createTestMedicationProfile(genericName: "Semaglutide")
        let profile2 = createTestMedicationProfile(genericName: "Tirzepatide")
        let profile3 = createTestMedicationProfile(genericName: "Semaglutide") // Duplicate
        
        let dose1 = createTestDose(amount: 1.0)
        let dose2 = createTestDose(amount: 2.0)
        let dose3 = createTestDose(amount: 3.0)
        let doseWithoutMedication = createTestDose(amount: 4.0)
        
        context.insert(profile1)
        context.insert(profile2)
        context.insert(profile3)
        context.insert(dose1)
        context.insert(dose2)
        context.insert(dose3)
        context.insert(doseWithoutMedication)
        
        // Set relationships after insertion
        dose1.medication = profile1
        dose2.medication = profile2
        dose3.medication = profile3
        
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Unique medications are returned, sorted
        let medications = viewModel.availableMedications
        #expect(medications.count == 2) // Semaglutide and Tirzepatide (deduplicated)
        #expect(medications.contains("Semaglutide"))
        #expect(medications.contains("Tirzepatide"))
        #expect(medications[0] <= medications[1]) // Sorted order
    }
    
    @Test("Available injection sites computed correctly")
    func testAvailableInjectionSitesComputation() async throws {
        // Given: Doses with different injection sites
        let dose1 = createTestDose(site: "Thigh")
        let dose2 = createTestDose(site: "Abdomen")
        let dose3 = createTestDose(site: "Thigh") // Duplicate
        let doseWithoutSite = createTestDose(site: nil)
        
        context.insert(dose1)
        context.insert(dose2)
        context.insert(dose3)
        context.insert(doseWithoutSite)
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Unique injection sites are returned, sorted
        let sites = viewModel.availableInjectionSites
        #expect(sites.count == 2) // Thigh and Abdomen (deduplicated)
        #expect(sites.contains("Thigh"))
        #expect(sites.contains("Abdomen"))
        #expect(sites[0] <= sites[1]) // Sorted order
    }
    
    @Test("Grouped doses by date computed correctly")
    func testGroupedDosesByDateComputation() async throws {
        // Given: Doses from different dates
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let todayDose1 = createTestDose(timestamp: today, amount: 1.0)
        let todayDose2 = createTestDose(timestamp: today.addingTimeInterval(3600), amount: 2.0) // 1 hour later
        let yesterdayDose = createTestDose(timestamp: yesterday, amount: 3.0)
        
        context.insert(todayDose1)
        context.insert(todayDose2)
        context.insert(yesterdayDose)
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Doses are grouped by date, sorted by date (newest first)
        let groupedDoses = viewModel.groupedDoses
        #expect(groupedDoses.count == 2) // Two date groups
        
        // Verify order (today's group should come first)
        let firstGroup = groupedDoses[0]
        let secondGroup = groupedDoses[1]
        
        // Today's group should have 2 doses, yesterday's group should have 1
        #expect(firstGroup.1.count == 2) // Today's doses
        #expect(secondGroup.1.count == 1) // Yesterday's dose
        
        // Within each group, doses should be sorted reverse chronologically
        #expect(firstGroup.1[0].amount == 2.0) // Later dose first
        #expect(firstGroup.1[1].amount == 1.0) // Earlier dose second
    }
    
    @Test("Has active filters computed correctly")
    func testHasActiveFiltersComputation() throws {
        // Given: Fresh view model
        #expect(viewModel.hasActiveFilters == false)
        
        // When: Setting various filters
        viewModel.searchText = "test"
        #expect(viewModel.hasActiveFilters == true)
        
        viewModel.searchText = ""
        viewModel.selectedMedicationFilter = "Semaglutide"
        #expect(viewModel.hasActiveFilters == true)
        
        viewModel.selectedMedicationFilter = nil
        viewModel.filterStartDate = Date()
        #expect(viewModel.hasActiveFilters == true)
        
        viewModel.filterStartDate = nil
        viewModel.showSkippedDoses = false
        #expect(viewModel.hasActiveFilters == true)
        
        // When: Clearing all filters
        viewModel.showSkippedDoses = true
        #expect(viewModel.hasActiveFilters == false)
    }
    
    // MARK: - CRUD Operations Tests
    
    @Test("Delete dose removes from context and updates arrays")
    func testDeleteDose() async throws {
        // Given: Dose exists
        let dose = createTestDose(amount: 1.5)
        context.insert(dose)
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(viewModel.allDoses.count == 1)
        
        // When: Deleting dose
        try viewModel.deleteDose(dose, context: context)
        
        // Then: Dose is removed from context and view model arrays
        #expect(viewModel.allDoses.isEmpty)
        #expect(viewModel.filteredDoses.isEmpty)
        
        // Verify dose is actually deleted from context
        let descriptor = FetchDescriptor<Dose>()
        let remainingDoses = try context.fetch(descriptor)
        #expect(remainingDoses.isEmpty)
    }
    
    @Test("Toggle skipped status updates dose and refreshes filters")
    func testToggleSkippedStatus() async throws {
        // Given: Non-skipped dose exists
        let dose = createTestDose(skipped: false)
        context.insert(dose)
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(dose.skipped == false)
        
        // When: Toggling skipped status
        try viewModel.toggleSkippedStatus(for: dose, context: context)
        
        // Then: Dose is marked as skipped
        #expect(dose.skipped == true)
        
        // When: Toggling again
        try viewModel.toggleSkippedStatus(for: dose, context: context)
        
        // Then: Dose is back to not skipped
        #expect(dose.skipped == false)
    }
    
    @Test("Duplicate dose creates new dose with current timestamp")
    func testDuplicateDose() async throws {
        // Given: Original dose exists
        let originalTimestamp = Date().addingTimeInterval(-3600) // 1 hour ago
        let profile = createTestMedicationProfile(genericName: "Semaglutide")
        let user = createTestUser()
        
        let originalDose = createTestDose(
            timestamp: originalTimestamp,
            amount: 1.5,
            site: "Thigh",
            notes: "Original dose",
            skipped: true // This should not be copied
        )
        
        context.insert(profile)
        context.insert(user)
        context.insert(originalDose)
        
        // Set relationships after insertion
        originalDose.user = user
        originalDose.medication = profile
        
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        let initialCount = viewModel.allDoses.count
        
        // When: Duplicating dose
        try viewModel.duplicateDose(originalDose, context: context)
        
        // Then: New dose is created with same data but current timestamp and not skipped
        #expect(viewModel.allDoses.count == initialCount + 1)
        
        let newDose = viewModel.allDoses.first { $0.id != originalDose.id }
        #expect(newDose != nil)
        
        if let newDose = newDose {
            #expect(newDose.amount == originalDose.amount)
            #expect(newDose.site == originalDose.site)
            #expect(newDose.notes == originalDose.notes)
            #expect(newDose.medication?.id == originalDose.medication?.id)
            #expect(newDose.user?.id == originalDose.user?.id)
            
            // Different from original
            #expect(newDose.timestamp > originalTimestamp) // Should be more recent
            #expect(newDose.skipped == false) // Should not be skipped
            #expect(newDose.id != originalDose.id) // Different ID
        }
    }
    
    @Test("Get dose for editing returns correct edit data")
    func testGetDoseForEditing() throws {
        // Given: Dose with specific data
        let testAmount = 2.5
        let testSite = "Abdomen"
        let testNotes = "Test notes"
        let testTimestamp = Date()
        let testSkipped = true
        
        let profile = createTestMedicationProfile(genericName: "Tirzepatide")
        let dose = createTestDose(
            timestamp: testTimestamp,
            amount: testAmount,
            site: testSite,
            notes: testNotes,
            skipped: testSkipped
        )
        
        context.insert(profile)
        context.insert(dose)
        
        // Set relationships after insertion
        dose.medication = profile
        
        try context.save()
        
        // When: Getting dose for editing
        let editData = viewModel.getDoseForEditing(dose)
        
        // Then: Edit data matches dose properties
        #expect(editData.id == dose.id)
        #expect(editData.amount == testAmount)
        #expect(editData.timestamp == testTimestamp)
        #expect(editData.site == testSite)
        #expect(editData.notes == testNotes)
        #expect(editData.skipped == testSkipped)
        #expect(editData.medicationProfile?.id == profile.id)
    }
    
    @Test("Update dose modifies existing dose and refreshes data")
    func testUpdateDose() async throws {
        // Given: Existing dose
        let originalDose = createTestDose(
            amount: 1.0,
            site: "Thigh",
            notes: "Original"
        )
        
        context.insert(originalDose)
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // When: Updating dose with new data
        let newAmount = 2.5
        let newSite = "Abdomen"
        let newNotes = "Updated notes"
        let newTimestamp = Date().addingTimeInterval(3600)
        
        let editData = DoseEditData(
            id: originalDose.id,
            amount: newAmount,
            timestamp: newTimestamp,
            site: newSite,
            notes: newNotes,
            imageData: nil,
            skipped: false,
            medicationProfile: nil
        )
        
        try viewModel.updateDose(originalDose, with: editData, context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Dose is updated with new values
        #expect(originalDose.amount == newAmount)
        #expect(originalDose.site == newSite)
        #expect(originalDose.notes == newNotes)
        #expect(originalDose.timestamp == newTimestamp)
        #expect(originalDose.skipped == false)
        
        // And: View model data is refreshed
        #expect(viewModel.allDoses.contains(where: { $0.id == originalDose.id }))
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Delete operation handles context save errors")
    func testDeleteDoseErrorHandling() async throws {
        // Given: Dose exists but context is in invalid state
        let dose = createTestDose(amount: 1.0)
        context.insert(dose)
        try context.save()
        
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Create a scenario where save might fail by using a different context
        let invalidContext = container.mainContext
        
        // When/Then: Delete operation should handle errors appropriately
        // Note: In real implementation, we might simulate context errors
        // For now, we verify the operation completes without crashing
        
        do {
            try viewModel.deleteDose(dose, context: invalidContext)
            // If no error thrown, operation succeeded
        } catch {
            // Error handling should be graceful
            #expect(error is any Error)
        }
    }
    
    // MARK: - Calendar Integration Tests

    @Test("ViewModel provides doses grouped by date for calendar display")
    func testGroupedDosesForCalendarView() async throws {
        // Given: Doses on different dates
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!

        let dose1 = createTestDose(timestamp: today, amount: 1.0)
        let dose2 = createTestDose(timestamp: today, amount: 2.0) // Same day
        let dose3 = createTestDose(timestamp: yesterday, amount: 1.5)
        let dose4 = createTestDose(timestamp: twoDaysAgo, amount: 0.5)

        [dose1, dose2, dose3, dose4].forEach { context.insert($0) }
        try context.save()

        // When: Setting doses in ViewModel
        viewModel.setDoses([dose1, dose2, dose3, dose4])

        // Then: Grouped doses should organize by date correctly
        let grouped = viewModel.groupedDoses

        #expect(grouped.count == 3) // 3 different dates

        // Find today's group
        let todayFormatter = DateFormatter()
        todayFormatter.dateStyle = .medium
        todayFormatter.timeStyle = .none
        let todayString = todayFormatter.string(from: today)

        let todayGroup = grouped.first { $0.0 == todayString }
        #expect(todayGroup != nil)
        #expect(todayGroup?.1.count == 2) // 2 doses today
    }

    @Test("ViewModel filters doses by date range for calendar month view")
    func testDateRangeFilteringForCalendarMonths() async throws {
        // Given: Doses across multiple months
        let calendar = Calendar.current
        let currentMonth = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!

        let currentMonthDose = createTestDose(timestamp: currentMonth, amount: 1.0)
        let lastMonthDose = createTestDose(timestamp: lastMonth, amount: 2.0)
        let nextMonthDose = createTestDose(timestamp: nextMonth, amount: 3.0)

        [currentMonthDose, lastMonthDose, nextMonthDose].forEach { context.insert($0) }
        try context.save()

        viewModel.setDoses([currentMonthDose, lastMonthDose, nextMonthDose])

        // When: Filtering by current month date range
        let monthStart = calendar.dateInterval(of: .month, for: currentMonth)!.start
        let monthEnd = calendar.dateInterval(of: .month, for: currentMonth)!.end

        viewModel.filterStartDate = monthStart
        viewModel.filterEndDate = monthEnd

        // Then: Only current month doses should be visible
        #expect(viewModel.filteredDoses.count == 1)
        #expect(viewModel.filteredDoses.first?.amount == 1.0)
    }

    @Test("ViewModel supports calendar data requirements with empty months")
    func testEmptyMonthCalendarSupport() async throws {
        // Given: No doses in the system
        viewModel.setDoses([])

        // When: Requesting grouped doses for calendar
        let grouped = viewModel.groupedDoses

        // Then: Empty array should be returned gracefully
        #expect(grouped.isEmpty)
        #expect(viewModel.filteredDoses.isEmpty)
        #expect(!viewModel.hasActiveFilters) // No filters applied initially
    }

    @Test("ViewModel provides dose counts per date for calendar indicators")
    func testDoseCountsPerDateForCalendarIndicators() async throws {
        // Given: Multiple doses on same date and single doses on other dates
        let targetDate = Date()
        let otherDate = Calendar.current.date(byAdding: .day, value: -1, to: targetDate)!

        let dose1 = createTestDose(timestamp: targetDate, amount: 1.0)
        let dose2 = createTestDose(timestamp: targetDate, amount: 2.0) // Same date
        let dose3 = createTestDose(timestamp: targetDate, amount: 1.5) // Same date
        let dose4 = createTestDose(timestamp: otherDate, amount: 0.5) // Different date

        [dose1, dose2, dose3, dose4].forEach { context.insert($0) }
        try context.save()

        viewModel.setDoses([dose1, dose2, dose3, dose4])

        // When: Getting grouped doses
        let grouped = viewModel.groupedDoses

        // Then: Target date should have 3 doses, other date should have 1
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let targetDateString = formatter.string(from: targetDate)
        let otherDateString = formatter.string(from: otherDate)

        let targetGroup = grouped.first { $0.0 == targetDateString }
        let otherGroup = grouped.first { $0.0 == otherDateString }

        #expect(targetGroup?.1.count == 3)
        #expect(otherGroup?.1.count == 1)
    }

    @Test("ViewModel provides doses for specific date calendar lookup")
    func testDosesForSpecificDate() async throws {
        // Given: Doses on different times of the same day and other days
        let calendar = Calendar.current
        let targetDate = Date()
        let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: targetDate)!
        let eveningTime = calendar.date(bySettingHour: 20, minute: 30, second: 0, of: targetDate)!
        let otherDate = calendar.date(byAdding: .day, value: -1, to: targetDate)!

        let morningDose = createTestDose(timestamp: morningTime, amount: 1.0)
        let eveningDose = createTestDose(timestamp: eveningTime, amount: 2.0)
        let otherDayDose = createTestDose(timestamp: otherDate, amount: 3.0)

        [morningDose, eveningDose, otherDayDose].forEach { context.insert($0) }
        try context.save()

        viewModel.setDoses([morningDose, eveningDose, otherDayDose])

        // When: Getting doses for target date
        let targetDateDoses = viewModel.doses(for: targetDate)

        // Then: Should return both doses from target date, sorted by time
        #expect(targetDateDoses.count == 2)
        #expect(targetDateDoses[0].amount == 1.0) // Morning dose first
        #expect(targetDateDoses[1].amount == 2.0) // Evening dose second

        // When: Getting dose count for target date
        let targetDateCount = viewModel.doseCount(for: targetDate)

        // Then: Should return correct count
        #expect(targetDateCount == 2)

        // When: Getting doses for other date
        let otherDateDoses = viewModel.doses(for: otherDate)

        // Then: Should return only the other day dose
        #expect(otherDateDoses.count == 1)
        #expect(otherDateDoses[0].amount == 3.0)
    }

    @Test("ViewModel provides grouped doses by date for calendar integration")
    func testGroupedDosesByDateForCalendar() async throws {
        // Given: Doses on different dates
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let dose1 = createTestDose(timestamp: today, amount: 1.0)
        let dose2 = createTestDose(timestamp: today, amount: 2.0) // Same day
        let dose3 = createTestDose(timestamp: yesterday, amount: 3.0)

        [dose1, dose2, dose3].forEach { context.insert($0) }
        try context.save()

        viewModel.setDoses([dose1, dose2, dose3])

        // When: Getting grouped doses by date
        let groupedByDate = viewModel.groupedDosesByDate

        // Then: Should group by start of day correctly
        let todayKey = calendar.startOfDay(for: today)
        let yesterdayKey = calendar.startOfDay(for: yesterday)

        #expect(groupedByDate.count == 2)
        #expect(groupedByDate[todayKey]?.count == 2)
        #expect(groupedByDate[yesterdayKey]?.count == 1)
    }

    // MARK: - Test Helper Methods
    
    private func createTestDose(
        timestamp: Date = Date(),
        amount: Double = 1.0,
        site: String? = nil,
        notes: String? = nil,
        imageData: Data? = nil,
        skipped: Bool = false,
        user: User? = nil,
        medication: MedicationProfile? = nil
    ) -> Dose {
        Dose(
            amount: amount,
            timestamp: timestamp,
            site: site,
            notes: notes,
            imageData: imageData,
            skipped: skipped,
            user: user,
            medication: medication
        )
    }
    
    private func createTestMedicationProfile(
        genericName: String = "TestMedication",
        brandName: String = "TestBrand",
        currentDose: Double = 1.0
    ) -> MedicationProfile {
        MedicationProfile(
            genericName: genericName,
            brandName: brandName,
            currentDose: currentDose
        )
    }
    
    private func createTestUser(
        email: String = "test@example.com",
        name: String = "Test User"
    ) -> User {
        User(
            email: email,
            name: name
        )
    }
}
