# Roadmap: MacroKinetic

## Overview

MacroKinetic is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management. See [project-prd.md](./project-prd.md) for complete product requirements.

## Domain Expertise

- ~/.claude/skills/ios-dev/SKILL.md

## Completed Milestones

- ✅ [v0.7.0 Dashboard Widget UX](milestones/v0.7.0-ROADMAP.md) (Phases 30-34) - SHIPPED 2026-01-12
- ✅ [v0.6.0 Onboarding Redux](milestones/v0.6.0-ROADMAP.md) (Phases 25-29) - SHIPPED 2026-01-07
- ✅ [v0.5.0 Navigation Refinement](milestones/v0.5.0-ROADMAP.md) (Phases 22-24) - SHIPPED 2026-01-05
- ✅ [v0.4.0 Calorie Expenditure Enhancements](milestones/v0.4.0-ROADMAP.md) (Phases 18-21) - SHIPPED 2026-01-04
- ✅ [v0.3.0 Goals & Nutrition Programs](milestones/v0.3.0-ROADMAP.md) (Phases 12-17) - SHIPPED 2026-01-02
- ✅ [v0.2.0 Enhanced Tracking](milestones/v0.2.0-ROADMAP.md) (Phases 5-11) - SHIPPED 2025-12-27
- ✅ [v0.1.0 Custom Foods](milestones/v0.1.0-ROADMAP.md) (Phases 1-4) - SHIPPED 2025-12-24

## Milestones

- 🚧 **v0.8.0 Food Search & Library** - Phases 35-38 (in progress)

## Phases

### 🚧 v0.8.0 Food Search & Library (In Progress)

**Milestone Goal:** Dramatically improve food search UX with better performance, ranking, and serving size handling

#### Phase 35: Search Performance & UX

**Goal**: Fix sluggish typing, auto-focus input, expand amount field tap target, polish search header
**Depends on**: Previous milestone complete
**Research**: Unlikely (internal patterns)
**Plans**: TBD

Plans:
- [x] 35-01: Search UX fixes (debounce, auto-focus, tap targets)

#### Phase 35.1: Food Search Header Indicators (INSERTED)

**Goal**: Update Food Search sheet header to show kcal and protein remaining indicators matching the Food Log view style (progress bars with "X left" labels)
**Depends on**: Phase 35
**Research**: Unlikely (internal patterns - reuse existing FoodLogView indicators)
**Plans**: TBD

Plans:
- [x] 35.1-01: Food Search header indicators

#### Phase 36: Search Ranking & Recall

**Goal**: Improve FTS5 ranking so common foods surface easily (apples, eggs, etc.)
**Depends on**: Phase 35
**Research**: Unlikely (FTS5 optimization, internal)
**Plans**: TBD

Plans:
- [ ] 36-01: TBD

#### Phase 37: Unit/Serving Strategy

**Goal**: Research competitors and implement serving size improvements (1 large egg, 1 medium apple)
**Depends on**: Phase 36
**Research**: Likely (competitive analysis required)
**Research topics**: How other apps handle serving sizes, common consumption units from OFF/USDA data
**Plans**: 1

Plans:
- [x] 37-01: Horizontal pill picker for serving unit selection

#### Phase 38: Bug Fixes & Cleanup

**Goal**: Fix barcode scanner bug, remove API fallback
**Depends on**: Phase 37
**Research**: Unlikely (internal fixes)
**Plans**: 1

Plans:
- [x] 38-01: Fix barcode scanner, remove Open Food Facts API, fix ISS-001

## Progress

**Execution Order:**
Phases execute in numeric order within each milestone.

| Phase                              | Milestone | Plans Complete | Status      | Completed  |
| ---------------------------------- | --------- | -------------- | ----------- | ---------- |
| 35. Search Performance & UX        | v0.8.0    | 1/1            | Complete    | 2026-01-12 |
| 35.1 Header Indicators (INSERTED)  | v0.8.0    | 1/1            | Complete    | 2026-01-12 |
| 36. Search Ranking & Recall        | v0.8.0    | 0/0            | Skipped     | -          |
| 37. Unit/Serving Strategy          | v0.8.0    | 1/1            | Complete    | 2026-01-12 |
| 38. Bug Fixes & Cleanup            | v0.8.0    | 1/1            | Complete    | 2026-01-13 |

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
