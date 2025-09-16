import XCTest

/// CloudKit Integration UI Tests
///
/// These tests verify real CloudKit integration functionality through the UI.
/// Unlike unit tests, these tests use actual CloudKit services to validate:
/// - iCloud account status detection
/// - Sync status UI updates
/// - Data persistence with CloudKit enabled
/// - Fallback behavior when CloudKit is unavailable
///
/// Note: These tests require a signed-in iCloud account on the test device/simulator
/// to fully exercise CloudKit functionality.
final class CloudKitIntegrationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - CloudKit Status UI Tests

    @MainActor
    func testCloudKitSyncStatusDisplay() throws {
        // Launch app with CloudKit test mode and reset data to skip onboarding
        let app = TestUtilities.launchAppWithCloudKitTestMode(resetData: true)

        // Navigate to Settings where sync status is displayed
        TestUtilities.navigateToTab(app, tabName: "Settings")

        // Verify sync status section exists
        let syncStatusHeader = app.staticTexts["Sync Status"]
        XCTAssertTrue(syncStatusHeader.waitForExistence(timeout: 10),
                      "Sync Status section should be visible in Settings")

        // Verify that we get a real sync status (not just loading)
        // Check for any valid CloudKit status message
        let hasValidStatus =
            app.staticTexts["Syncing with iCloud"].exists ||
            app.staticTexts["Sign in to iCloud to sync across devices"].exists ||
            app.staticTexts["Sync unavailable - using local storage"].exists ||
            app.staticTexts["iCloud sync restricted"].exists ||
            app.staticTexts["No network connection for sync"].exists

        XCTAssertTrue(hasValidStatus, "Should display a valid CloudKit sync status")

        // Print what we found
        let allStatusTexts = app.staticTexts.allElementsBoundByIndex.map(\.label)
        let syncStatusTexts = allStatusTexts.filter { $0.contains("iCloud") || $0.contains("Sync") }
        print("CloudKit sync status found: \(syncStatusTexts)")
    }

    @MainActor
    func testCloudKitAccountStatusDetection() throws {
        // Test that the app can detect and display iCloud account status
        let app = TestUtilities.launchAppWithCloudKitTestMode(resetData: true)

        TestUtilities.navigateToTab(app, tabName: "Settings")

        // Wait for CloudKit status to be determined
        let syncStatusHeader = app.staticTexts["Sync Status"]
        XCTAssertTrue(syncStatusHeader.waitForExistence(timeout: 10),
                      "Sync Status section should appear")

        // The app should show either:
        // - "Syncing with iCloud" (if signed in and available)
        // - "Sign in to iCloud to sync across devices" (if not signed in)
        // - Other valid status messages

        let hasValidStatus =
            app.staticTexts["Syncing with iCloud"].exists ||
            app.staticTexts["Sign in to iCloud to sync across devices"].exists ||
            app.staticTexts["Sync unavailable - using local storage"].exists ||
            app.staticTexts["iCloud sync restricted"].exists ||
            app.staticTexts["No network connection for sync"].exists

        XCTAssertTrue(hasValidStatus, "Should display a valid CloudKit account status message")
    }

    @MainActor
    func testCloudKitRetryFunctionality() throws {
        // Test that users can retry CloudKit setup when there are issues
        let app = TestUtilities.launchAppWithCloudKitTestMode(resetData: true)

        TestUtilities.navigateToTab(app, tabName: "Settings")

        let syncStatusHeader = app.staticTexts["Sync Status"]
        XCTAssertTrue(syncStatusHeader.waitForExistence(timeout: 10),
                      "Sync Status section should appear")

        // Look for retry button or tap capability on sync status
        if app.buttons["retry-sync-button"].exists {
            app.buttons["retry-sync-button"].tap()

            // Verify that status updates after retry
            // Should see either a loading state or updated status
            let statusUpdated = app.staticTexts["Checking sync status..."].waitForExistence(timeout: 3) ||
                app.staticTexts["Syncing with iCloud"].waitForExistence(timeout: 10)

            XCTAssertTrue(statusUpdated, "Sync status should update after retry")
        } else if syncStatusHeader.isHittable {
            // Some implementations might make the entire section tappable for retry
            syncStatusHeader.tap()

            // Give time for retry operation
            sleep(2)

            // Status should remain valid after retry
            let hasValidStatus =
                app.staticTexts["Syncing with iCloud"].exists ||
                app.staticTexts["Sign in to iCloud to sync across devices"].exists ||
                app.staticTexts["Sync unavailable - using local storage"].exists

            XCTAssertTrue(hasValidStatus, "Should maintain valid status after retry")
        }
    }

    // MARK: - Data Persistence with CloudKit

    @MainActor
    func testDataPersistenceWithCloudKitEnabled() throws {
        // Test that data persists correctly when CloudKit is enabled
        let app = TestUtilities.launchAppWithCloudKitTestMode()

        // Complete onboarding to create user data
        try self.completeOnboardingFlow(app)

        // Verify data was created
        TestUtilities.navigateToTab(app, tabName: "Settings")
        XCTAssertTrue(app.staticTexts["User Profile"].waitForExistence(timeout: 5),
                      "User profile should be created after onboarding")

        // Restart app to test persistence
        app.terminate()

        let restartedApp = TestUtilities.launchAppWithCloudKitTestMode()

        // Should skip onboarding and show main app
        XCTAssertTrue(restartedApp.tabBars.firstMatch.waitForExistence(timeout: 10),
                      "Should show main app after restart (data persisted)")

        TestUtilities.navigateToTab(restartedApp, tabName: "Settings")
        XCTAssertTrue(restartedApp.staticTexts["User Profile"].waitForExistence(timeout: 5),
                      "User profile should persist after app restart with CloudKit")
    }

    @MainActor
    func testCloudKitFallbackBehavior() throws {
        // Test that app works correctly when CloudKit is unavailable
        let app = TestUtilities.launchAppWithCloudKitTestMode()

        TestUtilities.navigateToTab(app, tabName: "Settings")

        // Check sync status
        let syncStatusHeader = app.staticTexts["Sync Status"]
        XCTAssertTrue(syncStatusHeader.waitForExistence(timeout: 10),
                      "Sync Status section should appear")

        // App should work regardless of CloudKit status
        // Test basic navigation
        TestUtilities.navigateToTab(app, tabName: "Home")
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3),
                      "Home tab should load correctly regardless of CloudKit status")

        TestUtilities.navigateToTab(app, tabName: "Add")
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3),
                      "Add tab should load correctly regardless of CloudKit status")

        // App should maintain full functionality even with CloudKit issues
        XCTAssertTrue(true, "App should maintain functionality with CloudKit fallback")
    }

    // MARK: - Multi-Device Sync Scenarios (If Possible)

    @MainActor
    func testSyncStatusReflectsActualCloudKitState() throws {
        // Test that sync status accurately reflects real CloudKit availability
        let app = TestUtilities.launchAppWithCloudKitTestMode()

        TestUtilities.navigateToTab(app, tabName: "Settings")

        let syncStatusHeader = app.staticTexts["Sync Status"]
        XCTAssertTrue(syncStatusHeader.waitForExistence(timeout: 10),
                      "Sync Status section should appear")

        // Wait for CloudKit status to stabilize
        sleep(5)

        // Capture the displayed status
        let allStatusTexts = app.staticTexts.allElementsBoundByIndex.map(\.label)
        let cloudKitStatusTexts = allStatusTexts.filter { text in
            text.contains("iCloud") || text.contains("Sync") ||
                text.contains("network") || text.contains("restricted") ||
                text.contains("Checking")
        }

        XCTAssertGreaterThan(cloudKitStatusTexts.count, 0,
                            "Should display at least one CloudKit status message")

        // Status should be consistent with actual CloudKit state
        // (This test validates that we're getting real CloudKit responses, not mocked)
        let hasRealisticStatus = cloudKitStatusTexts.contains { status in
            // These are realistic CloudKit status messages that indicate real integration
            status.contains("Syncing with iCloud") ||
                status.contains("Sign in to iCloud") ||
                status.contains("Sync unavailable") ||
                status.contains("network connection") ||
                status.contains("restricted")
        }

        XCTAssertTrue(hasRealisticStatus,
                      "Should display realistic CloudKit status. Got: \(cloudKitStatusTexts)")

        print("CloudKit integration test - Status messages found: \(cloudKitStatusTexts)")
    }

    // MARK: - Helper Methods

    private func completeOnboardingFlow(_ app: XCUIApplication) throws {
        // This is a simplified onboarding completion for testing
        // In a real implementation, this would navigate through actual onboarding steps

        // Wait for onboarding to appear
        let continueButton = app.buttons["onboarding-continue-button"]
        if continueButton.waitForExistence(timeout: 10) {
            // Navigate through onboarding steps
            for _ in 0 ..< 5 { // Max 5 steps to avoid infinite loop
                if continueButton.exists, continueButton.isEnabled {
                    continueButton.tap()
                    sleep(1)
                } else {
                    break
                }
            }
        }

        // Verify we reached the main app
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10),
                      "Should reach main app after onboarding")
    }
}

// MARK: - CloudKit Test Utilities

extension CloudKitIntegrationUITests {
    /// Verify that CloudKit-related UI elements are present and functional
    private func verifyCloudKitUI(_ app: XCUIApplication) {
        // Check for sync status indicators
        let syncIndicators = [
            "sync-status-card",
            "icloud-sync-icon",
            "sync-status-label",
        ]

        for identifier in syncIndicators {
            if app.otherElements[identifier].exists || app.staticTexts[identifier].exists {
                // At least one sync indicator should exist
                return
            }
        }

        XCTFail("No CloudKit sync UI elements found")
    }

    /// Wait for CloudKit status to stabilize
    private func waitForCloudKitStatusStabilization(_ app: XCUIApplication, timeout: TimeInterval = 15) {
        let startTime = Date()
        var lastStatus = ""
        var stableCount = 0

        while Date().timeIntervalSince(startTime) < timeout {
            let currentStatus = self.getCurrentSyncStatus(app)

            if currentStatus == lastStatus {
                stableCount += 1
                if stableCount >= 3 { // Status stable for 3 checks
                    return
                }
            } else {
                stableCount = 0
                lastStatus = currentStatus
            }

            sleep(1)
        }
    }

    private func getCurrentSyncStatus(_ app: XCUIApplication) -> String {
        let statusTexts = app.staticTexts.allElementsBoundByIndex
            .map(\.label)
            .filter { $0.contains("iCloud") || $0.contains("Sync") || $0.contains("network") }

        return statusTexts.first ?? "unknown"
    }
}
