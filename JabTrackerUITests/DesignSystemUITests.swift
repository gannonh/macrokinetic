import XCTest

final class DesignSystemUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDesignSystemComponents() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Navigate to Settings tab to test design system components
        TestUtilities.navigateToTab(app, tabName: "Settings")

        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings navigation should exist")

        // Scroll down to ensure design system components are visible
        app.swipeUp()

        // Test actual design system components that exist in Settings
        XCTAssertTrue(
            app.staticTexts["User Profile"].waitForExistence(timeout: 5),
            "Settings should show user profile section")

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
        XCTAssertTrue(
            editButton.waitForExistence(timeout: 3), "Edit button should reappear after cancel")
    }

    @MainActor
    func testDesignSystemAccessibility() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Navigate to Settings tab
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings navigation should exist")

        // Test actual UI component accessibility (no scrolling needed)
        XCTAssertTrue(
            app.staticTexts["User Profile"].waitForExistence(timeout: 5),
            "Settings should show user profile section")

        let editButton = app.buttons["edit-profile-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button should exist")

        // Verify accessibility properties of design system components
        XCTAssertFalse(editButton.label.isEmpty, "Edit button should have accessibility label")
        XCTAssertTrue(editButton.exists, "Edit button should exist for accessibility")

        // Test sign out button accessibility
        if app.buttons["sign-out-button"].waitForExistence(timeout: 2) {
            let signOutButton = app.buttons["sign-out-button"]
            XCTAssertFalse(signOutButton.label.isEmpty, "Sign out button should have accessibility label")
            XCTAssertTrue(
                signOutButton.isHittable, "Sign out button should be hittable for accessibility")
        }
    }

    @MainActor
    func testTypographyRendering() throws {
        let app = TestUtilities.launchAppWithTestMode()

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
        let headline = app.staticTexts["design-system-headline"]
        XCTAssertTrue(headline.waitForExistence(timeout: 5), "Headline should exist")

        let bodyText = app.staticTexts["design-system-body"]
        XCTAssertTrue(bodyText.exists, "Body text should exist")

        let caption = app.staticTexts["design-system-caption"]
        XCTAssertTrue(caption.exists, "Caption should exist")

        // Verify text content is readable
        XCTAssertFalse(headline.label.isEmpty, "Headline should have text content")
        XCTAssertFalse(bodyText.label.isEmpty, "Body text should have text content")
        XCTAssertFalse(caption.label.isEmpty, "Caption should have text content")

        // Verify the actual text content matches expected design system elements
        XCTAssertEqual(headline.label, "Design System Demo", "Headline should have correct text")
        XCTAssertEqual(bodyText.label, "Typography and Colors", "Body text should have correct text")
        XCTAssertEqual(caption.label, "Sample caption text", "Caption should have correct text")
    }
}
