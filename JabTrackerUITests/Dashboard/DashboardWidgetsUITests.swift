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
        // The widget identifier is on StaticText children, use staticTexts query
        let weeklyWidget = app.staticTexts["weekly-nutrition-hero-widget"].firstMatch
        XCTAssertTrue(weeklyWidget.waitForExistence(timeout: 5), "Weekly nutrition widget should be visible initially")

        // Swipe left to navigate to second widget (Daily Nutrition)
        heroContainer.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)  // Allow animation to complete

        // Daily Nutrition widget - look for its identifier on staticTexts
        let dailyWidget = app.staticTexts["daily-nutrition-hero-widget"].firstMatch
        XCTAssertTrue(dailyWidget.waitForExistence(timeout: 3), "Daily nutrition widget should appear after swipe")

        // Swipe left to navigate to third widget (Energy Balance)
        heroContainer.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)

        // Energy Balance widget - look for its identifier on staticTexts
        let energyWidget = app.staticTexts["energy-balance-hero-widget"].firstMatch
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

        // Find the Consumed and Remaining buttons inside the toggle
        let consumedButton = app.buttons["Consumed view"]
        let remainingButton = app.buttons["Remaining view"]
        XCTAssertTrue(consumedButton.waitForExistence(timeout: 5), "Consumed button should exist")
        XCTAssertTrue(remainingButton.exists, "Remaining button should exist")

        // Verify Consumed is initially selected
        XCTAssertTrue(consumedButton.isSelected, "Consumed should be initially selected")

        // Tap Remaining to toggle
        remainingButton.tap()
        Thread.sleep(forTimeInterval: 0.3)

        // Verify Remaining is now selected
        XCTAssertTrue(remainingButton.isSelected, "Remaining should be selected after tap")

        // Toggle back to Consumed
        consumedButton.tap()
        Thread.sleep(forTimeInterval: 0.3)

        XCTAssertTrue(consumedButton.isSelected, "Consumed should be selected again")
    }

    func testEnergyDisplayToggle() throws {
        app = TestUtilities.launchAppWithSeededData(preset: .oneYearHighQuality)

        let dashboardView = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboardView.waitForExistence(timeout: 10), "Dashboard should load")

        // Navigate to energy balance widget
        let heroContainer = app.otherElements["hero-widget-container"]
        XCTAssertTrue(heroContainer.waitForExistence(timeout: 5), "Hero container should exist")

        // Swipe twice to get to energy balance (page index 2)
        heroContainer.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)
        heroContainer.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)

        // Find the Expenditure and Targets buttons inside the toggle
        let expenditureButton = app.buttons["Expenditure view"]
        let targetsButton = app.buttons["Targets view"]
        XCTAssertTrue(expenditureButton.waitForExistence(timeout: 5), "Expenditure button should exist")
        XCTAssertTrue(targetsButton.exists, "Targets button should exist")

        // Tap to toggle to Targets
        targetsButton.tap()
        Thread.sleep(forTimeInterval: 0.3)

        // Verify widget is still visible after toggle
        let energyWidget = app.otherElements["energy-balance-hero-widget"]
        XCTAssertTrue(energyWidget.exists, "Energy balance widget should remain visible after toggle")

        // Verify Targets is now selected
        XCTAssertTrue(targetsButton.isSelected, "Targets should be selected after tap")
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

        // Verify time period buttons exist (use accessibility labels)
        let yearButton = app.buttons["One year"]
        XCTAssertTrue(yearButton.waitForExistence(timeout: 3), "Time period selector should exist")

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

        // Test time period buttons (use accessibility labels, not identifiers)
        // The buttons have identifier 'detail-time-period-selector' but labels like 'One week'
        let weekButton = app.buttons["One week"]
        let monthButton = app.buttons["One month"]
        let threeMonthButton = app.buttons["Three months"]
        let yearButton = app.buttons["One year"]

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
        // Widget identifier is on StaticText children
        let weeklyWidget = app.staticTexts["weekly-nutrition-hero-widget"].firstMatch
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

        // Use the sheet grabber to dismiss (more reliable than swipeDown on view)
        let sheetGrabber = app.buttons["Sheet Grabber"]
        if sheetGrabber.exists {
            // Drag the sheet grabber down to dismiss
            let start = sheetGrabber.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let end = start.withOffset(CGVector(dx: 0, dy: 400))
            start.press(forDuration: 0.1, thenDragTo: end)
        } else {
            // Fallback: swipe down on the detail view itself
            detailView.swipeDown()
        }
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
