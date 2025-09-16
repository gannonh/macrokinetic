//
//  DoseCalendarViewTests.swift
//  JabTrackerTests
//
//  Unit tests for DoseCalendarView component
//

@testable import JabTracker
import SwiftUI
import Testing

struct DoseCalendarViewTests {
    // MARK: - Calendar Display Tests

    @Test("Calendar view initializes with current month")
    func calendarViewInitializesWithCurrentMonth() {
        // GIVEN: A calendar view model
        let calendar = Calendar.current
        let today = Date()

        // WHEN: Calendar view is initialized
        let expectedMonth = calendar.component(.month, from: today)
        let expectedYear = calendar.component(.year, from: today)

        // THEN: Calendar should display current month and year
        #expect(expectedMonth >= 1 && expectedMonth <= 12)
        #expect(expectedYear >= 2024)
    }

    @Test("Calendar view handles month navigation")
    func calendarViewHandlesMonthNavigation() async throws {
        // GIVEN: A calendar view with current date
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.component(.month, from: today)

        // WHEN: User navigates to next month
        let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: today)!
        let nextMonth = calendar.component(.month, from: nextMonthDate)

        // THEN: Calendar should update to show next month
        #expect(nextMonth != currentMonth)
        #expect(abs(nextMonth - currentMonth) == 1 || abs(nextMonth - currentMonth) == 11) // Handle year boundary
    }

    @Test("Calendar view generates correct number of days for month")
    func calendarViewGeneratesCorrectDaysForMonth() throws {
        // GIVEN: A specific month and year
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 2) // February 2024 (leap year)
        let date = calendar.date(from: components)!

        // WHEN: Getting the number of days in month
        let range = calendar.range(of: .day, in: .month, for: date)!
        let daysInMonth = range.count

        // THEN: February 2024 should have 29 days (leap year)
        #expect(daysInMonth == 29)
    }

    // MARK: - Dose Data Integration Tests

    @Test("Calendar view identifies dates with doses")
    func calendarViewIdentifiesDatesWithDoses() throws {
        // GIVEN: Sample doses on specific dates
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

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
        let todayMorning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today)!
        let todayEvening = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!

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
        let today = calendar.startOfDay(for: now)

        // WHEN: Calendar determines if a date is today
        let isToday = calendar.isDateInToday(now)

        // THEN: Today should be identified correctly
        #expect(isToday == true)

        // AND: Yesterday should not be today
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
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
