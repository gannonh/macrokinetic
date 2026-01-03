# Smoke Test: Rollover Calories

## Feature
Rollover up to 200 unused calories from yesterday to today's calorie target.

## How to Test

1. **Access Settings Toggle**
   - Launch app on simulator
   - Navigate to: More tab → Calorie Expenditure
   - Locate "Rollover Calories" toggle

2. **Enable Feature**
   - Toggle "Rollover Calories" ON
   - Navigate back to Dashboard or Food Log

3. **Verify Rollover Works**
   - Ensure yesterday has unused calories (under target)
   - Navigate to Food Log for today
   - Verify calorie target shows increased by rollover amount (max 200)

## Expected Behavior
- Toggle exists and is interactive
- App does not crash when toggle enabled
- Dashboard loads correctly with calorie ring
- Food Log displays adjusted target including rollover
- Rollover is capped at 200 kcal maximum

## Verification
- [x] Settings toggle exists
- [x] Toggle can be enabled/disabled
- [x] No crashes after enabling
- [x] Dashboard loads correctly
- [x] Food Log displays adjusted target with rollover

## Issues Found
**Bug Fixed:** FoodLogView wasn't refreshing when rolloverCaloriesEnabled changed.
- Added `onChange(of: users.first?.rolloverCaloriesEnabled)` handler to trigger `updateCalorieTarget()`
- After fix, rollover correctly adds to today's target

## Status
- [x] Verified
