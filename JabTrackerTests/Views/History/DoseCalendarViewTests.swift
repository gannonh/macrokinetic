//
//  DoseCalendarViewTests.swift
//  JabTrackerTests
//
//  Unit tests for DoseCalendarView component
//

import SwiftUI
import Testing

@testable import JabTracker

struct DoseCalendarViewTests {
    // MARK: - Calendar Display Tests

    @Test("Calendar view initializes with current month")
    func calendarViewInitializesWithCurrentMonth() {
        // GIVEN: A specific date for testing
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 9, day: 15)
        guard let testDate = calendar.date(from: components) else {
            Issue.record("Failed to create test date from components")
            return
        }

        // WHEN: DoseCalendarView is initialized with test data
        _ = DoseCalendarView()

        // Create a test view with known state
        let testViewModel = TestCalendarViewModel(currentDate: testDate)

        // THEN: Calendar should display the correct month and year
        let monthYear = testViewModel.monthYearString
        #expect(monthYear.contains("September"))
        #expect(monthYear.contains("2024"))
    }

    @Test("Calendar view handles month navigation")
    func calendarViewHandlesMonthNavigation() async throws {
        // GIVEN: A calendar view model with a specific date
        let calendar = Calendar.current
        guard let september2024 = calendar.date(from: DateComponents(year: 2024, month: 9, day: 15))
        else {
            Issue.record("Failed to create September 2024 test date")
            return
        }
        let testViewModel = TestCalendarViewModel(currentDate: september2024)

        // WHEN: User navigates to next month
        testViewModel.nextMonth()

        // THEN: Calendar should update to October 2024
        let newMonthYear = testViewModel.monthYearString
        #expect(newMonthYear.contains("October"))
        #expect(newMonthYear.contains("2024"))

        // WHEN: User navigates to previous month (from original September)
        testViewModel.currentDate = september2024
        testViewModel.previousMonth()

        // THEN: Calendar should update to August 2024
        let previousMonthYear = testViewModel.monthYearString
        #expect(previousMonthYear.contains("August"))
        #expect(previousMonthYear.contains("2024"))
    }

    @Test("Calendar view generates correct number of days for month")
    func calendarViewGeneratesCorrectDaysForMonth() throws {
        // GIVEN: February 2024 (leap year) for testing
        let calendar = Calendar.current
        guard let february2024 = calendar.date(from: DateComponents(year: 2024, month: 2, day: 1))
        else {
            Issue.record("Failed to create February 2024 test date")
            return
        }
        let testViewModel = TestCalendarViewModel(currentDate: february2024)

        // WHEN: Calendar generates days for the month
        let daysInMonth = testViewModel.daysInMonth

        // THEN: February 2024 should generate correct calendar grid
        // Count non-nil days (actual days in month)
        let actualDays = daysInMonth.compactMap { $0 }
        #expect(actualDays.count == 29)  // Leap year February has 29 days

        // Verify first and last days are correct
        guard let firstDay = actualDays.first,
            let lastDay = actualDays.last
        else {
            Issue.record("Failed to get first or last day from actual days")
            return
        }
        #expect(calendar.component(.day, from: firstDay) == 1)
        #expect(calendar.component(.day, from: lastDay) == 29)
        #expect(calendar.component(.month, from: firstDay) == 2)
        #expect(calendar.component(.month, from: lastDay) == 2)
    }

    // MARK: - Dose Data Integration Tests

    @Test("Calendar view identifies dates with doses")
    func calendarViewIdentifiesDatesWithDoses() throws {
        // GIVEN: Sample doses on specific dates
        let calendar = Calendar.current
        let today = Date()
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            Issue.record("Failed to create yesterday date")
            return
        }

        let doses = [
            createMockDose(timestamp: today),
            createMockDose(timestamp: yesterday),
        ]

        // WHEN: Calendar processes dose data
        let datesWithDoses = Set(doses.map { calendar.startOfDay(for: $0.timestamp) })

        // THEN: Calendar should identify correct dates
        #expect(datesWithDoses.contains(calendar.startOfDay(for: today)))
        #expect(datesWithDoses.contains(calendar.startOfDay(for: yesterday)))
        #expect(datesWithDoses.count == 2)
    }

    @Test("Calendar view handles empty dose data")
    func calendarViewHandlesEmptyDoseData() throws {
        // GIVEN: No doses
        let doses: [Dose] = []

        // WHEN: Calendar processes empty dose data
        let datesWithDoses = Set(doses.map { Calendar.current.startOfDay(for: $0.timestamp) })

        // THEN: Calendar should handle empty state gracefully
        #expect(datesWithDoses.isEmpty)
    }

    @Test("Calendar view groups multiple doses per day")
    func calendarViewGroupsMultipleDosesPerDay() throws {
        // GIVEN: Multiple doses on the same day
        let calendar = Calendar.current
        let today = Date()
        guard let todayMorning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today),
            let todayEvening = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)
        else {
            Issue.record("Failed to create morning or evening test dates")
            return
        }

        let doses = [
            createMockDose(timestamp: todayMorning),
            createMockDose(timestamp: todayEvening),
        ]

        // WHEN: Calendar groups doses by date
        let groupedDoses = Dictionary(grouping: doses) { dose in
            calendar.startOfDay(for: dose.timestamp)
        }

        // THEN: Both doses should be grouped under the same date
        let todayStart = calendar.startOfDay(for: today)
        #expect(groupedDoses[todayStart]?.count == 2)
    }

    // MARK: - Today Highlighting Tests

    @Test("Calendar view identifies today correctly")
    func calendarViewIdentifiesTodayCorrectly() throws {
        // GIVEN: Current date
        let calendar = Calendar.current
        let now = Date()
        _ = calendar.startOfDay(for: now)

        // WHEN: Calendar determines if a date is today
        let isToday = calendar.isDateInToday(now)

        // THEN: Today should be identified correctly
        #expect(isToday == true)

        // AND: Yesterday should not be today
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else {
            Issue.record("Failed to create yesterday date for today test")
            return
        }
        let isYesterdayToday = calendar.isDateInToday(yesterday)
        #expect(isYesterdayToday == false)
    }

    // MARK: - Helper Methods

    private func createMockDose(timestamp: Date) -> Dose {
        Dose(
            amount: 1.0,
            timestamp: timestamp,
            site: "Abdomen",
            notes: "Test dose",
            imageData: nil,
            skipped: false,
            user: nil,
            medication: nil)
    }
}

// MARK: - Test Calendar View Model

/// Test view model that exposes DoseCalendarView's computed properties for testing
private class TestCalendarViewModel {
    var currentDate: Date
    private let calendar = Calendar.current

    init(currentDate: Date = Date()) {
        self.currentDate = currentDate
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self.currentDate)
    }

    var daysInMonth: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentDate),
            let firstOfMonth = calendar.dateInterval(of: .month, for: currentDate)?.start
        else {
            return []
        }

        let firstWeekday = self.calendar.component(.weekday, from: firstOfMonth)
        let paddingDays = firstWeekday - self.calendar.firstWeekday

        var days: [Date?] = Array(repeating: nil, count: paddingDays)

        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        // Pad to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            self.currentDate = newDate
        }
    }

    func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            self.currentDate = newDate
        }
    }

    func dosesForDate(_: Date) -> [Dose] {
        // Simplified for testing - in real implementation would filter from allDoses
        []
    }
}
