# Project State

## Project Summary

**Building:** MacroKinetic — iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management.

**Last shipped:** v0.9.0 Improvements & Fixes (2026-01-17)

**Core value:** Reduce repetitive food logging through copy/paste and scheduled meals.

## Current Position

Phase: 46 of 47 (Schedule UX)
Plan: 01 of 03
Status: In progress
Last activity: 2026-01-18 - Completed 46-01-PLAN.md

Progress: ██████░░░░ 54%

## GitHub Tracking

Issue: N/A
PR: N/A
Branch: main
Status: Plan 01 complete, 02-03 remaining

## Performance Metrics

**Velocity:**
- Total plans completed: 6 (v0.10.0)
- Average duration: 8min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 44 | 3 | 23min | 8min |
| 45 | 2 | 20min | 10min |
| 46 | 1 | 4min | 4min |

**Historical (v0.9.0):**
- 8 plans completed (+4 FIX plans)
- Timeline: 3 days
- Files modified: 140

## Accumulated Context

### Decisions

| Decision | Phase | Rationale |
|----------|-------|-----------|
| Value types for clipboard | 44-01 | Avoid SwiftData context invalidation when navigating |
| Session-only clipboard | 44-01 | Per COPY-05 requirement, cleared on app termination |
| Single clipboard (no history) | 44-01 | Simplicity, new copy replaces existing |
| Segmented control in header | 44-02 | User enhancement for quick copy/paste access in toolbar |
| Skip confirmation on empty day | 44-02 | Streamline common workflow when no entries to replace |
| Insert before delete on paste | 44-02 | Prevent data loss if operation fails midway |
| confirmationDialog anchor to trigger | 44-03 | Attach dialog to CopyPasteSegmentedControl for proper header positioning |
| ScheduleDay rawValues 1-7 | 45-01 | Match Calendar.component(.weekday) for direct conversion |
| JSON-encoded scheduleConfigData | 45-01 | CloudKit-compatible, matches NutritionProgram pattern |
| UUID foodId reference | 45-01 | Avoids @Relationship cascade issues with CloudKit |
| getSchedules(for:) day filtering | 45-02 | Uses scheduledMeals(for:) to check day of week, not just appliesTo |
| Empty barcode on conversion | 45-02 | Avoid duplicate conflicts when auto-converting non-custom foods |
| DayMealKey struct for Set ops | 46-01 | O(1) lookup instead of array searching for grid selection |
| Toggle-controlled date pickers | 46-01 | Optional date range with explicit user intent |

### Pending Todos

10 todos in `.planning/todos/pending/`

### Blockers/Concerns

(None)

## Session Continuity

Last session: 2026-01-18 19:15 UTC
Stopped at: Completed 46-01-PLAN.md
Resume file: None

---

**Next Step:** Execute 46-02-PLAN.md (Food Library swipe actions).
