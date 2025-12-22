---
created: 2025-12-19T14:51:00Z
last_updated: 2025-12-20T00:22:10Z
---

# Project Context

## Overview

**MacroKinetic** is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management. It features a 1.7M+ food database with barcode scanning, macro tracking, and for medication users, a unique pharmacokinetic engine that correlates drug concentration levels with eating patterns.

The name reflects the app's dual focus:
- **Macro** - Macronutrient tracking for weight management
- **Kinetic** - Pharmacokinetics modeling for medication users

## Target Users

### Primary: Weight Management Users
- Anyone on a weight loss or nutrition journey
- Users seeking data-driven macro tracking
- Health-conscious individuals wanting food logging

### Secondary: GLP-1 Medication Users
- Patients taking GLP-1 medications (semaglutide, tirzepatide, liraglutide, dulaglutide)
- Users who want medication + nutrition integration
- Patients seeking to understand medication effects on appetite

### Tertiary: Data-Driven Health Enthusiasts
- Users who want insights, not just logging
- People interested in correlating nutrition with medication effects
- Those who prefer science-backed, precision health tools

## Core Features

### Nutrition Tracking (Primary)
- **Food Search**: 1.7M+ foods from USDA and Open Food Facts
- **Barcode Scanning**: Instant lookup for packaged foods
- **Meal Logging**: Breakfast, lunch, dinner, and snacks sections
- **Macro Goals**: Daily targets for calories, protein, carbs, fat
- **Protein Preservation Alerts**: Warnings when protein intake is too low

### Medication Management (For GLP-1 Users)
- Support for 4 GLP-1 medications with brand variants
- Dose escalation tracking and scheduling
- Reconstitution calculator for compounded medications
- Injection site preferences

### Pharmacokinetics Dashboard (For GLP-1 Users)
- Real-time concentration calculations using exponential decay
- Peak, trough, and current level displays
- Steady-state progress indicator
- Interactive concentration timeline charts

### Medication-Nutrition Correlation (Unique Differentiator)
- Track appetite changes relative to medication concentration
- Insights on eating patterns during medication cycles
- Correlation between drug levels and food intake

### Analytics & Insights
- Daily and weekly nutrition summaries
- Adherence rate calculations (medication users)
- Streak tracking for consistent logging
- Personalized insights based on patterns
- Export capabilities

### Authentication
- Sign in with Apple (sole authentication method)
- Biometric authentication (Face ID/Touch ID) for app access
- Secure Keychain storage for credentials

### Notifications
- Meal logging reminders
- Scheduled dose reminders (medication users)
- Protein preservation alerts
- Badge management

## Technical Highlights

- **Offline-First**: 1.7M+ foods available without internet
- **CloudKit Sync**: Automatic iCloud synchronization across devices
- **Privacy-Focused**: On-device processing, minimal data collection
- **Accessible**: VoiceOver support, Dynamic Type, high contrast

## App Structure

### Tab Navigation
1. **Dashboard** - Daily overview, macro progress, quick actions
2. **Add (+)** - Quick food or dose entry sheet
3. **History** - Calendar and list views of meals and doses
4. **Analytics** - Charts, trends, and insights
5. **Settings** - Profile, goals, medications, preferences

### Key User Flows

#### Nutrition-Focused Users
1. **Onboarding** - Welcome, goal setup, macro targets, permissions
2. **Quick Log** - Search food, scan barcode, log meal
3. **Daily Review** - Check macro progress, review meals
4. **Weekly Insights** - View trends, adjust goals

#### Medication Users (Additional Flows)
1. **Medication Setup** - Select medication, initial dose, schedule setup
2. **Quick Dose** - Tap +, confirm medication/dose, save
3. **Concentration Check** - View PK dashboard, understand levels
4. **Correlation Insights** - Review nutrition-medication patterns

## Competitive Positioning

| Feature | Competitors | MacroKinetic |
|---------|-------------|--------------|
| Food database | Varies (100K-1M) | 1.7M+ with barcodes |
| Pharmacokinetics modeling | Basic estimates | True exponential decay |
| Medication-nutrition insights | None | Correlation engine |
| Protein preservation alerts | None | Yes (muscle loss prevention) |
| Offline food search | Limited | Full database offline |

## Business Context

- **Platform**: iOS 17.0+ (native Swift/SwiftUI)
- **Monetization**: Subscription model (StoreKit integration)
- **Distribution**: App Store (preparing for TestFlight beta)
- **Compliance**: Healthcare app considerations for FDA guidelines

## Implementation Roadmap

See Epic #315 for detailed implementation phases:
- Phase 1: Core nutrition infrastructure (food database, search, logging)
- Phase 2: Macro goals and daily tracking
- Phase 3: Protein preservation alerts
- Phase 4: Medication-nutrition correlation
- Phase 5: HealthKit weight/activity sync

## Update History

- 2025-12-19T21:30:00Z: Rebranded from JabTracker to MacroKinetic, expanded scope to comprehensive weight management + nutrition app
- 2025-12-19T14:51:00Z: Initial context creation
