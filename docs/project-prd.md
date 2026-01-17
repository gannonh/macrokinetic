---
created: 2024-01-15T00:00:00Z
updated: 2026-01-07T22:20:31Z
---

# MacroKinetic Product Requirements Document

## Overview

MacroKinetic is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management.

**Target Users:**
- Primary: Anyone on a weight loss or nutrition journey
- Secondary: GLP-1 medication users wanting medication + nutrition integration

**Tech Stack:** iOS 17+, Swift/SwiftUI, SwiftData, CloudKit, SQLite FTS5

---

## Feature Status Legend

| Status | Meaning     |
| ------ | ----------- |
| ✅      | Done        |
| 🔨      | In Progress |
| 📋      | Planned     |

---

## Features (Sequenced)

### ✅ Authentication

Secure user authentication using Apple's native authentication services, providing seamless sign-in and biometric protection for app access.

#### Requirements

- [x] Sign in with Apple
- [x] Face ID/Touch ID for app access
- [x] Keychain credential storage
- [x] Persistent session state

#### User Stories

##### Sign In
- **As a user**, I want to sign in with my Apple ID, so that I don't need to create a new account.
- **As a user**, I want my session to persist, so that I don't have to sign in every time I open the app.

##### Security
- **As a user**, I want to unlock the app with Face ID, so that my health data stays private.
- **As a user**, I want my credentials stored securely, so that I don't worry about data breaches.

#### Key Design Decisions

1. **Apple-only authentication** - Simplifies onboarding and leverages existing Apple ID trust.
2. **Biometric gating** - Optional but recommended for health data privacy.
3. **Keychain storage** - System-level security for credential persistence.

#### Acceptance Criteria

- [x] User can sign in with Apple ID
- [x] Face ID/Touch ID unlocks app when enabled
- [x] Session persists across app restarts
- [x] Credentials stored in Keychain

---

### ✅ User Onboarding (Medication Path)

Guided onboarding flow for GLP-1 medication users, collecting medication type, initial dose, and schedule preferences.

#### Requirements

- [x] Welcome screens with app benefits
- [x] Medication selection wizard (4 GLP-1 meds)
- [x] Initial dose entry with injection site
- [x] Schedule setup (weekly, split-dose, custom)
- [x] Notification permissions
- [x] Subscription screen placeholder

#### User Stories

##### Discovery
- **As a new user**, I want to understand what the app does, so that I know if it's right for me.
- **As a user**, I want to select my medication, so that the app can provide accurate tracking.

##### Setup
- **As a user**, I want to enter my current dose, so that tracking starts from my actual regimen.
- **As a user**, I want to set my injection schedule, so that I receive timely reminders.

#### Key Design Decisions

1. **4 GLP-1 medications supported** - Covers Ozempic, Wegovy, Mounjaro, and Zepbound.
2. **Flexible scheduling** - Weekly, split-dose, and custom patterns.
3. **Site rotation tracking** - Prevents injection site complications.

#### Acceptance Criteria

- [x] User completes onboarding in under 3 minutes
- [x] All 4 GLP-1 medications selectable
- [x] Schedule configured with preferred day/time
- [x] Notification permissions requested

---

### ✅ Medication Profile Management

CRUD operations for medication profiles with brand-specific dose validation, titration tracking, and reconstitution support.

#### Requirements

- [x] CRUD for medication profiles
- [x] Support 4 GLP-1 medications with brand variants
- [x] Brand-aware dose validation
- [x] Dose escalation (titration) tracking
- [x] Reconstitution calculator for compounded meds
- [x] Injection site preferences

#### User Stories

##### Profile Management
- **As a user**, I want to add multiple medications, so that I can track combination therapies.
- **As a user**, I want to edit my medication details, so that I can update when my prescription changes.

##### Titration
- **As a user**, I want to track dose escalation, so that I know when to increase my dose.
- **As a user**, I want validation for my dose, so that I don't accidentally enter an incorrect amount.

##### Compounding
- **As a user**, I want to calculate reconstitution, so that I mix my compounded medication correctly.

#### Key Design Decisions

1. **Brand-aware validation** - Different brands have different dose ranges.
2. **Titration schedules** - Automatic escalation tracking based on FDA guidelines.
3. **Reconstitution calculator** - For users with compounded medications.

#### Acceptance Criteria

- [x] User can create/edit/delete medication profiles
- [x] Dose validation prevents out-of-range entries
- [x] Titration progress visible and trackable
- [x] Reconstitution calculator accurate for all concentrations

---

### ✅ Dose Tracking

Core dose logging functionality with quick entry, manual override, calendar visualization, and statistical insights.

#### Requirements

- [x] Quick dose entry via "+" tab button
- [x] Manual entry with date/time, amount, site, notes
- [x] Calendar view with dose indicators
- [x] List view with search and filtering
- [x] Edit/delete past entries
- [x] Statistics (adherence rates, streaks)

#### User Stories

##### Logging
- **As a user**, I want to log my dose quickly, so that I can record it right after injection.
- **As a user**, I want to add notes, so that I can track side effects or observations.

##### History
- **As a user**, I want to see my dose history on a calendar, so that I can visualize my adherence.
- **As a user**, I want to search past doses, so that I can find specific entries.

##### Insights
- **As a user**, I want to see my adherence rate, so that I know how consistent I've been.
- **As a user**, I want to track my streak, so that I stay motivated.

#### Key Design Decisions

1. **Quick entry prioritized** - One-tap logging for most common use case.
2. **Dual view modes** - Calendar for patterns, list for details.
3. **Site rotation enforcement** - Prompts for balanced site usage.

#### Acceptance Criteria

- [x] Dose logged in under 5 seconds via quick entry
- [x] Calendar shows dose indicators on logged days
- [x] Adherence percentage calculated correctly
- [x] Past entries editable and deletable

---

### ✅ Pharmacokinetics Engine

Mathematical modeling of GLP-1 medication concentration using exponential decay, providing real-time level calculations and steady-state tracking.

#### Requirements

- [x] Exponential decay concentration modeling
- [x] Medication-specific half-life values
- [x] Peak, trough, and current level calculations
- [x] Steady-state progress tracking
- [x] ConcentrationCard dashboard display

#### User Stories

##### Understanding Levels
- **As a user**, I want to see my current medication level, so that I understand why I feel a certain way.
- **As a user**, I want to know my peak and trough, so that I can plan activities accordingly.

##### Steady State
- **As a user**, I want to track progress to steady state, so that I know when my medication reaches full effect.

#### Key Design Decisions

1. **True exponential decay** - Accurate pharmacokinetic modeling vs. simple estimates.
2. **Medication-specific half-lives** - Semaglutide (7 days), Tirzepatide (5 days).
3. **Visual concentration curve** - Easy-to-understand dashboard display.

#### Acceptance Criteria

- [x] Concentration calculated using correct half-life for each medication
- [x] Peak, trough, and current levels displayed accurately
- [x] Steady-state progress shown as percentage
- [x] Dashboard card updates in real-time

---

### ✅ Dose Scheduling

Flexible scheduling system supporting weekly, split-dose, and custom patterns with pause/resume and modification history.

#### Requirements

- [x] Schedule creation (weekly, split-dose, custom)
- [x] Upcoming dose projections
- [x] Pause/resume schedules
- [x] Modification history
- [x] Titration completion workflow

#### User Stories

##### Scheduling
- **As a user**, I want to set a weekly schedule, so that I inject on the same day each week.
- **As a user**, I want to see upcoming doses, so that I can plan ahead.

##### Flexibility
- **As a user**, I want to pause my schedule, so that I can handle medication breaks.
- **As a user**, I want to see schedule history, so that I can track changes over time.

#### Key Design Decisions

1. **Multiple schedule types** - Supports various dosing regimens.
2. **Projection engine** - Shows future doses for planning.
3. **Non-destructive history** - Modifications tracked, not overwritten.

#### Acceptance Criteria

- [x] Weekly schedule creates correct recurring doses
- [x] Split-dose schedules supported
- [x] Pause/resume preserves schedule state
- [x] Modification history queryable

---

### ✅ Notifications (Medication)

Comprehensive notification system for dose reminders, titration alerts, and missed dose handling with actionable responses.

#### Requirements

- [x] Scheduled dose reminders
- [x] Titration completion alerts
- [x] Missed dose notifications
- [x] Badge management
- [x] Deep linking to entry screens
- [x] Action handling (log, snooze, skip)

#### User Stories

##### Reminders
- **As a user**, I want dose reminders, so that I don't forget to inject.
- **As a user**, I want to snooze reminders, so that I can delay if I'm busy.

##### Actions
- **As a user**, I want to log directly from the notification, so that I don't need to open the app.
- **As a user**, I want missed dose alerts, so that I know if I forgot.

#### Key Design Decisions

1. **Actionable notifications** - Log, snooze, skip from notification.
2. **iOS 64-notification limit** - Rolling window management.
3. **Deep linking** - Notification opens relevant screen.

#### Acceptance Criteria

- [x] Reminders fire at scheduled times
- [x] Notification actions work correctly
- [x] Deep links navigate to correct screens
- [x] Badge count reflects pending doses

---

### ✅ Analytics (Medication)

Interactive analytics dashboard with concentration timeline charts, dose markers, future projections, and adherence insights.

#### Requirements

- [x] Concentration timeline chart (interactive)
- [x] Time period selection (7d, 30d, 90d, 1y)
- [x] Dose markers on timeline
- [x] Future projections
- [x] Adherence insights
- [x] Streak tracking

#### User Stories

##### Visualization
- **As a user**, I want to see my concentration over time, so that I understand medication patterns.
- **As a user**, I want to select different time periods, so that I can zoom in or out.

##### Insights
- **As a user**, I want adherence insights, so that I can improve my consistency.
- **As a user**, I want to see future projections, so that I can anticipate levels.

#### Key Design Decisions

1. **Swift Charts integration** - Native, performant charting.
2. **Interactive markers** - Tap dose points for details.
3. **Projection curves** - Dashed lines for future estimates.

#### Acceptance Criteria

- [x] Chart renders within 500ms for 365 data points
- [x] Time period selection updates chart
- [x] Dose markers show on chart
- [x] Projections extend beyond current date

---

### ✅ CloudKit Sync

Automatic iCloud synchronization with real-time status monitoring, offline-first architecture, and multi-device support.

#### Requirements

- [x] Automatic iCloud synchronization
- [x] Real-time sync status monitoring
- [x] Graceful offline-first fallback
- [x] Multi-device support

#### User Stories

##### Sync
- **As a user**, I want my data synced to iCloud, so that I don't lose it if I change phones.
- **As a user**, I want to see sync status, so that I know if my data is current.

##### Multi-Device
- **As a user**, I want to access my data on multiple devices, so that I can log from anywhere.

#### Key Design Decisions

1. **SwiftData + CloudKit** - Native Apple sync solution.
2. **Offline-first** - App works without connectivity.
3. **Conflict resolution** - Last-write-wins with merge support.

#### Acceptance Criteria

- [x] Data syncs within 30 seconds of change
- [x] Sync status indicator accurate
- [x] App functions fully offline
- [x] Multi-device changes merge correctly

---

### ✅ Food Database Infrastructure

Issue: [#314](https://github.com/gannonh/jab-tracker-ios/issues/314)

Comprehensive food database with 1.7M+ foods from USDA and Open Food Facts, featuring SQLite FTS5 full-text search and barcode lookup.

#### Requirements

- [x] Food and FoodEntry SwiftData models
- [x] 1.7M+ foods from USDA + Open Food Facts
- [x] SQLite FTS5 full-text search
- [x] Barcode column with index
- [x] Offline-first (entire database bundled)
- [x] FoodService orchestrating search
- [x] LocalFoodDatabase service
- [x] OpenFoodFactsService API client
- [x] MealLogService for CRUD

#### User Stories

##### Search
- **As a user**, I want to search for any food, so that I can log what I eat.
- **As a user**, I want fast search results, so that logging doesn't slow me down.

##### Offline
- **As a user**, I want to search without internet, so that I can log anywhere.

#### Key Design Decisions

1. **Bundled database** - 382MB SQLite for offline-first.
2. **FTS5 full-text search** - Sub-100ms query performance.
3. **Hybrid search** - Local first, API fallback.

#### Acceptance Criteria

- [x] Search returns results in under 100ms
- [x] 1.7M+ foods searchable
- [x] Barcode lookup works offline (local DB)
- [x] API fallback for missing items

---

### ✅ Meal Logging UI

Issue: [#314](https://github.com/gannonh/jab-tracker-ios/issues/314)

Food logging interface with search, nutrition facts display, serving adjustment, and meal section organization.

#### Requirements

- [x] FoodSearchView - search with results list
- [x] FoodDetailView - nutrition facts, serving adjustment
- [x] MealLogView - today's meals by section
- [x] AddFoodSheet - quick add modal
- [x] Four meal sections (breakfast, lunch, dinner, snacks)
- [x] Serving size input with unit conversion
- [x] Edit and delete logged entries

#### User Stories

##### Logging
- **As a user**, I want to search and add foods quickly, so that logging is effortless.
- **As a user**, I want to adjust serving sizes, so that I log accurate amounts.

##### Organization
- **As a user**, I want foods organized by meal, so that I can see my daily eating pattern.
- **As a user**, I want to edit logged entries, so that I can fix mistakes.

#### Key Design Decisions

1. **Four meal sections** - Standard meal organization.
2. **Bidirectional serving input** - Quantity or target macro.
3. **Swipe actions** - Quick edit/delete gestures.

#### Acceptance Criteria

- [x] Food searchable and addable
- [x] Serving size adjustable with live macro updates
- [x] Meals organized by section
- [x] Entries editable and deletable

---

### ✅ Custom Foods (Food Library)

Issue: [#317](https://github.com/gannonh/jab-tracker-ios/issues/317)
Completed: 2025-12-24

User-created custom foods with barcode assignment, cloud sync, and prioritized search placement.

#### Requirements

- [x] CustomFood SwiftData model with CloudKit sync
- [x] "To Custom" button opens CreateFoodSheet pre-filled
- [x] Create food with custom name, macros, serving info
- [x] "Create" and "Create & Add" save actions
- [x] "My Foods" section in search results
- [x] Custom foods prioritized in search results
- [x] Edit existing custom foods via swipe action
- [x] Delete custom foods with confirmation
- [x] Barcode scanner via Scan tab in FoodSearchSheet
- [x] Barcode shortcut in ShortcutsSheet
- [x] Barcode lookup in Open Food Facts database
- [x] Assign barcode to custom food
- [x] Works fully offline, syncs via CloudKit

#### User Stories

##### Creation
- **As a user**, I want to create custom foods, so that I can log items not in the database.
- **As a user**, I want to save a searched food as custom, so that I can modify its values.

##### Barcodes
- **As a user**, I want to scan barcodes, so that I can quickly find products.
- **As a user**, I want to assign barcodes to custom foods, so that future scans auto-fill.

##### Access
- **As a user**, I want my custom foods shown first in search, so that I find them quickly.
- **As a user**, I want my custom foods synced across devices, so that I have them everywhere.

#### Key Design Decisions

1. **Custom foods prioritized** - Appear in "My Foods" section at top.
2. **Barcode assignment** - Link any barcode to a custom food.
3. **CloudKit sync** - Custom foods available on all devices.

#### Acceptance Criteria

- [x] Custom food creatable with name and macros
- [x] Barcode scanner functional
- [x] Custom foods appear first in search
- [x] Sync works across devices

**Deferred:**
- Manual barcode entry field (scan-only for now)
- Recipe builder (combining foods into calculated recipes)

---

### ✅ Enhanced Daily Tracking (v0.2.0)

Issue: [#319](https://github.com/gannonh/jab-tracker-ios/issues/319)
Completed: 2025-12-26

Calendar navigation, food library management, quick macro entry, weight tracking with HealthKit, body metrics with progress photos, and feature settings.

#### Requirements

- [x] Week calendar strip with day selection updating macro summary
- [x] Tap food entry to open editable FoodDetailSheet
- [x] Dedicated Food Library screen with Foods tab, sort options, tap-to-add
- [x] Quick Add for macro-only food logging without food lookup
- [x] Weight and body fat entry with HealthKit sync
- [x] Configurable body metrics (waist, chest, hips, bicep, thigh) with HealthKit sync (waist only)
- [x] Progress photo capture (front, side, back) with local storage
- [x] Body metrics visibility toggles (which metrics to show in sheets)
- [x] Units of measure preferences (metric/imperial for weight and length)
- [x] CloudKit sync for all new models

#### User Stories

##### Calendar Navigation
- **As a user**, I want a week calendar in Food Log, so that I can navigate to past days quickly.
- **As a user**, I want to tap a day to see that day's entries, so that I can review my eating history.

##### Food Library
- **As a user**, I want a dedicated Food Library screen, so that I can manage all my custom foods in one place.
- **As a user**, I want to sort foods by name or date added, so that I can find foods easily.
- **As a user**, I want swipe actions to edit or delete foods, so that management is fast.

##### Quick Add
- **As a user**, I want to log macros directly without searching for foods, so that I can log quickly when I know the values.

##### Weight Tracking
- **As a user**, I want to log my weight quickly, so that I track progress over time.
- **As a user**, I want to log body fat percentage, so that I track body composition.
- **As a user**, I want weight synced to Apple Health, so that my data is centralized.

##### Body Metrics
- **As a user**, I want to log body measurements, so that I track progress beyond the scale.
- **As a user**, I want to choose which metrics to show, so that I only see what's relevant to me.
- **As a user**, I want to take progress photos, so that I have visual records of my journey.

##### Settings
- **As a user**, I want to toggle metric visibility, so that sheets aren't cluttered with unused fields.
- **As a user**, I want to choose my preferred units, so that values display in familiar measurements.

#### Key Design Decisions

1. **Week calendar strip** - Compact navigation without leaving Food Log tab.
2. **Metric-first storage** - All measurements stored in metric (kg, cm), converted for display.
3. **HealthKit waist only** - Apple Health only supports waistCircumference type for body metrics.
4. **Photo types as strings** - CloudKit-compatible storage for future extensibility.
5. **Default minimal metrics** - Waist enabled by default, others opt-in.

#### Acceptance Criteria

- [x] Week calendar navigates days with entry indicators
- [x] Tapping food entry opens editable sheet
- [x] Food Library shows custom foods with sort options
- [x] Quick Add logs macro-only entries
- [x] Weight entry syncs to HealthKit when enabled
- [x] Body metrics respect visibility preferences
- [x] Progress photos capture and store locally
- [x] Units display according to preferences
- [x] All data syncs via CloudKit

---

### ✅ Nutrition Goals & Daily Tracking (v0.3.0)

Issue: [#321](https://github.com/gannonh/jab-tracker-ios/issues/321)
Completed: 2026-01-01

Set personalized weight and macro goals with program styles (Coached/Collaborative/Manual), adaptive TDEE engine, daily progress tracking with visual indicators, and weekly check-ins for program optimization.

#### Requirements

- [x] Goal configuration wizard (weight loss/gain/maintenance, target weight, weekly pace)
- [x] Program configuration wizard (Coached/Collaborative/Manual styles)
- [x] Diet preference selection (Balanced, High Protein, Low Carb, Low Fat, Keto)
- [x] Adaptive TDEE engine with EWMA smoothing and confidence scoring
- [x] HealthKit integration for height, sex, DOB, weight
- [x] Daily calorie, protein, carb, and fat targets with per-day customization
- [x] Weekly macro distribution (Even or Shifted for Coached; per-day for Collaborative/Manual)
- [x] Progress rings for each macro with color thresholds (green/yellow/red)
- [x] Remaining vs consumed display on dashboard
- [x] Color coding for under/on-track/over targets
- [x] Strategy view with weekly macro grid and goal summary
- [x] Edit goals and programs from Strategy view
- [x] Weekly check-ins with countdown timer and optimization flow

#### User Stories

##### Goal Setup
- **As a user**, I want a guided goal setup, so that I configure targets correctly.
- **As a user**, I want to set a weight goal, so that the app calculates my daily calorie target.
- **As a user**, I want to choose my weight loss pace, so that I balance speed with sustainability.
- **As a user**, I want to select a nutrition strategy, so that my macro targets align with my diet.
- **As a user**, I want my calorie target to adjust based on actual weight changes via adaptive TDEE.

##### Program Styles
- **As a user**, I want Coached mode, so that all my targets are calculated automatically.
- **As a user**, I want Collaborative mode, so that I can customize per-day targets while keeping TDEE guidance.
- **As a user**, I want Manual mode, so that I can enter my own calorie and macro targets.

##### Daily Tracking
- **As a user**, I want to see progress rings, so that I visualize my daily intake at a glance.
- **As a user**, I want color coding, so that I know when I'm over or under target.
- **As a user**, I want to see remaining macros, so that I plan my next meal.

##### Adjustments
- **As a user**, I want weekly check-ins, so that I can review progress and adjust my program.
- **As a user**, I want to edit goals and programs, so that I can adapt as my needs change.

#### Key Design Decisions

1. **Three program styles** - Coached (fully automated), Collaborative (guided + customization), Manual (full control).
2. **Adaptive TDEE** - Learns from weight history using EWMA smoothing with 70% confidence threshold.
3. **Per-day macro distribution** - Supports even, shifted (Coached), and fully custom (Collaborative/Manual) patterns.
4. **Visual progress rings** - 70pt circular rings with 6pt stroke for compact dashboard display.
5. **Color semantics** - Green (<95%), Yellow (95-110%), Red (>110% of target).
6. **Weekly check-ins** - 7-day minimum between check-ins with countdown display.

#### Acceptance Criteria

- [x] Goal wizard completes setup in under 2 minutes
- [x] Calorie goal calculated from weight goal, pace, and TDEE
- [x] Progress rings update in real-time as food is logged
- [x] Color coding reflects target status (green/yellow/red)
- [x] Goals and programs editable from Strategy view
- [x] Per-day targets display correctly in weekly macro grid
- [x] Weekly check-in countdown visible in Strategy view

#### Delivered Components

**Data Models:**
- NutritionGoal, NutritionProgram SwiftData models
- WeeklyMacroDistribution, DailyMacros value types
- ProgramStyle, DietPreference, CalorieFloor, TrainingLevel enums

**Services:**
- TDEECalculationEngine (BMR, activity multipliers)
- TDEEService (adaptive TDEE with confidence scoring)
- WeeklyCheckInService (summary generation, adherence)

**Views:**
- GoalWizardView (goal type, target weight, weekly rate)
- ProgramWizardView (style, diet pref, calorie floor, training, distribution, protein level)
- StrategyView (goal summary, weekly grid, action buttons, check-in countdown)
- ProgramReadySheet (calculated targets display)
- ProgramOptimizationSheet (weekly check-in flow)
- NutritionSummaryCard progress rings

**More Tab Refinements:**
- SecurityPrivacyView (Face ID, Health, iCloud status)
- NotificationSettingsView (weigh-in, food logging, medication reminders)
- SubscriptionSettingsView (mock)
- CalorieExpenditureView (placeholder - implemented in v0.4.0)

**Deferred:**
- Metabolic adaptation modeling (future TDEE refinement)
- Weight trend smoothing visualization

---

### ✅ Calorie Expenditure Enhancements (v0.4.0)

Issue: [#326](https://github.com/gannonh/jab-tracker-ios/issues/326)
Completed: 2026-01-04

Real-time burned calorie integration from HealthKit, rollover unused calories, and predictive activity adjustments based on historical trends to provide dynamic calorie targets.

#### Requirements

- [x] Add burned calories from HealthKit back to daily targets in real-time
- [x] HKObserverQuery with background delivery for activeEnergyBurned
- [x] Rollover up to 200 unused calories from yesterday to today
- [x] Predictive activity adjustment based on 7-day historical average
- [x] Goal-mode multipliers (0.8/1.0/1.2) for weight loss/maintenance/muscle gain
- [x] Integration with CalorieAdjustmentService and NutritionSummaryViewModel
- [x] Feature toggles in CalorieExpenditureView settings
- [x] Flame icon indicator when burned calories active
- [x] E2E tests for all calorie expenditure features

#### User Stories

##### Add Burned Calories
- **As a user**, I want my burned calories added to my daily target, so that I can eat more on active days.
- **As a user**, I want to see a flame icon when burned calories are active, so that I know the feature is working.

##### Rollover Calories
- **As a user**, I want unused calories from yesterday to carry over, so that I have flexibility in daily eating.
- **As a user**, I want a cap on rollover, so that I don't accumulate too large a deficit.

##### Predictive Activity
- **As a user**, I want my target adjusted based on my typical activity level, so that I'm prepared for expected activity.
- **As a user**, I want the prediction to match my goal type, so that I eat appropriately for weight loss vs muscle gain.

#### Key Design Decisions

1. **Real-time updates** - HKObserverQuery ensures burned calories update immediately.
2. **200 kcal rollover cap** - Prevents excessive rollover accumulation while providing flexibility.
3. **Mutual exclusivity** - Predictive activity skipped when burned calories enabled (avoids double-counting).
4. **Goal multipliers** - Weight loss 0.8x, maintenance 1.0x, muscle gain 1.2x of 7-day average.
5. **Feature toggles** - Each feature independently enabled via CalorieExpenditureView.

#### Acceptance Criteria

- [x] Burned calories from HealthKit added to daily target when enabled
- [x] Flame icon appears on dashboard and food log when burned calories > 0
- [x] Rollover capped at 200 kcal maximum
- [x] Rollover only applies when yesterday had a deficit
- [x] Predictive uses 7-day history with goal-mode multiplier
- [x] All features toggle independently
- [x] E2E tests pass for all scenarios

#### Delivered Components

**Services:**
- CalorieAdjustmentService (orchestrates burned + rollover + predictive)
- RolloverCalorieProvider (calculates yesterday's unused calories)
- PredictiveActivityProvider (7-day average with goal multipliers)
- HealthKitService active energy methods and observer query

**Views:**
- CalorieExpenditureView (feature toggles, Health Sync dependency)
- NutritionSummaryCard flame icon indicator

**Tests:**
- CalorieExpenditureUITests (14 tests)
- RolloverCaloriesUITests (8 tests)
- PredictiveActivityUITests (6 tests)
- Unit tests for all providers and services

---

### ✅ Navigation Refinement (v0.5.0)

Issue: [#327](https://github.com/gannonh/jab-tracker-ios/issues/327)
Completed: 2026-01-05

Streamlined navigation by consolidating GLP-1 features under More tab, promoting Strategy to a top-level tab, and modernizing the Add button design.

#### Requirements

- [x] Merge Shots tab and Medication Profiles into unified "GLP-1 Programs" section under More
- [x] GLP-1 Programs view with Analytics/Medications segmented picker
- [x] Analytics sub-sections: Concentration, Adherence, History
- [x] Medications list with swipe actions (disable, delete, enable)
- [x] Replace Shots tab in tab bar with Strategy tab
- [x] Strategy tab directly loads StrategyView (Goals & Strategy)
- [x] Icon-only, larger Add button with no text label
- [x] Floating overlay button design (44x44, plus icon, blue tint)

#### User Stories

##### Navigation Consolidation
- **As a user**, I want GLP-1 features in one place, so that I can access shots and medications together.
- **As a user**, I want Strategy as a top-level tab, so that I can quickly access my goals and program.

##### Add Button
- **As a user**, I want a cleaner Add button, so that the tab bar looks more modern.
- **As a user**, I want the same shortcuts behavior, so that my workflow isn't disrupted.

#### Key Design Decisions

1. **GLP-1 consolidation** - Unified "GLP-1 Programs" view replaces separate Shots tab and Medication Profiles.
2. **Strategy promotion** - Strategy elevated from More sub-menu to top-level tab (Dashboard-style prominence).
3. **Floating Add button** - Uses ZStack overlay instead of tab item to allow custom sizing.
4. **Tab bar order** - Dashboard | Food Log | Add (center) | Strategy | More.

#### Acceptance Criteria

- [x] GLP-1 Programs accessible from More tab
- [x] Analytics/Medications toggle works correctly
- [x] Strategy tab appears in tab bar
- [x] Shots tab no longer in tab bar
- [x] Add button is icon-only and larger
- [x] ShortcutsSheet behavior preserved

#### Delivered Components

**Views:**
- GLP1ProgramsView (unified analytics + medications)
- ConcentrationSection, AdherenceSection, HistorySection (extracted components)
- Updated ContentView with Strategy tab and floating Add button
- Updated MoreView with "GLP-1 Programs" row

**Tests:**
- GLP1ProgramsUITests (navigation, section switching, medications list)
- StrategyTabUITests (tab existence, navigation, tab bar order)
- AddButtonUITests (existence, shortcuts sheet, icon-only design)

---

### ✅ Onboarding Redux (v0.6.0)

Issue: [#329](https://github.com/gannonh/jab-tracker-ios/issues/329)
Completed: 2026-01-07

Complete rewrite of onboarding focused on core experience — USP showcase, simplified goal/program setup, and permission screens (HealthKit, Face ID, Notifications).

#### Requirements

- [x] Archive legacy onboarding (prefixed with "Legacy" for reference)
- [x] New OnboardingCoordinator with clean step structure
- [x] Sign in with Apple retained as first step
- [x] USP showcase screens (adaptive TDEE, precision tracking, calorie adjustments, GLP-1 support)
- [x] Simplified goal setup (weight loss/gain/maintain, target weight)
- [x] Simplified program setup (program style, diet preference, calorie floor, activity level, weekly distribution, protein level)
- [x] Profile completion step (height, DOB, sex) with HealthKit pre-fill when available
- [x] Individual permission screens with toggle pattern (HealthKit, Face ID, Notifications)
- [x] Setup confirmation screen with calculated targets display
- [x] Completion screen with summary and next steps
- [x] Smooth transition from onboarding to main app with opacity animation
- [x] "Skip for now" option on goal/program steps
- [x] E2E tests for complete onboarding flow

#### User Stories

##### Discovery
- **As a new user**, I want to see what makes MacroKinetic special, so that I understand the value proposition.
- **As a user**, I want a streamlined setup, so that I can start tracking quickly.

##### Setup
- **As a user**, I want to set my weight goal, so that the app calculates my targets.
- **As a user**, I want to configure my program, so that macros match my preferences.
- **As a user**, I want to enable permissions selectively, so that I control what data the app accesses.

##### Flexibility
- **As a user**, I want to skip setup if I'm exploring, so that I can complete it later.
- **As a user**, I want to see my calculated targets before finishing, so that I can verify my setup.

#### Key Design Decisions

1. **Toggle pattern for permissions** - HealthKit, Face ID, and Notifications use toggle + Continue instead of separate skip/enable buttons.
2. **Mint accent color (#00A693)** - Brand identity with good contrast in both light and dark modes.
3. **Fullscreen onboarding** - Avoids flash of ContentView before onboarding completes.
4. **2000 kcal baseline** - Simple starting point (150g protein, 200g carbs, 67g fat) for all goal types.
5. **Smart target weight defaults** - -10kg for loss, +5kg for gain, 0 for maintain.
6. **Calculating overlay** - 5-second animation while computing targets for perceived sophistication.
7. **BiologicalSex enum** - Cleaner model than raw strings with HealthKit integration.

#### Acceptance Criteria

- [x] User completes onboarding in under 3 minutes
- [x] USP screens showcase 4 key features
- [x] Goal and program setup calculates personalized targets
- [x] Permission toggles work correctly (enable/skip)
- [x] Setup confirmation shows calculated calories and macros
- [x] Completion screen provides clear next steps
- [x] Transition to main app is smooth
- [x] Skip option available on appropriate steps
- [x] E2E tests pass for complete flow and all permission scenarios

#### Delivered Components

**Coordinator:**
- OnboardingCoordinator (step progression, data collection)
- OnboardingViewModel (step validation, target calculation)

**Views:**
- WelcomeStepView, USPShowcaseStepView
- GoalTypeStepView, TargetWeightStepView, ProfileCompletionStepView
- ProgramStyleStepView, DietPreferenceStepView, CalorieFloorStepView
- ActivityLevelStepView, WeeklyDistributionStepView, ProteinLevelStepView
- SetupConfirmationStepView (with calculating overlay)
- HealthKitStepView, FaceIDStepView, NotificationsStepView
- CompletionStepView (summary card, next steps)

**Tests:**
- NewOnboardingUITests (12 tests - complete flow, navigation, step display)
- OnboardingPermissionsUITests (7 tests - HealthKit, Face ID, Notifications enable/skip)

**Deferred:**
- GLP-1 medication setup (moved to future milestone)
- StoreKit subscription screen (moved to future milestone)

---

### 📋 Protein Preservation Alerts

Proactive protein monitoring to prevent muscle loss during weight loss, with alerts and recommendations.

#### Requirements

- [ ] Minimum protein threshold based on body weight (1.6g/kg)
- [ ] ProteinMonitoringService
- [ ] Evening notification if protein < 80% target
- [ ] Protein progress ring on dashboard (prominent)
- [ ] Color-coded severity (green/yellow/red)
- [ ] High-protein food suggestions
- [ ] Weekly protein trend analysis

#### User Stories

##### Alerts
- **As a user**, I want protein alerts, so that I don't lose muscle while losing weight.
- **As a user**, I want evening reminders, so that I can still hit my target before bed.

##### Guidance
- **As a user**, I want high-protein food suggestions, so that I know what to eat to catch up.
- **As a user**, I want weekly trends, so that I can see if I'm consistently hitting targets.

#### Key Design Decisions

1. **1.6g/kg minimum** - Research-backed threshold for muscle preservation.
2. **Evening window** - Alert at 6pm if below 80% target.
3. **Prominent dashboard placement** - Protein ring more visible than other macros.

#### Acceptance Criteria

- [ ] Protein threshold calculated from body weight
- [ ] Evening notification fires when under 80%
- [ ] Protein ring prominent on dashboard
- [ ] Food suggestions relevant and actionable

---

### ✅ HealthKit Integration

Sync weight, body fat, steps, and active calories from Apple Health for comprehensive tracking.

#### Requirements

- [ ] HealthKitService
- [ ] Request authorization
- [ ] Sync weight from Apple Health
- [ ] Sync body fat percentage
- [ ] Sync steps and active calories
- [ ] Display weight trend on dashboard
- [ ] Calculate net calories (consumed - burned)

#### User Stories

##### Sync
- **As a user**, I want my weight synced from Apple Health, so that I don't enter it manually.
- **As a user**, I want my activity data imported, so that calorie burn is factored in.

##### Insights
- **As a user**, I want to see my weight trend, so that I know if I'm making progress.
- **As a user**, I want net calories shown, so that I understand my true intake.

#### Key Design Decisions

1. **Read-only integration** - No writes to HealthKit.
2. **Daily sync** - Pull latest values on app launch.
3. **Net calories** - Consumed minus active calories.

#### Acceptance Criteria

- [ ] HealthKit authorization requested appropriately
- [ ] Weight syncs from Apple Health
- [ ] Steps and active calories imported
- [ ] Weight trend displayed on dashboard

---

### 📋 Medication-Nutrition Correlation

Analyze relationships between GLP-1 medication levels and eating patterns to provide personalized insights.

#### Requirements

- [ ] AppetiteEntry model (hunger, cravings, food noise)
- [ ] Daily appetite check-in UI
- [ ] NutritionCorrelationEngine
- [ ] Concentration vs. appetite chart overlay
- [ ] Food noise reduction timeline
- [ ] Eating patterns by medication cycle
- [ ] Optimal eating window calculation
- [ ] Correlation insights generation

#### User Stories

##### Tracking
- **As a user**, I want to log my appetite, so that I can correlate it with medication levels.
- **As a user**, I want to track food noise, so that I can see medication effects.

##### Insights
- **As a user**, I want to see patterns, so that I understand how medication affects my eating.
- **As a user**, I want optimal eating windows, so that I can plan meals effectively.

#### Key Design Decisions

1. **Appetite metrics** - Hunger, cravings, food noise (0-10 scales).
2. **Correlation engine** - Statistical analysis of patterns.
3. **Cycle-aware insights** - Analysis relative to dose timing.

#### Acceptance Criteria

- [ ] Appetite logging available
- [ ] Charts overlay concentration and appetite
- [ ] Eating patterns identified by cycle position
- [ ] Insights generated and displayed

---

### ✅ Barcode Scanning

Note: Basic barcode scanning already implemented in Custom Foods feature. This extends functionality.

#### Requirements

- [ ] AVFoundation camera integration
- [ ] Open Food Facts API lookup
- [ ] Quick-add flow after scan
- [ ] Handle "not found" gracefully

#### User Stories

##### Scanning
- **As a user**, I want to scan any barcode, so that I can quickly log packaged foods.
- **As a user**, I want graceful handling of unknown barcodes, so that I can still log the item manually.

#### Key Design Decisions

1. **Camera-based scanning** - AVFoundation for native performance.
2. **Fallback to manual** - Unknown barcodes prompt custom food creation.

#### Acceptance Criteria

- [ ] Barcode scanner opens quickly
- [ ] Known barcodes return food details
- [ ] Unknown barcodes offer manual entry option

---

### 📋 AI Photo to Macros

AI-powered food recognition from photos with portion estimation and macro calculation.

#### Requirements

- [ ] Camera capture for food photos
- [ ] AI vision API integration (identify food items)
- [ ] Portion size estimation from image
- [ ] Macro estimation based on identified foods
- [ ] User confirmation/adjustment before logging
- [ ] Fallback to manual search if low confidence

#### User Stories

##### Photo Logging
- **As a user**, I want to photograph my meal, so that I can log without searching.
- **As a user**, I want AI to estimate portions, so that logging is even faster.

##### Verification
- **As a user**, I want to confirm AI suggestions, so that I can correct mistakes.
- **As a user**, I want to fall back to search, so that I can log if AI fails.

#### Key Design Decisions

1. **AI vision API** - External service for food recognition.
2. **Confidence thresholds** - Auto-log high confidence, confirm medium, reject low.
3. **User verification** - Always allow adjustment before logging.

#### Acceptance Criteria

- [ ] Camera capture works
- [ ] AI identifies common foods
- [ ] Portion estimation reasonable
- [ ] User can adjust before logging

---

### 📋 Dashboard

Unified dashboard with nutrition tracking, energy balance, body metrics, and weight analytics.

@.planning/project-prd+dashboard.md

---

### 📋 Unified Analytics

Combined analytics showing nutrition trends, medication-nutrition correlations, and progress insights.

#### Requirements

- [ ] Nutrition trends (calories, protein over time)
- [ ] Concentration vs. daily calories chart
- [ ] Food noise by day post-dose chart
- [ ] Protein intake vs. weight change chart

#### User Stories

##### Trends
- **As a user**, I want to see nutrition trends, so that I understand my eating patterns.
- **As a user**, I want correlation charts, so that I see medication effects on eating.

##### Progress
- **As a user**, I want protein vs. weight charts, so that I optimize muscle preservation.

#### Key Design Decisions

1. **Multi-series charts** - Overlay multiple metrics.
2. **Time period selection** - 7d, 30d, 90d, 1y views.
3. **Interactive exploration** - Tap for data point details.

#### Acceptance Criteria

- [ ] Nutrition trends chart renders
- [ ] Correlation charts overlay correctly
- [ ] Time periods selectable
- [ ] Charts performant with large datasets

---

### 📋 Export & Reporting

PDF and CSV export with combined medication and nutrition summaries for sharing with healthcare providers.

#### Requirements

- [ ] PDF report generation
- [ ] CSV export
- [ ] Combined medication + nutrition summary
- [ ] Weight progress section

#### User Stories

##### Sharing
- **As a user**, I want to export PDF reports, so that I can share with my doctor.
- **As a user**, I want CSV export, so that I can analyze my data externally.

##### Comprehensive
- **As a user**, I want combined reports, so that I see medication and nutrition together.

#### Key Design Decisions

1. **PDF for sharing** - Professional format for healthcare providers.
2. **CSV for analysis** - Raw data for spreadsheet users.
3. **Configurable date ranges** - User selects report period.

#### Acceptance Criteria

- [ ] PDF generates with all data sections
- [ ] CSV exports correctly formatted
- [ ] Date range selectable
- [ ] Share sheet integration works

---

### 📋 User Onboarding (Nutrition Path)

Alternative onboarding flow for nutrition-only users, with optional medication tracking add-on.

#### Requirements

- [ ] Welcome screens with nutrition benefits
- [ ] Goal selection (weight loss, maintenance, muscle gain)
- [ ] Macro target setup
- [ ] Meal reminder preferences
- [ ] Optional: Add medication tracking

#### User Stories

##### Discovery
- **As a new user**, I want nutrition-focused onboarding, so that I'm not overwhelmed by medication features.
- **As a user**, I want to set my goal, so that targets are personalized.

##### Expansion
- **As a nutrition user**, I want to add medication tracking later, so that I can expand when ready.

#### Key Design Decisions

1. **Dual-path onboarding** - Medication or nutrition entry point.
2. **Goal-first setup** - Calculate targets from user goal.
3. **Optional expansion** - Add medication features without re-onboarding.

#### Acceptance Criteria

- [ ] Nutrition onboarding completable
- [ ] Goals set up correctly
- [ ] Medication tracking addable later
- [ ] User can skip medication entirely

---

### 🔨 Subscription Management

StoreKit 2 integration for subscription tiers with paywall UI and purchase restoration.

#### Requirements

- [ ] StoreKit 2 integration
- [ ] Subscription tiers
- [ ] Paywall UI
- [ ] Restore purchases

#### User Stories

##### Purchasing
- **As a user**, I want to subscribe, so that I access premium features.
- **As a user**, I want to see tier options, so that I choose the right plan.

##### Management
- **As a user**, I want to restore purchases, so that I regain access on new devices.

#### Key Design Decisions

1. **StoreKit 2** - Modern Apple subscription API.
2. **Tiered access** - Free, Premium, Pro levels.
3. **Graceful degradation** - App works without subscription.

#### Acceptance Criteria

- [ ] Subscription products load
- [ ] Purchase flow completes
- [ ] Restore purchases works
- [ ] Tier access enforced correctly

---

## Non-Functional Requirements

### Performance
| Metric                        | Target      |
| ----------------------------- | ----------- |
| App launch                    | < 2 seconds |
| Food search                   | < 100ms     |
| Calculation updates           | < 50ms      |
| Chart rendering (365 entries) | < 500ms     |
| Memory usage                  | < 100MB     |

### Security & Privacy
- SwiftData encryption
- Keychain for credentials
- Biometric protection
- On-device processing preference
- No third-party analytics

### Accessibility
- VoiceOver support
- Dynamic Type scaling
- High Contrast mode
- Reduce Motion compatibility
- 44x44pt minimum touch targets

### Testing Coverage
- Business Logic: 90%
- View Models: 85%
- Infrastructure: 62%
- Framework Integration: 42%

---

## Competitive Advantages

| Feature                       | Competitors     | MacroKinetic           |
| ----------------------------- | --------------- | ---------------------- |
| Food database                 | 100K-1M         | 1.7M+ with barcodes    |
| Pharmacokinetics              | Basic estimates | True exponential decay |
| Medication-nutrition insights | None            | Correlation engine     |
| Protein preservation alerts   | None            | Yes                    |
| Offline food search           | Limited         | Full database offline  |
| Reconstitution calculator     | None            | Yes                    |
| Split-dose support            | None            | Yes                    |

---

## Update History

- 2026-01-07: Added Onboarding Redux (v0.6.0) - Complete onboarding rewrite with USP showcase, simplified goal/program setup, permission screens with toggle pattern, E2E tests
- 2026-01-05: Added Navigation Refinement (v0.5.0) - GLP-1 Programs consolidation, Strategy tab promotion, Add button redesign
- 2026-01-01: Added Goals & Nutrition Programs (v0.3.0) - goal/program wizards, 3 program styles (Coached/Collaborative/Manual), adaptive TDEE engine, progress rings, weekly check-ins, More tab refinements
- 2025-12-26: Added Enhanced Daily Tracking (v0.2.0) - calendar navigation, food library, quick add, weight tracking, body metrics, progress photos, feature settings
- 2025-12-24: Added Custom Foods (Food Library) feature - completed with barcode scanning
- 2025-12-20: Consolidated from macro-integration.md and project-prd.md into single sequenced PRD
- 2025-12-19: Initial nutrition infrastructure documentation
