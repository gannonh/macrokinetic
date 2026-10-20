import XCTest

/// Adherence metrics through More > GLP-1 Programs > Analytics > Adherence.
/// Three weekly Ozempic doses at 100% adherence give literal, deterministic values.
final class AdherenceMetricsDisplayUITests: XCTestCase {
    private let ratingLabel = "Adherence rate: 100%, Excellent adherence"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchAdherence() -> XCUIApplication {
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 3)
        TestUtilities.navigateToAdherence(app)
        return app
    }

    func testAdherenceInsightsViewDisplay() throws {
        let app = launchAdherence()
        let rating = TestUtilities.requireLabeled(app, ratingLabel, value: "100%")
        XCTAssertTrue(rating.isHittable)
        TestUtilities.requireLabeled(app, "Adherence Rate")
        TestUtilities.requireLabeled(app, "Excellent")
        TestUtilities.requireLabeled(app, "Current streak: 1 day")
        TestUtilities.requireLabeled(app, "Best streak: 1 day")
    }

    func testAdherenceMetricsUpdate() throws {
        let app = launchAdherence()
        TestUtilities.requireLabeled(app, ratingLabel, value: "100%")

        TestUtilities.navigateToTab(app, tabName: "Dashboard")
        TestUtilities.navigateToAdherence(app)

        TestUtilities.requireLabeled(app, ratingLabel, value: "100%")
        TestUtilities.requireLabeled(app, "Current streak: 1 day")
        TestUtilities.requireLabeled(app, "Best streak: 1 day")
    }

    func testStreakCountersDisplay() throws {
        let app = launchAdherence()
        TestUtilities.requireLabeled(app, "Dose Streaks")
        let current = TestUtilities.requireLabeled(app, "Current streak: 1 day")
        let best = TestUtilities.requireLabeled(app, "Best streak: 1 day")
        XCTAssertEqual(current.staticTexts["Current Streak"].label, "Current Streak")
        XCTAssertEqual(best.staticTexts["Best Streak"].label, "Best Streak")
        XCTAssertEqual(current.staticTexts["1 day"].label, "1 day")
        XCTAssertEqual(best.staticTexts["1 day"].label, "1 day")
    }

    func testAdherenceColorCoding() throws {
        let app = launchAdherence()
        // Quality is conveyed by text as well as color: the rating word and the spoken label.
        let rating = TestUtilities.requireLabeled(app, ratingLabel, value: "100%")
        XCTAssertEqual(rating.staticTexts["Excellent"].label, "Excellent")
        XCTAssertEqual(rating.staticTexts["100%"].label, "100%")
        TestUtilities.requireLabeled(app, "Goal achieved!")
    }

    func testVoiceOverAccessibility() throws {
        let app = launchAdherence()
        let rating = TestUtilities.requireLabeled(app, ratingLabel, value: "100%")
        XCTAssertTrue(rating.isHittable)
        TestUtilities.requireLabeled(app, "Current streak: 1 day")
        TestUtilities.requireLabeled(app, "Best streak: 1 day")
        TestUtilities.requireLabeled(
            app, "Adherence trend chart showing stable pattern", value: "Current trend: Stable")
        let picker = app.segmentedControls["analytics-section-picker"]
        XCTAssertTrue(picker.exists)
        XCTAssertTrue(picker.isHittable)
        XCTAssertTrue(picker.buttons["Adherence"].isSelected)
    }
}
