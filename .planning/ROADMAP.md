# Roadmap: MacroKinetic

## Overview

MacroKinetic is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management. See [project-prd.md](./project-prd.md) for complete product requirements.

## Domain Expertise

- ~/.claude/skills/ios-dev/SKILL.md

## Milestones

- 🚧 **v0.1.0 Custom Foods** - Phases 1-4 (in progress)

## Phases

### 🚧 v0.1.0 Custom Foods (In Progress)

**Milestone Goal:** Add custom food creation and management to MacroKinetic, enabling users to create personalized foods from existing database entries or from scratch.

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

#### Phase 1: CustomFood Model & Storage
**Goal**: SwiftData model with CloudKit compatibility and CRUD service
**Depends on**: Nothing (first phase)
**Research**: Unlikely (established SwiftData patterns in codebase)
**Plans**: 1 (01-01-PLAN.md)

Key deliverables:
- CustomFood SwiftData model (name, calories, protein, fat, carbs, serving size, serving description, barcode)
- CustomFoodService for CRUD operations
- Integration with ModelContext and CloudKit sync
- Unit tests for model and service

Plans:
- [x] 01-01: CustomFood model and service implementation

#### Phase 2: Create Food UI
**Goal**: CreateFoodSheet for entering custom food details
**Depends on**: Phase 1
**Research**: Unlikely (existing UI patterns from FoodDetailSheet)
**Plans**: 2 (02-01-PLAN.md, 02-02-PLAN.md)

Key deliverables:
- CreateFoodSheet view/sheet
- Pre-fill from Food Details ("To Custom" flow)
- Form validation for required fields
- Two save actions: "Create" and "Create & Add"
- Unit tests for ViewModel

Plans:
- [x] 02-01: CreateFoodSheet UI implementation
- [x] 02-02: ViewModel and validation logic

#### Phase 3: Food Library Integration
**Goal**: Custom foods appear in search and can be managed
**Depends on**: Phase 2
**Research**: Unlikely (extending existing FoodService patterns)
**Plans**: 1 (03-01-PLAN.md)

Key deliverables:
- "My Foods" section in FoodSearchSheet
- Search result prioritization (custom foods first)
- Edit custom food flow from Food Library
- Delete custom food with confirmation
- E2E tests for search integration

Plans:
- [x] 03-01: Search integration and management UI

#### Phase 4: Barcode Assignment
**Goal**: Scan or manually enter barcodes for custom foods
**Depends on**: Phase 3
**Research**: Likely (AVFoundation camera integration)
**Research topics**: AVCaptureSession setup, barcode detection with Vision/AVFoundation, camera permissions, conflict handling
**Plans**: 2 (04-01-PLAN.md, 04-02-PLAN.md)

Key deliverables:
- BarcodeScannerView using AVFoundation
- Barcode-to-custom-food lookup during search
- Conflict resolution for duplicate barcodes
- Camera permission handling

Plans:
- [x] 04-01: Barcode scanner implementation
- [x] 04-02: Barcode assignment and lookup

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. CustomFood Model & Storage | v0.1.0 | 1/1 | Complete | 2025-12-22 |
| 2. Create Food UI | v0.1.0 | 2/2 | Complete | 2025-12-22 |
| 3. Food Library Integration | v0.1.0 | 1/1 | Complete | 2025-12-23 |
| 4. Barcode Assignment | v0.1.0 | 2/2 | Complete | 2025-12-23 |
