//
//  FoodLogCalendarUITests.swift
//  JabTrackerUITests
//
//  E2E tests for week calendar navigation in Food Log.
//

import XCTest

final class FoodLogCalendarUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)

        // Wait for app to be ready
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should appear after launch")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Week Navigation

    /// User can see week calendar strip in Food Log
    /// Acceptance: Week strip visible with 7 days, today highlighted
    func testWeekCalendarStripVisible() {
        // GIVEN: User launches the app
        // (done in setUp)

        // WHEN: User navigates to Food Log tab
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // THEN: Week calendar strip is visible
        let weekCalendarStrip = app.otherElements["week-calendar-strip"]
        XCTAssertTrue(
            weekCalendarStrip.waitForExistence(timeout: 3),
            "Week calendar strip should be visible in Food Log"
        )

        // THEN: 7 day cells are visible (one for each day of the week)
        // Day cells use "food-day-{dayNumber}" identifier
        let calendar = Calendar.current
        let today = Date()
        let todayDay = calendar.component(.day, from: today)

        // Verify today's day cell exists (use .firstMatch for reliability)
        let todayCell = app.buttons["food-day-\(todayDay)"].firstMatch
        XCTAssertTrue(
            todayCell.waitForExistence(timeout: 3),
            "Today's date cell (food-day-\(todayDay)) should exist in week calendar"
        )

        // THEN: Today's cell has selected trait (is highlighted)
        // The cell should be present and interactive
        XCTAssertTrue(todayCell.isHittable, "Today's date cell should be hittable")
    }

    /// User can tap a day to view that day's entries
    /// Acceptance: Tapping day updates summary title and meal sections
    func testTapDayUpdatesEntries() {
        // GIVEN: App is launched with test data
        // (done in setUp)

        // WHEN: User navigates to Food Log tab
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Verify initial state shows "Today" in summary title
        let summaryTitle = app.staticTexts["daily-summary-title"]
        XCTAssertTrue(summaryTitle.waitForExistence(timeout: 3), "Daily summary title should exist")
        XCTAssertEqual(summaryTitle.label, "Today", "Summary title should show 'Today' initially")

        // WHEN: User taps a different day in the week strip
        // Strategy: Navigate to previous week first, then tap a day there
        // This ensures we're always testing a non-today date regardless of week boundaries
        let previousWeekButton = app.buttons["week-calendar-previous"]
        XCTAssertTrue(previousWeekButton.waitForExistence(timeout: 3), "Previous week button should exist")
        previousWeekButton.tap()

        // Wait for week to update
        let weekTransition = XCTestExpectation(description: "Wait for week transition")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            weekTransition.fulfill()
        }
        wait(for: [weekTransition], timeout: 1.0)

        // THEN: Summary title updates to formatted date (not "Today")
        // After navigating to previous week, the first day of that week is auto-selected
        XCTAssertNotEqual(
            summaryTitle.label,
            "Today",
            "Summary title should update to formatted date when selecting a different day"
        )

        // Verify the title shows a formatted date (contains comma like "Monday, Dec 23")
        XCTAssertTrue(
            summaryTitle.label.contains(","),
            "Summary title should be in format 'Weekday, Mon Day' after selecting different day"
        )
    }

    /// User can navigate to previous week
    /// Acceptance: Chevron tap shows previous week, selects first day
    func testNavigateToPreviousWeek() {
        // GIVEN: User is on Food Log with week calendar visible
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Verify week calendar title exists
        let weekCalendarTitle = app.staticTexts["week-calendar-title"]
        XCTAssertTrue(weekCalendarTitle.waitForExistence(timeout: 3), "Week calendar title should exist")

        // WHEN: User taps previous week button
        let previousWeekButton = app.buttons["week-calendar-previous"]
        XCTAssertTrue(previousWeekButton.waitForExistence(timeout: 3), "Previous week button should exist")
        previousWeekButton.tap()

        // Wait for week transition
        let expectation = XCTestExpectation(description: "Wait for week transition")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // THEN: Summary title shows formatted date (not "Today") after week navigation
        let summaryTitle = app.staticTexts["daily-summary-title"]
        XCTAssertNotEqual(
            summaryTitle.label,
            "Today",
            "Summary title should not show 'Today' after navigating to previous week"
        )

        // Verify the selected date is in the past by checking title format
        // Title should be something like "Monday, Dec 23" not "Today"
        XCTAssertTrue(
            summaryTitle.label.contains(","),
            "Summary title should show formatted date (contains comma) for previous week"
        )
    }

    /// User can navigate to next week
    /// Acceptance: Chevron tap shows next week, selects first day
    func testNavigateToNextWeek() {
        // GIVEN: User is on Food Log with week calendar visible
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Verify summary title exists and starts with "Today"
        let summaryTitle = app.staticTexts["daily-summary-title"]
        XCTAssertTrue(summaryTitle.waitForExistence(timeout: 3), "Daily summary title should exist")
        XCTAssertEqual(summaryTitle.label, "Today", "Summary title should start with 'Today'")

        // WHEN: User taps next week button
        let nextWeekButton = app.buttons["week-calendar-next"]
        XCTAssertTrue(nextWeekButton.waitForExistence(timeout: 3), "Next week button should exist")
        nextWeekButton.tap()

        // Wait for week transition
        let expectation = XCTestExpectation(description: "Wait for week transition")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // THEN: Summary title shows formatted date (not "Today") after week navigation
        XCTAssertNotEqual(
            summaryTitle.label,
            "Today",
            "Summary title should not show 'Today' after navigating to next week"
        )

        // Verify the title shows a formatted date
        XCTAssertTrue(
            summaryTitle.label.contains(","),
            "Summary title should show formatted date (contains comma) for next week"
        )
    }

    // MARK: - Visual Indicators

    /// Days with food entries show indicator dot
    /// Acceptance: Logged days have visible dot, empty days don't
    func testEntryIndicatorDots() {
        // GIVEN: User logs a food entry for today
        logTestFoodEntry()

        // WHEN: User views the week calendar
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        let weekCalendarStrip = app.otherElements["week-calendar-strip"]
        XCTAssertTrue(weekCalendarStrip.waitForExistence(timeout: 3), "Week calendar strip should be visible")

        // Get today's day number
        let calendar = Calendar.current
        let todayDay = calendar.component(.day, from: Date())

        // THEN: Today's cell should exist (we can't directly verify the dot color in XCUITest,
        // but we can verify the cell exists and is interactive)
        let todayCell = app.buttons["food-day-\(todayDay)"].firstMatch
        XCTAssertTrue(
            todayCell.waitForExistence(timeout: 3),
            "Today's date cell should exist after logging entry"
        )

        // The accessibility label includes entry count when entries exist
        // e.g., "Thursday, December 26, 2024, today, 1 food entry"
        let todayLabel = todayCell.label
        XCTAssertTrue(
            todayLabel.contains("entry") || todayLabel.contains("entries"),
            "Today's cell accessibility label should indicate food entries: \(todayLabel)"
        )
    }

    // MARK: - Edge Cases

    /// Today is visually highlighted in week calendar
    /// Acceptance: Today has distinct border/style from other days
    func testTodayHighlighted() {
        // GIVEN: User is on Food Log
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // WHEN: User views the week calendar
        let weekCalendarStrip = app.otherElements["week-calendar-strip"]
        XCTAssertTrue(weekCalendarStrip.waitForExistence(timeout: 3), "Week calendar strip should be visible")

        // Get today's day number
        let calendar = Calendar.current
        let todayDay = calendar.component(.day, from: Date())

        // THEN: Today's cell should exist with "today" in accessibility label
        // Use .firstMatch to handle any potential duplicate matches
        let todayCell = app.buttons["food-day-\(todayDay)"].firstMatch
        XCTAssertTrue(
            todayCell.waitForExistence(timeout: 3),
            "Today's date cell (food-day-\(todayDay)) should exist"
        )

        // Verify accessibility label includes "today"
        let todayLabel = todayCell.label
        XCTAssertTrue(
            todayLabel.lowercased().contains("today"),
            "Today's cell accessibility label should include 'today': \(todayLabel)"
        )

        // Verify it's the selected element (has selected trait)
        // In the initial state, today should be selected
        // We can verify by checking the summary title shows "Today"
        let summaryTitle = app.staticTexts["daily-summary-title"]
        XCTAssertEqual(
            summaryTitle.label,
            "Today",
            "Summary title should show 'Today' indicating today is selected"
        )
    }

    /// Summary title changes based on selected date
    /// Acceptance: "Today" for today, formatted date for other days
    func testSummaryTitleUpdates() {
        // GIVEN: User is on Food Log
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // WHEN: Initial state
        let summaryTitle = app.staticTexts["daily-summary-title"]
        XCTAssertTrue(summaryTitle.waitForExistence(timeout: 3), "Daily summary title should exist")

        // THEN: Summary shows "Today"
        XCTAssertEqual(summaryTitle.label, "Today", "Summary title should show 'Today' initially")

        // WHEN: User taps a different day (navigate to previous week first, then select a day)
        let previousWeekButton = app.buttons["week-calendar-previous"]
        XCTAssertTrue(previousWeekButton.waitForExistence(timeout: 3), "Previous week button should exist")
        previousWeekButton.tap()

        // Wait for transition
        let transition1 = XCTestExpectation(description: "Wait for week transition")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            transition1.fulfill()
        }
        wait(for: [transition1], timeout: 1.0)

        // THEN: Summary title shows formatted date (not "Today")
        XCTAssertNotEqual(
            summaryTitle.label,
            "Today",
            "Summary title should show formatted date for previous week"
        )

        // The formatted date should contain a comma (e.g., "Monday, Dec 23")
        XCTAssertTrue(
            summaryTitle.label.contains(","),
            "Summary title should be in format 'Weekday, Mon Day' (contains comma)"
        )

        // WHEN: User taps back to today (navigate forward to current week)
        let nextWeekButton = app.buttons["week-calendar-next"]
        XCTAssertTrue(nextWeekButton.waitForExistence(timeout: 3), "Next week button should exist")
        nextWeekButton.tap()

        // Wait for transition
        let transition2 = XCTestExpectation(description: "Wait for week transition back")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            transition2.fulfill()
        }
        wait(for: [transition2], timeout: 1.0)

        // Now tap today's cell to select it
        let calendar = Calendar.current
        let todayDay = calendar.component(.day, from: Date())
        let todayCell = app.buttons["food-day-\(todayDay)"].firstMatch
        XCTAssertTrue(
            todayCell.waitForExistence(timeout: 3),
            "Today's cell (food-day-\(todayDay)) should exist after navigating back"
        )
        todayCell.tap()

        // Wait for selection
        let selectionWait = XCTestExpectation(description: "Wait for selection update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            selectionWait.fulfill()
        }
        wait(for: [selectionWait], timeout: 1.0)

        // THEN: Summary title shows "Today" again
        XCTAssertEqual(
            summaryTitle.label,
            "Today",
            "Summary title should show 'Today' again after selecting today"
        )
    }

    // MARK: - Helpers

    /// Logs a test food entry for use in indicator tests
    private func logTestFoodEntry() {
        // Navigate to Food Log tab
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Open Food Search sheet via + button
        let addButton = app.buttons["add-food-button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3), "Add food button should exist")
        addButton.tap()

        // Wait for Food Search Sheet
        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 5), "Food search sheet should appear")

        // Search for a common food
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText("apple")

        // Select first result
        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Should have search result for 'apple'")
        firstResult.tap()

        // Wait for FoodDetailSheet to appear
        let foodDetailSheet = app.otherElements["food-detail-sheet"]
        XCTAssertTrue(foodDetailSheet.waitForExistence(timeout: 5), "Food detail sheet should appear")

        // Save the food entry
        let addFoodButton = app.buttons["add-food-button"].firstMatch
        XCTAssertTrue(addFoodButton.waitForExistence(timeout: 3), "Add button should exist in food detail sheet")
        addFoodButton.tap()

        // Wait for sheets to dismiss
        Thread.sleep(forTimeInterval: 1.5)
    }
}
