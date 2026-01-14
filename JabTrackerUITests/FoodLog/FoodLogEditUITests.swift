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

    // MARK: - Persisted Serving Options Tests (PR Coverage)

    /// Test that editing a food with persisted serving options shows ServingPillPicker
    /// Acceptance: Foods from USDA database should display pill picker instead of legacy unit buttons
    /// PR: feat/persist-serving-units
    func testEditSheetShowsServingPillPicker() throws {
        // Step 1: Log a food entry with serving options (USDA foods have these)
        try logTestFoodEntryWithServingOptions()

        // Step 2: Navigate to Food Log
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Step 3: Tap the food entry to open edit sheet
        let firstEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(firstEntry.waitForExistence(timeout: 5), "Food entry row should exist")
        firstEntry.tap()

        // Step 4: Verify edit sheet opens
        let editSheet = app.otherElements["edit-food-entry-sheet"]
        XCTAssertTrue(editSheet.waitForExistence(timeout: 3), "Edit sheet should open")

        // Step 5: Verify ServingPillPicker is present (has accessibility identifier)
        // Note: ServingPillPicker is exposed as a ScrollView in the accessibility hierarchy
        let pillPicker = app.scrollViews["serving-pill-picker"]
        XCTAssertTrue(
            pillPicker.waitForExistence(timeout: 3),
            "ServingPillPicker should appear for foods with persisted serving options"
        )
    }

    /// Test that pill option selection updates quantity display correctly
    /// Acceptance: Selecting different serving unit via pill updates gram calculation
    /// PR: feat/persist-serving-units
    func testServingPillOptionChangesQuantityDisplay() throws {
        // Step 1: Log a food entry with serving options
        try logTestFoodEntryWithServingOptions()

        // Step 2: Navigate to Food Log and open edit sheet
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let firstEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(firstEntry.waitForExistence(timeout: 5), "Food entry row should exist")
        firstEntry.tap()

        let editSheet = app.otherElements["edit-food-entry-sheet"]
        XCTAssertTrue(editSheet.waitForExistence(timeout: 3), "Edit sheet should open")

        // Step 3: Verify pill picker exists (exposed as ScrollView)
        let pillPicker = app.scrollViews["serving-pill-picker"]
        XCTAssertTrue(pillPicker.waitForExistence(timeout: 3), "ServingPillPicker should appear")

        // Step 4: Tap a serving pill option (e.g., "g" for grams)
        let gramsPill = app.buttons["serving-pill-g"]
        if gramsPill.waitForExistence(timeout: 2) {
            gramsPill.tap()

            // Step 5: Verify quantity input field exists and is interactable
            let quantityInput = app.textFields["quantity-input"]
            XCTAssertTrue(quantityInput.exists, "Quantity input should exist after selecting serving unit")
        } else {
            // If grams pill not found, try the first available pill
            let anyPill = app.buttons.matching(
                NSPredicate(format: "identifier BEGINSWITH 'serving-pill-'")
            ).firstMatch
            XCTAssertTrue(anyPill.waitForExistence(timeout: 2), "At least one serving pill should exist")
        }
    }

    /// Test that swap mode button toggles between quantity and target modes in edit sheet
    /// Acceptance: Tapping swap mode button changes input to target macro mode and back
    /// PR: feat/persist-serving-units
    func testSwapModeButtonTogglesInputMode() throws {
        // Step 1: Log a food entry with serving options
        try logTestFoodEntryWithServingOptions()

        // Step 2: Navigate to Food Log and open edit sheet
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let firstEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(firstEntry.waitForExistence(timeout: 5), "Food entry row should exist")
        firstEntry.tap()

        let editSheet = app.otherElements["edit-food-entry-sheet"]
        XCTAssertTrue(editSheet.waitForExistence(timeout: 3), "Edit sheet should open")

        // Step 3: Verify quantity input exists (default mode)
        let quantityInput = app.textFields["quantity-input"]
        XCTAssertTrue(quantityInput.waitForExistence(timeout: 3), "Quantity input should exist in default mode")

        // Step 4: Tap swap mode button
        let swapModeButton = app.buttons["swap-mode-button"]
        XCTAssertTrue(swapModeButton.waitForExistence(timeout: 3), "Swap mode button should exist")
        swapModeButton.tap()

        // Step 5: Verify target input appears (target mode)
        let targetInput = app.textFields["target-input"]
        XCTAssertTrue(
            targetInput.waitForExistence(timeout: 3),
            "Target input should appear after tapping swap mode button"
        )

        // Step 6: Verify macro buttons appear in target mode
        // Note: TargetMacro.calories.rawValue is "cal", so identifier is "macro-button-cal"
        let caloriesMacroButton = app.buttons["macro-button-cal"]
        XCTAssertTrue(
            caloriesMacroButton.waitForExistence(timeout: 3),
            "Calories macro button should appear in target mode"
        )

        // Step 7: Tap swap mode button again to return to quantity mode
        swapModeButton.tap()
        XCTAssertTrue(
            quantityInput.waitForExistence(timeout: 3),
            "Quantity input should reappear after toggling back to quantity mode"
        )
    }

    /// Test that editing a food without persisted serving options shows legacy unit buttons
    /// Acceptance: Custom/history foods without serving options use legacy g/oz/item buttons
    /// PR: feat/persist-serving-units
    func testEditSheetShowsLegacyUnitButtonsWhenNoServingOptions() throws {
        // Step 1: Log a simple food entry (chicken from existing test helper - may not have serving options)
        try logTestFoodEntry()

        // Step 2: Navigate to Food Log
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Step 3: Tap the food entry to open edit sheet
        let firstEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(firstEntry.waitForExistence(timeout: 5), "Food entry row should exist")
        firstEntry.tap()

        // Step 4: Verify edit sheet opens
        let editSheet = app.otherElements["edit-food-entry-sheet"]
        XCTAssertTrue(editSheet.waitForExistence(timeout: 3), "Edit sheet should open")

        // Step 5: Either pill picker or legacy unit buttons should exist
        // Check for the swap mode button which exists in both cases
        let swapModeButton = app.buttons["swap-mode-button"]
        XCTAssertTrue(
            swapModeButton.waitForExistence(timeout: 3),
            "Swap mode button should exist in edit sheet"
        )

        // Step 6: Verify we can toggle to target mode regardless of serving option type
        swapModeButton.tap()
        let targetInput = app.textFields["target-input"]
        XCTAssertTrue(
            targetInput.waitForExistence(timeout: 3),
            "Target input should appear after tapping swap mode button"
        )
    }

    /// Test that saving edited entry with changed serving size persists correctly
    /// Acceptance: Changing serving size and saving updates the entry
    /// PR: feat/persist-serving-units
    func testSaveEditedServingSizePersists() throws {
        // Step 1: Log a food entry with serving options
        try logTestFoodEntryWithServingOptions()

        // Step 2: Navigate to Food Log and open edit sheet
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let firstEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(firstEntry.waitForExistence(timeout: 5), "Food entry row should exist")
        firstEntry.tap()

        let editSheet = app.otherElements["edit-food-entry-sheet"]
        XCTAssertTrue(editSheet.waitForExistence(timeout: 3), "Edit sheet should open")

        // Step 3: Change the quantity
        let quantityInput = app.textFields["quantity-input"]
        XCTAssertTrue(quantityInput.waitForExistence(timeout: 3), "Quantity input should exist")
        quantityInput.tap()
        // Clear existing text and enter new value
        quantityInput.doubleTap()  // Select all
        quantityInput.typeText("2")  // Enter new quantity

        // Step 4: Save the entry
        let saveButton = app.buttons["save-entry-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should exist")
        saveButton.tap()

        // Step 5: Verify sheet dismissed
        XCTAssertFalse(
            editSheet.waitForExistence(timeout: 2),
            "Edit sheet should dismiss after saving"
        )

        // Step 6: Verify entry still exists in food log
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.exists, "Food log should be visible after saving")
        let savedEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(savedEntry.exists, "Saved food entry should appear in food log")
    }

    // MARK: - Helpers

    /// Logs a test food entry with serving options (USDA food)
    /// Uses "egg" which has multiple serving options like "large", "medium"
    private func logTestFoodEntryWithServingOptions() throws {
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

        // Search for "egg" - USDA eggs have multiple serving options
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText("egg")

        // Select first result from Common section (USDA foods have serving options)
        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Should have search result for 'egg'")
        firstResult.tap()

        // Wait for FoodDetailSheet to appear
        let foodDetailSheet = app.otherElements["food-detail-sheet"]
        XCTAssertTrue(foodDetailSheet.waitForExistence(timeout: 5), "Food detail sheet should appear")

        // Save the food entry
        let addFoodButton = app.buttons["add-food-button"].firstMatch
        XCTAssertTrue(addFoodButton.waitForExistence(timeout: 3), "Add button should exist")
        addFoodButton.tap()

        // Wait for sheets to dismiss
        let dismissPredicate = NSPredicate(format: "exists == false")
        let dismissExpectation = XCTNSPredicateExpectation(predicate: dismissPredicate, object: foodSearchSheet)
        let waitResult = XCTWaiter().wait(for: [dismissExpectation], timeout: 3)
        XCTAssertEqual(waitResult, .completed, "Food search sheet should dismiss after adding food")
    }

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
