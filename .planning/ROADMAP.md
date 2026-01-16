# Roadmap: MacroKinetic

## Overview

MacroKinetic is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management. See [project-prd.md](./project-prd.md) for complete product requirements.


## Completed Milestones

- ✅ [v0.8.0 Food Search & Library](milestones/v0.8.0-ROADMAP.md) (Phases 35-38) - SHIPPED 2026-01-13
- ✅ [v0.7.0 Dashboard Widget UX](milestones/v0.7.0-ROADMAP.md) (Phases 30-34) - SHIPPED 2026-01-12
- ✅ [v0.6.0 Onboarding Redux](milestones/v0.6.0-ROADMAP.md) (Phases 25-29) - SHIPPED 2026-01-07
- ✅ [v0.5.0 Navigation Refinement](milestones/v0.5.0-ROADMAP.md) (Phases 22-24) - SHIPPED 2026-01-05
- ✅ [v0.4.0 Calorie Expenditure Enhancements](milestones/v0.4.0-ROADMAP.md) (Phases 18-21) - SHIPPED 2026-01-04
- ✅ [v0.3.0 Goals & Nutrition Programs](milestones/v0.3.0-ROADMAP.md) (Phases 12-17) - SHIPPED 2026-01-02
- ✅ [v0.2.0 Enhanced Tracking](milestones/v0.2.0-ROADMAP.md) (Phases 5-11) - SHIPPED 2025-12-27
- ✅ [v0.1.0 Custom Foods](milestones/v0.1.0-ROADMAP.md) (Phases 1-4) - SHIPPED 2025-12-24

## Milestones

- ✅ **v0.8.0 Food Search & Library** - Phases 35-38 (shipped)
- 🚧 **v0.9.0 Improvements & Fixes** - Phases 39-43 (in progress)

## Phases

### 🚧 v0.9.0 Improvements & Fixes (In Progress)

**Milestone Goal:** Address analytics accuracy issues and enhance GLP-1 medication tracking UX.

#### Phase 39: Day Status Tracking ✅

**Goal**: Add day completion status (logging/complete/fasting) to handle partial days and fast days in analytics
**Depends on**: Previous milestone complete
**Research**: Unlikely (internal patterns)
**Completed**: 2026-01-15

Related todos:
- Handle partial day calculations in dashboard
- Mark fast days to exclude from calculations

Plans:
- [x] 39-01: Day Status Tracking Implementation

#### Phase 40: GLP-1 Dose Adjustments ✓

**Goal**: Allow adjustable dose amount when logging shots for compounded medications
**Depends on**: Phase 39
**Research**: Unlikely (internal UI patterns)
**Plans**: 1

Related todos:
- Allow adjustable dose amount when logging shots

Plans:
- [x] 40-01: Quick Dose Entry Adjustability

#### Phase 41: GLP-1 Analytics Fixes ✅

**Goal**: Fix steady state progress calculation (2416% bug) and change concentration graph to histogram
**Depends on**: Phase 40
**Research**: Unlikely (internal patterns)
**Completed**: 2026-01-15

Related todos:
- Fix steady state progress calculation showing 2416%
- Change drug concentration graph to histogram

Plans:
- [x] 41-01: Fix Steady State Progress Calculation
- [x] 41-02: Change Concentration Chart to Histogram

#### Phase 42: Serving Unit Mapping

**Goal**: Fix serving unit to gram mapping for foods with unrealistic conversions and unit conversion when editing
**Depends on**: Phase 41
**Research**: Unlikely (database/data quality)
**Plans**: 1

Related todos:
- Fix serving unit to gram mapping for foods
- Fix food entry unit conversion when editing

Plans:
- [ ] 42-01-PLAN.md — Serving label validation and unit conversion fixes

#### Phase 43: Integration & Polish

**Goal**: Final testing, edge cases, and cleanup for v0.9.0
**Depends on**: Phase 42
**Research**: Unlikely (internal)
**Plans**: TBD

Plans:
- [ ] 43-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order within each milestone.

### 🚧 v0.9.0 Improvements & Fixes (Phases 39-43) - In Progress

| Phase                      | Plans Complete | Status      | Completed  |
| -------------------------- | -------------- | ----------- | ---------- |
| 39. Day Status Tracking    | 1/1            | Complete    | 2026-01-15 |
| 40. GLP-1 Dose Adjustments | 1/1            | Complete    | 2026-01-15 |
| 41. GLP-1 Analytics Fixes  | 2/2            | Complete    | 2026-01-15 |
| 42. Serving Unit Mapping   | 0/1            | Not started | -          |
| 43. Integration & Polish   | 0/?            | Not started | -          |

<details>
<summary>✅ v0.8.0 Food Search & Library (Phases 35-38) - SHIPPED 2026-01-13</summary>

| Phase                             | Plans Complete | Status   | Completed  |
| --------------------------------- | -------------- | -------- | ---------- |
| 35. Search Performance & UX       | 1/1            | Complete | 2026-01-12 |
| 35.1 Header Indicators (INSERTED) | 1/1            | Complete | 2026-01-12 |
| 36. Search Ranking & Recall       | 0/0            | Skipped  | -          |
| 37. Unit/Serving Strategy         | 1/1            | Complete | 2026-01-12 |
| 38. Bug Fixes & Cleanup           | 1/1            | Complete | 2026-01-13 |

</details>

<details>
<summary>✅ v0.7.0 Dashboard Widget UX (Phases 30-34) - SHIPPED 2026-01-12</summary>

| Phase                           | Plans Complete | Status   | Completed  |
| ------------------------------- | -------------- | -------- | ---------- |
| 30. Dashboard Foundation        | 2/2            | Complete | 2026-01-08 |
| 31. Main Widget (Hero)          | 2/2            | Complete | 2026-01-09 |
| 32. Standard Widgets - Insights | 1/1            | Complete | 2026-01-09 |
| 33. Detail Views                | 3/3            | Complete | 2026-01-10 |
| 33.1 TDEE History (INSERTED)    | 2/2            | Complete | 2026-01-11 |
| 34. Integration & Polish        | 4/4            | Complete | 2026-01-12 |

</details>

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
