# Roadmap: Custom Foods

## Overview

Enable users to create and manage custom foods in their personal Food Library. Starting with the data foundation (CustomFood model with CloudKit sync), we build the creation UI with "To Custom" integration, extend search to prioritize user foods, and finally add barcode assignment via camera scanning.

## Domain Expertise

None

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Data Layer Foundation** - CustomFood model with CloudKit sync, CustomFoodService for CRUD
- [ ] **Phase 2: Create Food Flow** - CreateFoodSheet UI, "To Custom" button, save actions
- [ ] **Phase 3: Search Integration** - "My Foods" section, search prioritization, edit/delete
- [ ] **Phase 4: Barcode Assignment** - Camera scanner, manual entry, barcode lookup

## Phase Details

### Phase 1: Data Layer Foundation
**Goal**: Establish CustomFood SwiftData model with CloudKit compatibility and service layer for CRUD operations
**Depends on**: Nothing (first phase)
**Research**: Unlikely (follows existing SwiftData + CloudKit patterns)
**Plans**: TBD

Key deliverables:
- CustomFood SwiftData model with all required fields
- CloudKit sync compatibility (non-optional defaults, proper relationships)
- CustomFoodService for create, read, update, delete operations
- Unit tests for model and service

### Phase 2: Create Food Flow
**Goal**: Enable users to create custom foods from existing foods or from scratch
**Depends on**: Phase 1
**Research**: Unlikely (internal UI patterns)
**Plans**: TBD

Key deliverables:
- CreateFoodSheet (modal) with form fields: name, calories, protein, fat, carbs, serving size, serving description
- Pre-fill from existing Food when accessed via "To Custom" button
- Two save actions: "Create" (save to library) and "Create & Add" (save + log to current meal)
- Integration with FoodDetailSheet "To Custom" button
- Form validation

### Phase 3: Search Integration
**Goal**: Surface custom foods prominently in search and enable management
**Depends on**: Phase 2
**Research**: Unlikely (extending existing FoodService patterns)
**Plans**: TBD

Key deliverables:
- "My Foods" section in FoodSearchSheet (dedicated expandable section)
- Custom foods prioritized at top of general search results
- Edit custom food flow (EditFoodSheet or reuse CreateFoodSheet)
- Delete custom food with confirmation dialog
- FoodService extension to search custom foods

### Phase 4: Barcode Assignment
**Goal**: Allow users to assign barcodes to custom foods for quick scanning
**Depends on**: Phase 3
**Research**: Likely (AVFoundation camera integration)
**Research topics**: AVCaptureSession setup, barcode detection (AVMetadataObject), camera permissions (NSCameraUsageDescription), supported barcode formats (UPC-A, UPC-E, EAN-8, EAN-13)
**Plans**: TBD

Key deliverables:
- BarcodeScannerView using AVFoundation
- Camera permission request and handling
- Manual barcode entry field as fallback
- Barcode-to-CustomFood lookup in search/scan flow
- Handle barcode conflicts (custom vs database food)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Data Layer Foundation | 0/TBD | Not started | - |
| 2. Create Food Flow | 0/TBD | Not started | - |
| 3. Search Integration | 0/TBD | Not started | - |
| 4. Barcode Assignment | 0/TBD | Not started | - |
