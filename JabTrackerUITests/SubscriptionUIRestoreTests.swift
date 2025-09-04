import StoreKitTest
import XCTest

/// Tests for restore purchase edge cases in subscription UI
final class SubscriptionUIRestoreTests: XCTestCase {
    var testSession: SKTestSession?

    override func setUpWithError() throws {
        continueAfterFailure = false
        let thisFile = URL(fileURLWithPath: #file)
        let repoRoot = thisFile.deletingLastPathComponent().deletingLastPathComponent()
        let configURL = repoRoot.appendingPathComponent("JabTrackerStoreKit.storekit")

        print("🛒 RestoreTests StoreKitTest init -> expecting config at: \(configURL.path)")
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            XCTFail("❌ StoreKit configuration missing at: \(configURL.path)")
            return
        }
        let session = try SKTestSession(contentsOf: configURL)
        session.disableDialogs = false
        session.clearTransactions()
        self.testSession = session
        print("✅ RestoreTests StoreKit session ready")
    }

    override func tearDown() {
        self.testSession = nil
        super.tearDown()
    }

    // MARK: - Restore Purchase Edge Cases

    @MainActor
    func testRestoreWithNoPreviousPurchases() throws {
        // EDGE CASE: Test restore when user has no previous purchases
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"])

        self.completeOnboardingToSubscriptionScreen(app)
        self.dismissSignInSimulationIfPresent(app)

        // Clear any existing transactions to simulate no previous purchases
        self.testSession?.clearTransactions()

        let restoreButton = app.buttons["restore-purchases-button"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 3),
                      "Restore purchases button should be available")

        restoreButton.tap()

        // Should show alert indicating no purchases to restore
        let restoreAlert = app.alerts["Restore Purchases"]
        XCTAssertTrue(restoreAlert.waitForExistence(timeout: 5),
                      "Should show restore purchases alert")

        // Dismiss alert
        if restoreAlert.buttons["OK"].exists {
            restoreAlert.buttons["OK"].tap()
        }

        // Should remain on subscription screen
        XCTAssertTrue(
            app.staticTexts["JabTracker Premium"].exists,
            "Should remain on subscription screen after restore with no purchases")
    }

    @MainActor
    func testMultipleRestoreAttempts() throws {
        // EDGE CASE: Test multiple restore attempts in succession
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"])

        self.completeOnboardingToSubscriptionScreen(app)
        self.dismissSignInSimulationIfPresent(app)

        let restoreButton = app.buttons["restore-purchases-button"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 3))

        // Attempt multiple restores rapidly
        for attempt in 1 ... 3 {
            print("🔄 Restore attempt \(attempt)")

            if !restoreButton.isEnabled {
                // Wait for restore button to become enabled again
                let enabled = XCTNSPredicateExpectation(
                    predicate: NSPredicate(format: "isEnabled == true"),
                    object: restoreButton)
                XCTAssertEqual(XCTWaiter().wait(for: [enabled], timeout: 3), .completed,
                               "Restore button should become enabled between attempts")
            }

            restoreButton.tap()

            let restoreAlert = app.alerts["Restore Purchases"]
            if restoreAlert.waitForExistence(timeout: 3) {
                restoreAlert.buttons["OK"].tap()
            }

            // Brief pause between attempts
            Thread.sleep(forTimeInterval: 0.5)
        }

        // App should remain stable after multiple restore attempts
        XCTAssertTrue(
            app.staticTexts["JabTracker Premium"].exists,
            "App should remain stable after multiple restore attempts")
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

    private func dismissSignInSimulationIfPresent(_ app: XCUIApplication, timeout: TimeInterval = 2.5) {
        let signInAlert = app.alerts["Sign in with Apple ID"]
        if signInAlert.waitForExistence(timeout: timeout) {
            if let okButton = [
                signInAlert.buttons["OK"],
                signInAlert.buttons["Continue"],
                signInAlert.buttons["Allow"],
            ].first(where: { $0.exists }) {
                okButton.tap()
            } else if signInAlert.buttons.firstMatch.exists {
                signInAlert.buttons.firstMatch.tap()
            }
        }
    }
}
