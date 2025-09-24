import XCTest

final class AuthenticationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // NOTE: Real Sign in with Apple testing has been moved to ManualAuthenticationUITests.swift
    // This allows for manual testing in Xcode while keeping automated tests reliable

    @MainActor
    func testBiometricAuthenticationUI() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Navigate to Settings
        TestUtilities.navigateToTab(app, tabName: "Settings")

        // Ensure user is authenticated first
        if app.buttons["sign-in-with-apple-button"].waitForExistence(timeout: 2) {
            XCTFail("User must be authenticated to test biometric settings. Please sign in first.")
        }

        // Verify biometric section exists (in test mode, biometrics are mocked as available)
        let biometricToggle = app.switches["biometric-auth-toggle"]
        XCTAssertTrue(
            biometricToggle.waitForExistence(timeout: 3),
            "Biometric toggle should exist for authenticated users in test mode")

        // Verify Face ID label is present
        XCTAssertTrue(app.staticTexts["Face ID"].exists, "Face ID label should be visible")
        XCTAssertTrue(
            app.staticTexts["Secure app access"].exists, "Biometric description should be visible")

        // Just verify the toggle is interactive - we can't test actual biometric functionality in simulator
        XCTAssertTrue(biometricToggle.isHittable, "Biometric toggle should be tappable")
    }

    @MainActor
    func testUserProfileEditing() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Navigate to Settings and verify authentication
        try TestUtilities.navigateToSettingsAndVerifyAuth(app)

        // Enter edit mode
        TestUtilities.enterProfileEditMode(app)

        // Test weight input
        let weightField = app.textFields["weight-input"]
        XCTAssertTrue(
            weightField.waitForExistence(timeout: 2), "Weight input field should appear in edit mode")

        weightField.tap()
        weightField.clearAndEnterText("75")

        // Test weight unit picker (segmented control)
        let weightUnitPicker = app.segmentedControls["weight-unit-picker"]
        XCTAssertTrue(weightUnitPicker.exists, "Weight unit picker should exist")

        // Save changes
        TestUtilities.saveProfileChanges(app)
    }

    @MainActor
    func testFormValidation() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Navigate to Settings and enter edit mode
        try TestUtilities.navigateToSettingsAndVerifyAuth(app)
        TestUtilities.enterProfileEditMode(app)

        // Test invalid weight input
        let weightField = app.textFields["weight-input"]
        weightField.tap()
        weightField.clearAndEnterText("-50")

        // Check for error message
        let errorMessage = app.staticTexts["weight-error-message"]
        XCTAssertTrue(
            errorMessage.waitForExistence(timeout: 2), "Error message should appear for invalid weight")

        // Save button should be disabled
        let saveButton = app.buttons["save-profile-button"]
        XCTAssertFalse(saveButton.isEnabled, "Save button should be disabled with invalid data")

        // Test valid weight
        weightField.clearAndEnterText("70")
        XCTAssertFalse(errorMessage.exists, "Error message should disappear with valid weight")
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled with valid data")
    }

    @MainActor
    func testSignOutFlow() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Navigate to Settings and verify authentication
        try TestUtilities.navigateToSettingsAndVerifyAuth(app)

        // Find and tap sign out button
        let signOutButton = app.buttons["sign-out-button"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 2), "Sign out button should exist")
        XCTAssertTrue(signOutButton.isEnabled, "Sign out button should be enabled")

        signOutButton.tap()

        // Verify sign in button appears after sign out
        let signInButton = app.buttons["sign-in-with-apple-button"]
        XCTAssertTrue(
            signInButton.waitForExistence(timeout: 3), "Sign in button should appear after sign out")

        // Verify profile is no longer visible
        XCTAssertFalse(
            app.staticTexts["User Profile"].exists, "User Profile should not be visible after sign out")
    }

    @MainActor
    func testAuthenticationPersistence() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // In test mode, should see TabView (may take a moment to initialize)
        TestUtilities.verifyAuthenticatedState(app)

        TestUtilities.navigateToTab(app, tabName: "Settings")

        // In test mode, should see user profile
        let profileExists = app.staticTexts["User Profile"].waitForExistence(timeout: 3)
        XCTAssertTrue(profileExists, "User profile should be visible in test mode")

        // Test app restart persistence
        app.terminate()

        // Relaunch with test mode
        let restartedApp = TestUtilities.launchAppWithTestMode()

        TestUtilities.verifyAuthenticatedState(restartedApp, timeout: 3)

        TestUtilities.navigateToTab(restartedApp, tabName: "Settings")

        // Profile should still be visible after relaunch in test mode
        XCTAssertTrue(
            restartedApp.staticTexts["User Profile"].waitForExistence(timeout: 3),
            "User Profile should persist after app relaunch in test mode")
    }
}
