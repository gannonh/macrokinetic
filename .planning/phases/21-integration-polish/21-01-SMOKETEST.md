# Smoke Test: Phase 21 UI Polish

## Feature
Calorie adjustment breakdown display in Food Log and goal multiplier text in settings.

## How to Test

### 1. Calorie Adjustment Breakdown (Food Log)
1. Open app on device/simulator
2. Navigate to **Food Log** tab
3. Enable one or more calorie adjustment features in **More > Calorie Expenditure**:
   - "Add Burned Calories" (requires Health Sync enabled)
   - "Rollover Calories"
   - "Predictive Activity" (requires Health Sync enabled)
4. Return to **Food Log** tab (viewing Today's date)
5. If any adjustments are active, verify the breakdown card appears above the daily summary

### 2. Goal Multiplier Text (Settings)
1. Navigate to **More > Calorie Expenditure**
2. Enable **Health Sync** if not already enabled
3. Look at the **Predictive Activity** toggle section
4. Verify the footer text shows current goal multiplier:
   - Weight Loss: "Currently: 80% of activity (weight loss)"
   - Maintenance: "Currently: 100% of activity (maintenance)"
   - Muscle Gain: "Currently: 120% of activity (muscle gain)"

## Expected Behavior

### Breakdown Card
- Shows only when at least one adjustment is > 0
- Displays base target at top
- Shows each enabled adjustment type with icon and +kcal value
- Shows total "Today's Target" at bottom
- Has proper divider between adjustments and total
- Uses correct colors (orange for burned, blue for rollover, purple for predictive, green for +values)

### Goal Multiplier Text
- Appears in footer when user has an active nutrition goal
- Shows correct percentage based on goal type
- Updates if goal changes

## Verification
- [ ] Breakdown card visible in Food Log when adjustments exist
- [ ] Breakdown card hidden when no adjustments
- [ ] Goal multiplier text shows in Predictive Activity footer
- [ ] Correct multiplier percentage for goal type
- [ ] No visual glitches
- [ ] No crashes

## Issues Found
(To be filled by tester)

## Status
- [ ] Verified
