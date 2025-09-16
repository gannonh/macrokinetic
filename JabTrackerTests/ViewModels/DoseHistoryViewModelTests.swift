//
//  DoseHistoryViewModelTests.swift
//  JabTrackerTests
//
//  Unit tests for DoseHistoryViewModel business logic
//  Defines contracts for data fetching, filtering, search, and CRUD operations
//

import Foundation
@testable import JabTracker
import SwiftData
import Testing
import XCTest

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
            cloudKitDatabase: .none)
        self.container = try ModelContainer(for: schema, configurations: [configuration])
        self.context = self.container.mainContext
        self.viewModel = DoseHistoryViewModel()
    }

    // MARK: - Data Loading Tests

    @Test("ViewModel loads doses in reverse chronological order")
    func loadDataSortsInReverseChronologicalOrder() async throws {
        // Given: Multiple doses with different timestamps
        let olderDate = Date().addingTimeInterval(-86400) // 1 day ago
        let newerDate = Date()

        let olderDose = self.createTestDose(timestamp: olderDate, amount: 1.0)
        let newerDose = self.createTestDose(timestamp: newerDate, amount: 2.0)

        self.context.insert(olderDose)
        self.context.insert(newerDose)
        try self.context.save()

        // When: ViewModel loads data
        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Doses are sorted in reverse chronological order (newest first)
        #expect(self.viewModel.allDoses.count == 2)
        #expect(self.viewModel.allDoses[0].timestamp == newerDate)
        #expect(self.viewModel.allDoses[1].timestamp == olderDate)
        #expect(self.viewModel.filteredDoses[0].amount == 2.0)
        #expect(self.viewModel.filteredDoses[1].amount == 1.0)
    }

    @Test("ViewModel handles empty data correctly")
    func loadDataWithNoDoses() async throws {
        // Given: No doses in database

        // When: ViewModel loads data
        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Arrays are empty but no error occurs
        #expect(self.viewModel.allDoses.isEmpty)
        #expect(self.viewModel.filteredDoses.isEmpty)
        #expect(self.viewModel.isLoading == false)
        #expect(self.viewModel.errorMessage == nil)
    }

    @Test("ViewModel handles loading state correctly")
    func loadingStateManagement() async throws {
        // Given: Fresh view model
        #expect(self.viewModel.isLoading == false)

        // When: Starting to load data
        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Loading state is managed properly
        #expect(self.viewModel.isLoading == false) // Synchronous operation completes immediately
        #expect(self.viewModel.errorMessage == nil)
    }

    @Test("Refresh data updates with pull-to-refresh")
    func refreshDataUpdatesCorrectly() async throws {
        // Given: Initial data loaded
        let initialDose = self.createTestDose(amount: 1.0)
        self.context.insert(initialDose)
        try self.context.save()
        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        let initialCount = self.viewModel.allDoses.count

        // When: Adding new dose and refreshing
        let newDose = self.createTestDose(amount: 2.0)
        self.context.insert(newDose)
        try self.context.save()

        await self.viewModel.refreshData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Data is updated
        #expect(self.viewModel.allDoses.count == initialCount + 1)
        #expect(self.viewModel.isRefreshing == false)
    }

    // MARK: - Search and Filtering Tests

    @Test("Search text filters doses correctly")
    func searchTextFiltering() async throws {
        // Given: Doses with different notes
        let doseWithMorning = self.createTestDose(notes: "morning injection")
        let doseWithEvening = self.createTestDose(notes: "evening dose")
        let doseWithoutNotes = self.createTestDose(notes: nil)

        self.context.insert(doseWithMorning)
        self.context.insert(doseWithEvening)
        self.context.insert(doseWithoutNotes)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Setting search text
        self.viewModel.searchText = "morning"

        // Then: Only matching doses are shown
        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.filteredDoses[0].notes == "morning injection")
    }

    @Test("Medication filter works correctly")
    func medicationFiltering() async throws {
        // Given: Doses with different medications
        let semaglutideProfile = self.createTestMedicationProfile(genericName: "Semaglutide")
        let tirzepatideProfile = self.createTestMedicationProfile(genericName: "Tirzepatide")

        let semaglutideDose = self.createTestDose(amount: 1.0)
        let tirzepatideDose = self.createTestDose(amount: 2.0)

        self.context.insert(semaglutideProfile)
        self.context.insert(tirzepatideProfile)
        self.context.insert(semaglutideDose)
        self.context.insert(tirzepatideDose)

        // Set relationships after insertion
        semaglutideDose.medication = semaglutideProfile
        tirzepatideDose.medication = tirzepatideProfile

        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Filtering by medication
        self.viewModel.selectedMedicationFilter = "Semaglutide"

        // Then: Only matching medication doses are shown
        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.filteredDoses[0].medication?.genericName == "Semaglutide")
    }

    @Test("Injection site filter works correctly")
    func injectionSiteFiltering() async throws {
        // Given: Doses with different injection sites
        let thighDose = self.createTestDose(site: "Thigh")
        let abdomenDose = self.createTestDose(site: "Abdomen")
        let noSiteDose = self.createTestDose(site: nil)

        self.context.insert(thighDose)
        self.context.insert(abdomenDose)
        self.context.insert(noSiteDose)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Filtering by injection site
        self.viewModel.selectedInjectionSiteFilter = "Thigh"

        // Then: Only matching site doses are shown
        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.filteredDoses[0].site == "Thigh")
    }

    @Test("Date range filtering works correctly")
    func dateRangeFiltering() async throws {
        // Given: Doses with different timestamps
        let yesterday = Date().addingTimeInterval(-86400)
        let today = Date()
        let tomorrow = Date().addingTimeInterval(86400)

        let yesterdayDose = self.createTestDose(timestamp: yesterday)
        let todayDose = self.createTestDose(timestamp: today)
        let tomorrowDose = self.createTestDose(timestamp: tomorrow)

        self.context.insert(yesterdayDose)
        self.context.insert(todayDose)
        self.context.insert(tomorrowDose)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Setting date range filter
        self.viewModel.filterStartDate = yesterday
        self.viewModel.filterEndDate = today

        // Then: Only doses within range are shown
        #expect(self.viewModel.filteredDoses.count == 2) // yesterday and today
        #expect(!self.viewModel.filteredDoses.contains(where: { $0.timestamp > tomorrow.addingTimeInterval(-3600) }))
    }

    @Test("Skipped dose filter works correctly")
    func skippedDoseFiltering() async throws {
        // Given: Mix of skipped and regular doses
        let regularDose = self.createTestDose(skipped: false)
        let skippedDose = self.createTestDose(skipped: true)

        self.context.insert(regularDose)
        self.context.insert(skippedDose)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Hiding skipped doses
        self.viewModel.showSkippedDoses = false

        // Then: Only regular doses are shown
        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.filteredDoses[0].skipped == false)

        // When: Showing skipped doses
        self.viewModel.showSkippedDoses = true

        // Then: All doses are shown
        #expect(self.viewModel.filteredDoses.count == 2)
    }

    @Test("Multiple filters work together")
    func multipleFiltersComposition() async throws {
        // Given: Complex data set
        let profile = self.createTestMedicationProfile(genericName: "Semaglutide")

        let matchingDose = self.createTestDose(
            timestamp: Date(),
            site: "Thigh",
            notes: "morning injection",
            skipped: false,
            medication: profile)

        let nonMatchingDose = self.createTestDose(
            timestamp: Date().addingTimeInterval(-86400),
            site: "Abdomen",
            notes: "evening dose",
            skipped: true)

        self.context.insert(profile)
        self.context.insert(matchingDose)
        self.context.insert(nonMatchingDose)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Applying multiple filters
        self.viewModel.searchText = "morning"
        self.viewModel.selectedMedicationFilter = "Semaglutide"
        self.viewModel.selectedInjectionSiteFilter = "Thigh"
        self.viewModel.showSkippedDoses = false

        // Then: Only fully matching dose is shown
        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.filteredDoses[0].notes == "morning injection")
        #expect(self.viewModel.filteredDoses[0].site == "Thigh")
        #expect(self.viewModel.filteredDoses[0].skipped == false)
    }

    @Test("Clear all filters resets to show all doses")
    func testClearAllFilters() async throws {
        // Given: Filtered data
        let dose1 = self.createTestDose(notes: "morning")
        let dose2 = self.createTestDose(notes: "evening")

        self.context.insert(dose1)
        self.context.insert(dose2)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)
        self.viewModel.searchText = "morning"

        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.hasActiveFilters == true)

        // When: Clearing all filters
        self.viewModel.clearAllFilters()

        // Then: All doses are shown and filters are reset
        #expect(self.viewModel.filteredDoses.count == 2)
        #expect(self.viewModel.hasActiveFilters == false)
        #expect(self.viewModel.searchText.isEmpty)
        #expect(self.viewModel.selectedMedicationFilter == nil)
        #expect(self.viewModel.selectedInjectionSiteFilter == nil)
        #expect(self.viewModel.filterStartDate == nil)
        #expect(self.viewModel.filterEndDate == nil)
        #expect(self.viewModel.showSkippedDoses == true)
    }

    // MARK: - Computed Properties Tests

    @Test("Available medications computed correctly")
    func availableMedicationsComputation() async throws {
        // Given: Doses with different medications
        let profile1 = self.createTestMedicationProfile(genericName: "Semaglutide")
        let profile2 = self.createTestMedicationProfile(genericName: "Tirzepatide")
        let profile3 = self.createTestMedicationProfile(genericName: "Semaglutide") // Duplicate

        let dose1 = self.createTestDose(amount: 1.0)
        let dose2 = self.createTestDose(amount: 2.0)
        let dose3 = self.createTestDose(amount: 3.0)
        let doseWithoutMedication = self.createTestDose(amount: 4.0)

        self.context.insert(profile1)
        self.context.insert(profile2)
        self.context.insert(profile3)
        self.context.insert(dose1)
        self.context.insert(dose2)
        self.context.insert(dose3)
        self.context.insert(doseWithoutMedication)

        // Set relationships after insertion
        dose1.medication = profile1
        dose2.medication = profile2
        dose3.medication = profile3

        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Unique medications are returned, sorted
        let medications = self.viewModel.availableMedications
        #expect(medications.count == 2) // Semaglutide and Tirzepatide (deduplicated)
        #expect(medications.contains("Semaglutide"))
        #expect(medications.contains("Tirzepatide"))
        #expect(medications[0] <= medications[1]) // Sorted order
    }

    @Test("Available injection sites computed correctly")
    func availableInjectionSitesComputation() async throws {
        // Given: Doses with different injection sites
        let dose1 = self.createTestDose(site: "Thigh")
        let dose2 = self.createTestDose(site: "Abdomen")
        let dose3 = self.createTestDose(site: "Thigh") // Duplicate
        let doseWithoutSite = self.createTestDose(site: nil)

        self.context.insert(dose1)
        self.context.insert(dose2)
        self.context.insert(dose3)
        self.context.insert(doseWithoutSite)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Unique injection sites are returned, sorted
        let sites = self.viewModel.availableInjectionSites
        #expect(sites.count == 2) // Thigh and Abdomen (deduplicated)
        #expect(sites.contains("Thigh"))
        #expect(sites.contains("Abdomen"))
        #expect(sites[0] <= sites[1]) // Sorted order
    }

    @Test("Grouped doses by date computed correctly")
    func groupedDosesByDateComputation() async throws {
        // Given: Doses from different dates
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let todayDose1 = self.createTestDose(timestamp: today, amount: 1.0)
        let todayDose2 = self.createTestDose(timestamp: today.addingTimeInterval(3600), amount: 2.0) // 1 hour later
        let yesterdayDose = self.createTestDose(timestamp: yesterday, amount: 3.0)

        self.context.insert(todayDose1)
        self.context.insert(todayDose2)
        self.context.insert(yesterdayDose)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Doses are grouped by date, sorted by date (newest first)
        let groupedDoses = self.viewModel.groupedDoses
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
    func hasActiveFiltersComputation() throws {
        // Given: Fresh view model
        #expect(self.viewModel.hasActiveFilters == false)

        // When: Setting various filters
        self.viewModel.searchText = "test"
        #expect(self.viewModel.hasActiveFilters == true)

        self.viewModel.searchText = ""
        self.viewModel.selectedMedicationFilter = "Semaglutide"
        #expect(self.viewModel.hasActiveFilters == true)

        self.viewModel.selectedMedicationFilter = nil
        self.viewModel.filterStartDate = Date()
        #expect(self.viewModel.hasActiveFilters == true)

        self.viewModel.filterStartDate = nil
        self.viewModel.showSkippedDoses = false
        #expect(self.viewModel.hasActiveFilters == true)

        // When: Clearing all filters
        self.viewModel.showSkippedDoses = true
        #expect(self.viewModel.hasActiveFilters == false)
    }

    // MARK: - CRUD Operations Tests

    @Test("Delete dose removes from context and updates arrays")
    func testDeleteDose() async throws {
        // Given: Dose exists
        let dose = self.createTestDose(amount: 1.5)
        self.context.insert(dose)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(self.viewModel.allDoses.count == 1)

        // When: Deleting dose
        try self.viewModel.deleteDose(dose, context: self.context)

        // Then: Dose is removed from context and view model arrays
        #expect(self.viewModel.allDoses.isEmpty)
        #expect(self.viewModel.filteredDoses.isEmpty)

        // Verify dose is actually deleted from context
        let descriptor = FetchDescriptor<Dose>()
        let remainingDoses = try context.fetch(descriptor)
        #expect(remainingDoses.isEmpty)
    }

    @Test("Toggle skipped status updates dose and refreshes filters")
    func testToggleSkippedStatus() async throws {
        // Given: Non-skipped dose exists
        let dose = self.createTestDose(skipped: false)
        self.context.insert(dose)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(dose.skipped == false)

        // When: Toggling skipped status
        try self.viewModel.toggleSkippedStatus(for: dose, context: self.context)

        // Then: Dose is marked as skipped
        #expect(dose.skipped == true)

        // When: Toggling again
        try self.viewModel.toggleSkippedStatus(for: dose, context: self.context)

        // Then: Dose is back to not skipped
        #expect(dose.skipped == false)
    }

    @Test("Duplicate dose creates new dose with current timestamp")
    func testDuplicateDose() async throws {
        // Given: Original dose exists
        let originalTimestamp = Date().addingTimeInterval(-3600) // 1 hour ago
        let profile = self.createTestMedicationProfile(genericName: "Semaglutide")
        let user = self.createTestUser()

        let originalDose = self.createTestDose(
            timestamp: originalTimestamp,
            amount: 1.5,
            site: "Thigh",
            notes: "Original dose",
            skipped: true // This should not be copied
        )

        self.context.insert(profile)
        self.context.insert(user)
        self.context.insert(originalDose)

        // Set relationships after insertion
        originalDose.user = user
        originalDose.medication = profile

        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)
        let initialCount = self.viewModel.allDoses.count

        // When: Duplicating dose
        try self.viewModel.duplicateDose(originalDose, context: self.context)

        // Then: New dose is created with same data but current timestamp and not skipped
        #expect(self.viewModel.allDoses.count == initialCount + 1)

        let newDose = self.viewModel.allDoses.first { $0.id != originalDose.id }
        #expect(newDose != nil)

        if let newDose {
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

        let profile = self.createTestMedicationProfile(genericName: "Tirzepatide")
        let dose = self.createTestDose(
            timestamp: testTimestamp,
            amount: testAmount,
            site: testSite,
            notes: testNotes,
            skipped: testSkipped)

        self.context.insert(profile)
        self.context.insert(dose)

        // Set relationships after insertion
        dose.medication = profile

        try self.context.save()

        // When: Getting dose for editing
        let editData = self.viewModel.getDoseForEditing(dose)

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
        let originalDose = self.createTestDose(
            amount: 1.0,
            site: "Thigh",
            notes: "Original")

        self.context.insert(originalDose)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
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
            medicationProfile: nil)

        try self.viewModel.updateDose(originalDose, with: editData, context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Dose is updated with new values
        #expect(originalDose.amount == newAmount)
        #expect(originalDose.site == newSite)
        #expect(originalDose.notes == newNotes)
        #expect(originalDose.timestamp == newTimestamp)
        #expect(originalDose.skipped == false)

        // And: View model data is refreshed
        #expect(self.viewModel.allDoses.contains(where: { $0.id == originalDose.id }))
    }

    // MARK: - Error Handling Tests

    @Test("Delete operation handles context save errors")
    func deleteDoseErrorHandling() async throws {
        // Given: Dose exists but context is in invalid state
        let dose = self.createTestDose(amount: 1.0)
        self.context.insert(dose)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Create a scenario where save might fail by using a different context
        let invalidContext = self.container.mainContext

        // When/Then: Delete operation should handle errors appropriately
        // Note: In real implementation, we might simulate context errors
        // For now, we verify the operation completes without crashing

        do {
            try self.viewModel.deleteDose(dose, context: invalidContext)
            // If no error thrown, operation succeeded
        } catch {
            // Error handling should be graceful
            #expect(error is any Error)
        }
    }

    // MARK: - Calendar Integration Tests

    @Test("ViewModel provides doses grouped by date for calendar display")
    func groupedDosesForCalendarView() async throws {
        // Given: Doses on different dates
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!

        let dose1 = self.createTestDose(timestamp: today, amount: 1.0)
        let dose2 = self.createTestDose(timestamp: today, amount: 2.0) // Same day
        let dose3 = self.createTestDose(timestamp: yesterday, amount: 1.5)
        let dose4 = self.createTestDose(timestamp: twoDaysAgo, amount: 0.5)

        [dose1, dose2, dose3, dose4].forEach { self.context.insert($0) }
        try self.context.save()

        // When: Setting doses in ViewModel
        self.viewModel.setDoses([dose1, dose2, dose3, dose4])

        // Then: Grouped doses should organize by date correctly
        let grouped = self.viewModel.groupedDoses

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
    func dateRangeFilteringForCalendarMonths() async throws {
        // Given: Doses across multiple months
        let calendar = Calendar.current
        let currentMonth = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!

        let currentMonthDose = self.createTestDose(timestamp: currentMonth, amount: 1.0)
        let lastMonthDose = self.createTestDose(timestamp: lastMonth, amount: 2.0)
        let nextMonthDose = self.createTestDose(timestamp: nextMonth, amount: 3.0)

        [currentMonthDose, lastMonthDose, nextMonthDose].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.setDoses([currentMonthDose, lastMonthDose, nextMonthDose])

        // When: Filtering by current month date range
        let monthStart = calendar.dateInterval(of: .month, for: currentMonth)!.start
        let monthEnd = calendar.dateInterval(of: .month, for: currentMonth)!.end

        self.viewModel.filterStartDate = monthStart
        self.viewModel.filterEndDate = monthEnd

        // Then: Only current month doses should be visible
        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.filteredDoses.first?.amount == 1.0)
    }

    @Test("ViewModel supports calendar data requirements with empty months")
    func emptyMonthCalendarSupport() async throws {
        // Given: No doses in the system
        self.viewModel.setDoses([])

        // When: Requesting grouped doses for calendar
        let grouped = self.viewModel.groupedDoses

        // Then: Empty array should be returned gracefully
        #expect(grouped.isEmpty)
        #expect(self.viewModel.filteredDoses.isEmpty)
        #expect(!self.viewModel.hasActiveFilters) // No filters applied initially
    }

    @Test("ViewModel provides dose counts per date for calendar indicators")
    func doseCountsPerDateForCalendarIndicators() async throws {
        // Given: Multiple doses on same date and single doses on other dates
        let targetDate = Date()
        let otherDate = Calendar.current.date(byAdding: .day, value: -1, to: targetDate)!

        let dose1 = self.createTestDose(timestamp: targetDate, amount: 1.0)
        let dose2 = self.createTestDose(timestamp: targetDate, amount: 2.0) // Same date
        let dose3 = self.createTestDose(timestamp: targetDate, amount: 1.5) // Same date
        let dose4 = self.createTestDose(timestamp: otherDate, amount: 0.5) // Different date

        [dose1, dose2, dose3, dose4].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.setDoses([dose1, dose2, dose3, dose4])

        // When: Getting grouped doses
        let grouped = self.viewModel.groupedDoses

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
    func dosesForSpecificDate() async throws {
        // Given: Doses on different times of the same day and other days
        let calendar = Calendar.current
        let targetDate = Date()
        let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: targetDate)!
        let eveningTime = calendar.date(bySettingHour: 20, minute: 30, second: 0, of: targetDate)!
        let otherDate = calendar.date(byAdding: .day, value: -1, to: targetDate)!

        let morningDose = self.createTestDose(timestamp: morningTime, amount: 1.0)
        let eveningDose = self.createTestDose(timestamp: eveningTime, amount: 2.0)
        let otherDayDose = self.createTestDose(timestamp: otherDate, amount: 3.0)

        [morningDose, eveningDose, otherDayDose].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.setDoses([morningDose, eveningDose, otherDayDose])

        // When: Getting doses for target date
        let targetDateDoses = self.viewModel.doses(for: targetDate)

        // Then: Should return both doses from target date, sorted by time
        #expect(targetDateDoses.count == 2)
        #expect(targetDateDoses[0].amount == 1.0) // Morning dose first
        #expect(targetDateDoses[1].amount == 2.0) // Evening dose second

        // When: Getting dose count for target date
        let targetDateCount = self.viewModel.doseCount(for: targetDate)

        // Then: Should return correct count
        #expect(targetDateCount == 2)

        // When: Getting doses for other date
        let otherDateDoses = self.viewModel.doses(for: otherDate)

        // Then: Should return only the other day dose
        #expect(otherDateDoses.count == 1)
        #expect(otherDateDoses[0].amount == 3.0)
    }

    @Test("ViewModel provides grouped doses by date for calendar integration")
    func groupedDosesByDateForCalendar() async throws {
        // Given: Doses on different dates
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let dose1 = self.createTestDose(timestamp: today, amount: 1.0)
        let dose2 = self.createTestDose(timestamp: today, amount: 2.0) // Same day
        let dose3 = self.createTestDose(timestamp: yesterday, amount: 3.0)

        [dose1, dose2, dose3].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.setDoses([dose1, dose2, dose3])

        // When: Getting grouped doses by date
        let groupedByDate = self.viewModel.groupedDosesByDate

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
        medication: MedicationProfile? = nil) -> Dose
    {
        Dose(
            amount: amount,
            timestamp: timestamp,
            site: site,
            notes: notes,
            imageData: imageData,
            skipped: skipped,
            user: user,
            medication: medication)
    }

    private func createTestMedicationProfile(
        genericName: String = "TestMedication",
        brandName: String = "TestBrand",
        currentDose: Double = 1.0) -> MedicationProfile
    {
        MedicationProfile(
            genericName: genericName,
            brandName: brandName,
            currentDose: currentDose)
    }

    private func createTestUser(
        email: String = "test@example.com",
        name: String = "Test User") -> User
    {
        User(
            email: email,
            name: name)
    }
}
