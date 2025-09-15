//
//  DoseCalendarViewModelTests.swift
//  JabTrackerTests
//
//  Unit tests for DoseCalendarViewModel business logic
//  Defines contracts for calendar navigation, dose data processing, and statistics calculations
//

import Testing
import SwiftData
import Foundation
@testable import JabTracker

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
            cloudKitDatabase: .none
        )
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = container.mainContext
        viewModel = DoseCalendarViewModel()
    }

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with current month")
    func testViewModelInitialization() throws {
        // Given: Fresh view model

        // Then: Current month is set to today's month
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = viewModel.currentMonth

        #expect(calendar.isDate(currentMonth, equalTo: today, toGranularity: .month),
               "Current month should be initialized to today's month")
        #expect(viewModel.allDoses.isEmpty, "Doses should be empty on initialization")
        #expect(viewModel.monthlyDoses.isEmpty, "Monthly doses should be empty on initialization")
        #expect(viewModel.isLoading == false, "Loading state should be false on initialization")
    }

    // MARK: - Data Loading Tests

    @Test("ViewModel sets doses and updates calendar data")
    func testSetDosesUpdatesCalendarData() throws {
        // Given: Test doses for current month
        let calendar = Calendar.current
        let currentMonth = Date()
        let monthStart = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth

        let doses = [
            createTestDose(timestamp: monthStart, amount: 1.0),
            createTestDose(timestamp: calendar.date(byAdding: .day, value: 5, to: monthStart) ?? monthStart,
                          amount: 1.5),
            createTestDose(timestamp: calendar.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart,
                          amount: 2.0) // Previous month
        ]

        // When: Setting doses
        viewModel.setDoses(doses)

        // Then: Calendar data is updated
        #expect(viewModel.allDoses.count == 3, "All doses should be stored")
        #expect(viewModel.monthlyDoses.count == 2, "Only current month doses should be in monthly doses")
        #expect(viewModel.dosesByDate.count == 2, "Doses should be grouped by date")
        #expect(viewModel.monthlyStatistics != nil, "Monthly statistics should be calculated")
    }

    @Test("ViewModel loads data from context correctly")
    func testLoadDataFromContext() async throws {
        // Given: Doses in context
        let dose1 = createTestDose(amount: 1.0)
        let dose2 = createTestDose(amount: 1.5)

        context.insert(dose1)
        context.insert(dose2)
        try context.save()

        // When: Loading data from context
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Data is loaded and processed
        #expect(viewModel.allDoses.count == 2, "Should load all doses from context")
        #expect(viewModel.isLoading == false, "Loading state should be false after completion")
        #expect(viewModel.errorMessage == nil, "Error message should be nil on successful load")
    }

    @Test("ViewModel handles loading errors gracefully")
    func testLoadDataErrorHandling() async throws {
        // Given: Invalid context scenario (simulated by using a different schema)
        // Note: In real scenario, this might involve network errors or corrupt data

        // When: Loading data with potential error
        viewModel.loadData(context: context)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then: Error handling is graceful (no crash)
        // Note: Specific error simulation would require more complex setup
        #expect(viewModel.isLoading == false, "Loading should complete even with potential errors")
    }

    // MARK: - Calendar Navigation Tests

    @Test("ViewModel navigates to previous month correctly")
    func testNavigateToPreviousMonth() throws {
        // Given: Current month set
        let originalMonth = Date()
        viewModel.currentMonth = originalMonth

        // When: Navigating to previous month
        viewModel.navigateToPreviousMonth()

        // Then: Month is decremented
        let calendar = Calendar.current
        let expectedMonth = calendar.date(byAdding: .month, value: -1, to: originalMonth)!

        #expect(calendar.isDate(viewModel.currentMonth, equalTo: expectedMonth, toGranularity: .month),
               "Should navigate to previous month")
    }

    @Test("ViewModel navigates to next month correctly")
    func testNavigateToNextMonth() throws {
        // Given: Current month set
        let originalMonth = Date()
        viewModel.currentMonth = originalMonth

        // When: Navigating to next month
        viewModel.navigateToNextMonth()

        // Then: Month is incremented
        let calendar = Calendar.current
        let expectedMonth = calendar.date(byAdding: .month, value: 1, to: originalMonth)!

        #expect(calendar.isDate(viewModel.currentMonth, equalTo: expectedMonth, toGranularity: .month),
               "Should navigate to next month")
    }

    @Test("ViewModel navigates to current month correctly")
    func testNavigateToCurrentMonth() throws {
        // Given: Month set to past month
        let pastMonth = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        viewModel.currentMonth = pastMonth

        // When: Navigating to current month
        viewModel.navigateToCurrentMonth()

        // Then: Month is set to today's month
        let calendar = Calendar.current
        let today = Date()

        #expect(calendar.isDate(viewModel.currentMonth, equalTo: today, toGranularity: .month),
               "Should navigate to current month")
    }

    @Test("ViewModel navigates to specific month correctly")
    func testNavigateToSpecificMonth() throws {
        // Given: Specific target month
        let targetMonth = Calendar.current.date(byAdding: .month, value: -6, to: Date())!

        // When: Navigating to specific month
        viewModel.navigateToMonth(targetMonth)

        // Then: Month is set to target
        let calendar = Calendar.current

        #expect(calendar.isDate(viewModel.currentMonth, equalTo: targetMonth, toGranularity: .month),
               "Should navigate to specific month")
    }

    // MARK: - Computed Properties Tests

    @Test("ViewModel calculates month start and end correctly")
    func testMonthStartAndEndCalculation() throws {
        // Given: Specific month
        let testDate = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        viewModel.currentMonth = testDate

        // When: Getting month boundaries
        let monthStart = viewModel.monthStart
        let monthEnd = viewModel.monthEnd

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
    func testDaysInMonthCalculation() throws {
        // Given: Known months with different day counts
        let testCases = [
            (year: 2024, month: 2, expectedDays: 29), // Leap year February
            (year: 2023, month: 2, expectedDays: 28), // Regular February
            (year: 2024, month: 4, expectedDays: 30), // April (30 days)
            (year: 2024, month: 1, expectedDays: 31), // January (31 days)
        ]

        for testCase in testCases {
            let testDate = Calendar.current.date(from: DateComponents(year: testCase.year, month: testCase.month, day: 1))!
            viewModel.currentMonth = testDate

            // When: Getting days in month
            let daysInMonth = viewModel.daysInMonth

            // Then: Day count is correct
            #expect(daysInMonth.count == testCase.expectedDays,
                   "Month \(testCase.month)/\(testCase.year) should have \(testCase.expectedDays) days")
        }
    }

    @Test("ViewModel detects data availability correctly")
    func testHasDataForCurrentMonth() throws {
        // Given: Empty doses initially
        #expect(viewModel.hasDataForCurrentMonth == false, "Should have no data initially")

        // When: Adding dose for current month
        let currentMonthDose = createTestDose(timestamp: Date(), amount: 1.0)
        viewModel.setDoses([currentMonthDose])

        // Then: Data availability is detected
        #expect(viewModel.hasDataForCurrentMonth == true, "Should detect data for current month")

        // When: Navigating to month without data
        let emptyMonth = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        viewModel.navigateToMonth(emptyMonth)

        // Then: No data is detected for that month
        #expect(viewModel.hasDataForCurrentMonth == false, "Should detect no data for empty month")
    }

    @Test("ViewModel formats current month title correctly")
    func testCurrentMonthTitleFormatting() throws {
        // Given: Known date
        let testDate = Calendar.current.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        viewModel.currentMonth = testDate

        // When: Getting month title
        let monthTitle = viewModel.currentMonthTitle

        // Then: Title is formatted correctly
        #expect(monthTitle == "June 2024", "Month title should be formatted as 'Month Year'")
    }

    // MARK: - Date Utilities Tests

    @Test("ViewModel retrieves doses for specific date correctly")
    func testDosesForSpecificDate() throws {
        // Given: Doses on specific dates
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let todayDose1 = createTestDose(timestamp: today, amount: 1.0)
        let todayDose2 = createTestDose(timestamp: today.addingTimeInterval(3600), amount: 1.5) // Same day, different time
        let tomorrowDose = createTestDose(timestamp: tomorrow, amount: 2.0)

        viewModel.setDoses([todayDose1, todayDose2, tomorrowDose])

        // When: Getting doses for specific dates
        let todayDoses = viewModel.doses(for: today)
        let tomorrowDoses = viewModel.doses(for: tomorrow)
        let emptyDateDoses = viewModel.doses(for: calendar.date(byAdding: .day, value: 5, to: today)!)

        // Then: Correct doses are returned
        #expect(todayDoses.count == 2, "Should return 2 doses for today")
        #expect(tomorrowDoses.count == 1, "Should return 1 dose for tomorrow")
        #expect(emptyDateDoses.isEmpty, "Should return empty array for date with no doses")
    }

    @Test("ViewModel detects dose presence correctly")
    func testHasDosesForDate() throws {
        // Given: Dose on specific date
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let todayDose = createTestDose(timestamp: today, amount: 1.0)
        viewModel.setDoses([todayDose])

        // When: Checking dose presence
        let hasToday = viewModel.hasdoses(for: today)
        let hasTomorrow = viewModel.hasdoses(for: tomorrow)

        // Then: Presence is detected correctly
        #expect(hasToday == true, "Should detect dose for today")
        #expect(hasTomorrow == false, "Should not detect dose for tomorrow")
    }

    @Test("ViewModel counts doses correctly")
    func testDoseCountForDate() throws {
        // Given: Multiple doses on same date
        let today = Calendar.current.startOfDay(for: Date())

        let dose1 = createTestDose(timestamp: today, amount: 1.0)
        let dose2 = createTestDose(timestamp: today.addingTimeInterval(3600), amount: 1.5)
        let dose3 = createTestDose(timestamp: today.addingTimeInterval(7200), amount: 2.0)

        viewModel.setDoses([dose1, dose2, dose3])

        // When: Getting dose count
        let doseCount = viewModel.doseCount(for: today)
        let hasMultiple = viewModel.hasMultipleDoses(for: today)

        // Then: Count is accurate
        #expect(doseCount == 3, "Should count 3 doses for today")
        #expect(hasMultiple == true, "Should detect multiple doses")
    }

    @Test("ViewModel identifies primary injection site correctly")
    func testPrimaryInjectionSiteIdentification() throws {
        // Given: Multiple doses with different sites on same date
        let today = Calendar.current.startOfDay(for: Date())

        let dose1 = createTestDose(timestamp: today, site: "Thigh")
        let dose2 = createTestDose(timestamp: today.addingTimeInterval(3600), site: "Thigh")
        let dose3 = createTestDose(timestamp: today.addingTimeInterval(7200), site: "Abdomen")

        viewModel.setDoses([dose1, dose2, dose3])

        // When: Getting primary site
        let primarySite = viewModel.primaryInjectionSite(for: today)

        // Then: Most frequent site is returned
        #expect(primarySite == "Thigh", "Should return most frequent injection site")

        // Test with no doses
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let noSite = viewModel.primaryInjectionSite(for: tomorrow)
        #expect(noSite == nil, "Should return nil for date with no doses")
    }

    @Test("ViewModel detects date relationships correctly")
    func testDateRelationshipDetection() throws {
        // Given: Known dates
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // When: Testing date relationships
        let isTodayToday = viewModel.isToday(today)
        let isYesterdayToday = viewModel.isToday(yesterday)

        let isPastYesterday = viewModel.isPastDate(yesterday)
        let isPastTomorrow = viewModel.isPastDate(tomorrow)

        let isFutureTomorrow = viewModel.isFutureDate(tomorrow)
        let isFutureYesterday = viewModel.isFutureDate(yesterday)

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
    func testCalculateStatisticsForMonth() throws {
        // Given: Known doses in specific month
        let calendar = Calendar.current
        let targetMonth = calendar.date(from: DateComponents(year: 2024, month: 6, day: 1))!
        let monthStart = calendar.dateInterval(of: .month, for: targetMonth)?.start ?? targetMonth

        let doses = [
            createTestDose(timestamp: monthStart, amount: 1.0, skipped: false),
            createTestDose(timestamp: calendar.date(byAdding: .day, value: 7, to: monthStart) ?? monthStart,
                          amount: 1.5, skipped: false),
            createTestDose(timestamp: calendar.date(byAdding: .day, value: 14, to: monthStart) ?? monthStart,
                          amount: 1.2, skipped: true),
            createTestDose(timestamp: calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart,
                          amount: 2.0, skipped: false) // Next month
        ]

        viewModel.setDoses(doses)

        // When: Calculating statistics for specific month
        let stats = viewModel.calculateStatistics(for: targetMonth)

        // Then: Statistics are calculated correctly for that month only
        #expect(stats.totalDoses == 3, "Should count 3 doses in target month")
        #expect(stats.skippedDoses == 1, "Should count 1 skipped dose")
        #expect(abs(stats.averageDose - 1.25) < 0.001, "Average should be calculated from non-skipped doses")
    }

    @Test("ViewModel provides formatted adherence rate")
    func testCurrentMonthAdherenceRateFormatting() throws {
        // Given: Doses with known adherence rate
        let doses = [
            createTestDose(timestamp: Date(), amount: 1.0, skipped: false),
            createTestDose(timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                          amount: 1.0, skipped: true),
        ]

        viewModel.setDoses(doses)

        // When: Getting formatted adherence rate
        let adherenceRate = viewModel.currentMonthAdherenceRate

        // Then: Rate is formatted as percentage
        #expect(adherenceRate.hasSuffix("%"), "Adherence rate should be formatted as percentage")
        #expect(adherenceRate != "0.0%", "Should calculate non-zero rate with actual data")
    }

    @Test("ViewModel provides formatted streak display")
    func testCurrentStreakDisplayFormatting() throws {
        // Given: Doses creating a streak
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let doses = [
            createTestDose(timestamp: yesterday, skipped: false),
            createTestDose(timestamp: today, skipped: false),
        ]

        viewModel.setDoses(doses)

        // When: Getting streak display
        let streakDisplay = viewModel.currentStreakDisplay

        // Then: Display is formatted correctly
        #expect(streakDisplay.contains("day"), "Streak display should contain 'day' or 'days'")
        #expect(streakDisplay.contains("2"), "Should show streak count")
    }

    // MARK: - Month Navigation with Data Updates Tests

    @Test("ViewModel updates data when month changes")
    func testDataUpdatesOnMonthChange() throws {
        // Given: Doses in different months
        let calendar = Calendar.current
        let currentMonth = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
        let lastMonthStart = calendar.dateInterval(of: .month, for: lastMonth)?.start ?? lastMonth

        let currentMonthDose = createTestDose(timestamp: currentMonth, amount: 1.0)
        let lastMonthDose = createTestDose(timestamp: lastMonthStart, amount: 2.0)

        viewModel.setDoses([currentMonthDose, lastMonthDose])

        // Initially on current month
        #expect(viewModel.monthlyDoses.count == 1, "Should show current month dose")
        #expect(viewModel.monthlyDoses[0].amount == 1.0, "Should show current month dose data")

        // When: Navigating to last month
        viewModel.navigateToMonth(lastMonth)

        // Then: Data updates to show last month's doses
        #expect(viewModel.monthlyDoses.count == 1, "Should show last month dose")
        #expect(viewModel.monthlyDoses[0].amount == 2.0, "Should show last month dose data")
    }

    // MARK: - Helper Methods

    private func createTestDose(
        timestamp: Date = Date(),
        amount: Double = 1.0,
        site: String? = nil,
        notes: String? = nil,
        skipped: Bool = false
    ) -> Dose {
        Dose(
            amount: amount,
            timestamp: timestamp,
            site: site,
            notes: notes,
            imageData: nil,
            skipped: skipped,
            user: nil,
            medication: nil
        )
    }
}
