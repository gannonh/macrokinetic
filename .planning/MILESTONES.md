# Project Milestones: MacroKinetic

## v0.2.0 Enhanced Tracking (Shipped: 2025-12-27)

**Delivered:** Enhanced daily tracking with week calendar navigation, food library management, quick macro entry, weight tracking with HealthKit sync, body metrics with progress photos, and feature settings for metrics visibility and units of measure.

**Phases completed:** 5-11 (11 plans total)

**Key accomplishments:**

- Week calendar navigation in Food Log with day selection updating macro summary
- Tap-to-edit food entries with FoodDetailSheet reuse
- Dedicated Food Library screen with Foods tab, sort options, and Your Foods shortcut
- Quick Add macro entry without food lookup via FoodSearchSheet tab
- Weight and body fat tracking with HealthKit sync and unit conversion
- Body metrics (waist, chest, hips, etc.) with configurable visibility and HealthKit sync
- Progress photo capture with camera/library support and photo type configuration
- Feature settings for body metrics visibility toggles and units of measure

**Stats:**

- 127 files created/modified
- +18,659 / -3,032 lines (net +15,627)
- 7 phases, 11 plans, ~4.25 hours execution time
- 4 days from start to ship (Dec 24-27, 2025)

**Git range:** `feat(05-01)` → `feat(11-02)`

**What's next:** Macro Goals & Daily Tracking, Protein Preservation Alerts, or Analytics Dashboard

---

## v0.1.0 Custom Foods (Shipped: 2025-12-24)

**Delivered:** Custom food creation and management with barcode scanning, enabling users to create personalized foods and quickly look them up by scanning product barcodes.

**Phases completed:** 1-4 (6 plans total)

**Key accomplishments:**

- CustomFoodService with full CRUD, validation, barcode uniqueness, and CloudKit sync
- CreateFoodSheet UI with "To Custom" prefill flow and "Create & Add" save-and-log action
- "My Foods" section in search with swipe-to-edit/delete and custom food prioritization
- Barcode scanner using AVFoundation with debouncing, haptic feedback, and ShortcutsSheet integration
- Comprehensive testing with 31+ unit tests and E2E test stubs for all flows
- Full offline support with custom foods persisted locally and synced via CloudKit

**Stats:**

- 71 files created/modified
- ~41,000 lines of Swift
- 4 phases, 6 plans, ~40 minutes execution time
- 3 days from start to ship (Dec 22-24, 2025)

**Git range:** `feat(01-01)` → `feat(04-02)`

**What's next:** Macro Goals & Daily Tracking, Protein Preservation Alerts, or HealthKit Integration

---
