//
//  FoodLogEditUITests.swift
//  JabTrackerUITests
//
//  E2E tests for food entry tap-to-edit functionality.
//

import XCTest

final class FoodLogEditUITests: XCTestCase {
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

    // MARK: - Tap to Edit Tests

    /// User can tap a food entry to open edit sheet
    /// Acceptance: Tap entry → EditFoodEntrySheet opens with entry data
    func testTapFoodEntryOpensEditSheet() throws {
        // Step 1: Log a food entry first
        try logTestFoodEntry()

        // Step 2: Navigate to Food Log
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Step 3: Tap the food entry row (wrapped in Button now)
        let firstEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(firstEntry.waitForExistence(timeout: 5), "Food entry row should exist after logging")
        firstEntry.tap()

        // Step 4: Verify edit sheet opens
        let editSheet = app.otherElements["edit-food-entry-sheet"]
        XCTAssertTrue(editSheet.waitForExistence(timeout: 3), "Edit sheet should open when tapping food entry")
    }

    /// User can dismiss edit sheet and return to food log
    /// Acceptance: Cancel button dismisses sheet, food log remains visible
    func testCanDismissEditSheet() throws {
        // Step 1: Log a food entry first
        try logTestFoodEntry()

        // Step 2: Navigate to Food Log
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Step 3: Tap entry to open edit sheet
        let firstEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(firstEntry.waitForExistence(timeout: 5), "Food entry row should exist")
        firstEntry.tap()

        // Step 4: Wait for edit sheet
        let editSheet = app.otherElements["edit-food-entry-sheet"]
        XCTAssertTrue(editSheet.waitForExistence(timeout: 3), "Edit sheet should open")

        // Step 5: Tap Cancel
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()

        // Step 6: Verify sheet dismissed and food log still visible
        XCTAssertFalse(editSheet.waitForExistence(timeout: 2), "Edit sheet should be dismissed")
        XCTAssertTrue(foodLogView.exists, "Food log should still be visible after dismissing edit sheet")
    }

    /// Swipe-to-edit still works after adding tap-to-edit
    /// Acceptance: Swipe left reveals Edit button, tapping it opens edit sheet
    func testSwipeToEditStillWorks() throws {
        // Step 1: Log a food entry first
        try logTestFoodEntry()

        // Step 2: Navigate to Food Log
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Step 3: Swipe right on entry (Edit is on leading edge)
        let firstEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(firstEntry.waitForExistence(timeout: 5), "Food entry row should exist")
        firstEntry.swipeRight()

        // Step 4: Tap Edit swipe action
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button should appear after swipe")
        editButton.tap()

        // Step 5: Verify edit sheet opens
        let editSheet = app.otherElements["edit-food-entry-sheet"]
        XCTAssertTrue(editSheet.waitForExistence(timeout: 3), "Edit sheet should open from swipe action")
    }

    // MARK: - Helpers

    /// Logs a test food entry for use in edit tests
    private func logTestFoodEntry() throws {
        // Navigate to Food Log tab
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Open Food Search sheet via + button
        let addButton = app.buttons["add-food-button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3), "Add food button should exist")
        addButton.tap()

        // Wait for Food Search Sheet (this is what FoodLogView presents)
        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 5), "Food search sheet should appear")

        // Search for a common food
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText("chicken")

        // Select first result
        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Should have search result for 'chicken'")
        firstResult.tap()

        // Wait for FoodDetailSheet to appear (identifier is "food-detail-sheet")
        let foodDetailSheet = app.otherElements["food-detail-sheet"]
        XCTAssertTrue(foodDetailSheet.waitForExistence(timeout: 5), "Food detail sheet should appear")

        // Save the food entry using the Add button in the detail sheet
        // The Add button has identifier "add-food-button" - tap it within the sheet context
        let addFoodButton = app.buttons["add-food-button"].firstMatch
        XCTAssertTrue(addFoodButton.waitForExistence(timeout: 3), "Add button should exist in food detail sheet")
        addFoodButton.tap()

        // Wait for sheets to dismiss and entry to be logged
        let dismissPredicate = NSPredicate(format: "exists == false")
        let dismissExpectation = XCTNSPredicateExpectation(predicate: dismissPredicate, object: foodSearchSheet)
        let waitResult = XCTWaiter().wait(for: [dismissExpectation], timeout: 3)
        XCTAssertEqual(waitResult, .completed, "Food search sheet should dismiss after adding food")
    }
}
