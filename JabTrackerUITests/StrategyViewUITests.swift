//
//  StrategyViewUITests.swift
//  JabTrackerUITests
//
//  E2E tests for the Strategy view.
//  Tests the main strategy management screen with goal/program entry points.
//

import XCTest

final class StrategyViewUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
    }

    // MARK: - Empty State

    func testEmptyStateShowsCreateGoal() throws {
        // TODO: Navigate to Strategy view (no goal exists)
        // TODO: Verify "No Active Goal" text visible
        // TODO: Verify "Create Goal" button visible
        // TODO: Verify no action buttons (Edit Goal, Edit Program, etc.)
    }

    func testCreateGoalFromEmptyState() throws {
        // TODO: Navigate to Strategy view (empty state)
        // TODO: Tap "Create Goal" button
        // TODO: Verify Goal Wizard appears with intro screen
    }

    // MARK: - With Active Goal

    func testShowsCurrentProgramWhenGoalExists() throws {
        // TODO: Seed goal with program
        // TODO: Navigate to Strategy view
        // TODO: Verify "In Progress" label visible
        // TODO: Verify program style shown (e.g., "Coached Program")
        // TODO: Verify daily targets displayed:
        //       - Daily Calories
        //       - Protein
        //       - Carbs
        //       - Fat
    }

    func testShowsCheckInCountdown() throws {
        // TODO: Seed goal with program
        // TODO: Navigate to Strategy view
        // TODO: Verify "Next Check-In" section visible
        // TODO: Verify countdown ring visible
    }

    func testActionButtonsVisibleWithGoal() throws {
        // TODO: Seed goal with program
        // TODO: Navigate to Strategy view
        // TODO: Verify all 4 action buttons visible:
        //       - "Edit Goal"
        //       - "Edit Program"
        //       - "New Goal"
        //       - "New Program"
    }

    // MARK: - Entry Points

    func testEditGoalLaunchesGoalWizard() throws {
        // TODO: Seed goal with program
        // TODO: Navigate to Strategy view
        // TODO: Tap "Edit Goal" button
        // TODO: Verify Goal Wizard appears
        // TODO: Verify NO intro screen (edit mode)
    }

    func testEditProgramLaunchesProgramWizard() throws {
        // TODO: Seed goal with program
        // TODO: Navigate to Strategy view
        // TODO: Tap "Edit Program" button
        // TODO: Verify Program Wizard appears
        // TODO: Verify edit mode (skips style selection)
    }

    func testNewGoalLaunchesGoalWizardWithIntro() throws {
        // TODO: Seed goal with program
        // TODO: Navigate to Strategy view
        // TODO: Tap "New Goal" button
        // TODO: Verify Goal Wizard appears
        // TODO: Verify intro screen visible (new goal mode)
    }

    func testNewProgramLaunchesProgramWizard() throws {
        // TODO: Seed goal with program
        // TODO: Navigate to Strategy view
        // TODO: Tap "New Program" button
        // TODO: Verify Program Wizard appears
        // TODO: Verify new mode (includes style selection)
    }

    // MARK: - Flow Integration

    func testNewGoalChainsToProgramWizard() throws {
        // TODO: Navigate to Strategy view (empty state)
        // TODO: Tap "Create Goal"
        // TODO: Complete Goal Wizard
        // TODO: Verify Program Wizard appears automatically
    }

    func testEditGoalShowsProgramSummary() throws {
        // TODO: Seed goal with program
        // TODO: Navigate to Strategy view
        // TODO: Tap "Edit Goal"
        // TODO: Complete Goal Wizard
        // TODO: Verify Program Summary Sheet appears
    }

    // MARK: - No User State

    func testNoUserShowsProfilePrompt() throws {
        // TODO: Launch without user data
        // TODO: Navigate to Strategy view
        // TODO: Verify "Set up your profile" message
        // TODO: Verify onboarding prompt
    }
}

// MARK: - Accessibility Identifiers Reference
//
// Strategy View:
// - "strategy-view" - Main view
// - "check-in-countdown-card" - Check-in countdown section
// - "current-program-card" - Current program display
// - "no-user-section" - No user state
//
// Empty State:
// - "create-goal-button" - Create Goal button (empty state)
//
// Action Buttons (with goal):
// - "edit-goal-button" - Edit Goal
// - "edit-program-button" - Edit Program
// - "new-goal-button" - New Goal
// - "new-program-button" - New Program
