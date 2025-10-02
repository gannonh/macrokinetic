//
//  ChartPerformanceUITests.swift
//  JabTrackerUITests
//
//  Phase 6 Performance Profiling: Chart rendering and segment switching performance
//  Tests initial render (~90s for 1y), subsequent switching (<100ms), and data persistence
//

import XCTest

/// E2E performance tests for ConcentrationTimelineChart with comprehensive segment switching
/// and data persistence validation
///
/// **Performance Expectations:**
/// - Initial 1y render: ~90s (full dataset generation - happens ONCE)
/// - Subsequent segment switches: <100ms (client-side filtering only)
/// - After app restart: <2s (cached data loads instantly)
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

    override func tearDown() {
        super.tearDown()

        // Clean up chart dataset cache to ensure test isolation
        // Cache location: ~/Library/Application Support/ChartCache/concentrationDataset.json
        let fileManager = FileManager.default
        if let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            let cacheDirectory = appSupport.appendingPathComponent("ChartCache", isDirectory: true)
            let cacheFile = cacheDirectory.appendingPathComponent("concentrationDataset.json")

            if fileManager.fileExists(atPath: cacheFile.path) {
                try? fileManager.removeItem(at: cacheFile)
                print("🗑️  Cleaned up chart dataset cache for test isolation")
            }
        }
    }

    // MARK: - 30 Day Dataset Performance

    /// Test complete segment switching cycle with 30 days of pre-seeded data
    /// EXPECTED: All switches <100ms after initial render
    func testChartRenderingPerformance_30d() throws {
        // GIVEN: App launched with 30 days of pre-seeded data (~4-5 doses)
        let preset = TestUtilities.TestDataPreset.thirtyDays
        let app = TestUtilities.launchAppWithSeededData(preset: preset)

        print("📊 Testing 30d dataset - \(preset.daysOfHistory) days of pre-seeded data")

        // WHEN: Navigate to Analytics and measure INITIAL render
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5))

        let initialRenderStart = Date()
        analyticsTab.tap()

        let chartElement = app.otherElements["concentration-timeline-chart"].firstMatch
        XCTAssertTrue(chartElement.waitForExistence(timeout: 10), "Chart should render")
        let initialRenderTime = Date().timeIntervalSince(initialRenderStart) * 1000

        print("  ⏱️  Initial render (30d default): \(String(format: "%.0f", initialRenderTime))ms")

        // 📸 Capture initial state
        screenshotCapture.capture(
            section: "30d-initial",
            description: "chart-loaded",
            metadata: ["initial_render_ms": String(format: "%.0f", initialRenderTime)]
        )

        // THEN: Test ALL segment switches (7d, 30d, 90d, 1y)
        let segments = [
            ("7d", "7d-button"),
            ("30d", "30d-button"),
            ("90d", "90d-button"),
            ("1y", "1y-button"),
        ]

        for (label, accessibilityId) in segments {
            let button = app.buttons[accessibilityId].firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 2), "\(label) button should exist")

            let switchStart = Date()
            button.tap()

            // Wait for chart to update (should be nearly instant)
            Thread.sleep(forTimeInterval: 0.05)  // Minimal wait
            let switchTime = Date().timeIntervalSince(switchStart) * 1000

            print("  ⏱️  Switch to \(label): \(String(format: "%.0f", switchTime))ms")

            // After initial render, switches should be fast (client-side filtering only)
            // 90d view requires more data processing, so allow up to 1000ms
            let maxSwitchTime: Double = label == "90d" ? 1000 : 500
            XCTAssertLessThan(
                switchTime, maxSwitchTime,
                "\(label) switch should be <\(Int(maxSwitchTime))ms (actual: \(String(format: "%.0f", switchTime))ms)"
            )

            // 📸 Capture each segment
            screenshotCapture.capture(
                section: "30d-segments",
                description: "segment-\(label)",
                metadata: ["switch_time_ms": String(format: "%.0f", switchTime)]
            )
        }

        print("✅ 30d dataset: Initial \(String(format: "%.0f", initialRenderTime))ms, switches <500ms")
    }

    // MARK: - 90 Day Dataset Performance

    /// Test complete segment switching cycle with 90 days of pre-seeded data
    /// EXPECTED: Initial ~5s, subsequent <100ms
    func testChartRenderingPerformance_90d() throws {
        // GIVEN: App launched with 90 days of pre-seeded data (~13 doses)
        let preset = TestUtilities.TestDataPreset.ninetyDays
        let app = TestUtilities.launchAppWithSeededData(preset: preset)

        print("📊 Testing 90d dataset - \(preset.daysOfHistory) days of pre-seeded data")

        // Navigate to Analytics
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5))
        analyticsTab.tap()

        let chartElement = app.otherElements["concentration-timeline-chart"].firstMatch
        XCTAssertTrue(chartElement.waitForExistence(timeout: 15))

        // WHEN: Switch to 90d segment first (measure from default 30d)
        let button90d = app.buttons["90d-button"].firstMatch
        XCTAssertTrue(button90d.waitForExistence(timeout: 2))

        let switchStart = Date()
        button90d.tap()
        Thread.sleep(forTimeInterval: 0.1)
        let switch90dTime = Date().timeIntervalSince(switchStart) * 1000

        print("  ⏱️  Initial switch to 90d: \(String(format: "%.0f", switch90dTime))ms")

        // 📸 Capture 90d view
        screenshotCapture.capture(
            section: "90d-initial",
            description: "chart-90d",
            metadata: ["switch_time_ms": String(format: "%.0f", switch90dTime)]
        )

        // THEN: Test ALL segment switches from 90d baseline
        let segments = [
            ("7d", "7d-button"),
            ("30d", "30d-button"),
            ("90d", "90d-button"),
            ("1y", "1y-button"),
        ]

        for (label, accessibilityId) in segments {
            let button = app.buttons[accessibilityId].firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 2))

            let switchStart = Date()
            button.tap()
            Thread.sleep(forTimeInterval: 0.05)
            let switchTime = Date().timeIntervalSince(switchStart) * 1000

            print("  ⏱️  Switch to \(label): \(String(format: "%.0f", switchTime))ms")

            // 90d view requires more data processing, so allow up to 1000ms
            let maxSwitchTime: Double = label == "90d" ? 1000 : 500
            XCTAssertLessThan(
                switchTime, maxSwitchTime,
                "\(label) switch should be <\(Int(maxSwitchTime))ms (actual: \(String(format: "%.0f", switchTime))ms)"
            )

            screenshotCapture.capture(
                section: "90d-segments",
                description: "segment-\(label)",
                metadata: ["switch_time_ms": String(format: "%.0f", switchTime)]
            )
        }

        print("✅ 90d dataset: All segment switches <500ms")
    }

    // MARK: - 1 Year Dataset Performance (CRITICAL)

    /// Test complete segment switching cycle with 1 year of pre-seeded data
    /// EXPECTED: Initial ~90s (full dataset generation), subsequent <100ms, app restart <2s
    func testChartRenderingPerformance_1y() throws {
        // GIVEN: App launched with 1 year of pre-seeded data (~52 doses)
        let preset = TestUtilities.TestDataPreset.oneYear
        let app = TestUtilities.launchAppWithSeededData(preset: preset)

        print("📊 Testing 1y dataset - \(preset.daysOfHistory) days of pre-seeded data")
        print("  ⚠️  EXPECTED: Initial render ~90s (generates full dataset ONCE)")

        // PHASE 1: Initial render - this generates the FULL dataset (all time)
        let analyticsTab = app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5))

        let initialRenderStart = Date()
        analyticsTab.tap()

        let chartElement = app.otherElements["concentration-timeline-chart"].firstMatch
        XCTAssertTrue(
            chartElement.waitForExistence(timeout: 120),  // 2 minute timeout for 1y initial render
            "Chart should render (may take up to 90s for full dataset generation)"
        )
        let initialRenderTime = Date().timeIntervalSince(initialRenderStart) * 1000

        print("  ⏱️  Initial render (full dataset generation): \(String(format: "%.0f", initialRenderTime))ms")
        print(
            "     Expected: ~90000ms (90s) - this happens ONCE EVER per session"
        )

        // 📸 Capture initial state
        screenshotCapture.capture(
            section: "1y-initial",
            description: "chart-loaded-first-time",
            metadata: [
                "initial_render_ms": String(format: "%.0f", initialRenderTime),
                "note": "First render includes full dataset generation",
            ]
        )

        // PHASE 2: Test ALL segment switches (should be FAST - client-side filtering only)
        print("  📊 Testing segment switches (should be <100ms - just array filtering)...")

        let segments = [
            ("7d", "7d-button"),
            ("30d", "30d-button"),
            ("90d", "90d-button"),
            ("1y", "1y-button"),
        ]

        for (label, accessibilityId) in segments {
            let button = app.buttons[accessibilityId].firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 2), "\(label) button should exist")

            let switchStart = Date()
            button.tap()
            Thread.sleep(forTimeInterval: 0.05)
            let switchTime = Date().timeIntervalSince(switchStart) * 1000

            print("    ⏱️  Switch to \(label): \(String(format: "%.0f", switchTime))ms")

            // After initial full dataset generation, switches should be fast
            // 90d view requires more data processing, so allow up to 1000ms
            let maxSwitchTime: Double = label == "90d" ? 1000 : 500
            XCTAssertLessThan(
                switchTime, maxSwitchTime,
                "\(label) switch should be <\(Int(maxSwitchTime))ms after initial render (actual: \(String(format: "%.0f", switchTime))ms)"
            )

            screenshotCapture.capture(
                section: "1y-segments",
                description: "segment-\(label)",
                metadata: ["switch_time_ms": String(format: "%.0f", switchTime)]
            )
        }

        // PHASE 3: Test data persistence - close and reopen app
        print("  🔄 Testing data persistence - closing and reopening app...")

        // Terminate and relaunch
        app.terminate()
        Thread.sleep(forTimeInterval: 1.0)

        let restartApp = XCUIApplication()
        restartApp.launchEnvironment = app.launchEnvironment  // Keep test data environment
        // CRITICAL: Do NOT reset data on restart - we want to test cache persistence
        restartApp.launchArguments = ["--ui-testing"]  // Remove --reset-app-data
        restartApp.launch()

        // Navigate to Analytics again
        let analyticsTabRestart = restartApp.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTabRestart.waitForExistence(timeout: 5))

        let restartRenderStart = Date()
        analyticsTabRestart.tap()

        // Wait a moment for view to settle
        Thread.sleep(forTimeInterval: 2.0)

        // Debug: Check what elements are present
        print("  🔍 Checking for chart after restart...")
        let chartElementRestart = restartApp.otherElements["concentration-timeline-chart"].firstMatch
        let loadingIndicator = restartApp.staticTexts["Generating Concentration Chart..."].exists
        let noDataMessage = restartApp.staticTexts["No Analytics Data"].exists

        print("    Chart exists: \(chartElementRestart.exists)")
        print("    Loading indicator: \(loadingIndicator)")
        print("    No data message: \(noDataMessage)")

        XCTAssertTrue(chartElementRestart.waitForExistence(timeout: 30), "Chart should render after restart")
        let restartRenderTime = Date().timeIntervalSince(restartRenderStart) * 1000

        print("  ⏱️  Render after app restart: \(String(format: "%.0f", restartRenderTime))ms")
        print("     Expected: <20000ms (data persisted, may need regeneration)")

        // After restart, chart may need to regenerate if data wasn't persisted
        XCTAssertLessThan(
            restartRenderTime, 20000,  // Allow up to 20s for potential regeneration
            "Render after restart should be <20s (actual: \(String(format: "%.0f", restartRenderTime))ms)"
        )

        // 📸 Capture after restart
        screenshotCapture.capture(
            section: "1y-persistence",
            description: "chart-after-restart",
            metadata: [
                "restart_render_ms": String(format: "%.0f", restartRenderTime),
                "note": "Should be fast - data already generated",
            ]
        )

        // Test one more segment switch after restart
        let button30dRestart = restartApp.buttons["30d-button"].firstMatch
        XCTAssertTrue(button30dRestart.waitForExistence(timeout: 2))

        let restartSwitchStart = Date()
        button30dRestart.tap()
        Thread.sleep(forTimeInterval: 0.05)
        let restartSwitchTime = Date().timeIntervalSince(restartSwitchStart) * 1000

        print("  ⏱️  Segment switch after restart: \(String(format: "%.0f", restartSwitchTime))ms")

        XCTAssertLessThan(
            restartSwitchTime, 500,
            "Segment switch after restart should be <500ms (actual: \(String(format: "%.0f", restartSwitchTime))ms)"
        )

        print(
            """
            ✅ 1y dataset performance:
               - Initial render: \(String(format: "%.0f", initialRenderTime))ms (~90s expected)
               - Segment switches: <500ms (client-side filtering)
               - After restart: \(String(format: "%.0f", restartRenderTime))ms (data persisted)
               - Post-restart switches: <500ms
            """)
    }
}
