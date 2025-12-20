---
created: 2025-12-19T14:49:57Z
last_updated: 2025-12-20T00:23:53Z
---

# Project Progress

## Current State

- **App Name**: MacroKinetic (rebranded from JabTracker)
- **Branch**: main
- **Last Commit**: 54bffb3 - feat(nutrition): Add food search with 1.7M+ local foods and barcode support
- **Status**: Active development - Nutrition infrastructure (Epic #314/315)

## Strategic Pivot

The app has been rebranded from **JabTracker** (GLP-1 injection tracker) to **MacroKinetic** (comprehensive weight management + nutrition app). Key changes:

- **Primary focus**: Nutrition tracking for all weight management users
- **Secondary focus**: GLP-1 medication management for applicable users
- **Unique differentiator**: Medication-nutrition correlation insights

## Recent Work

### Nutrition Infrastructure (Issue #314) - ~75% Complete
- Food and FoodEntry SwiftData models
- FoodService orchestrating search across sources
- LocalFoodDatabase with SQLite FTS5 (1.7M+ foods)
- OpenFoodFactsService for API fallback
- MealLogService for CRUD operations
- Barcode lookup support

### Database Enhancement
- Processed USDA Foundation + SR Legacy data
- Integrated Open Food Facts dump (1.7M branded products)
- Added barcode column with index for fast lookups
- Database size: 382 MB with full offline support

## Completed Major Features

### Core Infrastructure
- SwiftData + CloudKit integration with graceful fallback
- Sign in with Apple authentication
- Biometric authentication (Face ID/Touch ID)
- Keychain credential storage

### Nutrition Tracking (New)
- 1.7M+ food database (USDA + Open Food Facts)
- SQLite FTS5 full-text search
- Barcode scanning support
- MealSection enum (breakfast, lunch, dinner, snacks)
- FoodEntry model with macro calculations

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

1. **Epic #314/315** - Complete nutrition infrastructure
   - Meal logging UI
   - Macro goals and daily tracking
   - Food search integration in UI
2. **Protein Preservation** - Alerts for low protein intake
3. **Medication-Nutrition Correlation** - Unique differentiator feature
4. **TestFlight Release** - Prepare for beta testing

## Test Coverage

- **Unit Tests**: 144+ test files in JabTrackerTests/
- **E2E Tests**: 60+ test files in JabTrackerUITests/
- **Coverage Policy**: 5-tier system (90% for business logic down to 42% for framework integration)

## Update History

- 2025-12-20T00:23:53Z: Rebranded to MacroKinetic, documented nutrition infrastructure progress
- 2025-12-19T14:49:57Z: Initial context creation - documented current state after Issue #260 completion
