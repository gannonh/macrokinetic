//
//  ProgramWizardUITests.swift
//  JabTrackerUITests
//
//  E2E tests for the Program wizard flow.
//  Tests program creation, editing, and navigation across all program styles.
//

import XCTest

final class ProgramWizardUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
    }

    // MARK: - New Coached Program - Even Distribution

    func testNewCoachedProgramEvenComplete() throws {
        // TODO: Seed goal or create goal first
        // TODO: Navigate to Strategy view
        // TODO: Tap "New Program" button
        // TODO: Select "Coached" program style
        // TODO: Continue → Diet Preference step
        // TODO: Select "Balanced"
        // TODO: Continue → Calorie Floor step
        // TODO: Select "Standard"
        // TODO: Continue → Training Level step
        // TODO: Select training option
        // TODO: Continue → Weekly Distribution step
        // TODO: Select "Even" (same every day)
        // TODO: Continue → Protein Level step
        // TODO: Select protein level
        // TODO: Continue → Confirmation step
        // TODO: Verify all selections displayed
        // TODO: Tap "Save Program"
        // TODO: Verify ProgramReadySheet appears with calculated macros
    }

    func testNewCoachedEvenShowsSameMacrosAllDays() throws {
        // TODO: Create Coached program with Even distribution
        // TODO: Verify ProgramReadySheet weekly grid shows identical values for all 7 days
        // TODO: Verify Strategy view weekly grid shows same values
    }

    // MARK: - New Coached Program - Shifted Distribution

    func testNewCoachedProgramShiftedComplete() throws {
        // TODO: Seed goal or create goal first
        // TODO: Navigate to Strategy view
        // TODO: Tap "New Program"
        // TODO: Select "Coached"
        // TODO: Continue through steps to Weekly Distribution
        // TODO: Select "Shifted" (custom per-day calories)
        // TODO: Verify per-day calorie editor appears
        // TODO: Adjust multipliers (e.g., higher on weekends)
        // TODO: Continue through remaining steps
        // TODO: Tap "Save Program"
        // TODO: Verify ProgramReadySheet shows varied daily calories
    }

    func testCoachedShiftedShowsVariedMacros() throws {
        // TODO: Create Coached Shifted program with weekend higher calories
        // TODO: Verify ProgramReadySheet weekly grid shows different values per day
        // TODO: Verify Strategy view reflects shifted distribution
    }

    // MARK: - Edit Coached Program

    func testEditCoachedProgramFlow() throws {
        // CRITICAL: Edit Coached skips program style step
        // Flow: Diet Pref → Calorie Floor → Training → Distribution → Protein → Confirm → Save
        // TODO: Seed test data with existing Coached program
        // TODO: Navigate to Strategy view
        // TODO: Tap "Edit Program"
        // TODO: Verify NO program style step (starts at Diet Preference)
        // TODO: Verify current selections are pre-populated
        // TODO: Modify diet preference
        // TODO: Continue through: Calorie Floor → Training → Distribution → Protein → Confirm
        // TODO: Tap "Save"
        // TODO: Verify Strategy view reflects updated program
    }

    func testEditCoachedLoadsSavedSelections() throws {
        // TODO: Seed Coached program with specific selections:
        //       - Diet: Balanced
        //       - Floor: Standard
        //       - Training: Lifting
        //       - Distribution: Even
        //       - Protein: High
        // TODO: Navigate to Strategy → Edit Program
        // TODO: Verify each step shows the saved selection pre-selected
    }

    func testEditCoachedShiftedToEvenClearsDistribution() throws {
        // CRITICAL: Switching Shifted → Even should redistribute calories evenly
        // TODO: Seed Coached Shifted program with custom day multipliers
        // TODO: Navigate to Strategy → Edit Program
        // TODO: Continue to Weekly Distribution step
        // TODO: Verify Shifted is selected with custom values
        // TODO: Select "Even"
        // TODO: Continue through remaining steps → Save
        // TODO: Verify Strategy view shows identical values for all 7 days
        // TODO: Verify old shifted data is cleared
    }

    // MARK: - New Collaborative Program

    func testNewCollaborativeProgramComplete() throws {
        // TODO: Seed goal or create goal first
        // TODO: Navigate to Strategy view
        // TODO: Tap "New Program"
        // TODO: Select "Collaborative" program style
        // TODO: Verify TDEE calculated and displayed
        // TODO: Verify per-day calorie/macro editor appears
        // TODO: Customize Monday's values
        // TODO: Customize Sunday's values
        // TODO: Continue to confirmation
        // TODO: Verify per-day values displayed correctly
        // TODO: Tap "Save Program"
    }

    func testCollaborativeLockDays() throws {
        // TODO: Create Collaborative program
        // TODO: Customize Monday with specific values
        // TODO: Tap lock icon on Monday (isLocked = true)
        // TODO: Customize Saturday with different values
        // TODO: Tap lock icon on Saturday (isLocked = true)
        // TODO: Leave other days unlocked (default values)
        // TODO: Save program
        // TODO: Verify Strategy view shows locked days with custom values
    }

    func testEditCollaborativeLoadsValuesAndLocks() throws {
        // CRITICAL: Edit mode must load saved values WITH lock states
        // TODO: Seed Collaborative program with:
        //       - Monday: 2200 cal, locked
        //       - Saturday: 2500 cal, locked
        //       - Other days: default, unlocked
        // TODO: Navigate to Strategy → Edit Program
        // TODO: Verify Monday shows 2200 cal AND lock icon filled
        // TODO: Verify Saturday shows 2500 cal AND lock icon filled
        // TODO: Verify other days show default values AND unlocked
    }

    func testEditCollaborativeModifyAndSavePersists() throws {
        // TODO: Seed Collaborative program with Monday locked at 2200
        // TODO: Navigate to Strategy → Edit Program
        // TODO: Change Monday to 2300 cal
        // TODO: Lock Tuesday at 2100 cal
        // TODO: Unlock Saturday (if previously locked)
        // TODO: Save program
        // TODO: Verify Strategy view reflects ALL changes
        // TODO: Navigate to Edit Program again
        // TODO: Verify Monday: 2300, locked
        // TODO: Verify Tuesday: 2100, locked
        // TODO: Verify Saturday: unlocked
    }

    // MARK: - New Manual Program

    func testNewManualProgramSameAllWeek() throws {
        // TODO: Seed goal or create goal first
        // TODO: Navigate to Strategy view
        // TODO: Tap "New Program"
        // TODO: Select "Manual" program style
        // TODO: Verify manual macro entry appears
        // TODO: Enter calories: 2000
        // TODO: Enter protein: 150g
        // TODO: Enter carbs: 200g
        // TODO: Enter fat: 67g
        // TODO: Keep "Same all week" mode
        // TODO: Save program
        // TODO: Verify Strategy view shows 2000/150/200/67 for all days
    }

    func testNewManualProgramPerDay() throws {
        // TODO: Select Manual program style
        // TODO: Enable "Per-day" mode
        // TODO: Enter different values for each day
        // TODO: Save program
        // TODO: Verify Strategy view shows varied daily targets
    }

    func testEditManualLoadsValues() throws {
        // TODO: Seed Manual program with specific values
        // TODO: Navigate to Strategy → Edit Program
        // TODO: Verify all saved macro values are pre-populated
        // TODO: Modify calorie value
        // TODO: Save
        // TODO: Verify Strategy view reflects change
    }

    // MARK: - Program Style Selection

    func testProgramStyleOptions() throws {
        // TODO: Start New Program wizard
        // TODO: Verify all program styles visible:
        //       - Coached
        //       - Collaborative
        //       - Manual
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
        //       - Low Fat
        //       - Low Carb
        //       - Keto
    }

    // MARK: - Calorie Floor

    func testCalorieFloorOptions() throws {
        // TODO: Navigate to Calorie Floor step
        // TODO: Verify all options visible:
        //       - Standard (1538 cal minimum)
        //       - Low (1025 cal minimum - shows warning)
    }

    // MARK: - Training Level

    func testTrainingLevelOptions() throws {
        // TODO: Navigate to Training step
        // TODO: Verify all training levels visible:
        //       - None or Relaxed Activity
        //       - Lifting
        //       - Cardio
        //       - Cardio & Lifting
    }

    // MARK: - Weekly Distribution

    func testWeeklyDistributionOptions() throws {
        // TODO: Navigate to Weekly Distribution step
        // TODO: Verify all distribution modes visible:
        //       - Even (same every day)
        //       - Shifted (custom per-day)
    }

    // MARK: - Protein Level

    func testProteinLevelOptions() throws {
        // TODO: Navigate to Protein Level step
        // TODO: Verify all protein levels visible:
        //       - Low
        //       - Moderate
        //       - High
        //       - Extra High
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

    // MARK: - Data Validation

    func testProgramDataMatchesBetweenStrategyAndEdit() throws {
        // CRITICAL: Single source of truth - data must match everywhere
        // TODO: Create program with specific values
        // TODO: Note all values shown in ProgramReadySheet
        // TODO: Navigate to Strategy view
        // TODO: Verify Strategy weekly grid matches ProgramReadySheet
        // TODO: Tap Edit Program
        // TODO: Verify Edit wizard shows same values
        // TODO: Cancel edit
        // TODO: Verify Strategy still shows same values
    }

    func testMacroMathCorrect() throws {
        // TODO: Create Coached Balanced program
        // TODO: Note daily calories on ProgramReadySheet
        // TODO: Verify: protein_cal + carb_cal + fat_cal ≈ total_cal
        //       - Protein: g × 4
        //       - Carbs: g × 4
        //       - Fat: g × 9
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
