//
//  DoseHistoryViewModelFilterTests.swift
//  JabTrackerTests
//
//  Search and filtering tests for DoseHistoryViewModel
//

import Foundation
import SwiftData
import Testing
import XCTest

@testable import JabTracker

@MainActor
struct DoseHistoryViewModelFilterTests {
    var container: ModelContainer
    var context: ModelContext
    var viewModel: DoseHistoryViewModel

    init() throws {
        // Create in-memory container for testing
        let schema = Schema([User.self, Dose.self, MedicationProfile.self, DoseTitration.self])
        let configuration = InMemoryTestStore.configuration(schema: schema)
        self.container = try ModelContainer(for: schema, configurations: [configuration])
        self.context = self.container.mainContext
        self.viewModel = DoseHistoryViewModel()
    }

    // MARK: - Search Tests

    @Test("ViewModel filters doses by search text")
    func searchFiltersDoses() async throws {
        // Given: Doses with different notes
        let dose1 = self.createTestDose(timestamp: Date(), amount: 1.0, notes: "Morning dose")
        let dose2 = self.createTestDose(
            timestamp: Date().addingTimeInterval(3600), amount: 2.0, notes: "Evening dose")
        let dose3 = self.createTestDose(
            timestamp: Date().addingTimeInterval(7200),
            amount: 1.5,
            notes: "Afternoon injection")

        [dose1, dose2, dose3].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Search for "morning"
        self.viewModel.searchText = "morning"
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should filter to matching dose
        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.filteredDoses.first?.notes == "Morning dose")
    }

    @Test("ViewModel search is case insensitive")
    func searchIsCaseInsensitive() async throws {
        // Given: Dose with mixed case notes
        let dose = self.createTestDose(timestamp: Date(), amount: 1.0, notes: "MORNING Dose")
        self.context.insert(dose)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Search with different case
        self.viewModel.searchText = "morning"
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should find the dose
        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.filteredDoses.first?.notes == "MORNING Dose")
    }

    @Test("ViewModel clears search results when search text is empty")
    func clearSearchResults() async throws {
        // Given: Multiple doses and active search
        let dose1 = self.createTestDose(timestamp: Date(), amount: 1.0, notes: "Morning dose")
        let dose2 = self.createTestDose(
            timestamp: Date().addingTimeInterval(3600), amount: 2.0, notes: "Evening dose")

        [dose1, dose2].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        self.viewModel.searchText = "morning"
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(self.viewModel.filteredDoses.count == 1)

        // When: Clear search
        self.viewModel.searchText = ""
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should show all doses
        #expect(self.viewModel.filteredDoses.count == 2)
    }

    // MARK: - Date Range Filtering Tests

    @Test("ViewModel filters doses by date range")
    func filterByDateRange() async throws {
        // Given: Doses on different dates
        let today = Date()
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: today))
        let tomorrow = try #require(Calendar.current.date(byAdding: .day, value: 1, to: today))

        let dose1 = self.createTestDose(timestamp: yesterday, amount: 1.0)
        let dose2 = self.createTestDose(timestamp: today, amount: 2.0)
        let dose3 = self.createTestDose(timestamp: tomorrow, amount: 3.0)

        [dose1, dose2, dose3].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Filter to today only
        self.viewModel.filterStartDate = Calendar.current.startOfDay(for: today)
        self.viewModel.filterEndDate = Calendar.current.startOfDay(for: today)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should show only today's dose
        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.filteredDoses.first?.amount == 2.0)
    }

    @Test("ViewModel filters by medication type")
    func filterByMedicationType() async throws {
        // Given: Doses with different medications
        let semaglutideProfile = self.createTestMedicationProfile(medication: .semaglutide)
        let tirzepatideProfile = self.createTestMedicationProfile(medication: .tirzepatide)

        self.context.insert(semaglutideProfile)
        self.context.insert(tirzepatideProfile)

        let dose1 = Dose(
            amount: 1.0,
            timestamp: Date(),
            site: "Thigh",
            notes: "Test dose",
            medication: semaglutideProfile)
        let dose2 = Dose(
            amount: 2.0,
            timestamp: Date().addingTimeInterval(3600),
            site: "Thigh",
            notes: "Test dose",
            medication: tirzepatideProfile)

        self.context.insert(dose1)
        self.context.insert(dose2)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Filter by semaglutide
        self.viewModel.selectedMedicationFilter = "semaglutide"
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should show only semaglutide dose
        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.filteredDoses.first?.amount == 1.0)
    }

    @Test("ViewModel filters by injection site")
    func filterByInjectionSite() async throws {
        // Given: Doses with different injection sites
        let dose1 = self.createTestDose(timestamp: Date(), amount: 1.0, site: "Thigh")
        let dose2 = self.createTestDose(
            timestamp: Date().addingTimeInterval(3600), amount: 2.0, site: "Arm")
        let dose3 = self.createTestDose(
            timestamp: Date().addingTimeInterval(7200), amount: 1.5, site: "Thigh")

        [dose1, dose2, dose3].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Filter by "Thigh"
        self.viewModel.selectedInjectionSiteFilter = "Thigh"
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should show only thigh injections
        #expect(self.viewModel.filteredDoses.count == 2)
        for dose in self.viewModel.filteredDoses {
            #expect(dose.site == "Thigh")
        }
    }

    @Test("ViewModel combines multiple filters")
    func combineMultipleFilters() async throws {
        // Given: Multiple doses with varying properties
        let today = Date()
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: today))

        let dose1 = self.createTestDose(
            timestamp: today, amount: 1.0, site: "Thigh", notes: "Morning dose")
        let dose2 = self.createTestDose(
            timestamp: today, amount: 2.0, site: "Arm", notes: "Evening dose")
        let dose3 = self.createTestDose(
            timestamp: yesterday, amount: 1.5, site: "Thigh", notes: "Yesterday dose")

        [dose1, dose2, dose3].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Apply multiple filters (today + thigh + search for "morning")
        self.viewModel.filterStartDate = Calendar.current.startOfDay(for: today)
        self.viewModel.filterEndDate = Calendar.current.startOfDay(for: today)
        self.viewModel.selectedInjectionSiteFilter = "Thigh"
        self.viewModel.searchText = "morning"
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should show only the dose matching all filters
        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.filteredDoses.first?.notes == "Morning dose")
    }

    @Test("ViewModel clears all filters")
    func clearAllFilters() async throws {
        // Given: Doses and active filters
        let dose1 = self.createTestDose(
            timestamp: Date(), amount: 1.0, site: "Thigh", notes: "Morning dose")
        let dose2 = self.createTestDose(
            timestamp: Date().addingTimeInterval(3600),
            amount: 2.0,
            site: "Arm",
            notes: "Evening dose")

        [dose1, dose2].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Apply filters
        self.viewModel.searchText = "morning"
        self.viewModel.selectedInjectionSiteFilter = "Thigh"
        self.viewModel.selectedMedicationFilter = "semaglutide"
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Clear all filters
        self.viewModel.clearAllFilters()
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Should show all doses and clear filter state
        #expect(self.viewModel.filteredDoses.count == 2)
        #expect(self.viewModel.searchText.isEmpty)
        #expect(self.viewModel.selectedInjectionSiteFilter == nil)
        #expect(self.viewModel.selectedMedicationFilter == nil)
        #expect(self.viewModel.filterStartDate == nil)
        #expect(self.viewModel.filterEndDate == nil)
        #expect(self.viewModel.filterAmountMin == nil)
        #expect(self.viewModel.filterAmountMax == nil)
    }

    // MARK: - Date Range Preset Tests

    @Test("ViewModel setDateRange today preset filters to today only")
    func setDateRangeTodayPreset() async throws {
        let today = Date()
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: today))

        let dose1 = self.createTestDose(timestamp: yesterday, amount: 1.0)
        let dose2 = self.createTestDose(timestamp: today, amount: 2.0)

        [dose1, dose2].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        self.viewModel.setDateRange(.today)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.filteredDoses.first?.amount == 2.0)
        #expect(self.viewModel.activeDateRangePreset == .today)
    }

    @Test("ViewModel setDateRange thisWeek preset uses Monday-first week")
    func setDateRangeThisWeekPreset() async throws {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let beforeWeek = try #require(calendar.date(byAdding: .day, value: -1, to: weekStart))

        let dose1 = self.createTestDose(timestamp: beforeWeek, amount: 1.0)
        let dose2 = self.createTestDose(timestamp: today, amount: 2.0)

        [dose1, dose2].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        self.viewModel.setDateRange(.thisWeek)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(self.viewModel.filteredDoses.contains { $0.amount == 2.0 })
        #expect(!self.viewModel.filteredDoses.contains { $0.amount == 1.0 })
        #expect(self.viewModel.activeDateRangePreset == .thisWeek)
    }

    @Test("ViewModel setDateRange thisMonth preset filters to current month")
    func setDateRangeThisMonthPreset() async throws {
        let calendar = Calendar.current
        let today = Date()
        let lastMonth = try #require(calendar.date(byAdding: .month, value: -1, to: today))

        let dose1 = self.createTestDose(timestamp: lastMonth, amount: 1.0)
        let dose2 = self.createTestDose(timestamp: today, amount: 2.0)

        [dose1, dose2].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        self.viewModel.setDateRange(.thisMonth)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.filteredDoses.first?.amount == 2.0)
        #expect(self.viewModel.activeDateRangePreset == .thisMonth)
    }

    // MARK: - Amount Range Filtering Tests

    @Test("ViewModel filters doses by amount range")
    func filterByAmountRange() async throws {
        let dose1 = self.createTestDose(timestamp: Date(), amount: 0.5)
        let dose2 = self.createTestDose(
            timestamp: Date().addingTimeInterval(3600), amount: 1.0)
        let dose3 = self.createTestDose(
            timestamp: Date().addingTimeInterval(7200), amount: 2.5)

        [dose1, dose2, dose3].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        self.viewModel.filterAmountMin = 0.75
        self.viewModel.filterAmountMax = 2.0
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(self.viewModel.isAmountFilterActive)
        #expect(self.viewModel.filteredDoses.count == 1)
        #expect(self.viewModel.filteredDoses.first?.amount == 1.0)
    }

    // MARK: - Active Filter Count Tests

    @Test("ViewModel activeFilterCount counts distinct active filters")
    func activeFilterCount() async throws {
        let dose = self.createTestDose(timestamp: Date(), amount: 1.0)
        self.context.insert(dose)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(self.viewModel.activeFilterCount == 0)

        self.viewModel.searchText = "test"
        #expect(self.viewModel.activeFilterCount == 1)

        self.viewModel.selectedMedicationFilter = "semaglutide"
        #expect(self.viewModel.activeFilterCount == 2)

        self.viewModel.setDateRange(.today)
        #expect(self.viewModel.activeFilterCount == 3)

        self.viewModel.showSkippedDoses = false
        #expect(self.viewModel.activeFilterCount == 4)

        self.viewModel.filterAmountMin = 0.5
        self.viewModel.filterAmountMax = 0.75
        #expect(self.viewModel.activeFilterCount == 5)

        self.viewModel.clearAllFilters()
        #expect(self.viewModel.activeFilterCount == 0)
    }

    // MARK: - Helper Methods

    private func createTestDose(
        timestamp: Date,
        amount: Double,
        site: String = "Thigh",
        notes: String = "Test dose"
    ) -> Dose {
        let medicationProfile = self.createTestMedicationProfile()
        self.context.insert(medicationProfile)

        return Dose(
            amount: amount,
            timestamp: timestamp,
            site: site,
            notes: notes,
            medication: medicationProfile)
    }

    private func createTestMedicationProfile(
        medication: Medication = .semaglutide,
        currentDose: Double = 1.0
    ) -> MedicationProfile {
        MedicationProfile(
            genericName: medication.rawValue,
            brandName: "Test Brand",
            currentDose: currentDose,
            startDate: Date(),
            medicationType: medication.rawValue)
    }

    private func createTestUser(name: String = "Test User", email: String = "test@example.com")
        -> User
    {
        User(
            email: email,
            name: name,
            appleUserId: "test-apple-id")
    }
}
