import StoreKitTest
import XCTest

/// Base test class with shared functionality for subscription UI tests
class SubscriptionUIBaseTests: XCTestCase {
    var testSession: SKTestSession?

    override func setUpWithError() throws {
        continueAfterFailure = false
        let thisFile = URL(fileURLWithPath: #file)
        let repoRoot = thisFile.deletingLastPathComponent().deletingLastPathComponent()
        let configURL = repoRoot.appendingPathComponent("JabTrackerStoreKit.storekit")

        print(
            "🛒 \(String(describing: type(of: self))) StoreKitTest init -> expecting config at: \(configURL.path)"
        )
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            XCTFail("❌ StoreKit configuration missing at: \(configURL.path)")
            return
        }
        let session = try SKTestSession(contentsOf: configURL)
        session.disableDialogs = false
        session.clearTransactions()
        self.testSession = session
        print("✅ \(String(describing: type(of: self))) StoreKit session ready")
    }

    override func tearDown() {
        self.testSession = nil
        super.tearDown()
    }

    // MARK: - Shared Helper Methods

    func completeOnboardingToSubscriptionScreen(_ app: XCUIApplication) {
        self.advanceWelcome(app)
        self.selectMedication(app)
        self.selectDose(app)
        self.handleNotifications(app)
        self.handleHealthKit(app)
        self.assertSubscriptionScreen(app)
    }

    func advanceWelcome(_ app: XCUIApplication) {
        for _ in 0..<3 {
            let continueButton = app.buttons["onboarding-continue-button"]
            if continueButton.waitForExistence(timeout: 3) {
                continueButton.tap()
            }
        }
    }

    func selectMedication(_ app: XCUIApplication) {
        if app.buttons["medication-semaglutide"].waitForExistence(timeout: 3) {
            app.buttons["medication-semaglutide"].tap()
            app.buttons["onboarding-continue-button"].tap()
        }
    }

    func selectDose(_ app: XCUIApplication) {
        if app.buttons["dose-button-1.0"].waitForExistence(timeout: 3) {
            app.buttons["dose-button-1.0"].tap()
            app.buttons["onboarding-continue-button"].tap()
        }
    }

    func handleNotifications(_ app: XCUIApplication) {
        // PrimaryButton/SecondaryButton components have hardcoded identifiers,
        // so we need to query by label text instead
        let enableButton = app.buttons["Enable Notifications"]
        let skipButton = app.buttons["Not Now"]

        if enableButton.waitForExistence(timeout: 3) && enableButton.isHittable {
            enableButton.tap()
        } else if skipButton.waitForExistence(timeout: 2) && skipButton.isHittable {
            skipButton.tap()
        }

        // Wait for animation and auto-advance
        usleep(800_000)

        // Tap Continue if still on same screen
        let continueButton = app.buttons["onboarding-continue-button"]
        if continueButton.waitForExistence(timeout: 2) && continueButton.isHittable {
            continueButton.tap()
        }
    }

    func handleHealthKit(_ app: XCUIApplication) {
        // Debug screenshot to track progress
        TestUtilities.debugScreenshot(app, step: 10, description: "before-healthkit")

        // Wait for screen to stabilize
        usleep(500_000)

        // PrimaryButton/SecondaryButton components have hardcoded identifiers,
        // so we need to query by label text instead
        let enableButton = app.buttons["Connect Health Data"]
        let skipButton = app.buttons["Skip for Now"]

        // Try skip button first (it's a secondary button that won't trigger system prompts)
        if skipButton.waitForExistence(timeout: 3) && skipButton.isHittable {
            skipButton.tap()
            usleep(500_000)
            TestUtilities.debugScreenshot(app, step: 11, description: "after-skip-healthkit")
        } else if enableButton.waitForExistence(timeout: 2) && enableButton.isHittable {
            enableButton.tap()
            usleep(800_000)
        } else {
            // Last resort - tap Continue at the bottom
            TestUtilities.debugScreenshot(app, step: 12, description: "healthkit-buttons-not-found")
        }

        // Tap Continue if still on same screen (some onboarding flows require it)
        let continueButton = app.buttons["onboarding-continue-button"]
        if continueButton.waitForExistence(timeout: 2) && continueButton.isHittable {
            continueButton.tap()
            usleep(500_000)
        }
    }

    func assertSubscriptionScreen(_ app: XCUIApplication) {
        // Debug screenshot to see current state
        TestUtilities.debugScreenshot(app, step: 1, description: "asserting-subscription-screen")

        // Look for subscription screen indicator
        let subscriptionView = app.descendants(matching: .any)["subscription-view"]
        let premiumTitle = app.staticTexts["JabTracker Premium"]

        let foundSubscriptionScreen =
            subscriptionView.waitForExistence(timeout: 5)
            || premiumTitle.waitForExistence(timeout: 2)

        if !foundSubscriptionScreen {
            // Additional debug screenshot on failure
            TestUtilities.debugScreenshot(app, step: 2, description: "subscription-screen-not-found")
            print("DEBUG: View hierarchy: \(app.debugDescription)")
        }

        XCTAssertTrue(
            foundSubscriptionScreen,
            "Should reach subscription screen after completing onboarding flow")
    }

    func dismissSignInSimulationIfPresent(_ app: XCUIApplication, timeout: TimeInterval = 2.5) {
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
