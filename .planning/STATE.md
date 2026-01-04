# Project State

## Project Summary

**Building:** Calorie expenditure enhancements for MacroKinetic with real-time burned calories from HealthKit, rollover unused calories, and predictive activity adjustments based on historical trends.

**Core requirements:**
- Add burned calories from HealthKit back to daily targets in real-time
- Rollover up to 200 unused calories to next day
- Predictive activity adjustment based on 7-day historical trends with goal-mode multipliers
- Integration with existing CalorieAdjustmentService and weekly check-in flow

**Constraints:**
- CloudKit sync required for cross-device access
- Offline-first functionality
- Follow existing MVVM architecture and @Observable patterns
- iOS 17+ APIs only
- HealthKit authorization for activeEnergyBurned

## Current Position

Phase: 21 of 21 (Integration & Polish)
Plan: 1 of 1 in current phase
Status: Milestone complete
Last activity: 2026-01-04 - Completed 21-01-PLAN.md

Progress: ██████████ 100%

## GitHub Tracking

Issue: #326
PR: #325
Branch: feat/v0.4.0-calorie-expenditure-enhancements

## Performance Metrics

**Velocity:**
- Total plans completed: 4
- Average duration: 14 min
- Total execution time: 56 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 18 | 1 | 18 min | 18 min |
| 19 | 1 | 25 min | 25 min |
| 20 | 1 | 8 min | 8 min |
| 21 | 1 | 5 min | 5 min |

**Recent Trend:**
- Phase 21 complete - milestone 100% done

*Updated after each plan completion*

## Accumulated Context

### Decisions Made

| Phase | Decision | Rationale |
|-------|----------|-----------|

### Deferred Issues

None yet.

### Roadmap Evolution

- Milestone v0.4.0 created: Calorie Expenditure Enhancements, 4 phases (Phase 18-21)
- Note: Phase 1-2 equivalent work (HealthKit integration, CalorieAdjustmentService, CalorieExpenditureView) was completed under APM workflow and committed. Phase 18 completes the E2E tests.

### Blockers/Concerns Carried Forward

None yet.

## Project Alignment

Last checked: 2026-01-03
Status: ✓ Aligned
Assessment: New milestone - baseline alignment.
Drift notes: None

## Session Continuity

Last session: 2026-01-04T14:20:12Z
Stopped at: Completed 21-01-PLAN.md (Milestone v0.4.0 complete)
Resume file: None

### Existing Work (from APM workflow)

The following was completed under APM and is committed:
- HealthKit activeEnergyBurned authorization
- Active energy query methods (getTodayActiveEnergy, getActiveEnergyForDate, getActiveEnergyHistory)
- Real-time HKObserverQuery observation with background delivery
- User preference properties (addBurnedCaloriesEnabled, rolloverCaloriesEnabled, predictiveActivityEnabled, predictedActivityBonus)
- CalorieAdjustmentService with burned calorie calculation
- CalorieExpenditureView wired to User preferences
- NutritionSummaryViewModel with real-time energy observation

**Missing:** CalorieExpenditureUITests.swift (E2E tests) - Phase 18 will complete this.
