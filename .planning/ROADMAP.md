# Roadmap: Custom Foods

## Overview

Add custom food creation and management to MacroKinetic, enabling users to create personalized foods from existing database entries or from scratch. The feature progresses from data foundation through UI, search integration, and finally barcode scanning for quick access.

## Domain Expertise

- ~/.claude/skills/ios-dev/SKILL.md

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: CustomFood Model & Storage** - Data model and service layer for custom foods
- [x] **Phase 2: Create Food UI** - Form for creating and editing custom foods (2/2 plans complete)
- [x] **Phase 3: Food Library Integration** - Search integration and management UI (1/1 plans complete)
- [ ] **Phase 4: Barcode Assignment** - Camera scanning and manual barcode entry

## Phase Details

### Phase 1: CustomFood Model & Storage
**Goal**: SwiftData model with CloudKit compatibility and CRUD service
**Depends on**: Nothing (first phase)
**Research**: Unlikely (established SwiftData patterns in codebase)
**Plans**: 1 (01-01-PLAN.md)

Key deliverables:
- CustomFood SwiftData model (name, calories, protein, fat, carbs, serving size, serving description, barcode)
- CustomFoodService for CRUD operations
- Integration with ModelContext and CloudKit sync
- Unit tests for model and service

### Phase 2: Create Food UI
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

### Phase 3: Food Library Integration
**Goal**: Custom foods appear in search and can be managed
**Depends on**: Phase 2
**Research**: Unlikely (extending existing FoodService patterns)
**Plans**: TBD

Key deliverables:
- "My Foods" section in FoodSearchSheet
- Search result prioritization (custom foods first)
- Edit custom food flow from Food Library
- Delete custom food with confirmation
- E2E tests for search integration

### Phase 4: Barcode Assignment
**Goal**: Scan or manually enter barcodes for custom foods
**Depends on**: Phase 3
**Research**: Likely (AVFoundation camera integration)
**Research topics**: AVCaptureSession setup, barcode detection with Vision/AVFoundation, camera permissions, conflict handling
**Plans**: TBD

Key deliverables:
- BarcodeScannerView using AVFoundation
- Manual barcode entry field
- Barcode-to-custom-food lookup during search
- Conflict resolution for duplicate barcodes
- Camera permission handling

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. CustomFood Model & Storage | 1/1 | Complete | 2025-12-22 |
| 2. Create Food UI | 2/2 | Complete | 2025-12-22 |
| 3. Food Library Integration | 1/1 | Complete | 2025-12-23 |
| 4. Barcode Assignment | 0/TBD | Not started | - |
