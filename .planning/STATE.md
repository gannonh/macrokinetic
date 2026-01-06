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
Plan: 2 of 2 in current phase
Status: Phase complete
Last activity: 2026-01-06 - Completed 25-02-PLAN.md

Progress: ██░░░░░░░░ 20%

## GitHub Tracking

Issue: #329
PR: #330
Branch: feat/v0.6.0-onboarding-redux

## Performance Metrics

**Velocity:**
- Total plans completed: 2
- Average duration: 12 min
- Total execution time: 24 min

**By Phase:**

| Phase | Plans | Total  | Avg/Plan |
|-------|-------|--------|----------|
| 25    | 2     | 24 min | 12 min   |

**Recent Trend:**
25-01: 20 min (Archive & Core Foundation)
25-02: 4 min (Placeholder Views & Verification)

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
| 25-01 | Prefixed legacy types with "Legacy" | Avoid type conflicts while maintaining legacy code as reference |
| 25-01 | Lazy ViewModel initialization in OnboardingView | Used @State with onAppear instead of init-time for @Observable + View lifecycle |

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

Last session: 2026-01-06T00:20:01Z
Stopped at: Completed 25-02-PLAN.md (Phase 25 complete)
Resume file: None (ready for Phase 26 planning)
