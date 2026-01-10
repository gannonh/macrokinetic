# Roadmap: MacroKinetic

## Overview

MacroKinetic is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management. See [project-prd.md](./project-prd.md) for complete product requirements.

## Domain Expertise

- ~/.claude/skills/ios-dev/SKILL.md

## Completed Milestones

- ✅ [v0.6.0 Onboarding Redux](milestones/v0.6.0-ROADMAP.md) (Phases 25-29) - SHIPPED 2026-01-07
- ✅ [v0.5.0 Navigation Refinement](milestones/v0.5.0-ROADMAP.md) (Phases 22-24) - SHIPPED 2026-01-05
- ✅ [v0.4.0 Calorie Expenditure Enhancements](milestones/v0.4.0-ROADMAP.md) (Phases 18-21) - SHIPPED 2026-01-04
- ✅ [v0.3.0 Goals & Nutrition Programs](milestones/v0.3.0-ROADMAP.md) (Phases 12-17) - SHIPPED 2026-01-02
- ✅ [v0.2.0 Enhanced Tracking](milestones/v0.2.0-ROADMAP.md) (Phases 5-11) - SHIPPED 2025-12-27
- ✅ [v0.1.0 Custom Foods](milestones/v0.1.0-ROADMAP.md) (Phases 1-4) - SHIPPED 2025-12-24

## Milestones

- 🚧 **v0.7.0 Dashboard Widget UX** - Phases 30-34 (in progress)

## Phases

### 🚧 v0.7.0 Dashboard Widget UX (In Progress)

**Milestone Goal:** Build the new unified dashboard with widget-based UI — static mockups first, wired to data once patterns established.

**Design Reference:**: `mocks/dashboard/DASHBOARD.png`

#### Phase 30: Dashboard Foundation

**Goal**: Create DashboardView with widget container system, establish reusable widget card patterns
**Depends on**: Previous milestone complete
**Research**: Unlikely (SwiftUI patterns)
**Plans**: TBD

**Figma References:**
- Hero Widget Container: `mocks/dashboard/Hero Widget.png`
- Standard Widget Pattern: `mocks/dashboard/Standard Widget, Grouped.png`

Plans:
- [x] 30-01: Foundation & Containers (DashboardWidget protocol, WidgetCard, HeroWidgetContainer, StandardWidgetGroup)
- [x] 30-02: Hero Widget Integration (WeeklyNutritionHeroWidget with mock data, integrate into DashboardView)

#### Phase 31: Main Widget (Hero)

**Goal**: Swipeable carousel with 3 states (Weekly Nutrition, Energy Balance, Daily Nutrition), Consumed/Remaining toggle
**Depends on**: Phase 30
**Research**: Unlikely (Swift Charts, internal)
**Plans**: TBD

**Figma References:**
- Weekly Nutrition: `mocks/dashboard/HERO - Weekly Nutrition.png`
- Energy Balance: `mocks/dashboard/HERO - Energy Balance.png`
- Daily Nutrition: `mocks/dashboard/HERO - Daily Nutrition.png`

Plans:
- [x] 31-01: Daily Nutrition Widget (DailyNutritionHeroWidget with circular ring, macro bars, environment-based toggle)
- [x] 31-02: Energy Balance Widget + Integration (EnergyBalanceHeroWidget with Swift Charts, complete carousel)

#### Phase 32: Standard Widgets - Insights

**Goal**: Insights & Analytics widget group with Expenditure, Weight Trend, Energy Balance, Goal Progress, Deficit cards
**Depends on**: Phase 31
**Research**: Unlikely (internal patterns)
**Plans**: TBD

**Figma References:**
- Insights & Analytics Group: `mocks/dashboard/Standard Widget, Grouped.png`

Plans:
- [x] 32-01: Standard Widget Components (ExpenditureWidget, WeightTrendWidget, EnergyBalanceWidget, GoalProgressWidget)

#### Phase 33: Detail Views

**Goal**: Weight Trend, Expenditure, Energy Balance detail screens with charts and time range filters
**Depends on**: Phase 32
**Research**: Unlikely (Swift Charts, internal)
**Plans**: 3

**Figma References:**
- Weight Trend Detail: `mocks/dashboard/Detail - Weight Trend.png`
- Expenditure Detail: `mocks/dashboard/Detail - Expenditure.png`
- Energy Balance Detail: `mocks/dashboard/Detail - Energy Balance.png`

Plans:
- [x] 33-01: Weight Trend Detail View (header, time filters, line chart, insights cards, data sources)
- [ ] 33-02: Expenditure Detail View (bar chart, insights cards, shared DetailTimePeriodSelector)
- [ ] 33-03: Energy Balance Detail View (mode toggle, navigation wiring from widgets)

#### Phase 34: Integration & Polish

**Goal**: Wire static UI to live data, transitions, E2E tests
**Depends on**: Phase 33
**Research**: Unlikely (internal wiring)
**Plans**: TBD

Plans:
- [ ] 34-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order within each milestone.

### 🚧 v0.7.0 Dashboard Widget UX (Phases 30-34)

| Phase                           | Plans Complete | Status      | Completed  |
| ------------------------------- | -------------- | ----------- | ---------- |
| 30. Dashboard Foundation        | 2/2            | Complete    | 2026-01-08 |
| 31. Main Widget (Hero)          | 2/2            | Complete    | 2026-01-09 |
| 32. Standard Widgets - Insights | 1/1            | Complete    | 2026-01-09 |
| 33. Detail Views                | 1/3            | In progress | -          |
| 34. Integration & Polish        | 0/?            | Not started | -          |

<details>
<summary>✅ v0.6.0 Onboarding Redux (Phases 25-29) - SHIPPED 2026-01-07</summary>

| Phase                               | Plans Complete | Status   | Completed  |
| ----------------------------------- | -------------- | -------- | ---------- |
| 25. Onboarding Foundation           | 2/2            | Complete | 2026-01-06 |
| 26. USP Showcase Screens            | 1/1            | Complete | 2026-01-06 |
| 27. Simplified Goal & Program Setup | 1/1            | Complete | 2026-01-06 |
| 28. Permission Setup Screens        | 1/1            | Complete | 2026-01-07 |
| 29. Integration & Polish            | 1/1            | Complete | 2026-01-07 |

</details>

<details>
<summary>✅ v0.5.0 Navigation Refinement (Phases 22-24) - SHIPPED 2026-01-05</summary>

| Phase                            | Plans Complete | Status   | Completed  |
| -------------------------------- | -------------- | -------- | ---------- |
| 22. GLP-1 Programs Consolidation | 2/2            | Complete | 2026-01-05 |
| 23. Strategy Tab Promotion       | 1/1            | Complete | 2026-01-05 |
| 24. Add Button Redesign          | 1/1            | Complete | 2026-01-05 |

</details>

<details>
<summary>✅ v0.4.0 Calorie Expenditure Enhancements (Phases 18-21) - SHIPPED 2026-01-04</summary>

| Phase                              | Plans Complete | Status   | Completed  |
| ---------------------------------- | -------------- | -------- | ---------- |
| 18. Complete Add Burned Calories   | 1/1            | Complete | 2026-01-03 |
| 19. Rollover Calories              | 1/1            | Complete | 2026-01-03 |
| 20. Predictive Activity Adjustment | 1/1            | Complete | 2026-01-03 |
| 21. Integration & Polish           | 1/1            | Complete | 2026-01-04 |

</details>

<details>
<summary>✅ v0.3.0 Goals & Nutrition Programs (Phases 12-17) - SHIPPED 2026-01-02</summary>

| Phase                             | Plans Complete | Status   | Completed  |
| --------------------------------- | -------------- | -------- | ---------- |
| 12. Goal Data Model               | 2/2            | Complete | 2025-12-27 |
| 13. Goal Configuration Wizard     | 2/2            | Complete | 2025-12-28 |
| 14. Adaptive TDEE Engine          | 3/3            | Complete | 2025-12-28 |
| 15. Daily Tracking Dashboard      | 1/1            | Complete | 2025-12-28 |
| 15.1 Initial TDEE Integration     | 3/3            | Complete | 2025-12-28 |
| 15.2 Program Style Implementation | 4/4            | Complete | 2025-12-30 |
| 16. Weekly Check-ins              | 2/2            | Complete | 2025-12-31 |
| 17. More Tab Refinements          | 3/3            | Complete | 2026-01-01 |

</details>

<details>
<summary>✅ v0.2.0 Enhanced Tracking (Phases 5-11) - SHIPPED 2025-12-27</summary>

| Phase                 | Plans Complete | Status   | Completed  |
| --------------------- | -------------- | -------- | ---------- |
| 5. Food Log Calendar  | 1/1            | Complete | 2025-12-24 |
| 6. Food Entry Editing | 1/1            | Complete | 2025-12-24 |
| 7. Food Library       | 1/1            | Complete | 2025-12-24 |
| 8. Quick Add          | 1/1            | Complete | 2025-12-25 |
| 9. Weight Tracking    | 3/3            | Complete | 2025-12-25 |
| 10. Metrics & Photos  | 2/2            | Complete | 2025-12-26 |
| 11. Feature Settings  | 2/2            | Complete | 2025-12-26 |

</details>

<details>
<summary>✅ v0.1.0 Custom Foods (Phases 1-4) - SHIPPED 2025-12-24</summary>

| Phase                         | Plans Complete | Status   | Completed  |
| ----------------------------- | -------------- | -------- | ---------- |
| 1. CustomFood Model & Storage | 1/1            | Complete | 2025-12-22 |
| 2. Create Food UI             | 2/2            | Complete | 2025-12-22 |
| 3. Food Library Integration   | 1/1            | Complete | 2025-12-23 |
| 4. Barcode Assignment         | 2/2            | Complete | 2025-12-23 |

</details>
