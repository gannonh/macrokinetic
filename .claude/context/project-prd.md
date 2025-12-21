---
created: 2024-01-15T00:00:00Z
updated: 2025-12-21T21:11:39Z
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

| Requirement                     | Done |
| ------------------------------- | ---- |
| Sign in with Apple              | ✅    |
| Face ID/Touch ID for app access | ✅    |
| Keychain credential storage     | ✅    |
| Persistent session state        | ✅    |

---

### ✅ User Onboarding (Medication Path)

| Requirement                                 | Done |
| ------------------------------------------- | ---- |
| Welcome screens with app benefits           | ✅    |
| Medication selection wizard (4 GLP-1 meds)  | ✅    |
| Initial dose entry with injection site      | ✅    |
| Schedule setup (weekly, split-dose, custom) | ✅    |
| Notification permissions                    | ✅    |
| Subscription screen placeholder             | ✅    |

---

### ✅ Medication Profile Management

| Requirement                                     | Done |
| ----------------------------------------------- | ---- |
| CRUD for medication profiles                    | ✅    |
| Support 4 GLP-1 medications with brand variants | ✅    |
| Brand-aware dose validation                     | ✅    |
| Dose escalation (titration) tracking            | ✅    |
| Reconstitution calculator for compounded meds   | ✅    |
| Injection site preferences                      | ✅    |

---

### ✅ Dose Tracking

| Requirement                                      | Done |
| ------------------------------------------------ | ---- |
| Quick dose entry via "+" tab button              | ✅    |
| Manual entry with date/time, amount, site, notes | ✅    |
| Calendar view with dose indicators               | ✅    |
| List view with search and filtering              | ✅    |
| Edit/delete past entries                         | ✅    |
| Statistics (adherence rates, streaks)            | ✅    |

---

### ✅ Pharmacokinetics Engine

| Requirement                                  | Done |
| -------------------------------------------- | ---- |
| Exponential decay concentration modeling     | ✅    |
| Medication-specific half-life values         | ✅    |
| Peak, trough, and current level calculations | ✅    |
| Steady-state progress tracking               | ✅    |
| ConcentrationCard dashboard display          | ✅    |

---

### ✅ Dose Scheduling

| Requirement                                    | Done |
| ---------------------------------------------- | ---- |
| Schedule creation (weekly, split-dose, custom) | ✅    |
| Upcoming dose projections                      | ✅    |
| Pause/resume schedules                         | ✅    |
| Modification history                           | ✅    |
| Titration completion workflow                  | ✅    |

---

### ✅ Notifications (Medication)

| Requirement                         | Done |
| ----------------------------------- | ---- |
| Scheduled dose reminders            | ✅    |
| Titration completion alerts         | ✅    |
| Missed dose notifications           | ✅    |
| Badge management                    | ✅    |
| Deep linking to entry screens       | ✅    |
| Action handling (log, snooze, skip) | ✅    |

---

### ✅ Analytics (Medication)

| Requirement                                | Done |
| ------------------------------------------ | ---- |
| Concentration timeline chart (interactive) | ✅    |
| Time period selection (7d, 30d, 90d, 1y)   | ✅    |
| Dose markers on timeline                   | ✅    |
| Future projections                         | ✅    |
| Adherence insights                         | ✅    |
| Streak tracking                            | ✅    |

---

### ✅ CloudKit Sync

| Requirement                      | Done |
| -------------------------------- | ---- |
| Automatic iCloud synchronization | ✅    |
| Real-time sync status monitoring | ✅    |
| Graceful offline-first fallback  | ✅    |
| Multi-device support             | ✅    |

---

### ✅ Food Database Infrastructure

Issue: [#314](https://github.com/gannonh/jab-tracker-ios/issues/314)

| Requirement                             | Done |
| --------------------------------------- | ---- |
| Food and FoodEntry SwiftData models     | ✅    |
| 1.7M+ foods from USDA + Open Food Facts | ✅    |
| SQLite FTS5 full-text search            | ✅    |
| Barcode column with index               | ✅    |
| Offline-first (entire database bundled) | ✅    |
| FoodService orchestrating search        | ✅    |
| LocalFoodDatabase service               | ✅    |
| OpenFoodFactsService API client         | ✅    |
| MealLogService for CRUD                 | ✅    |

---

### 🔨 Meal Logging UI

Issue: [#314](https://github.com/gannonh/jab-tracker-ios/issues/314)

| Requirement                                           | Done |
| ----------------------------------------------------- | ---- |
| FoodSearchView - search with results list             | ✅    |
| FoodDetailView - nutrition facts, serving adjustment  | ✅    |
| MealLogView - today's meals by section                | ✅    |
| AddFoodSheet - quick add modal                        | ✅    |
| Four meal sections (breakfast, lunch, dinner, snacks) | ✅    |
| Serving size input with unit conversion               | ✅    |
| Edit and delete logged entries                        |      |

---

### 📋 User Model Extension (Nutrition Goals)

| Requirement                    | Done |
| ------------------------------ | ---- |
| Daily calorie goal field       |      |
| Daily protein goal field       |      |
| Daily carb goal field          |      |
| Daily fat goal field           |      |
| FoodEntry relationship on User |      |

---

### 📋 Tab Navigation Update

| Requirement                              | Done |
| ---------------------------------------- | ---- |
| Update tab structure for nutrition focus |      |
| "+" button opens food/dose picker        |      |
| Combined history view (meals + doses)    |      |

---

### 📋 Macro Goals & Daily Tracking

| Requirement                                           | Done |
| ----------------------------------------------------- | ---- |
| Goal configuration UI (calories, protein, carbs, fat) |      |
| Progress rings/bars for each macro                    |      |
| Remaining vs consumed display                         |      |
| Color coding for under/over targets                   |      |
| Daily summary on dashboard                            |      |

---

### 📋 Protein Preservation Alerts

| Requirement                                              | Done |
| -------------------------------------------------------- | ---- |
| Minimum protein threshold based on body weight (1.6g/kg) |      |
| ProteinMonitoringService                                 |      |
| Evening notification if protein < 80% target             |      |
| Protein progress ring on dashboard (prominent)           |      |
| Color-coded severity (green/yellow/red)                  |      |
| High-protein food suggestions                            |      |
| Weekly protein trend analysis                            |      |

---

### 📋 HealthKit Integration

| Requirement                                | Done |
| ------------------------------------------ | ---- |
| HealthKitService                           |      |
| Request authorization                      |      |
| Sync weight from Apple Health              |      |
| Sync body fat percentage                   |      |
| Sync steps and active calories             |      |
| Display weight trend on dashboard          |      |
| Calculate net calories (consumed - burned) |      |

---

### 📋 Medication-Nutrition Correlation

| Requirement                                        | Done |
| -------------------------------------------------- | ---- |
| AppetiteEntry model (hunger, cravings, food noise) |      |
| Daily appetite check-in UI                         |      |
| NutritionCorrelationEngine                         |      |
| Concentration vs. appetite chart overlay           |      |
| Food noise reduction timeline                      |      |
| Eating patterns by medication cycle                |      |
| Optimal eating window calculation                  |      |
| Correlation insights generation                    |      |

---

### 📋 Barcode Scanning

| Requirement                     | Done |
| ------------------------------- | ---- |
| AVFoundation camera integration |      |
| Open Food Facts API lookup      |      |
| Quick-add flow after scan       |      |
| Handle "not found" gracefully   |      |

---

### 📋 AI Photo to Macros

| Requirement                                     | Done |
| ----------------------------------------------- | ---- |
| Camera capture for food photos                  |      |
| AI vision API integration (identify food items) |      |
| Portion size estimation from image              |      |
| Macro estimation based on identified foods      |      |
| User confirmation/adjustment before logging     |      |
| Fallback to manual search if low confidence     |      |

---

### 📋 Unified Dashboard

| Requirement                           | Done |
| ------------------------------------- | ---- |
| Concentration card (medication users) |      |
| Today's nutrition summary             |      |
| Prominent protein progress ring       |      |
| Appetite/food noise indicator         |      |
| Weight trend from HealthKit           |      |

---

### 📋 Combined Calendar View

| Requirement                                    | Done |
| ---------------------------------------------- | ---- |
| Dose markers (existing)                        |      |
| Meal indicators (breakfast/lunch/dinner icons) |      |
| Protein status dots (green/yellow/red)         |      |
| Weight data points                             |      |

---

### 📋 Unified Analytics

| Requirement                                    | Done |
| ---------------------------------------------- | ---- |
| Nutrition trends (calories, protein over time) |      |
| Concentration vs. daily calories chart         |      |
| Food noise by day post-dose chart              |      |
| Protein intake vs. weight change chart         |      |

---

### 📋 Export & Reporting

| Requirement                             | Done |
| --------------------------------------- | ---- |
| PDF report generation                   |      |
| CSV export                              |      |
| Combined medication + nutrition summary |      |
| Weight progress section                 |      |

---

### 📋 User Onboarding (Nutrition Path)

| Requirement                                            | Done |
| ------------------------------------------------------ | ---- |
| Welcome screens with nutrition benefits                |      |
| Goal selection (weight loss, maintenance, muscle gain) |      |
| Macro target setup                                     |      |
| Meal reminder preferences                              |      |
| Optional: Add medication tracking                      |      |

---

### 🔨 Subscription Management

| Requirement            | Done |
| ---------------------- | ---- |
| StoreKit 2 integration |      |
| Subscription tiers     |      |
| Paywall UI             |      |
| Restore purchases      |      |

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

- 2025-12-20: Consolidated from macro-integration.md and project-prd.md into single sequenced PRD
- 2025-12-19: Initial nutrition infrastructure documentation
