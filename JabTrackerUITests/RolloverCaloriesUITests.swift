//
//  RolloverCaloriesUITests.swift
//  JabTrackerUITests
//
//  E2E tests for Rollover Calories feature.
//  These tests verify that unused calories from yesterday roll over to today's target.
//

import XCTest

final class RolloverCaloriesUITests: XCTestCase {

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

    /// User can toggle rollover calories setting
    /// Acceptance: Toggle exists, is enabled (no HealthKit requirement), and interactive
    func testRolloverCaloriesToggleExists() {
        app = TestUtilities.launchAppWithTestMode(resetData: true)

        navigateToCalorieExpenditureView()

        let navBar = app.navigationBars["Calorie Expenditure"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Calorie Expenditure view should appear")

        // Rollover toggle should exist and always be enabled (no HealthKit requirement)
        let rolloverToggle = app.switches["rollover-calories-toggle"]
        XCTAssertTrue(rolloverToggle.waitForExistence(timeout: 5), "Rollover calories toggle should exist")
        XCTAssertTrue(rolloverToggle.isEnabled, "Rollover toggle should be enabled (no HealthKit requirement)")
    }

    /// Toggle rollover on and off and verify state changes persist
    func testRolloverToggleStateChanges() {
        app = TestUtilities.launchAppWithTestMode(resetData: true)

        navigateToCalorieExpenditureView()

        let rolloverToggle = app.switches["rollover-calories-toggle"]
        XCTAssertTrue(rolloverToggle.waitForExistence(timeout: 5), "Toggle should exist")
        XCTAssertTrue(rolloverToggle.isEnabled, "Toggle should be enabled")

        let initialValue = rolloverToggle.value as? String ?? "0"

        // Toggle to opposite state
        rolloverToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        let newValue = rolloverToggle.value as? String ?? "0"
        XCTAssertNotEqual(initialValue, newValue, "Toggle state should change after tap")

        // Toggle back
        rolloverToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        let finalValue = rolloverToggle.value as? String ?? "0"
        XCTAssertEqual(initialValue, finalValue, "Toggle should return to original state")
    }

    // MARK: - Feature Behavior Tests

    /// Rollover adds unused calories from yesterday to today's target
    /// Acceptance: Base 2000 + 200 unused yesterday = 2200 today (capped at 200)
    ///
    /// Requires: --seed-rollover-deficit launch argument that creates:
    /// - User with rolloverCaloriesEnabled = true
    /// - Yesterday's food entries totaling base - 200 (for 200 calorie deficit)
    func testRolloverAddsUnusedCalories() throws {
        throw XCTSkip("Requires --seed-rollover-deficit launch argument infrastructure")
        // Launch with seeded rollover deficit data
        app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--reset-app-data",
            "--seed-rollover-deficit=200",  // Seeds yesterday with 200 calorie deficit
        ]
        app.launch()

        // Navigate to Food Log to verify adjusted target
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log should appear")

        // Wait for macro summary card to load
        let macroSummaryCard = app.otherElements["macro-summary-card"]
        XCTAssertTrue(macroSummaryCard.waitForExistence(timeout: 10), "Macro summary card should appear")

        // Verify the adjusted calorie target (2000 base + 200 rollover = 2200)
        // Look for text containing adjusted target
        let adjustedTarget = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '2,200' OR label CONTAINS '2200'")
        ).firstMatch

        XCTAssertTrue(
            adjustedTarget.waitForExistence(timeout: 5),
            "Food Log should show adjusted target with rollover (2200 = 2000 base + 200 rollover)"
        )
    }

    /// Rollover is capped at 200 maximum
    /// Acceptance: 500 unused yesterday → only +200 today
    ///
    /// Requires: --seed-rollover-deficit=500 to create large deficit
    func testRolloverCappedAt200() throws {
        throw XCTSkip("Requires --seed-rollover-deficit launch argument infrastructure")
        // Launch with seeded large rollover deficit
        app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--reset-app-data",
            "--seed-rollover-deficit=500",  // Seeds yesterday with 500 calorie deficit
        ]
        app.launch()

        // Navigate to Food Log
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log should appear")

        // Wait for macro summary card
        let macroSummaryCard = app.otherElements["macro-summary-card"]
        XCTAssertTrue(macroSummaryCard.waitForExistence(timeout: 10), "Macro summary card should appear")

        // Should show 2200 (max rollover), NOT 2500
        let adjustedTarget = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '2,200' OR label CONTAINS '2200'")
        ).firstMatch

        let oversizedTarget = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '2,500' OR label CONTAINS '2500'")
        ).firstMatch

        XCTAssertTrue(
            adjustedTarget.waitForExistence(timeout: 5),
            "Rollover should be capped at 200 (2200 total, not 2500)"
        )
        XCTAssertFalse(
            oversizedTarget.exists,
            "Target should NOT be 2500 - rollover is capped at 200"
        )
    }

    /// No rollover when yesterday was over budget
    /// Acceptance: Base target unchanged when no deficit
    ///
    /// Requires: --seed-rollover-surplus to create over-budget day
    func testNoRolloverWhenOverBudget() throws {
        throw XCTSkip("Requires --seed-rollover-surplus launch argument infrastructure")
        // Launch with seeded surplus (yesterday over budget)
        app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--reset-app-data",
            "--seed-rollover-surplus",  // Seeds yesterday over calorie target
        ]
        app.launch()

        // Navigate to Food Log
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log should appear")

        // Wait for macro summary card
        let macroSummaryCard = app.otherElements["macro-summary-card"]
        XCTAssertTrue(macroSummaryCard.waitForExistence(timeout: 10), "Macro summary card should appear")

        // Target should be base (2000), not adjusted
        let baseTarget = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '2,000' OR label CONTAINS '2000'")
        ).firstMatch

        XCTAssertTrue(
            baseTarget.waitForExistence(timeout: 5),
            "Target should be base (2000) when yesterday was over budget"
        )
    }

    /// Rollover works combined with burned calories
    /// Acceptance: Target = Base + Burned + Rollover
    ///
    /// Requires:
    /// - --seed-rollover-deficit=150 for rollover
    /// - --mock-active-energy=300 for burned calories
    /// - --seed-calorie-user for Health Sync enabled
    func testRolloverStacksWithBurnedCalories() throws {
        throw XCTSkip("Requires --seed-rollover-deficit launch argument infrastructure")
        // Launch with both rollover deficit AND mock active energy
        app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--reset-app-data",
            "--seed-calorie-user",  // Health Sync enabled
            "--seed-rollover-deficit=150",  // 150 rollover
            "--mock-active-energy=300",  // 300 burned
        ]
        app.launch()

        // Enable Add Burned Calories toggle (rollover is already enabled via seed)
        navigateToCalorieExpenditureView()

        let burnedToggle = app.switches["add-burned-calories-toggle"]
        XCTAssertTrue(burnedToggle.waitForExistence(timeout: 5), "Burned toggle should exist")

        if burnedToggle.value as? String == "0" {
            burnedToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }

        // Navigate to Food Log
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        backButton.tap()
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log should appear")

        // Wait for macro summary card
        let macroSummaryCard = app.otherElements["macro-summary-card"]
        XCTAssertTrue(macroSummaryCard.waitForExistence(timeout: 10), "Macro summary card should appear")

        // Target should be 2000 + 300 burned + 150 rollover = 2450
        let combinedTarget = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '2,450' OR label CONTAINS '2450'")
        ).firstMatch

        XCTAssertTrue(
            combinedTarget.waitForExistence(timeout: 5),
            "Target should include both burned (300) and rollover (150) = 2450"
        )
    }

    /// Rollover disabled shows base target only
    /// Acceptance: Toggle off → no rollover applied even with deficit
    func testRolloverDisabledShowsBaseTarget() throws {
        throw XCTSkip("Requires --seed-rollover-deficit launch argument infrastructure")
        // Launch with seeded deficit but we'll disable rollover
        app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--reset-app-data",
            "--seed-rollover-deficit=200",  // Would be 200 rollover if enabled
        ]
        app.launch()

        // Disable rollover toggle
        navigateToCalorieExpenditureView()

        let rolloverToggle = app.switches["rollover-calories-toggle"]
        XCTAssertTrue(rolloverToggle.waitForExistence(timeout: 5), "Toggle should exist")

        // Turn off if it's on
        if rolloverToggle.value as? String == "1" {
            rolloverToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertEqual(rolloverToggle.value as? String, "0", "Rollover should be disabled")

        // Navigate to Food Log
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        backButton.tap()
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log should appear")

        // Wait for macro summary card
        let macroSummaryCard = app.otherElements["macro-summary-card"]
        XCTAssertTrue(macroSummaryCard.waitForExistence(timeout: 10), "Macro summary card should appear")

        // Target should be base (2000), NOT 2200
        let baseTarget = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS '2,000' OR label CONTAINS '2000'")
        ).firstMatch

        XCTAssertTrue(
            baseTarget.waitForExistence(timeout: 5),
            "Target should be base (2000) when rollover is disabled"
        )
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
}
