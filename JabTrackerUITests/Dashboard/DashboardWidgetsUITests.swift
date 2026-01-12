//
//  DashboardWidgetsUITests.swift
//  JabTrackerUITests
//
//  E2E tests for dashboard widgets covering hero carousel, standard widgets,
//  and detail view navigation with multiple data quality scenarios.
//

import XCTest

final class DashboardWidgetsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Hero Carousel Tests (High Quality Data)

    func testHeroCarouselSwipeNavigation() throws {
        // Launch with high quality data for complete visualization
        app = TestUtilities.launchAppWithSeededData(preset: .oneYearHighQuality)

        // Verify dashboard loads
        let dashboardView = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 10), "Dashboard should load")

        // Verify hero widget container exists
        let heroContainer = app.otherElements["hero-widget-container"]
        XCTAssertTrue(heroContainer.waitForExistence(timeout: 5), "Hero widget container should exist")

        // Verify first hero widget is visible (Weekly Nutrition)
        let weeklyWidget = app.otherElements["weekly-nutrition-hero-widget"]
        XCTAssertTrue(weeklyWidget.waitForExistence(timeout: 5), "Weekly nutrition widget should be visible initially")

        // Swipe left to navigate to second widget (Daily Nutrition)
        heroContainer.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)  // Allow animation to complete

        let dailyWidget = app.otherElements["daily-nutrition-hero-widget"]
        XCTAssertTrue(dailyWidget.waitForExistence(timeout: 3), "Daily nutrition widget should appear after swipe")

        // Swipe left to navigate to third widget (Energy Balance)
        heroContainer.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)

        let energyWidget = app.otherElements["energy-balance-hero-widget"]
        XCTAssertTrue(
            energyWidget.waitForExistence(timeout: 3), "Energy balance widget should appear after second swipe")

        // Swipe right to go back
        heroContainer.swipeRight()
        Thread.sleep(forTimeInterval: 0.5)

        XCTAssertTrue(dailyWidget.waitForExistence(timeout: 3), "Should navigate back to daily nutrition widget")
    }

    func testConsumedRemainingToggle() throws {
        app = TestUtilities.launchAppWithSeededData(preset: .oneYearHighQuality)

        let dashboardView = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 10), "Dashboard should load")

        // Find and tap the display toggle
        let displayToggle = app.buttons["hero-display-toggle"]
        XCTAssertTrue(displayToggle.waitForExistence(timeout: 5), "Display toggle should exist")

        // Capture initial state
        let initialToggleLabel = displayToggle.label

        // Tap to toggle
        displayToggle.tap()
        Thread.sleep(forTimeInterval: 0.3)

        // Verify toggle state changed
        let newToggleLabel = displayToggle.label
        XCTAssertNotEqual(initialToggleLabel, newToggleLabel, "Toggle label should change after tap")

        // Toggle back
        displayToggle.tap()
        Thread.sleep(forTimeInterval: 0.3)

        XCTAssertEqual(displayToggle.label, initialToggleLabel, "Toggle should return to original state")
    }

    func testEnergyDisplayToggle() throws {
        app = TestUtilities.launchAppWithSeededData(preset: .oneYearHighQuality)

        let dashboardView = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 10), "Dashboard should load")

        // Navigate to energy balance widget
        let heroContainer = app.otherElements["hero-widget-container"]
        XCTAssertTrue(heroContainer.waitForExistence(timeout: 5), "Hero container should exist")

        // Swipe twice to get to energy balance
        heroContainer.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)
        heroContainer.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)

        // Find energy display toggle
        let energyToggle = app.buttons["energy-display-toggle"]
        XCTAssertTrue(energyToggle.waitForExistence(timeout: 3), "Energy display toggle should exist")

        // Tap to toggle
        energyToggle.tap()
        Thread.sleep(forTimeInterval: 0.3)

        // Verify widget is still visible after toggle
        let energyWidget = app.otherElements["energy-balance-hero-widget"]
        XCTAssertTrue(energyWidget.exists, "Energy balance widget should remain visible after toggle")
    }

    // MARK: - Standard Widget Grid Tests

    func testStandardWidgetGroupVisibility() throws {
        app = TestUtilities.launchAppWithSeededData(preset: .oneYearHighQuality)

        let dashboardView = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 10), "Dashboard should load")

        // Scroll down to see standard widgets
        let scrollView = app.scrollViews["dashboard-scroll-view"]
        scrollView.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)

        // Verify standard widgets exist
        let weightWidget = app.otherElements["weight-trend-widget"]
        XCTAssertTrue(weightWidget.waitForExistence(timeout: 5), "Weight trend widget should exist")

        let expenditureWidget = app.otherElements["expenditure-widget"]
        XCTAssertTrue(expenditureWidget.waitForExistence(timeout: 3), "Expenditure widget should exist")

        let energyBalanceWidget = app.otherElements["energy-balance-widget"]
        XCTAssertTrue(energyBalanceWidget.waitForExistence(timeout: 3), "Energy balance widget should exist")

        let goalWidget = app.otherElements["goal-progress-widget"]
        XCTAssertTrue(goalWidget.waitForExistence(timeout: 3), "Goal progress widget should exist")
    }

    // MARK: - Detail View Navigation Tests

    func testWeightTrendDetailNavigation() throws {
        app = TestUtilities.launchAppWithSeededData(preset: .oneYearHighQuality)

        let dashboardView = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 10), "Dashboard should load")

        // Scroll to weight widget
        let scrollView = app.scrollViews["dashboard-scroll-view"]
        scrollView.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)

        // Tap weight trend widget
        let weightWidget = app.otherElements["weight-trend-widget"]
        XCTAssertTrue(weightWidget.waitForExistence(timeout: 5), "Weight trend widget should exist")
        weightWidget.tap()

        // Verify detail view appears
        let detailView = app.otherElements["weight-trend-detail-view"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 5), "Weight trend detail view should appear")

        // Verify time period selector exists
        let timePeriodSelector = app.otherElements["detail-time-period-selector"]
        XCTAssertTrue(timePeriodSelector.waitForExistence(timeout: 3), "Time period selector should exist")

        // Dismiss detail view
        dismissDetailView()
    }

    func testExpenditureDetailNavigation() throws {
        app = TestUtilities.launchAppWithSeededData(preset: .oneYearHighQuality)

        let dashboardView = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 10), "Dashboard should load")

        // Scroll to expenditure widget
        let scrollView = app.scrollViews["dashboard-scroll-view"]
        scrollView.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)

        // Tap expenditure widget
        let expenditureWidget = app.otherElements["expenditure-widget"]
        XCTAssertTrue(expenditureWidget.waitForExistence(timeout: 5), "Expenditure widget should exist")
        expenditureWidget.tap()

        // Verify detail view appears
        let detailView = app.otherElements["expenditure-detail-view"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 5), "Expenditure detail view should appear")

        // Dismiss detail view
        dismissDetailView()
    }

    func testEnergyBalanceDetailNavigation() throws {
        app = TestUtilities.launchAppWithSeededData(preset: .oneYearHighQuality)

        let dashboardView = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 10), "Dashboard should load")

        // Scroll to energy balance widget
        let scrollView = app.scrollViews["dashboard-scroll-view"]
        scrollView.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)

        // Tap energy balance widget
        let energyWidget = app.otherElements["energy-balance-widget"]
        XCTAssertTrue(energyWidget.waitForExistence(timeout: 5), "Energy balance widget should exist")
        energyWidget.tap()

        // Verify detail view appears
        let detailView = app.otherElements["energy-balance-detail-view"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 5), "Energy balance detail view should appear")

        // Dismiss detail view
        dismissDetailView()
    }

    func testTimePeriodSelectorInDetailView() throws {
        app = TestUtilities.launchAppWithSeededData(preset: .oneYearHighQuality)

        let dashboardView = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 10), "Dashboard should load")

        // Scroll and tap weight widget
        let scrollView = app.scrollViews["dashboard-scroll-view"]
        scrollView.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)

        let weightWidget = app.otherElements["weight-trend-widget"]
        XCTAssertTrue(weightWidget.waitForExistence(timeout: 5), "Weight widget should exist")
        weightWidget.tap()

        // Wait for detail view
        let detailView = app.otherElements["weight-trend-detail-view"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 5), "Detail view should appear")

        // Test time period buttons
        let weekButton = app.buttons["1w-period-button"]
        let monthButton = app.buttons["1m-period-button"]
        let threeMonthButton = app.buttons["3m-period-button"]
        let yearButton = app.buttons["1y-period-button"]

        // Verify buttons exist
        XCTAssertTrue(weekButton.waitForExistence(timeout: 3), "Week period button should exist")
        XCTAssertTrue(monthButton.exists, "Month period button should exist")
        XCTAssertTrue(threeMonthButton.exists, "3-month period button should exist")
        XCTAssertTrue(yearButton.exists, "Year period button should exist")

        // Test switching periods
        weekButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        monthButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        threeMonthButton.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Dismiss
        dismissDetailView()
    }

    // MARK: - Medium Quality Data Tests

    func testDashboardWithMediumQualityData() throws {
        app = TestUtilities.launchAppWithSeededData(preset: .oneYearMediumQuality)

        let dashboardView = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 10), "Dashboard should load with medium quality data")

        // Verify hero widget container still works with partial data
        let heroContainer = app.otherElements["hero-widget-container"]
        XCTAssertTrue(heroContainer.waitForExistence(timeout: 5), "Hero container should exist")

        // Verify weekly widget shows (may show partial data state)
        let weeklyWidget = app.otherElements["weekly-nutrition-hero-widget"]
        XCTAssertTrue(weeklyWidget.waitForExistence(timeout: 5), "Weekly widget should handle partial data")

        // Scroll to standard widgets
        let scrollView = app.scrollViews["dashboard-scroll-view"]
        scrollView.swipeUp()

        // Verify standard widgets handle sparse data gracefully
        let weightWidget = app.otherElements["weight-trend-widget"]
        XCTAssertTrue(weightWidget.waitForExistence(timeout: 5), "Weight widget should handle partial data")
    }

    // MARK: - Low Quality Data Tests

    func testDashboardWithLowQualityData() throws {
        app = TestUtilities.launchAppWithSeededData(preset: .oneYearLowQuality)

        let dashboardView = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 10), "Dashboard should load with low quality data")

        // Verify widgets handle sparse data
        let heroContainer = app.otherElements["hero-widget-container"]
        XCTAssertTrue(heroContainer.waitForExistence(timeout: 5), "Hero container should exist")

        // Navigate through hero widgets to verify they handle sparse data
        heroContainer.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)
        heroContainer.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)

        // Energy balance widget with sparse data
        let energyWidget = app.otherElements["energy-balance-hero-widget"]
        XCTAssertTrue(energyWidget.waitForExistence(timeout: 3), "Energy widget should handle sparse data")
    }

    // MARK: - New User Tests

    func testDashboardWithNewUser() throws {
        app = TestUtilities.launchAppWithSeededData(preset: .newUser)

        let dashboardView = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 10), "Dashboard should load for new user")

        // Verify hero widgets exist even with minimal data
        let heroContainer = app.otherElements["hero-widget-container"]
        XCTAssertTrue(heroContainer.waitForExistence(timeout: 5), "Hero container should exist for new user")

        // Scroll to standard widgets
        let scrollView = app.scrollViews["dashboard-scroll-view"]
        scrollView.swipeUp()

        // Standard widgets should still be visible (may show empty/onboarding state)
        let weightWidget = app.otherElements["weight-trend-widget"]
        XCTAssertTrue(weightWidget.waitForExistence(timeout: 5), "Weight widget should exist for new user")

        // Verify tapping still works (detail views should handle minimal data)
        weightWidget.tap()

        let detailView = app.otherElements["weight-trend-detail-view"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 5), "Detail view should open even with minimal data")

        dismissDetailView()
    }

    // MARK: - Detail View Dismiss Tests

    func testDetailViewDragToDismiss() throws {
        app = TestUtilities.launchAppWithSeededData(preset: .thirtyDays)

        let dashboardView = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 10), "Dashboard should load")

        // Scroll and tap widget
        let scrollView = app.scrollViews["dashboard-scroll-view"]
        scrollView.swipeUp()

        let weightWidget = app.otherElements["weight-trend-widget"]
        XCTAssertTrue(weightWidget.waitForExistence(timeout: 5), "Weight widget should exist")
        weightWidget.tap()

        let detailView = app.otherElements["weight-trend-detail-view"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 5), "Detail view should appear")

        // Drag down to dismiss
        detailView.swipeDown()
        Thread.sleep(forTimeInterval: 0.5)

        // Verify detail view is dismissed
        XCTAssertFalse(detailView.exists, "Detail view should be dismissed after drag down")

        // Verify we're back on dashboard
        XCTAssertTrue(dashboardView.exists, "Should return to dashboard after dismiss")
    }

    // MARK: - Helper Methods

    private func dismissDetailView() {
        // Try Done button first
        let doneButton = app.buttons["Done"]
        if doneButton.waitForExistence(timeout: 2) {
            doneButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
            return
        }

        // Fallback to swipe down
        let detailViews = [
            app.otherElements["weight-trend-detail-view"],
            app.otherElements["expenditure-detail-view"],
            app.otherElements["energy-balance-detail-view"],
        ]

        for view in detailViews where view.exists {
            view.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
            return
        }
    }
}
