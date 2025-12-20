---
created: 2024-01-15T00:00:00Z
updated: 2025-12-20T01:31:31Z
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

| Status | Meaning |
|--------|---------|
| ✅ | Done |
| 🔨 | In Progress |
| 📋 | Planned |

---

## Features (Sequenced)

### ✅ 1. Authentication

| Requirement | Done |
|-------------|------|
| Sign in with Apple | ✅ |
| Face ID/Touch ID for app access | ✅ |
| Keychain credential storage | ✅ |
| Persistent session state | ✅ |

---

### ✅ 2. User Onboarding (Medication Path)

| Requirement | Done |
|-------------|------|
| Welcome screens with app benefits | ✅ |
| Medication selection wizard (4 GLP-1 meds) | ✅ |
| Initial dose entry with injection site | ✅ |
| Schedule setup (weekly, split-dose, custom) | ✅ |
| Notification permissions | ✅ |
| Subscription screen placeholder | ✅ |

---

### ✅ 3. Medication Profile Management

| Requirement | Done |
|-------------|------|
| CRUD for medication profiles | ✅ |
| Support 4 GLP-1 medications with brand variants | ✅ |
| Brand-aware dose validation | ✅ |
| Dose escalation (titration) tracking | ✅ |
| Reconstitution calculator for compounded meds | ✅ |
| Injection site preferences | ✅ |

---

### ✅ 4. Dose Tracking

| Requirement | Done |
|-------------|------|
| Quick dose entry via "+" tab button | ✅ |
| Manual entry with date/time, amount, site, notes | ✅ |
| Calendar view with dose indicators | ✅ |
| List view with search and filtering | ✅ |
| Edit/delete past entries | ✅ |
| Statistics (adherence rates, streaks) | ✅ |

---

### ✅ 5. Pharmacokinetics Engine

| Requirement | Done |
|-------------|------|
| Exponential decay concentration modeling | ✅ |
| Medication-specific half-life values | ✅ |
| Peak, trough, and current level calculations | ✅ |
| Steady-state progress tracking | ✅ |
| ConcentrationCard dashboard display | ✅ |

---

### ✅ 6. Dose Scheduling

| Requirement | Done |
|-------------|------|
| Schedule creation (weekly, split-dose, custom) | ✅ |
| Upcoming dose projections | ✅ |
| Pause/resume schedules | ✅ |
| Modification history | ✅ |
| Titration completion workflow | ✅ |

---

### ✅ 7. Notifications (Medication)

| Requirement | Done |
|-------------|------|
| Scheduled dose reminders | ✅ |
| Titration completion alerts | ✅ |
| Missed dose notifications | ✅ |
| Badge management | ✅ |
| Deep linking to entry screens | ✅ |
| Action handling (log, snooze, skip) | ✅ |

---

### ✅ 8. Analytics (Medication)

| Requirement | Done |
|-------------|------|
| Concentration timeline chart (interactive) | ✅ |
| Time period selection (7d, 30d, 90d, 1y) | ✅ |
| Dose markers on timeline | ✅ |
| Future projections | ✅ |
| Adherence insights | ✅ |
| Streak tracking | ✅ |

---

### ✅ 9. CloudKit Sync

| Requirement | Done |
|-------------|------|
| Automatic iCloud synchronization | ✅ |
| Real-time sync status monitoring | ✅ |
| Graceful offline-first fallback | ✅ |
| Multi-device support | ✅ |

---

### ✅ 10. Food Database Infrastructure

| Requirement | Done |
|-------------|------|
| Food and FoodEntry SwiftData models | ✅ |
| 1.7M+ foods from USDA + Open Food Facts | ✅ |
| SQLite FTS5 full-text search | ✅ |
| Barcode column with index | ✅ |
| Offline-first (entire database bundled) | ✅ |
| FoodService orchestrating search | ✅ |
| LocalFoodDatabase service | ✅ |
| OpenFoodFactsService API client | ✅ |
| MealLogService for CRUD | ✅ |

---

### 🔨 11. Meal Logging UI

| Requirement | Done |
|-------------|------|
| FoodSearchView - search with results list | |
| FoodDetailView - nutrition facts, serving adjustment | |
| MealLogView - today's meals by section | |
| AddFoodSheet - quick add modal | |
| Four meal sections (breakfast, lunch, dinner, snacks) | |
| Serving size input with unit conversion | |
| Edit and delete logged entries | |

---

### 📋 12. User Model Extension (Nutrition Goals)

| Requirement | Done |
|-------------|------|
| Daily calorie goal field | |
| Daily protein goal field | |
| Daily carb goal field | |
| Daily fat goal field | |
| FoodEntry relationship on User | |

---

### 📋 13. Tab Navigation Update

| Requirement | Done |
|-------------|------|
| Update tab structure for nutrition focus | |
| "+" button opens food/dose picker | |
| Combined history view (meals + doses) | |

---

### 📋 14. Macro Goals & Daily Tracking

| Requirement | Done |
|-------------|------|
| Goal configuration UI (calories, protein, carbs, fat) | |
| Progress rings/bars for each macro | |
| Remaining vs consumed display | |
| Color coding for under/over targets | |
| Daily summary on dashboard | |

---

### 📋 15. Protein Preservation Alerts

| Requirement | Done |
|-------------|------|
| Minimum protein threshold based on body weight (1.6g/kg) | |
| ProteinMonitoringService | |
| Evening notification if protein < 80% target | |
| Protein progress ring on dashboard (prominent) | |
| Color-coded severity (green/yellow/red) | |
| High-protein food suggestions | |
| Weekly protein trend analysis | |

---

### 📋 16. HealthKit Integration

| Requirement | Done |
|-------------|------|
| HealthKitService | |
| Request authorization | |
| Sync weight from Apple Health | |
| Sync body fat percentage | |
| Sync steps and active calories | |
| Display weight trend on dashboard | |
| Calculate net calories (consumed - burned) | |

---

### 📋 17. Medication-Nutrition Correlation

| Requirement | Done |
|-------------|------|
| AppetiteEntry model (hunger, cravings, food noise) | |
| Daily appetite check-in UI | |
| NutritionCorrelationEngine | |
| Concentration vs. appetite chart overlay | |
| Food noise reduction timeline | |
| Eating patterns by medication cycle | |
| Optimal eating window calculation | |
| Correlation insights generation | |

---

### 📋 18. Barcode Scanning

| Requirement | Done |
|-------------|------|
| AVFoundation camera integration | |
| Open Food Facts API lookup | |
| Quick-add flow after scan | |
| Handle "not found" gracefully | |

---

### 📋 19. AI Photo to Macros

| Requirement | Done |
|-------------|------|
| Camera capture for food photos | |
| AI vision API integration (identify food items) | |
| Portion size estimation from image | |
| Macro estimation based on identified foods | |
| User confirmation/adjustment before logging | |
| Fallback to manual search if low confidence | |

---

### 📋 20. Unified Dashboard

| Requirement | Done |
|-------------|------|
| Concentration card (medication users) | |
| Today's nutrition summary | |
| Prominent protein progress ring | |
| Appetite/food noise indicator | |
| Weight trend from HealthKit | |

---

### 📋 21. Combined Calendar View

| Requirement | Done |
|-------------|------|
| Dose markers (existing) | |
| Meal indicators (breakfast/lunch/dinner icons) | |
| Protein status dots (green/yellow/red) | |
| Weight data points | |

---

### 📋 22. Unified Analytics

| Requirement | Done |
|-------------|------|
| Nutrition trends (calories, protein over time) | |
| Concentration vs. daily calories chart | |
| Food noise by day post-dose chart | |
| Protein intake vs. weight change chart | |

---

### 📋 23. Export & Reporting

| Requirement | Done |
|-------------|------|
| PDF report generation | |
| CSV export | |
| Combined medication + nutrition summary | |
| Weight progress section | |

---

### 📋 24. User Onboarding (Nutrition Path)

| Requirement | Done |
|-------------|------|
| Welcome screens with nutrition benefits | |
| Goal selection (weight loss, maintenance, muscle gain) | |
| Macro target setup | |
| Meal reminder preferences | |
| Optional: Add medication tracking | |

---

### 🔨 25. Subscription Management

| Requirement | Done |
|-------------|------|
| StoreKit 2 integration | |
| Subscription tiers | |
| Paywall UI | |
| Restore purchases | |

---

## Non-Functional Requirements

### Performance
| Metric | Target |
|--------|--------|
| App launch | < 2 seconds |
| Food search | < 100ms |
| Calculation updates | < 50ms |
| Chart rendering (365 entries) | < 500ms |
| Memory usage | < 100MB |

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

| Feature | Competitors | MacroKinetic |
|---------|-------------|--------------|
| Food database | 100K-1M | 1.7M+ with barcodes |
| Pharmacokinetics | Basic estimates | True exponential decay |
| Medication-nutrition insights | None | Correlation engine |
| Protein preservation alerts | None | Yes |
| Offline food search | Limited | Full database offline |
| Reconstitution calculator | None | Yes |
| Split-dose support | None | Yes |

---

## Update History

- 2025-12-20: Consolidated from macro-integration.md and project-prd.md into single sequenced PRD
- 2025-12-19: Initial nutrition infrastructure documentation
