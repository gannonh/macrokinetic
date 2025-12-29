//
//  ProgramWizardUITests.swift
//  JabTrackerUITests
//
//  E2E tests for the Program wizard flow.
//  Tests program creation, editing, and navigation.
//

import XCTest

final class ProgramWizardUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
    }

    // MARK: - New Program Flow

    func testNewProgramWizardComplete() throws {
        // TODO: Navigate to Strategy view (with existing goal)
        // TODO: Tap "New Program" button
        // TODO: Verify program style step appears
        // TODO: Select "Coached"
        // TODO: Continue through all steps:
        //       - Diet Preference
        //       - Calorie Floor
        //       - Training Level
        //       - Weekly Distribution
        //       - Protein Level
        // TODO: Verify confirmation screen shows all selections
        // TODO: Tap "Save Program"
        // TODO: Verify wizard dismissed
    }

    func testNewProgramAllStepsVisible() throws {
        // TODO: Navigate to Strategy view
        // TODO: Tap "New Program"
        // TODO: Verify all 7 steps can be navigated
        // TODO: Verify back navigation works
    }

    // MARK: - Edit Program Flow

    func testEditProgramFlow() throws {
        // TODO: Create goal with program (or seed test data)
        // TODO: Navigate to Strategy view
        // TODO: Tap "Edit Program"
        // TODO: Verify NO program style step (edit mode skips style)
        // TODO: Verify starts at Diet Preference step
        // TODO: Modify a setting
        // TODO: Complete wizard
        // TODO: Verify program updated
    }

    func testEditProgramSkipsStyleSelection() throws {
        // TODO: Start Edit Program flow
        // TODO: Verify first step is Diet Preference (not Program Style)
        // TODO: Verify step count is 6 (not 7)
    }

    // MARK: - Program Style Selection

    func testProgramStyleOptions() throws {
        // TODO: Start New Program wizard
        // TODO: Verify all program styles visible:
        //       - Coached
        //       - Relaxed
    }

    func testContinueDisabledWithoutProgramStyle() throws {
        // TODO: Start New Program wizard
        // TODO: Verify Continue button disabled
        // TODO: Select a program style
        // TODO: Verify Continue button enabled
    }

    // MARK: - Diet Preference

    func testDietPreferenceOptions() throws {
        // TODO: Navigate to Diet Preference step
        // TODO: Verify all diet options visible:
        //       - Balanced
        //       - Low Carb
        //       - Keto
        //       - Plant Based
    }

    // MARK: - Calorie Floor

    func testCalorieFloorOptions() throws {
        // TODO: Navigate to Calorie Floor step
        // TODO: Verify all options visible:
        //       - Standard
        //       - Aggressive
    }

    // MARK: - Training Level

    func testTrainingLevelOptions() throws {
        // TODO: Navigate to Training step
        // TODO: Verify all training levels visible:
        //       - None
        //       - Relaxed
    }

    // MARK: - Weekly Distribution

    func testWeeklyDistributionOptions() throws {
        // TODO: Navigate to Weekly Distribution step
        // TODO: Verify all distribution modes visible:
        //       - Even (same every day)
        //       - High/Low cycling
    }

    // MARK: - Protein Level

    func testProteinLevelOptions() throws {
        // TODO: Navigate to Protein Level step
        // TODO: Verify all protein levels visible:
        //       - Moderate
        //       - High
        //       - Very High
    }

    // MARK: - Confirmation

    func testConfirmationShowsAllSelections() throws {
        // TODO: Complete all steps with specific selections
        // TODO: Verify confirmation screen displays all:
        //       - Program Style
        //       - Diet Preference
        //       - Calorie Floor
        //       - Training Level
        //       - Distribution Mode
        //       - Protein Level
    }

    // MARK: - Navigation

    func testBackNavigationPreservesSelections() throws {
        // TODO: Start New Program wizard
        // TODO: Select program style → Continue
        // TODO: Select diet preference → Continue
        // TODO: Go back twice
        // TODO: Verify program style still selected
    }

    func testCancelWizardDismisses() throws {
        // TODO: Start New Program wizard
        // TODO: Navigate to middle step
        // TODO: Tap Cancel
        // TODO: Verify wizard is dismissed
        // TODO: Verify no program created/modified
    }

    // MARK: - TDEE Integration Tests (Phase 15.1)

    func testCoachedProgramShowsProfileCompletionStepWhenMissingData() throws {
        // TODO: Set up user with missing profile data (height, sex, or birthday)
        // TODO: Navigate to Strategy → Set Goal → create goal
        // TODO: Select "Coached" program style
        // TODO: Verify: "Complete Your Profile" step appears
        // TODO: Verify: Missing fields shown (height picker, sex picker, birthday picker)
        // TODO: Verify: Info banner explains why profile data is needed
        // TODO: Fill in missing fields
        // TODO: Tap Continue
        // TODO: Verify: Proceeds to next wizard step
    }

    func testCoachedProgramSkipsProfileCompletionWhenDataComplete() throws {
        // TODO: Set up user with complete profile (height, sex, birthday)
        // TODO: Navigate to Strategy → create goal → select "Coached"
        // TODO: Verify: Profile completion step is NOT shown
        // TODO: Verify: Goes directly to Diet Preference step
    }

    func testProgramReadySheetDisplaysTDEECalculation() throws {
        // TODO: Set up profile: Male, 180 lbs, 5'10", age 30, activity level set
        // TODO: Create goal: Weight Loss, 1.0 lbs/week, Target 170 lbs
        // TODO: Select Coached program with Balanced diet
        // TODO: Complete all wizard steps
        // TODO: Verify: Program Ready Sheet appears
        // TODO: Verify: "Your macro program is ready" header
        // TODO: Verify: Step 1 shows "Estimated Expenditure (TDEE)" with value ~2700-2800 kcal
        // TODO: Verify: Step 2 shows "Daily Target" with value ~2200-2300 kcal
        // TODO: Verify: Step 3 shows "Macro Split" with diet name and P/F/C breakdown
    }

    func testProgramReadySheetWeeklyMacroGrid() throws {
        // TODO: Complete Coached program creation
        // TODO: Verify: Program Ready Sheet shows weekly macro grid (M-T-W-T-F-S-S)
        // TODO: Verify: All 7 days show identical values (Even distribution)
        // TODO: Verify: Calorie values displayed in pill-shaped cells
        // TODO: Verify: Protein/Fat/Carbs rows visible with colored cells
        // TODO: Verify: Values are integers (no decimals)
    }

    func testCalorieDeficitCalculationAccuracy() throws {
        // Test Case: 1 lb/week weight loss should show ~500 kcal deficit
        // TODO: Set up profile: Male, 180 lbs, 5'10", age 30
        // TODO: Create goal: Weight Loss, 1.0 lbs/week pace
        // TODO: Complete Coached program
        // TODO: Verify: Daily Target = TDEE - ~500 kcal
        // TODO: Verify: Daily Target NOT suspiciously close to TDEE (regression check)
        //
        // Expected: If TDEE ~2700, Daily Target should be ~2200
        // Bug regression: Previous bug showed ~2630 (divided by 7 twice)
    }

    func testCalorieSurplusCalculationAccuracy() throws {
        // Test Case: 1 lb/week weight gain should show ~500 kcal surplus
        // TODO: Set up profile: Male, 180 lbs, 5'10", age 30
        // TODO: Create goal: Weight Gain, 1.0 lbs/week pace
        // TODO: Complete Coached program
        // TODO: Verify: Daily Target = TDEE + ~500 kcal
        //
        // Expected: If TDEE ~2700, Daily Target should be ~3200
    }

    func testSlowerPaceShowsSmallDeficit() throws {
        // Test Case: 0.5 lbs/week weight loss should show ~250 kcal deficit
        // TODO: Set up profile: Male, 180 lbs, 5'10", age 30
        // TODO: Create goal: Weight Loss, 0.5 lbs/week pace
        // TODO: Complete Coached program
        // TODO: Verify: Daily Target = TDEE - ~250 kcal
    }

    func testDietPreferenceAffectsMacros() throws {
        // TODO: Create Coached program with Balanced diet
        // TODO: Note macro values on Program Ready Sheet
        // TODO: Create another Coached program with High Protein diet
        // TODO: Verify: Protein grams increased
        // TODO: Verify: Carb grams decreased to compensate
        //
        // Each diet preference should produce different macro distributions
    }

    func testStrategyViewPersistsCalculatedTargets() throws {
        // TODO: Complete Coached program creation
        // TODO: Verify Program Ready Sheet values
        // TODO: Tap "Start Program" or dismiss
        // TODO: Navigate to Strategy view
        // TODO: Verify: Strategy card shows same values as Program Ready Sheet
        // TODO: Restart app (terminate and relaunch)
        // TODO: Verify: Values persist after restart
    }

    func testProgramWizardRaceConditionFix() throws {
        // Regression test: Fast tapping should not show blank screen
        // TODO: Navigate to Strategy → Set Goal → create goal
        // TODO: Select Coached style and tap Continue rapidly
        // TODO: Continue through steps quickly (tap immediately when available)
        // TODO: Verify: No blank screens appear
        // TODO: Verify: Program Ready Sheet loads with calculated values (not "Calculating...")
    }
}

// MARK: - Accessibility Identifiers Reference
//
// Strategy Entry Points:
// - "strategy-view" - Strategy screen
// - "new-program-button" - New program button
// - "edit-program-button" - Edit program button
//
// Program Wizard:
// - "program-wizard" - Main wizard view
// - "program-wizard-cancel-button" - Cancel button
// - "program-wizard-back-button" - Back button
// - "program-wizard-continue-button" - Continue button
// - "program-wizard-save-button" - Save button
//
// Step Views:
// - "program-wizard-programStyle-step"
// - "program-wizard-dietPreference-step"
// - "program-wizard-calorieFloor-step"
// - "program-wizard-training-step"
// - "program-wizard-weeklyDistribution-step"
// - "program-wizard-proteinLevel-step"
// - "program-wizard-confirmation-step"
//
// Program Style Options:
// - "program-wizard-style-coached"
// - "program-wizard-style-relaxed"
//
// Diet Options:
// - "program-wizard-diet-balanced"
// - "program-wizard-diet-low_carb"
// - "program-wizard-diet-keto"
// - "program-wizard-diet-plant_based"
//
// Calorie Floor Options:
// - "program-wizard-floor-standard"
// - "program-wizard-floor-aggressive"
//
// Training Options:
// - "program-wizard-training-none"
// - "program-wizard-training-relaxed"
//
// Distribution Options:
// - "program-wizard-distribution-even"
// - "program-wizard-distribution-high_low"
//
// Protein Options:
// - "program-wizard-protein-moderate"
// - "program-wizard-protein-high"
// - "program-wizard-protein-very_high"
//
// Profile Completion Step (Phase 15.1):
// - "program-wizard-profileCompletion-step"
// - "program-wizard-height-picker"
// - "program-wizard-sex-picker"
// - "program-wizard-birthday-picker"
// - "program-wizard-profile-info-banner"
//
// Program Ready Sheet (Phase 15.1):
// - "program-ready-sheet"
// - "program-ready-header"
// - "program-ready-tdee-value"
// - "program-ready-daily-target-value"
// - "program-ready-macro-split"
// - "program-ready-weekly-grid"
// - "program-ready-start-button"
