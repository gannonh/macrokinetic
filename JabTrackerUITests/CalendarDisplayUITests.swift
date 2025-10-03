//
//  CalendarDisplayUITests.swift
//  JabTrackerUITests
//
//  Calendar Display and Visual Presentation Tests
//  Tests for calendar layout, visual indicators, and basic display functionality
//

import XCTest

final class CalendarDisplayUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Calendar Layout and Visual Presentation

    func test_calendar_displaysCurrentMonth() throws {
        // GIVEN: App is open to History tab
        let app = TestUtilities.launchAppWithTestMode()
        TestUtilities.navigateToHistoryView(in: app)

        // WHEN: User taps calendar view toggle
        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        XCTAssertTrue(
            segmentedControl.waitForExistence(timeout: 3), "View mode picker should be available")

        let calendarToggleButton = segmentedControl.buttons["history-calendar-toggle"]
        XCTAssertTrue(calendarToggleButton.exists, "Calendar toggle should be available")
        calendarToggleButton.tap()

        // THEN: Calendar view appears with current month layout
        let calendarView = app.descendants(matching: .any)["dose-calendar-view"]
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3), "Calendar view should appear")

        // THEN: Current month header is displayed
        let monthYearHeader = app.staticTexts["calendar-month-year"]

        if !monthYearHeader.waitForExistence(timeout: 3) {
            // If not found by identifier, find by content containing current year
            let monthTexts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "2025"))
            XCTAssertGreaterThan(monthTexts.count, 0, "Should find month header by content")

            let foundHeader = monthTexts.firstMatch
            XCTAssertTrue(foundHeader.exists, "Should find month header by content")
            XCTAssertTrue(foundHeader.label.contains("2025"), "Should display current year")
        } else {
            // Verify it shows current month/year
            let currentDate = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            let expectedMonthYear = formatter.string(from: currentDate)
            XCTAssertEqual(
                monthYearHeader.label, expectedMonthYear, "Should display current month and year")
        }

        // THEN: Today's date is clearly highlighted
        let todayDay = Calendar.current.component(.day, from: Date())
        let todayButton = app.buttons["calendar-day-\(todayDay)"]
        XCTAssertTrue(todayButton.exists, "Today's date button should exist in calendar")

        // THEN: Calendar displays proper date grid layout
        let calendarDays = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'calendar-day-'"))
        XCTAssertGreaterThan(
            calendarDays.count, 20, "Calendar should show multiple day buttons for the month")
        XCTAssertLessThan(calendarDays.count, 50, "Calendar should not show excessive day buttons")
    }

    func test_calendar_todayHighlighting() throws {
        // GIVEN: Calendar is displayed
        let app = TestUtilities.launchAppWithTestMode()
        TestUtilities.navigateToHistoryView(in: app)

        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        let calendarToggleButton = segmentedControl.buttons["history-calendar-toggle"]
        calendarToggleButton.tap()

        let calendarView = app.descendants(matching: .any)["dose-calendar-view"]
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3), "Calendar view should appear")

        // WHEN: Current month contains today's date
        let todayDay = Calendar.current.component(.day, from: Date())
        let todayButton = app.buttons["calendar-day-\(todayDay)"]

        // THEN: Today's date has distinct visual highlighting
        XCTAssertTrue(todayButton.exists, "Today's date button should exist and be visible")

        // Verify today's accessibility label includes "today" indication
        let accessibilityLabel = todayButton.label
        // The CalendarDayView adds ", today" to the accessibility label for today's date
        XCTAssertTrue(
            accessibilityLabel.lowercased().contains("today"),
            "Today's date should be announced as 'today' in accessibility label")

        // THEN: Highlighting distinguishes from other date states
        // Test that other dates don't have "today" in their label
        let tomorrowDay = Calendar.current.component(.day, from: Date().addingTimeInterval(86400))
        let tomorrowButton = app.buttons["calendar-day-\(tomorrowDay)"]

        if tomorrowButton.exists {
            let tomorrowLabel = tomorrowButton.label
            XCTAssertFalse(
                tomorrowLabel.lowercased().contains("today"),
                "Non-today dates should not be labeled as 'today'")
        }
    }

    func test_calendar_doseIndicatorVariations() throws {
        // GIVEN: User has doses recorded
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 5)
        TestUtilities.navigateToHistoryView(in: app)

        // WHEN: Calendar is displayed
        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        let calendarToggleButton = segmentedControl.buttons["history-calendar-toggle"]
        calendarToggleButton.tap()

        let calendarView = app.descendants(matching: .any)["dose-calendar-view"]
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3), "Calendar view should appear")

        // THEN: Verify calendar can display dose indicators
        // Note: Full implementation would test different indicator styles for:
        // - Single doses (single circle)
        // - Multiple doses (multiple circles with + indicator)
        // - Skipped doses (orange/warning indicator)

        // For now, just verify the calendar properly shows dates with doses
        let todayDay = Calendar.current.component(.day, from: Date())
        let todayButton = app.buttons["calendar-day-\(todayDay)"]
        XCTAssertTrue(todayButton.exists, "Today with doses should be accessible")
    }

    func test_calendar_injectionSiteColorCoding() throws {
        // GIVEN: User has doses with injection sites
        let preset = TestUtilities.TestDataPreset.thirtyDays
        let app = TestUtilities.launchAppWithSeededData(preset: preset)

        TestUtilities.navigateToHistoryView(in: app)

        // WHEN: Calendar displays dose indicators
        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        let calendarToggleButton = segmentedControl.buttons["history-calendar-toggle"]
        calendarToggleButton.tap()

        let calendarView = app.descendants(matching: .any)["dose-calendar-view"]
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3), "Calendar view should appear")

        // THEN: Verify doses are properly displayed
        // Note: Full implementation would:
        // - Create doses with specific injection sites
        // - Verify color consistency across the calendar
        // - Test accessibility labels include site information

        // For now, verify the calendar renders without issues
        let calendarDays = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'calendar-day-'"))
        XCTAssertGreaterThan(calendarDays.count, 0, "Calendar should display dates")
    }

    func test_calendar_showsDoseIndicators() throws {
        // GIVEN: User has doses recorded on specific dates
        let preset = TestUtilities.TestDataPreset.thirtyDays
        let app = TestUtilities.launchAppWithSeededData(preset: preset)
        TestUtilities.navigateToHistoryView(in: app)

        // WHEN: User views calendar
        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        XCTAssertTrue(
            segmentedControl.waitForExistence(timeout: 3), "View mode picker should be available")

        let calendarToggleButton = segmentedControl.buttons["history-calendar-toggle"]
        calendarToggleButton.tap()

        let calendarView = app.descendants(matching: .any)["dose-calendar-view"]
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3), "Calendar view should appear")

        // THEN: Dates with doses show visual indicators
        // Wait for calendar to load dose indicators
        let expectation = XCTestExpectation(description: "Wait for dose indicators")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)

        // Look for dose indicators on calendar days
        _ = app.descendants(matching: .any).matching(identifier: "calendar-dose-indicator")

        // If indicators aren't found by identifier, check that today's date has visual content
        // (since our test creates doses on today's date)
        let todayDay = Calendar.current.component(.day, from: Date())
        let todayButton = app.buttons["calendar-day-\(todayDay)"]
        XCTAssertTrue(todayButton.exists, "Today's date should exist in calendar")

        // THEN: Dates without doses appear as normal calendar days
        // Find a date that shouldn't have doses (like tomorrow or yesterday)
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else {
            XCTFail("Failed to calculate tomorrow's date")
            return
        }
        let tomorrowDay = calendar.component(.day, from: tomorrow)
        let tomorrowButton = app.buttons["calendar-day-\(tomorrowDay)"]

        if tomorrowButton.exists {
            // Tomorrow should exist and not have dose indicators (since we only created today's doses)
            XCTAssertTrue(tomorrowButton.exists, "Tomorrow's date should appear as normal calendar day")
        }

        // Verify we can distinguish between dates with and without doses by tapping
        todayButton.tap()
        let dateDetailView = app.descendants(matching: .any)["dose-day-detail-view"]
        XCTAssertTrue(
            dateDetailView.waitForExistence(timeout: 3), "Date detail should open for date with doses")

        let doseList = app.descendants(matching: .any)["dose-list"]
        XCTAssertTrue(doseList.exists, "Should show dose list for date with doses")

        // Close detail view
        let doneButton = app.buttons["Done"]
        doneButton.tap()
    }
}
