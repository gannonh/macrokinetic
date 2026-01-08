# Project State

## Project Summary

**Building:** Dashboard Widget UX for MacroKinetic — unified dashboard with widget-based UI, static mockups first then wired to data.

**Core requirements:**
- Dashboard foundation with widget container system
- Main Widget (Hero): Swipeable carousel (Weekly Nutrition, Energy Balance, Daily Nutrition) with Consumed/Remaining toggle
- Standard Widgets - Insights & Analytics group (Expenditure, Weight Trend, Energy Balance, Goal Progress, Deficit)
- Detail Views: Weight Trend, Expenditure, Energy Balance screens with charts and time filters
- Static UI first, wire to live data once patterns established

**Constraints:**
- CloudKit sync required for cross-device access
- Offline-first functionality
- Follow existing MVVM architecture and @Observable patterns
- iOS 17+ APIs only
- Use Swift Charts for visualizations

## Current Position

Phase: 30 of 34 (Dashboard Foundation)
Plan: Not started
Status: Ready to plan
Last activity: 2026-01-08 - Milestone v0.7.0 created

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
| 30    | 0     | -     | -        |

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
| 25-01 | Prefixed legacy types with "Legacy" | Avoid type conflicts while maintaining legacy code as reference |
| 25-01 | Lazy ViewModel initialization in OnboardingView | Used @State with onAppear instead of init-time for @Observable + View lifecycle |
| 26-01 | Mint accent color (#00A693) | Brand identity, good contrast with white text in both modes |
| 26-01 | Fullscreen onboarding instead of sheet | Avoid flash of ContentView before onboarding |
| 26-01 | Standard SF font (not rounded) | User preference for standard system typography |
| 27-01 | 2000 kcal baseline with 150g/200g/67g macros | Simple starting point for all goal types |
| 27-01 | Smart defaults for target weight | -10kg for loss, +5kg for gain, 0 for maintain |
| 29-01 | Simple .transition(.opacity) for onboarding→main app | Clean, professional feel without complexity |
| 29-01 | Private helper views in CompletionStepView | CompletionSummaryRow, NextStepRow kept local to file |

### Deferred Issues

None yet.

### Roadmap Evolution

- Milestone v0.4.0 created: Calorie Expenditure Enhancements, 4 phases (Phase 18-21)
- Milestone v0.5.0 created: Navigation Refinement, 3 phases (Phase 22-24)
- Milestone v0.6.0 created: Onboarding Redux, 5 phases (Phase 25-29)
- Milestone v0.7.0 created: Dashboard Widget UX, 5 phases (Phase 30-34)

### Blockers/Concerns Carried Forward

None.

## Project Alignment

Last checked: 2026-01-04
Status: ✓ Aligned
Assessment: New milestone - baseline alignment.
Drift notes: None

## Session Continuity

Last session: 2026-01-08T18:46:40Z
Stopped at: Milestone v0.7.0 initialization
Resume file: None
