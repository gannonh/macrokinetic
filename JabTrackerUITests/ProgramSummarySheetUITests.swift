//
//  ProgramSummarySheetUITests.swift
//  JabTrackerUITests
//
//  E2E tests for the Program Summary Sheet.
//  Tests the sheet that appears after Edit Goal flow.
//

import XCTest

final class ProgramSummarySheetUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
    }

    // MARK: - Sheet Appearance

    func testSheetAppearsAfterEditGoal() throws {
        // TODO: Seed test data with goal and program
        // TODO: Navigate to Strategy view
        // TODO: Tap "Edit Goal"
        // TODO: Complete goal wizard (modify target weight)
        // TODO: Verify Program Summary Sheet appears
        // TODO: Verify "Goal Updated!" header visible
    }

    func testSheetDoesNotAppearAfterNewGoal() throws {
        // TODO: Navigate to Strategy view (empty state)
        // TODO: Tap "Create Goal"
        // TODO: Complete goal wizard
        // TODO: Verify Program Wizard appears (not Summary Sheet)
    }

    // MARK: - Content Display

    func testSheetDisplaysProgramDetails() throws {
        // TODO: Trigger Program Summary Sheet
        // TODO: Verify all program details visible:
        //       - Style (e.g., "Coached")
        //       - Diet (e.g., "Balanced")
        //       - Calorie Floor (e.g., "Standard")
        //       - Training (e.g., "None")
        //       - Distribution (e.g., "Even")
        //       - Protein (e.g., "Moderate")
    }

    func testSheetShowsCurrentValues() throws {
        // TODO: Seed specific program settings
        // TODO: Trigger Program Summary Sheet
        // TODO: Verify values match seeded data
    }

    // MARK: - Actions

    func testLooksGoodDismissesSheet() throws {
        // TODO: Trigger Program Summary Sheet
        // TODO: Tap "Looks Good" button
        // TODO: Verify sheet dismissed
        // TODO: Verify Strategy view visible
        // TODO: Verify program unchanged
    }

    func testSetNewProgramLaunchesWizard() throws {
        // TODO: Trigger Program Summary Sheet
        // TODO: Tap "Set New Program" button
        // TODO: Verify Program Summary Sheet dismissed
        // TODO: Verify Program Wizard appears
    }

    func testCancelDismissesSheet() throws {
        // TODO: Trigger Program Summary Sheet
        // TODO: Tap Cancel button
        // TODO: Verify sheet dismissed
        // TODO: Verify Strategy view visible
    }

    // MARK: - Flow Integration

    func testEditGoalToNewProgramFlow() throws {
        // TODO: Complete Edit Goal flow
        // TODO: Verify Program Summary Sheet appears
        // TODO: Tap "Set New Program"
        // TODO: Complete Program Wizard
        // TODO: Verify back at Strategy view
        // TODO: Verify program updated
    }

    func testEditGoalKeepProgramFlow() throws {
        // TODO: Complete Edit Goal flow
        // TODO: Verify Program Summary Sheet appears
        // TODO: Tap "Looks Good"
        // TODO: Verify back at Strategy view
        // TODO: Verify goal updated but program unchanged
    }
}

// MARK: - Accessibility Identifiers Reference
//
// Program Summary Sheet:
// - "program-summary-sheet" - Main sheet view
// - "looks-good-button" - Keep current program
// - "set-new-program-button" - Launch program wizard
//
// Program Detail Cards (within grid):
// - Style card
// - Diet card
// - Calorie Floor card
// - Training card
// - Distribution card
// - Protein card
