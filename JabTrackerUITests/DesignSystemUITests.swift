import XCTest

final class DesignSystemUITests: XCTestCase {
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
    func testDesignSystemComponents() throws {
        let app = launchAppWithTestMode()

        // Navigate to Settings tab to test design system components
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings navigation should exist")

        // Scroll down to ensure design system components are visible
        app.swipeUp()

        // Test actual design system components that exist in Settings
        XCTAssertTrue(app.staticTexts["User Profile"].waitForExistence(timeout: 5), "Settings should show user profile section")
        
        // Verify design system is working by checking for proper UI elements
        let editButton = app.buttons["edit-profile-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button should exist")

        // Test button functionality (design system component)
        XCTAssertTrue(editButton.isEnabled, "Edit button should be enabled")
        editButton.tap()
        
        // Verify edit mode shows design system components
        let saveButton = app.buttons["save-profile-button"] 
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should appear in edit mode")
        
        let cancelButton = app.buttons["cancel-edit-button"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist in edit mode")

        // Test design system button interactions
        cancelButton.tap()
        
        // Verify returned to view mode (design system working correctly)
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button should reappear after cancel")
    }

    @MainActor
    func testDesignSystemAccessibility() throws {
        let app = launchAppWithTestMode()

        // Navigate to Settings tab
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings navigation should exist")

        // Test actual UI component accessibility (no scrolling needed)
        XCTAssertTrue(app.staticTexts["User Profile"].waitForExistence(timeout: 5), "Settings should show user profile section")
        
        let editButton = app.buttons["edit-profile-button"] 
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button should exist")

        // Verify accessibility properties of design system components  
        XCTAssertFalse(editButton.label.isEmpty, "Edit button should have accessibility label")
        XCTAssertTrue(editButton.exists, "Edit button should exist for accessibility")

        // Test sign out button accessibility
        if app.buttons["sign-out-button"].waitForExistence(timeout: 2) {
            let signOutButton = app.buttons["sign-out-button"]
            XCTAssertFalse(signOutButton.label.isEmpty, "Sign out button should have accessibility label")
            XCTAssertTrue(signOutButton.isHittable, "Sign out button should be hittable for accessibility")
        }
    }

    @MainActor
    func testTypographyRendering() throws {
        let app = launchAppWithTestMode()

        // Navigate to Settings tab
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings navigation should exist")

        // Scroll down to ensure typography elements are visible
        app.swipeUp()

        // Verify typography elements exist with proper styling
        let largeTitle = app.staticTexts["design-system-large-title"]
        XCTAssertTrue(largeTitle.waitForExistence(timeout: 5), "Large title should exist")

        let headline = app.staticTexts["Design System Demo"]
        XCTAssertTrue(headline.exists, "Headline should exist")

        let bodyText = app.staticTexts["Typography and Colors"]
        XCTAssertTrue(bodyText.exists, "Body text should exist")

        let caption = app.staticTexts["Sample caption text"]
        XCTAssertTrue(caption.exists, "Caption should exist")

        // Verify text content is readable
        XCTAssertFalse(largeTitle.label.isEmpty, "Large title should have text content")
        XCTAssertFalse(headline.label.isEmpty, "Headline should have text content")
        XCTAssertFalse(bodyText.label.isEmpty, "Body text should have text content")
        XCTAssertFalse(caption.label.isEmpty, "Caption should have text content")
    }
}
