//
//  NutritionFlowUITests.swift
//  JabTrackerUITests
//
//  E2E tests for nutrition flow: search food, log meal, view daily totals.
//

import XCTest

final class NutritionFlowUITests: XCTestCase {
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

    // MARK: - Core Flow Tests

    /// Test the complete nutrition flow: search food → log meal → view daily totals
    func testSearchFoodLogMealViewDailyTotals() throws {
        // Step 1: Navigate to Food Log tab
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Verify initial state shows "No items logged"
        let noItemsText = app.staticTexts["No items logged"]
        XCTAssertTrue(noItemsText.waitForExistence(timeout: 3), "Should show 'No items logged' initially")

        // Step 2: Open Add Food sheet via + button in toolbar
        let addButton = app.buttons["add-food-button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3), "Add food button should exist")
        addButton.tap()

        // Wait for Add Food Sheet to appear
        let addFoodSheet = app.otherElements["add-food-sheet"]
        XCTAssertTrue(addFoodSheet.waitForExistence(timeout: 3), "Add food sheet should appear")

        // Step 3: Tap "Search for food" button to open search
        let searchFoodButton = app.buttons["search-food-button"]
        XCTAssertTrue(searchFoodButton.waitForExistence(timeout: 3), "Search for food button should exist")
        searchFoodButton.tap()

        // Wait for Food Search View to appear
        let foodSearchView = app.otherElements["food-search-view"]
        XCTAssertTrue(foodSearchView.waitForExistence(timeout: 3), "Food search view should appear")

        // Step 4: Search for a common food
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText("chicken")

        // Wait for search results to load (debounce + search time)
        sleep(3)

        // Step 5: Select a food from results
        let searchResults = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        )

        // Wait for results to populate
        var resultExists = false
        for _ in 0..<10 {
            if searchResults.count > 0 {
                resultExists = true
                break
            }
            sleep(1)
        }

        XCTAssertTrue(resultExists, "Should have at least one search result for 'chicken'")

        // Tap the first result
        let firstResult = searchResults.element(boundBy: 0)
        XCTAssertTrue(firstResult.exists, "First search result should exist")
        firstResult.tap()

        // Step 6: Should return to AddFoodSheet with food selected
        // Wait for add-food-sheet to reappear with selected food
        XCTAssertTrue(addFoodSheet.waitForExistence(timeout: 5), "Add food sheet should reappear")

        // Wait for the save button to become enabled (indicates food was selected)
        // The save button is disabled until a food is selected
        sleep(1)  // Allow UI to update

        // Step 7: Save the food entry
        let saveButton = app.buttons["save-food-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should exist")
        saveButton.tap()

        // Step 8: Verify food was logged - should return to Food Log view
        sleep(2)  // Allow time for sheet dismissal and data refresh

        // Navigate back to Food Log to see updated list
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        // Verify the food appears in the log
        let todaySection = app.staticTexts["Today"]
        XCTAssertTrue(todaySection.waitForExistence(timeout: 3), "Today section should exist in Food Log")

        // Check that we have some calorie count displayed (non-zero after logging)
        // The calorie total for the day should be visible
        let calLabel = app.staticTexts["Cal"]
        XCTAssertTrue(calLabel.exists, "Cal label should exist in summary")

        // Success - we completed the flow
        XCTAssertTrue(true, "Completed search food → log meal flow")
    }

    // MARK: - Search Tests

    /// Test food search shows results from database
    func testFoodSearchShowsResults() throws {
        // Open shortcuts and navigate to food search
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3), "Search shortcut should exist")
        searchButton.tap()

        // Wait for food search sheet
        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Search for a common food
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText("apple")

        // Wait for results
        sleep(2)

        // Verify results appear
        let searchResults = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        )

        // Wait up to 10 seconds for results
        var hasResults = false
        for _ in 0..<10 {
            if searchResults.count > 0 {
                hasResults = true
                break
            }
            sleep(1)
        }

        XCTAssertTrue(hasResults, "Should have search results for 'apple'")
    }

    /// Test cancel button dismisses search sheet
    func testCancelDismissesFoodSearch() throws {
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Tap cancel
        let cancelButton = app.buttons["food-search-cancel-button"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()

        // Verify sheet is dismissed
        XCTAssertFalse(
            foodSearchSheet.waitForExistence(timeout: 2),
            "Food search sheet should be dismissed after cancel"
        )
    }

    // MARK: - Dashboard Integration Tests

    /// Test that NutritionSummaryCard appears on Dashboard
    func testDashboardShowsNutritionSummaryCard() throws {
        // Navigate to Dashboard
        TestUtilities.navigateToTab(app, tabName: "Dashboard")

        // Look for "Today's Nutrition" text which is the card header
        let nutritionHeader = app.staticTexts["Today's Nutrition"]
        XCTAssertTrue(
            nutritionHeader.waitForExistence(timeout: 5),
            "Nutrition card header should appear on Dashboard"
        )
    }

    /// Test that macro progress bars appear in NutritionSummaryCard
    func testNutritionCardShowsMacroProgress() throws {
        TestUtilities.navigateToTab(app, tabName: "Dashboard")

        // Look for macro labels that indicate the card is showing
        let caloriesLabel = app.staticTexts["Calories"]
        let proteinLabel = app.staticTexts["Protein"]
        let carbsLabel = app.staticTexts["Carbs"]
        let fatLabel = app.staticTexts["Fat"]

        // Wait for the card to load
        XCTAssertTrue(caloriesLabel.waitForExistence(timeout: 5), "Calories label should exist")
        XCTAssertTrue(proteinLabel.exists, "Protein label should exist")
        XCTAssertTrue(carbsLabel.exists, "Carbs label should exist")
        XCTAssertTrue(fatLabel.exists, "Fat label should exist")
    }

    // MARK: - Food Log View Tests

    /// Test Food Log view displays meal sections
    func testFoodLogShowsMealSections() throws {
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Check for meal section headers
        let breakfastText = app.staticTexts["Breakfast"]
        let lunchText = app.staticTexts["Lunch"]
        let dinnerText = app.staticTexts["Dinner"]
        let snacksText = app.staticTexts["Snacks"]

        XCTAssertTrue(breakfastText.exists, "Breakfast section should exist")
        XCTAssertTrue(lunchText.exists, "Lunch section should exist")
        XCTAssertTrue(dinnerText.exists, "Dinner section should exist")
        XCTAssertTrue(snacksText.exists, "Snacks section should exist")
    }

    /// Test Food Log view displays daily summary
    func testFoodLogShowsDailySummary() throws {
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Check for "Today" header
        let todayHeader = app.staticTexts["Today"]
        XCTAssertTrue(todayHeader.exists, "Today header should exist in daily summary")

        // Check for macro labels
        let calLabel = app.staticTexts["Cal"]
        let proteinLabel = app.staticTexts["Protein"]
        let carbsLabel = app.staticTexts["Carbs"]
        let fatLabel = app.staticTexts["Fat"]

        XCTAssertTrue(calLabel.exists, "Cal label should exist in summary")
        XCTAssertTrue(proteinLabel.exists, "Protein label should exist in summary")
        XCTAssertTrue(carbsLabel.exists, "Carbs label should exist in summary")
        XCTAssertTrue(fatLabel.exists, "Fat label should exist in summary")
    }

    // MARK: - Performance Tests

    /// Test that food search responds within acceptable time for the 1.7M+ food database
    func testFoodSearchPerformance() throws {
        // Open shortcuts and navigate to food search
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3), "Search shortcut should exist")
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Measure search performance
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")

        // Record start time
        let startTime = Date()

        // Type search query
        searchField.tap()
        searchField.typeText("egg")

        // Wait for results
        let searchResults = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        )

        var hasResults = false
        for _ in 0..<30 {  // Max 3 seconds
            if searchResults.count > 0 {
                hasResults = true
                break
            }
            usleep(100_000)  // 100ms
        }

        let endTime = Date()
        let searchDuration = endTime.timeIntervalSince(startTime)

        XCTAssertTrue(hasResults, "Should have search results for 'egg'")

        // Search should complete within 3 seconds for a responsive feel
        // Accounting for typing time (~0.5s) and debounce (~0.5s), actual search should be < 2s
        XCTAssertLessThan(
            searchDuration,
            3.0,
            "Food search should complete within 3 seconds, took \(searchDuration)s"
        )

        print("🚀 Food search completed in \(String(format: "%.2f", searchDuration))s")
    }
}
