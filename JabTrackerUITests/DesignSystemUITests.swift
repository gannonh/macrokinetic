import XCTest

final class DesignSystemUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDesignSystemComponents() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Navigate to Settings tab to test design system components
        TestUtilities.navigateToSettings(app)

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

        // Navigate to Settings via More tab
        TestUtilities.navigateToSettings(app)

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

        // Navigate to Settings via More tab
        TestUtilities.navigateToSettings(app)

        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings navigation should exist")

        // Verify actual typography elements exist in Settings view
        // Test section headers (headline style)
        let userProfileHeader = app.staticTexts["User Profile"]
        XCTAssertTrue(userProfileHeader.waitForExistence(timeout: 5), "User Profile header should exist")
        XCTAssertFalse(userProfileHeader.label.isEmpty, "User Profile header should have text content")

        // Test button labels (body/caption style)
        let editButton = app.buttons["edit-profile-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Edit button should exist")
        XCTAssertFalse(editButton.label.isEmpty, "Edit button should have text content")

        // Scroll to see more content
        app.swipeUp()

        // Test Medication Profiles section if visible
        let medicationProfilesButton = app.buttons["Medication Profiles"]
        if medicationProfilesButton.waitForExistence(timeout: 2) {
            XCTAssertFalse(medicationProfilesButton.label.isEmpty, "Medication Profiles should have text content")
        }

        // Verify typography is rendering without crashes
        XCTAssertTrue(settingsTitle.exists, "Settings should continue to render correctly")
    }
}
