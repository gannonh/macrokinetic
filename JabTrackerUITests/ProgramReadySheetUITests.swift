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
}
