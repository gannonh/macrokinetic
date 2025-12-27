//
//  FoodLibraryUITests.swift
//  JabTrackerUITests
//
//  E2E tests for Food Library Integration.
//  Includes both the "My Foods" section in search (Phase 3) and the Library tab (Phase 7).
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

    // MARK: - Library Tab (Phase 7)

    /// Navigate to Library tab from food search sheet
    private func navigateToLibraryTab() {
        // Given: App is launched, open food search
        openFoodSearch()

        // When: Tap Library method tab
        let libraryTab = app.buttons["method-tab-library"]
        XCTAssertTrue(libraryTab.waitForExistence(timeout: 5), "Library method tab should exist")
        libraryTab.tap()

        // Wait for Library content to load - verify by checking for the Foods tab button
        // which indicates we're on the Library tab
        let foodsTab = app.buttons["food-library-tab-foods"]
        XCTAssertTrue(foodsTab.waitForExistence(timeout: 5), "Food library content should appear (Foods tab visible)")
    }

    /// User can access Library tab from food search
    /// Acceptance: Tap Library tab, Foods tab is selected by default
    func testAccessLibraryTabFromFoodSearch() {
        // Given: App is launched
        // When: Open food search and tap Library tab
        navigateToLibraryTab()

        // Then: Foods tab should be selected by default
        let foodsTab = app.buttons["food-library-tab-foods"]
        XCTAssertTrue(foodsTab.waitForExistence(timeout: 3), "Foods tab should exist")
        // Verify Foods tab is visually selected (it's the default)
        // The header showing "Foods" confirms we're on the Foods tab
        let foodsHeader = app.staticTexts["Foods"]
        XCTAssertTrue(foodsHeader.waitForExistence(timeout: 3), "Foods header should be visible")
    }

    /// User can access Library from Your Foods shortcut
    /// Acceptance: Tap +, tap Your Foods, Library opens on Foods tab
    func testAccessLibraryFromYourFoodsShortcut() {
        // Given: App is launched
        // When: Open shortcuts sheet
        TestUtilities.openShortcutsSheet(app)

        // And: Tap "Your Foods" shortcut
        let yourFoodsButton = app.buttons["Your Foods"]
        XCTAssertTrue(yourFoodsButton.waitForExistence(timeout: 3), "Your Foods shortcut should exist")
        yourFoodsButton.tap()

        // Then: Food search sheet opens with Library tab selected
        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 5), "Food search sheet should appear")

        // And: Library content should be visible (verified by Foods tab button presence)
        let foodsTab = app.buttons["food-library-tab-foods"]
        XCTAssertTrue(foodsTab.waitForExistence(timeout: 5), "Food library content should appear (Foods tab visible)")

        // And: Foods header should be visible
        let foodsHeader = app.staticTexts["Foods"]
        XCTAssertTrue(foodsHeader.waitForExistence(timeout: 3), "Foods header should be visible")
    }

    /// User sees custom foods in Library tab
    /// Acceptance: Create a custom food, open Library, food appears in list
    func testCustomFoodsAppearInLibraryTab() {
        let customFoodName = "Library Test Food"

        // Given: User has created a custom food
        createCustomFood(name: customFoodName)

        // When: User opens food search and navigates to Library tab
        navigateToLibraryTab()

        // Then: Custom food should appear in the Library list
        // Look for any food library row
        let foodRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-library-row-'")
        ).element(boundBy: 0)
        XCTAssertTrue(foodRow.waitForExistence(timeout: 5), "Food row should appear in Library")

        // And: The food name should be visible
        let foodNameText = app.staticTexts[customFoodName]
        XCTAssertTrue(foodNameText.waitForExistence(timeout: 3), "Custom food name should be visible in Library")
    }

    /// User can sort foods by name in Library tab
    /// Acceptance: Tap sort menu, select Name, foods reorder alphabetically
    func testSortFoodsByNameInLibrary() {
        // Given: User has created multiple custom foods
        createCustomFood(name: "Zebra Snack")
        createCustomFood(name: "Apple Pie Custom")

        // When: User opens Library tab
        navigateToLibraryTab()

        // And: Taps the sort menu (identifier is food-library-content, shown as "Date Added" button)
        let sortMenu = app.buttons["food-library-content"]
        XCTAssertTrue(sortMenu.waitForExistence(timeout: 3), "Sort menu should exist")
        sortMenu.tap()

        // And: Selects "Name" sort option
        let nameOption = app.buttons["Name"]
        XCTAssertTrue(nameOption.waitForExistence(timeout: 3), "Name sort option should exist")
        nameOption.tap()

        // Then: Sort menu should now show "Name"
        // The menu label contains the current sort option text
        let nameText = app.staticTexts["Name"]
        XCTAssertTrue(nameText.waitForExistence(timeout: 3), "Sort menu should show Name as selected")
    }

    /// User can sort foods by date added in Library tab
    /// Acceptance: Tap sort menu, select Date Added, foods order by date
    func testSortFoodsByDateAddedInLibrary() {
        // Given: User has created custom foods
        createCustomFood(name: "Date Test Food")

        // When: User opens Library tab
        navigateToLibraryTab()

        // And: Taps the sort menu (identifier is food-library-content, default is "Date Added")
        let sortMenu = app.buttons["food-library-content"]
        XCTAssertTrue(sortMenu.waitForExistence(timeout: 3), "Sort menu should exist")
        sortMenu.tap()

        // First, change to "Name" sort (so "Date Added" isn't the current selection)
        // This avoids the "multiple matching elements" issue when testing Date Added
        let nameOption = app.buttons["Name"]
        XCTAssertTrue(nameOption.waitForExistence(timeout: 3), "Name sort option should exist")
        nameOption.tap()

        // Verify Name is now selected
        let nameText = app.staticTexts["Name"]
        XCTAssertTrue(nameText.waitForExistence(timeout: 3), "Sort menu should show Name as selected")

        // Now test selecting "Date Added" (only one element with this label now)
        sortMenu.tap()

        let dateAddedOption = app.buttons["Date Added"]
        XCTAssertTrue(dateAddedOption.waitForExistence(timeout: 3), "Date Added sort option should exist")
        dateAddedOption.tap()

        // Then: Sort menu should show "Date Added" as selected
        let dateAddedText = app.staticTexts["Date Added"]
        XCTAssertTrue(dateAddedText.waitForExistence(timeout: 3), "Sort menu should show Date Added as selected")
    }

    /// User can tap food in Library to add to meal
    /// Acceptance: Tap food in Library, FoodDetailSheet opens
    func testTapFoodInLibraryOpensDetailSheet() {
        let customFoodName = "Tappable Test Food"

        // Given: User has created a custom food
        createCustomFood(name: customFoodName)

        // When: User opens Library tab
        navigateToLibraryTab()

        // And: Taps on a food row
        let foodRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-library-row-'")
        ).element(boundBy: 0)
        XCTAssertTrue(foodRow.waitForExistence(timeout: 5), "Food row should exist")
        foodRow.tap()

        // Then: FoodDetailSheet should open
        let foodDetailSheet = app.otherElements["food-detail-sheet"]
        XCTAssertTrue(foodDetailSheet.waitForExistence(timeout: 5), "Food detail sheet should appear")

        // And: The food name should be visible in the detail sheet
        let foodNameInDetail = app.staticTexts[customFoodName]
        XCTAssertTrue(foodNameInDetail.waitForExistence(timeout: 3), "Food name should be visible in detail sheet")
    }

    /// User can swipe to edit custom food in Library
    /// Acceptance: Swipe right, tap Edit, CreateFoodSheet opens
    func testSwipeToEditFoodInLibrary() {
        let customFoodName = "Editable Library Food"

        // Given: User has created a custom food
        createCustomFood(name: customFoodName)

        // When: User opens Library tab
        navigateToLibraryTab()

        // And: Swipes right on a food row to reveal edit
        let foodRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-library-row-'")
        ).element(boundBy: 0)
        XCTAssertTrue(foodRow.waitForExistence(timeout: 5), "Food row should exist")
        foodRow.swipeRight()

        // And: Taps Edit button
        let editButton = app.buttons["edit-food-library-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button should appear after swipe right")
        editButton.tap()

        // Then: CreateFoodSheet should open for editing
        let createFoodSheet = app.otherElements["create-food-sheet"]
        XCTAssertTrue(createFoodSheet.waitForExistence(timeout: 5), "Create food sheet should appear for editing")

        // And: Food name should be pre-filled
        let nameField = app.textFields["food-name-input"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Name field should exist")
        if let nameValue = nameField.value as? String {
            XCTAssertTrue(
                nameValue.contains("Editable") || nameValue.contains("Library"),
                "Name field should contain the custom food name"
            )
        }
    }

    /// User can swipe to delete custom food in Library
    /// Acceptance: Swipe left, tap Delete, confirmation appears, confirm removes food
    func testSwipeToDeleteFoodInLibrary() {
        let customFoodName = "Deletable Library Food"

        // Given: User has created a custom food
        createCustomFood(name: customFoodName)

        // When: User opens Library tab
        navigateToLibraryTab()

        // And: Swipes left on a food row to reveal delete
        let foodRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-library-row-'")
        ).element(boundBy: 0)
        XCTAssertTrue(foodRow.waitForExistence(timeout: 5), "Food row should exist")
        foodRow.swipeLeft()

        // And: Taps Delete button
        let deleteButton = app.buttons["delete-food-library-button"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "Delete button should appear after swipe left")
        deleteButton.tap()

        // Then: Confirmation alert should appear
        let deleteAlert = app.alerts.firstMatch
        XCTAssertTrue(deleteAlert.waitForExistence(timeout: 3), "Delete confirmation alert should appear")

        // And: Alert should have Delete and Cancel buttons
        let alertDeleteButton = deleteAlert.buttons["Delete"]
        let alertCancelButton = deleteAlert.buttons["Cancel"]
        XCTAssertTrue(alertDeleteButton.exists, "Alert should have Delete button")
        XCTAssertTrue(alertCancelButton.exists, "Alert should have Cancel button")

        // When: User confirms deletion
        alertDeleteButton.tap()

        // Then: Alert should dismiss
        XCTAssertFalse(deleteAlert.waitForExistence(timeout: 2), "Alert should dismiss after confirming delete")

        // And: Food should no longer appear in library
        let foodNameText = app.staticTexts[customFoodName]
        XCTAssertFalse(foodNameText.waitForExistence(timeout: 3), "Deleted food should not appear in Library")
    }

    /// User sees empty state when no custom foods in Library
    /// Acceptance: With no custom foods, Library shows empty message
    func testLibraryEmptyStateWhenNoFoods() {
        // Given: App is launched with no custom foods (clean state from setUp via --reset-app-data)
        // When: User opens Library tab
        navigateToLibraryTab()

        // Then: Empty state message should be visible
        let emptyStateText = app.staticTexts["No custom foods yet"]
        XCTAssertTrue(emptyStateText.waitForExistence(timeout: 5), "Empty state message should appear")

        // And: Help text should be visible
        let helpText = app.staticTexts["Create one to get started."]
        XCTAssertTrue(helpText.waitForExistence(timeout: 3), "Empty state help text should be visible")
    }

    /// Recipes and Favorites tabs show "Coming Soon"
    /// Acceptance: Tap Recipes/Favorites, alert shows "Coming Soon"
    func testRecipesAndFavoritesTabsShowComingSoon() {
        // Given: User opens Library tab
        navigateToLibraryTab()

        // When: User taps Recipes tab
        let recipesTab = app.buttons["food-library-tab-recipes"]
        XCTAssertTrue(recipesTab.waitForExistence(timeout: 3), "Recipes tab should exist")
        recipesTab.tap()

        // Then: "Coming Soon" alert should appear
        let comingSoonAlert = app.alerts["Coming Soon"]
        XCTAssertTrue(comingSoonAlert.waitForExistence(timeout: 3), "Coming Soon alert should appear for Recipes")

        // Dismiss the alert
        let okButton = comingSoonAlert.buttons["OK"]
        XCTAssertTrue(okButton.exists, "OK button should exist in alert")
        okButton.tap()

        // When: User taps Favorites tab
        let favoritesTab = app.buttons["food-library-tab-favorites"]
        XCTAssertTrue(favoritesTab.waitForExistence(timeout: 3), "Favorites tab should exist")
        favoritesTab.tap()

        // Then: "Coming Soon" alert should appear again
        let comingSoonAlertAgain = app.alerts["Coming Soon"]
        XCTAssertTrue(
            comingSoonAlertAgain.waitForExistence(timeout: 3),
            "Coming Soon alert should appear for Favorites"
        )
    }
}
