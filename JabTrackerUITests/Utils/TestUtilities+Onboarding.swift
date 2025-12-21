import XCTest

extension TestUtilities {
    // MARK: - Onboarding Helper Methods

    /// Complete the welcome screens by tapping Continue
    static func completeWelcomeScreens(_ app: XCUIApplication) {
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(
            continueButton.waitForExistence(timeout: 5),
            "Continue button should exist on welcome screens")
        continueButton.tap()
    }

    /// Select a medication during onboarding
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - medication: The medication name (e.g., "Semaglutide")
    static func selectMedication(_ app: XCUIApplication, medication: String) {
        let medicationButton = app.buttons["medication-\(medication.lowercased())"]
        XCTAssertTrue(
            medicationButton.waitForExistence(timeout: 3),
            "Medication button for \(medication) should exist")
        medicationButton.tap()

        app.buttons["onboarding-continue-button"].tap()
    }

    /// Configure the initial dose during onboarding
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - amount: The dose amount as a string (e.g., "1.0")
    static func configureInitialDose(_ app: XCUIApplication, amount: String) {
        let doseButton = app.buttons["dose-button-\(amount)"]
        XCTAssertTrue(
            doseButton.waitForExistence(timeout: 3),
            "Dose button for \(amount) mg should exist")

        doseButton.tap()

        // Select injection site (required to proceed)
        let abdomenSiteButton = app.buttons["injection-site-abdomen"]
        XCTAssertTrue(
            abdomenSiteButton.waitForExistence(timeout: 3),
            "Abdomen injection site button should exist")
        abdomenSiteButton.tap()

        // Starting date is already set to today by default
        // Continue to next step
        app.buttons["onboarding-continue-button"].tap()
    }

    /// Handle notification permissions during onboarding
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - grant: Whether to grant (true) or deny (false) notification permissions
    static func handleNotificationPermissions(_ app: XCUIApplication, grant: Bool) {
        XCTAssertTrue(
            app.staticTexts["Never miss a dose"].exists,
            "Should show notification value proposition")

        if grant {
            app.buttons["Enable Notifications"].tap()

            // Handle notification permission dialog - MUST appear for valid test
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

            let allowButtonExists =
                app.buttons["Allow"].waitForExistence(timeout: 5)
                || springboard.buttons["Allow"].waitForExistence(timeout: 5)

            XCTAssertTrue(
                allowButtonExists,
                "System notification permission dialog MUST appear when granting notifications. Dialog not appearing indicates test setup issue - simulator permissions may need reset. Run: xcrun simctl privacy booted reset notifications com.gannonhall.JabTracker"
            )

            // Tap Allow button - automatically advances to HealthKit
            if app.buttons["Allow"].exists {
                app.buttons["Allow"].tap()
            } else if springboard.buttons["Allow"].exists {
                springboard.buttons["Allow"].tap()
            }
        } else {
            // Tap "Not Now" - automatically advances to HealthKit screen
            app.buttons["Not Now"].tap()
        }
    }

    /// Handle HealthKit permissions during onboarding
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - grant: Whether to grant (true) or skip (false) HealthKit permissions
    static func handleHealthKitPermissions(_ app: XCUIApplication, grant: Bool) {
        XCTAssertTrue(
            app.staticTexts["Track your progress"].waitForExistence(timeout: 5),
            "Should show HealthKit value proposition")

        if grant {
            app.buttons["Connect Health Data"].tap()

            // Handle HealthKit permission dialog - it may not appear if already granted
            if app.staticTexts["Turn On All"].waitForExistence(timeout: 3) {
                // Fresh permissions - handle dialog
                app.staticTexts["Turn On All"].tap()

                XCTAssertTrue(
                    app.buttons["UIA.Health.AuthSheet.DoneButton"].waitForExistence(timeout: 5),
                    "Allow button should appear after Turn On All")
                app.buttons["UIA.Health.AuthSheet.DoneButton"].tap()
            }

            // Wait for app to continue (either after permission dialog or immediate if already granted)
            XCTAssertTrue(
                app.staticTexts["JabTracker Premium"].waitForExistence(timeout: 10),
                "Should show subscription screen after HealthKit permission handling")
        } else {
            app.buttons["Skip for Now"].tap()
        }
    }

    /// Handle the schedule setup screen during onboarding
    /// - Parameter app: The XCUIApplication instance
    static func handleScheduleSetup(_ app: XCUIApplication) {
        // Wait for schedule setup screen
        XCTAssertTrue(
            app.staticTexts["Set Up Your Schedule"].waitForExistence(timeout: 3),
            "Should show schedule setup screen")

        // Continue with default schedule settings
        app.buttons["onboarding-continue-button"].tap()
    }

    /// Complete the entire onboarding flow
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - grantNotifications: Whether to grant notification permissions (default: true)
    ///   - grantHealthKit: Whether to grant HealthKit permissions (default: false)
    static func completeOnboardingFlow(
        _ app: XCUIApplication,
        grantNotifications: Bool = true,
        grantHealthKit: Bool = false
    ) {
        // Welcome screens
        completeWelcomeScreens(app)

        // Medication selection
        selectMedication(app, medication: "Semaglutide")

        // Dose setup
        configureInitialDose(app, amount: "0.25")

        // Schedule setup
        handleScheduleSetup(app)

        // Notification permissions
        handleNotificationPermissions(app, grant: grantNotifications)

        // Wait for transition to HealthKit screen
        usleep(500_000)  // 0.5 seconds

        // HealthKit permissions
        handleHealthKitPermissions(app, grant: grantHealthKit)

        // Complete onboarding (subscription screen)
        let completeButton = app.buttons["onboarding-complete-button"]
        XCTAssertTrue(
            completeButton.waitForExistence(timeout: 5),
            "Complete button should exist on subscription screen")
        completeButton.tap()

        // Wait for main app to appear
        XCTAssertTrue(
            app.tabBars.firstMatch.waitForExistence(timeout: 10),
            "Main app should appear after onboarding completion")
    }
}
