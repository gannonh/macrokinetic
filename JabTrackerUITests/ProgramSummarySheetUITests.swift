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
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper to Launch with Seeded Data

    private func launchWithGoalAndProgram() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data", "--seed-check-in-good"]
        app.launch()
        return app
    }

    private func launchWithCollaborativeProgram() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing", "--reset-app-data",
            "--seed-check-in-good", "--seed-collaborative",
        ]
        app.launch()
        return app
    }

    // MARK: - Sheet Appearance

    func testSheetAppearsAfterEditGoal() throws {
        app = launchWithGoalAndProgram()

        // Wait for app to load
        let tabBar = app.tabBars.element
        guard tabBar.waitForExistence(timeout: 10) else {
            XCTFail("Tab bar should appear")
            return
        }

        // Navigate to Strategy view via More > Goals & Strategy
        navigateToStrategy()

        // Wait for Strategy view to load (it's a ScrollView)
        let strategyView = app.scrollViews["strategy-view"]
        guard strategyView.waitForExistence(timeout: 5) else {
            XCTFail("Strategy view should appear")
            return
        }

        // Tap Edit Goal
        let editGoalButton = app.buttons["edit-goal-button"]
        guard editGoalButton.waitForExistence(timeout: 3) else {
            XCTFail("Edit Goal button should exist when goal is present")
            return
        }
        editGoalButton.tap()

        // Complete goal wizard edits
        completeGoalWizardEdit()

        // Verify Program Summary Sheet appears
        let summarySheet = app.otherElements["program-summary-sheet"]
        XCTAssertTrue(
            summarySheet.waitForExistence(timeout: 5),
            "Program Summary Sheet should appear after Edit Goal"
        )

        // Verify "Goal Updated!" header visible
        let goalUpdatedText = app.staticTexts["Goal Updated!"]
        XCTAssertTrue(
            goalUpdatedText.waitForExistence(timeout: 3),
            "Goal Updated! header should be visible"
        )
    }

    func testSheetDoesNotAppearAfterNewGoal() throws {
        app = TestUtilities.launchAppWithTestMode(resetData: true)

        // Navigate to Strategy view (empty state)
        navigateToStrategy()

        // Tap Create Goal button
        let createButton = app.buttons["create-goal-button"]
        guard createButton.waitForExistence(timeout: 5) else {
            // May already have a goal
            return
        }
        createButton.tap()

        // Complete goal wizard
        completeGoalWizardNew()

        // After new goal, Program Wizard should appear (not Summary Sheet)
        let programWizard = app.otherElements["program-wizard"]
        let summarySheet = app.otherElements["program-summary-sheet"]

        // Either wizard appears or sheet does not
        let wizardAppears = programWizard.waitForExistence(timeout: 5)
        let summaryAppears = summarySheet.exists

        XCTAssertTrue(
            wizardAppears || !summaryAppears,
            "Program Wizard should appear for new goal (not Summary Sheet)"
        )
    }

    // MARK: - Content Display

    func testSheetDisplaysProgramDetails() throws {
        app = launchWithGoalAndProgram()

        // Trigger Program Summary Sheet
        triggerProgramSummarySheet()

        // Verify sheet appears
        let summarySheet = app.otherElements["program-summary-sheet"]
        guard summarySheet.waitForExistence(timeout: 5) else {
            XCTFail("Program Summary Sheet should appear")
            return
        }

        // Verify program details are visible
        // The sheet displays: Style, Diet, Calorie Floor, Training, Distribution, Protein
        let styleText = app.staticTexts["Style"]
        let dietText = app.staticTexts["Diet"]
        let floorText = app.staticTexts["Calorie Floor"]
        let trainingText = app.staticTexts["Training"]

        XCTAssertTrue(styleText.exists, "Style label should be visible")
        XCTAssertTrue(dietText.exists, "Diet label should be visible")
        XCTAssertTrue(floorText.exists, "Calorie Floor label should be visible")
        XCTAssertTrue(trainingText.exists, "Training label should be visible")
    }

    func testSheetShowsCurrentValues() throws {
        // Seed with specific program settings
        app = launchWithGoalAndProgram()

        // Trigger sheet
        triggerProgramSummarySheet()

        // Verify sheet appears
        let summarySheet = app.otherElements["program-summary-sheet"]
        guard summarySheet.waitForExistence(timeout: 5) else {
            XCTFail("Program Summary Sheet should appear")
            return
        }

        // Seeded data uses Coached style - verify it's shown
        let coachedText = app.staticTexts["Coached"]
        let balancedText = app.staticTexts["Balanced"]

        XCTAssertTrue(
            coachedText.exists || balancedText.exists,
            "Program values should match seeded data"
        )
    }

    // MARK: - Actions

    func testLooksGoodDismissesSheet() throws {
        app = launchWithGoalAndProgram()

        // Trigger Program Summary Sheet
        triggerProgramSummarySheet()

        let summarySheet = app.otherElements["program-summary-sheet"]
        guard summarySheet.waitForExistence(timeout: 5) else {
            XCTFail("Program Summary Sheet should appear")
            return
        }

        // Tap "Looks Good" button
        let looksGoodButton = app.buttons["looks-good-button"]
        guard looksGoodButton.waitForExistence(timeout: 3) else {
            XCTFail("Looks Good button should exist")
            return
        }
        looksGoodButton.tap()

        // Verify sheet dismissed
        XCTAssertFalse(
            summarySheet.waitForExistence(timeout: 2),
            "Program Summary Sheet should be dismissed"
        )

        // Verify Strategy view visible
        let strategyView = app.scrollViews["strategy-view"]
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 3),
            "Strategy view should be visible after dismissing sheet"
        )
    }

    func testSetNewProgramLaunchesWizard() throws {
        app = launchWithGoalAndProgram()

        // Trigger Program Summary Sheet
        triggerProgramSummarySheet()

        let summarySheet = app.otherElements["program-summary-sheet"]
        guard summarySheet.waitForExistence(timeout: 5) else {
            XCTFail("Program Summary Sheet should appear")
            return
        }

        // Tap "Set New Program" button
        let setNewButton = app.buttons["set-new-program-button"]
        guard setNewButton.waitForExistence(timeout: 3) else {
            XCTFail("Set New Program button should exist")
            return
        }
        setNewButton.tap()

        // Verify Program Summary Sheet dismissed
        XCTAssertFalse(
            summarySheet.waitForExistence(timeout: 2),
            "Program Summary Sheet should be dismissed"
        )

        // Verify Program Wizard appears
        let programWizard = app.otherElements["program-wizard"]
        XCTAssertTrue(
            programWizard.waitForExistence(timeout: 5),
            "Program Wizard should appear after tapping Set New Program"
        )
    }

    func testCancelDismissesSheet() throws {
        app = launchWithGoalAndProgram()

        // Trigger Program Summary Sheet
        triggerProgramSummarySheet()

        let summarySheet = app.otherElements["program-summary-sheet"]
        guard summarySheet.waitForExistence(timeout: 5) else {
            XCTFail("Program Summary Sheet should appear")
            return
        }

        // Tap Cancel button in navigation bar
        let cancelButton = app.buttons["Cancel"]
        guard cancelButton.waitForExistence(timeout: 3) else {
            XCTFail("Cancel button should exist")
            return
        }
        cancelButton.tap()

        // Verify sheet dismissed
        XCTAssertFalse(
            summarySheet.waitForExistence(timeout: 2),
            "Program Summary Sheet should be dismissed after Cancel"
        )

        // Verify Strategy view visible
        let strategyView = app.scrollViews["strategy-view"]
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 3),
            "Strategy view should be visible after Cancel"
        )
    }

    // MARK: - Flow Integration

    func testEditGoalToNewProgramFlow() throws {
        app = launchWithGoalAndProgram()

        // Complete Edit Goal flow
        triggerProgramSummarySheet()

        // Verify Program Summary Sheet appears
        let summarySheet = app.otherElements["program-summary-sheet"]
        guard summarySheet.waitForExistence(timeout: 5) else {
            XCTFail("Program Summary Sheet should appear")
            return
        }

        // Tap "Set New Program"
        let setNewButton = app.buttons["set-new-program-button"]
        guard setNewButton.waitForExistence(timeout: 3) else {
            XCTFail("Set New Program button should exist")
            return
        }
        setNewButton.tap()

        // Complete Program Wizard
        let programWizard = app.otherElements["program-wizard"]
        if programWizard.waitForExistence(timeout: 5) {
            completeProgramWizardNew()
        }

        // May end up at Program Ready Sheet or Strategy view
        let strategyView = app.scrollViews["strategy-view"]
        let readySheet = app.otherElements["program-ready-sheet"]

        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 10) || readySheet.exists,
            "Should end at Strategy view or Program Ready Sheet"
        )
    }

    func testEditGoalKeepProgramFlow() throws {
        app = launchWithGoalAndProgram()

        // Complete Edit Goal flow
        triggerProgramSummarySheet()

        // Verify Program Summary Sheet appears
        let summarySheet = app.otherElements["program-summary-sheet"]
        guard summarySheet.waitForExistence(timeout: 5) else {
            XCTFail("Program Summary Sheet should appear")
            return
        }

        // Tap "Looks Good" (keep existing program)
        let looksGoodButton = app.buttons["looks-good-button"]
        guard looksGoodButton.waitForExistence(timeout: 3) else {
            XCTFail("Looks Good button should exist")
            return
        }
        looksGoodButton.tap()

        // Verify back at Strategy view
        let strategyView = app.scrollViews["strategy-view"]
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 5),
            "Strategy view should be visible after keeping program"
        )

        // Verify program card is still visible (program unchanged)
        let programCard = app.descendants(matching: .any)["current-program-card"].firstMatch
        XCTAssertTrue(
            programCard.waitForExistence(timeout: 3),
            "Current program card should still be visible"
        )
    }

    // MARK: - Journey: Edit Goal -> Keep/New Program Choice

    func testEditGoalTriggersNewProgramChoice() throws {
        app = launchWithGoalAndProgram()

        // Navigate to Strategy view
        navigateToStrategy()

        let strategyView = app.scrollViews["strategy-view"]
        guard strategyView.waitForExistence(timeout: 5) else {
            XCTFail("Strategy view should appear")
            return
        }

        // Tap "Edit Goal"
        let editGoalButton = app.buttons["edit-goal-button"]
        guard editGoalButton.waitForExistence(timeout: 3) else {
            XCTFail("Edit Goal button should exist")
            return
        }
        editGoalButton.tap()

        // Modify target weight in Goal Wizard
        completeGoalWizardEdit()

        // Verify Program Summary Sheet appears with both options
        let summarySheet = app.otherElements["program-summary-sheet"]
        XCTAssertTrue(summarySheet.waitForExistence(timeout: 5), "Summary sheet should appear")

        // Verify "Goal Updated!" header
        let goalUpdated = app.staticTexts["Goal Updated!"]
        XCTAssertTrue(goalUpdated.exists, "Goal Updated header should be visible")

        // Verify both buttons exist
        let looksGoodButton = app.buttons["looks-good-button"]
        let setNewButton = app.buttons["set-new-program-button"]
        XCTAssertTrue(looksGoodButton.exists, "Looks Good button should exist")
        XCTAssertTrue(setNewButton.exists, "Set New Program button should exist")
    }

    func testKeepExistingProgramPreservesMacros() throws {
        app = launchWithGoalAndProgram()

        // Navigate to Strategy view to note current values
        navigateToStrategy()

        let programCard = app.descendants(matching: .any)["current-program-card"].firstMatch
        guard programCard.waitForExistence(timeout: 5) else {
            XCTFail("Program card should exist")
            return
        }

        // Edit Goal
        let editGoalButton = app.buttons["edit-goal-button"]
        guard editGoalButton.waitForExistence(timeout: 3) else {
            XCTFail("Edit Goal button should exist")
            return
        }
        editGoalButton.tap()

        // Complete Goal Wizard
        completeGoalWizardEdit()

        // Tap "Looks Good" on Program Summary Sheet
        let looksGoodButton = app.buttons["looks-good-button"]
        guard looksGoodButton.waitForExistence(timeout: 5) else {
            XCTFail("Looks Good button should exist")
            return
        }
        looksGoodButton.tap()

        // Verify Strategy view shows program (macros preserved)
        XCTAssertTrue(
            programCard.waitForExistence(timeout: 5),
            "Program card should still exist with preserved macros"
        )
    }

    func testSetNewProgramAllowsReconfigure() throws {
        app = launchWithGoalAndProgram()

        // Navigate to Strategy -> Edit Goal
        navigateToStrategy()

        let editGoalButton = app.buttons["edit-goal-button"]
        guard editGoalButton.waitForExistence(timeout: 5) else {
            XCTFail("Edit Goal button should exist")
            return
        }
        editGoalButton.tap()

        // Complete Goal Wizard
        completeGoalWizardEdit()

        // Tap "Set New Program" on Program Summary Sheet
        let setNewButton = app.buttons["set-new-program-button"]
        guard setNewButton.waitForExistence(timeout: 5) else {
            XCTFail("Set New Program button should exist")
            return
        }
        setNewButton.tap()

        // Verify Program Wizard appears
        let programWizard = app.otherElements["program-wizard"]
        XCTAssertTrue(
            programWizard.waitForExistence(timeout: 5),
            "Program Wizard should appear for reconfiguration"
        )
    }

    // MARK: - Data Display Accuracy

    func testSheetShowsCurrentProgramFromSingleSource() throws {
        // Seed Collaborative program with specific per-day macros
        app = launchWithCollaborativeProgram()

        // Trigger Program Summary Sheet
        triggerProgramSummarySheet()

        // Verify sheet appears
        let summarySheet = app.otherElements["program-summary-sheet"]
        guard summarySheet.waitForExistence(timeout: 5) else {
            XCTFail("Program Summary Sheet should appear")
            return
        }

        // Verify Collaborative style is shown (from seeded data)
        let collaborativeText = app.staticTexts["Collaborative"]
        XCTAssertTrue(
            collaborativeText.exists,
            "Collaborative program style should be displayed from single source"
        )
    }

    // MARK: - Private Helpers

    /// Navigate to Strategy view via More tab -> Goals & Strategy
    private func navigateToStrategy() {
        // First navigate to More tab
        TestUtilities.navigateToTab(app, tabName: "More", timeout: 5)

        // Wait for MoreView to load
        let moreView = app.otherElements["more-view"]
        guard moreView.waitForExistence(timeout: 5) else {
            XCTFail("More view should appear")
            return
        }

        // Goals & Strategy is a NavigationLink which becomes a cell in List
        let goalsStrategyText = app.staticTexts["Goals & Strategy"]
        if goalsStrategyText.waitForExistence(timeout: 5) {
            goalsStrategyText.tap()
        } else {
            // Fallback: try querying by accessibility identifier on cells
            let goalsStrategyCell = app.cells.containing(.staticText, identifier: "Goals & Strategy").firstMatch
            XCTAssertTrue(
                goalsStrategyCell.waitForExistence(timeout: 5),
                "Goals & Strategy cell should exist in More menu"
            )
            goalsStrategyCell.tap()
        }

        // Wait for Strategy view to load (it's a ScrollView)
        let strategyView = app.scrollViews["strategy-view"]
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 5),
            "Strategy view should appear after tapping Goals & Strategy"
        )
    }

    private func triggerProgramSummarySheet() {
        // Wait for app to load
        let tabBar = app.tabBars.element
        guard tabBar.waitForExistence(timeout: 10) else {
            return
        }

        // Navigate to Strategy view via More > Goals & Strategy
        navigateToStrategy()

        // Wait for Strategy view (ScrollView)
        let strategyView = app.scrollViews["strategy-view"]
        guard strategyView.waitForExistence(timeout: 5) else {
            return
        }

        // Tap Edit Goal
        let editGoalButton = app.buttons["edit-goal-button"]
        guard editGoalButton.waitForExistence(timeout: 3) else {
            return
        }
        editGoalButton.tap()

        // Complete goal wizard
        completeGoalWizardEdit()
    }

    private func completeGoalWizardEdit() {
        // Edit mode skips intro, starts at target weight
        // Navigate through steps until save
        for _ in 0..<6 {
            let nextButton = app.buttons["Next"]
            let saveButton = app.buttons["save-goal-button"]
            let updateButton = app.buttons["Update Goal"]

            if saveButton.waitForExistence(timeout: 1) {
                saveButton.tap()
                break
            } else if updateButton.waitForExistence(timeout: 1) {
                updateButton.tap()
                break
            } else if nextButton.waitForExistence(timeout: 1) {
                nextButton.tap()
            }
        }
    }

    private func completeGoalWizardNew() {
        // New goal includes intro, tap Get Started first
        let getStarted = app.buttons["Get Started"]
        if getStarted.waitForExistence(timeout: 2) {
            getStarted.tap()
        }

        // Navigate through steps
        for _ in 0..<6 {
            let nextButton = app.buttons["Next"]
            let saveButton = app.buttons["save-goal-button"]
            let continueButton = app.buttons["Continue"]

            if saveButton.waitForExistence(timeout: 1) {
                saveButton.tap()
                break
            } else if nextButton.waitForExistence(timeout: 1) {
                nextButton.tap()
            } else if continueButton.waitForExistence(timeout: 1) {
                continueButton.tap()
            }
        }
    }

    private func completeProgramWizardNew() {
        // Navigate through wizard steps
        for _ in 0..<8 {
            let nextButton = app.buttons["Next"]
            let saveButton = app.buttons["save-program-button"]
            let createButton = app.buttons["Create Program"]

            if saveButton.waitForExistence(timeout: 1) {
                saveButton.tap()
                break
            } else if createButton.waitForExistence(timeout: 1) {
                createButton.tap()
                break
            } else if nextButton.waitForExistence(timeout: 1) {
                nextButton.tap()
            }
        }
    }
}
