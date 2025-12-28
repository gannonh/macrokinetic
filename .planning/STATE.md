# Project State

## Project Summary

**Building:** Goals and nutrition programs for MacroKinetic with personalized weight/macro targets, program styles (Coached/Collaborative/Manual), diet preferences, adaptive TDEE, daily progress tracking, and weekly check-ins.

**Core requirements:**
- Goal configuration wizard with program style, diet preference, calorie floor, weekly distribution, protein level
- Adaptive TDEE engine that learns from weight history
- Daily tracking dashboard with progress rings, remaining/consumed, color coding
- Weekly check-ins for weight trend review and goal/program adjustments
- Edit goals from settings

**Constraints:**
- CloudKit sync required for cross-device access
- Offline-first functionality
- Follow existing MVVM architecture and @Observable patterns
- iOS 17+ APIs only

## Current Position

Phase: 14 of 17 (Adaptive TDEE Engine)
Plan: 1 of 3 in current phase
Status: In progress
Last activity: 2025-12-28 - Completed 14-01 (TDEE data foundation, BMR engine)

Progress: █████░░░░░ 45%

## GitHub Tracking

Issue: #321
PR: #322
Branch: feat/321-v0.3.0-goals-nutrition-programs

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: TBD
- Total execution time: TBD

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 12 | 2/2 | 14 min | 7 min |
| 13 | 2/2 | 34 min | 17 min |
| 14 | 1/3 | 8 min | 8 min |
| 15 | 0/? | - | - |
| 16 | 0/? | - | - |
| 17 | 0/? | - | - |

**Recent Trend:**
- Last 5 plans: 12-02 (8 min), 13-01 (9 min), 13-02 (25 min), 14-01 (8 min)
- Trend: Phase 14 in progress

*Updated after each plan completion*

## Accumulated Context

### Decisions Made

| Phase | Decision | Rationale |
|-------|----------|-----------|
| 12-01 | MacroPercentages struct instead of tuple | SwiftLint large_tuple compliance, cleaner API with named properties |
| 13-01 | Extended file_length SwiftLint rule for Nutrition views | Wizard contains 7 inline step views per architecture decision |
| 13-02 | Separate Goal and Program into distinct wizards | Mock review revealed incorrect domain coupling; Goal = type + target weight + rate, Program = style + diet prefs |
| 14-01 | Empty string default for gender with case-insensitive matching | CloudKit compatibility; unknown gender averages male/female BMR formulas |

### Deferred Issues

None yet.

### Roadmap Evolution

- Milestone v0.3.0 created: Goals & Nutrition Programs, 6 phases (Phase 12-17)

### Blockers/Concerns Carried Forward

None yet.

## Project Alignment

Last checked: 2025-12-27
Status: ✓ Aligned
Assessment: New milestone - baseline alignment.
Drift notes: None

## Session Continuity

Last session: 2025-12-28T15:47:45Z
Stopped at: Completed 14-01-PLAN.md
Resume file: None
