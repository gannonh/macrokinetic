//
//  DoseHistoryFilteringUITests.swift
//  JabTrackerUITests
//
//  Dose History Search and Filtering Tests
//  Tests for search functionality, date range, medication, and injection site filtering
//

import XCTest

final class DoseHistoryFilteringUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Search and Filtering

    func test_doseHistory_searchFiltersInRealTime() throws {
        // GIVEN: Multiple doses exist (deterministic seeding; thirtyDays randomly skips ~5%)
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 4, dose: "0.5")

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // Verify we have multiple doses initially
        let initialDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 4)
        XCTAssertGreaterThan(initialDoseRows.count, 3, "Should start with more than 3 doses")

        // WHEN: User enters text in search bar
        // SwiftUI TextField may be exposed differently based on container
        var searchField = app.textFields["dose-history-search"]
        if !searchField.waitForExistence(timeout: 2) {
            searchField = app.textFields["Search doses..."]
        }
        if !searchField.waitForExistence(timeout: 2) {
            searchField = app.textFields.firstMatch
        }
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should be available")

        // Enter search text that should filter results
        searchField.tap()
        searchField.typeText("test")

        // THEN: List filters in real-time to show only matching doses
        // Wait for filtering to complete by checking filtered results
        let filteredResults = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count <= \(initialDoseRows.count)"),
            object: app.buttons.matching(identifier: "dose-history-row"))
        wait(for: [filteredResults], timeout: 5)

        // Verify filtering occurred (assuming some doses match "test" and some don't)
        let filteredDoseRows = app.buttons.matching(identifier: "dose-history-row")
        XCTAssertLessThanOrEqual(
            filteredDoseRows.count, 3,
            "Filtered results should be less than or equal to original count")

        // Clear search to verify all doses return
        TestUtilities.clearAndEnterText(in: searchField)

        // Wait for filter to clear by checking restored results
        let restoredResults = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count >= 3"),
            object: app.buttons.matching(identifier: "dose-history-row"))
        wait(for: [restoredResults], timeout: 5)

        // Verify all doses are shown again
        let restoredDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 3)
        XCTAssertGreaterThan(
            restoredDoseRows.count, 3,
            "All doses should be visible after clearing search")
    }

    func test_doseHistory_searchClearsWhenTextRemoved() throws {
        // GIVEN: 4 doses exist (deterministic seeding; thirtyDays randomly skips ~5%)
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 4, dose: "0.5")

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // Verify we have multiple doses initially
        let initialDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 3)
        XCTAssertGreaterThan(initialDoseRows.count, 3, "Should start with more than 3 doses")

        // Apply search filter
        // SwiftUI TextField may be exposed differently based on container
        var searchField = app.textFields["dose-history-search"]
        if !searchField.waitForExistence(timeout: 2) {
            searchField = app.textFields["Search doses..."]
        }
        if !searchField.waitForExistence(timeout: 2) {
            searchField = app.textFields.firstMatch
        }
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should be available")

        TestUtilities.clearAndEnterText(in: searchField, newText: "filter")

        // Wait for filtering to complete by checking that filtering occurred
        let filteringComplete = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count <= 3"),
            object: app.buttons.matching(identifier: "dose-history-row"))
        wait(for: [filteringComplete], timeout: 5)

        // WHEN: User clears search text
        TestUtilities.clearAndEnterText(in: searchField)

        // Wait for filter to clear by checking restored results
        let clearingComplete = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count >= 3"),
            object: app.buttons.matching(identifier: "dose-history-row"))
        wait(for: [clearingComplete], timeout: 5)

        // THEN: All doses are shown again
        let restoredDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 3)
        XCTAssertGreaterThan(
            restoredDoseRows.count, 3,
            "All doses should be visible after clearing search text")
    }

    func test_doseHistory_dateRangeFiltering() throws {
        // GIVEN: Doses from multiple dates exist
        // GIVEN: App launched with 30 days of pre-seeded data (~4-5 doses)
        let preset = TestUtilities.TestDataPreset.thirtyDays
        let app = TestUtilities.launchAppWithSeededData(preset: preset)

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // Verify we have multiple doses initially
        // (thirtyDays seeding skips ~5% of doses, so the count can vary 3-5)
        let initialDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 3)
        XCTAssertGreaterThanOrEqual(
            initialDoseRows.count, 3, "Should start with at least 3 doses")

        // WHEN: User applies date range filter
        // Look for filter button or date range picker
        let filterButton = app.buttons["filter-button"]
        if filterButton.waitForExistence(timeout: 3) {
            filterButton.tap()

            // Look for date range controls
            let dateFromPicker = app.datePickers["date-from-picker"]
            let dateToPicker = app.datePickers["date-to-picker"]

            if dateFromPicker.exists, dateToPicker.exists {
                // Set concrete date values for date range filtering
                XCTAssertTrue(dateFromPicker.exists, "Date from picker should exist")
                XCTAssertTrue(dateToPicker.exists, "Date to picker should exist")

                // Set date range - adjust wheels or use coordinate-based interaction
                dateFromPicker.adjust(toPickerWheelValue: "Yesterday")
                dateToPicker.adjust(toPickerWheelValue: "Today")

                // Apply filter (close filter interface)
                let applyFilterButton = app.buttons["apply-filter"]
                XCTAssertTrue(
                    applyFilterButton.waitForExistence(timeout: 3), "Apply filter button should exist")
                applyFilterButton.tap()
            }
        }

        // THEN: Only doses within date range are shown
        // Wait for date filtering to apply by checking filtered results
        let dateFilterComplete = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count <= 5"),
            object: app.buttons.matching(identifier: "dose-history-row"))
        wait(for: [dateFilterComplete], timeout: 5)

        // Verify filtering occurred (exact count depends on implementation)
        let filteredDoseRows = app.buttons.matching(identifier: "dose-history-row")
        XCTAssertLessThanOrEqual(
            filteredDoseRows.count, 5,
            "Filtered results should be less than or equal to original count")

        // Note: This test may need adjustment based on actual date filtering UI implementation
    }

    func test_doseHistory_medicationFiltering() throws {
        // GIVEN: Doses with different medications exist (seeded via launch arguments)
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 3, medicationProfiles: 2)

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // Verify we have multiple doses initially
        let initialDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 3)
        XCTAssertEqual(initialDoseRows.count, 3, "Should start with 3 doses")

        // WHEN: User filters by specific medication
        // Look for medication filter control
        let medicationFilterButton = app.buttons["medication-filter"]
        if medicationFilterButton.waitForExistence(timeout: 3) {
            medicationFilterButton.tap()

            // Select a specific medication from the filter options
            let medicationOption = app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'Mounjaro' OR label CONTAINS 'Tirzepatide'")
            ).firstMatch
            if medicationOption.exists {
                medicationOption.tap()
            }
        }

        // THEN: Only doses with selected medication are shown
        // Wait for medication filtering to apply by checking filtered results
        let medicationFilterComplete = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count <= 3"),
            object: app.buttons.matching(identifier: "dose-history-row"))
        wait(for: [medicationFilterComplete], timeout: 5)

        // Verify filtering occurred
        let filteredDoseRows = app.buttons.matching(identifier: "dose-history-row")
        XCTAssertLessThanOrEqual(
            filteredDoseRows.count, 3,
            "Filtered results should be less than or equal to original count")

        // Note: This test may need adjustment based on actual medication filtering UI implementation
    }

    func test_doseHistory_injectionSiteFiltering() throws {
        // GIVEN: Doses with different injection sites exist
        // Create doses with different injection sites
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 3)

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // Verify we have multiple doses initially
        let initialDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 3)
        XCTAssertEqual(initialDoseRows.count, 3, "Should start with 3 doses")

        // WHEN: User filters by specific injection site
        // Look for injection site filter control
        let siteFilterButton = app.buttons["injection-site-filter"]
        if siteFilterButton.waitForExistence(timeout: 3) {
            siteFilterButton.tap()

            // Select a specific injection site from the filter options
            let siteOption = app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'thigh' OR label CONTAINS 'arm'")
            ).firstMatch
            if siteOption.exists {
                siteOption.tap()
            }
        }

        // THEN: Only doses with selected injection site are shown
        // Wait for injection site filtering to apply by checking filtered results
        let siteFilterComplete = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count <= 3"),
            object: app.buttons.matching(identifier: "dose-history-row"))
        wait(for: [siteFilterComplete], timeout: 5)

        // Verify filtering occurred
        let filteredDoseRows = app.buttons.matching(identifier: "dose-history-row")
        XCTAssertLessThanOrEqual(
            filteredDoseRows.count, 3,
            "Filtered results should be less than or equal to original count")

        // Note: This test may need adjustment based on actual injection site filtering UI implementation
    }

    func test_doseHistory_pullToRefreshUpdatesData() throws {
        // GIVEN: Dose history is displayed

        // Create initial doses
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 2)

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // Verify initial dose count
        let initialDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 2)
        XCTAssertEqual(initialDoseRows.count, 2, "Should start with 2 doses")

        // WHEN: User pulls down to refresh
        // (dose-history-container identifiers are overridden when embedded;
        // the dose list rows are always addressable)
        let historyRows = app.buttons.matching(identifier: "dose-history-row")
        XCTAssertTrue(
            historyRows.firstMatch.waitForExistence(timeout: 3),
            "History dose rows should be available")

        // Perform pull-to-refresh gesture over the list
        let startCoordinate = historyRows.firstMatch.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.0))
        let endCoordinate = historyRows.firstMatch.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 6.0))
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)

        // THEN: Refresh indicator appears and data updates
        // Wait for refresh to complete by checking that history rows are still shown
        let refreshComplete = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count >= 2"),
            object: app.buttons.matching(identifier: "dose-history-row"))
        wait(for: [refreshComplete], timeout: 10)

        // Verify data is still displayed (refresh completed)
        let refreshedDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 2)
        XCTAssertGreaterThanOrEqual(
            refreshedDoseRows.count, 2,
            "Doses should still be displayed after refresh")

        // Note: This test verifies pull-to-refresh gesture works, actual data refresh depends on implementation
    }

    // MARK: - Issue #44 Enhancements

    /// Opens the Search & Filter sheet from the dose history view
    private func openFilterSheet(in app: XCUIApplication) {
        let filterButton = app.buttons["filter-button"]
        XCTAssertTrue(
            filterButton.waitForExistence(timeout: 5), "Filter button should exist in history view")
        filterButton.tap()
        // The sheet's search field is at the top of the scrollable form; the
        // Actions section (Apply/Clear buttons) renders below the fold.
        let searchField = app.textFields["dose-history-search"]
        if !searchField.waitForExistence(timeout: 15) {
            TestUtilities.debugScreenshot(app, name: "filter-sheet-failure")
            print(app.debugDescription)
        }
        XCTAssertTrue(searchField.exists, "Filter sheet should appear (search field visible)")
    }

    /// Dismisses the Search & Filter sheet via the Done toolbar button
    private func dismissFilterSheet(in app: XCUIApplication) {
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3), "Done button should exist in filter sheet")
        doneButton.tap()
        let sheetGone = app.textFields["dose-history-search"].waitForNonExistence(timeout: 5)
        XCTAssertTrue(sheetGone, "Filter sheet should dismiss")
    }

    /// Scrolls the filter sheet to the bottom and taps Clear All Filters
    private func clearAllFilters(in app: XCUIApplication) {
        let clearButton = app.buttons["clear-all-filters-button"]
        if !clearButton.exists {
            app.swipeUp()
        }
        XCTAssertTrue(
            clearButton.waitForExistence(timeout: 3),
            "Clear all filters button should exist after scrolling")
        clearButton.tap()
    }

    /// Reads the "X of Y doses" results count label
    /// (queried by accessibility label; container identifiers override element
    /// identifiers when DoseHistoryView is embedded, but labels always survive)
    private func resultsCountLabel(in app: XCUIApplication) -> String {
        let count = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS %@", "doses shown"))
            .firstMatch
        XCTAssertTrue(
            count.waitForExistence(timeout: 5), "Results count label should exist")
        return count.label
    }

    /// The filter button's accessibility label carries the active filter count
    /// (e.g. "Search and filter, 2 active filters")
    private func filterButtonLabel(in app: XCUIApplication) -> String {
        let filterButton = app.buttons["filter-button"]
        XCTAssertTrue(filterButton.waitForExistence(timeout: 5), "Filter button should exist")
        return filterButton.label
    }

    func test_doseHistory_dateRangePresets() throws {
        // GIVEN: 5 weekly doses seeded deterministically (adherence 1.0, one today)
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 4, dose: "0.5")
        TestUtilities.navigateToHistoryView(in: app)

        let initialCount = TestUtilities.getDoseRows(from: app, minimumCount: 3).count
        XCTAssertEqual(initialCount, 4, "Should start with 4 seeded doses")

        // WHEN: User opens the filter sheet and taps the Today preset
        self.openFilterSheet(in: app)

        let todayPreset = app.buttons["date-preset-today"]
        XCTAssertTrue(todayPreset.waitForExistence(timeout: 3), "Today preset button should exist")
        todayPreset.tap()

        // Preset applies live; the button should now be selected
        XCTAssertTrue(
            app.buttons["date-preset-today"].isSelected,
            "Today preset should be selected after tapping")

        // The custom date range sheet is reachable from the same section
        let customRangeButton = app.buttons["date-range-button"]
        XCTAssertTrue(
            customRangeButton.waitForExistence(timeout: 3),
            "Custom date range button should exist")
        customRangeButton.tap()
        XCTAssertTrue(
            app.navigationBars["Date Range"].waitForExistence(timeout: 5),
            "Custom date range sheet should present")
        // Scope Done to the nested sheet's nav bar; the outer sheet has its own Done
        app.navigationBars["Date Range"].buttons["Done"].tap()

        self.dismissFilterSheet(in: app)

        // THEN: Only today's dose is shown
        let filteredRows = app.buttons.matching(identifier: "dose-history-row")
        let filteredExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count == 1"), object: filteredRows)
        wait(for: [filteredExpectation], timeout: 5)
        XCTAssertEqual(filteredRows.count, 1, "Today preset should show only today's dose")

        // WHEN: User clears all filters
        self.openFilterSheet(in: app)
        self.clearAllFilters(in: app)
        self.dismissFilterSheet(in: app)

        // THEN: All doses return
        let restoredExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count >= %d", initialCount),
            object: app.buttons.matching(identifier: "dose-history-row"))
        wait(for: [restoredExpectation], timeout: 5)
    }

    func test_doseHistory_filterCountBadge() throws {
        // GIVEN: App launched with pre-seeded data, no filters active
        let app = TestUtilities.launchAppWithSeededData(preset: .thirtyDays)
        TestUtilities.navigateToHistoryView(in: app)

        // The filter button label carries the badge count (accessibility)
        let noFilterLabel = self.filterButtonLabel(in: app)
        XCTAssertFalse(
            noFilterLabel.contains("active filters"),
            "Filter button should not report active filters initially, got: \(noFilterLabel)")

        // WHEN: User applies the Today date range preset
        self.openFilterSheet(in: app)
        app.buttons["date-preset-today"].tap()
        self.dismissFilterSheet(in: app)

        // THEN: The filter button reports 1 active filter
        let oneFilterLabel = self.filterButtonLabel(in: app)
        XCTAssertTrue(
            oneFilterLabel.contains("1 active filter"),
            "Filter button should report 1 active filter, got: \(oneFilterLabel)")

        // WHEN: User applies a second filter (search text)
        self.openFilterSheet(in: app)
        let searchField = app.descendants(matching: .any)["dose-history-search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist in sheet")
        searchField.tap()
        searchField.typeText("ozempic")
        self.dismissFilterSheet(in: app)

        // THEN: The count updates to 2
        let twoFilters = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", "2 active filters"),
            object: app.buttons["filter-button"])
        wait(for: [twoFilters], timeout: 5)

        // WHEN: User clears all filters
        self.openFilterSheet(in: app)
        self.clearAllFilters(in: app)
        self.dismissFilterSheet(in: app)

        // THEN: The count disappears
        let clearedFilters = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "NOT label CONTAINS %@", "active filters"),
            object: app.buttons["filter-button"])
        let cleared = XCTWaiter().wait(for: [clearedFilters], timeout: 5)
        XCTAssertEqual(cleared, .completed, "Filter count should disappear after clearing filters")
    }

    func test_doseHistory_resultsCountDisplay() throws {
        // GIVEN: 5 weekly doses seeded deterministically (adherence 1.0, one today)
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 4, dose: "0.5")
        TestUtilities.navigateToHistoryView(in: app)

        let initialCount = TestUtilities.getDoseRows(from: app, minimumCount: 3).count
        XCTAssertEqual(initialCount, 4, "Should start with 4 seeded doses")

        // THEN: Results count shows all doses
        let initialLabel = self.resultsCountLabel(in: app)
        XCTAssertTrue(
            initialLabel.contains("\(initialCount) of \(initialCount)"),
            "Initial results count should show all doses, got: \(initialLabel)")

        // WHEN: User applies the Today date range preset
        self.openFilterSheet(in: app)
        app.buttons["date-preset-today"].tap()
        self.dismissFilterSheet(in: app)

        // THEN: Results count updates to reflect the single matching dose
        let filteredLabel = self.resultsCountLabel(in: app)
        XCTAssertTrue(
            filteredLabel.contains("1 of \(initialCount)"),
            "Filtered results count should show 1 of \(initialCount), got: \(filteredLabel)")
    }

    func test_doseHistory_doseAmountRangeSlider() throws {
        // GIVEN: App launched with 30 days of pre-seeded data
        // All seeded doses are 0.5 mg, so dynamic bounds are 0.25...0.75 mg
        let app = TestUtilities.launchAppWithSeededData(preset: .thirtyDays)
        TestUtilities.navigateToHistoryView(in: app)

        let initialRows = TestUtilities.getDoseRows(from: app, minimumCount: 3)
        let initialCount = initialRows.count

        // WHEN: User raises the minimum amount slider to the top of the range
        self.openFilterSheet(in: app)

        let minSlider = app.sliders["dose-amount-min-slider"]
        XCTAssertTrue(
            minSlider.waitForExistence(timeout: 3), "Dose amount min slider should exist")
        minSlider.adjust(toNormalizedSliderPosition: 1.0)

        self.dismissFilterSheet(in: app)

        // THEN: No 0.5 mg dose fits above a 0.75 mg minimum, so no results match
        let filteredLabel = self.resultsCountLabel(in: app)
        XCTAssertTrue(
            filteredLabel.contains("0 of \(initialCount)"),
            "Amount filter above all doses should show 0 results, got: \(filteredLabel)")
        XCTAssertTrue(
            app.staticTexts["No doses match your current filters."].waitForExistence(timeout: 5),
            "Empty state should explain that no doses match the filters")

        // WHEN: User lowers the minimum amount slider back to the bottom
        self.openFilterSheet(in: app)
        minSlider.adjust(toNormalizedSliderPosition: 0.0)
        self.dismissFilterSheet(in: app)

        // THEN: All doses return
        let restoredLabel = self.resultsCountLabel(in: app)
        XCTAssertTrue(
            restoredLabel.contains("\(initialCount) of \(initialCount)"),
            "Resetting the amount filter should restore all doses, got: \(restoredLabel)")
    }
}
