import XCTest

final class SubscriptionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSubscriptionPurchaseFlow() throws {
        // ACCEPTANCE CRITERIA: User can navigate to subscription screen and see available products
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"]
        )
        
        // Navigate through onboarding to reach subscription screen
        completeOnboardingToSubscriptionScreen(app)
        
        // ACCEPTANCE CRITERIA: Available subscription products are loaded and displayed
        XCTAssertTrue(app.staticTexts["JabTracker Premium"].waitForExistence(timeout: 5),
                      "Should show subscription screen title")
        XCTAssertTrue(app.staticTexts["$4.99/month"].waitForExistence(timeout: 3),
                      "Should display monthly subscription price")
        XCTAssertTrue(app.staticTexts["2-week free trial"].waitForExistence(timeout: 3),
                      "Should display trial period information")
        
        // ACCEPTANCE CRITERIA: Purchase button is available and functional
        let purchaseButton = app.buttons["purchase-subscription-button"]
        XCTAssertTrue(purchaseButton.waitForExistence(timeout: 3),
                      "Should show purchase subscription button")
        XCTAssertTrue(purchaseButton.isEnabled,
                      "Purchase button should be enabled when products are loaded")
        
        // Tap purchase button to initiate subscription flow
        purchaseButton.tap()
        
        // ACCEPTANCE CRITERIA: StoreKit purchase sheet appears (in sandbox/testing)
        // Note: In sandbox testing, StoreKit shows a different UI than production
        let purchaseConfirmation = app.alerts.firstMatch
        XCTAssertTrue(purchaseConfirmation.waitForExistence(timeout: 5),
                      "Should show StoreKit purchase confirmation dialog")
        
        // In sandbox testing, we can simulate successful purchase
        if purchaseConfirmation.buttons["Subscribe"].exists {
            purchaseConfirmation.buttons["Subscribe"].tap()
        }
        
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
            additionalArguments: ["--force-onboarding"]
        )
        
        // Navigate to subscription screen
        completeOnboardingToSubscriptionScreen(app)
        
        // ACCEPTANCE CRITERIA: Restore purchases button is available
        let restoreButton = app.buttons["restore-purchases-button"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 3),
                      "Should show restore purchases button")
        XCTAssertTrue(restoreButton.isEnabled,
                      "Restore button should be enabled")
        
        // Tap restore purchases
        restoreButton.tap()
        
        // ACCEPTANCE CRITERIA: Restore process provides user feedback
        let restoreAlert = app.alerts.firstMatch
        XCTAssertTrue(restoreAlert.waitForExistence(timeout: 5),
                      "Should show restore purchases result alert")
        
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
            // If trial info exists, it should show valid days remaining
            let trialText = trialInfo.label
            XCTAssertTrue(trialText.contains("days remaining") || trialText.contains("Trial Active"),
                         "Trial info should contain valid trial period information")
        }
    }
    
    // MARK: - Helper Methods
    
    private func completeOnboardingToSubscriptionScreen(_ app: XCUIApplication) {
        // Navigate through welcome screens
        for _ in 0..<3 {
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
}