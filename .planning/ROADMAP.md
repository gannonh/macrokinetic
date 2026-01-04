# Roadmap: MacroKinetic

## Overview

MacroKinetic is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management. See [project-prd.md](./project-prd.md) for complete product requirements.

## Domain Expertise

- ~/.claude/skills/ios-dev/SKILL.md

## Completed Milestones

- ✅ [v0.3.0 Goals & Nutrition Programs](milestones/v0.3.0-ROADMAP.md) (Phases 12-17) - SHIPPED 2026-01-02
- ✅ [v0.2.0 Enhanced Tracking](milestones/v0.2.0-ROADMAP.md) (Phases 5-11) - SHIPPED 2025-12-27
- ✅ [v0.1.0 Custom Foods](milestones/v0.1.0-ROADMAP.md) (Phases 1-4) - SHIPPED 2025-12-24

## Milestones

- 🚧 **v0.4.0 Calorie Expenditure Enhancements** - Phases 18-21 (in progress)

## Phases

### 🚧 v0.4.0 Calorie Expenditure Enhancements (In Progress)

**Milestone Goal:** Enhance calorie targets with real-time burned calories from HealthKit, rollover unused calories, and predictive activity adjustments based on historical trends. These features are user enabled from More > Calorie Expenditure settings (mock: /Users/gannonhall/Desktop/Simulator Screenshot - iPhone 17 Pro - 2026-01-03 at 10.39.23.png)

#### Phase 18: Complete Add Burned Calories

**Goal:** Validate work completed thus far and create E2E tests for Add Burned Calories feature (HealthKit integration and service layer already done)
**Depends on:** Previous milestone complete
**Research:** Unlikely (E2E patterns established)
**Plans:** TBD

Plans:
- [x] 18-01: Add Burned Calories E2E Tests (3 tasks)

#### Phase 19: Rollover Calories

**Goal:** Carry up to 200 unused calories from yesterday to today with CalorieAdjustmentService integration
**Depends on:** Phase 18
**Research:** Unlikely (internal calculation patterns)
**Plans:** TBD

Plans:
- [x] 19-01: Rollover Calories Implementation (4 tasks)

#### Phase 20: Predictive Activity Adjustment

**Goal:** Apply 7-day activity average with goal-mode multipliers (0.8/1.0/1.2) during weekly check-in
**Depends on:** Phase 19
**Research:** Unlikely (existing WeeklyCheckInService integration)
**Plans:** TBD

Plans:
- [x] 20-01: Predictive Activity Provider (3 tasks)

#### Phase 21: Integration & Polish

**Goal:** Final integration testing, edge case handling, and UI polish for all calorie expenditure features
**Depends on:** Phase 20
**Research:** Unlikely (internal patterns)
**Plans:** TBD

Plans:
- [ ] 21-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order within each milestone.

| Phase                              | Milestone | Plans Complete | Status      | Completed  |
| ---------------------------------- | --------- | -------------- | ----------- | ---------- |
| 18. Complete Add Burned Calories   | v0.4.0    | 1/1            | Complete    | 2026-01-03 |
| 19. Rollover Calories              | v0.4.0    | 1/1            | Complete    | 2026-01-03 |
| 20. Predictive Activity Adjustment | v0.4.0    | 1/1            | Complete    | 2026-01-03 |
| 21. Integration & Polish           | v0.4.0    | 0/?            | Not started | -          |

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
