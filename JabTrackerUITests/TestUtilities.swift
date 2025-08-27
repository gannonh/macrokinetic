import XCTest

/// Shared test utilities for UI testing across the JabTracker app
/// Provides common app launch methods and helper functions
enum TestUtilities {
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
        additionalEnvironment: [String: String] = [:]) -> XCUIApplication {
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

        // Wait briefly for the Apple ID authentication sheet
        sleep(1) // Reduced from 2 seconds - give minimal time for system sheet to appear
        print("⏳ Waiting for Apple ID sheet")

        // Wait for Apple ID sheet to load
        sleep(2)

        // Handle the Apple ID authentication sheet - only the contexts that actually work
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let mainApp = XCUIApplication()

        // Check available authentication options
        let continueWithPasswordButton = springboard.buttons["Continue with Password"]
        let siwaButton = mainApp.buttons["SIWA_CONTINUE_BUTTON"]

        print("🔍 Checking authentication options:")
        print("  SpringBoard 'Continue with Password': \(continueWithPasswordButton.exists)")
        print("  MainApp 'SIWA_CONTINUE_BUTTON': \(siwaButton.exists)")

        // Case 1: SpringBoard "Continue with Password" (proven to work)
        if continueWithPasswordButton.waitForExistence(timeout: 2) {
            print("🔑 Found Continue with Password button")
            continueWithPasswordButton.tap()
            print("✅ Tapped Continue with Password button")
            sleep(1)

            // Enter password in SpringBoard context
            let passwordField = springboard.secureTextFields.firstMatch
            if passwordField.waitForExistence(timeout: 3) {
                passwordField.tap()
                passwordField.typeText("S3cr3t77!")
                print("🔒 Entered password")

                let signInButton = springboard.buttons["Sign In"]
                if signInButton.waitForExistence(timeout: 2) {
                    signInButton.tap()
                    print("✅ Tapped Sign In button")

                    // Wait for authentication to complete and return to app
                    let tabBar = mainApp.tabBars.firstMatch
                    if tabBar.waitForExistence(timeout: 10) {
                        print("🎉 Sign in flow completed successfully")
                        return
                    }
                }
            }

            print("❌ SpringBoard authentication flow failed")
            XCTFail("Apple ID authentication failed in SpringBoard context")
            return
        } else if siwaButton.waitForExistence(timeout: 2) {
            print("🔑 Found SIWA_CONTINUE_BUTTON")
            siwaButton.tap()
            print("✅ Tapped SIWA_CONTINUE_BUTTON")
            sleep(2)

            // Check if authentication completed
            let tabBar = mainApp.tabBars.firstMatch
            if tabBar.waitForExistence(timeout: 10) {
                print("🎉 Sign in flow completed successfully")
                return
            }

            print("❌ MainApp SIWA flow failed")
            XCTFail("Apple ID authentication failed in MainApp SIWA context")
            return
        } else {
            // No authentication elements found
            print("❌ No authentication elements found")

            // Debug: Show what's available
            print("🔍 Available SpringBoard buttons:")
            let allButtons = springboard.buttons.allElementsBoundByIndex
            for (index, button) in allButtons.prefix(5).enumerated() {
                print("  Button \(index): '\(button.label)' - exists: \(button.exists)")
            }

            XCTFail("Apple ID authentication failed - no expected authentication elements found")
            return
        }

        // If we reach here without returning early, authentication may have failed
        print("❌ Sign in flow completed with unknown result - authentication may have failed")
        XCTFail("Apple ID authentication completed but result is unknown - check logs for issues")
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
            usleep(100_000) // Sleep for 100ms to prevent tight spinning
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
            usleep(100_000) // Sleep for 100ms to prevent tight spinning
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
    static func saveProfileChanges(_ app: XCUIApplication, timeout _: TimeInterval = 2) {
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
        guard elementType == .textField else { return }

        tap()
        press(forDuration: 1.0)

        let selectAll = XCUIApplication().menuItems["Select All"]
        if selectAll.exists {
            selectAll.tap()
        }

        typeText(text)
    }

    /// Wait for element to exist and be hittable
    /// - Parameters:
    ///   - timeout: Maximum time to wait
    /// - Returns: True if element exists and is hittable within timeout
    func waitForExistenceAndHittable(timeout: TimeInterval) -> Bool {
        waitForExistence(timeout: timeout) && isHittable
    }
}
