# Project State

## Project Summary

**Building:** MacroKinetic — iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management.

**Last shipped:** v0.8.0 Food Search & Library (2026-01-13)

**Core value:** Adaptive calorie targets based on real expenditure data with unified dashboard visualization.

## Current Position

Phase: 42 of 43 (Serving Unit Mapping) - COMPLETE
Plan: All plans complete (1/1)
Status: Phase verified, ready for Phase 43
Last activity: 2026-01-16 - Phase 42 execution complete

Progress: ████████░░ 80%

## GitHub Tracking

Issue: N/A
PR: #339
Branch: feat/41-glp1-analytics-fixes
Status: PR Review complete - ready for CodeRabbit review or merge

## Performance Metrics

**v0.8.0 Velocity:**
- Total plans completed: 5 (including 35.1 inserted phase)
- Average duration: 10 min
- Total execution time: ~50 min

**By Phase:**

| Phase | Plans | Total   | Avg/Plan |
|-------|-------|---------|----------|
| 35    | 1     | ~15 min | 15 min   |
| 35.1  | 1     | ~10 min | 10 min   |
| 36    | 0     | skipped | -        |
| 37    | 1     | ~15 min | 15 min   |
| 38    | 1     | 7 min   | 7 min    |
| 41    | 3     | ~20 min | 7 min    |

## Accumulated Context

### Decisions Made

**Phase 42 decisions (Plan 01):**
- Use density thresholds (cup: 80-300g, tbsp: 5-25g, tsp: 2-10g) to detect suspicious unit labels
- Sanitize suspicious labels to generic 'serving' instead of removing them
- Apply validation both at data import time AND at UI display time (defense in depth)

**Phase 41 decisions (FIX plan):**
- Use 0.5-hour sampling interval for histogram (4x increase from 2.0 hours)
- Calculate optimal therapeutic concentration as midpoint of min/max
- Disable design token lint rules for chart-specific color constants (internal implementation)

**Phase 41 decisions (Plan 01):**
- Changed steadyStateProgress return type from percentage (0-100) to decimal (0.0-1.0)
- UI code already expected decimal and multiplied by 100, so only API change needed
- Pharmacokinetics progress values should always return decimals (0.0-1.0), let UI format as percentage

**Phase 41 decisions (Plan 02):**
- Use 0.8 opacity on bars to allow therapeutic range band to show through
- BarMark auto-determines bar width based on data density
- Per-bar accessibility labels with date/time and concentration value

**Phase 40 decisions (Plan 01):**
- Stepper control chosen over TextField for better UX with discrete dose increments
- Medication-specific therapeutic bounds for dose range (varies by medication type)
- Compounded medications use 0.25mg fine-grained steps; branded use pen dose steps
- Dose values automatically clamped to valid range via didSet

**Phase 39 decisions:**
- DayStatus model stores fasting flag per day
- Fasting toggle only shown when no food entries exist
- Today always excluded from multi-day aggregations (partial data)
- Fasting days excluded from TDEE calorie averaging

**v0.8.0 decisions:**
- Removed ALL Open Food Facts API code - local database (1.7M foods) is sufficient
- If barcode not found locally, user creates custom food (no API fallback)
- Horizontal pill picker for serving unit selection
- Header indicators in Food Search matching Food Log style

### Deferred Issues

No open issues in `.planning/ISSUES.md`.
- ISS-001 resolved in Phase 38-01

### Pending Todos

5 todos in `.planning/todos/pending/`

### Roadmap Evolution

- Milestone v0.9.0 created: Improvements & Fixes, 5 phases (Phase 39-43)
- Milestone v0.8.0 complete: Food Search & Library, 5 phases (Phase 35-38)
- Phase 35.1 inserted after Phase 35: Food Search Header Indicators
- Phase 36 (Search Ranking) skipped - to be revisited in future milestone

### Blockers/Concerns Carried Forward

None.

## Project Alignment

Last checked: 2026-01-16
Status: ✓ Aligned
Assessment: Phase 42 complete. Serving label validation and unit conversion fixes verified.
Drift notes: None

## Session Continuity

Last session: 2026-01-16T21:14:56Z
Stopped at: Completed 42-01-PLAN.md (serving unit mapping)
Resume file: None
