---
created: 2025-12-19T14:51:00Z
last_updated: 2025-12-19T14:51:00Z
---

# Project Context

## Overview

**JabTracker** is a native iOS application for tracking GLP-1 medication injections. It helps patients manage their medication schedules, track doses, monitor pharmacokinetic concentration levels, and maintain adherence to their treatment regimen.

## Target Users

- Patients taking GLP-1 medications (semaglutide, tirzepatide, liraglutide, dulaglutide)
- Users who need to track weekly or split-dose injection schedules
- Patients who want to understand their medication concentration levels over time

## Core Features

### Authentication
- Sign in with Apple (sole authentication method)
- Biometric authentication (Face ID/Touch ID) for app access
- Secure Keychain storage for credentials

### Medication Profile Management
- Support for 4 GLP-1 medications with brand variants
- Dose escalation tracking and scheduling
- Reconstitution calculator for compounded medications
- Injection site preferences

### Dose Tracking
- Quick dose entry via tab bar "+" button
- Calendar view with dose indicators and statistics
- Dose history with search and filtering
- Support for weekly and split-dose schedules

### Pharmacokinetics Dashboard
- Real-time concentration calculations using exponential decay
- Peak, trough, and current level displays
- Steady-state progress indicator
- Interactive concentration timeline charts

### Analytics & Insights
- Adherence rate calculations and trends
- Streak tracking for consecutive doses
- Personalized insights based on dose patterns
- Export capabilities for medical records

### Notifications
- Scheduled dose reminders
- Titration completion notifications
- Badge management for pending doses
- Deep linking to dose entry from notifications

## Technical Highlights

- **Offline-First**: Full functionality without internet connection
- **CloudKit Sync**: Automatic iCloud synchronization across devices
- **Privacy-Focused**: On-device processing, minimal data collection
- **Accessible**: VoiceOver support, Dynamic Type, high contrast

## App Structure

### Tab Navigation
1. **Dashboard** - Current status, concentration card, quick actions
2. **Add (+)** - Quick dose entry sheet
3. **History** - Calendar and list views of dose history
4. **Analytics** - Charts, trends, and insights
5. **Settings** - Profile, medications, preferences

### Key User Flows
1. **Onboarding** - Welcome, medication selection, initial dose, schedule setup, permissions
2. **Quick Dose** - Tap +, confirm medication/dose, save
3. **Schedule Management** - View upcoming doses, edit schedules, pause/resume
4. **Review History** - Browse calendar, view dose details, track adherence

## Business Context

- **Platform**: iOS 17.0+ (native Swift/SwiftUI)
- **Monetization**: Subscription model (StoreKit integration)
- **Distribution**: App Store (preparing for TestFlight beta)
- **Compliance**: Healthcare app considerations for FDA guidelines

## Update History

- 2025-12-19T14:51:00Z: Initial context creation
