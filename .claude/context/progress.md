---
created: 2025-12-19T14:49:57Z
last_updated: 2025-12-20T17:50:53Z
---

# Project Progress

## Current State

- **App Name**: MacroKinetic (rebranded from JabTracker)
- **Branch**: feat/314-core-nutrition-infrastructure
- **Last Commit**: feat(nutrition): Add shortcuts sheet and enhanced food detail UI
- **Status**: Active development - Nutrition UI (Issue #314 - Phase 5)

## Strategic Pivot

The app has been rebranded from **JabTracker** (GLP-1 injection tracker) to **MacroKinetic** (comprehensive weight management + nutrition app). Key changes:

- **Primary focus**: Nutrition tracking for all weight management users
- **Secondary focus**: GLP-1 medication management for applicable users
- **Unique differentiator**: Medication-nutrition correlation insights

## Recent Work

### Nutrition Infrastructure (Issue #314) - ~90% Complete

#### Data Layer (Complete)
- Food and FoodEntry SwiftData models with CloudKit compatibility
- FoodService orchestrating search across local database + API
- LocalFoodDatabase with SQLite FTS5 (1.7M+ foods)
- OpenFoodFactsService for API fallback
- MealLogService for CRUD operations
- Barcode lookup support

#### UI Components (Complete)
- **ShortcutsSheet** - Quick action buttons replacing confirmation dialog
- **FoodSearchSheet** - Method tabs, categorized results (History/Custom/Common/Branded)
- **FoodDetailSheet** - Macro display with circular progress rings
- **ServingInputView** - Advanced input with unit conversion (g, oz, item, lb)
- **Target macro mode** - Enter desired cal/P/F/C → calculate quantity needed
- **CircularProgressRing** - Reusable macro visualization component

#### Tab Navigation Restructure
- Tab enum for type-safe navigation
- Renamed Home → Dashboard
- New Food Log tab for today's meals
- Combined Analytics + History → Shots tab with 3-segment picker
- New More overflow tab containing Settings

### Database Enhancement
- Processed USDA Foundation + SR Legacy data
- Integrated Open Food Facts dump (1.7M branded products)
- Added barcode column with index for fast lookups
- Added serving_description column for parsed serving options
- Database size: 382 MB with full offline support

## Completed Major Features

### Core Infrastructure
- SwiftData + CloudKit integration with graceful fallback
- Sign in with Apple authentication
- Biometric authentication (Face ID/Touch ID)
- Keychain credential storage

### Nutrition Tracking
- 1.7M+ food database (USDA + Open Food Facts)
- SQLite FTS5 full-text search
- Barcode scanning support
- MealSection enum (breakfast, lunch, dinner, snacks)
- FoodEntry model with macro calculations
- ShortcutsSheet with quick action buttons
- FoodSearchSheet with categorized results
- FoodDetailSheet with macro rings and advanced serving input
- Unit conversion (g, oz, item, lb) with quantity preservation
- Target macro mode for reverse calculation

### Medication Management
- Full CRUD operations for medication profiles
- Reconstitution calculator
- Dose escalation system with timeline UI
- Brand-aware dose validation

### Dose Tracking
- Quick dose entry via "+" tab button
- Calendar view with dose indicators
- Dose history with filtering
- Statistics engine with adherence rates

### Pharmacokinetics Engine
- Exponential decay concentration modeling
- Real-time concentration calculations
- Steady-state progress tracking
- ConcentrationCard dashboard integration

### Analytics System
- AnalyticsService for cross-model coordination
- ChartDataProcessor with Swift Charts integration
- ConcentrationTimelineChart with zoom/pan
- AdherenceInsights visualization

### Dose Scheduling
- DoseSchedule and ScheduledDose SwiftData models
- ScheduleService with projections, modifications, adherence tracking
- NotificationService with background refresh
- Onboarding schedule setup integration
- Calendar integration for scheduled doses
- Notification UI configuration

## Current Priorities

1. **Issue #314 Phase 5** - Complete nutrition integration
   - E2E test: Search food → log meal → view daily totals
   - Dashboard NutritionSummaryCard integration
   - Daily macro totals display
   - Performance testing
2. **Protein Preservation** - Alerts for low protein intake
3. **Medication-Nutrition Correlation** - Unique differentiator feature
4. **TestFlight Release** - Prepare for beta testing

## Test Coverage

- **Unit Tests**: 144+ test files in JabTrackerTests/
- **E2E Tests**: 60+ test files in JabTrackerUITests/
- **Coverage Policy**: 5-tier system (90% for business logic down to 42% for framework integration)

## Update History

- 2025-12-20T17:50:53Z: Updated for Issue #314 - ShortcutsSheet, FoodSearchSheet, FoodDetailSheet, tab navigation restructure
- 2025-12-20T00:23:53Z: Rebranded to MacroKinetic, documented nutrition infrastructure progress
- 2025-12-19T14:49:57Z: Initial context creation - documented current state after Issue #260 completion
