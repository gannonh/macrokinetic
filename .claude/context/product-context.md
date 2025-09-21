---
created: 2025-09-11T16:54:56Z
last_updated: 2025-09-21T20:59:02Z
version: 1.4
author: Claude Code PM System
---

# Product Context

## Product Overview
JabTracker is a native iOS application for tracking injectable GLP-1 medication doses (Ozempic, Wegovy, Mounjaro, Trulicity) and monitoring drug concentration levels using pharmacokinetic modeling. The app helps patients maintain proper medication adherence while providing healthcare providers with detailed treatment data.

## Target Users

### Primary Users
- **Weight Management Patients**: Using GLP-1 medications for obesity treatment
- **Age Range**: 25-65 years old
- **Tech Comfort**: Moderate to high iOS device familiarity

### Secondary Users
- **Healthcare Providers**: Endocrinologists, primary care physicians
- **Caregivers**: Family members helping with medication management
- **Clinical Researchers**: Studying medication adherence patterns

## Core User Needs

### Patient Pain Points
- **Medication Adherence**: Difficulty remembering doses and timing
- **Dose Tracking**: Manual logging is cumbersome and error-prone
- **Provider Communication**: Hard to communicate adherence patterns to doctors
- **Concentration Understanding**: No visibility into drug levels in body
- **Dose Titration**: Confusion about when and how to increase doses

### Healthcare Provider Needs
- **Objective Data**: Reliable adherence metrics beyond patient self-reporting
- **Visual Reports**: Easy-to-interpret charts and summaries
- **Export Capability**: Data export for medical records
- **Medication History**: Complete dose history with timestamps

## Key Use Cases

### Daily Usage Patterns
1. **Dose Logging**: Quick entry after injection (30 seconds)
2. **Concentration Monitoring**: Check current drug levels (1-2x daily)
3. **Adherence Tracking**: Review missed doses and streaks
4. **Reminder Management**: Set and respond to dose notifications

### Weekly/Monthly Patterns
1. **Dose Escalation**: Follow titration schedule with guidance
2. **Provider Visits**: Generate reports for appointments
3. **Trend Analysis**: Review adherence patterns and insights
4. **Refill Planning**: Track remaining doses and schedule refills

### Setup and Configuration
1. **Onboarding**: Initial medication selection and profile setup
2. **Authentication**: Sign in with Apple and biometric setup
3. **Permissions**: HealthKit and notification authorization
4. **Preferences**: Injection sites, reminder times, units

## Supported Medications

### GLP-1 Receptor Agonists
- **Semaglutide**: Ozempic, Wegovy (weekly injections)
- **Tirzepatide**: Mounjaro, Zepbound (weekly injections)
- **Liraglutide**: Victoza, Saxenda (daily injections)
- **Dulaglutide**: Trulicity (weekly injections)

### Medication Properties
- **Half-life tracking**: Accurate pharmacokinetic modeling
- **Dose ranges**: Brand-specific available doses
- **Frequency patterns**: Weekly vs daily injection schedules
- **Escalation protocols**: Standard dose titration timelines

## Core Functionality

### Medication Management
- Multiple medication profile support
- Brand and generic name tracking
- Current dose and escalation schedule
- Injection site preferences and rotation
- Start date and refill tracking

### Dose Tracking ✅
- ✅ **Quick one-tap dose entry** - Implemented via "+" tab button with QuickDoseSheet
- ✅ **Manual entry with full details** - Complete form with time, site, notes (photos deferred)
- ✅ **Missed dose handling and rescheduling** - Skip dose functionality
- ✅ **Historical dose review and editing** - Complete history list with swipe actions
- ✅ **Calendar view with dose indicators** - Full calendar integration with monthly navigation, dose indicators, and statistics

### Pharmacokinetic Monitoring ✅
- ✅ **Real-time concentration calculations** - Complete PharmacokineticsEngine implementation
- ✅ **Peak and trough level tracking** - ConcentrationCard dashboard display
- ✅ **Steady-state progress monitoring** - Progress percentage with visual indicators
- ✅ **Therapeutic range indicators** - Color-coded concentration displays
- ✅ **Concentration projections** - Future level calculations

### Analytics and Insights
- ✅ **Adherence percentage and streaks** - Monthly statistics with real-time calculations
- Concentration timeline charts
- Dose consistency patterns
- Comparative analysis with typical patterns
- Milestone achievements and notifications

## Value Propositions

### For Patients
- **Better Adherence**: Visual feedback and reminders improve compliance
- **Understanding**: Clear visualization of how medication works in body
- **Confidence**: Data-driven insights about treatment progress
- **Communication**: Professional reports for provider discussions
- **Convenience**: Quick, easy dose logging with minimal friction

### for Healthcare Providers
- **Objective Data**: Reliable adherence metrics beyond patient reporting
- **Clinical Insights**: Pharmacokinetic data for treatment optimization
- **Time Savings**: Pre-generated reports reduce appointment preparation
- **Better Outcomes**: Improved adherence leads to better patient outcomes
- **Documentation**: Complete medication history for medical records

## Success Metrics

### User Engagement
- Daily dose logging rate (target: 90%+)
- App retention (30-day: 80%, 90-day: 60%)
- Feature adoption (analytics: 70%, exports: 40%)
- Session frequency (4-5x per week)

### Clinical Value
- Medication adherence improvement (baseline vs 3-month)
- Steady-state achievement tracking
- Provider report generation and usage
- User-reported outcome improvements

### Business Metrics
- App Store rating (target: 4.5+)
- Premium subscription conversion (target: 15%)
- Healthcare provider referrals
- Clinical study participation rates

## Product Insights from Calendar Integration (Issue #42)
- **Calendar integration significantly enhances dose tracking user experience** - Users can visualize their adherence patterns over time with clear monthly views
- **Month navigation and dose indicators provide clear adherence visualization** - Visual timeline helps users understand their medication consistency
- **Statistics integration creates valuable insights** - Monthly adherence rates, streak tracking, and dose distribution provide actionable healthcare data
- **Seamless History tab integration maintains existing user workflow patterns** - Segmented control allows users to switch between list and calendar views without disrupting established habits

## Product Insights from PK Engine Integration (Issue #45)
- **Real-time pharmacokinetic calculations provide significant user value over basic dose tracking** - Concentration monitoring transforms the app from simple logging to medical insights
- **Dashboard integration makes concentration data actionable for users** - ConcentrationCard displays current levels prominently for daily decision-making
- **Comprehensive dose entry integration creates seamless user workflow** - Automatic recalculation after dose entry provides immediate feedback
- **Medical accuracy requirements drive comprehensive testing approaches** - 8 E2E acceptance tests ensure calculation reliability for healthcare applications

## Update History
- 2025-09-21T20:59:02Z: Epic complete! Updated all core feature status - dose tracking and pharmacokinetics fully implemented
- 2025-09-16T22:39:56Z: Added calendar integration insights and updated dose tracking/analytics feature status
- 2025-09-12T16:35:25Z: Updated dose tracking feature status - quick dose entry now implemented