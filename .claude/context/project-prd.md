---
created: 2024-01-15T00:00:00Z
last_updated: 2025-12-19T15:10:06Z
---

# JabTracker Product Requirements Document

## 1. Executive Summary

### 1.1 Product Overview

JabTracker is a native iOS application for tracking injectable GLP-1 medication doses and monitoring drug concentration levels using pharmacokinetic modeling. It helps patients manage their medication schedules, track adherence, and understand their medication's effects over time.

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
| Testing | Swift Testing + XCUITest |
| Build Tools | XcodeGen, SwiftLint, xcbeautify |

### 1.3 Key Features

| Feature | Status |
|---------|--------|
| Authentication (Sign in with Apple, Biometrics) | ✅ Complete |
| User Onboarding Flow | ✅ Complete |
| Medication Profile Management | ✅ Complete |
| Dose Tracking & History | ✅ Complete |
| Pharmacokinetics Engine | ✅ Complete |
| Analytics & Charts | ✅ Complete |
| Dose Scheduling | ✅ Complete |
| Notifications | ✅ Complete |
| CloudKit Sync | ✅ Complete |
| Subscription Management | 🔄 In Progress |
| Apple Watch App | 📋 Planned |
| PDF Reports | 📋 Planned |

## 2. Functional Requirements

### 2.1 User Authentication ✅

**Status**: Complete

- **Sign in with Apple** - Sole authentication method
- **Biometric Security** - Face ID/Touch ID for app access
- **Keychain Storage** - Secure credential persistence
- **Session Management** - Persistent authentication state

### 2.2 User Onboarding ✅

**Status**: Complete

1. Welcome screens with app benefits and pharmacokinetics explanation
2. Medication selection wizard (4 GLP-1 medications)
3. Initial dose entry with injection site selection
4. Schedule setup (weekly, split-dose, custom patterns)
5. Notification and HealthKit permissions
6. Subscription screen (placeholder)

### 2.3 Medication Management ✅

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

### 2.4 Dose Tracking ✅

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

### 2.5 Pharmacokinetics Engine ✅

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

### 2.6 Analytics & Visualization ✅

**Status**: Complete

#### Charts (Swift Charts)
- **ConcentrationTimelineChart**: Interactive line chart with zoom/pan
- Dose markers on timeline
- Time period selection (7d, 30d, 90d, 1y)
- Future projections

#### Insights
- Adherence score and trends
- Streak tracking
- Missed dose pattern analysis
- Personalized recommendations

#### Data Processing
- ChartDataProcessor for data transformation
- Filtering and aggregation extensions
- Interpolation for smooth curves
- Performance-optimized for 365+ doses

### 2.7 Dose Scheduling ✅

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

### 2.8 Notifications ✅

**Status**: Complete

#### Notification Types
- Scheduled dose reminders
- Titration completion alerts
- Missed dose notifications

#### Features
- NotificationService with background refresh
- Badge management for pending doses
- Deep linking to dose entry
- Action handling (log, snooze, skip)
- UserDefaults persistence for settings

### 2.9 Data Management ✅

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
| Calculation updates | < 50ms |
| Chart rendering (365 doses) | < 500ms |
| Memory usage | < 100MB |

### 3.2 Security & Privacy

- SwiftData encryption enabled
- Keychain for credential storage
- Face ID/Touch ID protection
- On-device processing preference
- Privacy nutrition labels

### 3.3 Accessibility

- VoiceOver support with dynamic descriptions
- Dynamic Type scaling
- High Contrast mode support
- Reduce Motion compatibility
- 44x44pt minimum touch targets

### 3.4 Testing

| Type | Coverage |
|------|----------|
| Unit Tests | 144 test files |
| E2E Tests | 60 test files |
| Business Logic | 90% minimum |
| View Models | 85% minimum |
| Framework Integration | 42% minimum |

## 4. User Interface

### 4.1 Navigation Structure

```
TabView
├── Dashboard (Home)
│   ├── ConcentrationCard
│   ├── Next Dose
│   └── Quick Actions
├── Add (+) → QuickDoseSheet
├── History
│   ├── Calendar View
│   └── List View
├── Analytics
│   ├── Concentration Chart
│   └── Adherence Insights
└── Settings
    ├── Profile
    ├── Medications
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

### Phase 1: Polish & Release
- Complete subscription integration
- App Store submission preparation
- TestFlight beta testing

### Phase 2: Platform Extensions
- Apple Watch companion app
- iOS Widgets
- iPad optimizations

### Phase 3: Advanced Features
- PDF export for providers
- Siri Shortcuts
- HealthKit write integration
- Educational content

## 6. Success Metrics

### User Engagement
- Daily active users
- Dose logging compliance rate
- Feature adoption rates

### Clinical Value
- Medication adherence improvement
- Steady-state achievement rate
- User-reported outcomes

### Technical Performance
- Crash-free rate > 99.5%
- App Store rating > 4.5

## 7. Compliance Considerations

- FDA classification awareness (wellness vs medical device)
- HIPAA compliance for health data
- App Tracking Transparency
- Privacy nutrition labels

## Update History

- 2025-12-19T15:10:06Z: Major revision - updated all sections to reflect current implementation status, removed timeline estimates, modernized code references
- 2024-01-15: Initial PRD creation
