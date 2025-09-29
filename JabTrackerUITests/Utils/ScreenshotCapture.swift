import XCTest

/// Utility for capturing systematic screenshots during UI testing
/// Used for documenting current state and tracking improvements
class ScreenshotCapture {

    private let app: XCUIApplication
    private let testCase: XCTestCase
    private let baseDirectory: String

    init(app: XCUIApplication, testCase: XCTestCase, phase: String = "baseline") {
        self.app = app
        self.testCase = testCase
        self.baseDirectory = "analytics-\(phase)"
    }

    /// Capture a screenshot with organized naming and metadata
    func capture(
        section: String,
        description: String,
        metadata: [String: String] = [:]
    ) {
        let timestamp = DateFormatter.screenshotTimestamp.string(from: Date())
        let filename = "\(section)-\(description)-\(timestamp)"

        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)

        // Create descriptive name for test results
        attachment.name = "\(baseDirectory)/\(filename)"
        attachment.lifetime = .keepAlways

        // Add metadata as attachment description
        var metadataString = "Section: \(section)\nDescription: \(description)\n"
        for (key, value) in metadata {
            metadataString += "\(key): \(value)\n"
        }

        // Add performance measurements if available
        if let loadTime = measureElementLoadTime() {
            metadataString += "Load Time: \(loadTime)ms\n"
        }

        attachment.userInfo = ["metadata": metadataString]
        testCase.add(attachment)

        print("📸 Screenshot captured: \(filename)")
        print("   Metadata: \(metadataString)")
    }

    /// Capture full analytics flow with all sections
    func captureAnalyticsFlow() throws {
        // Navigate to analytics tab
        TestUtilities.navigateToAnalyticsTab(app: app)

        // Wait for initial load
        let analyticsView = app.scrollViews["analytics-scroll-view"]
        XCTAssertTrue(analyticsView.waitForExistence(timeout: 10), "Analytics view should be visible")

        // Capture initial state
        capture(
            section: "analytics-initial",
            description: "default-load",
            metadata: [
                "section": "concentration",
                "state": "loaded",
            ]
        )

        // Capture concentration section
        let concentrationPicker = app.segmentedControls["analytics-type-picker"]
        if concentrationPicker.exists {
            concentrationPicker.buttons["Concentration"].tap()
            sleep(1)  // Allow transition

            capture(
                section: "concentration",
                description: "chart-view",
                metadata: [
                    "chart_type": "concentration_timeline",
                    "transition": "complete",
                ]
            )
        }

        // Capture adherence section
        if concentrationPicker.exists {
            concentrationPicker.buttons["Adherence"].tap()
            sleep(1)  // Allow transition

            capture(
                section: "adherence",
                description: "insights-view",
                metadata: [
                    "section": "adherence_insights",
                    "transition": "complete",
                ]
            )
        }

        // Capture segmented control interaction
        capture(
            section: "navigation",
            description: "segmented-control",
            metadata: [
                "control_type": "segmented_picker",
                "selected": "adherence",
            ]
        )

        // Test empty state (if possible)
        // Note: Would require test data setup to show empty state
    }

    /// Measure element load time for performance baseline
    private func measureElementLoadTime() -> Int? {
        // Simple load time measurement
        // In a real implementation, this would measure specific elements
        // For now, return nil as we'd need to implement proper timing
        nil
    }

    /// Capture performance metrics for baseline
    func capturePerformanceBaseline() -> [String: Any] {
        var metrics: [String: Any] = [:]

        // Measure app launch time
        let launchStart = Date()
        TestUtilities.launchAppWithTestMode()
        let launchEnd = Date()
        metrics["app_launch_time"] = launchEnd.timeIntervalSince(launchStart) * 1000  // ms

        // Measure analytics tab load time
        let tabLoadStart = Date()
        TestUtilities.navigateToAnalyticsTab(app: app)

        let analyticsView = app.scrollViews["analytics-scroll-view"]
        _ = analyticsView.waitForExistence(timeout: 10)
        let tabLoadEnd = Date()
        metrics["analytics_load_time"] = tabLoadEnd.timeIntervalSince(tabLoadStart) * 1000  // ms

        // Measure section transition time
        let transitionStart = Date()
        let picker = app.segmentedControls["analytics-type-picker"]
        if picker.exists {
            picker.buttons["Adherence"].tap()
            sleep(1)  // Wait for transition
        }
        let transitionEnd = Date()
        metrics["section_transition_time"] = transitionEnd.timeIntervalSince(transitionStart) * 1000  // ms

        return metrics
    }
}

// MARK: - Utilities

extension DateFormatter {
    static let screenshotTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}

extension TestUtilities {
    /// Navigate to analytics tab with error handling
    static func navigateToAnalyticsTab(app: XCUIApplication) {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should be visible")

        let analyticsTab = tabBar.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.exists, "Analytics tab should exist")
        analyticsTab.tap()

        // Wait for navigation to complete
        sleep(2)
    }
}
