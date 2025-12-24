//
//  FoodLibraryUITests.swift
//  JabTrackerUITests
//
//  E2E tests for Food Library Integration (My Foods section).
//

import XCTest

final class FoodLibraryUITests: XCTestCase {
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

    /// Create a custom food with the given name via the UI
    private func createCustomFood(name: String) {
        // Open shortcuts and navigate to food search
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3), "Search shortcut should exist")
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Search for a base food
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText("egg")

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

        // Set custom name
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

    /// Open food search sheet
    private func openFoodSearch() {
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3), "Search shortcut should exist")
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")
    }

    // MARK: - My Foods Section

    /// My Foods section appears when user has custom foods
    /// Acceptance: Section header shows "My Foods" with custom food results
    func testMyFoodsSectionAppearsWithCustomFoods() {
        let customFoodName = "My Special Protein Shake"

        // Create a custom food first
        createCustomFood(name: customFoodName)

        // Open food search
        openFoodSearch()

        // Search for the custom food
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText("Special Protein")

        // Verify "My Foods" section header is visible
        let myFoodsSection = app.staticTexts["My Foods"]
        XCTAssertTrue(
            myFoodsSection.waitForExistence(timeout: 5),
            "My Foods section should appear when custom foods exist"
        )

        // Verify custom food appears in the results
        let customFoodResult = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(
            customFoodResult.waitForExistence(timeout: 3),
            "Custom food should appear in My Foods section"
        )
    }

    /// Custom foods appear before database foods in search
    /// Acceptance: My Foods section positioned before Common/Branded
    func testCustomFoodsPrioritizedInSearch() {
        // Create custom food with a common name that will also match database foods
        let customFoodName = "Custom Chicken Breast"
        createCustomFood(name: customFoodName)

        // Open food search
        openFoodSearch()

        // Search for "chicken" - should match both custom and database foods
        let searchField = app.textFields["food-search-field"]
        searchField.tap()
        searchField.typeText("chicken")

        // Wait for results
        let myFoodsSection = app.staticTexts["My Foods"]
        let commonSection = app.staticTexts["Common"]

        XCTAssertTrue(
            myFoodsSection.waitForExistence(timeout: 5),
            "My Foods section should appear"
        )

        // Wait for Common section too
        XCTAssertTrue(
            commonSection.waitForExistence(timeout: 5),
            "Common section should also appear for 'chicken'"
        )

        // Verify My Foods section appears above Common section (Y coordinate should be less)
        // This validates that custom foods are prioritized in the UI order
        if myFoodsSection.exists && commonSection.exists {
            XCTAssertLessThan(
                myFoodsSection.frame.minY,
                commonSection.frame.minY,
                "My Foods section should appear above Common section"
            )
        }
    }

    // MARK: - Edit Custom Food

    /// User can edit custom food via swipe action
    /// Acceptance: Swipe right reveals Edit, tapping opens CreateFoodSheet
    func testUserCanEditCustomFoodFromSearch() {
        let customFoodName = "Editable Test Food"

        // Create a custom food
        createCustomFood(name: customFoodName)

        // Open food search
        openFoodSearch()

        // Search for the custom food
        let searchField = app.textFields["food-search-field"]
        searchField.tap()
        searchField.typeText("Editable Test")

        // Wait for My Foods section
        let myFoodsSection = app.staticTexts["My Foods"]
        XCTAssertTrue(myFoodsSection.waitForExistence(timeout: 5), "My Foods section should appear")

        // Find the custom food row
        let customFoodResult = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(customFoodResult.waitForExistence(timeout: 3), "Custom food result should exist")

        // Swipe right to reveal edit button (edit is on leading edge)
        customFoodResult.swipeRight()

        // Verify "Edit" button appears
        let editButton = app.buttons["edit-custom-food-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button should appear after swipe right")

        // Tap Edit
        editButton.tap()

        // Verify CreateFoodSheet opens with food data pre-filled
        let createFoodSheet = app.otherElements["create-food-sheet"]
        XCTAssertTrue(createFoodSheet.waitForExistence(timeout: 3), "Create food sheet should open for editing")

        // Verify name field contains the food name
        let nameField = app.textFields["food-name-input"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Name field should exist")
        if let nameValue = nameField.value as? String {
            XCTAssertTrue(
                nameValue.contains("Editable") || nameValue.contains("Test"),
                "Name field should contain the custom food name"
            )
        }
    }

    /// Edited custom food updates in search results
    /// Acceptance: Changed name appears on next search
    func testEditedCustomFoodUpdatesInResults() {
        let originalName = "Original Food Name"
        let updatedName = "Completely New Name"

        // Create a custom food
        createCustomFood(name: originalName)

        // Open food search and find the food
        openFoodSearch()

        let searchField = app.textFields["food-search-field"]
        searchField.tap()
        searchField.typeText("Original Food")

        // Wait for My Foods section
        let myFoodsSection = app.staticTexts["My Foods"]
        XCTAssertTrue(myFoodsSection.waitForExistence(timeout: 5), "My Foods section should appear")

        // Swipe right to reveal edit button (edit is on leading edge)
        let customFoodResult = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'food-result-'")
        ).element(boundBy: 0)
        customFoodResult.swipeRight()

        let editButton = app.buttons["edit-custom-food-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button should appear after swipe right")
        editButton.tap()

        // Wait for CreateFoodSheet
        let createFoodSheet = app.otherElements["create-food-sheet"]
        XCTAssertTrue(createFoodSheet.waitForExistence(timeout: 3), "Create food sheet should appear")

        // Update the name
        let nameField = app.textFields["food-name-input"]
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

        // Wait for sheet to dismiss
        XCTAssertFalse(createFoodSheet.waitForExistence(timeout: 3), "Sheet should dismiss")

        // Dismiss all remaining sheets and wait for app to stabilize
        dismissAllSheets()
        Thread.sleep(forTimeInterval: 0.5)

        // Search for the updated name
        openFoodSearch()

        let newSearchField = app.textFields["food-search-field"]
        newSearchField.tap()
        newSearchField.typeText("Completely New")

        // Verify "My Foods" section appears with the updated food
        XCTAssertTrue(
            myFoodsSection.waitForExistence(timeout: 5),
            "My Foods section should show the updated custom food"
        )
    }

    // MARK: - Delete Custom Food

    /// User can delete custom food with confirmation
    /// Acceptance: Swipe left shows Delete, confirmation alert appears
    func testUserCanDeleteCustomFoodWithConfirmation() {
        let customFoodName = "Food To Delete"

        // Create a custom food
        createCustomFood(name: customFoodName)

        // Open food search
        openFoodSearch()

        // Search for the custom food
        let searchField = app.textFields["food-search-field"]
        searchField.tap()
        searchField.typeText("Food To Delete")

        // Wait for My Foods section
        let myFoodsSection = app.staticTexts["My Foods"]
        XCTAssertTrue(myFoodsSection.waitForExistence(timeout: 5), "My Foods section should appear")

        // Find the custom food row
        let customFoodResult = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(customFoodResult.waitForExistence(timeout: 3), "Custom food result should exist")

        // Swipe right (full swipe) to reveal delete
        customFoodResult.swipeLeft()

        // Look for delete button
        let deleteButton = app.buttons["delete-custom-food-button"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "Delete button should appear after swipe")

        // Tap Delete
        deleteButton.tap()

        // Verify confirmation alert appears
        let deleteAlert = app.alerts.firstMatch
        XCTAssertTrue(deleteAlert.waitForExistence(timeout: 3), "Confirmation alert should appear")

        // Verify alert has Delete and Cancel buttons
        let alertDeleteButton = deleteAlert.buttons["Delete"]
        let alertCancelButton = deleteAlert.buttons["Cancel"]
        XCTAssertTrue(alertDeleteButton.exists, "Alert should have Delete button")
        XCTAssertTrue(alertCancelButton.exists, "Alert should have Cancel button")
    }

    /// Deleting custom food removes it from search
    /// Acceptance: Deleted food no longer appears in results
    func testDeletedCustomFoodRemovedFromSearch() {
        let customFoodName = "Deletable Food Item"

        // Create a custom food
        createCustomFood(name: customFoodName)

        // Open food search and find the food
        openFoodSearch()

        let searchField = app.textFields["food-search-field"]
        searchField.tap()
        searchField.typeText("Deletable Food")

        // Wait for My Foods section
        let myFoodsSection = app.staticTexts["My Foods"]
        XCTAssertTrue(myFoodsSection.waitForExistence(timeout: 5), "My Foods section should appear")

        // Swipe and delete
        let customFoodResult = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'food-result-'")
        ).element(boundBy: 0)
        customFoodResult.swipeLeft()

        let deleteButton = app.buttons["delete-custom-food-button"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "Delete button should appear")
        deleteButton.tap()

        // Confirm deletion
        let deleteAlert = app.alerts.firstMatch
        XCTAssertTrue(deleteAlert.waitForExistence(timeout: 3), "Alert should appear")

        let alertDeleteButton = deleteAlert.buttons["Delete"]
        alertDeleteButton.tap()

        // Wait for alert to dismiss
        XCTAssertFalse(deleteAlert.waitForExistence(timeout: 2), "Alert should dismiss")

        // Clear search and search again
        let cancelButton = app.buttons["food-search-cancel-button"]
        if cancelButton.exists {
            cancelButton.tap()
        }

        // Re-open search
        openFoodSearch()

        let newSearchField = app.textFields["food-search-field"]
        newSearchField.tap()
        newSearchField.typeText("Deletable Food")

        // Wait a moment for search results
        Thread.sleep(forTimeInterval: 2.0)

        // My Foods section should NOT appear (food was deleted)
        XCTAssertFalse(
            myFoodsSection.waitForExistence(timeout: 3),
            "My Foods section should not appear after food is deleted"
        )
    }

    /// User can cancel delete action
    /// Acceptance: Tapping Cancel dismisses alert, food remains
    func testUserCanCancelDeleteAction() {
        let customFoodName = "Food That Stays"

        // Create a custom food
        createCustomFood(name: customFoodName)

        // Open food search
        openFoodSearch()

        // Search for the custom food
        let searchField = app.textFields["food-search-field"]
        searchField.tap()
        searchField.typeText("Food That Stays")

        // Wait for My Foods section
        let myFoodsSection = app.staticTexts["My Foods"]
        XCTAssertTrue(myFoodsSection.waitForExistence(timeout: 5), "My Foods section should appear")

        // Find and swipe to delete
        let customFoodResult = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS 'food-result-'")
        ).element(boundBy: 0)
        customFoodResult.swipeLeft()

        let deleteButton = app.buttons["delete-custom-food-button"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "Delete button should appear")
        deleteButton.tap()

        // Tap Cancel in the alert
        let deleteAlert = app.alerts.firstMatch
        XCTAssertTrue(deleteAlert.waitForExistence(timeout: 3), "Alert should appear")

        let cancelButton = deleteAlert.buttons["Cancel"]
        cancelButton.tap()

        // Verify alert is dismissed
        XCTAssertFalse(deleteAlert.waitForExistence(timeout: 2), "Alert should dismiss after cancel")

        // Verify food still appears in search
        XCTAssertTrue(myFoodsSection.exists, "My Foods section should still exist")
        XCTAssertTrue(customFoodResult.exists, "Custom food should still exist after canceling delete")
    }
}
