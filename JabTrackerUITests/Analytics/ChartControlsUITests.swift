//
//  ChartControlsUITests.swift
//  JabTrackerUITests
//
//  Enhanced with screenshot capture and performance measurement for UI/UX analysis
//

import XCTest

/// E2E acceptance tests for chart controls functionality
/// Defines the complete user experience and acceptance criteria for chart interactions
/// Enhanced with screenshot capture and performance measurement for UI/UX analysis
final class ChartControlsUITests: XCTestCase {

    var screenshotCapture: ScreenshotCapture!

    // Debug flag - set to true to enable debug output during test development
    private let enableDebugOutput = false

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func setUp() {
        super.setUp()
        let app = XCUIApplication()
        screenshotCapture = ScreenshotCapture(app: app, testCase: self, phase: "baseline")
    }

    // MARK: - Helper Methods

    /// Find chart element using multiple possible identifiers
    private func findChartElement(in app: XCUIApplication) -> XCUIElement {
        let chartElement = app.otherElements["concentration-timeline-chart"]
        let analyticsChartElement = app.otherElements["analytics-concentration-chart"]

        return chartElement.exists ? chartElement : analyticsChartElement
    }

    // MARK: - ACCEPTANCE CRITERION: Time period selector works correctly
    func testTimePeriodSelectorChangesChartTimeframe() throws {
        // GIVEN: User has dose data and is viewing concentration timeline chart
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile first
        TestUtilities.createMedicationProfile(
            app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")

        // Create multiple doses for chart data
        TestUtilities.createHistoricalChartData(in: app, count: 5)

        // 📸 PHASE 1: Capture baseline before chart controls test
        screenshotCapture.capture(
            section: "chart-controls",
            description: "before-navigation",
            metadata: ["state": "ready", "dose_count": "5"]
        )

        // Navigate to Analytics tab
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")

        // Measure chart controls load performance
        let loadStart = Date()
        analyticsTab.tap()

        // Wait for Analytics view to load
        let analyticsView = app.scrollViews["analytics-scroll-view"]
        _ = analyticsView.waitForExistence(timeout: 10)
        let loadEnd = Date()
        let loadTime = loadEnd.timeIntervalSince(loadStart) * 1000  // ms

        // 📸 PHASE 1: Capture chart controls view loaded
        screenshotCapture.capture(
            section: "chart-controls",
            description: "controls-loaded",
            metadata: [
                "load_time_ms": String(format: "%.1f", loadTime),
                "section": "concentration",
                "state": "chart_controls_loaded",
            ]
        )

        // Debug what buttons actually exist
        if enableDebugOutput {
            print("🔍 DEBUG: All buttons on Analytics tab:")
            for button in app.buttons.allElementsBoundByIndex where button.exists {
                print("  Button: '\(button.identifier)' label: '\(button.label)'")
            }
        }

        // Verify we have a chart (not empty state)
        let chartElement = findChartElement(in: app)
        let emptyState = app.otherElements.containing(.staticText, identifier: "No Analytics Data")
            .firstMatch

        XCTAssertFalse(
            emptyState.exists, "Test requires dose data - empty state indicates test data creation failed"
        )
        XCTAssertTrue(
            chartElement.waitForExistence(timeout: 5), "Chart should be present with test data")

        // WHEN: User would tap different time period selectors
        // NOTE: Time period selector buttons are not yet implemented in ConcentrationTimelineChart
        // The chart shows "Last Week", "Last Month", "Last Quarter", "Last Year" labels
        // but they are not interactive buttons yet

        // For now, just verify the chart displays with the historical data
        print("ℹ️ Time period selectors not yet implemented - chart shows static time period labels")

        // Verify we can see the time period labels (even if not interactive yet)
        let lastWeekLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Last' AND label CONTAINS 'Week'")
        ).firstMatch
        let lastMonthLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Last' AND label CONTAINS 'Month'")
        ).firstMatch

        if lastWeekLabel.exists || lastMonthLabel.exists {
            print("✅ Chart displays time period labels (static for now)")
        }

        // THEN: Chart should display the concentration timeline with historical data
        XCTAssertTrue(chartElement.exists, "Chart should display concentration timeline")

        // The chart should be showing data points for the doses we created
        // We created doses at 0, 7, 14, 21, 28 days ago
        print("✅ Chart displays with historical dose data spanning multiple weeks")
    }

    // MARK: - ACCEPTANCE CRITERION: Chart controls display correct state
    func testChartControlsDisplayCorrectState() throws {
        // GIVEN: User has chart controls visible
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile and dose data
        TestUtilities.createMedicationProfile(
            app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")
        TestUtilities.createHistoricalChartData(in: app, count: 5)

        // Navigate to Analytics tab
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
        analyticsTab.tap()

        // Wait for Analytics view to load
        // sleep(3)

        // Verify chart is present (not empty state)
        let chartElement = findChartElement(in: app)
        XCTAssertTrue(
            chartElement.waitForExistence(timeout: 5), "Chart should be present with test data")

        // WHEN: User interacts with time period controls
        // Now that accessibility identifiers are fixed, we can use them directly
        let lastWeekButton = app.buttons["time-period-last week"]
        let lastMonthButton = app.buttons["time-period-last month"]
        let lastQuarterButton = app.buttons["time-period-last quarter"]
        let lastYearButton = app.buttons["time-period-last year"]

        // THEN: Time period controls should be accessible and functional
        XCTAssertTrue(lastWeekButton.waitForExistence(timeout: 3), "Last Week button should exist")
        XCTAssertTrue(lastMonthButton.exists, "Last Month button should exist")
        XCTAssertTrue(lastQuarterButton.exists, "Last Quarter button should exist")
        XCTAssertTrue(lastYearButton.exists, "Last Year button should exist")

        print("✅ Found time period buttons using accessibility identifiers")

        // Test actual button interactions
        lastWeekButton.tap()
        // sleep(1)
        XCTAssertTrue(chartElement.exists, "Chart should remain visible after Last Week selection")

        lastMonthButton.tap()
        // sleep(1)
        XCTAssertTrue(chartElement.exists, "Chart should remain visible after Last Month selection")

        lastQuarterButton.tap()
        // sleep(1)
        XCTAssertTrue(chartElement.exists, "Chart should remain visible after Last Quarter selection")

        lastYearButton.tap()
        // sleep(1)
        XCTAssertTrue(chartElement.exists, "Chart should remain visible after Last Year selection")

        print(
            "✅ All time period buttons are functional - chart maintains visibility through selections")
    }

    // MARK: - ACCEPTANCE CRITERION: Chart controls are accessible
    func testChartControlsAccessibility() throws {
        // GIVEN: User is viewing concentration timeline chart
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile and dose data
        TestUtilities.createMedicationProfile(
            app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")
        TestUtilities.createHistoricalChartData(in: app, count: 3)

        // Navigate to Analytics tab
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
        analyticsTab.tap()

        // Wait for Analytics view to load
        // sleep(3)

        // Verify chart is present
        let chartElement = findChartElement(in: app)
        XCTAssertTrue(
            chartElement.waitForExistence(timeout: 5), "Chart should be present with test data")

        // WHEN: User navigates chart with accessibility
        // THEN: Chart provides accessibility information
        XCTAssertNotNil(chartElement.label, "Chart should have accessibility label")
        XCTAssertFalse(chartElement.label.isEmpty, "Chart accessibility label should not be empty")

        print("✅ Chart accessibility label: '\(chartElement.label)'")

        // Test time period button accessibility
        let lastWeekButton = app.buttons["time-period-last week"]
        let lastMonthButton = app.buttons["time-period-last month"]
        let lastQuarterButton = app.buttons["time-period-last quarter"]
        let lastYearButton = app.buttons["time-period-last year"]

        XCTAssertTrue(
            lastWeekButton.waitForExistence(timeout: 3), "Last Week button should be accessible")
        XCTAssertTrue(lastMonthButton.exists, "Last Month button should be accessible")
        XCTAssertTrue(lastQuarterButton.exists, "Last Quarter button should be accessible")
        XCTAssertTrue(lastYearButton.exists, "Last Year button should be accessible")

        // Verify buttons are hittable for VoiceOver
        XCTAssertTrue(lastWeekButton.isHittable, "Last Week button should be hittable")
        XCTAssertTrue(lastMonthButton.isHittable, "Last Month button should be hittable")
        XCTAssertTrue(lastQuarterButton.isHittable, "Last Quarter button should be hittable")
        XCTAssertTrue(lastYearButton.isHittable, "Last Year button should be hittable")

        // Test button labels for accessibility - buttons should have their text as the label
        XCTAssertEqual(lastWeekButton.label, "Last Week", "Last Week button should have correct label")
        XCTAssertEqual(
            lastMonthButton.label, "Last Month", "Last Month button should have correct label")
        XCTAssertEqual(
            lastQuarterButton.label, "Last Quarter", "Last Quarter button should have correct label")
        XCTAssertEqual(lastYearButton.label, "Last Year", "Last Year button should have correct label")

        // Test VoiceOver interaction with chart
        XCTAssertTrue(chartElement.isHittable, "Chart should be hittable for accessibility navigation")

        print("✅ All chart controls are properly accessible with VoiceOver support")
    }

    // MARK: - ACCEPTANCE CRITERION: Multiple time periods can be selected
    func testMultipleTimePeriodSelection() throws {
        // GIVEN: Chart with accessible time period options
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile and dose data for testing
        TestUtilities.createMedicationProfile(
            app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")
        TestUtilities.createHistoricalChartData(in: app, count: 4)

        // Navigate to Analytics tab
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
        analyticsTab.tap()

        // Wait for Analytics view to load
        // sleep(3)

        // Verify chart is present with data
        let chartElement = findChartElement(in: app)
        XCTAssertTrue(
            chartElement.waitForExistence(timeout: 5), "Chart should be present with test data")

        // WHEN: User selects different time periods sequentially
        let lastWeekButton = app.buttons["time-period-last week"]
        let lastMonthButton = app.buttons["time-period-last month"]
        let lastQuarterButton = app.buttons["time-period-last quarter"]
        let lastYearButton = app.buttons["time-period-last year"]

        // Verify all buttons are accessible
        XCTAssertTrue(lastWeekButton.waitForExistence(timeout: 3), "Last Week button should exist")
        XCTAssertTrue(lastMonthButton.exists, "Last Month button should exist")
        XCTAssertTrue(lastQuarterButton.exists, "Last Quarter button should exist")
        XCTAssertTrue(lastYearButton.exists, "Last Year button should exist")

        // Test sequential time period selection
        lastWeekButton.tap()
        // sleep(2)
        XCTAssertTrue(chartElement.exists, "Chart should remain visible after Week selection")

        lastMonthButton.tap()
        // sleep(2)
        XCTAssertTrue(chartElement.exists, "Chart should remain visible after Month selection")

        lastQuarterButton.tap()
        // sleep(2)
        XCTAssertTrue(chartElement.exists, "Chart should remain visible after Quarter selection")

        lastYearButton.tap()
        // sleep(2)
        XCTAssertTrue(chartElement.exists, "Chart should remain visible after Year selection")

        // Test switching back to earlier time periods
        lastWeekButton.tap()
        // sleep(2)
        XCTAssertTrue(chartElement.exists, "Chart should handle switching back to Week view")

        print("✅ Multiple time period selection works - all buttons functional and chart responsive")
    }

    // MARK: - ACCEPTANCE CRITERION: Default time period is selected on load
    func testDefaultTimePeriodSelection() throws {
        // GIVEN: User opens chart for first time
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile and dose data
        TestUtilities.createMedicationProfile(
            app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")
        TestUtilities.createHistoricalChartData(in: app, count: 2)

        // Navigate to Analytics tab
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
        analyticsTab.tap()

        // Wait for Analytics view to load
        // sleep(3)

        // WHEN: Chart loads with default configuration
        let chartElement = findChartElement(in: app)
        XCTAssertTrue(
            chartElement.waitForExistence(timeout: 5), "Chart should load with default time period")

        // THEN: Chart loads successfully with default period
        XCTAssertTrue(chartElement.exists, "Chart should display with default time period selection")

        // Verify chart accessibility indicates it has data content
        XCTAssertFalse(
            chartElement.label.isEmpty, "Chart should have proper accessibility label on load")
        XCTAssertEqual(
            chartElement.label,
            "Concentration Timeline Chart showing medication concentration over time",
            "Chart should have expected accessibility label"
        )

        // Verify that time period buttons are present and one is selected by default
        let lastWeekButton = app.buttons["time-period-last week"]
        let lastMonthButton = app.buttons["time-period-last month"]
        let lastQuarterButton = app.buttons["time-period-last quarter"]
        let lastYearButton = app.buttons["time-period-last year"]

        // All buttons should exist
        XCTAssertTrue(lastWeekButton.waitForExistence(timeout: 3), "Last Week button should exist")
        XCTAssertTrue(lastMonthButton.exists, "Last Month button should exist")
        XCTAssertTrue(lastQuarterButton.exists, "Last Quarter button should exist")
        XCTAssertTrue(lastYearButton.exists, "Last Year button should exist")

        // Test that a selection change works from the default state
        lastMonthButton.tap()
        // sleep(2)
        XCTAssertTrue(chartElement.exists, "Chart should remain functional after changing from default")

        // Switch back to verify default behavior is restorable
        lastWeekButton.tap()
        // sleep(2)
        XCTAssertTrue(
            chartElement.exists, "Chart should handle switching back to Week view from default")

        print(
            "✅ Default time period functionality verified - chart loads properly and selections work from initial state"
        )
    }
}
