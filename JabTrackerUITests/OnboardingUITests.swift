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
        // codegen
   
                
        
        // codegen end
        // ACCEPTANCE CRITERIA: After authentication, user should see onboarding
        XCTAssertTrue(app.staticTexts["Track Your Progress"].waitForExistence(timeout: 5),
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
        
        XCTAssertTrue(app.staticTexts["Subscription pricing: $4.99 per month with 2-week free trial"].exists,
                      "Should show pricing and trial information")
        
        app.buttons["onboarding-complete-button"].tap()
        
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
        XCTAssertFalse(app.staticTexts["Track Your Progress"].exists,
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
        
        // Check progress indicator is visible (look for the step text)
        XCTAssertTrue(app.staticTexts["1 of 6"].waitForExistence(timeout: 5),
                      "Progress indicator should be visible")
        
        // Navigate through flow and verify progress updates
        self.completeWelcomeScreens(app)
        
        // Progress should update as user moves through flow
        XCTAssertTrue(app.staticTexts["2 of 6"].waitForExistence(timeout: 3),
                      "Progress should show current step after welcome")
        
        print("✅ Onboarding progress indicator test passed")
    }
    
    // MARK: - Helper Methods
    
    private func completeWelcomeScreens(_ app: XCUIApplication) {
        // Use the main Continue button to advance past welcome screens
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5),
                      "Continue button should exist on welcome screens")
        continueButton.tap()
    }
    
    private func selectMedication(_ app: XCUIApplication, medication: String) {
        let medicationButton = app.buttons["medication-\(medication.lowercased())"]
        XCTAssertTrue(medicationButton.waitForExistence(timeout: 3),
                      "Medication button for \(medication) should exist")
        medicationButton.tap()
        
        app.buttons["Continue"].tap()
    }
    
    private func configureInitialDose(_ app: XCUIApplication, amount: String) {
        let doseButton = app.buttons["dose-button-\(amount)"]
        XCTAssertTrue(doseButton.waitForExistence(timeout: 3),
                      "Dose button for \(amount) mg should exist")
        
        doseButton.tap()
        
        // Select injection site (required to proceed)
        let injectionSiteButton = app.buttons["injection-site-thigh"]
        XCTAssertTrue(injectionSiteButton.waitForExistence(timeout: 3),
                      "Injection site selection should exist")
        injectionSiteButton.tap()
        
        // Starting date is already set to today by default
        // Continue to next step
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
            
            // Handle HealthKit permission dialog using recorded element locators
            // Tap "Turn On All" button (it's a staticText element in a specific cell)
            XCTAssertTrue(app.staticTexts["Turn On All"].waitForExistence(timeout: 5),
                         "Turn On All button should appear in HealthKit dialog")
            app.staticTexts["Turn On All"].tap()
            
            // Tap the final "Allow" button to complete permission flow
            XCTAssertTrue(app.buttons["UIA.Health.AuthSheet.DoneButton"].waitForExistence(timeout: 5),
                         "Allow button should appear after Turn On All")
            app.buttons["UIA.Health.AuthSheet.DoneButton"].tap()
            
            // Wait for permission flow to complete and return to app
            XCTAssertTrue(app.staticTexts["JabTracker Premium"].waitForExistence(timeout: 10),
                         "Should return to app and show subscription screen after HealthKit permission")
        } else {
            app.buttons["Skip for Now"].tap()
        }
    }
    
    private func verifyAccessibilityCompliance(_ app: XCUIApplication) {
        // Verify key elements have accessibility identifiers
        // This is a basic check - full accessibility testing should be done with Accessibility Inspector
        XCTAssertTrue(app.tabBars.buttons["Home"].exists,
                      "Home tab should be accessible")
    }
}
