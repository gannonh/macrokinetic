//
//  ChartPerformanceUITests.swift
//  JabTrackerUITests
//
//  Phase 6 Performance Profiling: Chart rendering with pre-seeded large datasets
//  Uses TestDataSeeding via launch arguments for instant data availability

import XCTest

/// E2E performance tests for ConcentrationTimelineChart with large pre-seeded datasets
/// Tests actual chart rendering performance with 1+ year of data
///
/// **Performance Targets:**
/// - Tab switching: <500ms
/// - Chart rendering: <2000ms
/// - Chart interactions: <100ms
final class ChartPerformanceUITests: XCTestCase {

    var screenshotCapture: ScreenshotCapture!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func setUp() {
        super.setUp()
        let app = XCUIApplication()
        screenshotCapture = ScreenshotCapture(app: app, testCase: self, phase: "performance")
    }

    // MARK: - Chart Rendering Performance (Pre-Seeded Data)

    /// Test chart rendering with 30 days of pre-seeded data (medium dataset)
    func testChartRenderingPerformance_MediumDataset() throws {
        // GIVEN: App launched with 30 days of pre-seeded data (~4 doses)
        let preset = TestUtilities.TestDataPreset.medium
        let app = TestUtilities.launchAppWithSeededData(preset: preset)

        print("📊 App launched with \(preset.daysOfHistory) days of pre-seeded data")

        // 📸 Capture initial state
        screenshotCapture.capture(
            section: "medium-dataset",
            description: "app-launched",
            metadata: ["days": String(preset.daysOfHistory)]
        )

        // WHEN: Navigate to Analytics tab and measure chart rendering
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")

        let navigationStart = Date()
        analyticsTab.tap()

        let chartElement = app.otherElements["concentration-timeline-chart"].firstMatch
        let chartExists = chartElement.waitForExistence(timeout: 10)
        let navigationTime = Date().timeIntervalSince(navigationStart) * 1000  // ms

        XCTAssertTrue(chartExists, "Chart should render with pre-seeded data")

        // 📸 Capture chart loaded
        screenshotCapture.capture(
            section: "medium-dataset",
            description: "chart-loaded",
            metadata: [
                "navigation_time_ms": String(format: "%.1f", navigationTime),
                "days": String(preset.daysOfHistory),
            ]
        )

        // THEN: Chart renders within acceptable time
        print(
            "⏱️  Medium dataset (\(preset.daysOfHistory) days) navigation: \(String(format: "%.1f", navigationTime))ms")
        XCTAssertLessThan(
            navigationTime, 1000,
            "Medium dataset navigation should be <1000ms (actual: \(String(format: "%.1f", navigationTime))ms)"
        )

        // Verify chart is interactive
        XCTAssertTrue(chartElement.isHittable, "Chart should be interactive after rendering")

        print("✅ Medium dataset performance: \(String(format: "%.1f", navigationTime))ms")
    }

    /// Test chart rendering with 365 days of pre-seeded data (large dataset - CRITICAL)
    func testChartRenderingPerformance_LargeDataset() throws {
        // GIVEN: App launched with 1 year of pre-seeded data (~52 doses)
        let preset = TestUtilities.TestDataPreset.large
        let app = TestUtilities.launchAppWithSeededData(preset: preset)

        print("📊 App launched with \(preset.daysOfHistory) days of pre-seeded data")

        // 📸 Capture initial state
        screenshotCapture.capture(
            section: "large-dataset",
            description: "app-launched",
            metadata: ["days": String(preset.daysOfHistory)]
        )

        // WHEN: Navigate to Analytics and measure rendering
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")

        let navigationStart = Date()
        analyticsTab.tap()

        let chartElement = app.otherElements["concentration-timeline-chart"].firstMatch
        let chartExists = chartElement.waitForExistence(timeout: 15)  // Longer timeout for large dataset
        let navigationTime = Date().timeIntervalSince(navigationStart) * 1000  // ms

        XCTAssertTrue(chartExists, "Chart should render with 1 year of pre-seeded data")

        // 📸 Capture chart loaded
        screenshotCapture.capture(
            section: "large-dataset",
            description: "chart-loaded",
            metadata: [
                "navigation_time_ms": String(format: "%.1f", navigationTime),
                "days": String(preset.daysOfHistory),
            ]
        )

        // THEN: Chart renders within target time for large dataset
        print("⏱️  Large dataset (\(preset.daysOfHistory) days) navigation: \(String(format: "%.1f", navigationTime))ms")
        XCTAssertLessThan(
            navigationTime, 2000,
            "Large dataset navigation should be <2000ms (actual: \(String(format: "%.1f", navigationTime))ms)"
        )

        // Verify chart remains responsive with large dataset
        XCTAssertTrue(chartElement.isHittable, "Chart should remain interactive with large dataset")

        print("✅ Large dataset (1 year) performance: \(String(format: "%.1f", navigationTime))ms")
    }

    // MARK: - Tab Switching Performance

    /// Test tab switching performance with pre-seeded data
    func testTabSwitchingPerformance() throws {
        // GIVEN: App with medium dataset
        let preset = TestUtilities.TestDataPreset.medium
        let app = TestUtilities.launchAppWithSeededData(preset: preset)

        // Navigate to Analytics once to warm up
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5))
        analyticsTab.tap()

        let chartElement = app.otherElements["concentration-timeline-chart"].firstMatch
        XCTAssertTrue(chartElement.waitForExistence(timeout: 10))

        // WHEN: Switch tabs multiple times
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.exists)

        // Switch away
        dashboardTab.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // 📸 Capture before switch back
        screenshotCapture.capture(
            section: "tab-switching",
            description: "before-return"
        )

        // Measure return to Analytics
        let switchStart = Date()
        analyticsTab.tap()
        _ = chartElement.waitForExistence(timeout: 5)
        let switchTime = Date().timeIntervalSince(switchStart) * 1000  // ms

        // 📸 Capture after switch
        screenshotCapture.capture(
            section: "tab-switching",
            description: "after-return",
            metadata: ["switch_time_ms": String(format: "%.1f", switchTime)]
        )

        // THEN: Tab switching is fast
        print("⏱️  Tab switch time: \(String(format: "%.1f", switchTime))ms")
        XCTAssertLessThan(
            switchTime, 500,
            "Tab switching should be <500ms (actual: \(String(format: "%.1f", switchTime))ms)"
        )

        print("✅ Tab switching performance: \(String(format: "%.1f", switchTime))ms")
    }

    // MARK: - Chart Interaction Performance

    /// Test chart interaction responsiveness
    func testChartInteractionPerformance() throws {
        // GIVEN: Chart with medium dataset
        let preset = TestUtilities.TestDataPreset.medium
        let app = TestUtilities.launchAppWithSeededData(preset: preset)

        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5))
        analyticsTab.tap()

        let chartElement = app.otherElements["concentration-timeline-chart"].firstMatch
        XCTAssertTrue(chartElement.waitForExistence(timeout: 10))

        // 📸 Capture initial state
        screenshotCapture.capture(
            section: "interaction",
            description: "initial"
        )

        // WHEN: Test reset button interaction
        let resetButton = app.buttons["reset-chart-button"]
        XCTAssertTrue(resetButton.exists, "Reset button should exist")

        let resetStart = Date()
        resetButton.tap()
        Thread.sleep(forTimeInterval: 0.1)
        let resetTime = Date().timeIntervalSince(resetStart) * 1000  // ms

        // 📸 Capture after reset
        screenshotCapture.capture(
            section: "interaction",
            description: "after-reset",
            metadata: ["reset_time_ms": String(format: "%.1f", resetTime)]
        )

        // THEN: Reset is fast
        print("⏱️  Reset interaction: \(String(format: "%.1f", resetTime))ms")
        XCTAssertLessThan(
            resetTime, 100,
            "Reset should be <100ms (actual: \(String(format: "%.1f", resetTime))ms)"
        )

        // WHEN: Test time period change
        let timePeriodButton = app.buttons["time-period-last month"].firstMatch
        XCTAssertTrue(timePeriodButton.exists, "Time period button should exist")

        let timePeriodStart = Date()
        timePeriodButton.tap()
        Thread.sleep(forTimeInterval: 0.2)
        let timePeriodTime = Date().timeIntervalSince(timePeriodStart) * 1000  // ms

        // 📸 Capture after time period change
        screenshotCapture.capture(
            section: "interaction",
            description: "after-time-period",
            metadata: ["time_period_time_ms": String(format: "%.1f", timePeriodTime)]
        )

        // THEN: Time period change is responsive
        print("⏱️  Time period change: \(String(format: "%.1f", timePeriodTime))ms")
        XCTAssertLessThan(
            timePeriodTime, 300,
            "Time period change should be <300ms (actual: \(String(format: "%.1f", timePeriodTime))ms)"
        )

        print(
            """
            ✅ Chart interaction performance:
               - Reset: \(String(format: "%.1f", resetTime))ms
               - Time period: \(String(format: "%.1f", timePeriodTime))ms
            """)
    }
}
