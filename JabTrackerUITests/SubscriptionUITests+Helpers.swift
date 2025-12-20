import XCTest

extension SubscriptionUITests {
    // MARK: - Onboarding Flow Helpers (small units)

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

    // MARK: - Transient System UI Handling

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

    // MARK: - Purchase + Verify Helpers

    func performPurchaseFlow(app: XCUIApplication) {
        let purchaseButton = app.buttons["purchase-annual-button"]
        XCTAssertTrue(purchaseButton.waitForExistence(timeout: 8))
        if !purchaseButton.isEnabled {
            let enabled = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "isEnabled == true"),
                object: purchaseButton)
            XCTAssertEqual(XCTWaiter().wait(for: [enabled], timeout: 5), .completed)
        }
        purchaseButton.tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let subscribeButtonSB = springboard.buttons["Subscribe"]
        XCTAssertTrue(subscribeButtonSB.waitForExistence(timeout: 8))
        subscribeButtonSB.tap()

        let handled = self.addUIInterruptionMonitor(
            withDescription: "Post-purchase confirmation"
        ) { alert in
            if alert.staticTexts["You’re all set."].exists {
                if alert.buttons["OK"].exists {
                    alert.buttons["OK"].tap()
                } else if let first = alert.buttons.allElementsBoundByIndex.first {
                    first.tap()
                }
                return true
            }
            return false
        }
        defer { self.removeUIInterruptionMonitor(handled) }
        app.tap()

        let getStartedSB = springboard.buttons["Get Started"]
        if getStartedSB.waitForExistence(timeout: 2) { getStartedSB.tap() }
        let getStartedApp = app.buttons["Get Started"]
        if getStartedApp.waitForExistence(timeout: 2) { getStartedApp.tap() }

        app.activate()
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(
            dashboardTab.waitForExistence(timeout: 10),
            "Dashboard tab should appear after completing purchase")
    }

    func verifyTrialOrPremiumInSettings(app: XCUIApplication) {
        TestUtilities.navigateToSettings(app)

        let statusLabel = app.staticTexts["subscription-status"]
        XCTAssertTrue(
            statusLabel.waitForExistence(timeout: 8),
            "Subscription status label should exist")

        let deadline = Date().addingTimeInterval(8)
        var statusText = statusLabel.label
        while Date() < deadline, statusText == "Not Subscribed" {
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            statusText = statusLabel.label
        }

        if statusText == "Trial Active" {
            let trialInfo = app.staticTexts["trial-days-remaining"]
            XCTAssertTrue(
                trialInfo.waitForExistence(timeout: 5),
                "Trial info label should appear during trial")
            let trialText = trialInfo.label
            print("🧪 Trial countdown label: \(trialText)")
            let numericPattern = "^\\d+ \\bday(s)? remaining$"
            let isNumeric = trialText.range(of: numericPattern, options: .regularExpression) != nil
            if isNumeric, let days = Int(trialText.split(separator: " ").first ?? "") {
                XCTAssertTrue(days > 0, "Trial days should be > 0 immediately after purchase")
                XCTAssertTrue(days <= 28, "Trial days should not exceed configured period (<= 28)")
            } else {
                XCTFail("Expected numeric trial countdown, got: \(trialText)")
            }
        } else {
            XCTAssertEqual(
                statusText, "Premium Active",
                "Expected Trial Active or Premium Active, got: \(statusText)")
        }
    }
}
