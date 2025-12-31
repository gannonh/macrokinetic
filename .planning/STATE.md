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

Phase: 16 of 17 (Weekly Check-ins)
Plan: 1 of 2 in current phase
Status: In progress
Last activity: 2025-12-31 - Completed 16-01-PLAN.md

Progress: ████████░░ 82%

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
| 15.1 | 3/3 | 15 min | 5 min |
| 15.2 | 4/4 | 32 min | 8 min |
| 16 | 1/2 | 8 min | 8 min |
| 17 | 0/? | - | - |

**Recent Trend:**
- Last 5 plans: 15.2-02 (5 min), 15.2-03 (8 min), 15.2-04 (12 min), 16-01 (8 min)
- Trend: Phase 16 in progress

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
| 15.1-02 | DispatchQueue 0.35s delay for sheet chaining | Minimal code change vs fullScreenCover(item:); ensures GoalWizard dismissal animation completes before ProgramWizard presents |
| 15.2-01 | WeeklyConstants enum for shared validWeekdayRange | DRY principle; both WeeklyMacroDistribution and WeeklyCalorieDistribution use same constant |
| 15.2-03 | Use defaults for missing optional fields in save() | Collaborative/Manual modes don't require all Coached fields; validation relaxed per program style |
| 15.2-04 | CollaborativeDayConfig struct for per-day state | Holds calories, proteinGramsPerLb, carbFatRatio, isLocked; auto-adjust distributes delta to unlocked days |
| 16-01 | Default check-in day to Monday (weekday=2) | Common weekly planning pattern; 7-day minimum between check-ins; 70% confidence threshold for TDEE changes |

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

Last session: 2025-12-31T19:37:32Z
Stopped at: Completed 16-01-PLAN.md
Resume file: None

### Recent Fixes (2025-12-30)
- Fixed Collaborative TDEE showing wrong calories (1564 vs 2166) - training level default changed from `.none` to `.lifting`
- Added integer formatter for calorie TextField (was showing decimals)
- Updated Collaborative Weekly Distribution UI with color-coded macro rows (P/F/C)
- Made CollaborativeDistributionStepView compact to fit above the fold:
  - Reduced header, card, and slider spacing
  - Added compactCardBackground modifier with tighter padding
  - Shrunk weekly grid with smaller fonts and row heights
  - Made day selector circles smaller (36px vs 40px)
  - Shortened helper text
- Fixed Edit Goal flow - ProgramSummarySheet/ProgramReadySheet now use @Query goal for loaded relationships
- Added recalculateProgramTargets() to update calorie/macro targets when "Looks Good" clicked after goal edit
- Show ProgramReadySheet for ALL new programs (not just Coached)
- Added Goal Summary card to Strategy view with target weight and weekly rate display
