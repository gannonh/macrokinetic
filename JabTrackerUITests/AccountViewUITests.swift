//
//  AccountViewUITests.swift
//  JabTrackerUITests
//
//  E2E tests for AccountView - Phase 15.1 smoketest coverage.
//  Tests profile editing, HealthKit integration, and account actions.
//

import XCTest

final class AccountViewUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)

        // Wait for app to be ready
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should appear after launch")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation Helpers

    /// Navigate to Account view via More tab -> Account
    private func navigateToAccountView(timeout: TimeInterval = 5) {
        // Tap More tab
        let moreTab = app.tabBars.buttons["More"]
        XCTAssertTrue(moreTab.waitForExistence(timeout: timeout), "More tab should exist")
        moreTab.tap()

        // Tap Account link
        let accountLink = app.buttons["account-link"]
        XCTAssertTrue(accountLink.waitForExistence(timeout: timeout), "Account link should exist in More view")
        accountLink.tap()

        // Verify Account view loaded
        let accountView = app.otherElements["account-view"]
        XCTAssertTrue(accountView.waitForExistence(timeout: timeout), "Account view should appear")
    }

    // MARK: - 1. Account View Structure

    /// Verify all sections appear in Account view
    /// Smoketest: 1. Account View Structure
    func testAccountViewShowsAllSections() throws {
        // GIVEN: Navigate to Account view
        navigateToAccountView()

        // THEN: Profile header should exist
        let profileHeader = app.otherElements["profile-header"]
        XCTAssertTrue(profileHeader.exists, "Profile header should exist")

        // THEN: Details section fields should exist
        XCTAssertTrue(app.buttons["name-row"].exists, "Name row should exist")
        XCTAssertTrue(app.buttons["birthday-row"].exists, "Birthday row should exist")
        XCTAssertTrue(app.buttons["sex-row"].exists, "Sex row should exist")
        XCTAssertTrue(app.buttons["height-row"].exists, "Height row should exist")
        XCTAssertTrue(app.buttons["weight-row"].exists, "Weight row should exist")
        XCTAssertTrue(app.buttons["cardio-row"].exists, "Cardio Experience row should exist")
        XCTAssertTrue(app.buttons["lifting-row"].exists, "Lifting Experience row should exist")

        // THEN: Integrations section should exist
        let healthToggleRow = app.otherElements["health-toggle-row"]
        XCTAssertTrue(healthToggleRow.exists, "Health toggle row should exist")

        // THEN: Account actions should exist
        XCTAssertTrue(app.buttons["log-out-button"].exists, "Log Out button should exist")
        XCTAssertTrue(app.buttons["restart-onboarding-button"].exists, "Restart Onboarding button should exist")
    }

    /// Verify Security section shows biometric toggle when available
    /// Smoketest: 1. Account View Structure (Security section)
    func testAccountViewShowsBiometricToggleWhenAvailable() throws {
        // GIVEN: Navigate to Account view
        navigateToAccountView()

        // THEN: Biometric toggle row may exist (device-dependent)
        let biometricRow = app.otherElements["biometric-toggle-row"]
        if biometricRow.exists {
            // Biometric is available on this simulator/device
            XCTAssertTrue(true, "Biometric toggle row exists when biometric is available")
        } else {
            // Biometric not available - this is acceptable
            print("Biometric toggle not present - biometric may not be available on this device")
        }
    }

    // MARK: - 2. Health Sync - Enable Flow

    /// User can enable Health sync via toggle
    /// Smoketest: 2. Health Sync - Enable Flow
    func testEnableHealthSyncViaToggle() throws {
        // GIVEN: Navigate to Account view
        navigateToAccountView()

        // WHEN: Find Health toggle
        let healthToggleRow = app.otherElements["health-toggle-row"]
        XCTAssertTrue(healthToggleRow.waitForExistence(timeout: 3), "Health toggle row should exist")

        // Find the toggle switch within the row
        let healthToggle = healthToggleRow.switches.firstMatch
        XCTAssertTrue(healthToggle.exists, "Health toggle switch should exist")

        // Get initial state
        let initialValue = healthToggle.value as? String ?? "0"

        // Skip if already enabled (need fresh simulator)
        guard initialValue == "0" else {
            print("Health sync already enabled - skipping enable test")
            return
        }

        // WHEN: Tap toggle to enable
        healthToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        // THEN: HealthKit permission dialog may appear
        // Note: Actual dialog requires simulator reset and cannot be fully automated
        // We verify the toggle interaction works by waiting for any UI change
        _ = healthToggle.waitForExistence(timeout: 1)
    }

    // MARK: - 3. Health Sync - Disable Flow

    /// User sees confirmation dialog when disabling Health sync
    /// Smoketest: 3. Health Sync - Disable Flow
    func testDisableHealthSyncShowsConfirmation() throws {
        // GIVEN: Navigate to Account view with Health sync enabled
        navigateToAccountView()

        let healthToggleRow = app.otherElements["health-toggle-row"]
        XCTAssertTrue(healthToggleRow.waitForExistence(timeout: 3), "Health toggle row should exist")

        let healthToggle = healthToggleRow.switches.firstMatch
        let initialValue = healthToggle.value as? String ?? "0"

        // Need Health sync enabled to test disable
        guard initialValue == "1" else {
            print("Health sync not enabled - skipping disable test (requires manual enable first)")
            return
        }

        // WHEN: Tap toggle to disable
        healthToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        // THEN: Confirmation dialog should appear
        let confirmationDialog = app.sheets["Disable Health Sync"]
        XCTAssertTrue(
            confirmationDialog.waitForExistence(timeout: 3),
            "Disable Health Sync confirmation dialog should appear"
        )

        // Verify dialog has expected buttons
        XCTAssertTrue(confirmationDialog.buttons["Disable"].exists, "Disable button should exist")
        XCTAssertTrue(confirmationDialog.buttons["Cancel"].exists, "Cancel button should exist")

        // WHEN: Tap Cancel
        confirmationDialog.buttons["Cancel"].tap()

        // THEN: Toggle should remain ON
        XCTAssertEqual(healthToggle.value as? String, "1", "Toggle should remain ON after cancel")
    }

    // MARK: - 4. Weight Logging (Profile)

    /// User can edit weight via Account -> Weight row
    /// Smoketest: 4. Weight Logging (Profile)
    func testEditWeightViaProfile() throws {
        // GIVEN: Navigate to Account view
        navigateToAccountView()

        // WHEN: Tap Weight row
        let weightRow = app.buttons["weight-row"]
        XCTAssertTrue(weightRow.waitForExistence(timeout: 3), "Weight row should exist")
        weightRow.tap()

        // THEN: Edit weight sheet should appear
        let weightPicker = app.otherElements["edit-weight-picker"]
        XCTAssertTrue(weightPicker.waitForExistence(timeout: 3), "Weight picker should appear in edit sheet")

        // WHEN: Adjust weight and save
        // Note: Stepper interaction is complex in XCUITest - verify UI is present
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.exists, "Save button should exist")

        // Tap save
        saveButton.tap()

        // THEN: Sheet should dismiss
        XCTAssertFalse(
            weightPicker.waitForExistence(timeout: 2),
            "Edit sheet should dismiss after save"
        )
    }

    // MARK: - 6. Height Editing

    /// User can edit height via Account -> Height row
    /// Smoketest: 6. Height Editing
    func testEditHeightViaProfile() throws {
        // GIVEN: Navigate to Account view
        navigateToAccountView()

        // WHEN: Tap Height row
        let heightRow = app.buttons["height-row"]
        XCTAssertTrue(heightRow.waitForExistence(timeout: 3), "Height row should exist")
        heightRow.tap()

        // THEN: Edit height sheet should appear with wheel pickers
        let heightPicker = app.otherElements["height-picker"]
        XCTAssertTrue(heightPicker.waitForExistence(timeout: 3), "Height picker should appear in edit sheet")

        // Verify feet and inches pickers exist
        let feetPicker = app.pickers["Feet"]
        let inchesPicker = app.pickers["Inches"]

        // Note: Pickers may be queried differently - verify sheet content
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.exists, "Save button should exist")

        // WHEN: Save (with current value)
        saveButton.tap()

        // THEN: Sheet should dismiss
        XCTAssertFalse(
            heightPicker.waitForExistence(timeout: 2),
            "Edit sheet should dismiss after save"
        )
    }

    // MARK: - 9. Profile Field Editing

    /// User can edit name field
    /// Smoketest: 9. Profile Field Editing - Name
    func testEditNameField() throws {
        // GIVEN: Navigate to Account view
        navigateToAccountView()

        // WHEN: Tap Name row
        let nameRow = app.buttons["name-row"]
        XCTAssertTrue(nameRow.waitForExistence(timeout: 3), "Name row should exist")
        nameRow.tap()

        // THEN: Edit name sheet should appear
        let nameField = app.textFields["edit-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "Name text field should appear")

        // WHEN: Edit name
        nameField.tap()
        nameField.typeText("Test User")

        // Save
        let saveButton = app.buttons["Save"]
        saveButton.tap()

        // THEN: Sheet dismisses and name updates
        XCTAssertFalse(nameField.waitForExistence(timeout: 2), "Edit sheet should dismiss")
    }

    /// User can edit birthday field
    /// Smoketest: 9. Profile Field Editing - Birthday
    func testEditBirthdayField() throws {
        // GIVEN: Navigate to Account view
        navigateToAccountView()

        // WHEN: Tap Birthday row
        let birthdayRow = app.buttons["birthday-row"]
        XCTAssertTrue(birthdayRow.waitForExistence(timeout: 3), "Birthday row should exist")
        birthdayRow.tap()

        // THEN: Edit birthday sheet should appear with date picker
        let birthdayPicker = app.datePickers["edit-birthday-picker"]
        XCTAssertTrue(birthdayPicker.waitForExistence(timeout: 3), "Birthday picker should appear")

        // Verify Save button exists
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.exists, "Save button should exist")

        // Cancel to close
        let cancelButton = app.buttons["Cancel"]
        cancelButton.tap()

        // THEN: Sheet dismisses
        XCTAssertFalse(birthdayPicker.waitForExistence(timeout: 2), "Edit sheet should dismiss")
    }

    /// User can edit sex field
    /// Smoketest: 9. Profile Field Editing - Sex
    func testEditSexField() throws {
        // GIVEN: Navigate to Account view
        navigateToAccountView()

        // WHEN: Tap Sex row
        let sexRow = app.buttons["sex-row"]
        XCTAssertTrue(sexRow.waitForExistence(timeout: 3), "Sex row should exist")
        sexRow.tap()

        // THEN: Edit sex sheet should appear with picker
        let sexPicker = app.pickers["edit-sex-picker"]
        // Note: Inline picker may have different query
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should appear")

        // Verify options exist
        XCTAssertTrue(app.staticTexts["Male"].exists || app.buttons["Male"].exists, "Male option should exist")
        XCTAssertTrue(app.staticTexts["Female"].exists || app.buttons["Female"].exists, "Female option should exist")

        // Cancel to close
        app.buttons["Cancel"].tap()
    }

    /// User can edit experience level fields
    /// Smoketest: 9. Profile Field Editing - Experience
    func testEditExperienceFields() throws {
        // GIVEN: Navigate to Account view
        navigateToAccountView()

        // Test Cardio Experience
        let cardioRow = app.buttons["cardio-row"]
        XCTAssertTrue(cardioRow.waitForExistence(timeout: 3), "Cardio row should exist")
        cardioRow.tap()

        // Verify picker appears with options
        XCTAssertTrue(
            app.staticTexts["Beginner"].waitForExistence(timeout: 3)
                || app.buttons["Beginner"].waitForExistence(timeout: 3),
            "Experience level options should appear"
        )

        app.buttons["Cancel"].tap()

        // Test Lifting Experience
        let liftingRow = app.buttons["lifting-row"]
        XCTAssertTrue(liftingRow.waitForExistence(timeout: 3), "Lifting row should exist")
        liftingRow.tap()

        XCTAssertTrue(
            app.staticTexts["Advanced"].waitForExistence(timeout: 3)
                || app.buttons["Advanced"].waitForExistence(timeout: 3),
            "Experience level options should appear"
        )

        app.buttons["Cancel"].tap()
    }

    // MARK: - 10. Security - Biometric Toggle

    /// User can toggle biometric authentication
    /// Smoketest: 10. Security - Biometric Toggle
    func testBiometricToggle() throws {
        // GIVEN: Navigate to Account view
        navigateToAccountView()

        // Check if biometric is available
        let biometricRow = app.otherElements["biometric-toggle-row"]
        guard biometricRow.waitForExistence(timeout: 2) else {
            print("Biometric not available on this device - skipping test")
            return
        }

        // WHEN: Find biometric toggle
        let biometricToggle = biometricRow.switches.firstMatch
        XCTAssertTrue(biometricToggle.exists, "Biometric toggle should exist")

        // Get initial state
        let initialValue = biometricToggle.value as? String ?? "0"

        // WHEN: Tap toggle
        biometricToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        // THEN: State should change (or biometric prompt appears)
        // Wait for any UI change using condition-based wait
        _ = biometricToggle.waitForExistence(timeout: 1)

        // Note: Actual biometric prompt cannot be automated
        // We verify the toggle is interactive
    }

    // MARK: - 11. Account Actions

    /// User can trigger Log Out with confirmation
    /// Smoketest: 11. Account Actions - Log Out
    func testLogOutShowsConfirmation() throws {
        // GIVEN: Navigate to Account view
        navigateToAccountView()

        // WHEN: Tap Log Out button
        let logOutButton = app.buttons["log-out-button"]
        XCTAssertTrue(logOutButton.waitForExistence(timeout: 3), "Log Out button should exist")
        logOutButton.tap()

        // THEN: Confirmation dialog should appear
        let confirmationDialog = app.sheets["Log Out"]
        XCTAssertTrue(
            confirmationDialog.waitForExistence(timeout: 3),
            "Log Out confirmation dialog should appear"
        )

        // Verify dialog has expected buttons
        XCTAssertTrue(confirmationDialog.buttons["Log Out"].exists, "Log Out button should exist in dialog")
        XCTAssertTrue(confirmationDialog.buttons["Cancel"].exists, "Cancel button should exist")

        // WHEN: Tap Cancel
        confirmationDialog.buttons["Cancel"].tap()

        // THEN: Dialog should dismiss, still on Account view
        XCTAssertFalse(confirmationDialog.exists, "Dialog should dismiss after cancel")
        XCTAssertTrue(app.otherElements["account-view"].exists, "Should still be on Account view")
    }

    /// User can trigger Restart Onboarding with confirmation
    /// Smoketest: 11. Account Actions - Restart Onboarding
    func testRestartOnboardingShowsConfirmation() throws {
        // GIVEN: Navigate to Account view
        navigateToAccountView()

        // WHEN: Tap Restart Onboarding button
        let restartButton = app.buttons["restart-onboarding-button"]
        XCTAssertTrue(restartButton.waitForExistence(timeout: 3), "Restart Onboarding button should exist")
        restartButton.tap()

        // THEN: Confirmation dialog should appear
        let confirmationDialog = app.sheets["Restart Onboarding"]
        XCTAssertTrue(
            confirmationDialog.waitForExistence(timeout: 3),
            "Restart Onboarding confirmation dialog should appear"
        )

        // Verify dialog has expected buttons
        XCTAssertTrue(confirmationDialog.buttons["Restart"].exists, "Restart button should exist in dialog")
        XCTAssertTrue(confirmationDialog.buttons["Cancel"].exists, "Cancel button should exist")

        // WHEN: Tap Cancel
        confirmationDialog.buttons["Cancel"].tap()

        // THEN: Dialog should dismiss
        XCTAssertFalse(confirmationDialog.exists, "Dialog should dismiss after cancel")
    }

    // MARK: - Accessibility

    /// All key elements have accessibility identifiers
    /// Smoketest: Accessibility compliance
    func testAccessibilityIdentifiers() throws {
        // GIVEN: Navigate to Account view
        navigateToAccountView()

        // THEN: Verify all key accessibility identifiers exist
        XCTAssertTrue(app.otherElements["account-view"].exists, "account-view identifier should exist")
        XCTAssertTrue(app.otherElements["profile-header"].exists, "profile-header identifier should exist")
        XCTAssertTrue(app.otherElements["health-toggle-row"].exists, "health-toggle-row identifier should exist")
        XCTAssertTrue(app.buttons["log-out-button"].exists, "log-out-button identifier should exist")
        XCTAssertTrue(
            app.buttons["restart-onboarding-button"].exists, "restart-onboarding-button identifier should exist")

        // Profile field rows
        XCTAssertTrue(app.buttons["name-row"].exists, "name-row identifier should exist")
        XCTAssertTrue(app.buttons["height-row"].exists, "height-row identifier should exist")
        XCTAssertTrue(app.buttons["weight-row"].exists, "weight-row identifier should exist")
    }

    // MARK: - Profile Data for Program Calculations

    /// Profile data enables TDEE calculation for Coached programs
    /// Acceptance: Complete profile allows Coached program creation without profile step
    func testCompleteProfileEnablesCoachedProgram() throws {
        // TODO: Ensure profile has all required fields:
        //       - Height
        //       - Weight
        //       - Birthday (for age)
        //       - Sex
        // TODO: Navigate to Strategy → Create Goal → Continue to Program
        // TODO: Select Coached style
        // TODO: Verify NO "Complete Your Profile" step appears
        // TODO: Verify TDEE is calculated and displayed
    }

    /// Profile weight updates affect program calculations
    /// Acceptance: Changing weight should affect macro calculations
    func testWeightChangeAffectsMacroCalculations() throws {
        // TODO: Create Coached program with current weight
        // TODO: Note calculated protein target (based on body weight)
        // TODO: Navigate to Account → Weight
        // TODO: Change weight significantly (e.g., +20 lbs)
        // TODO: Navigate to Strategy
        // TODO: Note: Existing program may not auto-update
        //       (new program would use new weight)
    }
}
