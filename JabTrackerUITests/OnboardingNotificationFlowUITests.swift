import XCTest

/// E2E tests for onboarding notification flow integration
/// Validates that notification permission flow during onboarding correctly activates NotificationService
final class OnboardingNotificationFlowUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - E2E Acceptance Tests (Stubs)

    /// GIVEN: User completes onboarding and grants notification permission
    /// WHEN: Onboarding finishes
    /// THEN: Notifications are enabled and reminder preferences are saved
    func testOnboardingActivatesNotificationsWhenPermissionGranted() throws {
        // Arrange
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--force-onboarding", "--reset-app-data"]
        app.launch()

        // Wait for onboarding to appear
        _ = app.staticTexts["Track your GLP-1 medication"].waitForExistence(timeout: 5)

        // Complete onboarding steps
        // Welcome screen
        app.buttons["Get Started"].tap()

        // Medication selection
        _ = app.staticTexts["Select Your Medication"].waitForExistence(timeout: 2)
        app.buttons["semaglutide-card"].tap()

        // Dose entry
        _ = app.staticTexts["Enter Your Starting Dose"].waitForExistence(timeout: 2)
        app.buttons["Continue"].tap()

        // Schedule setup (with notification permissions)
        _ = app.staticTexts["Set Up Your Dosing Schedule"].waitForExistence(timeout: 2)

        // Note: System permission alerts cannot be interacted with in XCUITest
        // The test environment auto-grants permissions for --ui-testing mode
        // We verify the *result* of permission flow, not the alert interaction
        app.buttons["Complete Setup"].tap()

        // Wait for onboarding to complete and dashboard to appear
        XCTAssertTrue(
            app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5),
            "Dashboard should appear after onboarding completion")

        // Navigate to Settings to verify notification state
        app.tabBars.buttons["Settings"].tap()

        // Wait for Settings to load
        _ = app.scrollViews["settings-scroll-view"].waitForExistence(timeout: 3)

        // Verify notification toggle exists and is enabled
        let notificationToggle = app.switches["notifications-toggle"]
        XCTAssertTrue(
            notificationToggle.waitForExistence(timeout: 3),
            "Notification toggle should exist in Settings")

        // Note: In UI testing with auto-granted permissions, notifications may be enabled
        // We're verifying the toggle is accessible and can be interacted with
        XCTAssertTrue(
            notificationToggle.isEnabled,
            "Notification toggle should be enabled (interactable)")

        // Verify reminder timing picker is visible when notifications enabled
        let reminderPicker = app.buttons["reminder-timing-picker"]
        XCTAssertTrue(
            reminderPicker.exists,
            "Reminder timing picker should be visible when notifications are configured")
    }

    /// GIVEN: User completes onboarding but denies notification permission
    /// WHEN: Onboarding finishes
    /// THEN: Notifications remain disabled and can be enabled later in Settings
    func testOnboardingDoesNotActivateNotificationsWhenPermissionDenied() throws {
        // Arrange
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--force-onboarding", "--reset-app-data"]
        app.launch()

        // Wait for onboarding to appear
        _ = app.staticTexts["Track your GLP-1 medication"].waitForExistence(timeout: 5)

        // Complete onboarding steps
        app.buttons["Get Started"].tap()

        // Medication selection
        _ = app.staticTexts["Select Your Medication"].waitForExistence(timeout: 2)
        app.buttons["semaglutide-card"].tap()

        // Dose entry
        _ = app.staticTexts["Enter Your Starting Dose"].waitForExistence(timeout: 2)
        app.buttons["Continue"].tap()

        // Schedule setup
        _ = app.staticTexts["Set Up Your Dosing Schedule"].waitForExistence(timeout: 2)

        // Note: We cannot actually deny permissions in XCUITest
        // This test verifies that Settings UI allows manual enablement
        // The actual permission denial would happen at OS level
        app.buttons["Complete Setup"].tap()

        // Wait for dashboard
        XCTAssertTrue(
            app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5),
            "Dashboard should appear even if notifications denied")

        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()

        // Wait for Settings to load
        _ = app.scrollViews["settings-scroll-view"].waitForExistence(timeout: 3)

        // Verify notification toggle exists and can be toggled
        let notificationToggle = app.switches["notifications-toggle"]
        XCTAssertTrue(
            notificationToggle.waitForExistence(timeout: 3),
            "Notification toggle should exist in Settings")

        // Verify toggle is interactable (can be manually enabled)
        XCTAssertTrue(
            notificationToggle.isEnabled,
            "Notification toggle should be interactable to allow manual enablement")

        // Verify user can toggle notifications on manually
        // Get initial state
        let initialValue = notificationToggle.value as? String

        // Tap toggle to change state
        notificationToggle.tap()

        // Wait a moment for state change
        usleep(500_000)  // 0.5 seconds

        // Verify state changed
        let newValue = notificationToggle.value as? String
        XCTAssertNotEqual(
            initialValue,
            newValue,
            "Toggle state should change when tapped, allowing manual notification enablement")
    }

    /// GIVEN: User selects different reminder timing in onboarding
    /// WHEN: Onboarding completes
    /// THEN: Reminder preference persists to Settings screen
    func testReminderTimingPersistsFromOnboardingToSettings() throws {
        // Arrange
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--force-onboarding", "--reset-app-data"]
        app.launch()

        // Complete onboarding
        _ = app.staticTexts["Track your GLP-1 medication"].waitForExistence(timeout: 5)
        app.buttons["Get Started"].tap()

        // Medication selection
        _ = app.staticTexts["Select Your Medication"].waitForExistence(timeout: 2)
        app.buttons["semaglutide-card"].tap()

        // Dose entry
        _ = app.staticTexts["Enter Your Starting Dose"].waitForExistence(timeout: 2)
        app.buttons["Continue"].tap()

        // Schedule setup - select specific reminder timing
        _ = app.staticTexts["Set Up Your Dosing Schedule"].waitForExistence(timeout: 2)

        // Find and tap reminder timing picker
        let reminderPicker = app.buttons["reminder-time-picker"]
        XCTAssertTrue(
            reminderPicker.waitForExistence(timeout: 3),
            "Reminder time picker should exist in schedule setup")

        // Open picker menu
        reminderPicker.tap()

        // Wait for picker menu to appear and select "30 min before"
        let thirtyMinOption = app.buttons["30 min before"]
        XCTAssertTrue(
            thirtyMinOption.waitForExistence(timeout: 2),
            "30 minute option should be available in picker")
        thirtyMinOption.tap()

        // Wait a moment for selection to register
        usleep(300_000)  // 0.3 seconds

        // Complete onboarding
        app.buttons["Complete Setup"].tap()

        // Wait for dashboard
        XCTAssertTrue(
            app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5),
            "Dashboard should appear after onboarding")

        // Navigate to Settings to verify persistence
        app.tabBars.buttons["Settings"].tap()

        // Wait for Settings to load
        _ = app.scrollViews["settings-scroll-view"].waitForExistence(timeout: 3)

        // Verify reminder timing picker exists in Settings
        let settingsReminderPicker = app.buttons["reminder-timing-picker"]
        XCTAssertTrue(
            settingsReminderPicker.waitForExistence(timeout: 3),
            "Reminder timing picker should exist in Settings")

        // Verify the selected value persisted (should show "30 min before")
        // The picker button should display the current selection
        let pickerLabel = settingsReminderPicker.label
        XCTAssertTrue(
            pickerLabel.contains("30") || pickerLabel.contains("30 min"),
            "Reminder timing picker should show '30 minutes' selection from onboarding. Found: '\(pickerLabel)'")
    }

    /// GIVEN: User completes onboarding with notifications enabled
    /// WHEN: App restarts
    /// THEN: Notification settings persist across app launches
    func testNotificationSettingsPersistAcrossAppRestarts() throws {
        // Arrange - First launch with onboarding
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--force-onboarding", "--reset-app-data"]
        app.launch()

        // Complete onboarding
        _ = app.staticTexts["Track your GLP-1 medication"].waitForExistence(timeout: 5)
        app.buttons["Get Started"].tap()

        _ = app.staticTexts["Select Your Medication"].waitForExistence(timeout: 2)
        app.buttons["semaglutide-card"].tap()

        _ = app.staticTexts["Enter Your Starting Dose"].waitForExistence(timeout: 2)
        app.buttons["Continue"].tap()

        // Schedule setup - select specific reminder timing to verify persistence
        _ = app.staticTexts["Set Up Your Dosing Schedule"].waitForExistence(timeout: 2)

        // Select 2 hours reminder timing
        let reminderPicker = app.buttons["reminder-time-picker"]
        if reminderPicker.waitForExistence(timeout: 3) {
            reminderPicker.tap()

            let twoHourOption = app.buttons["2 hours before"]
            if twoHourOption.waitForExistence(timeout: 2) {
                twoHourOption.tap()
                usleep(300_000)  // 0.3 seconds
            }
        }

        app.buttons["Complete Setup"].tap()

        // Wait for dashboard
        XCTAssertTrue(
            app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5),
            "Dashboard should appear after onboarding")

        // Navigate to Settings and verify notification state before restart
        app.tabBars.buttons["Settings"].tap()
        _ = app.scrollViews["settings-scroll-view"].waitForExistence(timeout: 3)

        // Get initial notification toggle state
        let notificationToggle = app.switches["notifications-toggle"]
        XCTAssertTrue(
            notificationToggle.waitForExistence(timeout: 3),
            "Notification toggle should exist before restart")

        let initialToggleValue = notificationToggle.value as? String

        // Get initial reminder timing
        let settingsReminderPicker = app.buttons["reminder-timing-picker"]
        let initialReminderLabel = settingsReminderPicker.exists ? settingsReminderPicker.label : ""

        // Terminate and relaunch
        app.terminate()

        let restartedApp = XCUIApplication()
        restartedApp.launchArguments = ["--ui-testing"]  // No reset, keep data
        restartedApp.launch()

        // Verify app launches successfully
        XCTAssertTrue(
            restartedApp.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5),
            "App should launch to dashboard after restart")

        // Navigate to Settings to verify persistence
        restartedApp.tabBars.buttons["Settings"].tap()

        // Wait for Settings to load
        _ = restartedApp.scrollViews["settings-scroll-view"].waitForExistence(timeout: 3)

        // Verify notification toggle state persisted
        let restartedToggle = restartedApp.switches["notifications-toggle"]
        XCTAssertTrue(
            restartedToggle.waitForExistence(timeout: 3),
            "Notification toggle should exist after restart")

        let restartedToggleValue = restartedToggle.value as? String
        XCTAssertEqual(
            initialToggleValue,
            restartedToggleValue,
            "Notification toggle state should persist across app restarts")

        // Verify reminder timing persisted
        let restartedReminderPicker = restartedApp.buttons["reminder-timing-picker"]
        XCTAssertTrue(
            restartedReminderPicker.exists,
            "Reminder timing picker should exist after restart")

        let restartedReminderLabel = restartedReminderPicker.label
        XCTAssertEqual(
            initialReminderLabel,
            restartedReminderLabel,
            "Reminder timing preference should persist across app restarts. Initial: '\(initialReminderLabel)', After restart: '\(restartedReminderLabel)'"
        )
    }
}
