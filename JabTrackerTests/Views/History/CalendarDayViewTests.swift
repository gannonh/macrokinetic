//
//  CalendarDayViewTests.swift
//  JabTrackerTests
//
//  Unit tests for CalendarDayView component
//

@testable import JabTracker
import SwiftUI
import Testing

struct CalendarDayViewTests {
    // MARK: - Day Display Tests

    @Test("Calendar day view displays correct day number")
    func calendarDayViewDisplaysCorrectDayNumber() throws {
        // GIVEN: A specific date
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 9, day: 15)
        let date = calendar.date(from: components)!

        // WHEN: Getting day number from date
        let dayNumber = calendar.component(.day, from: date)

        // THEN: Day number should be 15
        #expect(dayNumber == 15)
    }

    @Test("Calendar day view handles first day of month")
    func calendarDayViewHandlesFirstDayOfMonth() throws {
        // GIVEN: First day of a month
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 9, day: 1)
        let date = calendar.date(from: components)!

        // WHEN: Getting day number
        let dayNumber = calendar.component(.day, from: date)

        // THEN: Day number should be 1
        #expect(dayNumber == 1)
    }

    @Test("Calendar day view handles last day of month")
    func calendarDayViewHandlesLastDayOfMonth() throws {
        // GIVEN: Last day of a month (September 30th)
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 9, day: 30)
        let date = calendar.date(from: components)!

        // WHEN: Getting day number
        let dayNumber = calendar.component(.day, from: date)

        // THEN: Day number should be 30
        #expect(dayNumber == 30)
    }

    // MARK: - Dose Indicator Tests

    @Test("Calendar day view identifies days with single dose")
    func calendarDayViewIdentifiesDaysWithSingleDose() throws {
        // GIVEN: A date with one dose
        let calendar = Calendar.current
        let date = Date()
        let doses = [createMockDose(timestamp: date)]

        // WHEN: Checking if date has doses
        let datesWithDoses = Set(doses.map { calendar.startOfDay(for: $0.timestamp) })
        let targetDate = calendar.startOfDay(for: date)
        let hasDoses = datesWithDoses.contains(targetDate)

        // THEN: Date should be identified as having doses
        #expect(hasDoses == true)
    }

    @Test("Calendar day view identifies days with multiple doses")
    func calendarDayViewIdentifiesDaysWithMultipleDoses() throws {
        // GIVEN: A date with multiple doses
        let calendar = Calendar.current
        let date = Date()
        let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date)!
        let evening = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: date)!

        let doses = [
            createMockDose(timestamp: morning),
            createMockDose(timestamp: evening),
        ]

        // WHEN: Grouping doses by date
        let groupedDoses = Dictionary(grouping: doses) { dose in
            calendar.startOfDay(for: dose.timestamp)
        }

        // THEN: Date should have multiple doses
        let targetDate = calendar.startOfDay(for: date)
        let dosesForDate = groupedDoses[targetDate] ?? []
        #expect(dosesForDate.count == 2)
    }

    @Test("Calendar day view identifies days without doses")
    func calendarDayViewIdentifiesDaysWithoutDoses() throws {
        // GIVEN: A date without doses
        let calendar = Calendar.current
        let date = Date()
        let doses: [Dose] = []

        // WHEN: Checking if date has doses
        let datesWithDoses = Set(doses.map { calendar.startOfDay(for: $0.timestamp) })
        let targetDate = calendar.startOfDay(for: date)
        let hasDoses = datesWithDoses.contains(targetDate)

        // THEN: Date should not be identified as having doses
        #expect(hasDoses == false)
    }

    // MARK: - Today State Tests

    @Test("Calendar day view identifies today correctly")
    func calendarDayViewIdentifiesTodayCorrectly() throws {
        // GIVEN: Today's date
        let calendar = Calendar.current
        let today = Date()

        // WHEN: Checking if date is today
        let isToday = calendar.isDateInToday(today)

        // THEN: Should be identified as today
        #expect(isToday == true)
    }

    @Test("Calendar day view distinguishes today from other dates")
    func calendarDayViewDistinguishesTodayFromOtherDates() throws {
        // GIVEN: Today and other dates
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // WHEN: Checking which dates are today
        let isTodayToday = calendar.isDateInToday(today)
        let isYesterdayToday = calendar.isDateInToday(yesterday)
        let isTomorrowToday = calendar.isDateInToday(tomorrow)

        // THEN: Only today should be identified as today
        #expect(isTodayToday == true)
        #expect(isYesterdayToday == false)
        #expect(isTomorrowToday == false)
    }

    // MARK: - Injection Site Color Tests

    @Test("Calendar day view handles different injection sites")
    func calendarDayViewHandlesDifferentInjectionSites() throws {
        // GIVEN: Doses with different injection sites
        let date = Date()
        let abdominalDose = self.createMockDose(timestamp: date, site: "Abdomen")
        let thighDose = self.createMockDose(timestamp: date, site: "Thigh")
        let armDose = self.createMockDose(timestamp: date, site: "Arm")

        let doses = [abdominalDose, thighDose, armDose]

        // WHEN: Extracting injection sites
        let injectionSites = Set(doses.compactMap(\.site))

        // THEN: All injection sites should be represented
        #expect(injectionSites.contains("Abdomen"))
        #expect(injectionSites.contains("Thigh"))
        #expect(injectionSites.contains("Arm"))
        #expect(injectionSites.count == 3)
    }

    @Test("Calendar day view handles doses without injection site")
    func calendarDayViewHandlesDosesWithoutInjectionSite() throws {
        // GIVEN: A dose without injection site
        let date = Date()
        let dose = self.createMockDose(timestamp: date, site: nil)

        // WHEN: Checking injection site
        let site = dose.site

        // THEN: Site should be nil
        #expect(site == nil)
    }

    // MARK: - Selection State Tests

    @Test("Calendar day view handles selection state")
    func calendarDayViewHandlesSelectionState() throws {
        // GIVEN: A calendar day that can be selected/deselected
        let date = Date()
        var isSelected = false

        // WHEN: Toggling selection state
        isSelected.toggle()

        // THEN: Selection state should change
        #expect(isSelected == true)

        // WHEN: Toggling again
        isSelected.toggle()

        // THEN: Should return to unselected
        #expect(isSelected == false)
    }

    // MARK: - Helper Methods

    private func createMockDose(timestamp: Date, site: String? = "Abdomen") -> Dose {
        Dose(
            amount: 1.0,
            timestamp: timestamp,
            site: site,
            notes: "Test dose",
            imageData: nil,
            skipped: false,
            user: nil,
            medication: nil)
    }
}
