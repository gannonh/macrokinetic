//
//  DashboardDetailViewsSmokeTest.swift
//  JabTrackerUITests
//
//  Quick smoketest to verify detail views (WeightTrendDetailView, ExpenditureDetailView,
//  EnergyBalanceDetailView) work correctly with their new ViewModels.
//  Part of v0.7.0 Dashboard Widget UX milestone (Phase 34).
//

import XCTest

final class DashboardDetailViewsSmokeTest: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Launch with 7-day seeded test data
        app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "true"
        app.launchEnvironment["TEST_DATA_SEED"] = "true"
        app.launchEnvironment["TEST_DATA_DAYS"] = "7"
        app.launchArguments = ["--ui-testing", "--reset-app-data", "--bypass-onboarding", "--seed-test-7d"]
        app.launch()

        // Wait for app to stabilize
        Thread.sleep(forTimeInterval: 2.0)
    }

    override func tearDownWithError() throws {
        // Capture failure screenshot if test failed
        if let testRun = testRun, testRun.hasSucceeded == false {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        app = nil
    }

    // MARK: - Weight Trend Widget -> Detail View

    func testWeightTrendWidgetNavigatesToDetailView() throws {
        // Navigate to Dashboard tab (should already be there by default)
        let dashboardView = app.scrollViews["dashboard-scroll-view"]
        XCTAssertTrue(
            dashboardView.waitForExistence(timeout: 5),
            "Dashboard scroll view should exist"
        )

        // Find and tap the Weight Trend widget
        let weightTrendWidget = app.otherElements["weight-trend-widget"]
        if !weightTrendWidget.waitForExistence(timeout: 3) {
            // Try scrolling down to find it
            dashboardView.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertTrue(
            weightTrendWidget.waitForExistence(timeout: 5),
            "Weight Trend widget should exist"
        )
        weightTrendWidget.tap()

        // Verify detail view appears by checking navigation title and Done button
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(
            doneButton.waitForExistence(timeout: 5),
            "Weight Trend detail view should appear (Done button visible)"
        )

        // Verify navigation title shows "Weight Trend"
        let navTitle = app.navigationBars["Weight Trend"]
        XCTAssertTrue(
            navTitle.waitForExistence(timeout: 3),
            "Weight Trend navigation title should be visible"
        )

        // Dismiss the detail view
        doneButton.tap()

        // Verify we're back on dashboard
        XCTAssertTrue(
            dashboardView.waitForExistence(timeout: 3),
            "Should return to dashboard after dismissing detail view"
        )
    }

    // MARK: - Expenditure Widget -> Detail View

    func testExpenditureWidgetNavigatesToDetailView() throws {
        // Navigate to Dashboard tab
        let dashboardView = app.scrollViews["dashboard-scroll-view"]
        XCTAssertTrue(
            dashboardView.waitForExistence(timeout: 5),
            "Dashboard scroll view should exist"
        )

        // Find and tap the Expenditure widget
        let expenditureWidget = app.otherElements["expenditure-widget"]
        if !expenditureWidget.waitForExistence(timeout: 3) {
            // Try scrolling down to find it
            dashboardView.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertTrue(
            expenditureWidget.waitForExistence(timeout: 5),
            "Expenditure widget should exist"
        )
        expenditureWidget.tap()

        // Verify detail view appears by checking navigation title and Done button
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(
            doneButton.waitForExistence(timeout: 5),
            "Expenditure detail view should appear (Done button visible)"
        )

        // Verify navigation title shows "Expenditure"
        let navTitle = app.navigationBars["Expenditure"]
        XCTAssertTrue(
            navTitle.waitForExistence(timeout: 3),
            "Expenditure navigation title should be visible"
        )

        // Dismiss the detail view
        doneButton.tap()

        // Verify we're back on dashboard
        XCTAssertTrue(
            dashboardView.waitForExistence(timeout: 3),
            "Should return to dashboard after dismissing detail view"
        )
    }

    // MARK: - Energy Balance Widget -> Detail View

    func testEnergyBalanceWidgetNavigatesToDetailView() throws {
        // Navigate to Dashboard tab
        let dashboardView = app.scrollViews["dashboard-scroll-view"]
        XCTAssertTrue(
            dashboardView.waitForExistence(timeout: 5),
            "Dashboard scroll view should exist"
        )

        // Find and tap the Energy Balance widget
        let energyBalanceWidget = app.otherElements["energy-balance-widget"]
        if !energyBalanceWidget.waitForExistence(timeout: 3) {
            // Try scrolling down to find it
            dashboardView.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertTrue(
            energyBalanceWidget.waitForExistence(timeout: 5),
            "Energy Balance widget should exist"
        )
        energyBalanceWidget.tap()

        // Verify detail view appears by checking navigation title and Done button
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(
            doneButton.waitForExistence(timeout: 5),
            "Energy Balance detail view should appear (Done button visible)"
        )

        // Verify navigation title shows "Energy Balance"
        let navTitle = app.navigationBars["Energy Balance"]
        XCTAssertTrue(
            navTitle.waitForExistence(timeout: 3),
            "Energy Balance navigation title should be visible"
        )

        // Dismiss the detail view
        doneButton.tap()

        // Verify we're back on dashboard
        XCTAssertTrue(
            dashboardView.waitForExistence(timeout: 3),
            "Should return to dashboard after dismissing detail view"
        )
    }
}
