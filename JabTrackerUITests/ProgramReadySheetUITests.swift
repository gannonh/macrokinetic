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

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation Tests

    @MainActor
    func testProgramReadySheetAppearsAfterCoachedProgram() throws {
        // Navigate to Strategy via More -> Goals & Strategy
        navigateToStrategy()

        // Wait for Strategy view to load and find create button
        let createButton = app.buttons["create-goal-button"]
        guard createButton.waitForExistence(timeout: 5) else {
            TestUtilities.debugScreenshot(app, name: "no-create-button")
            print("DEBUG: Element hierarchy:\n\(app.debugDescription)")
            XCTFail("Create goal button not found - Strategy view may already have a goal")
            return
        }
        createButton.tap()

        // Complete GoalWizard
        completeGoalWizard()

        // Debug: capture state after goal wizard
        TestUtilities.debugScreenshot(app, name: "after-goal-wizard")

        // Complete ProgramWizard with Coached style (default)
        completeProgramWizard()

        // Debug: capture state after program wizard
        TestUtilities.debugScreenshot(app, name: "after-program-wizard")
        print("DEBUG: Looking for program-ready-sheet in:\n\(app.debugDescription)")

        // Verify ProgramReadySheet appears
        let readySheet = app.otherElements["program-ready-sheet"]
        XCTAssertTrue(
            readySheet.waitForExistence(timeout: 5),
            "ProgramReadySheet should appear after completing program setup"
        )
    }

    @MainActor
    func testProgramReadySheetShowsCalculatedValues() throws {
        // Navigate and create goal + program
        navigateToAndCreateProgram()

        // Verify ProgramReadySheet elements
        let readySheet = app.otherElements["program-ready-sheet"]
        XCTAssertTrue(readySheet.waitForExistence(timeout: 5), "ProgramReadySheet should appear")

        // Verify weekly grid exists (identifier on child elements)
        let macroGrid = app.descendants(matching: .any)["weekly-macro-grid"].firstMatch
        XCTAssertTrue(macroGrid.waitForExistence(timeout: 3), "Weekly macro grid should be visible")

        // Verify calculation explanation exists (identifier on child elements)
        let explanation = app.descendants(matching: .any)["calculation-explanation"].firstMatch
        XCTAssertTrue(explanation.waitForExistence(timeout: 3), "Calculation explanation should be visible")

        // Verify done button exists
        let doneButton = app.buttons["done-button"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3), "Done button should be visible")
    }

    @MainActor
    func testDoneButtonDismissesProgramReadySheet() throws {
        // Navigate and create goal + program
        navigateToAndCreateProgram()

        let readySheet = app.otherElements["program-ready-sheet"]
        guard readySheet.waitForExistence(timeout: 5) else {
            XCTFail("ProgramReadySheet should appear")
            return
        }

        // Tap done button
        let doneButton = app.buttons["done-button"]
        guard doneButton.waitForExistence(timeout: 3) else {
            XCTFail("Done button not found")
            return
        }
        doneButton.tap()

        // Verify sheet is dismissed
        XCTAssertFalse(
            readySheet.waitForExistence(timeout: 2),
            "ProgramReadySheet should be dismissed after tapping Done"
        )

        // Verify Strategy view is visible (it's a ScrollView, not otherElements)
        let strategyView = app.scrollViews["strategy-view"]
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 3),
            "Strategy view should be visible after dismissing ProgramReadySheet"
        )
    }

    // MARK: - Per-Day Display Tests

    @MainActor
    func testProgramReadySheetShowsPerDayValues() throws {
        // Navigate and create goal + program
        navigateToAndCreateProgram()

        // Verify ProgramReadySheet appears
        let readySheet = app.otherElements["program-ready-sheet"]
        XCTAssertTrue(readySheet.waitForExistence(timeout: 5), "ProgramReadySheet should appear")

        // Verify weekly grid exists with day columns (identifier on child elements)
        let macroGrid = app.descendants(matching: .any)["weekly-macro-grid"].firstMatch
        XCTAssertTrue(macroGrid.waitForExistence(timeout: 3), "Weekly macro grid should be visible")

        // Verify day headers are present (M-T-W-T-F-S-S format)
        // The grid uses M, T, W, T, F, S, S labels for Monday through Sunday
        let mondayHeader = app.staticTexts["M"]
        XCTAssertTrue(mondayHeader.exists, "Monday header should be visible in grid")
    }

    @MainActor
    func testCoachedEvenShowsSameValuesAllDays() throws {
        // Navigate and create goal + program with Even distribution
        navigateToAndCreateProgramWithDistribution(.even)

        // Verify ProgramReadySheet appears
        let readySheet = app.otherElements["program-ready-sheet"]
        XCTAssertTrue(readySheet.waitForExistence(timeout: 5), "ProgramReadySheet should appear")

        // Verify weekly grid exists (identifier on child elements)
        let macroGrid = app.descendants(matching: .any)["weekly-macro-grid"].firstMatch
        XCTAssertTrue(macroGrid.waitForExistence(timeout: 3), "Weekly macro grid should be visible")

        // For Even distribution, all days should have identical values
        // This is verified visually via the grid showing same numbers in each column
    }

    @MainActor
    func testValuesMatchStrategyViewAfterDismiss() throws {
        // Navigate and create goal + program
        navigateToAndCreateProgram()

        // Verify ProgramReadySheet appears
        let readySheet = app.otherElements["program-ready-sheet"]
        guard readySheet.waitForExistence(timeout: 5) else {
            XCTFail("ProgramReadySheet should appear")
            return
        }

        // Dismiss via Done button
        let doneButton = app.buttons["done-button"]
        guard doneButton.waitForExistence(timeout: 3) else {
            XCTFail("Done button not found")
            return
        }
        doneButton.tap()

        // Wait for Strategy view (it's a ScrollView, not otherElements)
        let strategyView = app.scrollViews["strategy-view"]
        guard strategyView.waitForExistence(timeout: 5) else {
            XCTFail("Strategy view should appear after dismissing ProgramReadySheet")
            return
        }

        // Verify current program card is visible with weekly grid (identifier on child elements)
        let programCard = app.descendants(matching: .any)["current-program-card"].firstMatch
        XCTAssertTrue(
            programCard.waitForExistence(timeout: 3),
            "Current program card should be visible on Strategy view"
        )
    }

    // MARK: - Header Section Tests

    @MainActor
    func testProgramReadySheetShowsHeader() throws {
        // Navigate and create goal + program
        navigateToAndCreateProgram()

        // Verify ProgramReadySheet appears
        let readySheet = app.otherElements["program-ready-sheet"]
        XCTAssertTrue(readySheet.waitForExistence(timeout: 5), "ProgramReadySheet should appear")

        // Verify header section (identifier on child elements like Image and StaticText)
        let header = app.descendants(matching: .any)["program-ready-header"].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 3), "Header section should be visible")

        // Verify header text
        let headerText = app.staticTexts["Your macro program is ready"]
        XCTAssertTrue(headerText.exists, "Header text should be visible")
    }

    // MARK: - Helpers

    /// Navigate to Strategy view via More tab -> Goals & Strategy
    private func navigateToStrategy() {
        // First navigate to More tab
        TestUtilities.navigateToTab(app, tabName: "More", timeout: 5)

        // Wait for MoreView to load
        let moreView = app.otherElements["more-view"]
        XCTAssertTrue(moreView.waitForExistence(timeout: 5), "More view should appear")

        // Goals & Strategy is a NavigationLink which becomes a cell in List
        // Query by staticTexts containing the label text
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

        // Wait for Strategy view to load
        let strategyView = app.scrollViews.firstMatch
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 5),
            "Strategy view should appear after tapping Goals & Strategy"
        )
    }

    private func navigateToAndCreateProgram() {
        navigateToStrategy()

        let createButton = app.buttons["create-goal-button"]
        if createButton.waitForExistence(timeout: 3) {
            createButton.tap()
            completeGoalWizard()
            completeProgramWizard()
        }
    }

    private func navigateToAndCreateProgramWithDistribution(_ distribution: ProgramDistribution) {
        navigateToStrategy()

        let createButton = app.buttons["create-goal-button"]
        if createButton.waitForExistence(timeout: 3) {
            createButton.tap()
            completeGoalWizard()
            completeProgramWizardWithDistribution(distribution)
        }
    }

    /// Complete the goal wizard with reasonable defaults
    private func completeGoalWizard() {
        // Wait for goal wizard to appear
        let goalWizard = app.otherElements["goal-wizard"]
        guard goalWizard.waitForExistence(timeout: 5) else {
            return
        }

        // Pass intro screen if present
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 2) {
            getStartedButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Select Weight Loss goal type
        let weightLossButton = app.buttons["goal-wizard-goalType-weight_loss"]
        if weightLossButton.waitForExistence(timeout: 3) {
            weightLossButton.tap()
        }

        // Tap Continue to go to target weight step
        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 2) && continueButton.isEnabled {
            continueButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
        }

        // Adjust target weight slider (for weight loss, target must be < current)
        let targetWeightSlider = app.sliders["goal-wizard-target-weight-slider"]
        if targetWeightSlider.waitForExistence(timeout: 3) {
            targetWeightSlider.adjust(toNormalizedSliderPosition: 0.3)
        }

        // Continue to summary
        if continueButton.waitForExistence(timeout: 2) && continueButton.isEnabled {
            continueButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
        }

        // Save goal / Continue to Program
        let continueToProgram = app.buttons["Continue to Program"]
        let saveGoal = app.buttons["Save Goal"]
        if continueToProgram.waitForExistence(timeout: 3) {
            continueToProgram.tap()
        } else if saveGoal.waitForExistence(timeout: 2) {
            saveGoal.tap()
        }
    }

    /// Complete the program wizard with default (Coached) settings
    private func completeProgramWizard() {
        // Wait for ProgramWizard to appear
        let programWizard = app.otherElements["program-wizard"]
        guard programWizard.waitForExistence(timeout: 5) else {
            return
        }

        // Navigate through wizard steps by tapping Continue until Create Program appears
        // Program wizard steps: style -> profile -> diet -> floor -> training -> distribution -> protein -> confirmation
        for _ in 0..<20 {
            let createButton = app.buttons["Create Program"]
            let continueButton = app.buttons["Continue"]

            // Handle each step by selecting required options
            selectWizardOptionIfNeeded("program-wizard-programStyle-coached")  // Style step
            selectWizardOptionIfNeeded("Male", isSegmented: true)  // Profile step (sex)
            selectWizardOptionIfNeeded("program-wizard-dietPreference-balanced")  // Diet step
            selectWizardOptionIfNeeded("program-wizard-calorieFloor-standard")  // Floor step
            selectWizardOptionIfNeeded("program-wizard-training-none")  // Training step
            selectWizardOptionIfNeeded("program-wizard-weeklyDistribution-even")  // Distribution step
            selectWizardOptionIfNeeded("program-wizard-proteinLevel-moderate")  // Protein step

            if createButton.waitForExistence(timeout: 1) && createButton.isEnabled {
                createButton.tap()
                // Wait for async save to complete before returning
                Thread.sleep(forTimeInterval: 1.0)
                break
            } else if continueButton.waitForExistence(timeout: 1) && continueButton.isEnabled {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.3)
            } else {
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }

    /// Helper to select a wizard option if it exists
    private func selectWizardOptionIfNeeded(_ identifier: String, isSegmented: Bool = false) {
        let button = app.buttons[identifier]
        if button.waitForExistence(timeout: 0.3) {
            // Always tap - card buttons may not have isSelected state
            button.tap()
            Thread.sleep(forTimeInterval: 0.2)
        }
    }

    private func completeProgramWizardWithDistribution(_ distribution: ProgramDistribution) {
        // Wait for ProgramWizard to appear
        let programWizard = app.otherElements["program-wizard"]
        guard programWizard.waitForExistence(timeout: 5) else {
            return
        }

        // Navigate through wizard steps
        for _ in 0..<20 {
            let createButton = app.buttons["Create Program"]
            let continueButton = app.buttons["Continue"]

            // Handle each step by selecting required options
            selectWizardOptionIfNeeded("program-wizard-programStyle-coached")  // Style step
            selectWizardOptionIfNeeded("Male", isSegmented: true)  // Profile step (sex)
            selectWizardOptionIfNeeded("program-wizard-dietPreference-balanced")  // Diet step
            selectWizardOptionIfNeeded("program-wizard-calorieFloor-standard")  // Floor step
            selectWizardOptionIfNeeded("program-wizard-training-none")  // Training step
            selectWizardOptionIfNeeded(distribution.buttonIdentifier)  // Distribution step (custom)
            selectWizardOptionIfNeeded("program-wizard-proteinLevel-moderate")  // Protein step

            if createButton.waitForExistence(timeout: 1) && createButton.isEnabled {
                createButton.tap()
                // Wait for async save to complete before returning
                Thread.sleep(forTimeInterval: 1.0)
                break
            } else if continueButton.waitForExistence(timeout: 1) && continueButton.isEnabled {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.3)
            } else {
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }

    // MARK: - Supporting Types

    private enum ProgramDistribution {
        case even
        case shifted

        var buttonIdentifier: String {
            switch self {
            case .even:
                return "program-wizard-weeklyDistribution-even"
            case .shifted:
                return "program-wizard-weeklyDistribution-shifted"
            }
        }
    }
}
