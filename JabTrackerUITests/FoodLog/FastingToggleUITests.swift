//
//  FastingToggleUITests.swift
//  JabTrackerUITests
//
//  E2E tests for fasting day toggle functionality in Food Log.
//  Phase 39: Day Status Tracking
//

import XCTest

final class FastingToggleUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)

        // Wait for app to be ready
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should appear after launch")
    }

    override func tearDownWithError() throws {
        if testRun?.hasSucceeded == false {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        app = nil
    }

    // MARK: - Fasting Toggle Visibility Tests

    /// UAT Test 1: Fasting toggle appears when no food entries exist for the day
    /// Acceptance: Open Food Log for a day with NO food entries. A "Fasting Day" toggle card should appear below the header.
    func testFastingToggleVisibleWhenNoFoodEntries() {
        // GIVEN: User is on Food Log tab
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Navigate to a day with no entries (previous week - unlikely to have test data)
        let previousWeekButton = findPreviousWeekButton()
        XCTAssertTrue(previousWeekButton.waitForExistence(timeout: 3), "Previous week button should exist")
        previousWeekButton.tap()

        // Wait for week to update
        waitForUIUpdate()

        // THEN: Fasting toggle card should be visible (since no entries for that day)
        // Note: FastingToggleCard uses .accessibilityElement(children: .combine) which combines
        // into a Switch element type due to containing a Toggle
        let fastingToggleCard = app.switches["fasting-toggle-card"]
        XCTAssertTrue(
            fastingToggleCard.waitForExistence(timeout: 3),
            "Fasting toggle card should appear when no food entries exist for the day"
        )
    }

    /// UAT Test 2: Fasting toggle hidden when food is logged
    /// Acceptance: Open Food Log for a day WITH food entries. The fasting toggle should NOT be visible.
    func testFastingToggleHiddenWhenFoodLogged() {
        // GIVEN: User logs a food entry for today
        logTestFoodEntry()

        // WHEN: User views the Food Log for today
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // THEN: Fasting toggle card should NOT be visible
        let fastingToggleCard = app.switches["fasting-toggle-card"]
        XCTAssertFalse(
            fastingToggleCard.waitForExistence(timeout: 2),
            "Fasting toggle card should NOT appear when food entries exist for the day"
        )

        // Verify food entry is visible
        let foodEntryRow = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(
            foodEntryRow.waitForExistence(timeout: 3),
            "Food entry should be visible confirming we have logged food"
        )
    }

    // MARK: - Fasting Toggle Interaction Tests

    /// UAT Test 3: Mark day as fasting
    /// Acceptance: On a day with no entries, toggle "Fasting Day" on. Toggle should stay enabled when you navigate away and return.
    func testMarkDayAsFasting() {
        // GIVEN: User is on Food Log tab with no entries for a past day
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Navigate to week -3 to find an empty day (avoid collision with other tests)
        let previousWeekButton = findPreviousWeekButton()
        XCTAssertTrue(previousWeekButton.waitForExistence(timeout: 3), "Previous week button should exist")
        previousWeekButton.tap()
        waitForUIUpdate()
        previousWeekButton.tap()
        waitForUIUpdate()
        previousWeekButton.tap()
        waitForUIUpdate()

        // WHEN: User toggles fasting on
        let fastingToggleCard = app.switches["fasting-toggle-card"]
        XCTAssertTrue(
            fastingToggleCard.waitForExistence(timeout: 3),
            "Fasting toggle card should appear for empty day"
        )

        // Tap the switch portion (right side) to toggle fasting
        // SwiftUI Toggle requires coordinate-based tap on the switch itself
        fastingToggleCard.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        waitForUIUpdate()

        // THEN: Toggle state should persist after navigation
        // Navigate away
        let nextWeekButton = findNextWeekButton()
        XCTAssertTrue(nextWeekButton.waitForExistence(timeout: 3), "Next week button should exist")
        nextWeekButton.tap()
        waitForUIUpdate()

        // Navigate back
        previousWeekButton.tap()
        waitForUIUpdate()

        // Verify toggle card still exists and shows fasting state
        XCTAssertTrue(
            fastingToggleCard.waitForExistence(timeout: 3),
            "Fasting toggle card should still appear after navigation"
        )

        // Verify accessibility label indicates fasting is enabled
        let fastingLabel = fastingToggleCard.label
        XCTAssertTrue(
            fastingLabel.lowercased().contains("enabled") || fastingLabel.lowercased().contains("zero calories"),
            "Fasting toggle should indicate enabled state in accessibility label: \(fastingLabel)"
        )
    }

    /// Test: Fasting toggle can be toggled off after being enabled
    func testToggleFastingOff() {
        // GIVEN: User is on Food Log with fasting enabled for a day
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Navigate to previous week (navigate back 2 weeks to get a fresh day without prior state)
        let previousWeekButton = findPreviousWeekButton()
        previousWeekButton.tap()
        waitForUIUpdate()
        previousWeekButton.tap()
        waitForUIUpdate()

        // Enable fasting using coordinate-based tap on switch portion
        let fastingToggleCard = app.switches["fasting-toggle-card"]
        XCTAssertTrue(fastingToggleCard.waitForExistence(timeout: 3), "Fasting toggle should exist")

        // Check initial state - if not enabled, enable it first
        var initialLabel = fastingToggleCard.label
        if initialLabel.lowercased().contains("disabled") || initialLabel.lowercased().contains("toggle on") {
            fastingToggleCard.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            waitForUIUpdate()
        }

        // Verify it's now enabled
        initialLabel = fastingToggleCard.label
        XCTAssertTrue(
            initialLabel.lowercased().contains("enabled") || initialLabel.lowercased().contains("zero calories"),
            "Fasting toggle should be enabled before we try to disable it: \(initialLabel)"
        )

        // WHEN: User taps toggle to disable
        fastingToggleCard.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        waitForUIUpdate()

        // THEN: Toggle should show disabled state
        let fastingLabel = fastingToggleCard.label
        XCTAssertTrue(
            fastingLabel.lowercased().contains("disabled") || fastingLabel.lowercased().contains("toggle on"),
            "Fasting toggle should indicate disabled state: \(fastingLabel)"
        )
    }

    // MARK: - Element Finders

    /// Find the previous week navigation button
    private func findPreviousWeekButton() -> XCUIElement {
        let predicate = NSPredicate(format: "label == 'Previous week'")
        return app.buttons.matching(predicate).firstMatch
    }

    /// Find the next week navigation button
    private func findNextWeekButton() -> XCUIElement {
        let predicate = NSPredicate(format: "label == 'Next week'")
        return app.buttons.matching(predicate).firstMatch
    }

    // MARK: - Helpers

    /// Wait for UI to update after animations/transitions
    private func waitForUIUpdate(seconds: TimeInterval = 0.5) {
        let expectation = XCTestExpectation(description: "Wait for UI update")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: seconds + 0.5)
    }

    /// Logs a test food entry for use in tests
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
        waitForUIUpdate(seconds: 1.5)
    }
}
