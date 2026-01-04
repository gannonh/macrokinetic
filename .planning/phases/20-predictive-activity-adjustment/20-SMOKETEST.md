# Phase 20: Predictive Activity Adjustment - Smoke Test

## Prerequisites
- User with Health Sync enabled
- User with active nutrition goal (weightLoss, maintenance, or muscleGain)
- At least a few days of activity history in HealthKit (optional but recommended)

## Test Cases

### 1. Toggle Accessibility
- [ ] Navigate to More > Calorie Expenditure
- [ ] Predictive Activity toggle is visible
- [ ] Toggle is enabled when Health Sync is on
- [ ] Toggle is disabled (greyed out) when Health Sync is off

### 2. Toggle Behavior
- [ ] Toggle can be turned on
- [ ] Toggle can be turned off
- [ ] State persists after navigating away and back

### 3. Mutual Exclusivity with Burned Calories
- [ ] Enable "Add Burned Calories" toggle
- [ ] Enable "Predictive Activity" toggle
- [ ] Verify only one affects calorie target (burned calories takes precedence)
- [ ] Verify predictive adjustment is 0 when burned calories is enabled

### 4. Goal Multiplier Verification
- [ ] With weightLoss goal: Footer shows "80% of activity"
- [ ] With maintenance goal: Footer shows "100% of activity"
- [ ] With muscleGain goal: Footer shows "120% of activity"

### 5. Calorie Target Adjustment
- [ ] Enable predictive activity (with burned calories OFF)
- [ ] Navigate to Dashboard
- [ ] Verify calorie target is higher than base target
- [ ] Adjustment should reflect 7-day average * goal multiplier

## Expected Behavior Summary
- Predictive activity adds a bonus based on historical activity trends
- Bonus = (7-day average active energy) * (goal multiplier)
- Goal multipliers: weightLoss=0.8, maintenance=1.0, muscleGain=1.2
- Feature is mutually exclusive with "Add Burned Calories" to prevent double-counting
- Toggle requires Health Sync to be enabled

## Known Limitations
- New users with <7 days of activity history will see smaller or zero prediction
- Predictive calculation uses data from yesterday backward (not today)
