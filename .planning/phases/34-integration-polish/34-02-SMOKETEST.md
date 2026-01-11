# Smoke Test: Standard Widgets Live Data

## Feature
Standard dashboard widgets (WeightTrend, Expenditure, EnergyBalance, GoalProgress) wired to live data via MVVM ViewModels.

## How to Test
1. Launch app and navigate to Dashboard tab
2. Scroll down to see the standard widgets grid (below hero carousel)
3. Verify each widget displays actual data or appropriate empty states

## Expected Behavior
- **Weight Trend Widget**: Shows 7-day weight history if entries exist, or "No data" state
- **Expenditure Widget**: Shows current TDEE estimate from NutritionGoal, or placeholder
- **Energy Balance Widget**: Shows 7-day net deficit/surplus, or empty state if no TDEE
- **Goal Progress Widget**: Shows today's calorie progress percentage toward daily goal

## Verification
- [ ] Weight Trend widget shows real weight data (or empty state)
- [ ] Expenditure widget shows TDEE value (or empty state)
- [ ] Energy Balance widget shows deficit/surplus indicator
- [ ] Goal Progress widget shows progress ring with percentage
- [ ] Widgets update when underlying data changes
- [ ] No crashes on empty data states
- [ ] No visual glitches

## Issues Found
(To be filled by tester)

## Status
- [x] Verified (2026-01-11)
