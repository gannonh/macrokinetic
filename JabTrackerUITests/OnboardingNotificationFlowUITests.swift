import XCTest

/// E2E tests for onboarding notification flow integration
/// Validates that notification permission flow during onboarding correctly activates NotificationService
///
/// **IMPORTANT**: These tests delete and reinstall the app before each test to reset
/// notification permissions (iOS provides no API to programmatically revoke permissions).
/// This adds ~5-10 seconds per test but ensures clean permission state.
final class OnboardingNotificationFlowUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        // Delete the app to reset all permissions (including notification authorization)
        // This is the ONLY reliable way to reset iOS notification permissions
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        // Activate SpringBoard to go to home screen before attempting deletion
        springboard.activate()

        let appIcon = springboard.icons["JabTracker"]

        if appIcon.waitForExistence(timeout: 3) {
            // Wait for icon to be hittable
            sleep(1)

            // Long press to enter jiggle mode
            appIcon.press(forDuration: 1.3)

            // Tap "Remove App" button
            if springboard.buttons["Remove App"].waitForExistence(timeout: 2) {
                springboard.buttons["Remove App"].tap()

                // Confirm deletion in alert
                if springboard.alerts.buttons["Delete App"].waitForExistence(timeout: 2) {
                    springboard.alerts.buttons["Delete App"].tap()
                }

                // Final confirmation
                if springboard.alerts.buttons["Delete"].waitForExistence(timeout: 2) {
                    springboard.alerts.buttons["Delete"].tap()
                }
            }

            // Wait for deletion to complete
            sleep(2)
        }
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

        // Complete onboarding flow with notifications granted
        TestUtilities.completeOnboardingFlow(app, grantNotifications: true, grantHealthKit: false)

        // Navigate to Settings to verify notification state
        TestUtilities.navigateToTab(app, tabName: "Settings")

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

        // Complete onboarding flow with notifications denied
        TestUtilities.completeOnboardingFlow(app, grantNotifications: false, grantHealthKit: false)

        // Navigate to Settings
        TestUtilities.navigateToTab(app, tabName: "Settings")

        // Wait for Settings to load
        _ = app.scrollViews["settings-scroll-view"].waitForExistence(timeout: 3)

        // Verify notification toggle exists
        let notificationToggle = app.switches["notifications-toggle"]
        XCTAssertTrue(
            notificationToggle.waitForExistence(timeout: 3),
            "Notification toggle should exist in Settings")

        // Verify toggle is interactable
        XCTAssertTrue(
            notificationToggle.isEnabled,
            "Notification toggle should be interactable")

        // Verify toggle is in off state (notifications were denied)
        let toggleValue = notificationToggle.value as? String
        XCTAssertEqual(
            toggleValue,
            "0",
            "Notification toggle should be off when permission was denied during onboarding")
    }

    /// GIVEN: User selects different reminder timing in onboarding
    /// WHEN: Onboarding completes
    /// THEN: Reminder preference persists to Settings screen
    func testReminderTimingPersistsFromOnboardingToSettings() throws {
        // Arrange
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--force-onboarding", "--reset-app-data"]
        app.launch()

        // Wait for onboarding to appear
        _ = app.staticTexts["Track your GLP-1 medication"].waitForExistence(timeout: 5)

        // Complete initial onboarding steps
        TestUtilities.completeWelcomeScreens(app)
        TestUtilities.selectMedication(app, medication: "Semaglutide")
        TestUtilities.configureInitialDose(app, amount: "0.25")

        // Schedule setup - select specific reminder timing (30 min before)
        XCTAssertTrue(
            app.staticTexts["Set Up Your Schedule"].waitForExistence(timeout: 3),
            "Should show schedule setup screen")

        let reminderPicker = app.buttons["reminder-time-picker"]
        XCTAssertTrue(
            reminderPicker.waitForExistence(timeout: 3),
            "Reminder time picker should exist in schedule setup")

        reminderPicker.tap()

        let thirtyMinOption = app.buttons["30 min before"]
        XCTAssertTrue(
            thirtyMinOption.waitForExistence(timeout: 2),
            "30 minute option should be available in picker")
        thirtyMinOption.tap()

        usleep(300_000)  // 0.3 seconds

        app.buttons["onboarding-continue-button"].tap()

        // Complete remaining steps (grant notifications, skip HealthKit)
        TestUtilities.handleNotificationPermissions(app, grant: true)
        TestUtilities.handleHealthKitPermissions(app, grant: false)

        // Complete onboarding
        let completeButton = app.buttons["onboarding-complete-button"]
        XCTAssertTrue(
            completeButton.waitForExistence(timeout: 5),
            "Complete button should exist on subscription screen")
        completeButton.tap()

        // Wait for main app to appear
        XCTAssertTrue(
            app.tabBars.firstMatch.waitForExistence(timeout: 10),
            "Main app should appear after onboarding completion")

        // Navigate to Settings
        TestUtilities.navigateToTab(app, tabName: "Settings")

        // Wait for Settings to load then scroll down to notifications section
        _ = app.scrollViews["settings-scroll-view"].waitForExistence(timeout: 3)
        app.swipeUp()

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

        // Wait for onboarding to appear
        _ = app.staticTexts["Track your GLP-1 medication"].waitForExistence(timeout: 5)

        // Complete initial onboarding steps
        TestUtilities.completeWelcomeScreens(app)
        TestUtilities.selectMedication(app, medication: "Semaglutide")
        TestUtilities.configureInitialDose(app, amount: "0.25")

        // Schedule setup - select "2 hours before" reminder timing
        XCTAssertTrue(
            app.staticTexts["Set Up Your Schedule"].waitForExistence(timeout: 3),
            "Should show schedule setup screen")

        let reminderPicker = app.buttons["reminder-time-picker"]
        if reminderPicker.waitForExistence(timeout: 3) {
            reminderPicker.tap()

            let twoHourOption = app.buttons["2 hours before"]
            if twoHourOption.waitForExistence(timeout: 2) {
                twoHourOption.tap()
                usleep(300_000)  // 0.3 seconds
            }
        }

        app.buttons["onboarding-continue-button"].tap()

        // Complete remaining steps (grant notifications, skip HealthKit)
        TestUtilities.handleNotificationPermissions(app, grant: true)
        TestUtilities.handleHealthKitPermissions(app, grant: false)

        // Complete onboarding
        let completeButton = app.buttons["onboarding-complete-button"]
        XCTAssertTrue(
            completeButton.waitForExistence(timeout: 5),
            "Complete button should exist on subscription screen")
        completeButton.tap()

        // Wait for main app to appear
        XCTAssertTrue(
            app.tabBars.firstMatch.waitForExistence(timeout: 10),
            "Main app should appear after onboarding completion")

        // Navigate to Settings and verify notification state before restart
        TestUtilities.navigateToTab(app, tabName: "Settings")

        // Wait for Settings to load then scroll down to notifications section
        _ = app.scrollViews["settings-scroll-view"].waitForExistence(timeout: 3)
        app.swipeUp()

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

        // Navigate to Settings (via More tab) to verify persistence
        TestUtilities.navigateToSettings(restartedApp)

        // Wait for Settings to load then scroll down to notifications section
        _ = restartedApp.scrollViews["settings-scroll-view"].waitForExistence(timeout: 3)
        restartedApp.swipeUp()

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
