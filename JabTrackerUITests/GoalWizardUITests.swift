//
//  GoalWizardUITests.swift
//  JabTrackerUITests
//
//  E2E tests for the Goal wizard flow.
//  Tests goal creation, editing, and navigation.
//

import XCTest

final class GoalWizardUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
    }

    // MARK: - New Goal Flow

    func testNewGoalWizardComplete() throws {
        // TODO: Navigate to Strategy view
        // TODO: Tap "New Goal" or "Create Goal" button
        // TODO: Verify intro screen appears
        // TODO: Tap "Get Started"
        // TODO: Select goal type (weight loss)
        // TODO: Configure target weight and rate
        // TODO: Verify summary shows correct values
        // TODO: Tap "Continue to Program" to chain to Program wizard
    }

    func testNewGoalWithIntroScreen() throws {
        // TODO: Navigate to Strategy view
        // TODO: Tap "New Goal"
        // TODO: Verify intro screen shows 2-step process
        // TODO: Verify "Get Started" button exists
    }

    // MARK: - Edit Goal Flow

    func testEditGoalFlow() throws {
        // TODO: Create initial goal (or seed test data)
        // TODO: Navigate to Strategy view
        // TODO: Tap "Edit Goal"
        // TODO: Verify NO intro screen (edit mode)
        // TODO: Modify target weight
        // TODO: Verify summary shows updated values
        // TODO: Complete wizard → ProgramSummarySheet appears
    }

    // MARK: - Navigation

    func testBackNavigationPreservesSelections() throws {
        // TODO: Start New Goal wizard
        // TODO: Select goal type
        // TODO: Continue to target weight step
        // TODO: Go back
        // TODO: Verify goal type still selected
    }

    func testCancelWizardDismisses() throws {
        // TODO: Start New Goal wizard
        // TODO: Tap Cancel
        // TODO: Verify wizard is dismissed
        // TODO: Verify no goal created
    }

    // MARK: - Goal Type Selection

    func testGoalTypeOptions() throws {
        // TODO: Start New Goal wizard
        // TODO: Pass intro screen
        // TODO: Verify all goal types visible:
        //       - Weight Loss
        //       - Maintenance
        //       - Muscle Gain
    }

    func testContinueDisabledWithoutGoalType() throws {
        // TODO: Start New Goal wizard
        // TODO: Pass intro screen
        // TODO: Verify Continue button disabled
        // TODO: Select a goal type
        // TODO: Verify Continue button enabled
    }

    // MARK: - Target Weight Configuration

    func testTargetWeightSliderUpdates() throws {
        // TODO: Start wizard, select Weight Loss
        // TODO: Adjust target weight slider
        // TODO: Verify projected results update
    }

    func testMaintenanceGoalSkipsWeightConfig() throws {
        // TODO: Start wizard, select Maintenance
        // TODO: Continue to target step
        // TODO: Verify maintenance card shown (no slider)
    }
}

// MARK: - Accessibility Identifiers Reference
//
// Strategy Entry Points:
// - "strategy-view" - Strategy screen
// - "create-goal-button" - Empty state create button
// - "new-goal-button" - New goal button (when goal exists)
// - "edit-goal-button" - Edit goal button
//
// Goal Wizard:
// - "goal-wizard" - Main wizard view
// - "goal-wizard-cancel-button" - Cancel button
// - "goal-wizard-get-started-button" - Intro "Get Started" button
// - "goal-wizard-back-button" - Back button
// - "goal-wizard-continue-button" - Continue button
// - "goal-wizard-save-button" - Save/Continue to Program button
//
// Step Views:
// - "goal-wizard-goalType-step"
// - "goal-wizard-targetWeight-step"
// - "goal-wizard-summary-step"
//
// Goal Type Options:
// - "goal-wizard-goalType-weight_loss"
// - "goal-wizard-goalType-maintenance"
// - "goal-wizard-goalType-muscle_gain"
//
// Target Weight Step:
// - "goal-wizard-target-weight-slider"
// - "goal-wizard-rate-slider"
