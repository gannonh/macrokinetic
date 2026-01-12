# Phase 34 Plan 1: Hero Widgets Live Data Summary

Hero carousel widgets (Daily, Weekly, Energy Balance) wired to live MealLogService/TDEEService data with ViewModels following TDD approach.

## Performance

- Duration: 21 min
- Started: 2026-01-10T22:47:36Z
- Completed: 2026-01-10T23:08:38Z
- Tasks completed: 3
- Files created: 7
- Files modified: 3

## What Was Built

### Task 1: DailyNutritionHeroWidget Live Data
Created `DailyNutritionHeroViewModel` that:
- Injects MealLogService and ModelContext
- Fetches today's DailyNutritionTotals from FoodEntry records
- Gets User's activeNutritionGoal or falls back to direct User goals
- Exposes consumed/target values for calories, protein, carbs, fat
- Widget updated to use ViewModel with `useMockData` flag for previews

### Task 2: WeeklyNutritionHeroWidget Live Data
Created `WeeklyNutritionHeroViewModel` that:
- Fetches 7 days of DailyNutritionTotals via MealLogService
- Calculates fill percentages: today = partial, future = 0%, past = actual
- Gets targets from User's activeNutritionGoal
- Widget updated to use ViewModel with preview support

### Task 3: EnergyBalanceHeroWidget Live Data
Created `EnergyBalanceHeroViewModel` that:
- Fetches 30 days of daily calories via MealLogService
- Gets TDEE from activeNutritionGoal.initialEstimatedTDEE for expenditure mode
- Gets calorie targets from activeNutritionGoal.dailyCalorieTarget for targets mode
- Calculates balance: consumed - expenditure OR consumed - target
- Widget updated to use ViewModel with preview support

## Files Created

| File | Purpose |
|------|---------|
| `JabTracker/ViewModels/DailyNutritionHeroViewModel.swift` | ViewModel for daily nutrition widget |
| `JabTracker/ViewModels/WeeklyNutritionHeroViewModel.swift` | ViewModel for weekly nutrition widget |
| `JabTracker/ViewModels/EnergyBalanceHeroViewModel.swift` | ViewModel for energy balance widget |
| `JabTrackerTests/ViewModels/DailyNutritionHeroViewModelTests.swift` | 7 unit tests |
| `JabTrackerTests/ViewModels/WeeklyNutritionHeroViewModelTests.swift` | 8 unit tests |
| `JabTrackerTests/ViewModels/EnergyBalanceHeroViewModelTests.swift` | 9 unit tests |
| `JabTracker/ViewModels/.swiftlint.yml` | SwiftLint config for preview force_try |

## Files Modified

| File | Changes |
|------|---------|
| `DailyNutritionHeroWidget.swift` | Added ViewModel integration, useMockData flag |
| `WeeklyNutritionHeroWidget.swift` | Added ViewModel integration, useMockData flag |
| `EnergyBalanceHeroWidget.swift` | Added ViewModel integration, useMockData flag |

## Test Results

- **DailyNutritionHeroViewModelTests**: 7 tests passed
- **WeeklyNutritionHeroViewModelTests**: 8 tests passed
- **EnergyBalanceHeroViewModelTests**: 9 tests passed
- **Total**: 24 new unit tests, all passing

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added SwiftLint config for ViewModels**
- Found during: ViewModel creation
- Issue: Preview extensions use force_try! for SwiftData container setup
- Fix: Created `.swiftlint.yml` in ViewModels directory to allow force_try in preview code
- Rationale: Consistent with existing preview patterns in codebase

## Decisions Made

None - implementation followed plan closely.

## Issues Encountered

None.

## Next Phase Readiness

Ready for 34-02-PLAN.md (Standard Widgets Live Data).
