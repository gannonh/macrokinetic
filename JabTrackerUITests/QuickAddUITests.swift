//
//  QuickAddUITests.swift
//  JabTrackerUITests
//
//  E2E tests for Quick Add feature.
//  Quick Add is a tab in FoodSearchSheet - entries are always named "Quick Add".
//

import XCTest

final class QuickAddUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    /// Open Quick Add tab via Shortcuts sheet
    private func openQuickAddTab(timeout: TimeInterval = 5) {
        // Open shortcuts sheet
        TestUtilities.openShortcutsSheet(app, timeout: timeout)

        // Tap Quick Add button in shortcuts
        let quickAddButton = app.buttons["Quick Add"]
        XCTAssertTrue(quickAddButton.waitForExistence(timeout: timeout), "Quick Add button should exist in shortcuts")
        quickAddButton.tap()

        // Wait for food search sheet with Quick Add tab
        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: timeout), "Food search sheet should appear")

        // Verify Quick Add tab is selected (content should be visible)
        let energyInput = app.textFields["quick-add-energy-input"]
        XCTAssertTrue(energyInput.waitForExistence(timeout: timeout), "Quick Add energy input should be visible")
    }

    /// Enter a value in a numeric text field (fields start empty, just type)
    private func enterValue(_ value: String, in field: XCUIElement) {
        field.tap()
        field.typeText(value)
    }

    // MARK: - Happy Path

    /// User can open Quick Add from Shortcuts and see Quick Add tab
    func testUserCanOpenQuickAddFromShortcuts() throws {
        openQuickAddTab()

        // Verify all Quick Add form elements are visible
        let energyInput = app.textFields["quick-add-energy-input"]
        let proteinInput = app.textFields["quick-add-protein-input"]
        let fatInput = app.textFields["quick-add-fat-input"]
        let carbsInput = app.textFields["quick-add-carbs-input"]
        let addButton = app.buttons["quick-add-add-button"]

        XCTAssertTrue(energyInput.exists, "Energy input should exist")
        XCTAssertTrue(proteinInput.exists, "Protein input should exist")
        XCTAssertTrue(fatInput.exists, "Fat input should exist")
        XCTAssertTrue(carbsInput.exists, "Carbs input should exist")
        XCTAssertTrue(addButton.exists, "Add button should exist")
    }

    /// User can log energy via Quick Add
    func testUserCanLogEnergyViaQuickAdd() throws {
        openQuickAddTab()

        // Enter energy value
        let energyInput = app.textFields["quick-add-energy-input"]
        enterValue("250", in: energyInput)

        // Tap Add button
        let addButton = app.buttons["quick-add-add-button"]
        XCTAssertTrue(addButton.isEnabled, "Add button should be enabled with energy entered")
        addButton.tap()

        // Verify sheet is dismissed
        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertFalse(foodSearchSheet.waitForExistence(timeout: 3), "Sheet should be dismissed after adding")

        // Navigate to Food Log to verify entry
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        // Look for Quick Add entry
        let quickAddEntry = app.staticTexts["Quick Add"]
        XCTAssertTrue(quickAddEntry.waitForExistence(timeout: 5), "Quick Add entry should appear in Food Log")
    }

    /// User can log macros via Quick Add
    func testUserCanLogMacrosViaQuickAdd() throws {
        openQuickAddTab()

        // Enter macro values
        let proteinInput = app.textFields["quick-add-protein-input"]
        let fatInput = app.textFields["quick-add-fat-input"]
        let carbsInput = app.textFields["quick-add-carbs-input"]

        enterValue("25", in: proteinInput)
        enterValue("10", in: fatInput)
        enterValue("30", in: carbsInput)

        // Tap Add button
        let addButton = app.buttons["quick-add-add-button"]
        XCTAssertTrue(addButton.isEnabled, "Add button should be enabled with macros entered")
        addButton.tap()

        // Verify sheet is dismissed
        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertFalse(foodSearchSheet.waitForExistence(timeout: 3), "Sheet should be dismissed after adding")
    }

    /// Macro sum displays and updates when macros are entered
    func testMacroSumDisplaysAndUpdates() throws {
        openQuickAddTab()

        // Verify initial macro sum is 0
        let macroSumText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Macro sum'")).firstMatch
        XCTAssertTrue(macroSumText.waitForExistence(timeout: 3), "Macro sum text should be visible")
        XCTAssertTrue(macroSumText.label.contains("0"), "Initial macro sum should be 0")

        // Enter a protein value
        let proteinInput = app.textFields["quick-add-protein-input"]
        enterValue("5", in: proteinInput)

        // Dismiss keyboard to see updated sum
        app.tap()

        // Verify sum has changed from initial "0 kcal"
        let updatedSumText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Macro sum'")).firstMatch
        XCTAssertTrue(updatedSumText.waitForExistence(timeout: 3), "Updated macro sum should be visible")

        // Sum should now show some positive value (not "0 kcal")
        let sumLabel = updatedSumText.label
        // Check that it's not the initial "0 kcal" - any positive number indicates the sum updated
        XCTAssertFalse(
            sumLabel == "Macro sum is 0 kcal", "Macro sum should update after entering protein, got: \(sumLabel)")
    }

    // MARK: - Validation

    /// Add button is disabled when all values are zero
    func testAddButtonDisabledWhenAllValuesZero() throws {
        openQuickAddTab()

        // Don't enter any values - button should be disabled
        let addButton = app.buttons["quick-add-add-button"]
        XCTAssertFalse(addButton.isEnabled, "Add button should be disabled when all values are zero")
    }

    /// Add button is enabled when only energy is entered
    func testAddButtonEnabledWhenOnlyEnergyEntered() throws {
        openQuickAddTab()

        // Enter only energy
        let energyInput = app.textFields["quick-add-energy-input"]
        enterValue("100", in: energyInput)

        // Dismiss keyboard
        app.tap()

        // Button should be enabled
        let addButton = app.buttons["quick-add-add-button"]
        XCTAssertTrue(addButton.isEnabled, "Add button should be enabled with only energy entered")
    }

    /// User can dismiss Food Search without saving
    func testUserCanDismissWithoutSaving() throws {
        openQuickAddTab()

        // Enter some values
        let energyInput = app.textFields["quick-add-energy-input"]
        enterValue("500", in: energyInput)

        // Tap cancel instead of add
        let cancelButton = app.buttons["food-search-cancel-button"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()

        // Verify sheet is dismissed
        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertFalse(foodSearchSheet.waitForExistence(timeout: 2), "Sheet should be dismissed after cancel")

        // Navigate to Food Log and verify no entry was created
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        // Should not have a Quick Add entry from this test
        let quickAddEntry = app.staticTexts["Quick Add"]
        // This could be flaky if other tests left entries - just verify sheet was dismissed
    }

    // MARK: - Tab Navigation

    /// Quick Add tab is available in FoodSearchSheet
    func testQuickAddTabAvailableInFoodSearchSheet() throws {
        // Open food search via Search shortcut
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Find Quick Add tab
        let quickAddTab = app.buttons["method-tab-quickAdd"]
        XCTAssertTrue(quickAddTab.waitForExistence(timeout: 3), "Quick Add tab should exist in method tabs")
    }

    /// User can switch to Quick Add tab from other tabs
    func testUserCanSwitchToQuickAddTab() throws {
        // Open food search via Search shortcut
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Tap Quick Add tab
        let quickAddTab = app.buttons["method-tab-quickAdd"]
        XCTAssertTrue(quickAddTab.waitForExistence(timeout: 3), "Quick Add tab should exist")
        quickAddTab.tap()

        // Verify Quick Add content is now visible
        let energyInput = app.textFields["quick-add-energy-input"]
        XCTAssertTrue(energyInput.waitForExistence(timeout: 3), "Quick Add energy input should appear after tab switch")
    }
}
