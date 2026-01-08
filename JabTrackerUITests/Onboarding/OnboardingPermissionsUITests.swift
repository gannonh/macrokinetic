//
//  OnboardingPermissionsUITests.swift
//  JabTrackerUITests
//
//  E2E tests for permission setup screens (HealthKit, Face ID, Notifications).
//
//  Permission steps use a toggle pattern:
//  - Toggle ON to enable the permission (may trigger system dialog)
//  - Toggle OFF (default) to skip the permission
//  - Tap Continue to proceed to next step
//

import XCTest

final class OnboardingPermissionsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data", "--force-onboarding"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - HealthKit Step

    /// User can enable HealthKit via toggle and proceed
    /// Acceptance: Toggle visible, turning ON and tapping Continue proceeds to goalType step
    func testUserCanEnableHealthKit() {
        // Navigate to HealthKit step (welcome -> USP -> HealthKit)
        navigateToHealthKitStep()

        // Verify HealthKit step displays
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-healthkit-step", timeout: 3),
            "HealthKit step should appear"
        )

        // Verify toggle exists (defaults to OFF)
        let toggle = app.switches["healthkit-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2), "HealthKit toggle should exist")

        // Turn toggle ON to enable HealthKit
        // Use coordinate tap for SwiftUI switches
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        // Tap Continue to proceed
        tapContinue()

        // Should proceed to goalType step
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-goalType-step", timeout: 5),
            "Goal Type step should appear after enabling HealthKit"
        )
    }

    /// User can skip HealthKit (leave toggle OFF) and proceed
    /// Acceptance: Toggle defaults to OFF, tapping Continue proceeds to goalType step
    func testUserCanSkipHealthKit() {
        // Navigate to HealthKit step
        navigateToHealthKitStep()

        // Verify HealthKit step displays
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-healthkit-step", timeout: 3),
            "HealthKit step should appear"
        )

        // Verify toggle exists and is OFF by default
        let toggle = app.switches["healthkit-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2), "HealthKit toggle should exist")

        // Leave toggle OFF (skip) and tap Continue
        tapContinue()

        // Should proceed to goalType step
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-goalType-step", timeout: 3),
            "Goal Type step should appear after skipping HealthKit"
        )
    }

    // MARK: - Face ID Step

    /// User can enable Face ID via toggle and proceed
    /// Acceptance: Toggle visible, turning ON and tapping Continue proceeds to notifications
    func testUserCanEnableFaceID() {
        // Navigate through full flow to Face ID step
        navigateToFaceIDStep()

        // Verify Face ID step displays
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-faceid-step", timeout: 3),
            "Face ID step should appear"
        )

        // Verify toggle exists
        let toggle = app.switches["faceid-toggle"]
        if toggle.waitForExistence(timeout: 2) {
            // Turn toggle ON to enable Face ID
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

            // Tap Continue
            tapContinue()

            // Should proceed to notifications step
            XCTAssertTrue(
                waitForElement(identifier: "onboarding-notifications-step", timeout: 5),
                "Notifications step should appear after enabling Face ID"
            )
        } else {
            // Biometrics unavailable on simulator - step may auto-skip
            XCTAssertTrue(
                waitForElement(identifier: "onboarding-notifications-step", timeout: 3),
                "Notifications step should appear (Face ID auto-skipped on simulator)"
            )
        }
    }

    /// User can skip Face ID (leave toggle OFF) and proceed
    /// Acceptance: Toggle defaults to OFF, tapping Continue proceeds to notifications
    func testUserCanSkipFaceID() {
        // Navigate through full flow to Face ID step
        navigateToFaceIDStep()

        // Verify Face ID step displays
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-faceid-step", timeout: 3),
            "Face ID step should appear"
        )

        // Try to find toggle and skip (leave OFF)
        let toggle = app.switches["faceid-toggle"]
        if toggle.waitForExistence(timeout: 2) {
            // Leave toggle OFF and tap Continue
            tapContinue()

            // Should proceed to notifications step
            XCTAssertTrue(
                waitForElement(identifier: "onboarding-notifications-step", timeout: 3),
                "Notifications step should appear after skipping Face ID"
            )
        } else {
            // Biometrics unavailable on simulator - step auto-skips
            XCTAssertTrue(
                waitForElement(identifier: "onboarding-notifications-step", timeout: 3),
                "Notifications step should appear (Face ID auto-skipped on simulator)"
            )
        }
    }

    // MARK: - Notifications Step

    /// User can enable notifications via toggle and proceed
    /// Acceptance: Toggle visible, turning ON and tapping Continue proceeds to completion
    func testUserCanEnableNotifications() {
        // Navigate through full flow to Notifications step
        navigateToNotificationsStep()

        // Verify Notifications step displays
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-notifications-step", timeout: 3),
            "Notifications step should appear"
        )

        // Verify toggle exists
        let toggle = app.switches["notifications-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2), "Notifications toggle should exist")

        // Turn toggle ON to enable notifications
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        // Tap Continue
        tapContinue()

        // Should proceed to completion step
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-completion-step", timeout: 5),
            "Completion step should appear after enabling notifications"
        )
    }

    /// User can skip notifications (leave toggle OFF) and proceed
    /// Acceptance: Toggle defaults to OFF, tapping Continue proceeds to completion
    func testUserCanSkipNotifications() {
        // Navigate through full flow to Notifications step
        navigateToNotificationsStep()

        // Verify Notifications step displays
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-notifications-step", timeout: 3),
            "Notifications step should appear"
        )

        // Verify toggle exists
        let toggle = app.switches["notifications-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2), "Notifications toggle should exist")

        // Leave toggle OFF (skip) and tap Continue
        tapContinue()

        // Should proceed to completion step
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-completion-step", timeout: 3),
            "Completion step should appear after skipping notifications"
        )
    }

    // MARK: - Full Flow Test

    /// User can complete full onboarding flow by skipping all permission steps
    /// Acceptance: Starting from welcome, can reach completion and main app
    func testCompleteOnboardingWithSkippedPermissions() {
        // Step 1: Welcome
        XCTAssertTrue(waitForElement(identifier: "onboarding-welcome-step", timeout: 5), "Welcome step should appear")
        tapContinue()

        // Step 2: USP Showcase
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-usp-showcase-step", timeout: 3),
            "USP Showcase step should appear"
        )
        tapContinue()

        // Step 3: HealthKit - Leave toggle OFF (skip)
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-healthkit-step", timeout: 3),
            "HealthKit step should appear"
        )
        tapContinue()

        // Step 4: Goal Type - Select Weight Loss
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-goalType-step", timeout: 3),
            "Goal Type step should appear"
        )
        let weightLossOption = app.buttons["goal-wizard-goalType-weight_loss"]
        if weightLossOption.waitForExistence(timeout: 2) {
            weightLossOption.tap()
        }
        tapContinue()

        // Step 5: Target Weight - Use defaults
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-targetWeight-step", timeout: 3),
            "Target Weight step should appear"
        )
        tapContinue()

        // Step 6: Profile Completion (may be skipped if HealthKit provided data)
        if waitForElement(identifier: "onboarding-profileCompletion-step", timeout: 3) {
            // Scroll to reveal sex buttons
            let scrollViews = app.scrollViews
            if scrollViews.count > 0 {
                scrollViews.firstMatch.swipeUp()
            }

            // Select Male sex to satisfy validation
            let maleButton = app.buttons.matching(identifier: "onboarding-profile-sex")
                .matching(NSPredicate(format: "label == 'Male'")).firstMatch
            if maleButton.waitForExistence(timeout: 3) {
                maleButton.tap()
            }
            tapContinue()
        }

        // Step 7: Program Style - Select Coached
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-programStyle-step", timeout: 3),
            "Program Style step should appear"
        )
        let coachedOption = app.buttons["program-wizard-programStyle-coached"]
        if coachedOption.waitForExistence(timeout: 2) {
            coachedOption.tap()
        }
        tapContinue()

        // Step 8: Diet Preference - Select Balanced
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-dietPreference-step", timeout: 3),
            "Diet Preference step should appear"
        )
        let balancedOption = app.buttons["program-wizard-dietPreference-balanced"]
        if balancedOption.waitForExistence(timeout: 2) {
            balancedOption.tap()
        }
        tapContinue()

        // Step 9: Calorie Floor - Select Standard
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-calorieFloor-step", timeout: 3),
            "Calorie Floor step should appear"
        )
        let standardOption = app.buttons["program-wizard-calorieFloor-standard"]
        if standardOption.waitForExistence(timeout: 2) {
            standardOption.tap()
        }
        tapContinue()

        // Step 10: Activity Level - Select None
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-activityLevel-step", timeout: 3),
            "Activity Level step should appear"
        )
        let noneOption = app.buttons["program-wizard-training-none"]
        if noneOption.waitForExistence(timeout: 2) {
            noneOption.tap()
        }
        tapContinue()

        // Step 11: Weekly Distribution - Select Even
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-weeklyDistribution-step", timeout: 3),
            "Weekly Distribution step should appear"
        )
        let evenOption = app.buttons["program-wizard-weeklyDistribution-even"]
        if evenOption.waitForExistence(timeout: 2) {
            evenOption.tap()
        }
        tapContinue()

        // Step 12: Protein Level - Select Moderate
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-proteinLevel-step", timeout: 3),
            "Protein Level step should appear"
        )
        let moderateOption = app.buttons["program-wizard-proteinLevel-moderate"]
        if moderateOption.waitForExistence(timeout: 2) {
            moderateOption.tap()
        }
        tapContinue()

        // Wait for calculating overlay to finish
        let calculatingOverlay = app.otherElements["calculating-overlay"]
        if calculatingOverlay.waitForExistence(timeout: 2) {
            let predicate = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: calculatingOverlay)
            _ = XCTWaiter().wait(for: [expectation], timeout: 10)
        }

        // Step 13: Setup Confirmation
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-setupConfirmation-step", timeout: 8),
            "Setup Confirmation step should appear"
        )
        tapContinue()

        // Step 14: Face ID - Leave toggle OFF or handle auto-skip
        if waitForElement(identifier: "onboarding-faceid-step", timeout: 3) {
            // Leave toggle OFF and continue
            tapContinue()
        }

        // Step 15: Notifications - Leave toggle OFF
        if waitForElement(identifier: "onboarding-notifications-step", timeout: 3) {
            tapContinue()
        }

        // Step 16: Completion
        XCTAssertTrue(
            waitForElement(identifier: "onboarding-completion-step", timeout: 3),
            "Completion step should appear after skipping all permissions"
        )

        // Verify completion UI elements
        XCTAssertTrue(
            waitForElement(identifier: "completion-summary-card", timeout: 2),
            "Summary card should appear on completion"
        )

        // Tap "Get Started" to complete onboarding
        let completeButton = app.buttons["onboarding-complete-button"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 2), "Get Started button should appear")
        completeButton.tap()

        // Verify main app appears
        let mainTabView = app.tabBars.firstMatch
        XCTAssertTrue(
            mainTabView.waitForExistence(timeout: 5),
            "Main app tab bar should appear after completing onboarding"
        )
    }

    // MARK: - Helper Methods

    /// Wait for an element with the given identifier to exist (searches all element types)
    private func waitForElement(identifier: String, timeout: TimeInterval) -> Bool {
        let element = app.descendants(matching: .any)[identifier].firstMatch
        return element.waitForExistence(timeout: timeout)
    }

    /// Tap the Continue button
    private func tapContinue() {
        let continueButton = app.buttons["onboarding-continue-button"]
        if continueButton.waitForExistence(timeout: 3) {
            continueButton.tap()
        }
    }

    /// Navigate to HealthKit step (welcome -> USP -> HealthKit)
    private func navigateToHealthKitStep() {
        // Step 1: Welcome
        _ = waitForElement(identifier: "onboarding-welcome-step", timeout: 5)
        tapContinue()

        // Step 2: USP Showcase
        _ = waitForElement(identifier: "onboarding-usp-showcase-step", timeout: 3)
        tapContinue()

        // Now at HealthKit step
    }

    /// Navigate through the full flow to reach the Face ID step
    private func navigateToFaceIDStep() {
        // Navigate to HealthKit
        navigateToHealthKitStep()

        // Step 3: HealthKit - Skip (leave toggle OFF)
        _ = waitForElement(identifier: "onboarding-healthkit-step", timeout: 3)
        tapContinue()

        // Step 4: Goal Type - Select Weight Loss
        _ = waitForElement(identifier: "onboarding-goalType-step", timeout: 3)
        let weightLossOption = app.buttons["goal-wizard-goalType-weight_loss"]
        if weightLossOption.waitForExistence(timeout: 2) {
            weightLossOption.tap()
        }
        tapContinue()

        // Step 5: Target Weight - Use defaults
        _ = waitForElement(identifier: "onboarding-targetWeight-step", timeout: 3)
        tapContinue()

        // Step 6: Profile Completion
        if waitForElement(identifier: "onboarding-profileCompletion-step", timeout: 3) {
            let scrollViews = app.scrollViews
            if scrollViews.count > 0 {
                scrollViews.firstMatch.swipeUp()
            }
            let maleButton = app.buttons.matching(identifier: "onboarding-profile-sex")
                .matching(NSPredicate(format: "label == 'Male'")).firstMatch
            if maleButton.waitForExistence(timeout: 3) {
                maleButton.tap()
            }
            tapContinue()
        }

        // Step 7: Program Style - Select Coached
        _ = waitForElement(identifier: "onboarding-programStyle-step", timeout: 3)
        let coachedOption = app.buttons["program-wizard-programStyle-coached"]
        if coachedOption.waitForExistence(timeout: 2) {
            coachedOption.tap()
        }
        tapContinue()

        // Step 8: Diet Preference - Select Balanced
        _ = waitForElement(identifier: "onboarding-dietPreference-step", timeout: 3)
        let balancedOption = app.buttons["program-wizard-dietPreference-balanced"]
        if balancedOption.waitForExistence(timeout: 2) {
            balancedOption.tap()
        }
        tapContinue()

        // Step 9: Calorie Floor - Select Standard
        _ = waitForElement(identifier: "onboarding-calorieFloor-step", timeout: 3)
        let standardOption = app.buttons["program-wizard-calorieFloor-standard"]
        if standardOption.waitForExistence(timeout: 2) {
            standardOption.tap()
        }
        tapContinue()

        // Step 10: Activity Level - Select None
        _ = waitForElement(identifier: "onboarding-activityLevel-step", timeout: 3)
        let noneOption = app.buttons["program-wizard-training-none"]
        if noneOption.waitForExistence(timeout: 2) {
            noneOption.tap()
        }
        tapContinue()

        // Step 11: Weekly Distribution - Select Even
        _ = waitForElement(identifier: "onboarding-weeklyDistribution-step", timeout: 3)
        let evenOption = app.buttons["program-wizard-weeklyDistribution-even"]
        if evenOption.waitForExistence(timeout: 2) {
            evenOption.tap()
        }
        tapContinue()

        // Step 12: Protein Level - Select Moderate
        _ = waitForElement(identifier: "onboarding-proteinLevel-step", timeout: 3)
        let moderateOption = app.buttons["program-wizard-proteinLevel-moderate"]
        if moderateOption.waitForExistence(timeout: 2) {
            moderateOption.tap()
        }
        tapContinue()

        // Wait for calculating overlay
        let calculatingOverlay = app.otherElements["calculating-overlay"]
        if calculatingOverlay.waitForExistence(timeout: 2) {
            let predicate = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: calculatingOverlay)
            _ = XCTWaiter().wait(for: [expectation], timeout: 10)
        }

        // Step 13: Setup Confirmation
        _ = waitForElement(identifier: "onboarding-setupConfirmation-step", timeout: 8)
        tapContinue()

        // Now at Face ID step
    }

    /// Navigate through the full flow to reach the Notifications step
    private func navigateToNotificationsStep() {
        // Navigate to Face ID step first
        navigateToFaceIDStep()

        // Step 14: Face ID - Skip (leave toggle OFF) or handle auto-skip
        if waitForElement(identifier: "onboarding-faceid-step", timeout: 3) {
            tapContinue()
        }
        // If biometrics unavailable, step auto-skips to notifications

        // Now at Notifications step
    }
}
