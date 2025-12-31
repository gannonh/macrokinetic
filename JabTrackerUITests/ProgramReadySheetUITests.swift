//
//  ProgramReadySheetUITests.swift
//  JabTrackerUITests
//
//  E2E tests for ProgramReadySheet after Coached program creation.
//

import XCTest

/// E2E tests for ProgramReadySheet after Coached program creation
final class ProgramReadySheetUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
    }

    // MARK: - Navigation Tests

    @MainActor
    func testProgramReadySheetAppearsAfterCoachedProgram() throws {
        // TODO: Implement when GoalWizard E2E is complete
        throw XCTSkip("Stub: Requires full GoalWizard and ProgramWizard navigation implementation")

        // Navigate to Strategy tab
        TestUtilities.navigateToTab(app, tabName: "Strategy")

        // Start goal creation
        let createButton = app.buttons["create-goal-button"]
        guard createButton.waitForExistence(timeout: 5) else {
            XCTFail("Create goal button not found")
            return
        }
        createButton.tap()

        // Complete GoalWizard (stub - actual implementation depends on wizard flow)
        completeGoalWizardStub()

        // Complete ProgramWizard with Coached style
        completeProgramWizardWithCoachedStyle()

        // Verify ProgramReadySheet appears
        let readySheet = app.otherElements["program-ready-sheet"]
        XCTAssertTrue(readySheet.waitForExistence(timeout: 5), "ProgramReadySheet should appear")
    }

    @MainActor
    func testProgramReadySheetShowsCalculatedValues() throws {
        // TODO: Implement when GoalWizard E2E is complete
        throw XCTSkip("Stub: Requires full wizard navigation to reach ProgramReadySheet")

        // Setup: Navigate through goal + program creation
        navigateToAndCreateProgram()

        // Verify weekly grid exists
        let macroGrid = app.otherElements["weekly-macro-grid"]
        XCTAssertTrue(macroGrid.waitForExistence(timeout: 5), "Weekly macro grid should be visible")

        // Verify calculation explanation exists
        let explanation = app.otherElements["calculation-explanation"]
        XCTAssertTrue(explanation.waitForExistence(timeout: 5), "Calculation explanation should be visible")

        // Verify done button exists
        let doneButton = app.buttons["done-button"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "Done button should be visible")
    }

    @MainActor
    func testDoneButtonDismissesProgramReadySheet() throws {
        // TODO: Implement when GoalWizard E2E is complete
        throw XCTSkip("Stub: Requires full wizard navigation to reach ProgramReadySheet")

        navigateToAndCreateProgram()

        // Tap done button
        let doneButton = app.buttons["done-button"]
        guard doneButton.waitForExistence(timeout: 5) else {
            XCTFail("Done button not found")
            return
        }
        doneButton.tap()

        // Verify sheet is dismissed
        let readySheet = app.otherElements["program-ready-sheet"]
        XCTAssertFalse(readySheet.waitForExistence(timeout: 2), "ProgramReadySheet should be dismissed")
    }

    // MARK: - Helpers

    private func completeGoalWizardStub() {
        // Stub: Navigate through GoalWizard steps
        // TODO: Implement when GoalWizard E2E is complete
        // For now, assume wizard auto-completes or use test data seeding

        // Wait for wizard to complete by checking for next screen
        let programWizard = app.otherElements["program-wizard"]
        _ = programWizard.waitForExistence(timeout: 3)
    }

    private func completeProgramWizardWithCoachedStyle() {
        // Wait for ProgramWizard to appear
        let programWizard = app.otherElements["program-wizard"]
        guard programWizard.waitForExistence(timeout: 5) else {
            XCTFail("ProgramWizard not found")
            return
        }

        // Select Coached style (should be default)
        // Navigate through wizard steps and save
        // TODO: Implement full wizard navigation

        // For stub: tap save button if visible
        let saveButton = app.buttons["save-program-button"]
        if saveButton.waitForExistence(timeout: 3) {
            saveButton.tap()
        }
    }

    private func navigateToAndCreateProgram() {
        TestUtilities.navigateToTab(app, tabName: "Strategy")

        let createButton = app.buttons["create-goal-button"]
        if createButton.waitForExistence(timeout: 3) {
            createButton.tap()
            completeGoalWizardStub()
            completeProgramWizardWithCoachedStyle()
        }
    }

    // MARK: - Per-Day Display Tests

    @MainActor
    func testProgramReadySheetShowsPerDayValues() throws {
        // CRITICAL: Weekly grid must show per-day macro breakdown
        // TODO: Complete program creation
        // TODO: Verify ProgramReadySheet weekly grid shows:
        //       - 7 columns (S-M-T-W-T-F-S or M-T-W-T-F-S-S)
        //       - Calories row with daily values
        //       - Protein row with daily values
        //       - Carbs row with daily values
        //       - Fat row with daily values
        throw XCTSkip("Stub: Requires full wizard navigation")
    }

    @MainActor
    func testCoachedEvenShowsSameValuesAllDays() throws {
        // TODO: Complete Coached program with Even distribution
        // TODO: Verify ProgramReadySheet grid shows:
        //       - Identical calorie values for all 7 days
        //       - Identical protein values for all 7 days
        //       - Identical carb values for all 7 days
        //       - Identical fat values for all 7 days
        throw XCTSkip("Stub: Requires full wizard navigation")
    }

    @MainActor
    func testCoachedShiftedShowsVariedValues() throws {
        // TODO: Complete Coached program with Shifted distribution
        // TODO: Select high calorie days (e.g., Sat/Sun)
        // TODO: Verify ProgramReadySheet grid shows:
        //       - Higher calories on selected days
        //       - Lower calories on other days
        //       - Macros proportionally adjusted
        throw XCTSkip("Stub: Requires full wizard navigation")
    }

    @MainActor
    func testCollaborativeShowsCustomizedDays() throws {
        // TODO: Complete Collaborative program
        // TODO: Customize Monday and Saturday with specific values
        // TODO: Lock those days
        // TODO: Verify ProgramReadySheet grid shows:
        //       - Custom values for Monday
        //       - Custom values for Saturday
        //       - Default values for other days
        throw XCTSkip("Stub: Requires full wizard navigation")
    }

    @MainActor
    func testManualPerDayShowsEnteredValues() throws {
        // TODO: Complete Manual program with "Different Per Day" mode
        // TODO: Enter unique values for each day
        // TODO: Verify ProgramReadySheet grid shows:
        //       - Exact values entered for each day
        //       - No auto-calculation or modification
        throw XCTSkip("Stub: Requires full wizard navigation")
    }

    // MARK: - Data Accuracy Tests

    @MainActor
    func testMacroMathIsCorrect() throws {
        // TODO: Complete any program
        // TODO: Verify for each day:
        //       - protein_cal (g × 4) + carb_cal (g × 4) + fat_cal (g × 9) ≈ total_cal
        throw XCTSkip("Stub: Requires full wizard navigation")
    }

    @MainActor
    func testValuesMatchStrategyViewAfterDismiss() throws {
        // CRITICAL: Single source of truth - values must match
        // TODO: Complete program creation
        // TODO: Note values shown in ProgramReadySheet grid
        // TODO: Tap "Start Program" to dismiss
        // TODO: Navigate to Strategy view
        // TODO: Verify Strategy weekly grid shows IDENTICAL values
        throw XCTSkip("Stub: Requires full wizard navigation")
    }
}
