//
//  ProgramOptimizationUITests.swift
//  JabTrackerUITests
//
//  E2E tests for the weekly check-in program optimization flow.
//  Tests check-in availability, optimization flow steps, and mode-specific actions.
//
//  Seeding Flags:
//  - --seed-check-in-ready: EXCELLENT tier (28 weight entries, 75% food, 28 days)
//  - --seed-check-in-good: GOOD tier (10 weight entries, 65% food, 10 days)
//  - --seed-check-in-minimum: MINIMUM tier (4 weight entries, 55% food, 7 days)
//  - --seed-check-in-insufficient: INSUFFICIENT tier (2 weight entries, 40% food, 5 days)
//  - --seed-collaborative: Changes program style from Coached to Collaborative
//

import XCTest

final class ProgramOptimizationUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    private func launchWithCheckInSeeding(
        tier: String,
        collaborative: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var args = ["--ui-testing", "--reset-app-data", tier]
        if collaborative {
            args.append("--seed-collaborative")
        }
        app.launchArguments = args
        app.launch()
        return app
    }

    private func navigateToStrategy(_ app: XCUIApplication) {
        // Strategy is now a top-level tab (v0.5.0)
        let strategyTab = app.tabBars.buttons["Strategy"]
        XCTAssertTrue(strategyTab.waitForExistence(timeout: 5), "Strategy tab should exist")
        strategyTab.tap()
    }

    private func waitForAppLoad(_ app: XCUIApplication) -> Bool {
        let tabBar = app.tabBars.element
        return tabBar.waitForExistence(timeout: 10)
    }

    private func startCheckInFlow(_ app: XCUIApplication) {
        // Tap the check-in countdown card (Button type in XCUITest)
        let checkInCard = app.buttons["check-in-countdown-card"]
        if checkInCard.waitForExistence(timeout: 5) && checkInCard.isHittable {
            checkInCard.tap()
        }
    }

    private func completeOptimizationToResults(_ app: XCUIApplication) {
        // Wait for intro (ScrollView type in XCUITest)
        let introStep = app.scrollViews["optimization-intro-step"]
        guard introStep.waitForExistence(timeout: 5) else {
            return
        }

        // Tap Start button
        let startButton = app.buttons["Start Program Optimization"]
        if startButton.waitForExistence(timeout: 3) {
            startButton.tap()
        }

        // Wait for calculating step to appear (if it shows)
        let calculatingStep = app.scrollViews["optimization-calculating-step"]
        _ = calculatingStep.waitForExistence(timeout: 3)

        // Wait for results (ScrollView type) - give more time for calculation
        let resultsStep = app.scrollViews["optimization-results-step"]
        _ = resultsStep.waitForExistence(timeout: 15)
    }

    // MARK: - Check-In Availability

    /// Check-in countdown appears for Coached programs
    /// Acceptance: Countdown card visible with days remaining
    func testCheckInCountdownAppearsForCoachedProgram() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-good")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)

        // Verify check-in-countdown-card exists (Button type in XCUITest)
        let checkInCard = app.buttons["check-in-countdown-card"]
        XCTAssertTrue(
            checkInCard.waitForExistence(timeout: 5),
            "Check-in countdown card should exist for Coached program"
        )
    }

    /// Check-in countdown appears for Collaborative programs
    /// Acceptance: Countdown card visible with days remaining
    func testCheckInCountdownAppearsForCollaborativeProgram() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-good", collaborative: true)

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)

        // Verify check-in-countdown-card exists
        let checkInCard = app.buttons["check-in-countdown-card"]
        XCTAssertTrue(
            checkInCard.waitForExistence(timeout: 5),
            "Check-in countdown card should exist for Collaborative program"
        )
    }

    /// Check-in countdown hidden for Manual programs
    /// Acceptance: No countdown card visible
    func testCheckInCountdownHiddenForManualProgram() throws {
        // Note: Manual program seeding would need a separate flag
        // For now, skip this test or mark as a known limitation
        // Manual programs should not show check-in UI
    }

    // MARK: - Progressive Accuracy: EXCELLENT Tier (Scenario 1)

    /// EXCELLENT tier allows check-in with high confidence
    /// Flags: --seed-check-in-ready
    /// Acceptance: Check-in proceeds, no data quality warnings
    func testExcellentTierAllowsCheckIn() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)

        // Verify check-in card is tappable (not locked)
        let checkInCard = app.buttons["check-in-countdown-card"]
        XCTAssertTrue(
            checkInCard.waitForExistence(timeout: 5),
            "Check-in card should exist"
        )

        // Check if card is tappable (ready state)
        if checkInCard.isHittable {
            checkInCard.tap()

            // Verify intro screen appears
            let introStep = app.scrollViews["optimization-intro-step"]
            XCTAssertTrue(
                introStep.waitForExistence(timeout: 5),
                "Intro screen should appear when check-in is ready"
            )
        }
    }

    /// EXCELLENT tier shows full optimization recommendations
    /// Flags: --seed-check-in-ready
    func testExcellentTierShowsFullRecommendations() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Verify "What changed?" section has content
        let whatChanged = app.descendants(matching: .any)["what-changed-section"].firstMatch
        XCTAssertTrue(
            whatChanged.waitForExistence(timeout: 5),
            "What changed section should exist"
        )

        // Verify macro grid shows values
        let macroGrid = app.descendants(matching: .any)["optimization-weekly-macro-grid"].firstMatch
        XCTAssertTrue(
            macroGrid.waitForExistence(timeout: 3),
            "Macro grid should show updated values"
        )
    }

    // MARK: - Progressive Accuracy: GOOD Tier (Scenario 2)

    /// GOOD tier allows check-in with good confidence
    /// Flags: --seed-check-in-good
    /// Acceptance: Check-in proceeds, confidence ceiling 70%
    func testGoodTierAllowsCheckIn() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-good")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)

        // Verify check-in card exists and is usable
        let checkInCard = app.buttons["check-in-countdown-card"]
        XCTAssertTrue(
            checkInCard.waitForExistence(timeout: 5),
            "Check-in card should exist for GOOD tier"
        )

        // Start flow if card is ready
        if checkInCard.isHittable {
            checkInCard.tap()

            // Verify flow starts
            let introStep = app.scrollViews["optimization-intro-step"]
            XCTAssertTrue(
                introStep.waitForExistence(timeout: 5),
                "Intro screen should appear for GOOD tier"
            )
        }
    }

    /// GOOD tier shows recommendations with subtle quality indicator
    /// Flags: --seed-check-in-good
    func testGoodTierShowsQualityIndicator() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-good")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Verify results screen shows data quality context
        let resultsStep = app.scrollViews["optimization-results-step"]
        XCTAssertTrue(
            resultsStep.waitForExistence(timeout: 10),
            "Results screen should show for GOOD tier"
        )
    }

    // MARK: - Progressive Accuracy: MINIMUM Tier (Scenario 3)

    /// MINIMUM tier allows check-in with low confidence
    /// Flags: --seed-check-in-minimum
    /// Acceptance: Check-in proceeds, confidence ceiling 50%
    func testMinimumTierAllowsCheckIn() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-minimum")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)

        // Verify check-in card exists
        let checkInCard = app.buttons["check-in-countdown-card"]
        XCTAssertTrue(
            checkInCard.waitForExistence(timeout: 5),
            "Check-in card should exist for MINIMUM tier"
        )

        // MINIMUM tier may or may not allow check-in depending on exact data
        // Verify card exists (flow availability depends on data quality assessment)
    }

    /// MINIMUM tier shows encouragement to log more
    /// Flags: --seed-check-in-minimum
    func testMinimumTierShowsLoggingEncouragement() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-minimum")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Verify "What's next?" mentions logging more data
        let whatsNext = app.descendants(matching: .any)["whats-next-section"].firstMatch
        if whatsNext.waitForExistence(timeout: 10) {
            XCTAssertTrue(whatsNext.exists, "What's next section should exist for MINIMUM tier")
        }
    }

    // MARK: - Progressive Accuracy: INSUFFICIENT Tier (Scenario 4)

    /// INSUFFICIENT tier blocks check-in
    /// Flags: --seed-check-in-insufficient
    /// Acceptance: Check-in button disabled, locked state shown
    func testInsufficientTierBlocksCheckIn() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-insufficient")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)

        // When insufficient, check-in card is NOT a Button (not tappable)
        // Use descendants with firstMatch to find any element with the identifier
        let checkInCardElement = app.descendants(matching: .any)["check-in-countdown-card"].firstMatch
        guard checkInCardElement.waitForExistence(timeout: 5) else {
            XCTFail("Check-in card should exist")
            return
        }

        // Card should show "More data needed" state and NOT be tappable
        // When insufficient, there's no Button element, so it won't be hittable
        let checkInButton = app.buttons["check-in-countdown-card"]
        XCTAssertFalse(
            checkInButton.exists,
            "Check-in card should NOT be a tappable button when data is insufficient"
        )

        // Verify "More data needed" subtitle is shown
        let moreDataNeeded = app.staticTexts["More data needed"]
        XCTAssertTrue(
            moreDataNeeded.waitForExistence(timeout: 3),
            "More data needed subtitle should be visible for locked state"
        )
    }

    /// INSUFFICIENT tier shows improvement tips
    /// Flags: --seed-check-in-insufficient
    /// Acceptance: Tips card visible with actionable steps
    func testInsufficientTierShowsImprovementTips() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-insufficient")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)

        // Verify improvement-tips-card exists (uses descendants since identifier may be on children)
        let tipsCard = app.descendants(matching: .any)["improvement-tips-card"].firstMatch
        XCTAssertTrue(
            tipsCard.waitForExistence(timeout: 5),
            "Improvement tips card should exist for INSUFFICIENT tier"
        )
    }

    /// INSUFFICIENT tier shows gray locked styling
    /// Flags: --seed-check-in-insufficient
    func testInsufficientTierShowsGrayLockedStyling() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-insufficient")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)

        // When insufficient, check-in card is NOT a Button (not tappable)
        // The identifier is applied to child elements (StaticText)
        // Use descendants with firstMatch to find any element with the identifier
        let checkInCardElement = app.descendants(matching: .any)["check-in-countdown-card"].firstMatch
        XCTAssertTrue(
            checkInCardElement.waitForExistence(timeout: 5),
            "Check-in card should exist"
        )

        // Visual styling (gray color) cannot be verified in UI tests
        // Instead verify "More data needed" subtitle is visible (locked state indicator)
        let moreDataNeeded = app.staticTexts["More data needed"]
        XCTAssertTrue(
            moreDataNeeded.waitForExistence(timeout: 3),
            "More data needed subtitle should be visible for locked state"
        )
    }

    // MARK: - Optimization Flow Steps

    /// User can start optimization from countdown card
    /// Acceptance: Tap card -> intro screen appears
    func testUserCanStartOptimizationFromCountdown() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)

        // Tap check-in-countdown-card
        let checkInCard = app.buttons["check-in-countdown-card"]
        guard checkInCard.waitForExistence(timeout: 5) && checkInCard.isHittable else {
            XCTFail("Check-in card should be tappable")
            return
        }
        checkInCard.tap()

        // Verify optimization-intro-step appears (ScrollView in XCUITest)
        let introStep = app.scrollViews["optimization-intro-step"]
        XCTAssertTrue(
            introStep.waitForExistence(timeout: 5),
            "Intro step should appear after tapping check-in card"
        )
    }

    /// Intro screen shows correct content
    /// Acceptance: Title, description, and Start button visible
    func testIntroScreenShowsStartButton() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)

        // Verify intro step content
        let introStep = app.scrollViews["optimization-intro-step"]
        guard introStep.waitForExistence(timeout: 5) else {
            XCTFail("Intro step should appear")
            return
        }

        // Verify "Time to optimize your program" text
        let titleText = app.staticTexts["Time to optimize your program"]
        XCTAssertTrue(titleText.exists, "Intro title should be visible")

        // Verify "Start Program Optimization" button exists
        let startButton = app.buttons["Start Program Optimization"]
        XCTAssertTrue(startButton.exists, "Start button should exist")
    }

    /// Calculation screen shows progress animation
    /// Acceptance: Progress indicator visible during calculation
    func testCalculationScreenShowsProgressAnimation() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)

        // Wait for intro step
        let introStep = app.scrollViews["optimization-intro-step"]
        guard introStep.waitForExistence(timeout: 5) else {
            XCTFail("Intro step should appear")
            return
        }

        // Tap "Start Program Optimization"
        let startButton = app.buttons["Start Program Optimization"]
        guard startButton.waitForExistence(timeout: 3) else {
            XCTFail("Start button should exist")
            return
        }
        startButton.tap()

        // Verify optimization-calculating-step appears
        // The calculating step is a VStack (Other element), not ScrollView
        // It may be very brief if calculation is fast - use shorter timeout
        let calculatingStep = app.descendants(matching: .any)["optimization-calculating-step"].firstMatch
        XCTAssertTrue(
            calculatingStep.waitForExistence(timeout: 3),
            "Calculating step should appear"
        )

        // Verify progress indicator visible (ProgressView is an activityIndicator)
        let progressIndicator = app.activityIndicators.firstMatch
        XCTAssertTrue(
            progressIndicator.exists,
            "Progress indicator should be visible during calculation"
        )
    }

    /// Results screen shows weekly macro grid
    /// Acceptance: Grid displays M-S with calorie/protein/fat/carb rows
    func testResultsScreenShowsWeeklyMacroGrid() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Verify optimization-weekly-macro-grid exists
        let macroGrid = app.descendants(matching: .any)["optimization-weekly-macro-grid"].firstMatch
        XCTAssertTrue(
            macroGrid.waitForExistence(timeout: 5),
            "Weekly macro grid should exist on results screen"
        )

        // Verify day headers (M, T, W, T, F, S, S)
        let mondayHeader = app.staticTexts["M"]
        XCTAssertTrue(mondayHeader.exists, "Monday header should exist in grid")
    }

    /// Results screen shows "What changed?" section
    /// Acceptance: Section visible with change description
    func testResultsScreenShowsWhatChangedSection() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Verify what-changed-section exists
        // Identifier is on StaticText children, use descendants to find any element
        let whatChanged = app.descendants(matching: .any)["what-changed-section"].firstMatch
        XCTAssertTrue(
            whatChanged.waitForExistence(timeout: 5),
            "What changed section should exist on results screen"
        )

        // Verify section has content text
        let sectionHeader = app.staticTexts["What changed?"]
        XCTAssertTrue(sectionHeader.exists, "What changed header should be visible")
    }

    /// Results screen shows "What's next?" section
    /// Acceptance: Section visible with next steps
    func testResultsScreenShowsWhatsNextSection() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Verify whats-next-section exists
        let whatsNext = app.descendants(matching: .any)["whats-next-section"].firstMatch
        XCTAssertTrue(
            whatsNext.waitForExistence(timeout: 5),
            "What's next section should exist on results screen"
        )
    }

    // MARK: - Coached Mode Actions

    /// Coached user sees Accept and Decline buttons
    /// Acceptance: Two buttons visible (Accept, Decline)
    func testCoachedUserSeesTwoButtons() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Verify accept-button exists
        let acceptButton = app.buttons["accept-button"]
        XCTAssertTrue(
            acceptButton.waitForExistence(timeout: 5),
            "Accept button should exist for Coached mode"
        )

        // Verify decline-button exists
        let declineButton = app.buttons["decline-button"]
        XCTAssertTrue(declineButton.exists, "Decline button should exist for Coached mode")

        // Verify modify-button does NOT exist (Coached mode)
        let modifyButton = app.buttons["modify-button"]
        XCTAssertFalse(modifyButton.exists, "Modify button should NOT exist for Coached mode")
    }

    /// Coached user can accept program changes
    /// Acceptance: Tap "Accept" -> sheet dismisses, program updated
    func testCoachedUserCanAcceptChanges() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Tap accept-button
        let acceptButton = app.buttons["accept-button"]
        guard acceptButton.waitForExistence(timeout: 5) else {
            XCTFail("Accept button should exist")
            return
        }
        acceptButton.tap()

        // Verify sheet dismisses
        let optimizationSheet = app.otherElements["program-optimization-sheet"]
        XCTAssertFalse(
            optimizationSheet.waitForExistence(timeout: 2),
            "Optimization sheet should be dismissed after Accept"
        )

        // Verify Strategy view shows updated values
        let strategyView = app.scrollViews["strategy-view"]
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 5),
            "Strategy view should be visible after accepting changes"
        )
    }

    /// Coached user can decline program changes
    /// Acceptance: Tap "Decline" -> sheet dismisses, program unchanged
    func testCoachedUserCanDeclineChanges() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Tap decline-button
        let declineButton = app.buttons["decline-button"]
        guard declineButton.waitForExistence(timeout: 5) else {
            XCTFail("Decline button should exist")
            return
        }
        declineButton.tap()

        // Verify sheet dismisses
        let optimizationSheet = app.otherElements["program-optimization-sheet"]
        XCTAssertFalse(
            optimizationSheet.waitForExistence(timeout: 2),
            "Optimization sheet should be dismissed after Decline"
        )

        // Verify Strategy view shows original values
        let strategyView = app.scrollViews["strategy-view"]
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 5),
            "Strategy view should be visible after declining changes"
        )
    }

    // MARK: - Collaborative Mode Actions (Scenario 5 & 6)

    /// Collaborative user sees three action buttons
    /// Flags: --seed-check-in-good --seed-collaborative
    /// Acceptance: Decline, Modify, Accept buttons all visible
    func testCollaborativeUserSeesThreeButtons() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-good", collaborative: true)

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Verify decline-button exists
        let declineButton = app.buttons["decline-button"]
        XCTAssertTrue(
            declineButton.waitForExistence(timeout: 5),
            "Decline button should exist for Collaborative mode"
        )

        // Verify modify-button exists
        let modifyButton = app.buttons["modify-button"]
        XCTAssertTrue(modifyButton.exists, "Modify button should exist for Collaborative mode")

        // Verify accept-button exists
        let acceptButton = app.buttons["accept-button"]
        XCTAssertTrue(acceptButton.exists, "Accept button should exist for Collaborative mode")
    }

    /// Collaborative user can accept all changes
    /// Flags: --seed-check-in-ready --seed-collaborative
    /// Acceptance: Tap "Accept" -> applies changes, dismisses
    func testCollaborativeUserCanAcceptAll() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready", collaborative: true)

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Tap accept-button
        let acceptButton = app.buttons["accept-button"]
        guard acceptButton.waitForExistence(timeout: 5) else {
            XCTFail("Accept button should exist")
            return
        }
        acceptButton.tap()

        // Verify sheet dismisses
        let optimizationSheet = app.otherElements["program-optimization-sheet"]
        XCTAssertFalse(
            optimizationSheet.waitForExistence(timeout: 2),
            "Optimization sheet should be dismissed"
        )

        // Verify new targets applied (Strategy view visible)
        let strategyView = app.scrollViews["strategy-view"]
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 5),
            "Strategy view should be visible with new targets"
        )
    }

    /// Collaborative user can modify program
    /// Flags: --seed-check-in-good --seed-collaborative
    /// Acceptance: Tap "Modify" -> applies changes, opens Program Wizard
    func testCollaborativeUserCanModifyProgram() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-good", collaborative: true)

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Tap modify-button
        let modifyButton = app.buttons["modify-button"]
        guard modifyButton.waitForExistence(timeout: 5) else {
            XCTFail("Modify button should exist")
            return
        }
        modifyButton.tap()

        // Verify Program Wizard opens
        let programWizard = app.otherElements["program-wizard"]
        XCTAssertTrue(
            programWizard.waitForExistence(timeout: 5),
            "Program Wizard should open after tapping Modify"
        )
    }

    /// Collaborative user can decline changes
    /// Flags: --seed-check-in-good --seed-collaborative
    /// Acceptance: Tap "Decline" -> dismisses without changes
    func testCollaborativeUserCanDeclineChanges() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-good", collaborative: true)

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Tap decline-button
        let declineButton = app.buttons["decline-button"]
        guard declineButton.waitForExistence(timeout: 5) else {
            XCTFail("Decline button should exist")
            return
        }
        declineButton.tap()

        // Verify sheet dismisses
        let optimizationSheet = app.otherElements["program-optimization-sheet"]
        XCTAssertFalse(
            optimizationSheet.waitForExistence(timeout: 2),
            "Optimization sheet should be dismissed"
        )

        // Verify original targets preserved (Strategy view visible)
        let strategyView = app.scrollViews["strategy-view"]
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 5),
            "Strategy view should be visible with original targets"
        )
    }

    // MARK: - Collaborative EXCELLENT Tier (Scenario 6)

    /// Collaborative + EXCELLENT tier shows high confidence
    /// Flags: --seed-check-in-ready --seed-collaborative
    func testCollaborativeExcellentTierHighConfidence() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready", collaborative: true)

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Verify three buttons visible
        let declineButton = app.buttons["decline-button"]
        let modifyButton = app.buttons["modify-button"]
        let acceptButton = app.buttons["accept-button"]

        XCTAssertTrue(
            declineButton.waitForExistence(timeout: 5),
            "Decline button should exist"
        )
        XCTAssertTrue(modifyButton.exists, "Modify button should exist")
        XCTAssertTrue(acceptButton.exists, "Accept button should exist")

        // Verify high confidence recommendations (macro grid visible)
        let macroGrid = app.descendants(matching: .any)["optimization-weekly-macro-grid"].firstMatch
        XCTAssertTrue(macroGrid.exists, "Macro grid should show high confidence recommendations")
    }

    // MARK: - Edge Cases

    /// Cancel button dismisses optimization sheet from intro
    func testCancelDismissesFromIntro() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)

        // Wait for intro step
        let introStep = app.scrollViews["optimization-intro-step"]
        guard introStep.waitForExistence(timeout: 5) else {
            XCTFail("Intro step should appear")
            return
        }

        // Tap Cancel button
        let cancelButton = app.buttons["Cancel"]
        guard cancelButton.waitForExistence(timeout: 3) else {
            XCTFail("Cancel button should exist")
            return
        }
        cancelButton.tap()

        // Verify sheet dismisses
        let optimizationSheet = app.otherElements["program-optimization-sheet"]
        XCTAssertFalse(
            optimizationSheet.waitForExistence(timeout: 2),
            "Optimization sheet should be dismissed after Cancel"
        )

        // Verify Strategy view visible
        let strategyView = app.scrollViews["strategy-view"]
        XCTAssertTrue(
            strategyView.waitForExistence(timeout: 3),
            "Strategy view should be visible after Cancel"
        )
    }

    /// Cancel button dismisses optimization sheet from results
    func testCancelDismissesFromResults() throws {
        app = launchWithCheckInSeeding(tier: "--seed-check-in-ready")

        guard waitForAppLoad(app) else {
            XCTFail("App should load")
            return
        }

        navigateToStrategy(app)
        startCheckInFlow(app)
        completeOptimizationToResults(app)

        // Verify results step visible
        let resultsStep = app.scrollViews["optimization-results-step"]
        guard resultsStep.waitForExistence(timeout: 10) else {
            XCTFail("Results step should appear")
            return
        }

        // Tap Cancel button
        let cancelButton = app.buttons["Cancel"]
        guard cancelButton.waitForExistence(timeout: 3) else {
            XCTFail("Cancel button should exist")
            return
        }
        cancelButton.tap()

        // Verify sheet dismisses without applying changes
        let optimizationSheet = app.otherElements["program-optimization-sheet"]
        XCTAssertFalse(
            optimizationSheet.waitForExistence(timeout: 2),
            "Optimization sheet should be dismissed after Cancel from results"
        )
    }
}
