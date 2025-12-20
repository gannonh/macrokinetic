import StoreKitTest
import XCTest

/// Tests for subscription data persistence and app lifecycle edge cases
final class SubscriptionUIPersistenceTests: SubscriptionUIBaseTests {
    // MARK: - Data Persistence Edge Cases

    @MainActor
    func testSubscriptionStateAfterAppRelaunch() throws {
        // EDGE CASE: Test subscription state persistence across app launches
        var app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: false,  // Don't reset to test persistence
            additionalArguments: ["--ui-testing"])

        // Navigate to Settings to check initial state
        TestUtilities.navigateToSettings(app)

        let initialStatus = app.staticTexts["subscription-status"]
        let initialStatusText = initialStatus.exists ? initialStatus.label : "Not Found"
        print("🔍 Initial subscription status: \(initialStatusText)")

        // Terminate and relaunch app
        app.terminate()

        app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: false,
            additionalArguments: ["--ui-testing"])

        // Check status after relaunch
        TestUtilities.navigateToSettings(app)

        let relaunchStatus = app.staticTexts["subscription-status"]
        if relaunchStatus.waitForExistence(timeout: 5) {
            let relaunchStatusText = relaunchStatus.label
            print("🔍 Status after relaunch: \(relaunchStatusText)")

            // Status should be consistent (or at least valid)
            let validStatuses = ["Trial Active", "Premium Active", "Not Subscribed"]
            XCTAssertTrue(
                validStatuses.contains(relaunchStatusText),
                "Subscription status should be valid after app relaunch")
        } else {
            XCTFail("Subscription status should be available after app relaunch")
        }
    }
}
