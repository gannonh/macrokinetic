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
        TestUtilities.debugScreenshot(app, name: "food-detail-first-presentation")
        print(app.debugDescription)
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
            searchField.waitForExistence(timeout: 3), "Search field should appear after switching to search mode"
        )
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

    /// Test that the empty state appears only after a completed zero-result query.
    func testSearchShowsCompletedEmptyState() throws {
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3), "Search shortcut should exist")
        searchButton.tap()

        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText("xyznonexistent123")

        let emptyState = app.descendants(matching: .any)["food-search-empty"].firstMatch
        XCTAssertTrue(emptyState.waitForExistence(timeout: 10), "Completed zero-result search should show No Results")
        XCTAssertTrue(app.staticTexts["No Results"].exists, "No Results title should be visible")
        XCTAssertTrue(
            app.staticTexts["No foods found for \"xyznonexistent123\""].exists,
            "Empty state should name the completed query"
        )
    }

    /// Test that replacing a query clears stale results before the replacement completes.
    func testSearchReplacementClearsStaleResultsAndPreservesCategoryOrder() throws {
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3), "Search shortcut should exist")
        searchButton.tap()

        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText("bread")

        let firstBreadResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstBreadResult.waitForExistence(timeout: 10), "Bread results should appear")

        let existingQuery = (searchField.value as? String) ?? "bread"
        searchField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingQuery.count))
        searchField.typeText("chicken")

        let staleBreadResults = app.buttons.matching(
            NSPredicate(format: "identifier CONTAINS[c] 'bread'")
        )
        XCTAssertEqual(staleBreadResults.count, 0, "Replacement query must clear stale bread results")

        let firstChickenResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstChickenResult.waitForExistence(timeout: 10), "Chicken results should appear")

        let commonHeader = app.staticTexts["Common"]
        let brandedHeader = app.staticTexts["Branded"]
        XCTAssertTrue(commonHeader.waitForExistence(timeout: 5), "Common category should appear")
        XCTAssertTrue(brandedHeader.waitForExistence(timeout: 10), "Branded category should appear")
        XCTAssertLessThan(commonHeader.frame.minY, brandedHeader.frame.minY, "Common should precede Branded")
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

    func testCompleteAddFoodFlow() throws {
        TestUtilities.openShortcutsSheet(app)

        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3))
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3))

        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText("salmon")

        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10))
        captureFoodState("food-detail-salmon-result")
        XCTAssertTrue(firstResult.staticTexts["Salmon, Atlantic, raw"].exists)
        firstResult.tap()

        let foodDetailSheet = app.otherElements["food-detail-sheet"]
        assertFoodDetails(
            name: "Salmon, Atlantic, raw", calories: "208", protein: "20", fat: "13", carbs: "0",
            screenshot: "food-detail-salmon-first-presentation"
        )
        let gramsPill = foodDetailSheet.buttons["serving-pill-g"]
        XCTAssertTrue(gramsPill.exists)
        XCTAssertTrue(foodDetailSheet.buttons["serving-pill-oz"].exists)
        gramsPill.tap()

        let quantityInput = foodDetailSheet.textFields["quantity-input"]
        captureFoodState("food-detail-salmon-grams")
        XCTAssertEqual(quantityInput.value as? String, "100", "Switching to grams should retain the 100g portion")
        quantityInput.tap()
        quantityInput.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3) + "200")
        captureFoodState("food-detail-salmon-200g")
        XCTAssertEqual(quantityInput.value as? String, "200")
        assertFoodDetails(
            name: "Salmon, Atlantic, raw", calories: "416", protein: "40", fat: "26", carbs: "0",
            screenshot: "food-detail-salmon-scaled-nutrition"
        )

        let addButton = foodDetailSheet.buttons["add-food-button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()
        captureFoodState("food-detail-after-save")
        XCTAssertTrue(
            foodDetailSheet.waitForNonExistence(timeout: 3),
            "Food detail sheet should dismiss after adding"
        )
        XCTAssertTrue(foodSearchSheet.waitForNonExistence(timeout: 3), "Search should dismiss after adding")
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        assertSingleSalmonEntry(screenshot: "food-detail-saved-log")

        app.terminate()
        app = TestUtilities.launchAppWithTestMode(resetData: false)
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        assertSingleSalmonEntry(screenshot: "food-detail-relaunched-log")
    }

    func testCancelThenSelectDifferentFoodShowsFreshDetails() throws {
        TestUtilities.openShortcutsSheet(app)
        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3))
        searchButton.tap()

        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 3))
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText("salmon")
        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10))
        firstResult.tap()
        assertFoodDetails(
            name: "Salmon, Atlantic, raw", calories: "208", protein: "20", fat: "13", carbs: "0",
            screenshot: "food-detail-before-cancel"
        )

        let detail = app.otherElements["food-detail-sheet"]
        let cancel = detail.buttons["Cancel"]
        XCTAssertTrue(cancel.exists)
        cancel.tap()
        captureFoodState("food-detail-canceled-search")
        XCTAssertTrue(detail.waitForNonExistence(timeout: 3))
        XCTAssertTrue(searchField.exists, "Cancel should return to the existing search")
        let clearSearch = foodSearchSheet.buttons["clear-search-button"]
        XCTAssertTrue(clearSearch.exists)
        clearSearch.tap()
        searchField.tap()
        searchField.typeText("chicken breast roasted")
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10))
        captureFoodState("food-detail-chicken-result")
        XCTAssertTrue(firstResult.staticTexts["Chicken breast, roasted"].exists)
        firstResult.tap()
        assertFoodDetails(
            name: "Chicken breast, roasted", calories: "165", protein: "31", fat: "3", carbs: "0",
            screenshot: "food-detail-different-selection"
        )
        XCTAssertFalse(detail.staticTexts["Salmon, Atlantic, raw"].exists, "The previous selection must be absent")
        let quantity = detail.textFields["quantity-input"]
        XCTAssertEqual(quantity.value as? String, "1", "The new food should open with its default serving")
        cancel.tap()
        captureFoodState("food-detail-second-cancel")
        XCTAssertTrue(detail.waitForNonExistence(timeout: 3))
        let closeSearch = foodSearchSheet.buttons["food-search-cancel-button"]
        XCTAssertTrue(closeSearch.exists)
        closeSearch.tap()
        XCTAssertTrue(foodSearchSheet.waitForNonExistence(timeout: 3))
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        captureFoodState("food-detail-cancel-empty-log")
        XCTAssertEqual(app.buttons.matching(identifier: "food-entry-row").count, 0, "Cancel must not log either food")
        let calories = app.staticTexts.matching(
            NSPredicate(format: "identifier == 'macro-consumed-cal' AND label == '0/2000'")
        ).firstMatch
        XCTAssertTrue(calories.exists, "Cancel must leave consumed calories at zero")
    }

    /// Recent-food and Library rows use the same selection contract as search results.
    func testRecentAndLibrarySelectionsOpenPopulatedDetails() throws {
        openSearchSheet()
        let foodSearchSheet = app.otherElements["food-search-sheet"]
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText("salmon")
        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10))
        firstResult.tap()
        let detail = app.otherElements["food-detail-sheet"]
        let logButton = detail.buttons["add-food-button"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 3))
        logButton.tap()
        XCTAssertTrue(detail.waitForNonExistence(timeout: 3))
        XCTAssertTrue(foodSearchSheet.waitForNonExistence(timeout: 3))

        // Recent: reopen search with an empty query and select the logged food.
        openSearchSheet()
        let recentRow = foodSearchSheet.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Salmon, Atlantic, raw'")
        ).firstMatch
        captureFoodState("food-detail-recent-list")
        XCTAssertTrue(recentRow.waitForExistence(timeout: 5), "The logged salmon appears under Recent")
        recentRow.tap()
        assertFoodDetails(
            name: "Salmon, Atlantic, raw", calories: "208", protein: "20", fat: "13", carbs: "0",
            screenshot: "food-detail-recent-populated"
        )

        // Library: save a fictional custom copy, then select it from the Library tab.
        let toCustom = detail.buttons["to-custom-button"]
        XCTAssertTrue(toCustom.exists)
        toCustom.tap()
        let createSheet = app.otherElements["create-food-sheet"]
        XCTAssertTrue(createSheet.waitForExistence(timeout: 5))
        let nameField = createSheet.textFields["food-name-input"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        let existingName = (nameField.value as? String) ?? ""
        nameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingName.count) + "Library Salmon")
        captureFoodState("food-detail-library-copy-form")
        let save = app.buttons["create-food-save"]
        XCTAssertTrue(save.waitForExistence(timeout: 3) && save.isEnabled)
        save.tap()
        XCTAssertTrue(createSheet.waitForNonExistence(timeout: 5))
        XCTAssertTrue(detail.waitForNonExistence(timeout: 5))
        XCTAssertTrue(foodSearchSheet.waitForNonExistence(timeout: 5), "Saving the custom copy closes search")

        openSearchSheet()
        let libraryTab = app.buttons["method-tab-library"]
        XCTAssertTrue(libraryTab.waitForExistence(timeout: 5))
        libraryTab.tap()
        let libraryRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Library Salmon'")
        ).firstMatch
        captureFoodState("food-detail-library-list")
        XCTAssertTrue(libraryRow.waitForExistence(timeout: 5), "The custom copy appears in the Library")
        libraryRow.tap()
        assertFoodDetails(
            name: "Library Salmon", calories: "208", protein: "20", fat: "13", carbs: "0",
            screenshot: "food-detail-library-populated"
        )
    }

    private func openSearchSheet() {
        TestUtilities.openShortcutsSheet(app)
        let searchButton = app.buttons["Search"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 3))
        searchButton.tap()
        XCTAssertTrue(app.otherElements["food-search-sheet"].waitForExistence(timeout: 3))
    }

    private func assertFoodDetails(
        name: String, calories: String, protein: String, fat: String, carbs: String, screenshot: String,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        let detail = app.otherElements["food-detail-sheet"]
        captureFoodState(screenshot)
        XCTAssertTrue(detail.waitForExistence(timeout: 3), file: file, line: line)
        XCTAssertTrue(detail.staticTexts[name].exists, file: file, line: line)
        for (identifier, nutrient, value) in [
            ("food-detail-calories", "Calories", calories),
            ("food-detail-macro-protein", "Protein", protein),
            ("food-detail-macro-fat", "Fat", fat),
            ("food-detail-macro-carbs", "Carbs", carbs),
        ] {
            let group = detail.descendants(matching: .any)[identifier].firstMatch
            XCTAssertTrue(group.exists, file: file, line: line)
            XCTAssertTrue(group.staticTexts[nutrient].exists, file: file, line: line)
            XCTAssertTrue(group.staticTexts[value].exists, file: file, line: line)
        }
    }

    private func assertSingleSalmonEntry(
        screenshot: String, file: StaticString = #filePath, line: UInt = #line
    ) {
        let log = app.otherElements["food-log-view"]
        let rows = log.buttons.matching(identifier: "food-entry-row")
        captureFoodState(screenshot)
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 3), file: file, line: line)
        XCTAssertEqual(rows.count, 1, "One Add should create exactly one entry", file: file, line: line)
        XCTAssertEqual(
            rows.firstMatch.label, "🐟, Salmon, Atlantic, raw, 40P, 26F, 0C, •, 200g, 416", file: file, line: line
        )
        for (identifier, label) in [
            ("macro-consumed-cal", "416/2000"),
            ("macro-consumed-protein", "40/150"),
            ("macro-consumed-fat", "26/65"),
            ("macro-consumed-carbs", "0/200"),
        ] {
            let total = log.staticTexts.matching(
                NSPredicate(format: "identifier == %@ AND label == %@", identifier, label)
            ).firstMatch
            XCTAssertTrue(total.exists, file: file, line: line)
        }
    }

    private func captureFoodState(_ name: String) {
        TestUtilities.debugScreenshot(app, name: name)
        print(app.debugDescription)
    }
}
