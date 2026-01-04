# Phase 18 Plan 01: Add Burned Calories E2E Tests Summary

**13 E2E tests for CalorieExpenditureView: 5 feature behavior validation tests + 8 toggle/navigation tests**

## Performance

- **Duration:** ~35 min (initial 18 min + 7 min improvements + 10 min FoodLogView bug fix)
- **Started:** 2026-01-03T18:47:03Z
- **Revised:** 2026-01-03T20:52:00Z
- **Tasks:** 5
- **Files modified:** 3

## Accomplishments

### Feature Validation Tests
- `testBurnedCaloriesIncreasesAvailableCalories` - Validates that enabling burned calories with 250 kcal mock energy increases available calories from 2000 to 2250, and flame icon appears
- `testDisablingBurnedCaloriesResetsTarget` - Validates that disabling the feature removes flame icon and resets target to base 2000
- `testBurnedCaloriesRequiresHealthSync` - Validates toggles are disabled when Health Sync is off
- `testNoFlameIconWhenZeroBurned` - Validates flame icon doesn't appear when burned = 0
- `testFoodLogShowsAdjustedCalories` - **NEW** - Validates Food Log shows adjusted target (not just Dashboard)

### Toggle/Navigation Tests
- `testNavigateToCalorieExpenditureView` - Navigation from More tab
- `testAddBurnedCaloriesToggleDefaultState` - Default toggle state
- `testToggleAddBurnedCaloriesOn/Off` - Toggle interactions
- `testTogglesDisabledWhenHealthSyncDisabled` - Disabled state verification
- `testPredictiveActivityToggle` - Predictive toggle interaction
- `testRolloverCaloriesToggle` - Rollover toggle interaction
- `testBackNavigationPreservesState` - State persistence

All 13 tests pass on iOS 26.2 simulator (243.9 seconds total)

## Files Created/Modified
- `JabTrackerUITests/CalorieExpenditureUITests.swift` - E2E tests with feature validation
- `JabTracker/Views/FoodLog/FoodLogView.swift` - **BUG FIX** - Added burned calorie support
- `.planning/phases/18-complete-add-burned-calories/18-SMOKETEST.md` - Manual verification checklist

## Key Test Infrastructure
- Launch arguments: `--seed-calorie-user` enables healthSyncEnabled=true, dailyCalorieGoal=2000
- Launch arguments: `--mock-active-energy=250` injects mock burned calories
- Accessibility identifiers: `burned-calories-indicator` (flame), `macro-remaining-calories` (target display)
- Dashboard tab: `nutrition-rings-card` shows adjusted calorie target

## Decisions Made
- Feature validation tests use `--seed-calorie-user` + `--mock-active-energy=X` for deterministic testing
- Navigate to Dashboard tab (not Food Log) to access NutritionSummaryCard
- Flame icon presence indicates burned calories are being added
- Verify adjusted calorie math: 2000 base + 250 burned = 2250 remaining

## Deviations from Original Plan

### Revision 1: Added Feature Validation Tests
- **Issue:** Original tests only validated toggle UI interactions, not actual feature behavior
- **Fix:** Added 4 new tests that seed mock data and verify calorie target adjustments
- **Verification:** All 12 tests pass

### Revision 2: FoodLogView Bug Fix + E2E Test
- **Issue:** Dashboard showed adjusted calories (2,001 kcal) but Food Log showed base target (2,000 Cal)
- **Root cause:** `FoodLogView.swift` used `user.macroTargetsForDate()` which returns base targets only
- **Fix:** Added `CalorieAdjustmentService` integration, real-time energy observation, and flame icon
- **New test:** `testFoodLogShowsAdjustedCalories` validates Food Log matches Dashboard
- **Verification:** All 13 tests pass

### Original Auto-fixed Issues
1. Element type mismatch: NavigationLink exposed as `app.buttons[]` not `app.cells[]`
2. View identifier not exposed: Used `app.navigationBars["Calorie Expenditure"]` instead

## Issues Encountered
- Initial tests validated only UI toggles, not feature behavior (user feedback)
- Food Log tab doesn't contain NutritionSummaryCard - Dashboard tab does
- **BUG FOUND:** Food Log was not showing adjusted calorie target - only Dashboard was correct
- E2E test element queries required debug-first protocol to identify correct element types (StaticText vs Other)

## Next Phase Readiness
- Phase 18 complete with proper feature validation
- SMOKETEST.md created for manual verification
- Ready for Phase 19: Rollover Calories

---
*Phase: 18-complete-add-burned-calories*
*Completed: 2026-01-03*
