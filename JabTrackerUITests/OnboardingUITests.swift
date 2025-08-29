import XCTest

final class OnboardingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCompleteOnboardingFlow() throws {
        // Launch app with fresh state to trigger onboarding
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"]
        )
        
        // ACCEPTANCE CRITERIA: After authentication, user should see onboarding
        XCTAssertTrue(app.staticTexts["Welcome to JabTracker"].waitForExistence(timeout: 5),
                      "Should show welcome screen after authentication")
        
        // ACCEPTANCE CRITERIA: Welcome screens display with app benefits
        self.completeWelcomeScreens(app)
        
        // ACCEPTANCE CRITERIA: Medication selection wizard
        XCTAssertTrue(app.staticTexts["Select Your Medication"].waitForExistence(timeout: 3),
                      "Should show medication selection screen")
        
        self.selectMedication(app, medication: "Semaglutide")
        
        // ACCEPTANCE CRITERIA: Initial dose entry captures starting dose
        XCTAssertTrue(app.staticTexts["Set Up Your First Dose"].waitForExistence(timeout: 3),
                      "Should show dose setup screen")
        
        self.configureInitialDose(app, amount: "1.0")
        
        // ACCEPTANCE CRITERIA: Notification permissions requested with value proposition
        XCTAssertTrue(app.staticTexts["Enable Notifications"].waitForExistence(timeout: 3),
                      "Should show notification permissions screen")
        
        self.handleNotificationPermissions(app, grant: true)
        
        // ACCEPTANCE CRITERIA: HealthKit permissions requested
        XCTAssertTrue(app.staticTexts["Connect Health Data"].waitForExistence(timeout: 3),
                      "Should show HealthKit permissions screen")
        
        self.handleHealthKitPermissions(app, grant: true)
        
        // ACCEPTANCE CRITERIA: Subscription placeholder shows pricing
        XCTAssertTrue(app.staticTexts["JabTracker Premium"].waitForExistence(timeout: 3),
                      "Should show subscription placeholder screen")
        
        XCTAssertTrue(app.staticTexts["$4.99/month"].exists,
                      "Should show pricing information")
        
        XCTAssertTrue(app.staticTexts["2-week free trial"].exists,
                      "Should show trial information")
        
        app.buttons["Maybe Later"].tap()
        
        // ACCEPTANCE CRITERIA: Smooth transition to main app after completion
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5),
                      "Should transition to main app with tab bar visible")
        
        // ACCEPTANCE CRITERIA: All screens follow accessibility standards
        self.verifyAccessibilityCompliance(app)
        
        print("✅ Complete onboarding flow test passed")
    }
    
    @MainActor
    func testSkipOnboardingForReturningUser() throws {
        // Test that returning users (who have completed onboarding) skip the flow
        let app = TestUtilities.launchAppWithTestMode()
        
        // Should go directly to main app without onboarding
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5),
                      "Returning users should skip onboarding and see main app")
        
        // Verify no onboarding screens are shown
        XCTAssertFalse(app.staticTexts["Welcome to JabTracker"].exists,
                       "Should not show welcome screen for returning users")
        
        print("✅ Skip onboarding for returning user test passed")
    }
    
    @MainActor
    func testOnboardingProgressIndicator() throws {
        // Test that progress indicator shows current step
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"]
        )
        
        // Check progress indicator is visible and shows correct step
        XCTAssertTrue(app.otherElements["onboarding-progress"].waitForExistence(timeout: 3),
                      "Progress indicator should be visible")
        
        // Navigate through flow and verify progress updates
        self.completeWelcomeScreens(app)
        
        // Progress should update as user moves through flow
        let progressText = app.staticTexts["2 of 6"].firstMatch
        XCTAssertTrue(progressText.exists,
                      "Progress should show current step after welcome")
        
        print("✅ Onboarding progress indicator test passed")
    }
    
    // MARK: - Helper Methods
    
    private func completeWelcomeScreens(_ app: XCUIApplication) {
        // Navigate through 3 welcome screens
        for step in 1...3 {
            XCTAssertTrue(app.buttons["Next"].waitForExistence(timeout: 3),
                          "Next button should exist for welcome screen \(step)")
            app.buttons["Next"].tap()
        }
    }
    
    private func selectMedication(_ app: XCUIApplication, medication: String) {
        let medicationButton = app.buttons["medication-\(medication.lowercased())"]
        XCTAssertTrue(medicationButton.waitForExistence(timeout: 3),
                      "Medication button for \(medication) should exist")
        medicationButton.tap()
        
        app.buttons["Continue"].tap()
    }
    
    private func configureInitialDose(_ app: XCUIApplication, amount: String) {
        let doseField = app.textFields["dose-amount-input"]
        XCTAssertTrue(doseField.waitForExistence(timeout: 3),
                      "Dose amount input should exist")
        
        doseField.tap()
        doseField.typeText(amount)
        
        app.buttons["Set Starting Date"].tap()
        // Accept default date
        app.buttons["Done"].tap()
        
        app.buttons["Continue"].tap()
    }
    
    private func handleNotificationPermissions(_ app: XCUIApplication, grant: Bool) {
        XCTAssertTrue(app.staticTexts["Never miss a dose"].exists,
                      "Should show notification value proposition")
        
        if grant {
            app.buttons["Enable Notifications"].tap()
            // In UI testing, this will be handled automatically
        } else {
            app.buttons["Not Now"].tap()
        }
    }
    
    private func handleHealthKitPermissions(_ app: XCUIApplication, grant: Bool) {
        XCTAssertTrue(app.staticTexts["Track your progress"].exists,
                      "Should show HealthKit value proposition")
        
        if grant {
            app.buttons["Connect Health Data"].tap()
            // In UI testing, this will be handled automatically
        } else {
            app.buttons["Skip for Now"].tap()
        }
    }
    
    private func verifyAccessibilityCompliance(_ app: XCUIApplication) {
        // Verify key elements have accessibility identifiers
        // This is a basic check - full accessibility testing should be done with Accessibility Inspector
        XCTAssertTrue(app.tabBars.firstMatch.isAccessibilityElement,
                      "Tab bar should be accessible")
    }
}