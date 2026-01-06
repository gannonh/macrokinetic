//
//  OnboardingGoalProgramUITests.swift
//  JabTrackerUITests
//
//  E2E tests for the onboarding goal and program selection flow.
//

import XCTest

final class OnboardingGoalProgramUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Launch app with force-onboarding to test onboarding flow
        app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"]
        )
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Goal Setup Step Tests

    func testGoalSetupStepExists() throws {
        // Navigate to goal setup step (welcome -> usp -> goal)
        navigateToStep(.goalSetup)

        // Verify the goal setup step view is displayed by checking for a goal card
        let weightLossCard = app.buttons["onboarding-goal-weight_loss"]
        XCTAssertTrue(
            weightLossCard.waitForExistence(timeout: 5),
            "Goal setup step should display weight loss option"
        )
    }

    func testGoalSelectionDisablesContinueUntilSelected() throws {
        // Navigate to goal setup step
        navigateToStep(.goalSetup)

        // Verify Continue button exists (may be disabled or enabled depending on view state)
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        // Note: The button is disabled until selection is made
        XCTAssertFalse(continueButton.isEnabled, "Continue should be disabled before selection")
    }

    func testSelectingWeightLossEnablesContinue() throws {
        // Navigate to goal setup step
        navigateToStep(.goalSetup)

        // Tap weight loss card
        let weightLossCard = app.buttons["onboarding-goal-weight_loss"]
        XCTAssertTrue(weightLossCard.waitForExistence(timeout: 5))
        weightLossCard.tap()

        // Verify Continue button is now enabled
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.isEnabled, "Continue should be enabled after selection")
    }

    func testSelectingMaintenanceEnablesContinue() throws {
        // Navigate to goal setup step
        navigateToStep(.goalSetup)

        // Tap maintenance card
        let maintenanceCard = app.buttons["onboarding-goal-maintenance"]
        XCTAssertTrue(maintenanceCard.waitForExistence(timeout: 5))
        maintenanceCard.tap()

        // Verify Continue button is now enabled
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.isEnabled, "Continue should be enabled after selection")
    }

    func testSelectingMuscleGainEnablesContinue() throws {
        // Navigate to goal setup step
        navigateToStep(.goalSetup)

        // Tap muscle gain card
        let muscleGainCard = app.buttons["onboarding-goal-muscle_gain"]
        XCTAssertTrue(muscleGainCard.waitForExistence(timeout: 5))
        muscleGainCard.tap()

        // Verify Continue button is now enabled
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.isEnabled, "Continue should be enabled after selection")
    }

    // MARK: - Program Setup Step Tests

    func testProgramSetupStepExists() throws {
        // Navigate to program setup step
        navigateToStep(.programSetup)

        // Verify the program setup step view is displayed by checking for a program card
        let coachedCard = app.buttons["onboarding-program-coached"]
        XCTAssertTrue(
            coachedCard.waitForExistence(timeout: 5),
            "Program setup step should display coached option"
        )
    }

    func testProgramSelectionDisablesContinueUntilSelected() throws {
        // Navigate to program setup step
        navigateToStep(.programSetup)

        // Verify Continue button is disabled initially
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        XCTAssertFalse(continueButton.isEnabled, "Continue should be disabled before selection")
    }

    func testSelectingCoachedEnablesContinue() throws {
        // Navigate to program setup step
        navigateToStep(.programSetup)

        // Tap coached card
        let coachedCard = app.buttons["onboarding-program-coached"]
        XCTAssertTrue(coachedCard.waitForExistence(timeout: 5))
        coachedCard.tap()

        // Verify Continue button is now enabled
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.isEnabled, "Continue should be enabled after selection")
    }

    func testSelectingCollaborativeEnablesContinue() throws {
        // Navigate to program setup step
        navigateToStep(.programSetup)

        // Tap collaborative card
        let collaborativeCard = app.buttons["onboarding-program-collaborative"]
        XCTAssertTrue(collaborativeCard.waitForExistence(timeout: 5))
        collaborativeCard.tap()

        // Verify Continue button is now enabled
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.isEnabled, "Continue should be enabled after selection")
    }

    func testSelectingManualEnablesContinue() throws {
        // Navigate to program setup step
        navigateToStep(.programSetup)

        // Tap manual card
        let manualCard = app.buttons["onboarding-program-manual"]
        XCTAssertTrue(manualCard.waitForExistence(timeout: 5))
        manualCard.tap()

        // Verify Continue button is now enabled
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.isEnabled, "Continue should be enabled after selection")
    }

    // MARK: - Complete Flow Test

    func testCompleteGoalProgramFlowNavigatesForward() throws {
        // Navigate to goal setup step
        navigateToStep(.goalSetup)

        // Select weight loss
        let weightLossCard = app.buttons["onboarding-goal-weight_loss"]
        XCTAssertTrue(weightLossCard.waitForExistence(timeout: 5))
        weightLossCard.tap()

        // Tap Continue
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()

        // Verify we're on program setup step
        let coachedCard = app.buttons["onboarding-program-coached"]
        XCTAssertTrue(coachedCard.waitForExistence(timeout: 5), "Should navigate to program setup")

        // Select coached
        coachedCard.tap()

        // Tap Continue to proceed past program setup
        let continueButton2 = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton2.isEnabled)
        continueButton2.tap()

        // Verify we navigated past program setup (coached card should no longer be visible)
        Thread.sleep(forTimeInterval: 0.5)  // Allow transition
        XCTAssertFalse(coachedCard.exists, "Should have navigated past program setup")
    }

    // MARK: - Helper Methods

    private enum OnboardingStepTarget {
        case goalSetup
        case programSetup
    }

    private func navigateToStep(_ step: OnboardingStepTarget) {
        // Wait for onboarding view to appear
        let onboardingView = app.otherElements["onboarding-view"]
        XCTAssertTrue(onboardingView.waitForExistence(timeout: 10), "Onboarding should appear")

        // Navigate through steps to reach target
        // Step order: welcome -> usp -> goal -> program -> ...
        let continueButton = app.buttons["onboarding-continue-button"]

        switch step {
        case .goalSetup:
            // Navigate: welcome -> usp -> goal (2 taps)
            for index in 0..<2 {
                XCTAssertTrue(
                    continueButton.waitForExistence(timeout: 5),
                    "Continue button should exist at step \(index)"
                )
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.5)  // Allow animation
            }
        case .programSetup:
            // Navigate: welcome -> usp -> goal (2 taps) then select goal and continue
            for index in 0..<2 {
                XCTAssertTrue(
                    continueButton.waitForExistence(timeout: 5),
                    "Continue button should exist at step \(index)"
                )
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
            // Select a goal type to enable Continue
            let weightLossCard = app.buttons["onboarding-goal-weight_loss"]
            XCTAssertTrue(weightLossCard.waitForExistence(timeout: 5))
            weightLossCard.tap()
            Thread.sleep(forTimeInterval: 0.3)
            continueButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
}
