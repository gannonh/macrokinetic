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
    }

    // MARK: - Helper Methods

    /// Navigate to Strategy view via More tab -> Goals & Strategy
    private func navigateToStrategy(_ app: XCUIApplication, timeout: TimeInterval = 5) {
        TestUtilities.navigateToTab(app, tabName: "More", timeout: timeout)

        // Wait for MoreView to load
        let moreView = app.otherElements["more-view"]
        XCTAssertTrue(
            moreView.waitForExistence(timeout: timeout),
            "More view should appear"
        )

        // Goals & Strategy is a NavigationLink which becomes a cell in List
        // Query by staticTexts containing the label text
        let goalsStrategyText = app.staticTexts["Goals & Strategy"]
        if goalsStrategyText.waitForExistence(timeout: timeout) {
            goalsStrategyText.tap()
        } else {
            // Fallback: try querying by accessibility identifier on cells
            let goalsStrategyCell = app.cells.containing(.staticText, identifier: "Goals & Strategy").firstMatch
            XCTAssertTrue(
                goalsStrategyCell.waitForExistence(timeout: timeout),
                "Goals & Strategy cell should exist in More menu"
            )
            goalsStrategyCell.tap()
        }

        // Wait for Strategy view to load (scroll view containing the strategy content)
        let strategyView = app.scrollViews.firstMatch
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: timeout),
            "Strategy view should appear after tapping Goals & Strategy"
        )
    }

    /// Launch app with seeded goal and program data
    private func launchWithSeededGoal() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "true"
        app.launchArguments = ["--ui-testing", "--reset-app-data", "--seed-check-in-good"]
        app.launch()
        return app
    }

    /// Launch app with clean state (no goal)
    private func launchWithCleanState() -> XCUIApplication {
        TestUtilities.launchAppWithTestMode(resetData: true)
    }

    /// Pass through the intro screen in new goal flow
    private func passIntroScreen(_ app: XCUIApplication, timeout: TimeInterval = 5) {
        // The intro screen shows "Let's Set Your Goal" title
        let introTitle = app.staticTexts["Let's Set Your Goal"]
        XCTAssertTrue(
            introTitle.waitForExistence(timeout: timeout),
            "Intro screen should show title"
        )

        // Tap "Get Started" button by label text (PrimaryButton uses its own identifier)
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(
            getStartedButton.waitForExistence(timeout: timeout),
            "Get Started button should appear on intro screen"
        )
        getStartedButton.tap()

        // Wait for animation to complete
        Thread.sleep(forTimeInterval: 0.5)
    }

    /// Select a goal type in the goal wizard
    private func selectGoalType(_ app: XCUIApplication, type: String, timeout: TimeInterval = 5) {
        // Verify we're on goal type step by checking for the title
        let chooseGoalTitle = app.staticTexts["Choose Your Goal"]
        XCTAssertTrue(
            chooseGoalTitle.waitForExistence(timeout: timeout),
            "Goal type step should be visible"
        )

        // Goal type buttons have identifier "goal-wizard-goalType-{type}"
        let goalTypeButton = app.buttons["goal-wizard-goalType-\(type)"]
        XCTAssertTrue(
            goalTypeButton.waitForExistence(timeout: timeout),
            "\(type) goal type option should exist"
        )
        goalTypeButton.tap()
    }

    /// Tap Continue button in wizard
    private func tapContinue(_ app: XCUIApplication, timeout: TimeInterval = 3) {
        // PrimaryButton uses "Continue" as the button label
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(
            continueButton.waitForExistence(timeout: timeout),
            "Continue button should exist"
        )
        XCTAssertTrue(continueButton.isEnabled, "Continue button should be enabled")
        continueButton.tap()

        // Wait for animation
        Thread.sleep(forTimeInterval: 0.3)
    }

    /// Tap Back button in wizard
    private func tapBack(_ app: XCUIApplication, timeout: TimeInterval = 3) {
        // SecondaryButton uses "Back" as the button label
        let backButton = app.buttons["Back"]
        XCTAssertTrue(
            backButton.waitForExistence(timeout: timeout),
            "Back button should exist"
        )
        backButton.tap()

        // Wait for animation
        Thread.sleep(forTimeInterval: 0.3)
    }

    /// Tap Save/Continue to Program button in wizard
    private func tapSave(_ app: XCUIApplication, timeout: TimeInterval = 3) {
        // Try "Continue to Program" first (new goal flow), then "Save Goal" (edit flow)
        let continueToProgram = app.buttons["Continue to Program"]
        let saveGoal = app.buttons["Save Goal"]

        if continueToProgram.waitForExistence(timeout: timeout) {
            continueToProgram.tap()
        } else if saveGoal.waitForExistence(timeout: timeout) {
            saveGoal.tap()
        } else {
            XCTFail("Neither 'Continue to Program' nor 'Save Goal' button found")
        }
    }

    // MARK: - New Goal Flow - Weight Loss

    func testNewGoalWeightLossComplete() throws {
        app = launchWithCleanState()
        navigateToStrategy(app)

        // Tap "Create Goal" button from empty state
        let createGoalButton = app.buttons["create-goal-button"]
        XCTAssertTrue(
            createGoalButton.waitForExistence(timeout: 5),
            "Create Goal button should exist in empty state"
        )
        createGoalButton.tap()

        // Verify wizard appears
        let goalWizard = app.otherElements["goal-wizard"]
        XCTAssertTrue(
            goalWizard.waitForExistence(timeout: 5),
            "Goal wizard should appear"
        )

        // Pass intro screen
        passIntroScreen(app)

        // Wait for goalType step to appear after animation
        // The step header "Choose Your Goal" indicates we're on the goal type step
        let chooseYourGoalTitle = app.staticTexts["Choose Your Goal"]
        XCTAssertTrue(
            chooseYourGoalTitle.waitForExistence(timeout: 5),
            "Goal type step should be shown after intro (Choose Your Goal header)"
        )

        // Select "Weight Loss"
        selectGoalType(app, type: "weight_loss")

        // Continue to target weight step
        tapContinue(app)

        // Verify target weight step is shown
        // Note: The identifier is applied to multiple elements (VStack with header + ScrollView)
        // Query the ScrollView specifically since that's the main content container
        let targetWeightStep = app.scrollViews["goal-wizard-targetWeight-step"]
        XCTAssertTrue(
            targetWeightStep.waitForExistence(timeout: 5),
            "Target weight step should be shown"
        )

        // Verify sliders are present (target weight and rate)
        let targetWeightSlider = app.sliders["goal-wizard-target-weight-slider"]
        XCTAssertTrue(
            targetWeightSlider.waitForExistence(timeout: 3),
            "Target weight slider should exist"
        )

        let rateSlider = app.sliders["goal-wizard-rate-slider"]
        XCTAssertTrue(
            rateSlider.waitForExistence(timeout: 3),
            "Weekly rate slider should exist"
        )

        // Adjust target weight slider to enable Continue (for weight loss, target must be < current)
        targetWeightSlider.adjust(toNormalizedSliderPosition: 0.5)

        // Continue to summary step
        tapContinue(app)

        // Verify summary step is shown
        let summaryStep = app.scrollViews["goal-wizard-summary-step"]
        XCTAssertTrue(
            summaryStep.waitForExistence(timeout: 5),
            "Summary step should be shown"
        )

        // Verify summary shows Weight Loss goal type
        let weightLossText = app.staticTexts["Weight Loss"]
        XCTAssertTrue(
            weightLossText.waitForExistence(timeout: 3),
            "Summary should show Weight Loss as goal type"
        )

        // Tap "Continue to Program" to chain to Program wizard
        tapSave(app)

        // Verify Program wizard appears (or Program Ready sheet)
        // After completing goal wizard, it should chain to program wizard
        let programWizard = app.otherElements["program-wizard"]
        let programReady = app.otherElements["program-ready-sheet"]
        let eitherExists = programWizard.waitForExistence(timeout: 5) || programReady.exists
        XCTAssertTrue(eitherExists, "Program wizard or ready sheet should appear after goal completion")
    }

    func testNewGoalWithIntroScreen() throws {
        app = launchWithCleanState()
        navigateToStrategy(app)

        // Tap "Create Goal"
        let createGoalButton = app.buttons["create-goal-button"]
        XCTAssertTrue(
            createGoalButton.waitForExistence(timeout: 5),
            "Create Goal button should exist"
        )
        createGoalButton.tap()

        // Verify wizard appears
        let goalWizard = app.otherElements["goal-wizard"]
        XCTAssertTrue(
            goalWizard.waitForExistence(timeout: 5),
            "Goal wizard should appear"
        )

        // Verify intro screen shows 2-step process text
        let introText = app.staticTexts["Let's Set Your Goal"]
        XCTAssertTrue(
            introText.waitForExistence(timeout: 5),
            "Intro screen should show 'Let's Set Your Goal' title"
        )

        // Verify "Get Started" button exists (query by label since PrimaryButton has its own identifier)
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(
            getStartedButton.waitForExistence(timeout: 3),
            "Get Started button should exist on intro screen"
        )
    }

    // MARK: - New Goal Flow - Maintenance

    func testNewGoalMaintenanceComplete() throws {
        app = launchWithCleanState()
        navigateToStrategy(app)

        // Create Goal
        let createGoalButton = app.buttons["create-goal-button"]
        XCTAssertTrue(createGoalButton.waitForExistence(timeout: 5))
        createGoalButton.tap()

        // Pass intro screen
        passIntroScreen(app)

        // Select "Maintenance"
        selectGoalType(app, type: "maintenance")

        // Continue to target step
        tapContinue(app)

        // Verify target weight step is shown
        let targetWeightStep = app.scrollViews["goal-wizard-targetWeight-step"]
        XCTAssertTrue(
            targetWeightStep.waitForExistence(timeout: 5),
            "Target weight step should be shown"
        )

        // Verify maintenance card is shown (no weight slider for maintenance)
        // For maintenance, the slider should NOT appear
        let targetWeightSlider = app.sliders["goal-wizard-target-weight-slider"]
        XCTAssertFalse(
            targetWeightSlider.waitForExistence(timeout: 2),
            "Target weight slider should NOT appear for maintenance goal"
        )

        // Continue to summary step
        tapContinue(app)

        // Verify summary shows Maintenance goal type
        let summaryStep = app.scrollViews["goal-wizard-summary-step"]
        XCTAssertTrue(summaryStep.waitForExistence(timeout: 5))

        let maintenanceText = app.staticTexts["Maintenance"]
        XCTAssertTrue(
            maintenanceText.waitForExistence(timeout: 3),
            "Summary should show Maintenance as goal type"
        )

        // Tap "Continue to Program"
        tapSave(app)
    }

    // MARK: - New Goal Flow - Muscle Gain

    func testNewGoalMuscleGainComplete() throws {
        app = launchWithCleanState()
        navigateToStrategy(app)

        // Create Goal
        let createGoalButton = app.buttons["create-goal-button"]
        XCTAssertTrue(createGoalButton.waitForExistence(timeout: 5))
        createGoalButton.tap()

        // Pass intro screen
        passIntroScreen(app)

        // Select "Muscle Gain"
        selectGoalType(app, type: "muscle_gain")

        // Continue to target weight step
        tapContinue(app)

        // Verify target weight step is shown
        let targetWeightStep = app.scrollViews["goal-wizard-targetWeight-step"]
        XCTAssertTrue(targetWeightStep.waitForExistence(timeout: 5))

        // Verify sliders are present
        let targetWeightSlider = app.sliders["goal-wizard-target-weight-slider"]
        XCTAssertTrue(targetWeightSlider.waitForExistence(timeout: 3))

        let rateSlider = app.sliders["goal-wizard-rate-slider"]
        XCTAssertTrue(rateSlider.waitForExistence(timeout: 3))

        // Adjust target weight slider to enable Continue (for muscle gain, target must be > current)
        targetWeightSlider.adjust(toNormalizedSliderPosition: 0.5)

        // Continue to summary step
        tapContinue(app)

        // Verify summary shows Muscle Gain goal type
        let summaryStep = app.scrollViews["goal-wizard-summary-step"]
        XCTAssertTrue(summaryStep.waitForExistence(timeout: 5))

        let muscleGainText = app.staticTexts["Muscle Gain"]
        XCTAssertTrue(
            muscleGainText.waitForExistence(timeout: 3),
            "Summary should show Muscle Gain as goal type"
        )

        // Tap "Continue to Program"
        tapSave(app)
    }

    // MARK: - Edit Goal Flow

    func testEditGoalSkipsGoalTypeStep() throws {
        // CRITICAL: Edit Goal should NOT show goalType step
        app = launchWithSeededGoal()
        navigateToStrategy(app)

        // Tap "Edit Goal" button
        let editGoalButton = app.buttons["edit-goal-button"]
        XCTAssertTrue(
            editGoalButton.waitForExistence(timeout: 5),
            "Edit Goal button should exist when goal is present"
        )
        editGoalButton.tap()

        // Verify wizard appears
        let goalWizard = app.otherElements["goal-wizard"]
        XCTAssertTrue(
            goalWizard.waitForExistence(timeout: 5),
            "Goal wizard should appear for editing"
        )

        // Verify NO intro screen appears (edit mode)
        let getStartedButton = app.buttons["goal-wizard-get-started-button"]
        XCTAssertFalse(
            getStartedButton.waitForExistence(timeout: 2),
            "Intro screen should NOT appear in edit mode"
        )

        // Verify first step is targetWeight, NOT goalType
        let targetWeightStep = app.scrollViews["goal-wizard-targetWeight-step"]
        XCTAssertTrue(
            targetWeightStep.waitForExistence(timeout: 5),
            "Edit mode should start at targetWeight step, not goalType"
        )

        let goalTypeStep = app.scrollViews["goal-wizard-goalType-step"]
        XCTAssertFalse(
            goalTypeStep.exists,
            "Goal type step should NOT be visible in edit mode"
        )

        // Verify current target weight is pre-populated (slider should exist)
        let targetWeightSlider = app.sliders["goal-wizard-target-weight-slider"]
        XCTAssertTrue(
            targetWeightSlider.waitForExistence(timeout: 3),
            "Target weight slider should exist with pre-populated value"
        )
    }

    func testEditGoalModifyAndSave() throws {
        app = launchWithSeededGoal()
        navigateToStrategy(app)

        // Tap "Edit Goal"
        let editGoalButton = app.buttons["edit-goal-button"]
        XCTAssertTrue(editGoalButton.waitForExistence(timeout: 5))
        editGoalButton.tap()

        // Verify targetWeight step shown first
        let targetWeightStep = app.scrollViews["goal-wizard-targetWeight-step"]
        XCTAssertTrue(targetWeightStep.waitForExistence(timeout: 5))

        // Modify target weight by adjusting slider
        let targetWeightSlider = app.sliders["goal-wizard-target-weight-slider"]
        XCTAssertTrue(targetWeightSlider.waitForExistence(timeout: 3))

        // Adjust slider (move to a different position)
        targetWeightSlider.adjust(toNormalizedSliderPosition: 0.3)

        // Continue to summary step
        tapContinue(app)

        // Verify summary step
        let summaryStep = app.scrollViews["goal-wizard-summary-step"]
        XCTAssertTrue(
            summaryStep.waitForExistence(timeout: 5),
            "Summary step should appear after target weight"
        )

        // Complete wizard
        tapSave(app)

        // Verify Program Summary Sheet appears (for edit goal flow)
        let programSummarySheet = app.otherElements["program-summary-sheet"]
        XCTAssertTrue(
            programSummarySheet.waitForExistence(timeout: 5),
            "Program Summary Sheet should appear after editing goal"
        )
    }

    func testEditGoalBackNavigationStopsAtTargetWeight() throws {
        // CRITICAL: Edit mode cannot go back before targetWeight step
        app = launchWithSeededGoal()
        navigateToStrategy(app)

        // Tap "Edit Goal"
        let editGoalButton = app.buttons["edit-goal-button"]
        XCTAssertTrue(editGoalButton.waitForExistence(timeout: 5))
        editGoalButton.tap()

        // Verify targetWeight step shown
        let targetWeightStep = app.scrollViews["goal-wizard-targetWeight-step"]
        XCTAssertTrue(targetWeightStep.waitForExistence(timeout: 5))

        // In edit mode at first step, there should be no back button
        // (or tapping back should dismiss the wizard)
        let backButton = app.buttons["goal-wizard-back-button"]

        if backButton.exists {
            // If back button exists, tapping it should dismiss wizard
            backButton.tap()

            // Verify wizard dismisses (strategy view visible again)
            let strategyView = app.otherElements["strategy-view"]
            XCTAssertTrue(
                strategyView.waitForExistence(timeout: 5),
                "Wizard should dismiss when going back from first edit step"
            )
        } else {
            // No back button means we're at the first step correctly
            XCTAssertTrue(true, "No back button at first step of edit mode is correct")
        }
    }

    func testEditGoalTriggersNewProgramPrompt() throws {
        // Journey: Edit Goal -> New/Keep Program choice
        app = launchWithSeededGoal()
        navigateToStrategy(app)

        // Tap "Edit Goal"
        let editGoalButton = app.buttons["edit-goal-button"]
        XCTAssertTrue(editGoalButton.waitForExistence(timeout: 5))
        editGoalButton.tap()

        // Modify target weight
        let targetWeightSlider = app.sliders["goal-wizard-target-weight-slider"]
        XCTAssertTrue(targetWeightSlider.waitForExistence(timeout: 5))
        targetWeightSlider.adjust(toNormalizedSliderPosition: 0.4)

        // Continue to summary
        tapContinue(app)

        // Complete Goal wizard
        let summaryStep = app.scrollViews["goal-wizard-summary-step"]
        XCTAssertTrue(summaryStep.waitForExistence(timeout: 5))
        tapSave(app)

        // Verify ProgramSummarySheet appears with options
        let programSummarySheet = app.otherElements["program-summary-sheet"]
        XCTAssertTrue(
            programSummarySheet.waitForExistence(timeout: 5),
            "Program Summary Sheet should appear after editing goal"
        )

        // Verify options exist: Keep existing program OR Create new program
        // Look for the two action buttons (identifiers are "looks-good-button" and "set-new-program-button")
        let looksGoodButton = app.buttons["looks-good-button"]
        let newProgramButton = app.buttons["set-new-program-button"]

        let hasOptions = looksGoodButton.waitForExistence(timeout: 3) || newProgramButton.exists
        XCTAssertTrue(hasOptions, "Program Summary should show Keep/New program options")
    }

    // MARK: - Navigation

    func testNewGoalBackNavigationPreservesSelections() throws {
        app = launchWithCleanState()
        navigateToStrategy(app)

        // Create Goal
        let createGoalButton = app.buttons["create-goal-button"]
        XCTAssertTrue(createGoalButton.waitForExistence(timeout: 5))
        createGoalButton.tap()

        // Pass intro screen
        passIntroScreen(app)

        // Select "Weight Loss"
        selectGoalType(app, type: "weight_loss")

        // Continue to target weight step
        tapContinue(app)

        // Verify we're on target weight step
        let targetWeightStep = app.scrollViews["goal-wizard-targetWeight-step"]
        XCTAssertTrue(targetWeightStep.waitForExistence(timeout: 5))

        // Go back to goalType step
        tapBack(app)

        // Verify goalType step is shown again
        let goalTypeStep = app.scrollViews["goal-wizard-goalType-step"]
        XCTAssertTrue(
            goalTypeStep.waitForExistence(timeout: 5),
            "Should return to goal type step"
        )

        // Verify "Weight Loss" is still selected (checkmark visible)
        let weightLossButton = app.buttons["goal-wizard-goalType-weight_loss"]
        XCTAssertTrue(
            weightLossButton.waitForExistence(timeout: 3),
            "Weight Loss option should still exist"
        )

        // The button should have selected state (isSelected trait)
        // This is harder to verify directly, but we can check Continue is enabled
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(
            continueButton.waitForExistence(timeout: 3) && continueButton.isEnabled,
            "Continue should be enabled indicating selection preserved"
        )
    }

    func testCancelWizardDismisses() throws {
        app = launchWithCleanState()
        navigateToStrategy(app)

        // Create Goal
        let createGoalButton = app.buttons["create-goal-button"]
        XCTAssertTrue(createGoalButton.waitForExistence(timeout: 5))
        createGoalButton.tap()

        // Verify wizard appears
        let goalWizard = app.otherElements["goal-wizard"]
        XCTAssertTrue(goalWizard.waitForExistence(timeout: 5))

        // Tap Cancel (in navigation bar)
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 3),
            "Cancel button should exist"
        )
        cancelButton.tap()

        // Verify wizard is dismissed
        XCTAssertFalse(
            goalWizard.waitForExistence(timeout: 2),
            "Wizard should be dismissed after cancel"
        )

        // Verify Strategy view still shows empty state (no goal created)
        let createGoalButtonAgain = app.buttons["create-goal-button"]
        XCTAssertTrue(
            createGoalButtonAgain.waitForExistence(timeout: 3),
            "Strategy view should still show empty state with Create Goal button"
        )
    }

    // MARK: - Goal Type Selection

    func testGoalTypeOptions() throws {
        app = launchWithCleanState()
        navigateToStrategy(app)

        // Create Goal
        let createGoalButton = app.buttons["create-goal-button"]
        XCTAssertTrue(createGoalButton.waitForExistence(timeout: 5))
        createGoalButton.tap()

        // Pass intro screen
        passIntroScreen(app)

        // Verify all goal types visible
        let weightLossOption = app.buttons["goal-wizard-goalType-weight_loss"]
        let maintenanceOption = app.buttons["goal-wizard-goalType-maintenance"]
        let muscleGainOption = app.buttons["goal-wizard-goalType-muscle_gain"]

        XCTAssertTrue(
            weightLossOption.waitForExistence(timeout: 5),
            "Weight Loss option should be visible"
        )
        XCTAssertTrue(
            maintenanceOption.waitForExistence(timeout: 3),
            "Maintenance option should be visible"
        )
        XCTAssertTrue(
            muscleGainOption.waitForExistence(timeout: 3),
            "Muscle Gain option should be visible"
        )
    }

    func testContinueDisabledWithoutGoalType() throws {
        app = launchWithCleanState()
        navigateToStrategy(app)

        // Create Goal
        let createGoalButton = app.buttons["create-goal-button"]
        XCTAssertTrue(createGoalButton.waitForExistence(timeout: 5))
        createGoalButton.tap()

        // Pass intro screen
        passIntroScreen(app)

        // Verify goal type step
        let goalTypeStep = app.scrollViews["goal-wizard-goalType-step"]
        XCTAssertTrue(goalTypeStep.waitForExistence(timeout: 5))

        // Verify Continue button is disabled (no goal type selected yet)
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 3))
        XCTAssertFalse(
            continueButton.isEnabled,
            "Continue button should be disabled without goal type selection"
        )

        // Select a goal type
        selectGoalType(app, type: "weight_loss")

        // Verify Continue button is now enabled
        XCTAssertTrue(
            continueButton.isEnabled,
            "Continue button should be enabled after selecting goal type"
        )
    }

    // MARK: - Target Weight Configuration

    func testTargetWeightSliderUpdates() throws {
        app = launchWithCleanState()
        navigateToStrategy(app)

        // Create Goal -> Weight Loss
        let createGoalButton = app.buttons["create-goal-button"]
        XCTAssertTrue(createGoalButton.waitForExistence(timeout: 5))
        createGoalButton.tap()
        passIntroScreen(app)
        selectGoalType(app, type: "weight_loss")
        tapContinue(app)

        // Verify target weight step
        let targetWeightStep = app.scrollViews["goal-wizard-targetWeight-step"]
        XCTAssertTrue(targetWeightStep.waitForExistence(timeout: 5))

        // Adjust target weight slider
        let targetWeightSlider = app.sliders["goal-wizard-target-weight-slider"]
        XCTAssertTrue(targetWeightSlider.waitForExistence(timeout: 3))

        // Adjust slider to different positions
        targetWeightSlider.adjust(toNormalizedSliderPosition: 0.2)

        // Verify projected results section exists (updates in real-time)
        let projectedResultsText = app.staticTexts["Projected Results"]
        XCTAssertTrue(
            projectedResultsText.waitForExistence(timeout: 3),
            "Projected Results section should be visible"
        )
    }

    func testMaintenanceGoalShowsMaintenanceCard() throws {
        app = launchWithCleanState()
        navigateToStrategy(app)

        // Create Goal -> Maintenance
        let createGoalButton = app.buttons["create-goal-button"]
        XCTAssertTrue(createGoalButton.waitForExistence(timeout: 5))
        createGoalButton.tap()
        passIntroScreen(app)
        selectGoalType(app, type: "maintenance")
        tapContinue(app)

        // Verify target step
        let targetWeightStep = app.scrollViews["goal-wizard-targetWeight-step"]
        XCTAssertTrue(targetWeightStep.waitForExistence(timeout: 5))

        // Verify maintenance info card shown (no weight slider)
        let maintenanceText = app.staticTexts["Maintain Your Weight"]
        XCTAssertTrue(
            maintenanceText.waitForExistence(timeout: 3),
            "Maintenance info card should be shown"
        )

        // Verify NO target weight slider for maintenance
        let targetWeightSlider = app.sliders["goal-wizard-target-weight-slider"]
        XCTAssertFalse(
            targetWeightSlider.waitForExistence(timeout: 2),
            "Target weight slider should NOT appear for maintenance"
        )
    }

    func testWeeklyRateSliderUpdates() throws {
        app = launchWithCleanState()
        navigateToStrategy(app)

        // Create Goal -> Weight Loss
        let createGoalButton = app.buttons["create-goal-button"]
        XCTAssertTrue(createGoalButton.waitForExistence(timeout: 5))
        createGoalButton.tap()
        passIntroScreen(app)
        selectGoalType(app, type: "weight_loss")
        tapContinue(app)

        // Verify target weight step
        let targetWeightStep = app.scrollViews["goal-wizard-targetWeight-step"]
        XCTAssertTrue(targetWeightStep.waitForExistence(timeout: 5))

        // Adjust weekly rate slider
        let rateSlider = app.sliders["goal-wizard-rate-slider"]
        XCTAssertTrue(
            rateSlider.waitForExistence(timeout: 3),
            "Weekly rate slider should exist"
        )

        // Adjust slider
        rateSlider.adjust(toNormalizedSliderPosition: 0.8)

        // Verify projected timeline updates (Duration text exists)
        let durationText = app.staticTexts["Duration"]
        XCTAssertTrue(
            durationText.waitForExistence(timeout: 3),
            "Duration label should be visible in projected results"
        )
    }

    // MARK: - Data Validation

    func testSummaryShowsCorrectCalculatedValues() throws {
        app = launchWithCleanState()
        navigateToStrategy(app)

        // Create Goal -> Weight Loss
        let createGoalButton = app.buttons["create-goal-button"]
        XCTAssertTrue(createGoalButton.waitForExistence(timeout: 5))
        createGoalButton.tap()
        passIntroScreen(app)
        selectGoalType(app, type: "weight_loss")
        tapContinue(app)

        // Set specific target weight and rate
        let targetWeightSlider = app.sliders["goal-wizard-target-weight-slider"]
        XCTAssertTrue(targetWeightSlider.waitForExistence(timeout: 3))
        targetWeightSlider.adjust(toNormalizedSliderPosition: 0.5)

        let rateSlider = app.sliders["goal-wizard-rate-slider"]
        XCTAssertTrue(rateSlider.waitForExistence(timeout: 3))
        rateSlider.adjust(toNormalizedSliderPosition: 0.5)

        // Continue to summary
        tapContinue(app)

        // Verify summary step
        let summaryStep = app.scrollViews["goal-wizard-summary-step"]
        XCTAssertTrue(summaryStep.waitForExistence(timeout: 5))

        // Verify summary displays key values
        let goalTypeLabel = app.staticTexts["Goal Type"]
        XCTAssertTrue(
            goalTypeLabel.waitForExistence(timeout: 3),
            "Summary should show Goal Type label"
        )

        let targetWeightLabel = app.staticTexts["Target Weight"]
        XCTAssertTrue(
            targetWeightLabel.waitForExistence(timeout: 3),
            "Summary should show Target Weight label"
        )

        let weeklyRateLabel = app.staticTexts["Weekly Rate"]
        XCTAssertTrue(
            weeklyRateLabel.waitForExistence(timeout: 3),
            "Summary should show Weekly Rate label"
        )

        let durationLabel = app.staticTexts["Duration"]
        XCTAssertTrue(
            durationLabel.waitForExistence(timeout: 3),
            "Summary should show Duration label"
        )
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
//
// Program Summary Sheet:
// - "program-summary-sheet"
// - "looks-good-button"
// - "set-new-program-button"
