# MacroKinetic

## Current State (Updated: 2026-01-05)

**Shipped:** v0.5.0 Navigation Refinement (2026-01-05)
**Status:** Development / TestFlight
**Codebase:** ~59,400 lines Swift, SwiftUI/SwiftData, iOS 17+

**v0.5.0 Delivered:**
- Consolidated GLP-1 features (analytics + medications) into unified section under More tab
- Promoted Strategy to top-level tab with target icon and check-in badge
- Floating 44pt Add button overlay replacing tab item for visual prominence
- Extracted reusable section components (ConcentrationSection, AdherenceSection, HistorySection) with TDD
- Standardized navigation bar styling (inline titles, circle buttons) across app

## Next Milestone Goals

**Vision:** See PRD for planned features - Protein Alerts, Analytics, or Subscription

**Candidates:**
- Protein Preservation Alerts - Minimum protein thresholds and notifications
- Analytics Dashboard - Weight trends, nutrition insights, medication correlation
- Subscription Management - StoreKit 2 integration and paywall
- Recipe Builder - Combine foods into calculated recipes

## Vision

MacroKinetic is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management. The app serves anyone on a weight loss or nutrition journey, with specialized features for GLP-1 medication users wanting integrated medication + nutrition tracking.

See [project-prd.md](./project-prd.md) for complete product requirements and feature status.

## Problem

Weight management apps either focus purely on calorie counting (ignoring medication effects) or medication tracking (ignoring nutrition). Users on GLP-1 medications experience appetite changes that affect eating patterns, but no app connects these dots. Additionally, food databases are often inaccurate, and users need the ability to create and manage custom foods for their specific needs.

## Success Criteria

How we know this worked:

- [x] Custom food creation and barcode scanning for personalized entries
- [x] Complete nutrition tracking with macro goals and progress tracking
- [ ] GLP-1 medication tracking with pharmacokinetics modeling
- [ ] Medication-nutrition correlation insights
- [x] CloudKit sync across all user devices
- [x] Offline-first functionality

## Scope

### Completed (v0.1.0)
- Custom food creation and management
- Barcode scanning for quick food lookup
- Food Library with "My Foods" section

### Future Milestones (see PRD)
- Macro Goals & Daily Tracking
- Protein Preservation Alerts
- HealthKit Integration
- Medication-Nutrition Correlation
- Unified Dashboard & Analytics

### Not Building
- Recipe builder (combining multiple foods into calculated recipe) - deferred
- Social features / sharing custom foods
- Micronutrient tracking beyond basic macros

## Context

**Current State:** Brownfield — MacroKinetic has complete food database infrastructure (1.7M+ foods), meal logging UI, medication tracking, dose scheduling, pharmacokinetics engine, CloudKit sync, and now custom foods with barcode scanning.

**Existing Architecture:**
- `Food` model for database foods (SQLite FTS5)
- `CustomFoodService` for user-created foods (SwiftData + CloudKit)
- `FoodEntry` model for logged meals (SwiftData + CloudKit)
- `FoodService` orchestrates search across sources
- Complete medication tracking subsystem
- MVVM architecture with @Observable ViewModels

## Constraints

- **CloudKit Sync**: All user data must sync across devices via iCloud
- **Offline-First**: Full functionality without network; sync when available
- **MVVM Architecture**: @Observable ViewModels, service layer conventions
- **iOS 17+**: Modern SwiftUI and SwiftData APIs
- **Testing**: 85%+ coverage for business logic and view models

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Data Model | Reuse `Food` model with source = .userCreated | Existing infrastructure supports custom foods without new model |
| Food Database | SQLite FTS5 with 1.7M+ foods | Fast full-text search, offline-first, includes barcodes |
| Medication Modeling | Exponential decay pharmacokinetics | Accurate concentration tracking for GLP-1 medications |
| Barcode Scanning | AVFoundation with debouncing | Native performance, 2-second debounce prevents duplicates |

## Open Questions

- [ ] Optimal approach for medication-nutrition correlation engine
- [ ] HealthKit integration scope and permissions flow
- [ ] Subscription tier structure and paywall placement

---
*Initialized: 2025-12-22*
*v0.1.0 Shipped: 2025-12-24*
