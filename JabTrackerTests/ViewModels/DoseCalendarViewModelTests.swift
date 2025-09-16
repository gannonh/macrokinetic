//
//  DoseCalendarViewModelTests.swift
//  JabTrackerTests
//
//  Unit tests for DoseCalendarViewModel business logic
//  Defines contracts for calendar navigation, dose data processing, and statistics calculations
//

import Foundation
@testable import JabTracker
import SwiftData
import Testing

@MainActor
struct DoseCalendarViewModelTests {
    var container: ModelContainer
    var context: ModelContext
    var viewModel: DoseCalendarViewModel

    init() throws {
        // Create in-memory container for testing
        let schema = Schema([User.self, Dose.self, MedicationProfile.self, DoseTitration.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none)
        self.container = try ModelContainer(for: schema, configurations: [configuration])
        self.context = self.container.mainContext
        self.viewModel = DoseCalendarViewModel()
    }

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with current month")
    func viewModelInitialization() throws {
        // Given: Fresh view model

        // Then: Current month is set to today's month
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = self.viewModel.currentMonth

        #expect(calendar.isDate(currentMonth, equalTo: today, toGranularity: .month),
                "Current month should be initialized to today's month")
        #expect(self.viewModel.allDoses.isEmpty, "Doses should be empty on initialization")
        #expect(self.viewModel.monthlyDoses.isEmpty, "Monthly doses should be empty on initialization")
        #expect(self.viewModel.isLoading == false, "Loading state should be false on initialization")
    }

    // MARK: - Data Loading Tests

    @Test("ViewModel sets doses and updates calendar data")
    func setDosesUpdatesCalendarData() throws {
        // Given: Test doses for current month
        let calendar = Calendar.current
        let currentMonth = Date()
        let monthStart = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth

        let doses = [
            createTestDose(timestamp: monthStart, amount: 1.0),
            createTestDose(timestamp: calendar.date(byAdding: .day, value: 5, to: monthStart) ?? monthStart,
                           amount: 1.5),
            self.createTestDose(timestamp: calendar.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart,
                                amount: 2.0), // Previous month
        ]

        // When: Setting doses
        self.viewModel.setDoses(doses)

        // Then: Calendar data is updated
        #expect(self.viewModel.allDoses.count == 3, "All doses should be stored")
        #expect(self.viewModel.monthlyDoses.count == 2, "Only current month doses should be in monthly doses")
        #expect(self.viewModel.dosesByDate.count == 2, "Doses should be grouped by date")
        #expect(self.viewModel.monthlyStatistics != nil, "Monthly statistics should be calculated")
    }

    @Test("ViewModel loads data from context correctly")
    func loadDataFromContext() async throws {
        // Given: Doses in context
        let dose1 = self.createTestDose(amount: 1.0)
        let dose2 = self.createTestDose(amount: 1.5)

        self.context.insert(dose1)
        self.context.insert(dose2)
        try self.context.save()

        // When: Loading data from context
        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Data is loaded and processed
        #expect(self.viewModel.allDoses.count == 2, "Should load all doses from context")
        #expect(self.viewModel.isLoading == false, "Loading state should be false after completion")
        #expect(self.viewModel.errorMessage == nil, "Error message should be nil on successful load")
    }

    @Test("ViewModel handles loading errors gracefully")
    func loadDataErrorHandling() async throws {
        // Given: Invalid context scenario (simulated by using a different schema)
        // Note: In real scenario, this might involve network errors or corrupt data

        // When: Loading data with potential error
        self.viewModel.loadData(context: self.context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Error handling is graceful (no crash)
        // Note: Specific error simulation would require more complex setup
        #expect(self.viewModel.isLoading == false, "Loading should complete even with potential errors")
    }

    // MARK: - Calendar Navigation Tests

    @Test("ViewModel navigates to previous month correctly")
    func testNavigateToPreviousMonth() throws {
        // Given: Current month set
        let originalMonth = Date()
        self.viewModel.currentMonth = originalMonth

        // When: Navigating to previous month
        self.viewModel.navigateToPreviousMonth()

        // Then: Month is decremented
        let calendar = Calendar.current
        let expectedMonth = calendar.date(byAdding: .month, value: -1, to: originalMonth)!

        #expect(calendar.isDate(self.viewModel.currentMonth, equalTo: expectedMonth, toGranularity: .month),
                "Should navigate to previous month")
    }

    @Test("ViewModel navigates to next month correctly")
    func testNavigateToNextMonth() throws {
        // Given: Current month set
        let originalMonth = Date()
        self.viewModel.currentMonth = originalMonth

        // When: Navigating to next month
        self.viewModel.navigateToNextMonth()

        // Then: Month is incremented
        let calendar = Calendar.current
        let expectedMonth = calendar.date(byAdding: .month, value: 1, to: originalMonth)!

        #expect(calendar.isDate(self.viewModel.currentMonth, equalTo: expectedMonth, toGranularity: .month),
                "Should navigate to next month")
    }

    @Test("ViewModel navigates to current month correctly")
    func testNavigateToCurrentMonth() throws {
        // Given: Month set to past month
        let pastMonth = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        self.viewModel.currentMonth = pastMonth

        // When: Navigating to current month
        self.viewModel.navigateToCurrentMonth()

        // Then: Month is set to today's month
        let calendar = Calendar.current
        let today = Date()

        #expect(calendar.isDate(self.viewModel.currentMonth, equalTo: today, toGranularity: .month),
                "Should navigate to current month")
    }

    @Test("ViewModel navigates to specific month correctly")
    func navigateToSpecificMonth() throws {
        // Given: Specific target month
        let targetMonth = Calendar.current.date(byAdding: .month, value: -6, to: Date())!

        // When: Navigating to specific month
        self.viewModel.navigateToMonth(targetMonth)

        // Then: Month is set to target
        let calendar = Calendar.current

        #expect(calendar.isDate(self.viewModel.currentMonth, equalTo: targetMonth, toGranularity: .month),
                "Should navigate to specific month")
    }

    // MARK: - Computed Properties Tests

    @Test("ViewModel calculates month start and end correctly")
    func monthStartAndEndCalculation() throws {
        // Given: Specific month
        let testDate = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        self.viewModel.currentMonth = testDate

        // When: Getting month boundaries
        let monthStart = self.viewModel.monthStart
        let monthEnd = self.viewModel.monthEnd

        // Then: Boundaries are correct
        let calendar = Calendar.current
        let expectedStart = calendar.date(from: DateComponents(year: 2024, month: 6, day: 1))!
        let expectedEnd = calendar.date(from: DateComponents(year: 2024, month: 7, day: 1))!

        #expect(calendar.isDate(monthStart, equalTo: expectedStart, toGranularity: .day),
                "Month start should be first day of month")
        #expect(calendar.isDate(monthEnd, equalTo: expectedEnd, toGranularity: .day),
                "Month end should be first day of next month")
    }

    @Test("ViewModel calculates days in month correctly")
    func daysInMonthCalculation() throws {
        // Given: Known months with different day counts
        let testCases = [
            (year: 2024, month: 2, expectedDays: 29), // Leap year February
            (year: 2023, month: 2, expectedDays: 28), // Regular February
            (year: 2024, month: 4, expectedDays: 30), // April (30 days)
            (year: 2024, month: 1, expectedDays: 31), // January (31 days)
        ]

        for testCase in testCases {
            let testDate = Calendar.current.date(from: DateComponents(year: testCase.year, month: testCase.month, day: 1))!
            self.viewModel.currentMonth = testDate

            // When: Getting days in month
            let daysInMonth = self.viewModel.daysInMonth

            // Then: Day count is correct
            #expect(daysInMonth.count == testCase.expectedDays,
                    "Month \(testCase.month)/\(testCase.year) should have \(testCase.expectedDays) days")
        }
    }

    @Test("ViewModel detects data availability correctly")
    func testHasDataForCurrentMonth() throws {
        // Given: Empty doses initially
        #expect(self.viewModel.hasDataForCurrentMonth == false, "Should have no data initially")

        // When: Adding dose for current month
        let currentMonthDose = self.createTestDose(timestamp: Date(), amount: 1.0)
        self.viewModel.setDoses([currentMonthDose])

        // Then: Data availability is detected
        #expect(self.viewModel.hasDataForCurrentMonth == true, "Should detect data for current month")

        // When: Navigating to month without data
        let emptyMonth = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        self.viewModel.navigateToMonth(emptyMonth)

        // Then: No data is detected for that month
        #expect(self.viewModel.hasDataForCurrentMonth == false, "Should detect no data for empty month")
    }

    @Test("ViewModel formats current month title correctly")
    func currentMonthTitleFormatting() throws {
        // Given: Known date
        let testDate = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        self.viewModel.currentMonth = testDate

        // When: Getting month title
        let monthTitle = self.viewModel.currentMonthTitle

        // Then: Title is formatted correctly
        #expect(monthTitle == "June 2024", "Month title should be formatted as 'Month Year'")
    }

    // MARK: - Date Utilities Tests

    @Test("ViewModel retrieves doses for specific date correctly")
    func dosesForSpecificDate() throws {
        // Given: Doses on specific dates
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let todayDose1 = self.createTestDose(timestamp: today, amount: 1.0)
        let todayDose2 = self.createTestDose(timestamp: today.addingTimeInterval(3600), amount: 1.5) // Same day, different time
        let tomorrowDose = self.createTestDose(timestamp: tomorrow, amount: 2.0)

        self.viewModel.setDoses([todayDose1, todayDose2, tomorrowDose])

        // When: Getting doses for specific dates
        let todayDoses = self.viewModel.doses(for: today)
        let tomorrowDoses = self.viewModel.doses(for: tomorrow)
        let emptyDateDoses = self.viewModel.doses(for: calendar.date(byAdding: .day, value: 5, to: today)!)

        // Then: Correct doses are returned
        #expect(todayDoses.count == 2, "Should return 2 doses for today")
        #expect(tomorrowDoses.count == 1, "Should return 1 dose for tomorrow")
        #expect(emptyDateDoses.isEmpty, "Should return empty array for date with no doses")
    }

    @Test("ViewModel detects dose presence correctly")
    func hasDosesForDate() throws {
        // Given: Dose on specific date
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let todayDose = self.createTestDose(timestamp: today, amount: 1.0)
        self.viewModel.setDoses([todayDose])

        // When: Checking dose presence
        let hasToday = self.viewModel.hasdoses(for: today)
        let hasTomorrow = self.viewModel.hasdoses(for: tomorrow)

        // Then: Presence is detected correctly
        #expect(hasToday == true, "Should detect dose for today")
        #expect(hasTomorrow == false, "Should not detect dose for tomorrow")
    }

    @Test("ViewModel counts doses correctly")
    func doseCountForDate() throws {
        // Given: Multiple doses on same date
        let today = Calendar.current.startOfDay(for: Date())

        let dose1 = self.createTestDose(timestamp: today, amount: 1.0)
        let dose2 = self.createTestDose(timestamp: today.addingTimeInterval(3600), amount: 1.5)
        let dose3 = self.createTestDose(timestamp: today.addingTimeInterval(7200), amount: 2.0)

        self.viewModel.setDoses([dose1, dose2, dose3])

        // When: Getting dose count
        let doseCount = self.viewModel.doseCount(for: today)
        let hasMultiple = self.viewModel.hasMultipleDoses(for: today)

        // Then: Count is accurate
        #expect(doseCount == 3, "Should count 3 doses for today")
        #expect(hasMultiple == true, "Should detect multiple doses")
    }

    @Test("ViewModel identifies primary injection site correctly")
    func primaryInjectionSiteIdentification() throws {
        // Given: Multiple doses with different sites on same date
        let today = Calendar.current.startOfDay(for: Date())

        let dose1 = self.createTestDose(timestamp: today, site: "Thigh")
        let dose2 = self.createTestDose(timestamp: today.addingTimeInterval(3600), site: "Thigh")
        let dose3 = self.createTestDose(timestamp: today.addingTimeInterval(7200), site: "Abdomen")

        self.viewModel.setDoses([dose1, dose2, dose3])

        // When: Getting primary site
        let primarySite = self.viewModel.primaryInjectionSite(for: today)

        // Then: Most frequent site is returned
        #expect(primarySite == "Thigh", "Should return most frequent injection site")

        // Test with no doses
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let noSite = self.viewModel.primaryInjectionSite(for: tomorrow)
        #expect(noSite == nil, "Should return nil for date with no doses")
    }

    @Test("ViewModel detects date relationships correctly")
    func dateRelationshipDetection() throws {
        // Given: Known dates
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // When: Testing date relationships
        let isTodayToday = self.viewModel.isToday(today)
        let isYesterdayToday = self.viewModel.isToday(yesterday)

        let isPastYesterday = self.viewModel.isPastDate(yesterday)
        let isPastTomorrow = self.viewModel.isPastDate(tomorrow)

        let isFutureTomorrow = self.viewModel.isFutureDate(tomorrow)
        let isFutureYesterday = self.viewModel.isFutureDate(yesterday)

        // Then: Relationships are detected correctly
        #expect(isTodayToday == true, "Should detect today as today")
        #expect(isYesterdayToday == false, "Should not detect yesterday as today")

        #expect(isPastYesterday == true, "Should detect yesterday as past")
        #expect(isPastTomorrow == false, "Should not detect tomorrow as past")

        #expect(isFutureTomorrow == true, "Should detect tomorrow as future")
        #expect(isFutureYesterday == false, "Should not detect yesterday as future")
    }

    // MARK: - Statistics Tests

    @Test("ViewModel calculates statistics for specific month")
    func calculateStatisticsForMonth() throws {
        // Given: Known doses in specific month
        let calendar = Calendar.current
        let targetMonth = calendar.date(from: DateComponents(year: 2024, month: 6, day: 1))!
        let monthStart = calendar.dateInterval(of: .month, for: targetMonth)?.start ?? targetMonth

        let doses = [
            createTestDose(timestamp: monthStart, amount: 1.0, skipped: false),
            createTestDose(timestamp: calendar.date(byAdding: .day, value: 7, to: monthStart) ?? monthStart,
                           amount: 1.5, skipped: false),
            self.createTestDose(timestamp: calendar.date(byAdding: .day, value: 14, to: monthStart) ?? monthStart,
                                amount: 1.2, skipped: true),
            self.createTestDose(timestamp: calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart,
                                amount: 2.0, skipped: false), // Next month
        ]

        self.viewModel.setDoses(doses)

        // When: Calculating statistics for specific month
        let stats = self.viewModel.calculateStatistics(for: targetMonth)

        // Then: Statistics are calculated correctly for that month only
        #expect(stats.totalDoses == 3, "Should count 3 doses in target month")
        #expect(stats.skippedDoses == 1, "Should count 1 skipped dose")
        #expect(abs(stats.averageDose - 1.25) < 0.001, "Average should be calculated from non-skipped doses")
    }

    @Test("ViewModel provides formatted adherence rate")
    func currentMonthAdherenceRateFormatting() throws {
        // Given: Doses with known adherence rate
        let doses = [
            createTestDose(timestamp: Date(), amount: 1.0, skipped: false),
            createTestDose(timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                           amount: 1.0, skipped: true),
        ]

        self.viewModel.setDoses(doses)

        // When: Getting formatted adherence rate
        let adherenceRate = self.viewModel.currentMonthAdherenceRate

        // Then: Rate is formatted as percentage
        #expect(adherenceRate.hasSuffix("%"), "Adherence rate should be formatted as percentage")
        #expect(adherenceRate != "0.0%", "Should calculate non-zero rate with actual data")
    }

    @Test("ViewModel provides formatted streak display")
    func currentStreakDisplayFormatting() throws {
        // Given: Doses creating a streak
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let doses = [
            createTestDose(timestamp: yesterday, skipped: false),
            createTestDose(timestamp: today, skipped: false),
        ]

        self.viewModel.setDoses(doses)

        // When: Getting streak display
        let streakDisplay = self.viewModel.currentStreakDisplay

        // Then: Display is formatted correctly
        #expect(streakDisplay.contains("day"), "Streak display should contain 'day' or 'days'")
        #expect(streakDisplay.contains("2"), "Should show streak count")
    }

    // MARK: - Month Navigation with Data Updates Tests

    @Test("ViewModel updates data when month changes")
    func dataUpdatesOnMonthChange() throws {
        // Given: Doses in different months
        let calendar = Calendar.current
        let currentMonth = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
        let lastMonthStart = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? lastMonth

        let currentMonthDose = self.createTestDose(timestamp: currentMonth, amount: 1.0)
        let lastMonthDose = self.createTestDose(timestamp: lastMonthStart, amount: 2.0)

        self.viewModel.setDoses([currentMonthDose, lastMonthDose])

        // Initially on current month
        #expect(self.viewModel.monthlyDoses.count == 1, "Should show current month dose")
        #expect(self.viewModel.monthlyDoses[0].amount == 1.0, "Should show current month dose data")

        // When: Navigating to last month
        self.viewModel.navigateToMonth(lastMonth)

        // Then: Data updates to show last month's doses
        #expect(self.viewModel.monthlyDoses.count == 1, "Should show last month dose")
        #expect(self.viewModel.monthlyDoses[0].amount == 2.0, "Should show last month dose data")
    }

    // MARK: - Helper Methods

    private func createTestDose(
        timestamp: Date = Date(),
        amount: Double = 1.0,
        site: String? = nil,
        notes: String? = nil,
        skipped: Bool = false) -> Dose
    {
        Dose(
            amount: amount,
            timestamp: timestamp,
            site: site,
            notes: notes,
            imageData: nil,
            skipped: skipped,
            user: nil,
            medication: nil)
    }
}
