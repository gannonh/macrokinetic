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

    // MARK: - Weekly Macro Grid Display

    func testWeeklyGridAlwaysVisible() throws {
        // CRITICAL: Weekly grid should be visible for ALL program types
        // TODO: Seed Coached Even program
        // TODO: Navigate to Strategy view
        // TODO: Verify weekly macro grid visible (M-T-W-T-F-S-S columns)
        // TODO: Verify rows: Calories, Protein, Carbs, Fat
    }

    func testWeeklyGridVisibleForCoached() throws {
        // TODO: Seed Coached program
        // TODO: Navigate to Strategy view
        // TODO: Verify weekly grid visible
    }

    func testWeeklyGridVisibleForCollaborative() throws {
        // TODO: Seed Collaborative program
        // TODO: Navigate to Strategy view
        // TODO: Verify weekly grid visible
    }

    func testWeeklyGridVisibleForManual() throws {
        // TODO: Seed Manual program
        // TODO: Navigate to Strategy view
        // TODO: Verify weekly grid visible
    }

    // MARK: - Weekly Grid Data Accuracy

    func testWeeklyGridReflectsSavedProgramData() throws {
        // CRITICAL: Strategy view must show same data as saved program
        // TODO: Seed Collaborative program with specific values:
        //       - Monday: 2200 cal, 165p, 220c, 73f
        //       - Saturday: 2500 cal, 188p, 250c, 83f
        // TODO: Navigate to Strategy view
        // TODO: Verify Monday column shows: 2200, 165, 220, 73
        // TODO: Verify Saturday column shows: 2500, 188, 250, 83
    }

    func testWeeklyGridUpdatesAfterEdit() throws {
        // TODO: Seed program with known values
        // TODO: Navigate to Strategy view
        // TODO: Note current values in grid
        // TODO: Tap "Edit Program"
        // TODO: Modify values and save
        // TODO: Verify Strategy view grid shows NEW values (not old)
    }

    func testCoachedEvenShowsSameValuesAllDays() throws {
        // TODO: Seed Coached Even program
        // TODO: Navigate to Strategy view
        // TODO: Verify all 7 columns in grid show identical values
    }

    func testCoachedShiftedShowsVariedValues() throws {
        // TODO: Seed Coached Shifted program with weekend higher calories
        // TODO: Navigate to Strategy view
        // TODO: Verify weekday columns show lower calories
        // TODO: Verify weekend columns show higher calories
    }

    func testCollaborativeShowsCustomizedDays() throws {
        // TODO: Seed Collaborative program with M/S customized
        // TODO: Navigate to Strategy view
        // TODO: Verify Monday shows custom values
        // TODO: Verify Saturday shows custom values
        // TODO: Verify other days show default values
    }

    // MARK: - Entry Points

    func testEditGoalLaunchesGoalWizard() throws {
        // TODO: Seed goal with program
        // TODO: Navigate to Strategy view
        // TODO: Tap "Edit Goal" button
        // TODO: Verify Goal Wizard appears
        // TODO: Verify NO intro screen (edit mode)
        // TODO: Verify first step is targetWeight (not goalType)
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
        // Journey: New Goal → New Program
        // TODO: Navigate to Strategy view (empty state)
        // TODO: Tap "Create Goal"
        // TODO: Complete Goal Wizard (select type, set targets)
        // TODO: Verify Program Wizard appears automatically
        // TODO: Complete Program Wizard
        // TODO: Verify Strategy view shows new goal and program
    }

    func testEditGoalShowsProgramSummary() throws {
        // Journey: Edit Goal → Keep/New Program choice
        // TODO: Seed goal with program
        // TODO: Navigate to Strategy view
        // TODO: Tap "Edit Goal"
        // TODO: Modify target weight
        // TODO: Complete Goal Wizard
        // TODO: Verify Program Summary Sheet appears
        // TODO: Verify options: Keep existing program OR Create new program
    }

    // MARK: - Data Persistence

    func testStrategyViewPersistsAfterRestart() throws {
        // TODO: Create goal and program
        // TODO: Navigate to Strategy view
        // TODO: Note displayed values
        // TODO: Terminate app
        // TODO: Relaunch app
        // TODO: Navigate to Strategy view
        // TODO: Verify same values displayed
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
