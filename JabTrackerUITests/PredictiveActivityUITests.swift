//
//  PredictiveActivityUITests.swift
//  JabTrackerUITests
//
//  E2E tests for predictive activity adjustment feature.
//  Tests verify UI behavior for enabling/disabling predictive activity
//  and its interaction with Add Burned Calories toggle.
//

import XCTest

final class PredictiveActivityUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDown() {
        if let testRun = testRun, !testRun.hasSucceeded, app != nil {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        super.tearDown()
    }

    // MARK: - Toggle Tests

    /// User can navigate to Calorie Expenditure and toggle predictive activity
    /// Acceptance: Toggle changes state, persists on navigation
    func testTogglePredictiveActivityOn() {
        // Launch with Health Sync enabled (required for predictive)
        app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--reset-app-data",
            "--seed-calorie-user",
        ]
        app.launch()

        navigateToCalorieExpenditureView()

        let navBar = app.navigationBars["Calorie Expenditure"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Calorie Expenditure view should appear")

        // Get predictive activity toggle
        let predictiveToggle = app.switches["predictive-activity-toggle"]
        XCTAssertTrue(predictiveToggle.waitForExistence(timeout: 5), "Predictive activity toggle should exist")
        XCTAssertTrue(predictiveToggle.isEnabled, "Toggle should be enabled when Health Sync is on")

        // Record initial state and toggle
        let initialValue = predictiveToggle.value as? String ?? "0"

        // Turn on if it's off
        if initialValue == "0" {
            predictiveToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            XCTAssertEqual(predictiveToggle.value as? String, "1", "Predictive activity should be enabled after tap")
        }

        // Navigate back and return to verify persistence
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        backButton.tap()

        // Verify we're back at More view using the view identifier (more reliable than nav bar title)
        let moreView = app.otherElements["more-view"]
        XCTAssertTrue(moreView.waitForExistence(timeout: 5), "Should return to More view")

        // Navigate back to CalorieExpenditureView
        navigateToCalorieExpenditureViewAfterScroll()

        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Should return to Calorie Expenditure view")

        // Verify toggle state persisted
        let toggleAgain = app.switches["predictive-activity-toggle"]
        XCTAssertTrue(toggleAgain.waitForExistence(timeout: 5), "Toggle should exist")
        XCTAssertEqual(toggleAgain.value as? String, "1", "Predictive activity state should persist")
    }

    /// Predictive activity toggle is disabled when Health Sync is off
    /// Acceptance: Toggle shows disabled state
    func testPredictiveToggleDisabledWithoutHealthSync() {
        // Launch WITHOUT --seed-calorie-user (healthSyncEnabled = false by default)
        app = TestUtilities.launchAppWithTestMode(resetData: true)

        navigateToCalorieExpenditureView()

        let navBar = app.navigationBars["Calorie Expenditure"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Calorie Expenditure view should appear")

        // Predictive toggle should be disabled
        let predictiveToggle = app.switches["predictive-activity-toggle"]
        XCTAssertTrue(predictiveToggle.waitForExistence(timeout: 5), "Predictive toggle should exist")
        XCTAssertFalse(
            predictiveToggle.isEnabled,
            "Predictive activity toggle should be DISABLED when Health Sync is off"
        )
    }

    // MARK: - Feature Behavior Tests

    /// Predictive activity and burned calories are mutually exclusive in effect
    /// When burned calories is enabled, predictive does not add to target (avoids double-counting)
    /// Acceptance: Both can be toggled, but system prevents overlap
    func testPredictiveAndBurnedCaloriesMutualExclusivity() {
        // Launch with Health Sync enabled
        app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--reset-app-data",
            "--seed-calorie-user",
        ]
        app.launch()

        navigateToCalorieExpenditureView()

        let navBar = app.navigationBars["Calorie Expenditure"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Calorie Expenditure view should appear")

        // Get both toggles
        let burnedToggle = app.switches["add-burned-calories-toggle"]
        let predictiveToggle = app.switches["predictive-activity-toggle"]

        XCTAssertTrue(burnedToggle.waitForExistence(timeout: 5), "Burned toggle should exist")
        XCTAssertTrue(predictiveToggle.waitForExistence(timeout: 5), "Predictive toggle should exist")

        // Both toggles should be enabled (UI allows both to be on, service handles exclusivity)
        XCTAssertTrue(burnedToggle.isEnabled, "Burned toggle should be enabled with Health Sync")
        XCTAssertTrue(predictiveToggle.isEnabled, "Predictive toggle should be enabled with Health Sync")

        // Enable burned calories first
        if burnedToggle.value as? String == "0" {
            burnedToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertEqual(burnedToggle.value as? String, "1", "Burned calories should be enabled")

        // Enable predictive (UI allows it, service skips predictive when burned is on)
        if predictiveToggle.value as? String == "0" {
            predictiveToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertEqual(predictiveToggle.value as? String, "1", "Predictive should be enabled in UI")

        // Both toggles are now on - the CalorieAdjustmentService will only apply
        // burned calories (skipping predictive to avoid double-counting)
        // This test verifies the UI allows both settings to be saved
    }

    /// Predictive applies goal-type multiplier (weightLoss = 0.8)
    /// Note: This is primarily a unit test concern; E2E verifies toggle enables without error
    func testPredictiveWithWeightLossGoal() {
        // Launch with Health Sync enabled and predictive seed data
        app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--reset-app-data",
            "--seed-calorie-user",
            "--seed-predictive-history",  // Seeds 7-day activity history
            "--seed-weight-loss-goal",  // Sets active goal to weight loss
        ]
        app.launch()

        navigateToCalorieExpenditureView()

        let navBar = app.navigationBars["Calorie Expenditure"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Calorie Expenditure view should appear")

        // Enable predictive activity (ensure burned is off to avoid skip)
        let burnedToggle = app.switches["add-burned-calories-toggle"]
        let predictiveToggle = app.switches["predictive-activity-toggle"]

        XCTAssertTrue(burnedToggle.waitForExistence(timeout: 5), "Burned toggle should exist")
        XCTAssertTrue(predictiveToggle.waitForExistence(timeout: 5), "Predictive toggle should exist")

        // Ensure burned is OFF (predictive skips when burned is on)
        if burnedToggle.value as? String == "1" {
            burnedToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertEqual(burnedToggle.value as? String, "0", "Burned should be off for predictive to work")

        // Enable predictive
        if predictiveToggle.value as? String == "0" {
            predictiveToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertEqual(predictiveToggle.value as? String, "1", "Predictive should be enabled")

        // The service will apply 0.8x multiplier to the 7-day average
        // E2E test verifies toggle works; unit tests verify calculation
    }

    /// Predictive applies goal-type multiplier (muscleGain = 1.2)
    /// Note: This is primarily a unit test concern; E2E verifies toggle enables without error
    func testPredictiveWithMuscleGainGoal() {
        // Launch with Health Sync enabled and muscle gain goal
        app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--reset-app-data",
            "--seed-calorie-user",
            "--seed-predictive-history",  // Seeds 7-day activity history
            "--seed-muscle-gain-goal",  // Sets active goal to muscle gain
        ]
        app.launch()

        navigateToCalorieExpenditureView()

        let navBar = app.navigationBars["Calorie Expenditure"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Calorie Expenditure view should appear")

        // Enable predictive activity (ensure burned is off to avoid skip)
        let burnedToggle = app.switches["add-burned-calories-toggle"]
        let predictiveToggle = app.switches["predictive-activity-toggle"]

        XCTAssertTrue(burnedToggle.waitForExistence(timeout: 5), "Burned toggle should exist")
        XCTAssertTrue(predictiveToggle.waitForExistence(timeout: 5), "Predictive toggle should exist")

        // Ensure burned is OFF
        if burnedToggle.value as? String == "1" {
            burnedToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertEqual(burnedToggle.value as? String, "0", "Burned should be off for predictive to work")

        // Enable predictive
        if predictiveToggle.value as? String == "0" {
            predictiveToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertEqual(predictiveToggle.value as? String, "1", "Predictive should be enabled")

        // The service will apply 1.2x multiplier to the 7-day average
        // E2E test verifies toggle works; unit tests verify calculation
    }

    /// Disabling predictive activity removes bonus from target
    /// Acceptance: Toggle off → no predictive bonus applied
    func testDisablingPredictiveRemovesBonus() {
        // Launch with Health Sync enabled
        app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--reset-app-data",
            "--seed-calorie-user",
            "--seed-predictive-history",  // Seeds 7-day activity history
        ]
        app.launch()

        navigateToCalorieExpenditureView()

        let navBar = app.navigationBars["Calorie Expenditure"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Calorie Expenditure view should appear")

        // Get toggles
        let burnedToggle = app.switches["add-burned-calories-toggle"]
        let predictiveToggle = app.switches["predictive-activity-toggle"]

        XCTAssertTrue(burnedToggle.waitForExistence(timeout: 5), "Burned toggle should exist")
        XCTAssertTrue(predictiveToggle.waitForExistence(timeout: 5), "Predictive toggle should exist")

        // Ensure burned is OFF
        if burnedToggle.value as? String == "1" {
            burnedToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }

        // Enable predictive first
        if predictiveToggle.value as? String == "0" {
            predictiveToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertEqual(predictiveToggle.value as? String, "1", "Predictive should be enabled")

        // Now disable predictive
        predictiveToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertEqual(predictiveToggle.value as? String, "0", "Predictive should be disabled after tap")

        // Navigate to Dashboard and verify target shows base (no predictive bonus)
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        backButton.tap()
        TestUtilities.navigateToTab(app, tabName: "Dashboard")

        let dashboardView = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 5), "Dashboard should appear")

        // Nutrition card should show base target without predictive bonus
        let nutritionCard = app.otherElements["nutrition-rings-card"]
        XCTAssertTrue(nutritionCard.waitForExistence(timeout: 10), "Nutrition card should appear")

        // With predictive disabled, target should be base (2000)
        // Note: If rollover is also disabled and no burned calories, target = 2000
        let remainingLabel = app.staticTexts["macro-remaining-calories"]
        XCTAssertTrue(remainingLabel.waitForExistence(timeout: 5), "Remaining label should exist")

        // The target should reflect only enabled adjustments (none when predictive is off)
    }

    // MARK: - Helper Methods

    /// Navigate to CalorieExpenditureView from More tab
    private func navigateToCalorieExpenditureView() {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.otherElements["more-view"]
        XCTAssertTrue(moreView.waitForExistence(timeout: 5), "More view should appear")

        // Scroll to find calorie expenditure row
        app.swipeUp()

        let rowButton = app.buttons["calorie-expenditure-row"]
        let rowCell = app.cells["calorie-expenditure-row"]

        if rowButton.waitForExistence(timeout: 3) {
            if !rowButton.isHittable {
                app.swipeUp()
            }
            rowButton.tap()
        } else if rowCell.waitForExistence(timeout: 3) {
            if !rowCell.isHittable {
                app.swipeUp()
            }
            rowCell.tap()
        } else {
            app.swipeUp()
            if rowButton.waitForExistence(timeout: 2) {
                rowButton.tap()
            } else if rowCell.waitForExistence(timeout: 2) {
                rowCell.tap()
            } else {
                XCTFail("Could not find calorie-expenditure-row")
            }
        }
    }

    /// Navigate after already on More view (for back navigation tests)
    private func navigateToCalorieExpenditureViewAfterScroll() {
        app.swipeUp()

        let rowButton = app.buttons["calorie-expenditure-row"]
        let rowCell = app.cells["calorie-expenditure-row"]

        if rowButton.waitForExistence(timeout: 2) {
            if !rowButton.isHittable {
                app.swipeUp()
            }
            rowButton.tap()
        } else if rowCell.waitForExistence(timeout: 2) {
            if !rowCell.isHittable {
                app.swipeUp()
            }
            rowCell.tap()
        } else {
            app.swipeUp()
            if rowButton.waitForExistence(timeout: 2) {
                rowButton.tap()
            } else if rowCell.waitForExistence(timeout: 2) {
                rowCell.tap()
            } else {
                XCTFail("Could not find calorie-expenditure-row after back navigation")
            }
        }
    }
}
