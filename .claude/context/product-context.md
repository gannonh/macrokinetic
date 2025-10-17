---
created: 2025-09-11T16:54:56Z
last_updated: 2025-10-15T18:06:05Z
version: 2.6
author: Claude Code PM System
---

# Product Context

## Product Overview
JabTracker is a native iOS application for tracking injectable GLP-1 medication doses (Ozempic, Wegovy, Mounjaro, Trulicity) and monitoring drug concentration levels using pharmacokinetic modeling. The app helps patients maintain proper medication adherence while providing healthcare providers with detailed treatment data.

## Why It Exists

### Medical Problem
- **Poor Adherence**: 30-50% of patients struggle with medication adherence
- **Lack of Visibility**: Patients don't understand how medications work in their body
- **Communication Gaps**: Difficult for patients to communicate patterns to providers
- **Dose Confusion**: Complex titration schedules lead to errors
- **Data Fragmentation**: No centralized system for comprehensive medication tracking

### Market Gap
- Existing medication apps lack pharmacokinetic modeling
- No specialized focus on GLP-1 medications and their unique properties
- Generic tracking apps don't address injection-specific needs
- Limited integration with healthcare provider workflows

## Project Scope

### In Scope
- **Core Tracking**: Dose logging, missed dose management, historical review
- **Pharmacokinetics**: Real-time concentration calculations using half-life modeling
- **Visual Analytics**: Charts showing concentration over time, adherence patterns
- **Provider Integration**: PDF reports, data export, clinical documentation
- **User Experience**: Onboarding, authentication, notifications, settings
- **Data Sync**: CloudKit integration with offline-first functionality

### Out of Scope (Phase 1)
- Direct EMR integration
- Telehealth video consultations
- Automatic injection device integration
- Social features and community aspects
- Multi-language support beyond English
- Android version

## Development Philosophy
- **Medical-First**: Safety and accuracy paramount in all decisions
- **User-Centered**: Intuitive design with accessibility as core requirement
- **Quality-Driven**: TDD approach with comprehensive testing
- **Native Excellence**: Leverage iOS platform capabilities fully
- **Privacy-Focused**: On-device processing and minimal data collection

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

## Constraints and Considerations

### Regulatory
- **FDA Compliance**: Ensure classification as wellness app, not medical device
- **Privacy**: HIPAA-like privacy standards, comprehensive data protection
- **Medical Accuracy**: Clinical advisory oversight for pharmacokinetic modeling
- **International**: CE marking and Health Canada requirements for expansion

### Technical
- **iOS Only**: Native iOS development with Swift/SwiftUI
- **Offline-First**: Full functionality without internet connection
- **Security**: Sign in with Apple, biometric authentication, encrypted storage
- **Performance**: Memory usage < 100MB, ProMotion 120Hz support

### Business
- **Timeline**: MVP in 6 months, full v1.0 in 12 months
- **Budget**: Bootstrapped development with focus on efficiency
- **Team**: Small team with AI-assisted development using Claude Code
- **Competition**: Differentiation through specialized GLP-1 focus and pharmacokinetics

## Risk Mitigation

### Technical Risks
- **CloudKit Complexity**: Graceful local-only fallback implemented
- **Pharmacokinetic Accuracy**: Clinical advisory board and validation
- **Test Coverage**: TDD approach with comprehensive test suite
- **Performance**: Regular profiling and optimization

### Market Risks
- **Regulatory Changes**: Stay informed on FDA guidance updates
- **Competition**: Focus on specialized value proposition
- **User Adoption**: Strong onboarding and clear value demonstration
- **Provider Adoption**: Professional reports and clinical integration focus

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

## Product Insights from ConcentrationTimelineChart Implementation (Issue #56)
- **Historical Dose Entry Value**: DatePicker enabling 30-day historical entry creates significant user value for patients catching up on missed doses or correcting entry errors
- **Chart Data Meaningfulness**: Historical dose creation with real concentration decay patterns demonstrates medical app utility - proper pharmacokinetic visualization over time
- **E2E Test Medical Validation**: Healthcare applications benefit from comprehensive end-to-end validation - chart display with multi-week concentration timeline proves medical calculation accuracy
- **User Experience Patterns**: Calendar interaction solutions must account for accessibility and modal presentation - form field tapping provides intuitive dismissal for users
- **Patient Workflow Enhancement**: Historical dose correction capability addresses real-world patient needs for medication management and adherence tracking
- **E2E Testing Medical Value**: Comprehensive chart interaction testing (reset, export, time periods) validates medical app usability for healthcare professionals
- **Accessibility Testing Excellence**: VoiceOver support validation with proper button labeling ensures medical app compliance with accessibility standards
- **Performance Testing Medical Standards**: Load time validation (<10s) and interaction response (<8s) ensures medical app performance meets patient safety requirements
- **Chart Control Integration Success**: Complete time period selection, export functionality, and reset controls provide professional-grade medical visualization tools

## Product Insights from AnalyticsService Core (Issue #54)
- **Core Analytics Foundation Complete**: AnalyticsService implementation enables comprehensive analytics visualization phase of the application
- **Medical Accuracy Validation Implementation**: Therapeutic range analysis with concentration optimality scoring provides medical-grade analytics for healthcare applications
- **User Analytics Summary Structure**: Complete analytics foundation ready for dashboard integration, enabling patient adherence insights and provider reporting
- **Cross-Model Analytics Value**: Centralized service coordination provides comprehensive user insights across medication profiles, doses, and concentration calculations

## Product Insights from Issue #56 Integration Success (PR #64 Merge)
- **AnalyticsView Integration Excellence**: Replacing placeholder with fully functional ConcentrationTimelineChart creates immediate user value in main application interface
- **Medical App Professional Standards Achievement**: Professional chart export capability with PDF generation essential for healthcare provider communication and medical records integration
- **Accessibility Excellence as Core Value**: Comprehensive VoiceOver support with trend descriptions transforms the app into an accessible medical tool meeting healthcare compliance standards
- **Performance Standards for Patient Safety**: Sub-500ms rendering for 365+ doses meets medical app responsiveness requirements ensuring patient safety and clinical workflow efficiency
- **Historical Data Entry Clinical Value**: 30-day historical dose entry enables real-world patient workflows for missed dose correction and medication adherence catch-up scenarios
- **Healthcare Provider Integration Ready**: Professional export functionality, accessibility compliance, and performance standards position the app for healthcare provider referrals and clinical adoption

## Product Insights from Issue #71 Test Coverage Excellence
- **Medical App Testing Excellence**: Comprehensive VoiceOver support validation demonstrates medical app accessibility compliance requirements - critical for healthcare application standards
- **Chart Component Medical Validation**: Successfully validated concentration chart components work together for pharmacokinetic visualization accuracy - essential for patient safety
- **Medical Data Accuracy Verification**: Test suites validate dose formatting, concentration calculations, and accessibility descriptions for healthcare accuracy requirements
- **Chart Interaction Testing Standards**: Comprehensive testing of gesture handling, accessibility, and chart state management ensures reliable user experience for medical data visualization
- **Patient Safety Through Testing**: 85+ test methods covering critical chart components demonstrate commitment to patient safety through comprehensive quality assurance
- **Medical Grade Testing Requirements**: Test coverage improvement from 3%-50% to 75%-85% demonstrates systematic approach to achieving medical-grade software quality standards
- **Pharmacokinetic Visualization Reliability**: Chart component testing ensures accurate concentration data presentation critical for medication management decisions

## Product Insights from Issue #57 AdherenceInsights Business Logic Validation
- **Weekly Medication Pattern Recognition**: AdherenceInsights algorithms must understand weekly vs daily dosing schedules - discovered during Issue #57 business logic validation
- **Medical Accuracy Requirements**: Dose escalation and weekend gap detection critical for patient adherence insights - algorithms must reflect real clinical patterns
- **Healthcare App Testing Standards**: Medical apps require higher testing standards due to patient safety implications - test workarounds compromise medical accuracy
- **Business Logic Medical Validation**: Three-stream parallel development revealed that UI excellence means nothing without medically accurate backend algorithms
- **Patient Safety Through Algorithm Accuracy**: Weekend gap detection for weekly medications was fundamentally flawed - could provide incorrect adherence insights to patients and providers
- **Medical Algorithm Design Requirements**: Healthcare applications must account for different medication schedules (weekly vs daily) in all pattern recognition algorithms

## Product Insights from Issue #57 Architecture Consolidation & E2E Testing Excellence
- **Scope Management Success**: Removing "Personalized improvement recommendations" from Issue #57 enabled focused delivery of core adherence functionality - demonstrates value of strategic scope reduction
- **Architecture Consolidation Value**: Successfully consolidated duplicate AdherenceInsightsView into ContentView.adherenceInsightsSection without losing functionality - shows architecture cleanup creates maintainable codebase
- **E2E Testing Quality Standards**: "Tests validate expected behavior" principle prevents quality degradation - if elements missing/wrong, fix implementation, NOT test weakening
- **CodeGen Testing Breakthrough**: User CodeGen recordings provide solutions when debug utilities insufficient - demonstrates collaborative debugging approach for complex UI interactions
- **Medical App Testing Excellence**: CodeGen element access patterns (`staticTexts.matching(identifier:).element(boundBy:)`) solve complex SwiftUI accessibility hierarchy challenges for medical apps
- **TestUtilities Enhancement Strategy**: `findElementsUsingCodeGenPatterns()` function provides systematic approach to robust E2E testing - demonstrates investment in testing infrastructure pays dividends

## Product Insights from Issue #59 Analytics Orchestration & Polish (Phase 2 Design Review)

### Medical App Design Standards Discovered
- **Therapeutic Range Visualization Critical**: Healthcare apps require therapeutic range visualization on concentration charts - essential for clinical value and helping users understand if medication levels are optimal
- **Medical Data Labeling Requirements**: Charts displaying medical data must include axis labels with units (ng/mL) - ambiguous data is misleading and reduces app credibility for medical use
- **User Education for Medical Terminology**: Medical terminology like "Concentration" needs contextual help or tooltips - non-medical users may not understand "Medication Level in Your Body" concept

### User Experience & Motivation Patterns
- **Gamification Effectiveness**: Gamification through streak visualization (🔥 fire emoji icons) increases user engagement and adherence motivation significantly
- **Actionable Insights Value**: Users highly value specific, actionable insights (e.g., "Sunday missed doses" with reminder suggestion) over generic feedback
- **Visual Feedback Requirements**: Time period selection controls must show clear visual feedback - users get confused when selected state isn't obvious

### Design Review Process Value
- **Screenshot-Driven Design Reviews**: Capturing comprehensive E2E test screenshots enables thorough visual analysis without running simulators repeatedly - significantly speeds up design iteration
- **Systematic UX Analysis**: Organizing feedback by view (above fold, below fold, specific features) with ratings and structured improvements creates immediately actionable implementation plan
- **Priority Framework Success**: Must Have (5) → Should Have (6) → Nice to Have (7) prioritization framework for polish tasks enables focused delivery

## Product Insights from Issue #174 Dose Scheduling Models (SwiftData Foundation)

### Medical Adherence Definition Refinement
- **Adherence Means Taking Medication**: Adherence calculations should reflect actual medication intake - `isAdherent` should return false for skipped doses even if they have a valid reason (`.adherent` status)
- **Skipped vs Missed Distinction**: Medical apps must distinguish between intentional skips (with reasons) and missed doses (forgotten) - both impact adherence metrics but differently
- **Adherence Status Categories**: Three-tier status system (adherent, nonAdherent, pending) provides clear tracking for medication management

### Scheduling Window Medical Requirements
- **1-Second Tolerance Medically Reasonable**: Scheduling window boundaries require 1-second tolerance for system timing precision - medically acceptable and necessary for reliable system operation
- **Window Definition Flexibility**: `windowStart` and `windowEnd` define adherence windows (typically ±2 hours for weekly doses) - flexible enough for real-world patient schedules
- **Real-Time Window Calculation**: `isInWindow` computed property provides real-time status - essential for dose reminder timing and adherence tracking

### Dose Scheduling Architecture Value
- **DoseEvent Calculated Entity**: Combining scheduled and actual doses into unified timeline (DoseEvent struct) simplifies adherence visualization and reporting
- **Pause/Resume Support**: Medical treatment interruptions require proper tracking (`pausedAt`, `pausedUntil`) without losing schedule history - essential for clinical accuracy
- **Reschedule Tracking**: Preserving original scheduled time (`rescheduledFrom`) enables accurate adherence analysis even when doses are rescheduled

## Product Insights from Issue #175 ScheduleService Core (2025-10-06)

### Schedule Management Complexity
- **Multiple Pattern Support**: Supporting weekly, split-dose, and custom patterns requires sophisticated algorithm design and comprehensive testing - reflects real-world patient medication variety
- **Configuration Flexibility**: ScheduleConfiguration with TimeComponents and CustomRecurrence enables type-safe scheduling across diverse medication regimens

### Medical Accuracy Requirements
- **90%+ Test Coverage Mandate**: Tier 1 business logic requirement (90%+ coverage) reflects critical importance of schedule calculations for patient safety
- **Algorithm Validation**: Dose generation algorithms directly impact medication adherence - medical accuracy requires comprehensive edge case testing

### Performance as User Experience
- **<100ms Requirement**: 365-day projection performance requirement ensures responsive UI interactions for dose scheduling
- **User Perception**: Fast schedule generation enables seamless user experience when creating or modifying medication schedules

## Product Insights from Issue #176 NotificationService (2025-10-08)

### Smart Notification Value Proposition
- **Actionable Notifications Transform Adherence Support**: Actionable notifications (Take, Skip, Snooze) transform passive dose tracking into active medication management - significantly enhances user adherence support through friction-free dose logging
- **Missed Dose Detection Clinical Value**: Automatic detection and alerting for doses outside adherence window addresses critical patient safety gap - complements scheduled reminders with catch-up alerts

### Background Refresh User Experience
- **Weekly Background Refresh Maintains Queue Accuracy**: Background refresh maintains notification queue accuracy without user intervention - ensures reliable dose reminders even when app not actively used
- **Notification Action UX Patterns**: Inline notification actions enable dose logging without opening app - reduces friction in daily medication adherence workflow

## Product Insights from Issue #178 Calendar Integration Bug Fixes (2025-10-14/15)

### User Expectations for Calendar Actions
- **Temporal Context Preservation**: Users expect "Log Dose Now" action from calendar to pre-populate with scheduled dose date, not today's date - maintaining temporal context is critical for scheduled dose logging
- **Future Dose Logging Workflow**: Long-pressing Oct 21 scheduled dose and selecting "Log Dose Now" should show Oct 21 in date picker, not Oct 14 (today) - primary calendar interaction pattern requires proper date handling
- **User Mental Model**: When acting on a scheduled dose from calendar, users expect the scheduled date to be preserved throughout the logging workflow - breaking this expectation causes confusion and data entry errors

### Analytics Accuracy and User Trust
- **Random Data Undermines Credibility**: Analytics showing random/fake adherence data (declining trend, 5 missed Sunday doses) with perfect adherence confuses users and destroys app credibility
- **Placeholder Methods in Production**: Never ship placeholder methods with random/hardcoded data - AnalyticsViewModel `generateTrendData()` with `Double.random(in: 0.6...0.95)` showed "declining adherence" even with 100% compliance
- **Medical App Integrity**: Healthcare applications must show real data or no data - fake analytics suggesting adherence problems when none exist could cause unnecessary medical anxiety or incorrect treatment adjustments

### Performance Perception Standards
- **Chart Load Time Expectations**: 163-second chart load time for 12 doses is unacceptable - users expect instant (<1s) rendering for small datasets
- **Performance vs Dataset Size**: User perception of "reasonable" performance varies dramatically by dataset size - 12 doses should be instant, 365 doses can take a few seconds
- **Medical App Responsiveness**: Slow chart rendering suggests unreliability - in medical apps, performance directly impacts perceived accuracy and trustworthiness

### Calendar Interaction Patterns
- **Long-Press as Primary Workflow**: Long-press on scheduled dose followed by "Log Now" is the primary calendar interaction for medication logging - date pre-population critical for this workflow
- **Scheduled Date Persistence**: Scheduled dose date must persist through all UI interactions (action sheet → QuickDoseSheet → DatePicker) - losing context anywhere breaks the workflow
- **Multi-Step Form Context**: When forms are triggered from contextual actions (calendar date), that context must flow through entire form submission process

## Update History
- 2025-10-15T18:06:05Z: Added Product Insights from Issue #178 Calendar Integration Bug Fixes - user expectations for calendar actions, analytics accuracy and user trust, performance perception standards, and calendar interaction patterns
- 2025-10-09T21:00:00Z: Consolidated context files - merged project-brief.md content (scope, constraints, risks), established testing.md as single source of truth for testing patterns, reduced duplication across tech-context, system-patterns, and project-style-guide
- 2025-10-08T20:37:55Z: Added Product Insights from Issue #176 NotificationService - smart notification value proposition (actionable notifications, missed dose detection), and background refresh user experience patterns
- 2025-10-06T20:59:29Z: Added Product Insights from Issue #175 ScheduleService Core - schedule management complexity, medical accuracy requirements (90%+ coverage mandate), and performance as user experience (<100ms requirement)
- 2025-10-05T23:08:25Z: Added Product Insights from Issue #174 Dose Scheduling Models - medical adherence definitions, scheduling window requirements, and dose scheduling architecture value for patient workflows
- 2025-10-01T20:00:09Z: Added Product Insights from Issue #59 Analytics Orchestration & Polish (Phase 2 Design Review) - medical app design standards, therapeutic range visualization requirements, user education needs, gamification effectiveness, and design review process patterns
- 2025-09-27T14:51:11Z: Added Product Insights from Issue #57 Architecture Consolidation & E2E Testing Excellence - scope management success, architecture consolidation value, E2E testing quality standards, CodeGen testing breakthrough, and TestUtilities enhancement strategy
- 2025-09-26T01:23:01Z: Added Product Insights from Issue #57 AdherenceInsights Business Logic Validation - weekly medication pattern recognition, medical accuracy requirements, healthcare testing standards, and algorithm design requirements
- 2025-09-25T19:11:47Z: Added Product Insights from Issue #71 Test Coverage Excellence - medical app testing excellence, chart component validation, data accuracy verification, and patient safety through comprehensive quality assurance
- 2025-09-25T18:58:42Z: Added Product Insights from Issue #56 Integration Success (PR #64 Merge) - AnalyticsView integration, medical app professional standards, accessibility excellence, and healthcare provider integration readiness
- 2025-09-24T18:23:44Z: Completed Product Insights from ConcentrationTimelineChart Implementation (Issue #56) - comprehensive E2E testing, accessibility standards, performance validation, and professional medical visualization tools
- 2025-09-21T20:59:02Z: Epic complete! Updated all core feature status - dose tracking and pharmacokinetics fully implemented
- 2025-09-16T22:39:56Z: Added calendar integration insights and updated dose tracking/analytics feature status
- 2025-09-12T16:35:25Z: Updated dose tracking feature status - quick dose entry now implemented