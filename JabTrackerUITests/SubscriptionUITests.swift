import StoreKitTest
import XCTest

final class SubscriptionUITests: XCTestCase {
    var testSession: SKTestSession?

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Deterministic approach based on repository root path:
        // From this test file path: <repo>/JabTrackerUITests/SubscriptionUITests.swift
        // Walk up two levels to repo root and load JabTrackerStoreKit.storekit.
        let thisFile = URL(fileURLWithPath: #file)
        let repoRoot = thisFile.deletingLastPathComponent().deletingLastPathComponent()
        let configURL = repoRoot.appendingPathComponent("JabTrackerStoreKit.storekit")

        print("🛒 StoreKitTest init -> expecting config at: \(configURL.path)")
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            XCTFail("❌ StoreKit configuration missing at: \(configURL.path)")
            return
        }
        let session = try SKTestSession(contentsOf: configURL)
        // We WANT dialogs so we can verify the purchase confirmation UI.
        session.disableDialogs = false
        session.clearTransactions()
        self.testSession = session
        print("✅ StoreKitTest session loaded from absolute path (disableDialogs=\(session.disableDialogs))")
    }

    override func tearDown() {
        self.testSession = nil
        super.tearDown()
    }

    @MainActor
    func testSubscriptionPurchaseFlow() throws {
        // ACCEPTANCE CRITERIA: User can navigate to subscription screen and see available products
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"])

        // Navigate through onboarding to reach subscription screen
        self.completeOnboardingToSubscriptionScreen(app)

        // Some simulators present a simulated Apple ID sign-in alert the first time we hit the
        // subscription screen with StoreKit dialogs enabled. Dismiss it proactively so the
        // purchase button can enable and be tappable.
        self.dismissSignInSimulationIfPresent(app)

        // ACCEPTANCE CRITERIA: Available subscription products are loaded and displayed.
        // Optimize by waiting ONCE for an anchor (purchase button) then performing zero-wait assertions.
        let purchaseButton = app.buttons["purchase-subscription-button"]
        XCTAssertTrue(purchaseButton.waitForExistence(timeout: 8),
                      "Purchase button (anchor for subscription screen) should appear")

        // Immediate assertions (no additional waits) – if these fail they'll provide fast feedback.
        XCTAssertTrue(app.staticTexts["JabTracker Premium"].exists, "Title should be present")
        XCTAssertTrue(app.staticTexts["$4.99/month"].exists, "Price label should be present")
        XCTAssertTrue(app.staticTexts["2-week free trial"].exists, "Trial label should be present")

        // Wait for button enabled but with a shorter timeout now that screen is visible.
        if !purchaseButton.isEnabled {
            let buttonEnabledPredicate = NSPredicate(format: "isEnabled == true")
            let enabledExpectation = XCTNSPredicateExpectation(predicate: buttonEnabledPredicate, object: purchaseButton)
            let enabledResult = XCTWaiter().wait(for: [enabledExpectation], timeout: 5)
            XCTAssertEqual(enabledResult, .completed, "Purchase button should enable after products load")
        }

        // Tap purchase button to initiate subscription flow
        print("🛒 Tapping purchase button (disableDialogs=\(self.testSession?.disableDialogs.description ?? "nil"))")
        purchaseButton.tap()

        // Deterministic path observed for this test environment:
        // StoreKit subscription sheet appears as a system sheet (SpringBoard process)
        // containing a "Subscribe" button.
        XCTAssertEqual(self.testSession?.disableDialogs, false, "StoreKit dialogs must be enabled for deterministic UI validation")

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let subscribeButtonSB = springboard.buttons["Subscribe"]
        print("🛒 Waiting for system subscription sheet (SpringBoard 'Subscribe' button)...")
        XCTAssertTrue(subscribeButtonSB.waitForExistence(timeout: 8),
                      "System subscription sheet should appear with a 'Subscribe' button")
        subscribeButtonSB.tap()
        print("✅ Tapped system 'Subscribe' button")

        // ACCEPTANCE CRITERIA: After successful purchase, user proceeds to main app
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10),
                      "Should navigate to main app after successful subscription")
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
        // blocked until it's accepted. Dismiss it if present.
        self.dismissSignInSimulationIfPresent(app)

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
    func testTrialPeriodCalculation() throws {
        // ACCEPTANCE CRITERIA: Trial period countdown is accurate and displayed
        let app = TestUtilities.launchAppWithTestMode()

        // Navigate to Settings tab
        app.tabBars.buttons["Settings"].tap()

        // ACCEPTANCE CRITERIA: Trial information is displayed when trial is active
        let trialInfo = app.staticTexts["trial-days-remaining"]
        if trialInfo.waitForExistence(timeout: 3) {
            // If trial info exists, it should show valid days remaining with a numeric
            // prefix (e.g. "23 days remaining")
            let trialText = trialInfo.label
            let regexPattern = "^\\d+ \\bday(s)? remaining$|^Trial Active$"
            let pattern = try? NSRegularExpression(
                pattern: regexPattern,
                options: .caseInsensitive)
            let range = NSRange(location: 0, length: trialText.utf16.count)
            let matches = pattern?.numberOfMatches(in: trialText, options: [], range: range) ?? 0
            XCTAssertTrue(matches == 1, "Trial info should show numeric countdown or 'Trial Active' – got: \(trialText)")
        }
    }

    // MARK: - Helper Methods

    // (Removed multi-path debug helper after confirming working absolute path strategy.)

    private func completeOnboardingToSubscriptionScreen(_ app: XCUIApplication) {
        // Navigate through welcome screens
        for _ in 0 ..< 3 {
            let continueButton = app.buttons["onboarding-continue-button"]
            if continueButton.waitForExistence(timeout: 3) {
                continueButton.tap()
            }
        }

        // Select medication (Semaglutide)
        if app.buttons["medication-semaglutide"].waitForExistence(timeout: 3) {
            app.buttons["medication-semaglutide"].tap()
            app.buttons["onboarding-continue-button"].tap()
        }

        // Configure initial dose
        if app.buttons["dose-button-1.0"].waitForExistence(timeout: 3) {
            app.buttons["dose-button-1.0"].tap()
            app.buttons["onboarding-continue-button"].tap()
        }

        // Handle notification permissions
        if app.buttons["enable-notifications-button"].waitForExistence(timeout: 3) {
            app.buttons["enable-notifications-button"].tap()
        }
        let continueFromNotifications = app.buttons["onboarding-continue-button"]
        if continueFromNotifications.waitForExistence(timeout: 3) {
            continueFromNotifications.tap()
        }

        // Handle HealthKit permissions
        if app.buttons["enable-healthkit-button"].waitForExistence(timeout: 3) {
            app.buttons["enable-healthkit-button"].tap()
        }
        let continueFromHealthKit = app.buttons["onboarding-continue-button"]
        if continueFromHealthKit.waitForExistence(timeout: 3) {
            continueFromHealthKit.tap()
        }

        // Should now be on subscription screen
        XCTAssertTrue(app.staticTexts["JabTracker Premium"].waitForExistence(timeout: 5),
                      "Should reach subscription screen after completing onboarding flow")
    }

    // MARK: - Transient System UI Handling

    private func dismissSignInSimulationIfPresent(_ app: XCUIApplication, timeout: TimeInterval = 2.5) {
        // The simulated Apple ID authentication alert (Xcode environment) can appear and block
        // taps on subscription actions (purchase / restore). Title observed: "Sign in with Apple ID".
        let signInAlert = app.alerts["Sign in with Apple ID"]
        if signInAlert.waitForExistence(timeout: timeout) {
            if let okButton = [signInAlert.buttons["OK"], signInAlert.buttons["Continue"], signInAlert.buttons["Allow"]].first(where: { $0.exists }) {
                okButton.tap()
            } else if signInAlert.buttons.firstMatch.exists {
                signInAlert.buttons.firstMatch.tap()
            }
            // Give the UI a brief moment to settle after dismissal (non-blocking)
            _ = signInAlert.waitForExistence(timeout: 0.2) // will return false once gone
        }
    }
}
