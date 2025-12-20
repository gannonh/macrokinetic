---
created: 2024-01-15T00:00:00Z
last_updated: 2025-12-20T00:22:10Z
---

# MacroKinetic Product Requirements Document

## 1. Executive Summary

### 1.1 Product Overview

MacroKinetic is a comprehensive iOS weight management application combining precision nutrition tracking with optional GLP-1 medication management. It empowers users to achieve their health goals through:

- **Macro Tracking**: 1.7M+ food database with barcode scanning for effortless logging
- **Pharmacokinetics**: Unique drug concentration modeling for medication users
- **Correlation Insights**: Understand how medication affects eating patterns

The app serves both general nutrition users and GLP-1 medication patients, with medication features as an advanced layer for applicable users.

### 1.2 Technology Stack

| Component | Technology |
|-----------|------------|
| Platform | iOS 17.0+ |
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Data Persistence | SwiftData |
| Cloud Sync | CloudKit |
| Authentication | Sign in with Apple |
| Charts | Swift Charts |
| Notifications | User Notifications |
| Health | HealthKit |
| Food Database | SQLite FTS5 (1.7M+ foods) |
| Testing | Swift Testing + XCUITest |
| Build Tools | XcodeGen, SwiftLint, xcbeautify |

### 1.3 Key Features

| Feature | Status |
|---------|--------|
| Authentication (Sign in with Apple, Biometrics) | Complete |
| User Onboarding Flow | Complete |
| Food Database (1.7M+ foods) | Complete |
| Food Search (FTS5 + barcode) | Complete |
| Meal Logging | In Progress |
| Macro Goals & Daily Tracking | Planned |
| Protein Preservation Alerts | Planned |
| Medication Profile Management | Complete |
| Dose Tracking & History | Complete |
| Pharmacokinetics Engine | Complete |
| Medication-Nutrition Correlation | Planned |
| Analytics & Charts | Complete |
| Dose Scheduling | Complete |
| Notifications | Complete |
| CloudKit Sync | Complete |
| HealthKit Integration | Planned |
| Subscription Management | In Progress |

## 2. Functional Requirements

### 2.1 User Authentication

**Status**: Complete

- **Sign in with Apple** - Sole authentication method
- **Biometric Security** - Face ID/Touch ID for app access
- **Keychain Storage** - Secure credential persistence
- **Session Management** - Persistent authentication state

### 2.2 User Onboarding

**Status**: Complete (nutrition path planned)

#### Current Flow (Medication Users)
1. Welcome screens with app benefits and pharmacokinetics explanation
2. Medication selection wizard (4 GLP-1 medications)
3. Initial dose entry with injection site selection
4. Schedule setup (weekly, split-dose, custom patterns)
5. Notification and HealthKit permissions
6. Subscription screen (placeholder)

#### Planned Flow (Nutrition Users)
1. Welcome screens with nutrition tracking benefits
2. Goal selection (weight loss, maintenance, muscle gain)
3. Macro target setup (calories, protein, carbs, fat)
4. Notification preferences for meal reminders
5. Optional: Add medication tracking

### 2.3 Nutrition Tracking

**Status**: In Progress (Epic #315)

#### Food Database
- 1.7M+ foods from USDA and Open Food Facts
- SQLite FTS5 full-text search for fast queries
- Offline-first: entire database bundled in app
- Sources: USDA Foundation, SR Legacy, Open Food Facts

#### Food Search
- Real-time search with prefix matching
- Barcode scanning for packaged foods
- Recent foods for quick access
- User-created custom foods

#### Meal Logging
- Four meal sections: Breakfast, Lunch, Dinner, Snacks
- Serving size in grams with unit conversion
- Quick log from recent/favorite foods
- Edit and delete logged entries
- Notes for each entry

### 2.4 Macro Goals & Daily Tracking

**Status**: Planned (Epic #315 Phase 2)

#### Goal Configuration
- Daily calorie target
- Macro breakdown (protein, carbs, fat percentages or grams)
- Fiber target (optional)
- Goal presets for common diets

#### Daily Tracking
- Progress rings/bars for each macro
- Remaining vs consumed display
- Color coding for under/over targets
- Daily summary notifications

### 2.5 Protein Preservation Alerts

**Status**: Planned (Epic #315 Phase 3)

#### Purpose
Prevent muscle loss during weight loss by ensuring adequate protein intake, especially important for GLP-1 medication users who may experience reduced appetite.

#### Features
- Minimum protein threshold based on body weight
- Alerts when daily protein is tracking below target
- Meal suggestions to increase protein
- Weekly protein trend analysis

### 2.6 Medication Management

**Status**: Complete

#### Supported Medications

| Generic | Brands | Schedule |
|---------|--------|----------|
| Semaglutide | Ozempic, Wegovy, Rybelsus | Weekly |
| Tirzepatide | Mounjaro, Zepbound | Weekly |
| Liraglutide | Victoza, Saxenda | Daily |
| Dulaglutide | Trulicity | Weekly |

#### Medication Profile Features
- Multiple medication profiles per user
- Brand-aware dose validation
- Dose escalation tracking (titration)
- Reconstitution calculator for compounded meds
- Injection site preferences
- Start date and refill tracking

### 2.7 Dose Tracking

**Status**: Complete

#### Dose Entry
- **Quick Add**: One-tap via tab bar "+" button
- **Manual Entry**: Date/time picker, dose amount, injection site, notes
- **Missed Dose Handling**: Mark as skipped, reschedule, smart recommendations

#### Dose History
- Calendar view with dose indicators
- List view with search and filtering
- Edit past entries
- Swipe actions (edit/delete)
- Statistics (adherence rates, streaks)

### 2.8 Pharmacokinetics Engine

**Status**: Complete

#### Calculations
- Exponential decay concentration modeling
- Medication-specific half-life values
- Steady-state progress tracking
- Peak, trough, and current level calculations

#### Dashboard Display
- ConcentrationCard with real-time levels
- Therapeutic range indicators
- Time to next dose
- Steady-state percentage

### 2.9 Medication-Nutrition Correlation

**Status**: Planned (Epic #315 Phase 4)

#### Purpose
Unique differentiator: correlate drug concentration levels with eating patterns to provide actionable insights.

#### Features
- Appetite tracking (optional daily rating)
- Calorie intake vs drug concentration chart
- Insights: "You tend to eat less on days 2-4 after injection"
- Recommendations for meal timing
- Pattern detection across medication cycles

### 2.10 Analytics & Visualization

**Status**: Complete (nutrition analytics planned)

#### Charts (Swift Charts)
- **ConcentrationTimelineChart**: Interactive line chart with zoom/pan
- **MacroProgressChart**: Daily/weekly macro trends (planned)
- Dose markers on timeline
- Time period selection (7d, 30d, 90d, 1y)
- Future projections

#### Insights
- Daily and weekly nutrition summaries
- Adherence score and trends (medication users)
- Streak tracking for consistent logging
- Missed dose/meal pattern analysis
- Personalized recommendations

#### Data Processing
- ChartDataProcessor for data transformation
- Filtering and aggregation extensions
- Interpolation for smooth curves
- Performance-optimized for 365+ entries

### 2.11 Dose Scheduling

**Status**: Complete

#### Schedule Management
- DoseSchedule and ScheduledDose SwiftData models
- Weekly, split-dose, and custom patterns
- Schedule projection (upcoming doses)
- Pause/resume schedules
- Modification history

#### Titration (Dose Escalation)
- DoseTitration model for tracking increases
- Titration completion workflow
- Confirmation dialogs for safety
- Timeline visualization

### 2.12 Notifications

**Status**: Complete

#### Notification Types
- Meal logging reminders (planned)
- Scheduled dose reminders
- Titration completion alerts
- Protein preservation alerts (planned)
- Missed dose notifications

#### Features
- NotificationService with background refresh
- Badge management for pending actions
- Deep linking to entry screens
- Action handling (log, snooze, skip)
- UserDefaults persistence for settings

### 2.13 HealthKit Integration

**Status**: Planned (Epic #315 Phase 5)

#### Read Access
- Body weight history
- Active energy burned
- Steps and distance

#### Write Access (Future)
- Dietary energy (calories logged)
- Macronutrients

#### Features
- Automatic weight sync
- TDEE estimation from activity
- Goal adjustment suggestions

### 2.14 Data Management

**Status**: Complete

#### CloudKit Sync
- Automatic iCloud synchronization
- Real-time sync status monitoring
- Graceful offline-first fallback
- Multi-device support

#### Data Export (Planned)
- PDF reports for healthcare providers
- CSV export
- HealthKit integration

## 3. Non-Functional Requirements

### 3.1 Performance

| Metric | Target |
|--------|--------|
| App launch | < 2 seconds |
| Food search | < 100ms |
| Calculation updates | < 50ms |
| Chart rendering (365 entries) | < 500ms |
| Memory usage | < 100MB |

### 3.2 Security & Privacy

- SwiftData encryption enabled
- Keychain for credential storage
- Face ID/Touch ID protection
- On-device processing preference
- Privacy nutrition labels
- No third-party analytics

### 3.3 Accessibility

- VoiceOver support with dynamic descriptions
- Dynamic Type scaling
- High Contrast mode support
- Reduce Motion compatibility
- 44x44pt minimum touch targets

### 3.4 Testing

| Type | Coverage |
|------|----------|
| Unit Tests | 144+ test files |
| E2E Tests | 60+ test files |
| Business Logic | 90% minimum |
| View Models | 85% minimum |
| Framework Integration | 42% minimum |

## 4. User Interface

### 4.1 Navigation Structure

```
TabView
├── Dashboard (Home)
│   ├── MacroProgressCard (nutrition users)
│   ├── ConcentrationCard (medication users)
│   ├── Today's Meals
│   └── Quick Actions
├── Add (+) → QuickEntrySheet
│   ├── Log Food
│   └── Log Dose (medication users)
├── History
│   ├── Calendar View (meals + doses)
│   └── List View
├── Analytics
│   ├── Nutrition Charts
│   ├── Concentration Chart (medication users)
│   └── Insights
└── Settings
    ├── Profile & Goals
    ├── Medications (if applicable)
    ├── Notifications
    └── Subscription
```

### 4.2 Design System

- Custom color palette with primary gradients
- SF Symbols for iconography
- Rounded system fonts
- Card-based component design
- Consistent spacing tokens

## 5. Future Roadmap

### Phase 1: Nutrition Foundation (Epic #315)
- Complete meal logging UI
- Macro goals and daily tracking
- Protein preservation alerts
- Medication-nutrition correlation

### Phase 2: Polish & Release
- Complete subscription integration
- App Store submission preparation
- TestFlight beta testing

### Phase 3: Platform Extensions
- Apple Watch companion app
- iOS Widgets (macro progress)
- iPad optimizations

### Phase 4: Advanced Features
- PDF export for providers
- Siri Shortcuts ("Log my lunch")
- HealthKit write integration
- Educational content
- AI meal suggestions

## 6. Success Metrics

### User Engagement
- Daily active users
- Meals logged per day
- Food search usage
- Barcode scan adoption

### Nutrition Goals
- Users meeting daily protein targets
- Macro goal adherence rate
- Streak lengths for consistent logging

### Medication Users
- Dose logging compliance rate
- Steady-state achievement rate
- Correlation insight engagement

### Technical Performance
- Crash-free rate > 99.5%
- App Store rating > 4.5
- Search latency p95 < 100ms

## 7. Compliance Considerations

- FDA classification awareness (wellness vs medical device)
- HIPAA compliance for health data
- App Tracking Transparency
- Privacy nutrition labels
- Medical disclaimer for pharmacokinetics

## Update History

- 2025-12-20T00:22:10Z: Rebranded from JabTracker to MacroKinetic, added nutrition tracking requirements (2.3-2.5, 2.9, 2.13), updated navigation structure, expanded success metrics
- 2025-12-19T15:10:06Z: Major revision - updated all sections to reflect current implementation status
- 2024-01-15: Initial PRD creation
