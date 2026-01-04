════════════════════════════════════════
  CHECKPOINT: Verification Required
  ════════════════════════════════════════

  Phase 21-01: UI Polish

  I built:
  - CalorieAdjustmentBreakdownView component showing burned/rollover/predictive breakdown
  - Integrated into FoodLogView (displays only for today when adjustments exist)
  - Goal multiplier text in CalorieExpenditureView settings footer

  How to verify:

  1. Food Log Breakdown Card:
    - Open app → Food Log tab
    - Enable calorie adjustments in More > Calorie Expenditure (e.g., Rollover, Burned, or Predictive)
    - Return to Food Log (today's date)
    - Verify breakdown card appears above daily summary with correct values
  2. Goal Multiplier Text:
    - Navigate to More > Calorie Expenditure
    - Look at Predictive Activity toggle footer
    - Verify it shows: "Currently: X% of activity (goal type)"

  Expected:
  - Breakdown card visible when adjustments > 0, hidden otherwise
  - Correct colors: orange (burned), blue (rollover), purple (predictive), green (+values)
  - Goal multiplier text matches active nutrition goal

  Type "approved" to continue, or describe any issues.

  ════════════════════════════════════════