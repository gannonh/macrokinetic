# Roadmap: MacroKinetic

## Overview

MacroKinetic is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management. See [project-prd.md](./project-prd.md) for complete product requirements.

## Domain Expertise

- ~/.claude/skills/ios-dev/SKILL.md

## Completed Milestones

- ✅ [v0.4.0 Calorie Expenditure Enhancements](milestones/v0.4.0-ROADMAP.md) (Phases 18-21) - SHIPPED 2026-01-04
- ✅ [v0.3.0 Goals & Nutrition Programs](milestones/v0.3.0-ROADMAP.md) (Phases 12-17) - SHIPPED 2026-01-02
- ✅ [v0.2.0 Enhanced Tracking](milestones/v0.2.0-ROADMAP.md) (Phases 5-11) - SHIPPED 2025-12-27
- ✅ [v0.1.0 Custom Foods](milestones/v0.1.0-ROADMAP.md) (Phases 1-4) - SHIPPED 2025-12-24

## Milestones

- 🚧 **v0.5.0 Navigation Refinement** - Phases 22-24 (in progress)

## Phases

### 🚧 v0.5.0 Navigation Refinement (In Progress)

**Milestone Goal:** Streamline navigation by consolidating GLP-1 features under More, promoting Strategy to a top-level tab, and modernizing the Add button.

#### Phase 22: GLP-1 Programs Consolidation

**Goal**: Merge Shots tab and Medication Profiles into unified "GLP-1 Programs" section under More tab
**Depends on**: Previous milestone complete
**Research**: Unlikely (internal UI patterns, existing views)
**Plans**: 2

Plans:
- [x] 22-01: Section Extraction & ShotsView Refactor (3 tasks) - Complete 2026-01-05
- [x] 22-02: GLP1ProgramsView & Integration (3 tasks) - Complete 2026-01-05

#### Phase 23: Strategy Tab Promotion

**Goal**: Replace Shots tab with Strategy in tab bar, uplevel Goals & Strategy to Dashboard-style prominence
**Depends on**: Phase 22
**Research**: Unlikely (internal patterns, following Dashboard precedent)
**Plans**: 1

Plans:
- [x] 23-01: Strategy Tab Promotion (3 tasks) - Complete 2026-01-05

#### Phase 24: Add Button Redesign

**Goal**: Icon-only, larger Add button with no text label, same ShortcutsSheet behavior
**Depends on**: Phase 23
**Research**: Unlikely (simple styling change)
**Plans**: TBD

Plans:
- [ ] 24-01: TBD (run /gsd:plan-phase 24 to break down)

## Progress

**Execution Order:**
Phases execute in numeric order within each milestone.

| Phase                             | Plans Complete | Status      | Completed  |
| --------------------------------- | -------------- | ----------- | ---------- |
| 22. GLP-1 Programs Consolidation  | 2/2            | Complete    | 2026-01-05 |
| 23. Strategy Tab Promotion        | 1/1            | Complete    | 2026-01-05 |
| 24. Add Button Redesign           | 0/?            | Not started | -          |

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
