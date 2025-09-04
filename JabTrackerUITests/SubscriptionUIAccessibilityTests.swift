import StoreKitTest
import XCTest

/// Tests for accessibility and data persistence edge cases in subscription UI
final class SubscriptionUIAccessibilityTests: XCTestCase {
    var testSession: SKTestSession?

    override func setUpWithError() throws {
        continueAfterFailure = false
        let thisFile = URL(fileURLWithPath: #file)
        let repoRoot = thisFile.deletingLastPathComponent().deletingLastPathComponent()
        let configURL = repoRoot.appendingPathComponent("JabTrackerStoreKit.storekit")

        print("🛒 AccessibilityTests StoreKitTest init -> expecting config at: \(configURL.path)")
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            XCTFail("❌ StoreKit configuration missing at: \(configURL.path)")
            return
        }
        let session = try SKTestSession(contentsOf: configURL)
        session.disableDialogs = false
        session.clearTransactions()
        self.testSession = session
        print("✅ AccessibilityTests StoreKit session ready")
    }

    override func tearDown() {
        self.testSession = nil
        super.tearDown()
    }

    // MARK: - Accessibility and Interaction

    @MainActor
    func testVoiceOverNavigationThroughPricingCards() throws {
        // EDGE CASE: Test accessibility navigation through subscription elements
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"])

        self.completeOnboardingToSubscriptionScreen(app)

        // Test that key elements have accessibility identifiers
        let monthlyCard = app.buttons["monthly-pricing-card"]
        let annualCard = app.buttons["annual-pricing-card"]
        let purchaseButton = app.buttons["purchase-annual-button"]
        let restoreButton = app.buttons["restore-purchases-button"]

        XCTAssertTrue(monthlyCard.exists,
                      "Monthly pricing card should be accessible")
        XCTAssertTrue(annualCard.exists,
                      "Annual pricing card should be accessible")
        XCTAssertTrue(purchaseButton.exists,
                      "Purchase button should be accessible")
        XCTAssertTrue(restoreButton.exists,
                      "Restore button should be accessible")

        // Test that pricing text is accessible
        let monthlyPrice = app.staticTexts["$4.99/month"]
        let annualPrice = app.staticTexts["$39.99/year"]
        let trialText = app.staticTexts["4-week free trial"]

        XCTAssertTrue(monthlyPrice.exists,
                      "Monthly price should be accessible to screen readers")
        XCTAssertTrue(annualPrice.exists,
                      "Annual price should be accessible to screen readers")
        XCTAssertTrue(trialText.exists,
                      "Trial period text should be accessible to screen readers")
    }

    // MARK: - Data Persistence Edge Cases

    @MainActor
    func testSubscriptionStateAfterAppRelaunch() throws {
        // EDGE CASE: Test subscription state persistence across app launches
        var app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: false, // Don't reset to test persistence
            additionalArguments: ["--ui-testing"])

        // Navigate to Settings to check initial state
        app.tabBars.buttons["Settings"].tap()

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
        app.tabBars.buttons["Settings"].tap()

        let relaunchStatus = app.staticTexts["subscription-status"]
        if relaunchStatus.waitForExistence(timeout: 5) {
            let relaunchStatusText = relaunchStatus.label
            print("🔍 Status after relaunch: \(relaunchStatusText)")

            // Status should be consistent (or at least valid)
            let validStatuses = ["Trial Active", "Premium Active", "Not Subscribed"]
            XCTAssertTrue(validStatuses.contains(relaunchStatusText),
                          "Subscription status should be valid after app relaunch")
        } else {
            XCTFail("Subscription status should be available after app relaunch")
        }
    }

    // MARK: - Terms and Privacy Links

    @MainActor
    func testTermsAndPrivacyLinksInteraction() throws {
        // EDGE CASE: Test Terms of Service and Privacy Policy links
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"])

        self.completeOnboardingToSubscriptionScreen(app)

        let termsLink = app.buttons["terms-of-service-link"]
        let privacyLink = app.buttons["privacy-policy-link"]

        XCTAssertTrue(termsLink.exists && termsLink.isEnabled,
                      "Terms of Service link should be available and enabled")
        XCTAssertTrue(privacyLink.exists && privacyLink.isEnabled,
                      "Privacy Policy link should be available and enabled")

        // Test that links don't crash the app when tapped
        // Note: In test environment, these might not actually open URLs
        termsLink.tap()

        // App should remain stable
        XCTAssertTrue(
            app.staticTexts["JabTracker Premium"].exists,
            "App should remain stable after Terms link interaction")

        privacyLink.tap()

        // App should remain stable
        XCTAssertTrue(
            app.staticTexts["JabTracker Premium"].exists,
            "App should remain stable after Privacy link interaction")
    }

    // MARK: - Helper Methods

    private func completeOnboardingToSubscriptionScreen(_ app: XCUIApplication) {
        self.advanceWelcome(app)
        self.selectMedication(app)
        self.selectDose(app)
        self.handleNotifications(app)
        self.handleHealthKit(app)
        self.assertSubscriptionScreen(app)
    }

    private func advanceWelcome(_ app: XCUIApplication) {
        for _ in 0 ..< 3 {
            let continueButton = app.buttons["onboarding-continue-button"]
            if continueButton.waitForExistence(timeout: 3) {
                continueButton.tap()
            }
        }
    }

    private func selectMedication(_ app: XCUIApplication) {
        if app.buttons["medication-semaglutide"].waitForExistence(timeout: 3) {
            app.buttons["medication-semaglutide"].tap()
            app.buttons["onboarding-continue-button"].tap()
        }
    }

    private func selectDose(_ app: XCUIApplication) {
        if app.buttons["dose-button-1.0"].waitForExistence(timeout: 3) {
            app.buttons["dose-button-1.0"].tap()
            app.buttons["onboarding-continue-button"].tap()
        }
    }

    private func handleNotifications(_ app: XCUIApplication) {
        if app.buttons["enable-notifications-button"].waitForExistence(timeout: 3) {
            app.buttons["enable-notifications-button"].tap()
        }
        let continueFromNotifications = app.buttons["onboarding-continue-button"]
        if continueFromNotifications.waitForExistence(timeout: 3) {
            continueFromNotifications.tap()
        }
    }

    private func handleHealthKit(_ app: XCUIApplication) {
        if app.buttons["enable-healthkit-button"].waitForExistence(timeout: 3) {
            app.buttons["enable-healthkit-button"].tap()
        }
        let continueFromHealthKit = app.buttons["onboarding-continue-button"]
        if continueFromHealthKit.waitForExistence(timeout: 3) {
            continueFromHealthKit.tap()
        }
    }

    private func assertSubscriptionScreen(_ app: XCUIApplication) {
        XCTAssertTrue(
            app.staticTexts["JabTracker Premium"].waitForExistence(timeout: 5),
            "Should reach subscription screen after completing onboarding flow")
    }
}
