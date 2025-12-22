import XCTest

extension SubscriptionUITests {
    // MARK: - Onboarding Flow Helpers (small units)

    func completeOnboardingToSubscriptionScreen(_ app: XCUIApplication) {
        self.advanceWelcome(app)
        self.selectMedication(app)
        self.selectDose(app)
        self.handleScheduleSetup(app)  // NEW: Schedule setup step
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

    func handleScheduleSetup(_ app: XCUIApplication) {
        // Schedule Setup screen - just tap Continue to accept defaults
        TestUtilities.debugScreenshot(app, step: 7, description: "before-schedule-setup")
        usleep(500_000)

        let continueButton = app.buttons["onboarding-continue-button"]
        if continueButton.waitForExistence(timeout: 3) && continueButton.isHittable {
            print("DEBUG: Tapping Continue on Schedule Setup")
            continueButton.tap()
            usleep(500_000)
        }
    }

    func handleNotifications(_ app: XCUIApplication) {
        // Debug screenshot
        TestUtilities.debugScreenshot(app, step: 8, description: "before-notifications")
        usleep(500_000)

        // PrimaryButton/SecondaryButton have hardcoded accessibilityIdentifier,
        // so we must use NSPredicate to query by label
        let enableButton = app.buttons.matching(
            NSPredicate(format: "label == 'Enable Notifications'")
        ).firstMatch
        let skipButton = app.buttons.matching(
            NSPredicate(format: "label == 'Not Now'")
        ).firstMatch

        print("DEBUG Notifications: Enable=\(enableButton.exists), Skip=\(skipButton.exists)")

        // Skip to avoid system notification prompt
        if skipButton.waitForExistence(timeout: 3) && skipButton.isHittable {
            print("DEBUG: Tapping Not Now")
            skipButton.tap()
            usleep(500_000)
            TestUtilities.debugScreenshot(app, step: 9, description: "after-skip-notifications")
        } else if enableButton.waitForExistence(timeout: 2) && enableButton.isHittable {
            print("DEBUG: Tapping Enable Notifications")
            enableButton.tap()
            usleep(800_000)
        } else {
            print("DEBUG: Neither Notifications button found")
            TestUtilities.debugScreenshot(app, step: 9, description: "notifications-buttons-not-found")
        }

        // Tap Continue if needed
        let continueButton = app.buttons["onboarding-continue-button"]
        if continueButton.waitForExistence(timeout: 2) && continueButton.isHittable {
            continueButton.tap()
            usleep(500_000)
        }
    }

    func handleHealthKit(_ app: XCUIApplication) {
        // Debug screenshot
        TestUtilities.debugScreenshot(app, step: 10, description: "before-healthkit")
        usleep(500_000)

        // PrimaryButton/SecondaryButton have hardcoded accessibilityIdentifier,
        // so we must use NSPredicate to query by label
        let enableButton = app.buttons.matching(
            NSPredicate(format: "label == 'Connect Health Data'")
        ).firstMatch
        let skipButton = app.buttons.matching(
            NSPredicate(format: "label == 'Skip for Now'")
        ).firstMatch

        print("DEBUG HealthKit: Enable=\(enableButton.exists), Skip=\(skipButton.exists)")

        // Skip to avoid system HealthKit prompt
        if skipButton.waitForExistence(timeout: 3) && skipButton.isHittable {
            print("DEBUG: Tapping Skip for Now")
            skipButton.tap()
            usleep(500_000)
            TestUtilities.debugScreenshot(app, step: 11, description: "after-skip-healthkit")
        } else if enableButton.waitForExistence(timeout: 2) && enableButton.isHittable {
            print("DEBUG: Tapping Connect Health Data")
            enableButton.tap()
            usleep(800_000)
        } else {
            print("DEBUG: Neither HealthKit button found")
            TestUtilities.debugScreenshot(app, step: 12, description: "healthkit-buttons-not-found")
        }

        // Tap Continue if needed
        let continueButton = app.buttons["onboarding-continue-button"]
        if continueButton.waitForExistence(timeout: 2) && continueButton.isHittable {
            print("DEBUG: Tapping Continue after HealthKit")
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
