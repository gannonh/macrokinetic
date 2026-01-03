# Phase 18 Plan 01: Add Burned Calories E2E Tests Summary

**12 E2E tests for CalorieExpenditureView: 4 feature behavior validation tests + 8 toggle/navigation tests**

## Performance

- **Duration:** ~25 min (initial 18 min + 7 min improvements)
- **Started:** 2026-01-03T18:47:03Z
- **Revised:** 2026-01-03T19:34:00Z
- **Tasks:** 4
- **Files modified:** 2

## Accomplishments

### Feature Validation Tests (NEW)
- `testBurnedCaloriesIncreasesAvailableCalories` - Validates that enabling burned calories with 250 kcal mock energy increases available calories from 2000 to 2250, and flame icon appears
- `testDisablingBurnedCaloriesResetsTarget` - Validates that disabling the feature removes flame icon and resets target to base 2000
- `testBurnedCaloriesRequiresHealthSync` - Validates toggles are disabled when Health Sync is off
- `testNoFlameIconWhenZeroBurned` - Validates flame icon doesn't appear when burned = 0

### Toggle/Navigation Tests (original)
- `testNavigateToCalorieExpenditureView` - Navigation from More tab
- `testAddBurnedCaloriesToggleDefaultState` - Default toggle state
- `testToggleAddBurnedCaloriesOn/Off` - Toggle interactions
- `testTogglesDisabledWhenHealthSyncDisabled` - Disabled state verification
- `testPredictiveActivityToggle` - Predictive toggle interaction
- `testRolloverCaloriesToggle` - Rollover toggle interaction
- `testBackNavigationPreservesState` - State persistence

All 12 tests pass on iOS 26.2 simulator (221.5 seconds total)

## Files Created/Modified
- `JabTrackerUITests/CalorieExpenditureUITests.swift` - E2E tests with feature validation
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

### Original Auto-fixed Issues
1. Element type mismatch: NavigationLink exposed as `app.buttons[]` not `app.cells[]`
2. View identifier not exposed: Used `app.navigationBars["Calorie Expenditure"]` instead

## Issues Encountered
- Initial tests validated only UI toggles, not feature behavior (user feedback)
- Food Log tab doesn't contain NutritionSummaryCard - Dashboard tab does

## Next Phase Readiness
- Phase 18 complete with proper feature validation
- SMOKETEST.md created for manual verification
- Ready for Phase 19: Rollover Calories

---
*Phase: 18-complete-add-burned-calories*
*Completed: 2026-01-03*
