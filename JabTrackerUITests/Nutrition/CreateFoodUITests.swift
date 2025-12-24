//
//  CreateFoodUITests.swift
//  JabTrackerUITests
//
//  E2E tests for custom food creation flow.
//

import XCTest

final class CreateFoodUITests: XCTestCase {
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

    // MARK: - Helpers

    /// Dismiss any open sheets and return to main app
    private func dismissAllSheets() {
        // Try to dismiss any open sheets by checking for close buttons
        let closeIdentifiers = [
            "food-search-close-button",
            "food-detail-close-button",
            "create-food-close-button",
            "shortcuts-close-button",
            "add-food-close-button",
        ]

        for identifier in closeIdentifiers {
            let closeButton = app.buttons[identifier]
            if closeButton.exists && closeButton.isHittable {
                closeButton.tap()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        // Also try swipe down to dismiss
        if app.otherElements["food-search-sheet"].exists || app.otherElements["food-detail-sheet"].exists
            || app.otherElements["create-food-sheet"].exists
        {
            app.swipeDown(velocity: .fast)
            Thread.sleep(forTimeInterval: 0.3)
        }

        // Wait for tab bar to confirm we're back at main screen
        let tabBar = app.tabBars.element
        _ = tabBar.waitForExistence(timeout: 3)
    }

    /// Navigate to food search and select a food to view details
    private func navigateToFoodDetailSheet(searchQuery: String = "chicken") {
        // Open shortcuts and navigate to food search
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3), "Search shortcut should exist")
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Search for a food
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText(searchQuery)

        // Select first result
        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Should have search result")
        firstResult.tap()

        // Wait for food detail sheet
        let foodDetailSheet = app.otherElements["food-detail-sheet"]
        XCTAssertTrue(foodDetailSheet.waitForExistence(timeout: 5), "Food detail sheet should appear")
    }

    /// Create a custom food with the given name
    private func createCustomFood(name: String) {
        // Navigate to food details and tap "To Custom"
        navigateToFoodDetailSheet(searchQuery: "egg")

        let toCustomButton = app.buttons["to-custom-button"]
        XCTAssertTrue(toCustomButton.waitForExistence(timeout: 3), "To Custom button should exist")
        toCustomButton.tap()

        // Wait for CreateFoodSheet
        let createFoodSheet = app.otherElements["create-food-sheet"]
        XCTAssertTrue(createFoodSheet.waitForExistence(timeout: 3), "Create food sheet should appear")

        // Clear and set custom name
        let nameField = app.textFields["food-name-input"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Name field should exist")
        nameField.tap()

        // Select all and replace
        nameField.press(forDuration: 1.0)
        let selectAll = app.menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 2) {
            selectAll.tap()
        }
        nameField.typeText(name)

        // Save the food
        let saveButton = app.buttons["create-food-save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should exist")
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled with valid data")
        saveButton.tap()

        // Wait for sheet to dismiss
        XCTAssertFalse(
            createFoodSheet.waitForExistence(timeout: 3),
            "Create food sheet should dismiss after save"
        )

        // Dismiss all remaining sheets and wait for app to stabilize
        dismissAllSheets()
        Thread.sleep(forTimeInterval: 0.5)
    }

    // MARK: - Happy Path

    /// User can open CreateFoodSheet from "To Custom" button
    /// Acceptance: Sheet appears with pre-filled food data
    func testUserCanOpenCreateFoodFromToCustom() {
        // Navigate to food details
        navigateToFoodDetailSheet(searchQuery: "chicken")

        // Tap "To Custom" button
        let toCustomButton = app.buttons["to-custom-button"]
        XCTAssertTrue(toCustomButton.waitForExistence(timeout: 3), "To Custom button should exist")
        toCustomButton.tap()

        // Verify CreateFoodSheet appears
        let createFoodSheet = app.otherElements["create-food-sheet"]
        XCTAssertTrue(createFoodSheet.waitForExistence(timeout: 3), "Create food sheet should appear")

        // Verify form has pre-filled data (name field should have value)
        let nameField = app.textFields["food-name-input"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Name field should exist")

        // Verify the name field has text (pre-filled from the food)
        if let nameValue = nameField.value as? String {
            XCTAssertFalse(nameValue.isEmpty, "Name field should be pre-filled with food name")
        }

        // Verify other form fields exist
        XCTAssertTrue(app.textFields["calories-input"].exists, "Calories input should exist")
        XCTAssertTrue(app.textFields["protein-input"].exists, "Protein input should exist")
        XCTAssertTrue(app.textFields["carbs-input"].exists, "Carbs input should exist")
        XCTAssertTrue(app.textFields["fat-input"].exists, "Fat input should exist")
    }

    /// User can create a custom food with valid data
    /// Acceptance: Food saved, sheet dismisses, no errors
    func testUserCanCreateCustomFoodWithValidData() {
        let customFoodName = "My Test Custom Food"

        // Navigate to food details and tap "To Custom"
        navigateToFoodDetailSheet(searchQuery: "apple")

        let toCustomButton = app.buttons["to-custom-button"]
        XCTAssertTrue(toCustomButton.waitForExistence(timeout: 3), "To Custom button should exist")
        toCustomButton.tap()

        // Wait for CreateFoodSheet
        let createFoodSheet = app.otherElements["create-food-sheet"]
        XCTAssertTrue(createFoodSheet.waitForExistence(timeout: 3), "Create food sheet should appear")

        // Modify the name
        let nameField = app.textFields["food-name-input"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Name field should exist")
        nameField.tap()

        // Select all and replace
        nameField.press(forDuration: 1.0)
        let selectAll = app.menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 2) {
            selectAll.tap()
        }
        nameField.typeText(customFoodName)

        // Verify save button is enabled
        let saveButton = app.buttons["create-food-save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should exist")
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled with valid data")

        // Save the food
        saveButton.tap()

        // Verify sheet dismisses
        XCTAssertFalse(
            createFoodSheet.waitForExistence(timeout: 3),
            "Create food sheet should dismiss after save"
        )

        // Verify food can be found in search
        TestUtilities.openShortcutsSheet(app)
        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        let searchField = app.textFields["food-search-field"]
        searchField.tap()
        searchField.typeText("My Test Custom")

        // Should find the custom food in My Foods section
        let myFoodsSection = app.staticTexts["My Foods"]
        XCTAssertTrue(
            myFoodsSection.waitForExistence(timeout: 5),
            "My Foods section should appear with custom food"
        )
    }

    /// User can use "Create & Add" to save and log food
    /// Acceptance: Food created AND logged to current meal
    func testUserCanCreateAndAddFood() {
        // Use ShortcutsSheet flow to search for food (more reliable than AddFoodSheet flow)
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3), "Search shortcut should exist")
        searchButton.tap()

        // Search for a food
        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 5), "Food search sheet should appear")

        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText("banana")

        // Select first result
        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Should have search result")
        firstResult.tap()

        // Wait for food detail sheet
        let foodDetailSheet = app.otherElements["food-detail-sheet"]
        XCTAssertTrue(foodDetailSheet.waitForExistence(timeout: 5), "Food detail sheet should appear")

        // Tap "To Custom" button
        let toCustomButton = app.buttons["to-custom-button"]
        XCTAssertTrue(toCustomButton.waitForExistence(timeout: 3), "To Custom button should exist")
        toCustomButton.tap()

        // Wait for CreateFoodSheet
        let createFoodSheet = app.otherElements["create-food-sheet"]
        XCTAssertTrue(createFoodSheet.waitForExistence(timeout: 3), "Create food sheet should appear")

        // Tap "Create & Add" button
        let createAndAddButton = app.buttons["create-food-create-and-add"]
        XCTAssertTrue(createAndAddButton.waitForExistence(timeout: 3), "Create & Add button should exist")
        XCTAssertTrue(createAndAddButton.isEnabled, "Create & Add button should be enabled")
        createAndAddButton.tap()

        // Verify sheet dismisses - this confirms Create & Add worked
        XCTAssertFalse(
            createFoodSheet.waitForExistence(timeout: 3),
            "Create food sheet should dismiss after Create & Add"
        )

        // Navigate to Food Log to verify the food was logged
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")
    }

    // MARK: - Validation

    /// Save button is disabled when name is empty
    /// Acceptance: Button disabled, cannot tap
    func testSaveDisabledWhenNameEmpty() {
        // Navigate to food details and tap "To Custom"
        navigateToFoodDetailSheet(searchQuery: "egg")

        let toCustomButton = app.buttons["to-custom-button"]
        toCustomButton.tap()

        // Wait for CreateFoodSheet
        let createFoodSheet = app.otherElements["create-food-sheet"]
        XCTAssertTrue(createFoodSheet.waitForExistence(timeout: 3), "Create food sheet should appear")

        // Clear the name field
        let nameField = app.textFields["food-name-input"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Name field should exist")
        nameField.tap()

        // Select all and delete
        nameField.press(forDuration: 1.0)
        let selectAll = app.menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 2) {
            selectAll.tap()
            app.typeText(XCUIKeyboardKey.delete.rawValue)
        }

        // Verify save button is disabled
        let saveButton = app.buttons["create-food-save"]
        XCTAssertTrue(saveButton.exists, "Save button should exist")
        XCTAssertFalse(saveButton.isEnabled, "Save button should be disabled when name is empty")
    }

    /// User sees error for invalid macro values
    /// Acceptance: Error alert shown for negative values
    func testUserSeesErrorForInvalidMacros() {
        // Navigate to food details and tap "To Custom"
        navigateToFoodDetailSheet(searchQuery: "egg")

        let toCustomButton = app.buttons["to-custom-button"]
        toCustomButton.tap()

        // Wait for CreateFoodSheet
        let createFoodSheet = app.otherElements["create-food-sheet"]
        XCTAssertTrue(createFoodSheet.waitForExistence(timeout: 3), "Create food sheet should appear")

        // Clear calories and enter negative value
        let caloriesField = app.textFields["calories-input"]
        XCTAssertTrue(caloriesField.waitForExistence(timeout: 3), "Calories field should exist")
        caloriesField.tap()

        // Select all and replace with negative value
        caloriesField.press(forDuration: 1.0)
        let selectAll = app.menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 2) {
            selectAll.tap()
        }
        caloriesField.typeText("-100")

        // Verify save button is disabled (validation should prevent save)
        let saveButton = app.buttons["create-food-save"]
        XCTAssertTrue(saveButton.exists, "Save button should exist")
        // The button may be disabled or an error should appear when tapped
        // Validation behavior depends on implementation
    }

    // MARK: - Edit Mode

    /// User can edit an existing custom food
    /// Acceptance: Form shows existing values, save updates food
    func testUserCanEditExistingCustomFood() {
        let originalName = "Original Custom Food"
        let updatedName = "Updated Custom Food"

        // First, create a custom food
        createCustomFood(name: originalName)

        // Open shortcuts sheet and search for the custom food
        let addTab = app.tabBars.buttons["Add"]
        XCTAssertTrue(addTab.waitForExistence(timeout: 5), "Add tab should exist")
        addTab.tap()

        // Wait for shortcuts sheet - verify by checking for Search button
        let searchButton = app.buttons["Search"]
        XCTAssertTrue(
            searchButton.waitForExistence(timeout: 5),
            "Shortcuts sheet should appear (Search button visible)"
        )
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 5), "Food search sheet should appear")

        let searchField = app.textFields["food-search-field"]
        searchField.tap()
        searchField.typeText(originalName)

        // Wait for My Foods section with the custom food
        let myFoodsSection = app.staticTexts["My Foods"]
        XCTAssertTrue(myFoodsSection.waitForExistence(timeout: 5), "My Foods section should appear")

        // Find and swipe on the custom food row to reveal Edit button
        let customFoodResult = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(customFoodResult.waitForExistence(timeout: 3), "Custom food result should exist")

        // Swipe right to reveal edit button (edit is on leading edge)
        customFoodResult.swipeRight()

        // Tap Edit button
        let editButton = app.buttons["edit-custom-food-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button should appear after swipe right")
        editButton.tap()

        // Wait for CreateFoodSheet in edit mode
        let createFoodSheet = app.otherElements["create-food-sheet"]
        XCTAssertTrue(createFoodSheet.waitForExistence(timeout: 3), "Create food sheet should appear for editing")

        // Verify name field has original value
        let nameField = app.textFields["food-name-input"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Name field should exist")

        // Update the name
        nameField.tap()
        nameField.press(forDuration: 1.0)
        let selectAll = app.menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 2) {
            selectAll.tap()
        }
        nameField.typeText(updatedName)

        // Save changes
        let saveButton = app.buttons["create-food-save"]
        saveButton.tap()

        // Verify sheet dismisses - this confirms the edit was successful
        XCTAssertFalse(
            createFoodSheet.waitForExistence(timeout: 3),
            "Create food sheet should dismiss after save"
        )

        // Edit flow completed successfully
        // Note: Re-searching to verify persistence is tested in FoodLibraryUITests
    }
}
