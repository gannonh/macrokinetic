---
created: 2024-01-15T00:00:00Z
updated: 2025-12-26T18:01:49Z
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

### 📋 Nutrition Goals & Daily Tracking

Set personalized weight and macro goals, then track daily progress with visual indicators showing intake vs. targets.

#### Requirements

- [ ] Goal configuration wizard (weight goal, pace, calorie/macro targets)
- [ ] Strategy/program selection (e.g., keto, balanced)
- [ ] Weight goal with target date and weekly pace selection
- [ ] Dynamic TDEE algorithm for calorie target (calorie targets adjust with weight changes)
- [ ] Daily calorie, protein, carb, and fat goals
- [ ] Progress rings/bars for each macro
- [ ] Remaining vs consumed display
- [ ] Color coding for under/over targets
- [ ] Daily summary on dashboard
- [ ] Edit goals from settings
- [ ] Weekly Check-ins for goal/strategy adjustments

#### User Stories

##### Goal Setup
- **As a user**, I want a guided goal setup, so that I configure targets correctly.
- **As a user**, I want to set a weight goal, so that the app calculates my daily calorie target.
- **As a user**, I want to choose my weight loss pace, so that I balance speed with sustainability.
- **As a user**, I want to select a nutrition strategy, so that my macro targets align with my diet.
- **As a user**, I want my calorie target to adjust, based on actual weight changes, not just a generic forumula

##### Daily Tracking
- **As a user**, I want to see progress rings, so that I visualize my daily intake at a glance.
- **As a user**, I want color coding, so that I know when I'm over or under target.
- **As a user**, I want to see remaining macros, so that I plan my next meal.

##### Adjustments
- **As a user**, I want to adjust goals later, so that I can adapt as my needs change.

#### Key Design Decisions

1. **Goal-driven calculations** - Calorie/macro targets derived from weight goal and pace.
2. **Visual progress rings** - Circular progress for each macro on dashboard.
3. **Color semantics** - Green (on track), Yellow (approaching limit), Red (over).

#### Acceptance Criteria

- [ ] Goal wizard completes setup in under 2 minutes
- [ ] Calorie goal calculated from weight goal and pace
- [ ] Progress rings update in real-time as food is logged
- [ ] Color coding reflects target status
- [ ] Goals editable from settings

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

### 📋 HealthKit Integration

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

### 📋 Barcode Scanning

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

- 2025-12-26: Added Enhanced Daily Tracking (v0.2.0) - calendar navigation, food library, quick add, weight tracking, body metrics, progress photos, feature settings
- 2025-12-24: Added Custom Foods (Food Library) feature - completed with barcode scanning
- 2025-12-20: Consolidated from macro-integration.md and project-prd.md into single sequenced PRD
- 2025-12-19: Initial nutrition infrastructure documentation
