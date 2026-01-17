# Project Milestones: MacroKinetic

## v0.9.0 Improvements & Fixes (Shipped: 2026-01-17)

**Delivered:** Analytics accuracy improvements and GLP-1 UX enhancements — day status tracking for fasting days, adjustable dose amounts, fixed steady state calculation (2416% bug), histogram concentration charts, serving unit validation, and correct widget averages.

**Phases completed:** 39-43 (8 plans + 4 FIX plans total)

**Key accomplishments:**

- Day status tracking with fasting toggle and rules for excluding partial/unknown days from TDEE calculations
- Adjustable GLP-1 dose amounts with Stepper control and medication-specific therapeutic bounds
- Fixed steady state progress calculation (2416% bug) by changing API to return decimal (0.0-1.0)
- Concentration chart changed from line to histogram (BarMark) with enhanced accessibility
- Density-based serving unit validation detecting suspicious gram mappings (e.g., "1 cup = 1,300g")
- Fixed energy balance hero widget to use actual day count instead of hardcoded 30
- Fixed next dose schedule calculation to project from last taken dose

**Stats:**

- 140 files modified
- +9,342 / -1,530 lines (net +7,812)
- 5 phases, 8 plans (+4 FIX plans), 108 commits
- 3 days from start to ship (Jan 15-17, 2026)

**Git range:** `feat(39-01)` → `feat(43-02)`

**What's next:** Protein Alerts, Analytics, Subscription, or Recipe Builder

---

## v0.8.0 Food Search & Library (Shipped: 2026-01-13)

**Delivered:** Dramatically improved food search UX with debounce, auto-focus, expanded tap targets, horizontal pill picker for serving units, MacroProgressBar header indicators, and local-only barcode lookup (removed Open Food Facts API).

**Phases completed:** 35-38 (4 plans total, including decimal phase 35.1, phase 36 skipped)

**Key accomplishments:**

- Search UX fixes with debounce, auto-focus, and expanded amount field tap targets
- MacroProgressBar header indicators in Food Search matching Food Log style
- Horizontal pill picker (ServingPillPicker) for serving unit selection (g, oz, item-based)
- Local-only barcode lookup using 1.7M+ food SQLite database
- Removed ALL Open Food Facts API code — fully offline-capable
- Code cleanup: deleted dead FoodSearchView, AddFoodSheet, MealLogView

**Stats:**

- 100+ files modified
- 5 phases (including 1 decimal phase), 4 plans
- 3 days from start to ship (Jan 11-13, 2026)

**Git range:** `feat(35-01)` → `feat(38-01)`

**What's next:** Analytics accuracy improvements and GLP-1 UX enhancements (v0.9.0)

---

## v0.7.0 Dashboard Widget UX (Shipped: 2026-01-12)

**Delivered:** Unified dashboard with widget-based UI featuring hero carousel (Weekly Nutrition, Daily Nutrition, Energy Balance), standard insights grid (4 widgets), detail views with time filtering and Swift Charts, and TDEE history tracking infrastructure.

**Phases completed:** 30-34 (14 plans total, including decimal phase 33.1)

**Key accomplishments:**

- DashboardWidget protocol and container components (WidgetCard, HeroWidgetContainer, StandardWidgetGroup)
- Hero carousel with 3 swipeable widgets using environment-based display mode toggles
- Standard insights grid with 4 widgets (Expenditure, Weight Trend, Energy Balance, Goal Progress)
- Detail views for Weight Trend, Expenditure, and Energy Balance with time period filtering and Swift Charts
- TDEESnapshot model for historical TDEE tracking with daily backfill logic
- Live data wiring with MVVM ViewModels and comprehensive E2E test suite

**Stats:**

- 151 files modified
- +20,324 / -2,173 lines (net +18,151)
- 6 phases (including 1 decimal phase), 14 plans, 296 min execution time (~5 hours)
- 5 days from start to ship (Jan 8-12, 2026)

**Git range:** `feat(30-01)` → `feat(34-04)`

**What's next:** Protein Alerts, Analytics enhancements, Subscription Management, or Recipe Builder

---

## v0.6.0 Onboarding Redux (Shipped: 2026-01-07)

**Delivered:** Complete rewrite of onboarding focused on core experience — USP showcase with mint brand identity, streamlined goal/program setup, permission screens (HealthKit, Face ID, Notifications), and animated completion flow with smooth transition to main app.

**Phases completed:** 25-29 (6 plans total)

**Key accomplishments:**

- Archived legacy GLP-1 onboarding to Legacy/, created new 17-step @Observable OnboardingViewModel with TDD (21+ tests)
- Welcome screen with AppLogo and 4-feature USP carousel (Adaptive TDEE, Precision Tracking, Calorie Adjustments, GLP-1 Support)
- Streamlined GoalSetupStepView and ProgramSetupStepView with GoalProgramService for smart defaults
- Permission screens for HealthKit, Face ID (dynamic biometric detection), and Notifications with enable/skip options
- CompletionStepView with animated checkmark, personalized summary card, and numbered next-steps guidance
- Comprehensive E2E test navigating through all 17 onboarding steps

**Stats:**

- 102 files modified
- +10,098 / -1,583 lines (net +8,515)
- 5 phases, 6 plans, 245 min execution time (~4 hours)
- 3 days from start to ship (Jan 5-7, 2026)

**Git range:** `770d03d` → `e9a156b`

**What's next:** Protein Preservation Alerts, Analytics Dashboard, Subscription Management, or Recipe Builder

---

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
