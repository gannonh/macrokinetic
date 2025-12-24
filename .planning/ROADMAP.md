# Roadmap: MacroKinetic

## Overview

MacroKinetic is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management. See [project-prd.md](./project-prd.md) for complete product requirements.

## Domain Expertise

- ~/.claude/skills/ios-dev/SKILL.md

## Completed Milestones

- [v0.1.0 Custom Foods](milestones/v0.1.0-ROADMAP.md) (Phases 1-4) - SHIPPED 2025-12-24

## Milestones

- 🚧 **v0.2.0 Enhanced Tracking** - Phases 5-10 (in progress)

## Phases

### 🚧 v0.2.0 Enhanced Tracking (In Progress)

**Milestone Goal:** Enhanced daily tracking with calendar navigation, food library management, quick macro entry, weight tracking with HealthKit, and body metrics with progress photos.

#### Phase 5: Food Log Calendar

**Goal**: Week calendar navigation with day selection updating macro summary
**Depends on**: Previous milestone complete
**Research**: Unlikely (SwiftUI calendar patterns)
**Plans**: TBD

Plans:
- [ ] 05-01: TBD (run /gsd:plan-phase 5 to break down)

#### Phase 6: Food Entry Editing

**Goal**: Tap food entry to open editable FoodDetailSheet
**Depends on**: Phase 5
**Research**: Unlikely (reusing existing FoodDetailSheet)
**Plans**: TBD

Plans:
- [ ] 06-01: TBD

#### Phase 7: Food Library

**Goal**: Dedicated Food Library screen with Foods tab, sort options, tap-to-add
**Depends on**: Phase 6
**Research**: Unlikely (internal UI patterns)
**Plans**: TBD

Plans:
- [ ] 07-01: TBD

#### Phase 8: Quick Add

**Goal**: Macro-only food logging without food lookup
**Depends on**: Phase 7
**Research**: Unlikely (simple form + existing logging service)
**Plans**: TBD

Plans:
- [ ] 08-01: TBD

#### Phase 9: Weight Tracking

**Goal**: Weight and body fat entry with HealthKit sync
**Depends on**: Phase 8
**Research**: Likely (HealthKit integration)
**Research topics**: HealthKit authorization, reading/writing weight and body fat data
**Plans**: TBD

Plans:
- [ ] 09-01: TBD

#### Phase 10: Metrics & Photos

**Goal**: Configurable body metrics with progress photo capture
**Depends on**: Phase 9
**Research**: Likely (photo capture/storage)
**Research topics**: Photo capture API, image storage patterns, configurable metrics settings
**Plans**: TBD

Plans:
- [ ] 10-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order within each milestone.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. CustomFood Model & Storage | v0.1.0 | 1/1 | Complete | 2025-12-22 |
| 2. Create Food UI | v0.1.0 | 2/2 | Complete | 2025-12-22 |
| 3. Food Library Integration | v0.1.0 | 1/1 | Complete | 2025-12-23 |
| 4. Barcode Assignment | v0.1.0 | 2/2 | Complete | 2025-12-23 |
| 5. Food Log Calendar | v0.2.0 | 0/? | Not started | - |
| 6. Food Entry Editing | v0.2.0 | 0/? | Not started | - |
| 7. Food Library | v0.2.0 | 0/? | Not started | - |
| 8. Quick Add | v0.2.0 | 0/? | Not started | - |
| 9. Weight Tracking | v0.2.0 | 0/? | Not started | - |
| 10. Metrics & Photos | v0.2.0 | 0/? | Not started | - |
