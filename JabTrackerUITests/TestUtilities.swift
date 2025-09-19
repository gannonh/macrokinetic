import XCTest

/// Shared test utilities for UI testing across the JabTracker app
/// Provides common app launch methods and helper functions
enum TestUtilities {
    // MARK: - App Launch Methods

    /// Launch app with UI testing mode enabled
    /// - Bypasses real Sign in with Apple authentication
    /// - Creates mock user data for testing
    /// - Provides full app functionality without external dependencies
    /// - Parameters:
    ///   - resetData: Whether to reset app data for clean state (default: true)
    static func launchAppWithTestMode(resetData: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "true"

        if resetData {
            app.launchArguments = ["--ui-testing", "--reset-app-data"]
        } else {
            app.launchArguments = ["--ui-testing"]
        }

        app.launch()
        return app
    }

    /// Launch app with CloudKit testing mode enabled
    /// - Enables CloudKit sync for testing CloudKit integration
    /// - Uses sandbox CloudKit environment (safe for testing)
    /// - Bypasses real Sign in with Apple authentication with mock user
    /// - Provides full CloudKit sync functionality for integration tests
    /// - Parameters:
    ///   - resetData: Whether to reset app data for clean state (default: true)
    static func launchAppWithCloudKitTestMode(resetData: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "true"

        if resetData {
            app.launchArguments = ["--cloudkit-testing", "--ui-testing", "--reset-app-data"]
        } else {
            app.launchArguments = ["--cloudkit-testing", "--ui-testing"]
        }

        app.launch()
        return app
    }

    /// Launch app for manual UI testing (shows auth UI but mocks Apple ID response)
    /// - Shows real AuthenticationView for manual interaction
    /// - Allows manual testing of UI flows
    /// - Mocks Apple ID authentication response after user interaction
    /// - Perfect for manual testing without requiring real Apple ID credentials
    static func launchAppForManualUITesting() -> XCUIApplication {
        let app = XCUIApplication()
        // Reset app data for clean state
        app.launchArguments.append("--reset-app-data")
        // Special flag for manual UI testing mode
        app.launchArguments.append("--manual-ui-testing")
        // Bypass onboarding for cleaner manual testing flow
        app.launchArguments.append("--bypass-onboarding")
        app.launch()
        return app
    }

    /// Launch app with real authentication (for testing actual Sign in with Apple flow)
    /// - Uses real Apple ID authentication
    /// - Resets app data for clean state
    /// - Bypasses onboarding after successful authentication
    /// - Suitable for testing authentication UI only (cannot complete without real credentials)
    static func launchAppWithRealAuth() -> XCUIApplication {
        let app = XCUIApplication()
        // Reset app data to ensure clean state for authentication testing
        app.launchArguments.append("--reset-app-data")
        // Bypass onboarding after authentication succeeds (for real auth testing)
        app.launchArguments.append("--bypass-onboarding")
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
        additionalEnvironment: [String: String] = [:]) -> XCUIApplication
    {
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
        self.navigateToTab(app, tabName: "Settings")

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
            self.signInWithApple(app)
        }
    }

    /// Perform Sign in with Apple authentication with real credentials
    /// - Parameter app: The XCUIApplication instance
    /// - Note: This uses hardcoded test credentials - should only be used in test environment
    static func signInWithApple(_ app: XCUIApplication) { // swiftlint:disable:this function_body_length
        print("🔐 Starting Sign in with Apple flow")

        // Wait for the sign in screen to appear
        let signInWithAppleButton = app.buttons["sign-in-with-apple-button"]
        self.waitForElement(signInWithAppleButton)
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
        self.waitForSignInButton(app, timeout: timeout)
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

    /// Clear existing text from a text field and optionally enter new text
    /// - Parameters:
    ///   - textField: The XCUIElement text field to clear and update
    ///   - newText: Optional new text to enter after clearing. If nil, field is left empty
    static func clearAndEnterText(in textField: XCUIElement, newText: String? = nil) {
        // Tap to focus the text field
        textField.tap()

        // Clear existing text if any
        if let stringValue = textField.value as? String, !stringValue.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
            textField.typeText(deleteString)
        }

        // Enter new text if provided
        if let newText {
            textField.typeText(newText)
        }
    }

    /// Debug utility to print accessibility hierarchy for troubleshooting element targeting
    /// This is essential for E2E testing as element types and identifiers often differ from expectations
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - searchTerm: Optional search term to filter elements (searches identifiers)
    ///   - prefix: Optional prefix for debug output (default: "🔍 DEBUG")
    static func debugElements(
        in app: XCUIApplication,
        containing searchTerm: String? = nil,
        prefix: String = "🔍 DEBUG"
    ) {
        print("\(prefix): === ACCESSIBILITY HIERARCHY DEBUG ===")

        // Print common element types with their identifiers
        let tables = app.tables.allElementsBoundByIndex.map(\.identifier)
        let scrollViews = app.scrollViews.allElementsBoundByIndex.map(\.identifier)
        let collectionViews = app.collectionViews.allElementsBoundByIndex.map(\.identifier)
        let buttons = app.buttons.allElementsBoundByIndex.map(\.identifier)
        let textFields = app.textFields.allElementsBoundByIndex.map(\.identifier)

        print("\(prefix): Tables: \(tables)")
        print("\(prefix): ScrollViews: \(scrollViews)")
        print("\(prefix): CollectionViews: \(collectionViews)")
        print("\(prefix): Buttons: \(buttons)")
        print("\(prefix): TextFields: \(textFields)")

        // If search term provided, show all matching elements with their types
        if let searchTerm {
            let matchingElements = app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier CONTAINS %@", searchTerm))
                .allElementsBoundByIndex
                .map { "\(self.elementTypeName(from: $0.elementType)):\($0.identifier)" }

            print("\(prefix): Elements containing '\(searchTerm)': \(matchingElements)")
        }

        print("\(prefix): === END DEBUG ===")
    }

    // Note: elementTypeName implementation moved to TestUtilities+ElementTypes.swift extension

    // MARK: - Medication Profile Helpers

    /// Navigate to medication profiles settings
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - timeout: Maximum time to wait for navigation (default: 3 seconds)
    static func navigateToMedicationProfiles(_ app: XCUIApplication, timeout: TimeInterval = 3) {
        // Check if we're already on the Medication Profiles screen
        if app.navigationBars["Medication Profiles"].exists {
            return // Already there, no need to navigate
        }

        self.navigateToTab(app, tabName: "Settings", timeout: timeout)

        let medicationProfilesButton = app.buttons["Medication Profiles"]
        XCTAssertTrue(medicationProfilesButton.waitForExistence(timeout: timeout),
                      "Medication Profiles button should exist")
        medicationProfilesButton.tap()
    }

    /// Create a test medication profile with specified parameters
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - genericName: The generic medication name (default: "semaglutide")
    ///   - brandName: The brand name (default: "Ozempic")
    ///   - dose: The dose amount (default: "0.25")
    ///   - timeout: Maximum time to wait for each UI element (default: 3 seconds)
    /// - Returns: The accessibility identifier for the created profile
    @discardableResult
    static func createMedicationProfile(
        _ app: XCUIApplication,
        genericName: String = "semaglutide",
        brandName: String = "Ozempic",
        dose: String = "0.25",
        timeout: TimeInterval = 3) -> String {
        self.navigateToMedicationProfiles(app, timeout: timeout)

        // Tap the + button in the navigation bar to add a new profile
        let addButton = app.navigationBars["Medication Profiles"].buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: timeout),
                      "Add (+) button should exist in navigation bar")
        addButton.tap()

        // Select medication
        let medicationPicker = app.buttons["medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: timeout),
                      "Medication picker should exist")
        medicationPicker.tap()

        let medicationOption = app.buttons["medication-\(genericName)"]
        XCTAssertTrue(medicationOption.waitForExistence(timeout: timeout),
                      "Medication option \(genericName) should exist")
        medicationOption.tap()

        // Select brand
        let brandPicker = app.buttons["add-brand-picker"]
        XCTAssertTrue(brandPicker.waitForExistence(timeout: timeout),
                      "Brand picker should exist")
        brandPicker.tap()

        let brandOption = app.buttons["add-brand-\(brandName.lowercased())"]
        XCTAssertTrue(brandOption.waitForExistence(timeout: timeout),
                      "Brand option \(brandName) should exist")
        brandOption.tap()

        // Select dose
        let dosePicker = app.buttons["add-dose-picker"]
        XCTAssertTrue(dosePicker.waitForExistence(timeout: timeout),
                      "Dose picker should exist")
        dosePicker.tap()

        let doseOption = app.buttons["add-dose-option-\(String(format: "%.2f", Double(dose) ?? 0.0))"]
        XCTAssertTrue(doseOption.waitForExistence(timeout: timeout),
                      "Dose option \(dose) should exist")
        doseOption.tap()

        // Save profile
        let saveButton = app.buttons["save-medication-profile"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: timeout),
                      "Save button should exist")
        saveButton.tap()

        // Verify profile created and return its identifier
        let doseFormatted = String(format: "%.2f", Double(dose) ?? 0.0)
        let profileIdentifier = "medication-profile-\(genericName)-\(brandName.lowercased())-\(doseFormatted)mg"

        let profileCell = app.buttons[profileIdentifier]
        XCTAssertTrue(profileCell.waitForExistence(timeout: timeout),
                      "Created profile should appear in list")

        return profileIdentifier
    }

    /// Delete a medication profile by its identifier
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - profileIdentifier: The accessibility identifier of the profile to delete
    ///   - timeout: Maximum time to wait for UI elements (default: 3 seconds)
    static func deleteMedicationProfile(_ app: XCUIApplication, profileIdentifier: String, timeout: TimeInterval = 3) {
        let profileCell = app.buttons[profileIdentifier]
        XCTAssertTrue(profileCell.exists, "Profile \(profileIdentifier) should exist before deletion")

        // Swipe to delete (standard iOS pattern)
        profileCell.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: timeout),
                      "Delete button should appear after swipe")
        deleteButton.tap()

        // Verify profile is removed
        XCTAssertFalse(profileCell.waitForExistence(timeout: 1),
                       "Profile should be deleted and no longer exist")
    }

    // MARK: - Dose Creation Helpers

    /// Create a test dose using the Quick Add Dose functionality
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - injectionSite: Optional injection site to select (default: nil, uses default)
    ///   - notes: Optional notes to add (default: nil)
    ///   - timeout: Maximum time to wait for UI elements (default: 3 seconds)
    /// - Returns: True if dose was successfully created
    @discardableResult
    static func createTestDose(
        _ app: XCUIApplication,
        injectionSite: String? = nil,
        notes: String? = nil,
        timeout: TimeInterval = 3) -> Bool {
        // Tap Add tab to open Quick Dose Sheet
        let addTab = app.tabBars.buttons["Add"]
        XCTAssertTrue(addTab.waitForExistence(timeout: timeout), "Add tab should exist")
        addTab.tap()

        // Wait for Quick Dose Sheet to appear
        let quickDoseSheet = app.sheets["quick-dose-sheet"]
        XCTAssertTrue(quickDoseSheet.waitForExistence(timeout: timeout), "Quick dose sheet should open")

        // Set injection site if provided
        if let injectionSite {
            let sitePicker = app.pickers["quick-dose-site-picker"]
            if sitePicker.exists {
                sitePicker.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: injectionSite)
            }
        }

        // Add notes if provided
        if let notes {
            let notesField = app.textFields["quick-dose-notes"]
            if notesField.exists {
                notesField.tap()
                notesField.typeText(notes)
            }
        }

        // Save the dose - try accessibility identifier first, fallback to coordinate tap
        let saveButton = app.buttons["quick-dose-save-button"]
        if saveButton.waitForExistence(timeout: 2) {
            saveButton.tap()
        } else {
            // Fallback: tap at Save button location (top right of sheet)
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.52)).tap()
        }

        // Verify sheet dismissed (dose was saved)
        let dismissed = !quickDoseSheet.waitForExistence(timeout: 1)
        XCTAssertTrue(dismissed, "Quick dose sheet should dismiss after saving dose")

        return dismissed
    }

    /// Create multiple test doses with different timestamps
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - count: Number of doses to create (default: 3)
    ///   - delay: Delay between each dose creation in seconds (default: 0.5)
    ///   - timeout: Maximum time to wait for UI elements (default: 3 seconds)
    static func createMultipleTestDoses(
        _ app: XCUIApplication,
        count: Int = 3,
        delay: TimeInterval = 0.5,
        timeout: TimeInterval = 3)
    {
        for index in 0 ..< count {
            let success = self.createTestDose(app, notes: "Test dose \(index + 1)", timeout: timeout)
            XCTAssertTrue(success, "Should successfully create test dose \(index + 1)")

            // Add delay for different timestamps
            if index < count - 1 {
                Thread.sleep(forTimeInterval: delay)
            }
        }
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
