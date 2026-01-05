# Project State

## Project Summary

**Building:** Complete onboarding rewrite for MacroKinetic — focused on core experience with USP showcase, simplified goal/program setup, and permission screens.

**Core requirements:**
- Complete rewrite of onboarding (stash current as reference)
- USP/feature showcase screens (adaptive TDEE, precision tracking, calorie adjustments, GLP-1 support)
- Simplified Goal + Program setup (streamlined for first-time users)
- Individual permission screens: HealthKit, Face ID, Notifications
- Retain Sign in with Apple as first step
- Remove GLP-1 setup and StoreKit for now

**Constraints:**
- CloudKit sync required for cross-device access
- Offline-first functionality
- Follow existing MVVM architecture and @Observable patterns
- iOS 17+ APIs only

## Current Position

Phase: 25 of 29 (Onboarding Foundation)
Plan: Not started
Status: Ready to plan
Last activity: 2026-01-05 - Milestone v0.6.0 created

Progress: ░░░░░░░░░░ 0%

## GitHub Tracking

Issue: TBD
PR: TBD
Branch: TBD

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: -
- Total execution time: 0 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 25    | 0     | -     | -        |

**Recent Trend:**
None yet.

*Updated after each plan completion*

## Accumulated Context

### Decisions Made

| Phase | Decision | Rationale |
|-------|----------|-----------|
| 22-01 | Props-based section components | Maximum reusability for GLP1ProgramsView |
| 22-01 | HistoryMode enum in HistorySection.swift | Co-locate with component that uses it |
| 22-02 | Kept Goals & Strategy as separate More row | Phase 23 will promote it to top-level tab |
| 22-02 | Inline navigation titles for GLP-1 views | Consistent with More tab sub-view patterns |
| 22-02 | Custom medications list in GLP1ProgramsView | Needed swipe actions + empty state not available when embedding |
| 24-01 | Floating overlay button instead of tab item | TabView ignores font size on tab items - overlay allows custom sizing |

### Deferred Issues

None yet.

### Roadmap Evolution

- Milestone v0.4.0 created: Calorie Expenditure Enhancements, 4 phases (Phase 18-21)
- Milestone v0.5.0 created: Navigation Refinement, 3 phases (Phase 22-24)
- Milestone v0.6.0 created: Onboarding Redux, 5 phases (Phase 25-29)

### Blockers/Concerns Carried Forward

None.

## Project Alignment

Last checked: 2026-01-04
Status: ✓ Aligned
Assessment: New milestone - baseline alignment.
Drift notes: None

## Session Continuity

Last session: 2026-01-05T23:01:41Z
Stopped at: Milestone v0.6.0 initialization
Resume file: None
