//
//  StrategyTabUITests.swift
//  JabTrackerUITests
//
//  E2E tests for Strategy Tab Promotion feature (v0.5.0 Phase 23).
//  Tests that Strategy is now a top-level tab in the tab bar, replacing the Shots tab.
//

import XCTest

final class StrategyTabUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
    }

    override func tearDownWithError() throws {
        if testRun?.hasSucceeded == false {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        app = nil
    }

    // MARK: - Strategy Tab Existence Tests

    /// Verify Strategy tab appears in the tab bar
    func testStrategyTabExists() throws {
        // GIVEN: App is launched with clean state

        // WHEN: We check the tab bar
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")

        // THEN: Strategy tab should exist
        let strategyTab = tabBar.buttons["Strategy"]
        XCTAssertTrue(strategyTab.exists, "Strategy tab should exist in the tab bar")
    }

    /// Verify tapping Strategy tab navigates to the Strategy view
    func testStrategyTabNavigatesToStrategyView() throws {
        // GIVEN: App is launched and tab bar is visible
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")

        // WHEN: User taps the Strategy tab
        let strategyTab = tabBar.buttons["Strategy"]
        XCTAssertTrue(strategyTab.exists, "Strategy tab should exist")
        strategyTab.tap()

        // THEN: Strategy view should appear
        // Use descendants query since it's in a NavigationStack
        let strategyView = app.descendants(matching: .any)["strategy-view"].firstMatch
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 5),
            "Strategy view should appear after tapping Strategy tab"
        )
    }

    /// Verify Strategy tab uses the correct icon (target symbol)
    func testStrategyTabShowsCorrectIcon() throws {
        // GIVEN: App is launched
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")

        // WHEN: We inspect the Strategy tab
        let strategyTab = tabBar.buttons["Strategy"]
        XCTAssertTrue(strategyTab.exists, "Strategy tab should exist")

        // THEN: The tab should be visible and tappable
        // Note: XCUITest cannot directly verify SF Symbol names, but we can verify
        // the tab exists and is functional. The icon "target" is set in Tab.swift.
        XCTAssertTrue(strategyTab.isHittable, "Strategy tab should be tappable")

        // Tap to verify it works with its icon
        strategyTab.tap()
        let strategyView = app.descendants(matching: .any)["strategy-view"].firstMatch
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 5),
            "Strategy tab with icon should navigate to Strategy view"
        )
    }

    // MARK: - Tab Bar Structure Tests

    /// Verify tab bar has correct labeled tabs and floating Add button
    /// Note: Add button is now a floating overlay (icon-only), not a tab bar item
    func testTabBarHasCorrectTabs() throws {
        // GIVEN: App is launched
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")

        // THEN: All labeled tabs should exist in tab bar
        let dashboardTab = tabBar.buttons["Dashboard"]
        let foodLogTab = tabBar.buttons["Food Log"]
        let strategyTab = tabBar.buttons["Strategy"]
        let moreTab = tabBar.buttons["More"]

        XCTAssertTrue(dashboardTab.exists, "Dashboard tab should exist")
        XCTAssertTrue(foodLogTab.exists, "Food Log tab should exist")
        XCTAssertTrue(strategyTab.exists, "Strategy tab should exist")
        XCTAssertTrue(moreTab.exists, "More tab should exist")

        // Add button is a floating overlay, verify it exists outside tab bar
        let addButton = app.buttons["add-button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add button should exist as floating overlay")
        XCTAssertTrue(addButton.isHittable, "Add button should be tappable")

        // Verify tab order (left to right) for labeled tabs
        XCTAssertLessThan(
            dashboardTab.frame.midX,
            foodLogTab.frame.midX,
            "Dashboard tab should be left of Food Log tab"
        )
        XCTAssertLessThan(
            foodLogTab.frame.midX,
            strategyTab.frame.midX,
            "Food Log tab should be left of Strategy tab"
        )
        XCTAssertLessThan(
            strategyTab.frame.midX,
            moreTab.frame.midX,
            "Strategy tab should be left of More tab"
        )

        // Verify Add button is visually centered between Food Log and Strategy tabs
        let addButtonCenterX = addButton.frame.midX
        XCTAssertGreaterThan(
            addButtonCenterX,
            foodLogTab.frame.maxX,
            "Add button should be positioned after Food Log tab"
        )
        XCTAssertLessThan(
            addButtonCenterX,
            strategyTab.frame.minX,
            "Add button should be positioned before Strategy tab"
        )
    }

    /// Verify the old "Shots" tab no longer exists in the tab bar
    func testShotsTabNoLongerExists() throws {
        // GIVEN: App is launched
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")

        // THEN: Shots tab should NOT exist (replaced by Strategy)
        let shotsTab = tabBar.buttons["Shots"]
        XCTAssertFalse(
            shotsTab.exists,
            "Shots tab should NOT exist - it has been replaced by Strategy tab"
        )
    }

    // MARK: - Tab Selection State Tests

    /// Verify Strategy tab shows selected state when tapped
    func testStrategyTabShowsSelectedState() throws {
        // GIVEN: App is launched
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")

        // WHEN: User taps Strategy tab
        let strategyTab = tabBar.buttons["Strategy"]
        XCTAssertTrue(strategyTab.exists, "Strategy tab should exist")
        strategyTab.tap()

        // Wait for navigation to complete
        let strategyView = app.descendants(matching: .any)["strategy-view"].firstMatch
        XCTAssertTrue(strategyView.waitForExistence(timeout: 5), "Strategy view should appear")

        // THEN: Strategy tab should be selected
        XCTAssertTrue(strategyTab.isSelected, "Strategy tab should be selected after tap")
    }

    /// Verify Strategy tab can be navigated to from any other tab
    func testStrategyTabAccessibleFromAllTabs() throws {
        // GIVEN: App is launched
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")
        let strategyTab = tabBar.buttons["Strategy"]

        // Test from Dashboard (default)
        strategyTab.tap()
        var strategyView = app.descendants(matching: .any)["strategy-view"].firstMatch
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 5),
            "Strategy should be accessible from Dashboard"
        )

        // Test from Food Log
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        strategyTab.tap()
        strategyView = app.descendants(matching: .any)["strategy-view"].firstMatch
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 5),
            "Strategy should be accessible from Food Log"
        )

        // Test from More
        TestUtilities.navigateToTab(app, tabName: "More")
        strategyTab.tap()
        strategyView = app.descendants(matching: .any)["strategy-view"].firstMatch
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 5),
            "Strategy should be accessible from More tab"
        )
    }
}

// MARK: - Accessibility Identifiers Reference
//
// Tab Bar:
// - "main-tab-view" - Main TabView container
//
// Tab Buttons (in tab bar):
// - "Dashboard" - Dashboard tab
// - "Food Log" - Food Log tab
// - "Strategy" - Strategy tab (replaced Shots)
// - "More" - More tab
//
// Floating Button (NOT in tab bar):
// - "add-button" - Floating Add button overlay (icon-only, larger size)
//
// Strategy View:
// - "strategy-view" - Main Strategy view identifier
//
// More Tab:
// - "more-view" - More view container
// - "glp1-programs-row" - GLP-1 Programs navigation row
//
// Note: "Shots" tab no longer exists - replaced by "Strategy" in v0.5.0
// Note: "Goals & Strategy" row removed from More - Strategy is now a top-level tab
// Note: Add button is now a floating overlay, not a tab bar item (v0.5.0 Phase 24)
