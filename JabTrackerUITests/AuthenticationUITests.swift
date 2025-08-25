import XCTest

final class AuthenticationUITests: XCTestCase {
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
    
    private func launchAppWithRealAuth() -> XCUIApplication {
        let app = XCUIApplication()
        // Reset app data to ensure clean state for authentication testing
        app.launchArguments.append("--reset-app-data")
        app.launch()
        return app
    }

    @MainActor
    func testCompleteSignInWithAppleFlow() throws {
        // This test verifies the Sign in with Apple UI appears correctly
        // It cannot complete the actual authentication without real Apple ID credentials
        let app = launchAppWithRealAuth()

        // When not authenticated, app should show AuthenticationView
        XCTAssertTrue(app.staticTexts["JabTracker"].waitForExistence(timeout: 5), 
                      "App title should be visible on authentication screen")
        
        XCTAssertTrue(app.staticTexts["Welcome to JabTracker"].waitForExistence(timeout: 3), 
                      "Welcome message should be visible")
        
        // Verify Sign in with Apple button exists and is enabled
        let signInButton = app.buttons["sign-in-with-apple-button"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 3), 
                      "Sign in with Apple button should be visible")
        XCTAssertTrue(signInButton.isEnabled, 
                      "Sign in with Apple button should be enabled")
        
        // Tap the button to verify it responds
        signInButton.tap()
        
        // Wait for system authentication sheet to appear
        sleep(2)
        
        // Check SpringBoard for the Apple ID authentication sheet
        let springBoard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let continueWithPasswordButton = springBoard.buttons["Continue with Password"]
        
        if continueWithPasswordButton.waitForExistence(timeout: 3) {
            // Apple ID sheet appeared - authentication flow started successfully  
            XCTAssertTrue(true, "Sign in with Apple authentication sheet appeared successfully")
            
            // Dismiss the sheet by tapping the X button in the top corner
            let closeButton = springBoard.buttons.matching(NSPredicate(format: "label CONTAINS '✕' OR identifier CONTAINS 'close' OR identifier CONTAINS 'cancel'")).firstMatch
            if closeButton.exists {
                closeButton.tap()
            }
            
        } else {
            XCTFail("Apple ID authentication sheet did not appear")
        }
    }

    @MainActor
    func testBiometricAuthenticationUI() throws {
        let app = launchAppWithTestMode()

        // Navigate to Settings
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Ensure user is authenticated first
        if app.buttons["sign-in-with-apple-button"].waitForExistence(timeout: 2) {
            XCTFail("User must be authenticated to test biometric settings. Please sign in first.")
        }

        // Verify biometric section exists (in test mode, biometrics are mocked as available)
        let biometricToggle = app.switches["biometric-auth-toggle"]
        XCTAssertTrue(biometricToggle.waitForExistence(timeout: 3), "Biometric toggle should exist for authenticated users in test mode")
        
        // Verify Face ID label is present
        XCTAssertTrue(app.staticTexts["Face ID"].exists, "Face ID label should be visible")
        XCTAssertTrue(app.staticTexts["Secure app access"].exists, "Biometric description should be visible")
        
        // Just verify the toggle is interactive - we can't test actual biometric functionality in simulator
        XCTAssertTrue(biometricToggle.isHittable, "Biometric toggle should be tappable")
    }

    @MainActor
    func testUserProfileEditing() throws {
        let app = launchAppWithTestMode()

        // Navigate to Settings
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Ensure user is authenticated
        XCTAssertTrue(app.staticTexts["User Profile"].waitForExistence(timeout: 3), 
                      "User Profile should be visible. Please sign in first.")

        // Tap Edit button
        let editButton = app.buttons["edit-profile-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2), "Edit profile button should exist")
        editButton.tap()

        // Test weight input
        let weightField = app.textFields["weight-input"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 2), "Weight input field should appear in edit mode")
        
        weightField.tap()
        weightField.clearAndEnterText("75")

        // Test weight unit picker (segmented control)
        let weightUnitPicker = app.segmentedControls["weight-unit-picker"]
        XCTAssertTrue(weightUnitPicker.exists, "Weight unit picker should exist")
        
        // Save changes
        let saveButton = app.buttons["save-profile-button"]
        XCTAssertTrue(saveButton.exists, "Save button should exist in edit mode")
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled with valid data")
        saveButton.tap()

        // Verify edit mode is exited
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Should return to view mode after save")
    }

    @MainActor
    func testFormValidation() throws {
        let app = launchAppWithTestMode()

        // Navigate to Settings and enter edit mode
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Ensure user is authenticated and enter edit mode
        XCTAssertTrue(app.staticTexts["User Profile"].waitForExistence(timeout: 3), 
                      "User Profile should be visible")
        
        let editButton = app.buttons["edit-profile-button"]
        editButton.tap()

        // Test invalid weight input
        let weightField = app.textFields["weight-input"]
        weightField.tap()
        weightField.clearAndEnterText("-50")
        
        // Check for error message
        let errorMessage = app.staticTexts["weight-error-message"]
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 2), "Error message should appear for invalid weight")
        
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
        let app = launchAppWithTestMode()

        // Navigate to Settings
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Ensure user is authenticated
        XCTAssertTrue(app.staticTexts["User Profile"].waitForExistence(timeout: 3), 
                      "User Profile should be visible")

        // Find and tap sign out button
        let signOutButton = app.buttons["sign-out-button"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 2), "Sign out button should exist")
        XCTAssertTrue(signOutButton.isEnabled, "Sign out button should be enabled")
        
        signOutButton.tap()

        // Verify sign in button appears after sign out
        let signInButton = app.buttons["sign-in-with-apple-button"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 3), "Sign in button should appear after sign out")
        
        // Verify profile is no longer visible
        XCTAssertFalse(app.staticTexts["User Profile"].exists, "User Profile should not be visible after sign out")
    }

    @MainActor
    func testAuthenticationPersistence() throws {
        let app = launchAppWithTestMode()
        
        // In test mode, should see TabView (may take a moment to initialize)
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "TabView should be visible in test mode")
        
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // In test mode, should see user profile
        let profileExists = app.staticTexts["User Profile"].waitForExistence(timeout: 3)
        XCTAssertTrue(profileExists, "User profile should be visible in test mode")
        
        // Test app restart persistence
        app.terminate()
        
        // Relaunch with test mode
        let restartedApp = launchAppWithTestMode()
        
        let restartedTabBar = restartedApp.tabBars.element
        XCTAssertTrue(restartedTabBar.waitForExistence(timeout: 3), "TabView should be visible after restart in test mode")
        
        let restartedSettingsTab = restartedTabBar.buttons["Settings"]
        restartedSettingsTab.tap()
        
        // Profile should still be visible after relaunch in test mode
        XCTAssertTrue(restartedApp.staticTexts["User Profile"].waitForExistence(timeout: 3), 
                      "User Profile should persist after app relaunch in test mode")
    }
}

// Extension to help with text field operations in UI tests
extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard self.elementType == .textField else { return }
        
        self.tap()
        self.press(forDuration: 1.0)
        
        let selectAll = XCUIApplication().menuItems["Select All"]
        if selectAll.exists {
            selectAll.tap()
        }
        
        self.typeText(text)
    }
}
