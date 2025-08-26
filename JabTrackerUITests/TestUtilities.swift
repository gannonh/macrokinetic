import XCTest

/// Shared test utilities for UI testing across the JabTracker app
/// Provides common app launch methods and helper functions
final class TestUtilities {
    
    // MARK: - App Launch Methods
    
    /// Launch app with UI testing mode enabled
    /// - Bypasses real Sign in with Apple authentication
    /// - Creates mock user data for testing
    /// - Provides full app functionality without external dependencies
    static func launchAppWithTestMode() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "true"
        app.launchArguments.append("--ui-testing")
        app.launch()
        return app
    }
    
    /// Launch app with real authentication (for testing actual Sign in with Apple flow)
    /// - Uses real Apple ID authentication
    /// - Resets app data for clean state
    /// - Suitable for testing authentication UI only (cannot complete without real credentials)
    static func launchAppWithRealAuth() -> XCUIApplication {
        let app = XCUIApplication()
        // Reset app data to ensure clean state for authentication testing
        app.launchArguments.append("--reset-app-data")
        app.launch()
        return app
    }
    
    /// Launch app with custom configuration
    /// - Parameters:
    ///   - testMode: Enable UI testing mode (bypasses authentication)
    ///   - resetData: Reset app data for clean state
    ///   - additionalArguments: Additional launch arguments
    ///   - additionalEnvironment: Additional environment variables
    static func launchAppWithConfiguration(
        testMode: Bool = false,
        resetData: Bool = false,
        additionalArguments: [String] = [],
        additionalEnvironment: [String: String] = [:]
    ) -> XCUIApplication {
        let app = XCUIApplication()
        
        if testMode {
            app.launchEnvironment["UI_TESTING"] = "true"
            app.launchArguments.append("--ui-testing")
        }
        
        if resetData {
            app.launchArguments.append("--reset-app-data")
        }
        
        // Add additional arguments
        app.launchArguments.append(contentsOf: additionalArguments)
        
        // Add additional environment variables
        for (key, value) in additionalEnvironment {
            app.launchEnvironment[key] = value
        }
        
        app.launch()
        return app
    }
    
    // MARK: - Navigation Helpers
    
    /// Navigate to a specific tab in the tab bar
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - tabName: Name of the tab to navigate to ("Home", "Add", "History", "Analytics", "Settings")
    ///   - timeout: Maximum time to wait for tab to exist (default: 5 seconds)
    /// - Returns: The tab button element
    @discardableResult
    static func navigateToTab(_ app: XCUIApplication, tabName: String, timeout: TimeInterval = 5) -> XCUIElement {
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: timeout), "Tab bar should exist")
        
        let tab = tabBar.buttons[tabName]
        XCTAssertTrue(tab.exists, "\(tabName) tab should exist")
        tab.tap()
        return tab
    }
    
    /// Navigate to Settings tab and verify user is authenticated
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - timeout: Maximum time to wait for profile to appear
    /// - Throws: XCTFail if user is not authenticated
    static func navigateToSettingsAndVerifyAuth(_ app: XCUIApplication, timeout: TimeInterval = 3) throws {
        navigateToTab(app, tabName: "Settings")
        
        guard app.staticTexts["User Profile"].waitForExistence(timeout: timeout) else {
            XCTFail("User Profile should be visible. Please ensure user is authenticated.")
            return
        }
    }
    
    // MARK: - Authentication Helpers
    
    /// Wait for and verify Sign in with Apple button exists
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - timeout: Maximum time to wait for button (default: 5 seconds)
    /// - Returns: The Sign in with Apple button element
    @discardableResult
    static func waitForSignInButton(_ app: XCUIApplication, timeout: TimeInterval = 5) -> XCUIElement {
        let signInButton = app.buttons["sign-in-with-apple-button"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: timeout), 
                      "Sign in with Apple button should be visible")
        return signInButton
    }
    
    /// Attempt to login if Sign in with Apple button is present
    /// - Parameter app: The XCUIApplication instance
    static func loginIfPresent(_ app: XCUIApplication) {
        let signInWithAppleButton = app.buttons["sign-in-with-apple-button"]
            .firstMatch

        if signInWithAppleButton.exists {
            signInWithApple(app)
        }
    }
    
    /// Perform Sign in with Apple authentication with real credentials
    /// - Parameter app: The XCUIApplication instance
    /// - Note: This uses hardcoded test credentials - should only be used in test environment
    static func signInWithApple(_ app: XCUIApplication) {
        print("🔐 Starting Sign in with Apple flow")

        // Wait for the sign in screen to appear
        let signInWithAppleButton = app.buttons["sign-in-with-apple-button"]
        waitForElement(signInWithAppleButton)
        signInWithAppleButton.tap()
        print("📱 Tapped Sign in with Apple button")

        // Wait for the Apple ID authentication sheet
        sleep(2) // Give time for system sheet to appear
        print("⏳ Waiting for Apple ID sheet")

        // Handle the Apple ID authentication sheet
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        // Check if Settings dialog appears first (sometimes required for Apple ID setup)
        let settingsButton = springboard.buttons["Settings"]
        if settingsButton.waitForExistence(timeout: 3) {
            print("⚙️ Settings dialog appeared - handling Apple ID setup flow")
            settingsButton.tap()
            
            // Debug: Print all available elements in Settings screen
            print("🔍 Debugging Settings screen elements:")
            let allStaticTexts = springboard.staticTexts.allElementsBoundByIndex
            for (index, text) in allStaticTexts.enumerated() {
                print("  StaticText \(index): '\(text.label)' - exists: \(text.exists)")
            }
            let allButtons = springboard.buttons.allElementsBoundByIndex
            for (index, button) in allButtons.enumerated() {
                print("  Button \(index): '\(button.label)' - exists: \(button.exists)")
            }
            
            // The modal is likely in AuthKit UI context, not Settings or SpringBoard
            let authKitApp = XCUIApplication(bundleIdentifier: "com.apple.AuthKitUI")
            let signInManuallyText = authKitApp.staticTexts["Sign in Manually"]
            var foundSignInManually = false
            
            if signInManuallyText.waitForExistence(timeout: 5) {
                signInManuallyText.tap()
                print("✅ Tapped Sign in Manually in AuthKit UI")
                foundSignInManually = true
            } else {
                // Try other contexts if AuthKit doesn't work
                let contexts = [
                    ("Settings", XCUIApplication(bundleIdentifier: "com.apple.Preferences")),
                    ("SpringBoard", springboard),
                    ("Main App", XCUIApplication())
                ]
                
                for (name, app) in contexts {
                    let signInText = app.staticTexts["Sign in Manually"]
                    if signInText.exists {
                        signInText.tap()
                        print("✅ Tapped Sign in Manually in \(name)")
                        foundSignInManually = true
                        break
                    }
                }
                
                if !foundSignInManually {
                    print("❌ Could not find 'Sign in Manually' in any context")
                }
            }
            
            // Wait for the sign in manually screen to load
            sleep(2)
            
            if foundSignInManually {
                // The Apple ID login screen appears in Settings context
                let settingsApp = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
                
                // Try to find the email/username field with various identifiers
                let possibleUsernameFields = [
                    settingsApp.textFields.element(boundBy: 0), // First text field
                    settingsApp.textFields["Apple ID"],
                    settingsApp.textFields["email"],
                    settingsApp.textFields["username"],
                    springboard.textFields.element(boundBy: 0), // Fallback to SpringBoard
                ]
                
                var foundUsernameField = false
                for usernameField in possibleUsernameFields {
                    if usernameField.waitForExistence(timeout: 2) {
                        usernameField.tap()
                        print("👤 Tapped username field: '\(usernameField.label)' or '\(usernameField.placeholderValue ?? "no placeholder")'")
                        
                        // Type the phone number
                        usernameField.typeText("4158878252")
                        print("📱 Entered phone number: 4158878252")
                        
                        foundUsernameField = true
                        break
                    }
                }
                
                if !foundUsernameField {
                    print("⚠️ Could not find username field, trying to proceed anyway")
                }
                
                // Wait a moment for the Continue button to become enabled after typing
                sleep(1)
                
                // Tap the continue button - try multiple approaches
                let continueButton = settingsApp.buttons["continue"]
                
                if continueButton.waitForExistence(timeout: 3) {
                    print("🔍 Continue button exists, trying multiple tap approaches...")
                    
                    // Try approach 1: Force tap regardless of hittable status
                    continueButton.tap()
                    print("⌨️ Attempted standard tap on continue button")
                    sleep(2)
                    
                    // Check if password field appeared (success indicator)
                    let passwordField = settingsApp.secureTextFields.element(boundBy: 0)
                    if !passwordField.exists {
                        print("🔄 Password field not found, trying coordinate tap...")
                        // Try approach 2: Coordinate tap
                        continueButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                        print("⌨️ Attempted coordinate tap on continue button")
                        sleep(2)
                    }
                    
                    // If still not working, try pressing return/enter key
                    if !passwordField.exists {
                        print("🔄 Still no password field, trying return key...")
                        settingsApp.keyboards.buttons["Return"].tap()
                        print("⌨️ Attempted Return key press")
                        sleep(2)
                    }
                    
                    // Final check and wait
                    sleep(1)
                    
                    // Enter password in Settings app context
                    if passwordField.waitForExistence(timeout: 3) {
                        passwordField.tap()
                        passwordField.typeText("S3cr3t77!")
                        print("🔒 Entered password")
                        
                        // Tap Done button after password entry (from your codegen)
                        let doneButton = settingsApp.buttons["Done"]
                        if doneButton.waitForExistence(timeout: 3) {
                            doneButton.tap()
                            print("✅ Tapped Done button after password entry")
                            
                            // Handle "Not Now" dialog - reduced timeout
                            let notNowButton = settingsApp.buttons["Not Now"]
                            if notNowButton.waitForExistence(timeout: 2) {
                                notNowButton.tap()
                                print("✅ Tapped Not Now")
                            }
                            
                            // Skip "Don't Merge" - handled automatically by interruption handler
                            
                            // Return to app via breadcrumb
                            let breadcrumbButton = springboard.buttons["breadcrumb"]
                            if breadcrumbButton.waitForExistence(timeout: 3) {
                                breadcrumbButton.tap()
                                print("↩️ Tapped breadcrumb to return to app")
                            }
                            
                            // Skip OK dialog - often doesn't appear
                            
                            // Wait for return to app - we should be back in main app now
                            sleep(2)
                            
                            // Check if we're back in the main app by looking for Sign in with Apple button
                            if signInWithAppleButton.waitForExistence(timeout: 3) {
                                signInWithAppleButton.tap()
                                print("📱 Tapped Sign in with Apple button to resume authorization")
                                sleep(2)
                            }
                            
                            // Now handle the Apple ID authorization screen in main app context
                            // Handle "Share My Email" selection - this appears in the main app
                            let shareMyEmailText = app.staticTexts["Share My Email"]
                            if shareMyEmailText.waitForExistence(timeout: 5) {
                                shareMyEmailText.tap()
                                print("✅ Tapped Share My Email in main app")
                                sleep(1)
                            }
                            
                            // Handle final Continue button (SIWA_CONTINUE_BUTTON) in main app
                            let siwaResumeButton = app.buttons["SIWA_CONTINUE_BUTTON"]
                            if siwaResumeButton.waitForExistence(timeout: 5) {
                                siwaResumeButton.tap()
                                print("✅ Tapped SIWA Continue button in main app")
                                sleep(1)
                            }
                            
                        } else {
                            print("⚠️ Could not find Done button after password entry")
                        }
                    } else {
                        print("⚠️ Could not find password field")
                    }
                } else {
                    print("⚠️ Could not find continue button")
                }
                
                // Authentication flow completed - return directly
            } else {
                // If we can't find "Sign in Manually", the authentication flow failed
                print("❌ Could not find Sign in Manually option - authentication flow failed")
                XCTFail("Apple ID authentication screen did not show expected 'Sign in Manually' option")
                return
            }
        }
        
        // Authentication flow completed
        print("🎉 Sign in flow completed")
    }
    
    /// Verify app is in authenticated state (TabView visible)
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - timeout: Maximum time to wait for TabView (default: 10 seconds)
    static func verifyAuthenticatedState(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: timeout), 
                      "TabView should be visible when authenticated")
    }
    
    /// Verify app is in unauthenticated state (Sign in button visible)
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - timeout: Maximum time to wait for sign in button (default: 5 seconds)
    static func verifyUnauthenticatedState(_ app: XCUIApplication, timeout: TimeInterval = 5) {
        waitForSignInButton(app, timeout: timeout)
        XCTAssertTrue(app.staticTexts["Welcome to JabTracker"].exists, 
                      "Welcome message should be visible when not authenticated")
    }
    
    // MARK: - Element Waiting Helpers
    
    /// Wait for element to exist with custom timeout and polling
    /// - Parameters:
    ///   - element: The XCUIElement to wait for
    ///   - timeout: Maximum time to wait in seconds (default: 30)
    static func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 30) {
        let start = Date()
        while !element.exists {
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("Timed out waiting for element to exist")
                return
            }
            usleep(100_000)  // Sleep for 100ms to prevent tight spinning
        }
    }

    /// Wait for element to disappear with custom timeout and polling
    /// - Parameters:
    ///   - element: The XCUIElement to wait for disappearance
    ///   - timeout: Maximum time to wait in seconds (default: 30)
    static func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 30) {
        let start = Date()
        while element.exists {
            if Date().timeIntervalSince(start) > timeout {
                XCTFail("Timed out waiting for element to disappear")
                return
            }
            usleep(100_000)  // Sleep for 100ms to prevent tight spinning
        }
    }

    // MARK: - Form Interaction Helpers
    
    /// Enter edit mode for user profile
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - timeout: Maximum time to wait for edit button (default: 2 seconds)
    /// - Returns: The edit button element
    @discardableResult
    static func enterProfileEditMode(_ app: XCUIApplication, timeout: TimeInterval = 2) -> XCUIElement {
        let editButton = app.buttons["edit-profile-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: timeout), "Edit profile button should exist")
        editButton.tap()
        return editButton
    }
    
    /// Save profile changes and exit edit mode
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - timeout: Maximum time to wait for save button (default: 2 seconds)
    static func saveProfileChanges(_ app: XCUIApplication, timeout: TimeInterval = 2) {
        let saveButton = app.buttons["save-profile-button"]
        XCTAssertTrue(saveButton.exists, "Save button should exist in edit mode")
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled with valid data")
        saveButton.tap()
        
        // Verify we're back in view mode
        let editButton = app.buttons["edit-profile-button"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3), "Should return to view mode after save")
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    /// Clear existing text and enter new text in a text field
    /// - Parameter text: The text to enter
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
    
    /// Wait for element to exist and be hittable
    /// - Parameters:
    ///   - timeout: Maximum time to wait
    /// - Returns: True if element exists and is hittable within timeout
    func waitForExistenceAndHittable(timeout: TimeInterval) -> Bool {
        return self.waitForExistence(timeout: timeout) && self.isHittable
    }
}