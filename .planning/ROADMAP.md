# Roadmap: MacroKinetic

## Overview

MacroKinetic is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management. See [project-prd.md](./project-prd.md) for complete product requirements.

## Domain Expertise

- ~/.claude/skills/ios-dev/SKILL.md

## Completed Milestones

- ✅ [v0.2.0 Enhanced Tracking](milestones/v0.2.0-ROADMAP.md) (Phases 5-11) - SHIPPED 2025-12-27
- ✅ [v0.1.0 Custom Foods](milestones/v0.1.0-ROADMAP.md) (Phases 1-4) - SHIPPED 2025-12-24

## Milestones

- 🚧 **v0.3.0 Goals & Nutrition Programs** - Phases 12-17 (in progress)

## Phases

### 🚧 v0.3.0 Goals & Nutrition Programs (In Progress)

**Milestone Goal:** Set personalized weight and macro goals with program styles (Coached/Collaborative/Manual), diet preferences, adaptive TDEE, and track daily progress with visual indicators and weekly check-ins.

#### Phase 12: Goal Data Model

**Goal**: SwiftData models for goals, nutrition programs, and TDEE tracking
**Depends on**: Previous milestone complete
**Research**: Unlikely (internal patterns - SwiftData)
**Plans**: 2

Plans:
- [x] 12-01: Data Foundation - Enums and value types (ProgramConfiguration.swift)
- [x] 12-02: SwiftData Models - NutritionGoal, NutritionProgram, User integration

#### Phase 13: Goal Configuration Wizard

**Goal**: Separate Goal and Program wizards with correct domain boundaries, Strategy view entry points
**Depends on**: Phase 12
**Research**: Unlikely (internal patterns - SwiftUI wizard)
**Plans**: 2

Plans:
- [x] 13-01: Initial wizard implementation (to be refactored in 13-02)
- [x] 13-02: Goal/Program design refactor - Separate wizards, Strategy view, NutritionGoal model updates

#### Phase 14: Adaptive TDEE Engine

**Goal**: Personalized metabolic rate calculation from weight history with trend smoothing
**Depends on**: Phase 13
**Research**: Likely (algorithm research)
**Research topics**: Adaptive TDEE algorithms, metabolic adaptation modeling, weight trend smoothing, calorie adjustment formulas
**Plans**: TBD

Plans:
- [x] 14-01: TDEE data foundation - User height/gender, TrainingLevel multipliers, TDEECalculationEngine
- [x] 14-02: Adaptive TDEE calculations - EWMA smoothing, confidence scoring, metabolic adaptation
- [x] 14-03: TDEEService orchestration - Initial/adaptive TDEE, goal updates, recalculation scheduling

#### Phase 15: Daily Tracking Dashboard

**Goal**: Progress rings for calories/macros, remaining vs consumed display, color coding for under/on-track/over
**Depends on**: Phase 14
**Research**: Unlikely (internal patterns - Swift Charts)
**Plans**: 1

Plans:
- [x] 15-01: Circular progress rings for NutritionSummaryCard with color thresholds

#### Phase 15.1: Initial TDEE Integration (INSERTED)

**Goal**: HealthKit biometrics integration, wire TDEEService to Coached mode goal creation, fix Program Wizard bugs
**Depends on**: Phase 15
**Research**: Unlikely (internal patterns - TDEEService built in Phase 14, HealthKit write exists)
**Plans**: 3

**Scope:**
- HealthKit READ integration: Import height, sex, DOB, weight when available
- Settings → Health Integration UI with manual entry fallback
- Wire TDEEService.calculateInitialTDEE() to Coached mode goal creation
- Fix Program Wizard blank screen race condition bug
- Program summary screen with calculated TDEE/targets display

Plans:
- [x] 15.1-01: HealthKit Foundation - HealthKitService, Settings UI, Info.plist
- [x] 15.1-02: TDEE Integration - Wire TDEEService to ProgramWizard, fix race condition
- [x] 15.1-03: Program Summary - Display calculated targets, E2E test stubs

#### Phase 15.2: Program Style Implementation (INSERTED)

**Goal**: Implement Collaborative and Manual program styles with weekly macro distribution
**Depends on**: Phase 15.1
**Research**: Unlikely (UI patterns from mocks)
**Plans**: TBD

**Scope:**
- Collaborative mode: Weekly macro grid with per-day editing (sliders for protein g/lb, carb:fat ratio)
- Manual mode: Same targets all week vs Different targets per day
- Weekly Distribution mode actually functional (Even vs Shifted)
- Per-day macro storage in NutritionProgram model

Plans:
- [x] 15.2-01: Data Model Foundation - WeeklyMacroDistribution, DailyMacros, NutritionProgram extensions
- [x] 15.2-02: Wizard Conditional Steps - Step views for Collaborative, Manual, Coached/Shifted modes
- [x] 15.2-03: Per-Day UI - ProgramReadySheet per-day display, wizard save, Dashboard/FoodLog wiring
- [x] 15.2-04: Fix Collaborative Mode - Single distribution editor with per-day editing and auto-adjust

#### Phase 16: Weekly Check-ins

**Goal**: Weight trend review, adherence summary, goal and program adjustment flow
**Depends on**: Phase 15.2
**Research**: Unlikely (internal patterns - existing weight tracking)
**Plans**: 2

**Scope:**
- WeeklyCheckInService for summary generation (EWMA weight smoothing, nutrition adherence)
- WeeklyCheckInSheet UI with weight progress and nutrition summary cards
- Dynamic countdown card in StrategyView with check-in trigger
- Navigation to goal/program adjustment from check-in

Plans:
- [x] 16-01: WeeklyCheckInService, lastCheckInDate field, check-in day settings UI
- [x] 16-02: ProgramOptimizationSheet, StrategyView integration, dynamic countdown, E2E test stubs

#### Phase 17: More Tab Refinements

**Goal**: Reorganize More tab with cleaner groupings, add new settings screens (Security & Privacy, Notifications, mock screens for Calorie Expenditure and Subscription)
**Depends on**: Phase 16
**Research**: Unlikely (internal patterns - existing settings UI)
**Plans**: 3

**Scope:**
- MoreView restructure: Remove User Card, add overflow menu, reorganize sections
- SecurityPrivacyView: Face ID toggle, Health toggle, iCloud sync status
- NotificationSettingsView: Weigh-in, food logging, medication reminder toggles with scheduling
- CalorieExpenditureView: Mock screen with "Coming soon" indicators
- SubscriptionView: Mock screen showing plan details and management links
- NotificationService extensions for weigh-in and food logging reminders

Plans:
- [x] 17-01: MoreView restructure, SecurityPrivacyView, SubscriptionSettingsView (mock)
- [ ] 17-02: NotificationSettingsView with NotificationService extensions
- [ ] 17-03: CalorieExpenditureView (mock), inactive placeholders, E2E test stubs

## Progress

**Execution Order:**
Phases execute in numeric order within each milestone.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 12. Goal Data Model | v0.3.0 | 2/2 | Complete | 2025-12-27 |
| 13. Goal Configuration Wizard | v0.3.0 | 2/2 | Complete | 2025-12-28 |
| 14. Adaptive TDEE Engine | v0.3.0 | 3/3 | Complete | 2025-12-28 |
| 15. Daily Tracking Dashboard | v0.3.0 | 1/1 | Complete | 2025-12-28 |
| 15.1 Initial TDEE Integration | v0.3.0 | 3/3 | Complete | 2025-12-28 |
| 15.2 Program Style Implementation | v0.3.0 | 4/4 | Complete | 2025-12-30 |
| 16. Weekly Check-ins | v0.3.0 | 2/2 | Complete | 2025-12-31 |
| 17. More Tab Refinements | v0.3.0 | 1/3 | In progress | - |

<details>
<summary>✅ v0.2.0 Enhanced Tracking (Phases 5-11) - SHIPPED 2025-12-27</summary>

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 5. Food Log Calendar | 1/1 | Complete | 2025-12-24 |
| 6. Food Entry Editing | 1/1 | Complete | 2025-12-24 |
| 7. Food Library | 1/1 | Complete | 2025-12-24 |
| 8. Quick Add | 1/1 | Complete | 2025-12-25 |
| 9. Weight Tracking | 3/3 | Complete | 2025-12-25 |
| 10. Metrics & Photos | 2/2 | Complete | 2025-12-26 |
| 11. Feature Settings | 2/2 | Complete | 2025-12-26 |

</details>

<details>
<summary>✅ v0.1.0 Custom Foods (Phases 1-4) - SHIPPED 2025-12-24</summary>

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. CustomFood Model & Storage | 1/1 | Complete | 2025-12-22 |
| 2. Create Food UI | 2/2 | Complete | 2025-12-22 |
| 3. Food Library Integration | 1/1 | Complete | 2025-12-23 |
| 4. Barcode Assignment | 2/2 | Complete | 2025-12-23 |

</details>
