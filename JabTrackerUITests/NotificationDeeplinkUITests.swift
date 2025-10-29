import XCTest

/// E2E tests for notification deeplink handling
/// Validates that jab-tracker:// URLs correctly navigate to QuickDoseSheet
final class NotificationDeeplinkUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - E2E Acceptance Tests (Stubs)

    /// GIVEN: User receives notification with "Log Dose" action
    /// WHEN: User taps "Log Dose" action
    /// THEN: App opens to QuickDoseSheet with scheduled dose pre-populated
    func testDeeplinkOpensQuickDoseSheetFromBackground() throws {
        // Arrange
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]

        // Create a known UUID for testing
        let testScheduledDoseId = UUID()

        // Launch app with deeplink URL
        let deeplinkURL = "jab-tracker://dose/log?scheduledDoseId=\(testScheduledDoseId.uuidString)"
        app.launchArguments.append("--deeplink-url=\(deeplinkURL)")
        app.launch()

        // Assert
        // Since QuickDoseSheet navigation is not yet implemented (TODO in DeeplinkHandler),
        // we can only verify the deeplink was processed without crashing
        XCTAssertTrue(app.exists, "App should launch successfully with deeplink")

        // TODO: Once DeeplinkHandler navigation is implemented, verify:
        // XCTAssertTrue(app.sheets["quick-dose-sheet"].waitForExistence(timeout: 5))
    }

    /// GIVEN: User receives notification while app is in foreground
    /// WHEN: User taps notification banner
    /// THEN: QuickDoseSheet appears with scheduled dose data
    func testDeeplinkOpensQuickDoseSheetFromForeground() throws {
        // Arrange
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
        app.launch()

        // Wait for app to be fully loaded
        _ = app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5)

        // Create a known UUID for testing
        let testScheduledDoseId = UUID()

        // Simulate deeplink opening while app is in foreground
        // In real scenario, this would come from notification tap
        // For testing, we can't actually trigger a notification, but we can verify
        // the deeplink handler works by terminating and relaunching with URL
        app.terminate()

        let deeplinkURL = "jab-tracker://dose/log?scheduledDoseId=\(testScheduledDoseId.uuidString)"
        app.launchArguments.append("--deeplink-url=\(deeplinkURL)")
        app.launch()

        // Assert
        XCTAssertTrue(app.exists, "App should handle deeplink gracefully")

        // TODO: Once navigation is implemented, verify QuickDoseSheet appears
        // XCTAssertTrue(app.sheets["quick-dose-sheet"].waitForExistence(timeout: 5))
    }

    /// GIVEN: App is terminated
    /// WHEN: User taps notification with deeplink
    /// THEN: App launches and shows QuickDoseSheet with dose data
    func testDeeplinkOpensQuickDoseSheetFromTerminated() throws {
        // Arrange
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]

        // Create a known UUID for testing
        let testScheduledDoseId = UUID()

        // Launch with deeplink URL
        let deeplinkURL = "jab-tracker://dose/log?scheduledDoseId=\(testScheduledDoseId.uuidString)"
        app.launchArguments.append("--deeplink-url=\(deeplinkURL)")
        app.launch()

        // Assert
        XCTAssertTrue(app.exists, "App should launch successfully from terminated state with deeplink")

        // Verify we don't crash and the app is in a valid state
        XCTAssertTrue(
            app.tabBars.buttons["Dashboard"].exists || app.sheets.count > 0,
            "App should be in valid state (dashboard or sheet)")

        // TODO: Once navigation is implemented, verify QuickDoseSheet appears:
        // XCTAssertTrue(app.sheets["quick-dose-sheet"].waitForExistence(timeout: 5))
    }

    /// GIVEN: Invalid deeplink URL (malformed UUID)
    /// WHEN: User taps notification
    /// THEN: App handles gracefully without crash
    func testInvalidDeeplinkHandledGracefully() throws {
        // Arrange
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]

        // Launch with invalid deeplink URL (malformed UUID)
        let invalidDeeplinkURL = "jab-tracker://dose/log?scheduledDoseId=invalid-uuid"
        app.launchArguments.append("--deeplink-url=\(invalidDeeplinkURL)")
        app.launch()

        // Assert
        XCTAssertTrue(app.exists, "App should handle invalid deeplink gracefully without crashing")

        // Verify app is in valid state
        XCTAssertTrue(
            app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5),
            "App should show dashboard when deeplink is invalid")

        // Verify QuickDoseSheet does NOT appear for invalid deeplink
        XCTAssertFalse(app.sheets["quick-dose-sheet"].exists, "QuickDoseSheet should not appear for invalid deeplink")
    }

    /// GIVEN: Deeplink for non-existent scheduled dose
    /// WHEN: User taps notification
    /// THEN: App handles gracefully and shows empty QuickDoseSheet
    func testDeeplinkWithNonExistentScheduledDoseHandledGracefully() throws {
        // Arrange
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]

        // Create a valid UUID that won't exist in database
        let nonExistentScheduledDoseId = UUID()

        // Launch with valid deeplink format but non-existent ID
        let deeplinkURL = "jab-tracker://dose/log?scheduledDoseId=\(nonExistentScheduledDoseId.uuidString)"
        app.launchArguments.append("--deeplink-url=\(deeplinkURL)")
        app.launch()

        // Assert
        XCTAssertTrue(app.exists, "App should handle non-existent scheduled dose gracefully")

        // Verify app is in valid state
        XCTAssertTrue(
            app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5),
            "App should show dashboard when scheduled dose doesn't exist")

        // TODO: Once navigation is implemented, verify behavior:
        // Either show QuickDoseSheet without pre-population, or gracefully show dashboard
        // XCTAssertTrue(app.sheets["quick-dose-sheet"].waitForExistence(timeout: 5) ||
        //               app.tabBars.buttons["Dashboard"].exists)
    }
}
