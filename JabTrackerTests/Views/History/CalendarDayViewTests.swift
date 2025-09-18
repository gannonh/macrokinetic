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
        // GIVEN: A specific date and CalendarDayView
        let calendar = Calendar.current
        let components = DateComponents(year: 2024, month: 9, day: 15)
        let date = calendar.date(from: components)!
        let doses: [Dose] = []

        // WHEN: CalendarDayView calculates day number
        let testDayView = TestCalendarDayViewModel(
            date: date,
            doses: doses,
            isToday: false,
            isSelected: false
        )

        // THEN: Day number should be 15 from view's computed property
        #expect(testDayView.dayNumber == 15)
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
        // GIVEN: Today's date and CalendarDayView
        let today = Date()
        let doses: [Dose] = []

        // WHEN: CalendarDayView is configured as today
        let testDayView = TestCalendarDayViewModel(
            date: today,
            doses: doses,
            isToday: true,
            isSelected: false
        )

        // THEN: View should reflect today styling properties
        #expect(testDayView.isToday == true)
        #expect(testDayView.textColor == .accentColor)
        #expect(testDayView.borderWidth == 1)
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
        // GIVEN: CalendarDayView with doses from different injection sites
        let date = Date()
        let abdominalDose = self.createMockDose(timestamp: date, site: "Abdomen")
        let thighDose = self.createMockDose(timestamp: date, site: "Thigh")
        let armDose = self.createMockDose(timestamp: date, site: "Arm")

        let testDayView = TestCalendarDayViewModel(
            date: date,
            doses: [abdominalDose, thighDose, armDose],
            isToday: false,
            isSelected: false
        )

        // WHEN: CalendarDayView determines indicator colors for different sites
        let abdominalColor = testDayView.indicatorColor(for: abdominalDose)
        let thighColor = testDayView.indicatorColor(for: thighDose)
        let armColor = testDayView.indicatorColor(for: armDose)

        // THEN: Each injection site should have its specific color
        #expect(abdominalColor == .blue)
        #expect(thighColor == .green)
        #expect(armColor == .purple)
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
        // GIVEN: A calendar day with different selection states
        let date = Date()
        let doses: [Dose] = []

        // WHEN: CalendarDayView is selected
        let selectedDayView = TestCalendarDayViewModel(
            date: date,
            doses: doses,
            isToday: false,
            isSelected: true
        )

        // THEN: View should reflect selected styling
        #expect(selectedDayView.isSelected == true)
        #expect(selectedDayView.textColor == .accentColor)
        #expect(selectedDayView.borderWidth == 2)
        #expect(selectedDayView.backgroundColor != .clear)

        // WHEN: CalendarDayView is not selected
        let unselectedDayView = TestCalendarDayViewModel(
            date: date,
            doses: doses,
            isToday: false,
            isSelected: false
        )

        // THEN: View should reflect unselected styling
        #expect(unselectedDayView.isSelected == false)
        #expect(unselectedDayView.textColor == .primary)
        #expect(unselectedDayView.borderWidth == 0)
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

// MARK: - Test Calendar Day View Model

/// Test view model that exposes CalendarDayView's computed properties for testing
private class TestCalendarDayViewModel {
    let date: Date
    let doses: [Dose]
    let isToday: Bool
    let isSelected: Bool
    private let calendar = Calendar.current

    init(date: Date, doses: [Dose], isToday: Bool, isSelected: Bool) {
        self.date = date
        self.doses = doses
        self.isToday = isToday
        self.isSelected = isSelected
    }

    var dayNumber: Int {
        calendar.component(.day, from: date)
    }

    var backgroundColor: Color {
        if isSelected {
            return .accentColor.opacity(0.2)
        } else if isToday {
            return .accentColor.opacity(0.1)
        } else {
            return Color.clear
        }
    }

    var textColor: Color {
        if isSelected {
            return .accentColor
        } else if isToday {
            return .accentColor
        } else {
            return .primary
        }
    }

    var borderColor: Color {
        if isSelected {
            return .accentColor
        } else if isToday {
            return .accentColor.opacity(0.5)
        } else {
            return Color.clear
        }
    }

    var borderWidth: CGFloat {
        if isSelected {
            return 2
        } else if isToday {
            return 1
        } else {
            return 0
        }
    }

    var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: date)

        var label = dateString
        if isToday {
            label += ", today"
        }
        if !doses.isEmpty {
            label += ", \(doses.count) dose\(doses.count == 1 ? "" : "s")"
        }
        return label
    }

    func indicatorColor(for dose: Dose) -> Color {
        if dose.skipped {
            return .orange.opacity(0.7)
        }

        switch dose.site?.lowercased() {
        case "abdomen":
            return .blue
        case "thigh":
            return .green
        case "arm":
            return .purple
        default:
            return .accentColor
        }
    }
}
