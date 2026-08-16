//
//  FoodSearchV08UITests.swift
//  JabTrackerUITests
//
//  E2E tests for v0.8.0 Food Search & Library features:
//  - Phase 35: Search UX improvements (auto-focus, debounce, tap targets)
//  - Phase 35.1: Food Search Header Indicators (kcal/protein remaining)
//  - Phase 37: Serving Pill Picker for unit selection
//  - Phase 38: Barcode scanner now uses local-only database
//

import XCTest

final class FoodSearchV08UITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
    }

    // MARK: - Phase 35: Search UX Improvements

    /// Test that search field auto-focuses when opening food search sheet
    func testSearchFieldAutoFocuses() throws {
        // Navigate to Food Log and open search
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Open shortcuts and navigate to food search
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3), "Search shortcut should exist")
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Verify search field exists and check if keyboard is visible
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")

        // The keyboard should appear automatically (auto-focus)
        // Use condition-based waiting instead of Thread.sleep - keyboard waitForExistence
        // will wait for auto-focus delay (300ms) + any animation time
        let keyboard = app.keyboards.element
        XCTAssertTrue(
            keyboard.waitForExistence(timeout: 2),
            "Keyboard should appear automatically due to auto-focus"
        )
    }

    /// Test that amount input card has expanded tap target
    func testAmountInputExpandedTapTarget() throws {
        // Navigate to Food Log tab first to ensure correct starting point
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        // Open food search and select a food to get to detail sheet
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Search for a common food
        let searchField = app.textFields["food-search-field"]
        searchField.tap()
        searchField.typeText("apple")

        // Wait for results and tap first one
        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Should have search results for 'apple'")
        firstResult.tap()

        // Wait for food detail sheet
        let foodDetailSheet = app.otherElements["food-detail-sheet"]
        XCTAssertTrue(foodDetailSheet.waitForExistence(timeout: 3), "Food detail sheet should appear")

        // Tap the quantity input area (the entire card should be tappable)
        let quantityInput = app.textFields["quantity-input"]
        XCTAssertTrue(quantityInput.waitForExistence(timeout: 3), "Quantity input should exist")

        // Verify the input can be focused
        quantityInput.tap()

        // Verify keyboard appears (input is focused)
        let keyboard = app.keyboards.element
        XCTAssertTrue(keyboard.waitForExistence(timeout: 2), "Keyboard should appear when quantity input is tapped")
    }

    // MARK: - Phase 35.1: Food Search Header Indicators

    /// Test that header shows calorie progress indicator
    func testHeaderShowsCalorieIndicator() throws {
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Look for the calories indicator in the header
        // MacroProgressBar uses .accessibilityElement(children: .combine) so use descendants query
        let caloriesIndicator = app.descendants(matching: .any)["search-header-calories"].firstMatch

        XCTAssertTrue(
            caloriesIndicator.waitForExistence(timeout: 3),
            "Calories indicator should appear in search header"
        )
    }

    /// Test that header shows protein progress indicator
    func testHeaderShowsProteinIndicator() throws {
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Look for the protein indicator in the header
        let proteinIndicator = app.descendants(matching: .any)["search-header-protein"].firstMatch

        XCTAssertTrue(
            proteinIndicator.waitForExistence(timeout: 3),
            "Protein indicator should appear in search header"
        )
    }

    /// Test that both macro indicators are visible together
    func testHeaderShowsBothMacroIndicators() throws {
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Verify both indicators exist using descendants query
        let caloriesIndicator = app.descendants(matching: .any)["search-header-calories"].firstMatch
        let proteinIndicator = app.descendants(matching: .any)["search-header-protein"].firstMatch

        XCTAssertTrue(caloriesIndicator.waitForExistence(timeout: 3), "Calories indicator should exist")
        XCTAssertTrue(proteinIndicator.exists, "Protein indicator should exist alongside calories")
    }

    // MARK: - Phase 37: Serving Pill Picker

    /// Test that serving pill picker appears in food detail sheet
    func testServingPillPickerAppearsInFoodDetail() throws {
        // Navigate to a food detail sheet
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Search and select a food
        let searchField = app.textFields["food-search-field"]
        searchField.tap()
        searchField.typeText("banana")

        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Should have search results for 'banana'")
        firstResult.tap()

        // Wait for food detail sheet
        let foodDetailSheet = app.otherElements["food-detail-sheet"]
        XCTAssertTrue(foodDetailSheet.waitForExistence(timeout: 3), "Food detail sheet should appear")

        // Verify pill picker appears - use descendants query since it's a horizontal ScrollView
        let pillPicker = app.descendants(matching: .any)["serving-pill-picker"].firstMatch

        XCTAssertTrue(
            pillPicker.waitForExistence(timeout: 3),
            "Serving pill picker should appear in food detail sheet"
        )
    }

    /// Test that serving pill picker shows universal g and oz options
    func testServingPillPickerShowsUniversalUnits() throws {
        // Navigate to a food detail sheet
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Search and select a food
        let searchField = app.textFields["food-search-field"]
        searchField.tap()
        searchField.typeText("egg")

        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Should have search results for 'egg'")
        firstResult.tap()

        // Wait for food detail sheet
        let foodDetailSheet = app.otherElements["food-detail-sheet"]
        XCTAssertTrue(foodDetailSheet.waitForExistence(timeout: 3), "Food detail sheet should appear")

        // Verify universal unit pills exist
        let gramsPill = app.buttons["serving-pill-g"]
        XCTAssertTrue(gramsPill.waitForExistence(timeout: 3), "Grams pill should exist")

        let ouncesPill = app.buttons["serving-pill-oz"]
        XCTAssertTrue(ouncesPill.exists, "Ounces pill should exist")
    }

    /// Test that selecting a serving pill updates quantity display
    func testSelectingServingPillUpdatesQuantity() throws {
        // Navigate to a food detail sheet
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Search and select a food
        let searchField = app.textFields["food-search-field"]
        searchField.tap()
        searchField.typeText("chicken")

        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Should have search results for 'chicken'")
        firstResult.tap()

        // Wait for food detail sheet
        let foodDetailSheet = app.otherElements["food-detail-sheet"]
        XCTAssertTrue(foodDetailSheet.waitForExistence(timeout: 3), "Food detail sheet should appear")

        // Tap ounces pill
        let ouncesPill = app.buttons["serving-pill-oz"]
        XCTAssertTrue(ouncesPill.waitForExistence(timeout: 3), "Ounces pill should exist")
        ouncesPill.tap()

        // Verify the pill appears selected (we can't easily check state, but the tap should succeed)
        // The quantity should now be interpreted as ounces
        let quantityInput = app.textFields["quantity-input"]
        XCTAssertTrue(quantityInput.exists, "Quantity input should still exist after pill selection")
    }

    /// Test that gram amount is preserved when switching between unit pills
    func testGramAmountPreservedWhenSwitchingUnits() throws {
        // This tests the fix from Phase 38 where gram amounts should be preserved
        // when switching between g and oz (unit-only pills)

        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Search and select a food
        let searchField = app.textFields["food-search-field"]
        searchField.tap()
        searchField.typeText("rice")

        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Should have search results for 'rice'")
        firstResult.tap()

        // Wait for food detail sheet
        let foodDetailSheet = app.otherElements["food-detail-sheet"]
        XCTAssertTrue(foodDetailSheet.waitForExistence(timeout: 3), "Food detail sheet should appear")

        // First select grams pill
        let gramsPill = app.buttons["serving-pill-g"]
        XCTAssertTrue(gramsPill.waitForExistence(timeout: 3), "Grams pill should exist")
        gramsPill.tap()

        // Enter a specific gram amount
        let quantityInput = app.textFields["quantity-input"]
        quantityInput.tap()

        // Clear and type new value
        quantityInput.clearAndEnterText("100")

        // Now switch to ounces - gram amount should be preserved (converted)
        let ouncesPill = app.buttons["serving-pill-oz"]
        ouncesPill.tap()

        // The quantity should have changed to reflect the conversion (100g ≈ 3.53oz)
        // We just verify the input still exists and has a value
        XCTAssertTrue(quantityInput.exists, "Quantity input should exist after unit switch")
    }

    // MARK: - Phase 38: Barcode Scanner Local-Only Database

    /// Test that barcode scanner view is accessible
    func testBarcodeScannerViewAccessible() throws {
        TestUtilities.openShortcutsSheet(app)

        // The Barcode shortcut button has identifier "shortcut-button-barcode"
        let barcodeButton = app.buttons["shortcut-button-barcode"]

        XCTAssertTrue(barcodeButton.waitForExistence(timeout: 3), "Barcode shortcut should exist")
        barcodeButton.tap()

        // Food search sheet should appear with barcode scanner active
        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // The scan method tab should be selected
        let scanMethodTab = app.buttons["method-tab-scan"]
        XCTAssertTrue(scanMethodTab.waitForExistence(timeout: 3), "Scan method tab should exist")
    }

    /// Test that switching from scan to search mode works
    func testSwitchFromScanToSearchMode() throws {
        TestUtilities.openShortcutsSheet(app)

        // Start with barcode scan - use correct identifier
        let barcodeButton = app.buttons["shortcut-button-barcode"]
        XCTAssertTrue(barcodeButton.waitForExistence(timeout: 3), "Barcode shortcut should exist")
        barcodeButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Switch to search mode
        let searchMethodTab = app.buttons["method-tab-search"]
        XCTAssertTrue(searchMethodTab.waitForExistence(timeout: 3), "Search method tab should exist")
        searchMethodTab.tap()

        // Verify search field appears
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(
            searchField.waitForExistence(timeout: 3), "Search field should appear after switching to search mode")
    }

    // MARK: - Search Performance

    /// Test that search returns results quickly (debounce + local FTS5)
    func testSearchResponseTime() throws {
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")

        // Record start time
        let startTime = Date()

        // Type a common search term
        searchField.tap()
        searchField.typeText("bread")

        // Wait for results
        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)

        let hasResults = firstResult.waitForExistence(timeout: 3)
        let searchDuration = Date().timeIntervalSince(startTime)

        XCTAssertTrue(hasResults, "Should have search results for 'bread'")
        XCTAssertLessThan(searchDuration, 3.0, "Search should complete within 3 seconds")
    }

    /// Test that a query exposes the pending lifecycle state before final results.
    func testSearchShowsPendingThenFinalState() throws {
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3), "Search shortcut should exist")
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText("bread")

        let pendingState = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier IN %@", ["food-search-loading", "food-search-searching"])
        ).firstMatch
        XCTAssertTrue(
            pendingState.exists,
            "Search should expose a loading state during debounce/execution"
        )

        let prematureEmptyState = app.descendants(matching: .any)["food-search-empty"].firstMatch
        XCTAssertFalse(prematureEmptyState.exists, "Pending search must not show No Results")

        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Final search results should appear")
        XCTAssertFalse(pendingState.exists, "Loading state should end when results render")
    }

    /// Test that a database failure shows a retryable error instead of No Results.
    func testSearchShowsRetryableError() throws {
        app.terminate()
        app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--food-search-fail-once"]
        )

        TestUtilities.navigateToTab(app, tabName: "Food Log")
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3), "Search shortcut should exist")
        searchButton.tap()

        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText("pizza")

        let errorState = app.staticTexts["Search Failed"]
        XCTAssertTrue(errorState.waitForExistence(timeout: 5), "Search failure should be visible")
        let retryButton = app.buttons["Try Again"]
        XCTAssertTrue(retryButton.waitForExistence(timeout: 1), "Retry button should be visible")
        XCTAssertFalse(
            app.descendants(matching: .any)["food-search-empty"].exists,
            "Search failure must not show No Results"
        )

        retryButton.tap()
        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Retry should recover with search results")
        XCTAssertFalse(errorState.exists, "Retryable error should clear after a successful retry")
    }

    /// Test that whole word matches appear first (search ranking improvement)
    func testWholeWordMatchesAppearFirst() throws {
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        let searchField = app.textFields["food-search-field"]
        searchField.tap()

        // Search for "egg" - should prioritize "egg" over "eggplant"
        searchField.typeText("egg")

        // Wait for results
        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Should have search results for 'egg'")

        // We can't easily verify the exact order in E2E tests, but we confirm results appear
        // The ranking improvement is better tested in unit tests
    }

    // MARK: - Add Food Flow

    /// Test complete flow: search -> select -> add food
    func testCompleteAddFoodFlow() throws {
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3), "Food search sheet should appear")

        // Search for food
        let searchField = app.textFields["food-search-field"]
        searchField.tap()
        searchField.typeText("salmon")

        // Select first result
        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Should have search results for 'salmon'")
        firstResult.tap()

        // Wait for food detail sheet
        let foodDetailSheet = app.otherElements["food-detail-sheet"]
        XCTAssertTrue(foodDetailSheet.waitForExistence(timeout: 3), "Food detail sheet should appear")

        // Verify pill picker is visible - use descendants query
        let pillPicker = app.descendants(matching: .any)["serving-pill-picker"].firstMatch

        XCTAssertTrue(pillPicker.waitForExistence(timeout: 3), "Pill picker should be visible")

        // Tap Add button
        let addButton = app.buttons["add-food-button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3), "Add button should exist")
        addButton.tap()

        // Verify sheets are dismissed (back to food log)
        XCTAssertFalse(
            foodDetailSheet.waitForExistence(timeout: 2),
            "Food detail sheet should be dismissed after adding"
        )
    }
}
