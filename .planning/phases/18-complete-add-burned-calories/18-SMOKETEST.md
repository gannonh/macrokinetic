# Smoke Test: Add Burned Calories Feature

## Feature
Real-time burned calorie integration from HealthKit that adjusts daily calorie targets. When enabled, active energy burned is added back to the user's available calories.

## Prerequisites
- HealthKit authorization granted on device
- Health Sync enabled in app settings (More → Metrics → Toggle on Health Sync)
- Some logged activity in Apple Health (workout, walking, etc.)

## How to Test

### Test 1: Enable Feature and Verify Calorie Adjustment
1. Launch the app with Health Sync enabled
2. Navigate to More → Calorie Expenditure
3. Toggle "Add Burned Calories" ON
4. Return to Food Log tab
5. Look at the Calories ring in the Nutrition Summary Card
6. **Verify**:
   - Flame icon (🔥) appears next to the calorie goal
   - Calorie goal shows increased value (base goal + burned)
   - If base goal is 2000 and you burned 300, goal shows ~2300

### Test 2: Verify Real-Time Updates
1. With "Add Burned Calories" enabled
2. Go for a walk or do some activity
3. Return to the Food Log tab
4. **Verify**: Calorie goal updates as activity is recorded in HealthKit

### Test 3: Disable Feature
1. Navigate to More → Calorie Expenditure
2. Toggle "Add Burned Calories" OFF
3. Return to Food Log tab
4. **Verify**:
   - Flame icon disappears
   - Calorie goal returns to base value (2000)

### Test 4: Feature Disabled Without Health Sync
1. Navigate to More → Metrics
2. Toggle "Health Sync" OFF
3. Navigate to More → Calorie Expenditure
4. **Verify**:
   - "Add Burned Calories" toggle is disabled/grayed out
   - "Predictive Activity" toggle is disabled/grayed out
   - "Rollover Calories" toggle is still enabled (no HealthKit requirement)

### Test 5: Rollover Calories (Independent Feature)
1. Toggle "Rollover Calories" ON
2. (This feature doesn't require Health Sync)
3. **Verify**: Toggle works regardless of Health Sync state

## Expected Behavior
- Feature only works when both Health Sync AND Add Burned Calories are enabled
- Flame icon is the visual indicator that burned calories are being added
- Calorie target = Base Target + Burned Calories
- Real-time updates as HealthKit data changes
- State persists across app restarts

## Verification Checklist
- [ ] Add Burned Calories toggle works when Health Sync is enabled
- [ ] Flame icon appears when burned > 0
- [ ] Calorie goal increases by burned amount
- [ ] Disabling feature removes flame and resets goal
- [ ] Toggles properly disabled when Health Sync is off
- [ ] State persists across navigation

## Issues Found
(To be filled by tester)

## Status
- [ ] Verified
