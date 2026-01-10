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

Phase: 33 of 34 (Detail Views)
Plan: 3 of 3 in current phase
Status: Phase complete
Last activity: 2026-01-10 - Completed 33-03-PLAN.md

Progress: ████████░░ 80%

## GitHub Tracking

Issue: #331
PR: #332
Branch: feat/v0.7.0-dashboard-widget-ux

## Performance Metrics

**Velocity:**
- Total plans completed: 8
- Average duration: 21 min
- Total execution time: 161 min

**By Phase:**

| Phase | Plans | Total   | Avg/Plan |
|-------|-------|---------|----------|
| 30    | 2     | 37 min  | 18 min   |
| 31    | 2     | 109 min | 54 min   |
| 32    | 1     | 4 min   | 4 min    |
| 33    | 3     | 11 min  | 3 min    |

**Recent Trend:**
- 30-01: 7 min (Foundation & Containers)
- 30-02: 30 min (Hero Widget Integration)
- 31-01: 64 min (Daily Nutrition Widget)
- 31-02: 45 min (Energy Balance + Integration)
- 32-01: 4 min (Standard Widgets - Insights)
- 33-01: 5 min (Weight Trend Detail View)
- 33-02: 4 min (Expenditure Detail View)
- 33-03: 2 min (Energy Balance Detail View)

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
| 30-01 | Array-based HeroWidgetContainer init | Avoid SwiftLint large_tuple violations vs ViewBuilder tuple overloads |
| 30-02 | Rectangular cells (26x38) for macro bars | Better visual hierarchy than square cells for progress visualization |
| 30-02 | Border-only today indicator | Cleaner than "T" text inside cells |
| 31-01 | Environment key for HeroDisplayMode | Cleaner than closure-based injection for shared toggle state |
| 31-01 | 130pt ring diameter (vs 160pt) | User feedback - reduced vertical cramping |
| 31-02 | EnergyDisplayMode environment key | Same pattern as HeroDisplayMode for consistency |
| 31-02 | Page-specific toggles in container | Energy Balance uses different toggle options than Weekly/Daily |
| 31-02 | Daily averages for Energy Balance | More meaningful than 30-day totals for "Last 30 Days" view |
| 31-02 | Day selection defaults to week totals | Simplest UX; tap to drill down into specific days |
| 31-02 | Carousel order: Weekly → Daily → Energy | Daily exists in carousel, Weekly should be primary |

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

Last session: 2026-01-10T22:01:47Z
Stopped at: Completed 33-03-PLAN.md
Resume file: None
