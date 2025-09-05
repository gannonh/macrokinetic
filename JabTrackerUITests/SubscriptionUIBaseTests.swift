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

        print("🛒 \(String(describing: type(of: self))) StoreKitTest init -> expecting config at: \(configURL.path)")
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
        for _ in 0 ..< 3 {
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
        if app.buttons["enable-notifications-button"].waitForExistence(timeout: 3) {
            app.buttons["enable-notifications-button"].tap()
        }
        let continueFromNotifications = app.buttons["onboarding-continue-button"]
        if continueFromNotifications.waitForExistence(timeout: 3) {
            continueFromNotifications.tap()
        }
    }

    func handleHealthKit(_ app: XCUIApplication) {
        if app.buttons["enable-healthkit-button"].waitForExistence(timeout: 3) {
            app.buttons["enable-healthkit-button"].tap()
        }
        let continueFromHealthKit = app.buttons["onboarding-continue-button"]
        if continueFromHealthKit.waitForExistence(timeout: 3) {
            continueFromHealthKit.tap()
        }
    }

    func assertSubscriptionScreen(_ app: XCUIApplication) {
        XCTAssertTrue(
            app.staticTexts["JabTracker Premium"].waitForExistence(timeout: 5),
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
