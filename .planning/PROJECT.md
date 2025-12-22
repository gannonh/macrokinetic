---
created: 2025-12-22T15:38:18Z
updated: 2025-12-22T15:38:18Z
---

# Custom Foods

## Vision

Add the ability for users to create and manage custom foods in their personal Food Library. When viewing any food from the database, users can tap "To Custom" to create a personalized version with modified name, macros, and serving information. This solves the common problem of inaccurate database entries, homemade meals, and meal prep foods that don't exist in standard databases.

Custom foods become first-class citizens in the app — appearing prominently in search results and accessible from a dedicated "My Foods" section. Users can assign barcodes to their custom foods, enabling quick scanning of frequently-used products that may have inaccurate or missing database entries.

## Problem

Users frequently encounter foods that:
- Have inaccurate macro information in the database
- Don't exist in the database (homemade meals, meal prep, local products)
- Need personalized serving sizes (e.g., "my usual protein shake")
- Are packaged products with barcodes but poor database coverage

Currently, users must search for the closest match each time and mentally adjust the macros. There's no way to save a corrected or custom food for reuse.

## Success Criteria

How we know this worked:

- [ ] "To Custom" button on Food Details opens Create Food view pre-filled with current food data
- [ ] Users can edit all fields: name, calories, protein, fat, carbs, serving size, serving description
- [ ] Two save actions: "Create" (save to library) and "Create & Add" (save + add to current meal)
- [ ] Custom foods appear in dedicated "My Foods" section in search UI
- [ ] Custom foods prioritized at top of general search results
- [ ] Full edit capability for existing custom foods from Food Library
- [ ] Delete custom food capability
- [ ] Barcode assignment via camera scan or manual entry
- [ ] Custom foods sync across devices via CloudKit
- [ ] Works fully offline, syncs when connection available

## Scope

### Building
- Create Food view/sheet pre-filled from Food Details
- CustomFood SwiftData model with CloudKit compatibility
- Food Library storage and retrieval service
- "My Foods" section in FoodSearchSheet
- Search result prioritization logic for custom foods
- Edit custom food flow
- Delete custom food with confirmation
- Barcode scanner (AVFoundation camera integration)
- Manual barcode entry field
- Barcode-to-custom-food lookup during search

### Not Building
- Recipe builder (combining multiple foods into calculated recipe)
- Sharing custom foods with other users
- Importing custom foods from external sources
- Nutritional analysis beyond basic macros (micronutrients, etc.)

## Context

**Current State:** Brownfield — MacroKinetic has complete food database infrastructure (1.7M+ foods), meal logging UI, and FoodDetailSheet. The "To Custom" button exists in the UI but is not yet functional.

**Existing Architecture:**
- `Food` model for database foods (SQLite FTS5)
- `FoodEntry` model for logged meals (SwiftData + CloudKit)
- `FoodService` orchestrates search across sources
- `LocalFoodDatabase` handles SQLite queries
- `FoodDetailSheet` displays food and handles logging

**Integration Points:**
- FoodDetailSheet: Add "To Custom" action
- FoodSearchSheet: Add "My Foods" section, prioritize custom in results
- FoodService: Extend to search custom foods
- New: CustomFood model, CustomFoodService, CreateFoodSheet

## Constraints

- **CloudKit Sync**: Custom foods must sync across user's devices via iCloud, following existing SwiftData + CloudKit patterns
- **Offline-First**: Full functionality without network; sync when available
- **Existing Patterns**: Must follow MVVM architecture, @Observable ViewModels, service layer conventions
- **iOS 17+**: Use modern SwiftUI and SwiftData APIs

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Data Model | New `CustomFood` SwiftData model | Separates custom foods from bundled database, enables CloudKit sync |
| Create Flow | Modal sheet or push nav | Flexibility based on UX feel during implementation |
| Save Actions | "Create" + "Create & Add" | Supports both "save for later" and "save and log now" workflows |
| Barcode Assignment | Scan + Manual Entry | Camera for convenience, manual as fallback |
| Search Priority | Custom foods first | Users' own foods should surface before generic database matches |

## Open Questions

Things to figure out during execution:

- [ ] Should CustomFood have a `sourceFood` reference linking to original database food?
- [ ] UX for barcode conflicts (custom food vs database food with same barcode)
- [ ] Maximum number of custom foods? (Probably unlimited, but worth considering)
- [ ] Should "My Foods" section be collapsible/expandable in search?

---
*Initialized: 2025-12-22*
