//
//  DoseHistoryViewModelComputedTests.swift
//  JabTrackerTests
//
//  Computed properties tests for DoseHistoryViewModel
//

import Foundation
import SwiftData
import Testing
import XCTest

@testable import JabTracker

@MainActor
struct DoseHistoryViewModelComputedTests {
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

    // MARK: - Computed Properties Tests

    @Test("ViewModel provides available medications for filtering")
    func availableMedicationsForFiltering() async throws {
        // Given: Doses with different medications
        let semaglutideProfile = self.createTestMedicationProfile(medication: .semaglutide)
        let tirzepatideProfile = self.createTestMedicationProfile(medication: .tirzepatide)

        self.context.insert(semaglutideProfile)
        self.context.insert(tirzepatideProfile)

        let dose1 = Dose(amount: 1.0, timestamp: Date(), medication: semaglutideProfile)
        let dose2 = Dose(
            amount: 2.0, timestamp: Date().addingTimeInterval(3600), medication: tirzepatideProfile)

        self.context.insert(dose1)
        self.context.insert(dose2)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Request available medications
        let medications = self.viewModel.availableMedications

        // Then: Should include both medication types
        #expect(medications.contains("semaglutide"))
        #expect(medications.contains("tirzepatide"))
        #expect(medications.count == 2)
    }

    @Test("ViewModel provides available injection sites for filtering")
    func availableInjectionSitesForFiltering() async throws {
        // Given: Doses with different injection sites
        let dose1 = self.createTestDose(timestamp: Date(), amount: 1.0, site: "Thigh")
        let dose2 = self.createTestDose(
            timestamp: Date().addingTimeInterval(3600), amount: 2.0, site: "Arm")
        let dose3 = self.createTestDose(
            timestamp: Date().addingTimeInterval(7200), amount: 1.5, site: "Abdomen")

        [dose1, dose2, dose3].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Request available injection sites
        let sites = self.viewModel.availableInjectionSites

        // Then: Should include all unique sites
        #expect(sites.contains("Thigh"))
        #expect(sites.contains("Arm"))
        #expect(sites.contains("Abdomen"))
        #expect(sites.count == 3)
    }

    @Test("ViewModel indicates when filters are active")
    func hasActiveFilters() async throws {
        // Given: Loaded doses
        let dose = self.createTestDose(timestamp: Date(), amount: 1.0)
        self.context.insert(dose)
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: No filters applied
        #expect(self.viewModel.hasActiveFilters == false)

        // When: Apply search filter
        self.viewModel.searchText = "test"
        #expect(self.viewModel.hasActiveFilters == true)

        // When: Clear search but add site filter
        self.viewModel.searchText = ""
        self.viewModel.selectedInjectionSiteFilter = "Thigh"
        #expect(self.viewModel.hasActiveFilters == true)

        // When: Clear all filters
        self.viewModel.clearAllFilters()
        #expect(self.viewModel.hasActiveFilters == false)
    }

    @Test("ViewModel provides dose counts per date for calendar indicators")
    func doseCountsPerDateForCalendarIndicators() async throws {
        // Given: Multiple doses on same date and single doses on other dates
        let targetDate = Date()
        let otherDate = try #require(Calendar.current.date(byAdding: .day, value: -1, to: targetDate))

        let dose1 = self.createTestDose(timestamp: targetDate, amount: 1.0)
        let dose2 = self.createTestDose(timestamp: targetDate, amount: 2.0)  // Same date
        let dose3 = self.createTestDose(timestamp: targetDate, amount: 1.5)  // Same date
        let dose4 = self.createTestDose(timestamp: otherDate, amount: 0.5)  // Different date

        [dose1, dose2, dose3, dose4].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Request dose counts per date
        let doseCounts = self.viewModel.groupedDosesByDate

        // Then: Should group doses by date
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: targetDate)
        let otherDay = calendar.startOfDay(for: otherDate)

        #expect(doseCounts[targetDay]?.count == 3)
        #expect(doseCounts[otherDay]?.count == 1)
    }

    @Test("ViewModel provides doses for specific date")
    func dosesForSpecificDate() async throws {
        // Given: Doses on different times of the same day and other days
        let calendar = Calendar.current
        let targetDate = Date()
        let morningTime = try #require(
            calendar.date(bySettingHour: 8, minute: 0, second: 0, of: targetDate))
        let eveningTime = try #require(
            calendar.date(bySettingHour: 20, minute: 30, second: 0, of: targetDate))
        let otherDate = try #require(calendar.date(byAdding: .day, value: -1, to: targetDate))

        let morningDose = self.createTestDose(timestamp: morningTime, amount: 1.0)
        let eveningDose = self.createTestDose(timestamp: eveningTime, amount: 2.0)
        let otherDayDose = self.createTestDose(timestamp: otherDate, amount: 3.0)

        [morningDose, eveningDose, otherDayDose].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Request doses for target date
        let targetDay = calendar.startOfDay(for: targetDate)
        let dosesForDate = self.viewModel.groupedDosesByDate[targetDay] ?? []

        // Then: Should return only doses from that day
        #expect(dosesForDate.count == 2)
        #expect(dosesForDate.contains { $0.amount == 1.0 })
        #expect(dosesForDate.contains { $0.amount == 2.0 })
        #expect(!dosesForDate.contains { $0.amount == 3.0 })
    }

    @Test("ViewModel provides grouped doses by date for calendar")
    func groupedDosesByDateForCalendar() async throws {
        // Given: Doses on different dates
        let calendar = Calendar.current
        let today = Date()
        let yesterday = try #require(calendar.date(byAdding: .day, value: -1, to: today))

        let dose1 = self.createTestDose(timestamp: today, amount: 1.0)
        let dose2 = self.createTestDose(timestamp: today, amount: 2.0)  // Same day
        let dose3 = self.createTestDose(timestamp: yesterday, amount: 3.0)

        [dose1, dose2, dose3].forEach { self.context.insert($0) }
        try self.context.save()

        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // When: Request grouped doses
        let groupedDoses = self.viewModel.groupedDosesByDate

        // Then: Should group by calendar day
        let todayKey = calendar.startOfDay(for: today)
        let yesterdayKey = calendar.startOfDay(for: yesterday)

        #expect(groupedDoses.keys.count == 2)
        #expect(groupedDoses[todayKey]?.count == 2)
        #expect(groupedDoses[yesterdayKey]?.count == 1)
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
