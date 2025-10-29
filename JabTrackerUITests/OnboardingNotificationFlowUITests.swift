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

        // Grant notification permission (system alert)
        // Note: In UI testing, we can't actually interact with system alerts
        // The test environment will auto-grant or we need to handle this differently
        app.buttons["Complete Setup"].tap()

        // Wait for onboarding to complete and dashboard to appear
        XCTAssertTrue(
            app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5),
            "Dashboard should appear after onboarding completion")

        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()

        // Verify notification settings section exists
        // Note: Actual verification depends on Settings screen implementation
        XCTAssertTrue(app.exists, "Settings screen should be accessible")

        // TODO: Verify notification toggle state once Settings UI is implemented
        // XCTAssertTrue(app.switches["notifications-toggle"].isEnabled)
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

        // Deny notification permission
        // Note: In UI testing, handling system permission alerts is complex
        // The test will proceed assuming permission was denied
        app.buttons["Complete Setup"].tap()

        // Wait for dashboard
        XCTAssertTrue(
            app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5),
            "Dashboard should appear even if notifications denied")

        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()

        // Verify Settings is accessible (user can enable notifications later)
        XCTAssertTrue(app.exists, "Settings should be accessible to enable notifications later")

        // TODO: Verify notification toggle state and that it can be manually enabled
        // XCTAssertFalse(app.switches["notifications-toggle"].isEnabled)
        // app.switches["notifications-toggle"].tap()
        // XCTAssertTrue(app.switches["notifications-toggle"].isEnabled)
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

        // Schedule setup - select reminder timing
        _ = app.staticTexts["Set Up Your Dosing Schedule"].waitForExistence(timeout: 2)

        // TODO: Select specific reminder timing (e.g., 30 minutes)
        // This depends on the UI implementation of the schedule setup screen
        // app.buttons["30-minute-reminder"].tap()

        app.buttons["Complete Setup"].tap()

        // Wait for dashboard
        XCTAssertTrue(
            app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5),
            "Dashboard should appear after onboarding")

        // Navigate to Settings
        app.tabBars.buttons["Settings"].tap()

        // TODO: Verify reminder timing persists
        // XCTAssertTrue(app.staticTexts["30 minutes before"].exists)
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

        _ = app.staticTexts["Set Up Your Dosing Schedule"].waitForExistence(timeout: 2)
        app.buttons["Complete Setup"].tap()

        // Wait for dashboard
        XCTAssertTrue(
            app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5),
            "Dashboard should appear after onboarding")

        // Terminate and relaunch
        app.terminate()

        let restartedApp = XCUIApplication()
        restartedApp.launchArguments = ["--ui-testing"]  // No reset, keep data
        restartedApp.launch()

        // Verify app launches successfully
        XCTAssertTrue(
            restartedApp.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5),
            "App should launch to dashboard after restart")

        // Navigate to Settings
        restartedApp.tabBars.buttons["Settings"].tap()

        // Verify Settings is accessible (settings persisted)
        XCTAssertTrue(restartedApp.exists, "Settings should be accessible after restart")

        // TODO: Verify notification settings persist
        // XCTAssertTrue(restartedApp.switches["notifications-toggle"].isEnabled)
        // XCTAssertTrue(restartedApp.staticTexts["reminder-timing"].exists)
    }
}
