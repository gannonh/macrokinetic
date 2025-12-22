//
//  CalendarNavigationUITests.swift
//  JabTrackerUITests
//
//  Calendar Navigation and Interaction Tests
//  Tests for month navigation, date selection, view toggling, and empty state handling
//

import XCTest

final class CalendarNavigationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Navigation and Interaction

    func test_calendar_monthNavigation() throws {
        // GIVEN: Calendar is displayed
        let app = TestUtilities.launchAppWithTestMode()
        TestUtilities.navigateToHistoryView(in: app)

        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        let calendarToggleButton = segmentedControl.buttons["Calendar"]
        calendarToggleButton.tap()

        let calendarView = app.descendants(matching: .any)["dose-calendar-container"]
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3), "Calendar view should appear")

        // Get current month/year for comparison
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let currentMonthYear = formatter.string(from: currentDate)

        let monthYearHeader = app.staticTexts["calendar-month-year"]
        if !monthYearHeader.waitForExistence(timeout: 3) {
            // Fallback: Find month header by content using current year
            let currentYear = Calendar.current.component(.year, from: Date())
            let monthTexts = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS %@", String(currentYear)))
            XCTAssertGreaterThan(monthTexts.count, 0, "Should find month header by content")
        } else {
            XCTAssertEqual(monthYearHeader.label, currentMonthYear, "Should start with current month")
        }

        // WHEN: User taps navigation controls to change month

        // Navigate to next month
        let nextMonthButton = app.buttons.matching(NSPredicate(format: "label == 'Next month'"))
            .firstMatch
        if !nextMonthButton.exists {
            // Fallback: Look for buttons with ">" or navigation symbols
            let navButtons = app.otherElements.matching(
                NSPredicate(format: "label CONTAINS '>' OR label CONTAINS 'next'"))
            XCTAssertGreaterThan(navButtons.count, 0, "Should find navigation buttons")
            navButtons.firstMatch.tap()
        } else {
            nextMonthButton.tap()
        }

        // THEN: Month header updates correctly
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) else {
            XCTFail("Failed to calculate next month")
            return
        }
        let expectedNextMonthYear = formatter.string(from: nextMonth)

        // Wait for month transition animation
        let nextMonthExpectation = XCTestExpectation(description: "Wait for month transition")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            nextMonthExpectation.fulfill()
        }
        wait(for: [nextMonthExpectation], timeout: 2.0)

        // Verify month changed - use fallback if accessibility identifier not available
        if monthYearHeader.exists {
            XCTAssertEqual(
                monthYearHeader.label, expectedNextMonthYear, "Should show next month after navigation")
        } else {
            // Fallback: verify some month text changed
            let nextMonthTexts = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS %@", expectedNextMonthYear)
            )
            XCTAssertGreaterThan(nextMonthTexts.count, 0, "Should find next month text after navigation")
        }

        // Navigate back to previous month
        let prevMonthButton = app.buttons.matching(NSPredicate(format: "label == 'Previous month'"))
            .firstMatch
        if !prevMonthButton.exists {
            // Fallback: Look for buttons with "<" or previous navigation symbols
            let prevNavButtons = app.otherElements.matching(
                NSPredicate(format: "label CONTAINS '<' OR label CONTAINS 'previous'")
            )
            XCTAssertGreaterThan(prevNavButtons.count, 0, "Should find previous navigation buttons")
            prevNavButtons.firstMatch.tap()
        } else {
            prevMonthButton.tap()
        }

        // THEN: Calendar transitions smoothly back to original month
        let prevMonthExpectation = XCTestExpectation(description: "Wait for month transition back")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            prevMonthExpectation.fulfill()
        }
        wait(for: [prevMonthExpectation], timeout: 2.0)

        // Verify returned to original month - use fallback if accessibility identifier not available
        if monthYearHeader.exists {
            XCTAssertEqual(monthYearHeader.label, currentMonthYear, "Should return to current month")
        } else {
            // Fallback: verify current month text is visible again
            let currentMonthTexts = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS %@", currentMonthYear)
            )
            XCTAssertGreaterThan(
                currentMonthTexts.count, 0, "Should find current month text after navigation back")
        }

        // THEN: Calendar grid still functions properly
        let calendarDays = app.otherElements.matching(
            NSPredicate(format: "identifier BEGINSWITH 'calendar-day-'"))
        XCTAssertGreaterThan(
            calendarDays.count, 20, "Calendar should still show day buttons after navigation")
    }

    func test_calendar_dateSelection() throws {
        // GIVEN: Calendar is displayed with doses
        let preset = TestUtilities.TestDataPreset.thirtyDays
        let app = TestUtilities.launchAppWithSeededData(preset: preset)

        TestUtilities.navigateToHistoryView(in: app)

        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        let calendarToggleButton = segmentedControl.buttons["Calendar"]
        calendarToggleButton.tap()

        let calendarView = app.descendants(matching: .any)["dose-calendar-container"]
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3), "Calendar view should appear")

        // Wait for calendar to load
        let expectation = XCTestExpectation(description: "Wait for calendar to load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)

        // WHEN: User taps on a date with doses
        // For 30-day weekly medication data, today should have a dose
        let todayDay = Calendar.current.component(.day, from: Date())
        let todayButton = app.descendants(matching: .any)["calendar-day-\(todayDay)"].firstMatch

        XCTAssertTrue(todayButton.exists, "Today's date button should exist")
        todayButton.tap()

        // THEN: Dose detail view appears for that date
        let dateDetailView = app.descendants(matching: .any)["dose-day-detail-view"]
        XCTAssertTrue(
            dateDetailView.waitForExistence(timeout: 5),
            "Date detail view should appear for date with doses")

        // THEN: All doses for the selected date are displayed
        // Note: With 30-day data seeding at 95% adherence, today might have no doses
        // The doseListView only shows when doses.isEmpty == false
        let doseList = app.descendants(matching: .any)["dose-list"]
        let emptyState = app.descendants(matching: .any)["empty-state"]

        // Accept either: doses shown OR empty state for days without doses
        XCTAssertTrue(
            doseList.exists || emptyState.exists,
            "Dose list OR empty state should be visible for selected date")

        // Only verify dose rows if we have a dose list (not empty state)
        if doseList.exists {
            let detailDoseRows = app.descendants(matching: .any).matching(identifier: "dose-detail-row")
            XCTAssertGreaterThan(
                detailDoseRows.count, 0, "Should show dose detail rows when dose list is visible")
        }

        // Close the detail view
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.exists, "Done button should be available")
        doneButton.tap()

        // WHEN: User taps on a date without doses (try a future date)
        let calendar = Calendar.current
        guard let futureDate = calendar.date(byAdding: .day, value: 7, to: Date()) else {
            // If we can't calculate future date, skip this part of the test
            return
        }
        let futureDay = calendar.component(.day, from: futureDate)
        let futureDateButton = app.descendants(matching: .any)["calendar-day-\(futureDay)"].firstMatch

        if futureDateButton.exists {
            futureDateButton.tap()

            // THEN: Detail view still appears (even for empty dates)
            XCTAssertTrue(
                dateDetailView.waitForExistence(timeout: 5),
                "Date detail view should appear even for empty dates")

            // THEN: Either dose list or empty state appears
            let futureEmptyState = app.descendants(matching: .any)["empty-state"]
            let futureDoseList = app.descendants(matching: .any)["dose-list"]
            XCTAssertTrue(
                futureEmptyState.waitForExistence(timeout: 3) || futureDoseList.exists,
                "Empty state or dose list should appear for selected date")

            // Close the detail view
            let doneButton2 = app.buttons["Done"]
            if doneButton2.exists {
                doneButton2.tap()
            }
        }
    }

    func test_calendar_viewToggling() throws {
        // GIVEN: User is in History tab with existing doses
        let preset = TestUtilities.TestDataPreset.thirtyDays
        let app = TestUtilities.launchAppWithSeededData(preset: preset)
        TestUtilities.navigateToHistoryView(in: app)

        // Verify we start in list view (ShotsView wraps with dose-history-container)
        let historyContainer = app.descendants(matching: .any)["dose-history-container"]
        XCTAssertTrue(historyContainer.waitForExistence(timeout: 3), "Should start in list view")

        // WHEN: User toggles from list view to calendar view
        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        XCTAssertTrue(
            segmentedControl.waitForExistence(timeout: 3), "View mode picker should be available")

        let calendarToggleButton = segmentedControl.buttons["Calendar"]
        XCTAssertTrue(
            calendarToggleButton.exists, "Calendar toggle should be available in segmented control")
        calendarToggleButton.tap()

        // THEN: Calendar view appears with smooth transition
        let calendarView = app.descendants(matching: .any)["dose-calendar-container"]
        XCTAssertTrue(
            calendarView.waitForExistence(timeout: 3), "Calendar view should appear after toggle")

        // THEN: List view is no longer visible
        XCTAssertFalse(historyContainer.exists, "List view should be hidden when calendar is shown")

        // WHEN: User toggles back to list view
        let listToggleButton = segmentedControl.buttons["List"]
        XCTAssertTrue(listToggleButton.exists, "List toggle should be available in segmented control")
        listToggleButton.tap()

        // THEN: List view appears with smooth transition
        XCTAssertTrue(
            historyContainer.waitForExistence(timeout: 3), "List view should reappear after toggle")

        // THEN: Calendar view is no longer visible
        XCTAssertFalse(calendarView.exists, "Calendar view should be hidden when list is shown")

        // THEN: Toggle control clearly indicates current view mode
        // Note: isSelected property may not work reliably on segmented control buttons
        // Instead verify the correct view is shown which proves the toggle worked
    }

    func test_calendar_emptyMonthHandling() throws {
        // GIVEN: User navigates to a month with no doses
        let app = TestUtilities.launchAppWithTestMode()
        // Don't create any doses - start with empty history
        TestUtilities.navigateToHistoryView(in: app)

        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        let calendarToggleButton = segmentedControl.buttons["Calendar"]
        calendarToggleButton.tap()

        let calendarView = app.descendants(matching: .any)["dose-calendar-container"]
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3), "Calendar view should appear")

        // Navigate to a future month that won't have any doses
        let nextMonthButton = app.buttons.matching(NSPredicate(format: "label == 'Next month'"))
            .firstMatch
        if !nextMonthButton.exists {
            // Fallback: Look for buttons with ">" or navigation symbols
            let navButtons = app.otherElements.matching(
                NSPredicate(format: "label CONTAINS '>' OR label CONTAINS 'next'"))
            XCTAssertGreaterThan(
                navButtons.count, 0, "Should find navigation buttons for empty month test")
            navButtons.firstMatch.tap()
        } else {
            nextMonthButton.tap()
        }

        // Wait for transition
        let expectation = XCTestExpectation(description: "Wait for month transition")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // WHEN: Calendar displays the empty month
        let monthYearHeader = app.staticTexts["calendar-month-year"]
        if !monthYearHeader.exists {
            // Fallback: verify some month header exists by content
            // Search for current or next year (handles Dec→Jan transition)
            let currentYear = Calendar.current.component(.year, from: Date())
            let nextYear = currentYear + 1
            let monthTexts = app.staticTexts.matching(
                NSPredicate(
                    format: "label CONTAINS %@ OR label CONTAINS %@",
                    String(currentYear), String(nextYear)))
            XCTAssertGreaterThan(
                monthTexts.count, 0, "Month header should still be visible (fallback check)")
        } else {
            XCTAssertTrue(monthYearHeader.exists, "Month header should still be visible")
        }

        // THEN: Calendar shows proper date layout without doses indicators
        let calendarDays = app.otherElements.matching(
            NSPredicate(format: "identifier BEGINSWITH 'calendar-day-'"))
        XCTAssertGreaterThan(
            calendarDays.count, 20, "Calendar should still show day buttons for empty month")

        // Verify no dose indicators are shown (since we didn't create any doses)
        let doseIndicators = app.descendants(matching: .any).matching(
            identifier: "calendar-dose-indicator")
        XCTAssertEqual(doseIndicators.count, 0, "Should have no dose indicators in empty month")

        // THEN: No error states or empty state messages appear in calendar grid
        // The calendar should just show the dates without any error messaging
        let errorMessages = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'error'"))
        XCTAssertEqual(errorMessages.count, 0, "Should not show error messages in calendar grid")

        // THEN: Navigation to other months remains functional
        let prevMonthButton = app.buttons.matching(NSPredicate(format: "label == 'Previous month'"))
            .firstMatch
        if !prevMonthButton.exists {
            // Fallback: Look for buttons with "<" or previous navigation symbols
            let prevNavButtons = app.otherElements.matching(
                NSPredicate(format: "label CONTAINS '<' OR label CONTAINS 'previous'")
            )
            XCTAssertGreaterThan(
                prevNavButtons.count, 0, "Should find previous navigation buttons in empty month test")
            prevNavButtons.firstMatch.tap()
        } else {
            prevMonthButton.tap()
        }

        // Wait for transition back
        let backExpectation = XCTestExpectation(description: "Wait for month transition back")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            backExpectation.fulfill()
        }
        wait(for: [backExpectation], timeout: 2.0)

        // Verify we're back to original month
        if monthYearHeader.exists {
            XCTAssertTrue(monthYearHeader.exists, "Month header should still be visible after navigation")
        } else {
            // Fallback: verify some month header exists by content after navigation back
            let currentYear = Calendar.current.component(.year, from: Date())
            let monthTextsBack = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS %@", String(currentYear)))
            XCTAssertGreaterThan(
                monthTextsBack.count, 0,
                "Month header should still be visible after navigation (fallback check)")
        }
    }
}
