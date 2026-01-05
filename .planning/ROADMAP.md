# Roadmap: MacroKinetic

## Overview

MacroKinetic is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management. See [project-prd.md](./project-prd.md) for complete product requirements.

## Domain Expertise

- ~/.claude/skills/ios-dev/SKILL.md

## Completed Milestones

- ✅ [v0.5.0 Navigation Refinement](milestones/v0.5.0-ROADMAP.md) (Phases 22-24) - SHIPPED 2026-01-05
- ✅ [v0.4.0 Calorie Expenditure Enhancements](milestones/v0.4.0-ROADMAP.md) (Phases 18-21) - SHIPPED 2026-01-04
- ✅ [v0.3.0 Goals & Nutrition Programs](milestones/v0.3.0-ROADMAP.md) (Phases 12-17) - SHIPPED 2026-01-02
- ✅ [v0.2.0 Enhanced Tracking](milestones/v0.2.0-ROADMAP.md) (Phases 5-11) - SHIPPED 2025-12-27
- ✅ [v0.1.0 Custom Foods](milestones/v0.1.0-ROADMAP.md) (Phases 1-4) - SHIPPED 2025-12-24

## Milestones

- 🚧 **v0.6.0 Onboarding Redux** - Phases 25-29 (in progress)

## Phases

### 🚧 v0.6.0 Onboarding Redux (In Progress)

**Milestone Goal:** Complete rewrite of onboarding focused on core experience — USP showcase, simplified goal/program setup, and permission screens (HealthKit, Face ID, Notifications). Removes GLP-1 and StoreKit aspects for now.

#### Phase 25: Onboarding Foundation

**Goal:** Stash current onboarding, create new coordinator with clean step structure, retain Sign in with Apple
**Depends on:** Previous milestone complete
**Research:** Unlikely (internal refactoring, existing auth patterns)
**Plans:** TBD

Plans:
- [ ] 25-01: TBD (run /gsd:plan-phase 25 to break down)

#### Phase 26: USP Showcase Screens

**Goal:** Feature highlight screens (adaptive TDEE, precision tracking, calorie adjustments, GLP-1 support)
**Depends on:** Phase 25
**Research:** Unlikely (internal UI components)
**Plans:** TBD

Plans:
- [ ] 26-01: TBD

#### Phase 27: Simplified Goal & Program Setup

**Goal:** Streamlined goal/program wizard for first-time users (simpler than Strategy flow)
**Depends on:** Phase 26
**Research:** Unlikely (existing Strategy flow patterns)
**Plans:** TBD

Plans:
- [ ] 27-01: TBD

#### Phase 28: Permission Setup Screens

**Goal:** Individual screens for HealthKit, Face ID, and Notifications with explanations
**Depends on:** Phase 27
**Research:** Unlikely (existing HealthKit, LocalAuth, Notifications patterns)
**Plans:** TBD

Plans:
- [ ] 28-01: TBD

#### Phase 29: Integration & Polish

**Goal:** Final flow integration, transitions, welcome screen, testing
**Depends on:** Phase 28
**Research:** Unlikely (internal polish work)
**Plans:** TBD

Plans:
- [ ] 29-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order within each milestone.

### v0.6.0 Onboarding Redux (Phases 25-29)

| Phase                                | Plans Complete | Status      | Completed |
| ------------------------------------ | -------------- | ----------- | --------- |
| 25. Onboarding Foundation            | 0/?            | Not started | -         |
| 26. USP Showcase Screens             | 0/?            | Not started | -         |
| 27. Simplified Goal & Program Setup  | 0/?            | Not started | -         |
| 28. Permission Setup Screens         | 0/?            | Not started | -         |
| 29. Integration & Polish             | 0/?            | Not started | -         |

<details>
<summary>✅ v0.5.0 Navigation Refinement (Phases 22-24) - SHIPPED 2026-01-05</summary>

| Phase                             | Plans Complete | Status      | Completed  |
| --------------------------------- | -------------- | ----------- | ---------- |
| 22. GLP-1 Programs Consolidation  | 2/2            | Complete    | 2026-01-05 |
| 23. Strategy Tab Promotion        | 1/1            | Complete    | 2026-01-05 |
| 24. Add Button Redesign           | 1/1            | Complete    | 2026-01-05 |

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
