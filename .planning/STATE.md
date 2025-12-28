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

Phase: 15.1 of 17 (Initial TDEE Integration) - INSERTED
Plan: 1 of 3 in current phase
Status: In progress
Last activity: 2025-12-28 - Completed 15.1-01-PLAN.md

Progress: ██████░░░░ 59%

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
| 14 | 3/3 | 28 min | 9 min |
| 15 | 1/1 | 2 min | 2 min |
| 15.1 | 1/3 | 5 min | 5 min |
| 16 | 0/? | - | - |
| 17 | 0/? | - | - |

**Recent Trend:**
- Last 5 plans: 14-02 (9 min), 14-03 (11 min), 15-01 (2 min), 15.1-01 (5 min)
- Trend: Phase 15.1 in progress

*Updated after each plan completion*

## Accumulated Context

### Decisions Made

| Phase | Decision | Rationale |
|-------|----------|-----------|
| 12-01 | MacroPercentages struct instead of tuple | SwiftLint large_tuple compliance, cleaner API with named properties |
| 13-01 | Extended file_length SwiftLint rule for Nutrition views | Wizard contains 7 inline step views per architecture decision |
| 13-02 | Separate Goal and Program into distinct wizards | Mock review revealed incorrect domain coupling; Goal = type + target weight + rate, Program = style + diet prefs |
| 14-01 | Empty string default for gender with case-insensitive matching | CloudKit compatibility; unknown gender averages male/female BMR formulas |
| 15-01 | Ring size 70pt with 6pt line width, consumed inside ring | Compact display fits 4 rings on iPhone SE, uses existing CircularProgressRing |

### Deferred Issues

None yet.

### Roadmap Evolution

- Milestone v0.3.0 created: Goals & Nutrition Programs, 6 phases (Phase 12-17)
- Phase 15.1 inserted after Phase 15: Initial TDEE Integration (URGENT) - Wire up TDEEService to goal creation, collect biometrics, calculate initial calorie/macro targets. Required before Phase 16 (Weekly Check-ins) which depends on TDEE working.

### Blockers/Concerns Carried Forward

None yet.

## Project Alignment

Last checked: 2025-12-27
Status: ✓ Aligned
Assessment: New milestone - baseline alignment.
Drift notes: None

## Session Continuity

Last session: 2025-12-28T21:47:29Z
Stopped at: Completed 15.1-01-PLAN.md
Resume file: None
