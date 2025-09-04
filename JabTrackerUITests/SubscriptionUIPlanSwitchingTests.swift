import StoreKitTest
import XCTest

/// Tests for plan switching edge cases in subscription UI
final class SubscriptionUIPlanSwitchingTests: XCTestCase {
    var testSession: SKTestSession?

    override func setUpWithError() throws {
        continueAfterFailure = false
        let thisFile = URL(fileURLWithPath: #file)
        let repoRoot = thisFile.deletingLastPathComponent().deletingLastPathComponent()
        let configURL = repoRoot.appendingPathComponent("JabTrackerStoreKit.storekit")

        print("🛒 PlanSwitchingTests StoreKitTest init -> expecting config at: \(configURL.path)")
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            XCTFail("❌ StoreKit configuration missing at: \(configURL.path)")
            return
        }
        let session = try SKTestSession(contentsOf: configURL)
        session.disableDialogs = false
        session.clearTransactions()
        self.testSession = session
        print("✅ PlanSwitchingTests StoreKit session ready")
    }

    override func tearDown() {
        self.testSession = nil
        super.tearDown()
    }

    // MARK: - Plan Switching Edge Cases

    @MainActor
    func testRapidPlanSwitching() throws {
        // EDGE CASE: Test rapid switching between monthly/annual plans
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"])

        self.completeOnboardingToSubscriptionScreen(app)

        let monthlyCard = app.buttons["monthly-pricing-card"]
        let annualCard = app.buttons["annual-pricing-card"]

        XCTAssertTrue(monthlyCard.waitForExistence(timeout: 3),
                      "Monthly pricing card should exist")
        XCTAssertTrue(annualCard.exists,
                      "Annual pricing card should exist")

        // Test rapid switching
        for _ in 0 ..< 3 {
            monthlyCard.tap()
            Thread.sleep(forTimeInterval: 0.1)

            // Verify monthly purchase button appears
            let monthlyPurchaseButton = app.buttons["purchase-monthly-button"]
            XCTAssertTrue(monthlyPurchaseButton.waitForExistence(timeout: 1),
                          "Monthly purchase button should appear when monthly plan selected")

            annualCard.tap()
            Thread.sleep(forTimeInterval: 0.1)

            // Verify annual purchase button appears
            let annualPurchaseButton = app.buttons["purchase-annual-button"]
            XCTAssertTrue(annualPurchaseButton.waitForExistence(timeout: 1),
                          "Annual purchase button should appear when annual plan selected")
        }
    }

    @MainActor
    func testMostPopularBadgeVisibility() throws {
        // EDGE CASE: Verify "Most Popular" badge only appears on annual plan
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"])

        self.completeOnboardingToSubscriptionScreen(app)

        // Most Popular badge should be visible by default (annual selected)
        let popularBadge = app.staticTexts["Most Popular"]
        XCTAssertTrue(popularBadge.exists,
                      "Most Popular badge should be visible on annual plan")

        // Switch to monthly and verify badge is still associated with annual card
        let monthlyCard = app.buttons["monthly-pricing-card"]
        monthlyCard.tap()

        // Badge should still exist (it's part of the annual card, not selection-dependent)
        XCTAssertTrue(popularBadge.exists,
                      "Most Popular badge should remain visible even when monthly plan selected")
    }

    @MainActor
    func testBackNavigationDuringPurchaseFlow() throws {
        // EDGE CASE: Test back navigation during purchase attempt
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"])

        self.completeOnboardingToSubscriptionScreen(app)

        // Check if back button is available (might not be in final onboarding step)
        let backButton = app.buttons["onboarding-back-button"]
        if backButton.exists {
            print("✅ Back button available during subscription screen")

            // Test back navigation
            backButton.tap()

            // Should navigate to previous onboarding step
            let continueButton = app.buttons["onboarding-continue-button"]
            if continueButton.waitForExistence(timeout: 2) {
                // Navigate forward again to test state consistency
                continueButton.tap()

                XCTAssertTrue(
                    app.staticTexts["JabTracker Premium"].waitForExistence(timeout: 3),
                    "Should return to subscription screen after back/forward navigation")
            }
        } else {
            print("ℹ️  No back button available on subscription screen (expected for final step)")
        }
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
