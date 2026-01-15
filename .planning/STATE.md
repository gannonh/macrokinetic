# Project State

## Project Summary

**Building:** MacroKinetic — iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management.

**Last shipped:** v0.8.0 Food Search & Library (2026-01-13)

**Core value:** Adaptive calorie targets based on real expenditure data with unified dashboard visualization.

## Current Position

Phase: 40 of 43 (GLP-1 Dose Adjustments)
Plan: Not started
Status: Ready for planning
Last activity: 2026-01-15 - Phase 39 complete

Progress: ██░░░░░░░░ 20%

## GitHub Tracking

Issue: N/A
PR: N/A
Branch: main
Status: Phase 39 complete on main

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

## Accumulated Context

### Decisions Made

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

7 todos in `.planning/todos/pending/`

### Roadmap Evolution

- Milestone v0.9.0 created: Improvements & Fixes, 5 phases (Phase 39-43)
- Milestone v0.8.0 complete: Food Search & Library, 5 phases (Phase 35-38)
- Phase 35.1 inserted after Phase 35: Food Search Header Indicators
- Phase 36 (Search Ranking) skipped - to be revisited in future milestone

### Blockers/Concerns Carried Forward

None.

## Project Alignment

Last checked: 2026-01-15
Status: ✓ Aligned
Assessment: Phase 39 complete, ready to plan Phase 40.
Drift notes: None

## Session Continuity

Last session: 2026-01-15T07:36:00Z
Stopped at: Phase 39 execution complete
Resume file: None
