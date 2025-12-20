import XCTest

final class JabTrackerUITestsLaunchTests: XCTestCase {
    override static var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Insert steps here to perform after app launch but before taking a screenshot
        // In the screenshot, the entire app's initial launch state is captured

        // Verify app launched successfully
        XCTAssertTrue(
            app.tabBars.element.waitForExistence(timeout: 10), "App should launch with tab bar visible")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testAppLaunchAndTabNavigation() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Verify tab bar exists
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")

        // Test Dashboard tab (should be selected by default)
        let dashboardTab = tabBar.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.exists, "Dashboard tab should exist")
        XCTAssertTrue(dashboardTab.isSelected, "Dashboard tab should be selected by default")

        // Verify Dashboard content (empty state shows "Add medication profiles")
        XCTAssertTrue(
            app.staticTexts["Add medication profiles"].waitForExistence(timeout: 3),
            "Dashboard empty state should exist")

        // Test Food Log tab navigation
        let foodLogTab = tabBar.buttons["Food Log"]
        XCTAssertTrue(foodLogTab.exists, "Food Log tab should exist")
        foodLogTab.tap()
        XCTAssertTrue(foodLogTab.isSelected, "Food Log tab should be selected after tap")

        // Test Add tab navigation (opens ShortcutsSheet)
        let addTab = tabBar.buttons["Add"]
        XCTAssertTrue(addTab.exists, "Add tab should exist")
        addTab.tap()

        // Verify ShortcutsSheet appears
        let shortcutsSheet = app.otherElements["shortcuts-sheet"]
        XCTAssertTrue(
            shortcutsSheet.waitForExistence(timeout: 3),
            "Shortcuts sheet should open when Add tab is tapped")

        // Dismiss the sheet
        let closeButton = app.buttons["shortcuts-close-button"]
        XCTAssertTrue(closeButton.exists, "Close button should exist")
        closeButton.tap()

        // Test Shots tab navigation
        let shotsTab = tabBar.buttons["Shots"]
        XCTAssertTrue(shotsTab.exists, "Shots tab should exist")
        shotsTab.tap()
        XCTAssertTrue(shotsTab.isSelected, "Shots tab should be selected after tap")

        // Verify Shots view content with segmented control
        let segmentedControl = app.segmentedControls["shots-section-picker"]
        XCTAssertTrue(
            segmentedControl.waitForExistence(timeout: 3),
            "Shots segmented control should exist")

        // Test switching between segments
        let historySegment = segmentedControl.buttons["History"]
        XCTAssertTrue(historySegment.exists, "History segment should exist")
        historySegment.tap()

        let concentrationSegment = segmentedControl.buttons["Concentration"]
        XCTAssertTrue(concentrationSegment.exists, "Concentration segment should exist")
        concentrationSegment.tap()

        let adherenceSegment = segmentedControl.buttons["Adherence"]
        XCTAssertTrue(adherenceSegment.exists, "Adherence segment should exist")
        adherenceSegment.tap()

        // Test More tab navigation
        let moreTab = tabBar.buttons["More"]
        XCTAssertTrue(moreTab.exists, "More tab should exist")
        moreTab.tap()
        XCTAssertTrue(moreTab.isSelected, "More tab should be selected after tap")

        // Verify Settings button exists in More menu
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(
            settingsButton.waitForExistence(timeout: 3),
            "Settings button should exist in More menu")

        // Navigate back to Dashboard tab
        dashboardTab.tap()
        XCTAssertTrue(dashboardTab.isSelected, "Dashboard tab should be selected after returning")
    }
}
