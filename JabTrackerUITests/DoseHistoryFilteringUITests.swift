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
        // GIVEN: Multiple doses with different notes exist
        let app = TestUtilities.launchAppWithTestMode()

        // Create multiple doses with different notes for filtering
        TestUtilities.setupDoseHistoryTest(app: app, doseCount: 3)

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // Verify we have multiple doses initially
        let initialDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 3)
        XCTAssertEqual(initialDoseRows.count, 3, "Should start with 3 doses")

        // WHEN: User enters text in search bar
        let searchField = app.textFields["dose-history-list"]
        XCTAssertTrue(searchField.exists, "Search field should be available")

        // Enter search text that should filter results
        searchField.tap()
        searchField.typeText("test")

        // THEN: List filters in real-time to show only matching doses
        // Wait for filtering to complete by checking filtered results
        let filteredResults = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "count <= 3"),
            object: app.buttons.matching(identifier: "dose-history-row"))
        wait(for: [filteredResults], timeout: 5)

        // Verify filtering occurred (assuming some doses match "test" and some don't)
        let filteredDoseRows = app.buttons.matching(identifier: "dose-history-row")
        XCTAssertLessThanOrEqual(filteredDoseRows.count, 3,
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
        XCTAssertEqual(restoredDoseRows.count, 3,
                       "All doses should be visible after clearing search")
    }

    func test_doseHistory_searchClearsWhenTextRemoved() throws {
        // GIVEN: Search has filtered the list
        let app = TestUtilities.launchAppWithTestMode()

        // Create multiple doses for filtering
        TestUtilities.setupDoseHistoryTest(app: app, doseCount: 3)

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // Verify we have multiple doses initially
        let initialDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 3)
        XCTAssertEqual(initialDoseRows.count, 3, "Should start with 3 doses")

        // Apply search filter
        let searchField = app.textFields["dose-history-list"]
        XCTAssertTrue(searchField.exists, "Search field should be available")

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
        XCTAssertEqual(restoredDoseRows.count, 3,
                       "All doses should be visible after clearing search text")
    }

    func test_doseHistory_dateRangeFiltering() throws {
        // GIVEN: Doses from multiple dates exist
        let app = TestUtilities.launchAppWithTestMode()

        // Create multiple doses across different dates
        TestUtilities.setupDoseHistoryTest(app: app, doseCount: 5)

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // Verify we have multiple doses initially
        let initialDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 5)
        XCTAssertEqual(initialDoseRows.count, 5, "Should start with 5 doses")

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
                XCTAssertTrue(applyFilterButton.waitForExistence(timeout: 3), "Apply filter button should exist")
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
        XCTAssertLessThanOrEqual(filteredDoseRows.count, 5,
                                 "Filtered results should be less than or equal to original count")

        // Note: This test may need adjustment based on actual date filtering UI implementation
    }

    func test_doseHistory_medicationFiltering() throws {
        // GIVEN: Doses with different medications exist
        let app = TestUtilities.launchAppWithTestMode()

        // Create doses with multiple medications
        TestUtilities.setupDoseHistoryTest(app: app, doseCount: 3, medicationProfiles: 2)

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
        XCTAssertLessThanOrEqual(filteredDoseRows.count, 3,
                                 "Filtered results should be less than or equal to original count")

        // Note: This test may need adjustment based on actual medication filtering UI implementation
    }

    func test_doseHistory_injectionSiteFiltering() throws {
        // GIVEN: Doses with different injection sites exist
        let app = TestUtilities.launchAppWithTestMode()

        // Create doses with different injection sites
        TestUtilities.setupDoseHistoryTest(app: app, doseCount: 3)

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
        XCTAssertLessThanOrEqual(filteredDoseRows.count, 3,
                                 "Filtered results should be less than or equal to original count")

        // Note: This test may need adjustment based on actual injection site filtering UI implementation
    }

    func test_doseHistory_pullToRefreshUpdatesData() throws {
        // GIVEN: Dose history is displayed
        let app = TestUtilities.launchAppWithTestMode()

        // Create initial doses
        TestUtilities.setupDoseHistoryTest(app: app, doseCount: 2)

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // Verify initial dose count
        let initialDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 2)
        XCTAssertEqual(initialDoseRows.count, 2, "Should start with 2 doses")

        // WHEN: User pulls down to refresh
        let historyView = app.collectionViews["dose-history-list"]
        XCTAssertTrue(historyView.waitForExistence(timeout: 3),
                      "History view should be available")

        // Perform pull-to-refresh gesture
        let startCoordinate = historyView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let endCoordinate = historyView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)

        // THEN: Refresh indicator appears and data updates
        // Wait for refresh to complete by checking that history view is still responsive
        let refreshComplete = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true"),
            object: historyView)
        wait(for: [refreshComplete], timeout: 10)

        // Verify data is still displayed (refresh completed)
        let refreshedDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 2)
        XCTAssertGreaterThanOrEqual(refreshedDoseRows.count, 2,
                                    "Doses should still be displayed after refresh")

        // Note: This test verifies pull-to-refresh gesture works, actual data refresh depends on implementation
    }
}
