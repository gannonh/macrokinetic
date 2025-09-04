import StoreKitTest
import XCTest

final class SubscriptionUITests: XCTestCase {
    var testSession: SKTestSession?

    override func setUpWithError() throws {
        continueAfterFailure = false
        let thisFile = URL(fileURLWithPath: #file)
        let repoRoot = thisFile.deletingLastPathComponent().deletingLastPathComponent()
        let configURL = repoRoot.appendingPathComponent("JabTrackerStoreKit.storekit")

        print("🛒 StoreKitTest init -> expecting config at: \(configURL.path)")
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            XCTFail("❌ StoreKit configuration missing at: \(configURL.path)")
            return
        }
        let session = try SKTestSession(contentsOf: configURL)
        session.disableDialogs = false // verify purchase UI
        session.clearTransactions()
        self.testSession = session
        print("✅ StoreKitTest session ready (disableDialogs=\(session.disableDialogs))")
    }

    override func tearDown() {
        self.testSession = nil
        super.tearDown()
    }

    @MainActor
    func testSubscriptionRestoreFlow() throws {
        // ACCEPTANCE CRITERIA: User can restore previous purchases
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"])

        // Navigate to subscription screen
        self.completeOnboardingToSubscriptionScreen(app)

        // If the simulated Apple ID sign-in alert is shown on first entry, restore will be
        // blocked until it's accepted. Dismiss it if present, and also register an
        // interruption monitor to catch any mid-flow appearances.
        self.dismissSignInSimulationIfPresent(app)
        let signInMonitor = self.addUIInterruptionMonitor(
            withDescription: "Simulated Apple ID sign-in"
        ) { alert in
            if alert.staticTexts["Sign in with Apple ID"].exists {
                if alert.buttons["OK"].exists { alert.buttons["OK"].tap(); return true }
                if alert.buttons["Continue"].exists { alert.buttons["Continue"].tap(); return true }
                if alert.buttons.firstMatch.exists { alert.buttons.firstMatch.tap(); return true }
            }
            return false
        }
        defer { self.removeUIInterruptionMonitor(signInMonitor) }
        // Nudge the app so the interruption monitor can fire if the alert is on-screen
        app.tap()

        // ACCEPTANCE CRITERIA: Restore purchases button is available
        let restoreButton = app.buttons["restore-purchases-button"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 3),
                      "Should show restore purchases button")
        XCTAssertTrue(restoreButton.isEnabled,
                      "Restore button should be enabled")

        // Tap restore purchases
        restoreButton.tap()

        // ACCEPTANCE CRITERIA: Restore process provides user feedback
        let restoreAlert = app.alerts["Restore Purchases"]
        XCTAssertTrue(restoreAlert.waitForExistence(timeout: 6),
                      "Should show restore purchases result alert (title: Restore Purchases)")

        // Dismiss alert and continue
        if restoreAlert.buttons["OK"].exists {
            restoreAlert.buttons["OK"].tap()
        }
    }

    @MainActor
    func testSubscriptionStatusDisplay() throws {
        // ACCEPTANCE CRITERIA: Subscription status is displayed correctly in Settings
        let app = TestUtilities.launchAppWithTestMode()

        // Navigate to Settings tab
        app.tabBars.buttons["Settings"].tap()

        // ACCEPTANCE CRITERIA: Subscription status section exists
        XCTAssertTrue(app.staticTexts["Subscription"].waitForExistence(timeout: 3),
                      "Should show subscription section in settings")

        // ACCEPTANCE CRITERIA: Current subscription status is displayed
        let subscriptionStatus = app.staticTexts["subscription-status"]
        XCTAssertTrue(subscriptionStatus.waitForExistence(timeout: 3),
                      "Should display current subscription status")

        // Status should be one of: Trial Active, Premium Active, or Not Subscribed
        let statusText = subscriptionStatus.label
        let validStatuses = ["Trial Active", "Premium Active", "Not Subscribed"]
        XCTAssertTrue(validStatuses.contains(statusText),
                      "Subscription status should be one of: \(validStatuses.joined(separator: ", "))")
    }

    @MainActor
    func testTrialCountdownAccuracyAfterPurchase() throws {
        XCTAssertEqual(self.testSession?.disableDialogs, false,
                       "StoreKit dialogs must be enabled for deterministic purchase UI")
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"])
        self.completeOnboardingToSubscriptionScreen(app)
        self.dismissSignInSimulationIfPresent(app)
        self.performPurchaseFlow(app: app)
        self.verifyTrialOrPremiumInSettings(app: app)
    }

    // Helpers moved to SubscriptionUITests+Helpers.swift
}
