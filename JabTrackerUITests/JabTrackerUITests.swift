import XCTest

final class JabTrackerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    private func launchAppWithTestMode() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "true"
        app.launchArguments.append("--ui-testing")
        app.launch()
        return app
    }

    @MainActor
    func testAppLaunchAndTabNavigation() throws {
        let app = launchAppWithTestMode()

        // Verify tab bar exists
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")

        // Test Home tab (should be selected by default)
        let homeTab = tabBar.buttons["Home"]
        XCTAssertTrue(homeTab.exists, "Home tab should exist")
        XCTAssertTrue(homeTab.isSelected, "Home tab should be selected by default")

        // Verify Dashboard content
        XCTAssertTrue(app.staticTexts["Dashboard"].exists, "Dashboard title should exist")
        XCTAssertTrue(app.staticTexts["Welcome to JabTracker"].exists, "Welcome text should exist")

        // Test Add Dose tab navigation
        let addTab = tabBar.buttons["Add"]
        XCTAssertTrue(addTab.exists, "Add tab should exist")
        addTab.tap()

        XCTAssertTrue(addTab.isSelected, "Add tab should be selected after tap")
        XCTAssertTrue(app.staticTexts["Add Dose"].exists, "Add Dose title should exist")
        XCTAssertTrue(app.buttons["quick-add-dose-button"].exists, "Quick add button should exist")

        // Test History tab navigation
        let historyTab = tabBar.buttons["History"]
        XCTAssertTrue(historyTab.exists, "History tab should exist")
        historyTab.tap()

        XCTAssertTrue(historyTab.isSelected, "History tab should be selected after tap")
        XCTAssertTrue(app.staticTexts["Dose History"].exists, "History title should exist")

        // Test Analytics tab navigation
        let analyticsTab = tabBar.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.exists, "Analytics tab should exist")
        analyticsTab.tap()

        XCTAssertTrue(analyticsTab.isSelected, "Analytics tab should be selected after tap")
        XCTAssertTrue(app.staticTexts["Analytics"].exists, "Analytics title should exist")

        // Test Settings tab navigation
        let settingsTab = tabBar.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
        settingsTab.tap()

        XCTAssertTrue(settingsTab.isSelected, "Settings tab should be selected after tap")
        XCTAssertTrue(app.staticTexts["Settings"].exists, "Settings title should exist")

        // Navigate back to Home tab
        homeTab.tap()
        XCTAssertTrue(homeTab.isSelected, "Home tab should be selected after returning")
    }

    @MainActor
    func testQuickAddDoseButtonInteraction() throws {
        let app = launchAppWithTestMode()

        // Navigate to Add Dose tab
        let tabBar = app.tabBars.element
        let addTab = tabBar.buttons["Add"]
        addTab.tap()

        // Verify Quick Add button exists and is tappable
        let quickAddButton = app.buttons["quick-add-dose-button"]
        XCTAssertTrue(quickAddButton.waitForExistence(timeout: 2), "Quick add button should exist")
        XCTAssertTrue(quickAddButton.isEnabled, "Quick add button should be enabled")

        // Tap the button (no functionality implemented yet, but should not crash)
        quickAddButton.tap()

        // Verify app is still functional after tap
        XCTAssertTrue(app.staticTexts["Add Dose"].exists, "Should still be on Add Dose view")
    }
}
