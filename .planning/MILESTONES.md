# Project Milestones: MacroKinetic

## v0.5.0 Navigation Refinement (Shipped: 2026-01-05)

**Delivered:** Streamlined navigation by consolidating GLP-1 features under More tab, promoting Strategy to a top-level tab with check-in badge, and modernizing the Add button with a floating 44pt icon-only design.

**Phases completed:** 22-24 (4 plans total)

**Key accomplishments:**

- Extracted reusable section components (ConcentrationSection, AdherenceSection, HistorySection) from ShotsView with full TDD coverage (10 tests)
- Created unified GLP1ProgramsView consolidating GLP-1 analytics and medication management under More tab
- Promoted Strategy to top-level tab with target icon and weekly check-in badge indicator
- Replaced Add tab item with floating 44pt icon-only button overlay for visual prominence
- Standardized navigation bar styling (inline titles, circle buttons) across app

**Stats:**

- 52 files modified
- +3,285 / -436 lines (net +2,849)
- 3 phases, 4 plans, 80 min execution time
- 2 days from start to ship (Jan 4-5, 2026)

**Git range:** `feat(22-01)` → `feat(24-01)`

**What's next:** Protein Preservation Alerts, Analytics Dashboard, Subscription Management, or Recipe Builder

---

## v0.4.0 Calorie Expenditure Enhancements (Shipped: 2026-01-04)

**Delivered:** Enhanced calorie targets with real-time burned calories from HealthKit, rollover unused calories to next day, and predictive activity adjustments based on 7-day historical trends with goal-type multipliers.

**Phases completed:** 18-21 (4 plans total)

**Key accomplishments:**

- Real-time burned calories from HealthKit added back to daily calorie targets with flame indicator
- Rollover calories feature carrying up to 200 unused calories from yesterday to today
- Predictive activity adjustment using 7-day average with goal-type multipliers (0.8/1.0/1.2)
- CalorieAdjustmentService pipeline with extensible provider architecture
- Calorie breakdown UI showing burned/rollover/predictive adjustments in FoodLogView
- 13 E2E tests for burned calories feature validation and toggle behavior

**Stats:**

- 85 files modified
- +8,945 / -1,610 lines (net +7,335)
- 4 phases, 4 plans, 56 min execution time
- 2 days from start to ship (Jan 3-4, 2026)

**Git range:** `feat(18-01)` → `feat(21-01)`

**What's next:** Protein Preservation Alerts, Analytics Dashboard, or Recipe Builder

---

## v0.3.0 Goals & Nutrition Programs (Shipped: 2026-01-02)

**Delivered:** Goal-based nutrition tracking with customizable programs, adaptive TDEE engine, weekly check-ins, and refined settings experience.

**Phases completed:** 12-17 (20 plans total, including decimal phases 15.1 and 15.2)

**Key accomplishments:**

- NutritionGoal and NutritionProgram data models with User integration
- Separate Goal and Program wizards with Strategy view entry points
- Three program styles: Coached (auto-calculated), Collaborative (per-day editing), Manual (user-defined)
- Adaptive TDEE engine with Mifflin-St Jeor BMR and EWMA weight smoothing
- HealthKit biometrics integration for height, weight, sex, DOB
- Daily progress rings for NutritionSummaryCard with color thresholds
- Weekly check-ins with ProgramOptimizationSheet for goal/program adjustments
- More tab refinements with Security & Privacy, Notifications, and placeholder screens

**Stats:**

- 160 files modified
- +28,655 / -8,034 lines (net +20,621)
- 8 phases (including 2 decimal phases), 20 plans
- 7 days from start to ship (Dec 27, 2025 - Jan 2, 2026)

**Git range:** `feat(12-01)` → `feat(17-03)`

**What's next:** Calorie Expenditure Enhancements (v0.4.0)

---

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
