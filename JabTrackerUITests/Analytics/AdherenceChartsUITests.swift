import XCTest

/// Adherence chart components through More > GLP-1 Programs > Analytics > Adherence.
/// Three weekly Ozempic doses at 100% adherence give literal, deterministic values.
final class AdherenceChartsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchAnalytics() -> XCUIApplication {
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 3)
        TestUtilities.navigateToGLP1Analytics(app)
        return app
    }

    func testAdherenceChartComponents() throws {
        let app = launchAnalytics()
        let picker = app.segmentedControls["analytics-section-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertEqual(picker.buttons.allElementsBoundByIndex.map(\.label), ["Adherence", "History"])
        picker.buttons["Adherence"].tap()
        XCTAssertTrue(picker.buttons["Adherence"].isSelected)

        TestUtilities.requireLabeled(app, "Adherence rate: 100%, Excellent adherence", value: "100%")
        TestUtilities.requireLabeled(app, "Current streak: 1 day")
        TestUtilities.requireLabeled(app, "Best streak: 1 day")
        TestUtilities.requireLabeled(app, "Adherence Goal")
        TestUtilities.requireLabeled(
            app, "Adherence trend chart showing stable pattern", value: "Current trend: Stable")
        TestUtilities.requireLabeled(app, "Missed dose pattern analysis", value: "Total missed doses: 0")
    }

    func testAdherenceTrendChartDisplay() throws {
        let app = launchAnalytics()
        app.segmentedControls["analytics-section-picker"].buttons["Adherence"].tap()
        let trend = TestUtilities.requireLabeled(
            app, "Adherence trend chart showing stable pattern", value: "Current trend: Stable")
        XCTAssertTrue(trend.exists)
        XCTAssertTrue(
            app.otherElements.matching(NSPredicate(format: "value == '0 to 0, 2 values'")).count > 0,
            "Trend chart should expose its plotted ranges")
    }

    func testMissedDosePatternView() throws {
        let app = launchAnalytics()
        app.segmentedControls["analytics-section-picker"].buttons["Adherence"].tap()
        TestUtilities.requireLabeled(app, "Missed dose pattern analysis", value: "Total missed doses: 0")
        TestUtilities.requireLabeled(app, "Adherence rate: 100%, Excellent adherence", value: "100%")
    }

    func testAdherenceProgressIndicator() throws {
        let app = launchAnalytics()
        app.segmentedControls["analytics-section-picker"].buttons["Adherence"].tap()
        for label in ["Adherence Goal", "This month", "Current", "Target", "80%", "Goal achieved!"] {
            TestUtilities.requireLabeled(app, label)
        }
        TestUtilities.requireLabeled(app, "100%")
        TestUtilities.requireLabeled(app, "Current streak: 1 day")
    }
}
