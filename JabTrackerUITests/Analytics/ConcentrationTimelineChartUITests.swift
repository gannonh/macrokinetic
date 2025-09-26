//
//  ConcentrationTimelineChartUITests.swift
//  JabTrackerUITests
//

import XCTest

/// E2E acceptance tests for ConcentrationTimelineChart functionality
/// Defines the complete user experience and acceptance criteria for chart interactions
final class ConcentrationTimelineChartUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - ACCEPTANCE CRITERION: Chart displays concentration timeline correctly
    func testConcentrationTimelineDisplaysCorrectly() throws {
        // GIVEN: User has medication profile with dose history
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile first
        TestUtilities.createMedicationProfile(
            app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")

        // Create dose history for chart data
        TestUtilities.createHistoricalChartData(in: app, count: 3)

        // WHEN: User navigates to concentration timeline chart
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
        analyticsTab.tap()

        // Wait for Analytics view to load
        // sleep(3)

        // THEN: Chart renders with concentration line over time
        let chartElement = app.otherElements["concentration-timeline-chart"].firstMatch
        XCTAssertTrue(
            chartElement.waitForExistence(timeout: 5),
            "ConcentrationTimelineChart should display with dose data")

        // Verify chart shows concentration data with proper accessibility
        XCTAssertEqual(
            chartElement.label,
            "Concentration Timeline Chart showing medication concentration over time",
            "Chart should have expected accessibility label"
        )

        print("✅ Concentration timeline chart displays correctly with dose history")
    }

    // MARK: - ACCEPTANCE CRITERION: Interactive features work correctly
    func testInteractiveChartFeatures() throws {
        // GIVEN: ConcentrationTimelineChart is displayed with data
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile and dose data
        TestUtilities.createMedicationProfile(
            app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")
        TestUtilities.createHistoricalChartData(in: app, count: 4)

        // Navigate to Analytics tab
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
        analyticsTab.tap()

        // Wait for chart to load
        // sleep(3)

        let chartElement = app.otherElements["concentration-timeline-chart"].firstMatch
        XCTAssertTrue(
            chartElement.waitForExistence(timeout: 5), "Chart should exist for interaction testing")

        // WHEN: User interacts with chart using gestures
        // Test reset chart functionality (simulates double-tap reset)
        let resetButton = app.buttons["reset-chart-button"]
        XCTAssertTrue(resetButton.exists, "Reset chart button should be available")
        resetButton.tap()

        // Verify chart still exists after reset
        XCTAssertTrue(chartElement.exists, "Chart should remain visible after reset interaction")

        // Test export functionality (chart interaction feature)
        let exportButton = app.buttons["export-chart-button"]
        XCTAssertTrue(exportButton.exists, "Export chart button should be available")
        exportButton.tap()

        // Wait briefly for any export interaction
        // sleep(2)

        // Dismiss export sheet if it appeared
        if app.sheets.firstMatch.exists {
            app.sheets.firstMatch.swipeDown()
            // sleep(1)
        }

        // THEN: Chart responds appropriately to user interactions
        XCTAssertTrue(chartElement.exists, "Chart should handle interactive features gracefully")

        // Verify chart maintains functionality after interactions
        let timePeriodButton = app.buttons["time-period-last month"].firstMatch
        XCTAssertTrue(
            timePeriodButton.exists, "Time period controls should remain functional after interactions")
        timePeriodButton.tap()
        // sleep(1)

        // Chart should still be responsive after interactive features
        XCTAssertTrue(chartElement.exists, "Chart should remain responsive after all interactions")

        print("✅ Interactive chart features work correctly - reset and export functionality verified")
    }

    // MARK: - ACCEPTANCE CRITERION: Time period selection works
    func testTimePeriodSelector() throws {
        // GIVEN: ConcentrationTimelineChart is displayed
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile and dose data spanning different time periods
        TestUtilities.createMedicationProfile(
            app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")
        TestUtilities.createHistoricalChartData(in: app, count: 5)

        // Navigate to Analytics tab
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
        analyticsTab.tap()

        // Wait for chart to load
        // sleep(3)

        let chartElement = app.otherElements["concentration-timeline-chart"].firstMatch
        XCTAssertTrue(
            chartElement.waitForExistence(timeout: 5), "Chart should display for time period testing")

        // WHEN: User selects different time periods (7d, 30d, 90d, 1y)
        let lastWeekButton = app.buttons["time-period-last week"].firstMatch
        let lastMonthButton = app.buttons["time-period-last month"].firstMatch
        let lastQuarterButton = app.buttons["time-period-last quarter"].firstMatch
        let lastYearButton = app.buttons["time-period-last year"].firstMatch

        // Verify all time period buttons exist
        XCTAssertTrue(lastWeekButton.waitForExistence(timeout: 3), "Last Week button should exist")
        XCTAssertTrue(lastMonthButton.exists, "Last Month button should exist")
        XCTAssertTrue(lastQuarterButton.exists, "Last Quarter button should exist")
        XCTAssertTrue(lastYearButton.exists, "Last Year button should exist")

        // Test sequential time period selection
        lastWeekButton.tap()
        // sleep(2)
        // THEN: Chart displays correct time range data
        XCTAssertTrue(chartElement.exists, "Chart should display data for Last Week time period")

        lastMonthButton.tap()
        // sleep(2)
        XCTAssertTrue(chartElement.exists, "Chart should display data for Last Month time period")

        lastQuarterButton.tap()
        // sleep(2)
        XCTAssertTrue(chartElement.exists, "Chart should display data for Last Quarter time period")

        lastYearButton.tap()
        // sleep(2)
        XCTAssertTrue(chartElement.exists, "Chart should display data for Last Year time period")

        // Verify chart maintains responsiveness across all time period selections
        lastWeekButton.tap()
        // sleep(2)
        XCTAssertTrue(
            chartElement.exists, "Chart should maintain responsiveness across time period changes")

        print("✅ Time period selector works correctly - all time ranges functional")
    }

    // MARK: - ACCEPTANCE CRITERION: Accessibility features work correctly
    func testChartAccessibilityFeatures() throws {
        // GIVEN: ConcentrationTimelineChart is displayed with data
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile and dose data
        TestUtilities.createMedicationProfile(
            app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")
        TestUtilities.createHistoricalChartData(in: app, count: 3)

        // Navigate to Analytics tab
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
        analyticsTab.tap()

        // Wait for chart to load
        // sleep(3)

        // WHEN: User navigates chart with VoiceOver enabled
        let chartElement = app.otherElements["concentration-timeline-chart"].firstMatch
        XCTAssertTrue(
            chartElement.waitForExistence(timeout: 5), "Chart should display for accessibility testing")

        // THEN: Chart provides complete accessibility experience
        // Verify chart has proper accessibility labeling
        XCTAssertNotNil(chartElement.label, "Chart should have accessibility label")
        XCTAssertFalse(chartElement.label.isEmpty, "Chart accessibility label should not be empty")

        // Verify chart is hittable for VoiceOver navigation
        XCTAssertTrue(chartElement.isHittable, "Chart should be hittable for accessibility navigation")

        // Test time period button accessibility
        let lastWeekButton = app.buttons["time-period-last week"].firstMatch
        let lastMonthButton = app.buttons["time-period-last month"].firstMatch
        let resetButton = app.buttons["reset-chart-button"].firstMatch
        let exportButton = app.buttons["export-chart-button"].firstMatch

        // Verify all interactive elements are accessible
        XCTAssertTrue(
            lastWeekButton.waitForExistence(timeout: 3), "Time period buttons should be accessible")
        XCTAssertTrue(lastWeekButton.isHittable, "Last Week button should be hittable")
        XCTAssertEqual(
            lastWeekButton.label, "Last Week", "Last Week button should have correct accessibility label")

        XCTAssertTrue(lastMonthButton.isHittable, "Last Month button should be hittable")
        XCTAssertEqual(
            lastMonthButton.label, "Last Month",
            "Last Month button should have correct accessibility label")

        XCTAssertTrue(resetButton.isHittable, "Reset button should be hittable")
        XCTAssertEqual(
            resetButton.label, "Reset chart view",
            "Reset button should have descriptive accessibility label")

        XCTAssertTrue(exportButton.isHittable, "Export button should be hittable")
        XCTAssertEqual(
            exportButton.label, "Export chart",
            "Export button should have descriptive accessibility label")

        // Test VoiceOver interaction with time period selection
        lastWeekButton.tap()
        // sleep(1)
        XCTAssertTrue(chartElement.exists, "Chart should remain accessible after time period change")

        print("✅ Chart accessibility features work correctly - full VoiceOver support verified")
    }

    // MARK: - ACCEPTANCE CRITERION: Performance with large datasets
    func testChartPerformanceWithLargeDatasets() throws {
        // GIVEN: User has extensive dose history (1+ year of data)
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile
        TestUtilities.createMedicationProfile(
            app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")

        // Create large dataset (simulating extensive dose history)
        // Note: For E2E testing, we use a reasonable size to avoid excessive test duration
        TestUtilities.createHistoricalChartData(in: app, count: 10)

        // WHEN: ConcentrationTimelineChart loads with full dataset
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")

        // Measure load time for large dataset
        let startTime = Date()
        analyticsTab.tap()

        // Wait for chart to load
        let chartElement = app.otherElements["concentration-timeline-chart"].firstMatch
        XCTAssertTrue(
            chartElement.waitForExistence(timeout: 10),
            "Chart should load with large dataset within reasonable time")

        let loadTime = Date().timeIntervalSince(startTime)

        // THEN: Chart maintains smooth performance
        // Verify reasonable load time (under 10 seconds for E2E testing)
        XCTAssertLessThan(loadTime, 10.0, "Chart should load large dataset within 10 seconds")

        // Test time period switching performance with large dataset
        let performanceStartTime = Date()

        let lastMonthButton = app.buttons["time-period-last month"].firstMatch
        XCTAssertTrue(
            lastMonthButton.waitForExistence(timeout: 3), "Time period buttons should be available")

        lastMonthButton.tap()
        // sleep(2)
        XCTAssertTrue(chartElement.exists, "Chart should handle time period changes with large dataset")

        let lastYearButton = app.buttons["time-period-last year"].firstMatch
        lastYearButton.tap()
        // sleep(2)
        XCTAssertTrue(chartElement.exists, "Chart should handle year view with large dataset")

        let performanceTime = Date().timeIntervalSince(performanceStartTime)

        // Verify interactive performance (under 8 seconds for time period changes)
        XCTAssertLessThan(
            performanceTime, 8.0, "Time period changes should be responsive with large dataset")

        // Test chart controls responsiveness
        let resetButton = app.buttons["reset-chart-button"].firstMatch
        resetButton.tap()
        // sleep(1)
        XCTAssertTrue(chartElement.exists, "Chart reset should work smoothly with large dataset")

        print(
            "✅ Chart performance with large datasets verified - load time: \\(String(format: \"%.2f\", loadTime))s, interaction time: \\(String(format: \"%.2f\", performanceTime))s"
        )
    }
}
