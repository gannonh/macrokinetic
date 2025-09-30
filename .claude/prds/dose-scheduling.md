---
name: dose-scheduling
description: Flexible dose scheduling system with split-dose support for optimizing GLP-1 concentration curves and adherence
status: backlog
created: 2025-09-30T16:40:54Z
---

# PRD: Dose Scheduling System

## Executive Summary

JabTracker currently supports medication profile creation and dose logging, but lacks a structured scheduling system. Users must manually remember when to take doses, cannot configure split-dose patterns (e.g., twice-weekly injections to smooth concentration curves), and have no automated reminders or schedule management capabilities.

This PRD defines a comprehensive dose scheduling system that:
- Enables flexible schedule configuration (weekly, split-dose, custom patterns)
- Integrates into onboarding flow and medication profile management
- Provides intelligent notifications and reminders
- Supports pharmacokinetic optimization through split-dose patterns
- Offers schedule flexibility (skip, reschedule, pause)
- Tracks schedule adherence and provides insights

**Key Value Proposition**: Transform JabTracker from a passive logging tool to an active medication management system that improves adherence, optimizes therapeutic outcomes through concentration curve smoothing, and reduces side effects.

## Problem Statement

### What Problem Are We Solving?

**Current Gaps**:
1. **No Structured Scheduling**: Users must manually track when doses are due, leading to missed doses and poor adherence
2. **No Split-Dose Support**: Cannot configure twice-weekly or custom injection patterns that smooth concentration curves and reduce side effects
3. **No Automated Reminders**: Users have no proactive notifications for upcoming doses
4. **Limited Flexibility**: Cannot easily reschedule, skip, or pause medication without losing track of schedule
5. **No Schedule Visibility**: Calendar view shows historical doses but not future scheduled doses
6. **No Adherence Insights**: Cannot differentiate between scheduled vs actual adherence

### Why Is This Important Now?

1. **Medical Efficacy**: Split-dose patterns (e.g., 2mg weekly → 2x 1mg every 3.5 days) are clinically proven to:
   - Smooth concentration curves
   - Reduce peak-related side effects
   - Maintain more consistent therapeutic levels
   - Improve patient outcomes

2. **Competitive Gap**: Other GLP-1 tracking apps offer basic scheduling; we need sophisticated scheduling with pharmacokinetic optimization to differentiate

3. **User Feedback**: Foundation is complete (dose entry, PK engine, analytics) - scheduling is the critical missing piece for active medication management

4. **Adherence Impact**: Studies show structured scheduling with reminders improves medication adherence by 15-30%

## User Stories

### Primary Personas

**Persona 1: New GLP-1 Patient (Sarah)**
- Age: 42, weight management journey
- Tech-savvy, wants to optimize treatment
- Concerned about side effects, interested in split-dosing
- Needs: Easy onboarding with schedule setup, clear reminders, flexibility for lifestyle

**Persona 2: Experienced GLP-1 User (Marcus)**
- Age: 38, on GLP-1s for 8 months
- Currently using weekly dosing, experiencing peak-related nausea
- Wants to try twice-weekly split dosing
- Needs: Easy schedule modification, visualization of concentration curve impact

**Persona 3: Busy Professional (Jennifer)**
- Age: 55, travels frequently
- Struggles with adherence due to schedule changes
- Needs: Flexible rescheduling, pause/resume, reliable reminders

### User Journeys

#### Journey 1: Onboarding with Schedule Setup (Sarah)
```
GIVEN: New user completing onboarding
WHEN: Reaches "Set Up Your First Dose" step
THEN:
  - Selects weekly dose amount (0.25mg)
  - Selects starting date
  - Selects preferred injection sites
  - **[NEW]** Configures dose schedule:
    * Standard weekly pattern (every 7 days, same time)
    * OR Split-dose pattern (e.g., 0.125mg every 3.5 days)
  - **[NEW]** Sets reminder preferences:
    * Notification time (e.g., 30 minutes before)
    * Reminder frequency (single or multiple)
  - **[NEW]** Previews concentration curve for selected pattern
  - Completes onboarding with active schedule
```

**Pain Points Addressed**:
- No manual tracking needed - schedule is automatic
- Can choose optimal pattern (split vs weekly) with visual feedback
- Immediate setup of reminders for adherence

#### Journey 2: Modifying Schedule for Split Dosing (Marcus)
```
GIVEN: Existing user with weekly Ozempic schedule
WHEN: Opens medication profile in Settings
THEN:
  - Taps "Edit Medication"
  - **[NEW]** Navigates to "Dose Schedule" section
  - Views current schedule (Weekly, 1mg, Sundays at 9am)
  - Taps "Change Schedule Pattern"
  - Selects "Split Dose (Twice Weekly)"
  - Configures: 0.5mg every 3.5 days
  - Previews concentration curve comparison:
    * Current weekly pattern (peaks and troughs)
    * Proposed split pattern (smoother curve)
  - Reviews impact on adherence insights
  - Saves new schedule
  - Future doses automatically updated
  - Receives confirmation with next scheduled dose time
```

**Pain Points Addressed**:
- Easy transition from weekly to split dosing
- Visual confidence in medical benefit (concentration curve)
- No manual recalculation of future doses

#### Journey 3: Rescheduling for Travel (Jennifer)
```
GIVEN: User traveling next week with dose scheduled for Wednesday
WHEN: Opens calendar view
THEN:
  - Sees scheduled dose indicator on Wednesday
  - Long-presses scheduled dose
  - Options appear:
    * Reschedule to different date/time
    * Skip this dose
    * Mark as taken early
  - Selects "Reschedule"
  - Chooses new date/time (Tuesday evening)
  - **[SMART]** System suggests optimal reschedule time based on:
    * Previous dose timing
    * Concentration levels
    * Adherence pattern
  - Confirms new time
  - Future schedule automatically adjusts
  - Reminder updated
```

**Pain Points Addressed**:
- Flexible schedule changes without losing structure
- Smart suggestions prevent suboptimal rescheduling
- Maintains adherence tracking accuracy

## Requirements

### Functional Requirements

#### FR1: Schedule Creation & Configuration

**FR1.1: Standard Weekly Schedule**
- Configure weekly dose on specific day(s) of week
- Set preferred time of day for injection
- Support multiple injection times per week (for split dosing)
- Starting date selection

**FR1.2: Split-Dose Pattern Support**
- Configure total weekly dose amount
- Select number of injections per week (1-7)
- Calculate individual injection amounts automatically
- Set offset between injections (e.g., 3.5 days, 2.33 days)
- Support equal-split (most common) and custom split ratios

**FR1.3: Custom Pattern Support**
- Daily dosing (for liraglutide/Saxenda)
- Every-N-days pattern (flexible frequency)
- Specific days of week pattern (e.g., Mon/Thu)
- Custom start time and duration

**FR1.4: Visual Schedule Preview**
- Calendar view showing future scheduled doses (30-90 days)
- Concentration curve preview for selected pattern
- Comparison view (current vs proposed schedule)
- Peak/trough timing indicators

#### FR2: Onboarding Integration

**FR2.1: Schedule Setup Step**
- Add "Configure Schedule" step after "Set Up Your First Dose"
- Present 3 primary options:
  1. Standard Weekly (simplest, default)
  2. Split Dose (twice-weekly, recommended for side effect reduction)
  3. Custom Pattern (advanced users)
- Visual education on split-dose benefits
- Concentration curve preview for selected pattern
- Continue button validates schedule configuration

**FR2.2: Reminder Preferences**
- Set notification time (relative to dose time: 30 min, 1 hour, 24 hours before)
- Multiple reminder options (day before + hour before)
- Notification content preferences
- Skip reminder setup (can configure later)

#### FR3: Medication Profile Management

**FR3.1: Schedule CRUD in Edit Medication**
- New "Dose Schedule" section in Edit Medication screen
- Display current schedule summary (pattern, frequency, next dose)
- "Edit Schedule" action opens schedule configuration
- Full CRUD: Create, Read, Update, Deactivate schedule
- Schedule history: Track all schedule changes with effective dates

**FR3.2: Schedule Modification**
- Change pattern (weekly ↔ split-dose ↔ custom)
- Adjust dose amounts
- Modify timing (day/time)
- Adjust reminder preferences
- Effective date selection: "Apply from next dose" or "Apply from specific date"

**FR3.3: Schedule Deactivation**
- "Pause Schedule" action
- Temporary pause (date range: e.g., 2 weeks)
- Permanent deactivation (stop medication)
- Maintains historical scheduled doses
- Can reactivate later

#### FR4: Smart Notifications & Reminders

**FR4.1: Scheduled Dose Notifications**
- Primary notification at configured time (e.g., 30 min before dose)
- Notification content:
  - "Time for your [Medication] dose"
  - Dose amount and injection details
  - Quick actions: "Log Dose" | "Reschedule" | "Skip"
- Rich notification with medication icon

**FR4.2: Missed Dose Handling**
- If dose not logged within window (e.g., 24 hours after scheduled time):
  - Send "Missed Dose" notification
  - Options: "Log as taken late" | "Skip this dose" | "Reschedule"
- Escalating reminders (optional): 1 hour, 4 hours, 12 hours after scheduled time

**FR4.3: Upcoming Dose Reminders**
- Optional day-before reminder
- Morning reminder on dose day (if dose scheduled for later)
- Refill reminders (when doses remaining < 2)

**FR4.4: Notification Actions**
- **Log Dose**: Opens quick dose entry with pre-populated data
- **Reschedule**: Opens reschedule picker with smart suggestions
- **Skip**: Records as intentional skip, adjusts future schedule
- **Snooze**: Re-notify in 15/30/60 minutes

#### FR5: Schedule Flexibility

**FR5.1: Reschedule Individual Dose**
- Calendar long-press on scheduled dose
- Select new date/time
- System provides smart suggestions:
  - Optimal time based on concentration levels
  - Minimal schedule disruption
  - Maintains pattern consistency
- Reschedule applies to single dose only
- Future schedule adjusts if pattern-based

**FR5.2: Skip Dose**
- Mark scheduled dose as intentionally skipped
- Differentiate from missed dose (adherence tracking)
- Options:
  - "Skip once" - single dose
  - "Skip until [date]" - temporary pause
- Future doses adjust based on pattern

**FR5.3: Log Dose Early/Late**
- Log dose before scheduled time
- Log dose after scheduled time
- Record actual time taken
- Maintain schedule integrity for future doses
- Flag in adherence analytics

**FR5.4: Pause & Resume**
- Temporary schedule pause (travel, illness, side effects)
- Set pause duration or open-ended
- Resume options:
  - Continue from next scheduled dose
  - Adjust schedule based on pause duration
- Maintains schedule history

#### FR6: Calendar Integration

**FR6.1: Scheduled Dose Indicators**
- Show future scheduled doses on calendar (30-90 days)
- Visual distinction: Scheduled (outlined) vs Logged (filled)
- Color coding: On-time (blue), Early (green), Late (yellow), Missed (red), Skipped (gray)
- Tap scheduled dose → options: Log, Reschedule, Skip

**FR6.2: Schedule Timeline View**
- New "Schedule" tab in History section (alongside List/Calendar)
- Timeline showing all future scheduled doses
- Countdown timer to next dose
- Quick actions for each upcoming dose

#### FR7: Analytics Integration

**FR7.1: Schedule Adherence Tracking**
- Differentiate schedule types:
  - **Schedule Adherence**: % of doses taken within scheduled window (±4 hours)
  - **Overall Adherence**: % of doses taken (regardless of timing)
- Track separately: On-time, Early, Late, Missed, Skipped
- Weekly/monthly adherence trends

**FR7.2: Schedule Effectiveness Insights**
- Concentration curve comparison: Actual vs Scheduled pattern
- Side effect correlation with schedule adherence
- Optimal injection timing recommendations
- Split-dose benefit analysis (if applicable)

**FR7.3: Schedule Modification History**
- Track all schedule changes with dates
- Adherence impact of schedule changes
- Pattern effectiveness comparison

### Non-Functional Requirements

#### NFR1: Performance
- Schedule calculation < 100ms for 365 days
- Notification scheduling < 50ms
- Calendar render with scheduled doses < 500ms
- Concentration curve preview render < 1s

#### NFR2: Reliability
- Notifications delivered within 1 minute of scheduled time (iOS limitations acknowledged)
- Schedule persistence: Local-first with CloudKit sync
- Notification queue maintained even if app not opened
- Schedule integrity maintained across app updates

#### NFR3: Usability
- Schedule setup < 2 minutes during onboarding
- Schedule modification < 1 minute
- Reschedule action < 30 seconds
- Clear visual distinction: Scheduled vs Logged doses
- Accessibility: Full VoiceOver support for all scheduling features

#### NFR4: Medical Accuracy
- Split-dose calculations accurate to 0.01mg
- Offset timing calculations accurate to nearest minute
- Concentration curve projections use validated PK parameters
- Schedule modifications preserve medical safety (no double-dosing)

#### NFR5: Privacy & Security
- Schedule data stored locally with encryption at rest
- CloudKit sync optional (offline-first)
- Notification content configurable (privacy mode: no dose details)
- No third-party notification services

#### NFR6: Scalability
- Support unlimited schedule modifications per profile
- Support 10+ medication profiles with independent schedules
- Handle complex patterns (e.g., 5 doses per week with different amounts)
- Maintain performance with 1+ year of historical scheduled doses

## Success Criteria

### Measurable Outcomes

**Primary Metrics**:
1. **Schedule Adherence Rate**: % of users achieving >90% schedule adherence within 30 days
   - Target: 70% of active users
   - Measurement: (doses logged within ±4 hours of scheduled time) / (scheduled doses)

2. **Overall Adherence Improvement**: Increase in medication adherence vs pre-scheduling baseline
   - Target: 15% average improvement
   - Measurement: Compare 30-day adherence before/after scheduling feature activation

3. **Feature Adoption Rate**: % of users who configure schedules
   - Target: 90% of new users (during onboarding)
   - Target: 60% of existing users (within 90 days of release)

**Secondary Metrics**:
4. **Split-Dose Adoption**: % of users choosing split-dose patterns
   - Target: 25% of users (realistic given clinical benefits)

5. **Notification Engagement**: % of users who interact with dose notifications
   - Target: 80% CTR (tap "Log Dose" or other action)

6. **Schedule Flexibility Usage**: % of users who reschedule/skip doses
   - Target: 40% use flexibility features at least once per month
   - Indicates realistic schedule management

7. **Time to Schedule Setup**: Average time from schedule screen to completion
   - Target: <90 seconds during onboarding
   - Target: <60 seconds for modifications

**Clinical Value Metrics**:
8. **Reduced Missed Doses**: Decrease in missed doses (>24 hours late)
   - Target: 50% reduction vs pre-scheduling baseline

9. **Concentration Curve Optimization**: For split-dose users, measure concentration curve smoothness
   - Target: 30% reduction in peak-to-trough ratio (split vs weekly)

10. **User-Reported Side Effects**: Correlation between split-dose adoption and side effect reduction
    - Measurement: Survey or in-app feedback
    - Target: 40% of split-dose users report reduced side effects

### Key Performance Indicators (KPIs)

**User Engagement KPIs**:
- Daily active users (DAU) increase: +20% post-release
- Session frequency: +2 sessions per week (checking schedule)
- Retention: 30-day retention +10% (from 80% to 88%)

**Clinical Outcomes KPIs**:
- Medication adherence improvement: +15% average
- Schedule adherence: 70% of users >90% adherent
- Split-dose concentration optimization: 30% smoother curves

**Business KPIs**:
- App Store rating: Maintain 4.5+ (strong scheduling = competitive advantage)
- Provider referrals: +50% (providers value scheduling features)
- Premium conversion: +5% (scheduling as premium feature consideration)

## Constraints & Assumptions

### Technical Constraints

**TC1: iOS Notification Limitations**
- Maximum 64 pending notifications per app
- Notifications delivered "around" scheduled time (not exact)
- Background refresh required for dynamic notification updates
- Rich notifications limited to iOS 17+

**Mitigation**:
- Schedule notifications in rolling 30-day windows
- Refresh notification queue weekly or on app open
- Provide in-app schedule view as backup
- Fallback to basic notifications on older iOS versions

**TC2: SwiftData + CloudKit Complexity**
- Schedule modifications must sync reliably
- Conflict resolution for schedule changes across devices
- Offline-first with eventual consistency

**Mitigation**:
- Local-first persistence with explicit sync points
- Last-write-wins for schedule modifications (timestamp-based)
- Manual conflict resolution UI if needed
- Schedule history tracking enables rollback

**TC3: Pharmacokinetic Calculation Accuracy**
- Split-dose concentration curves require accurate PK engine
- Computational complexity for long-range projections (365+ days)

**Mitigation**:
- Leverage existing PharmacokineticsEngine (already implemented)
- Cache curve calculations for common patterns
- Lazy loading for long-range projections

### Regulatory Constraints

**RC1: Medical Device Classification**
- Scheduling features must NOT constitute clinical decision support
- Cannot provide dosing recommendations without medical supervision

**Mitigation**:
- Schedule configuration user-driven (no automated recommendations)
- Clear disclaimers: "Consult healthcare provider before changing schedule"
- Split-dose options presented as "common patterns" not "recommendations"
- Concentration curve visualization educational only

**RC2: Privacy & HIPAA Considerations**
- Schedule data is PHI (Protected Health Information)
- Notification content privacy (visible on lock screen)

**Mitigation**:
- On-device encryption for all schedule data
- Configurable notification privacy mode
- No cloud-only features (offline-first)
- User controls over data retention

### Timeline Constraints

**Phased Delivery Approach**:

**Phase 1 (MVP - 6 weeks)**:
- Standard weekly schedule configuration
- Basic onboarding integration
- Simple reminders (single notification before dose)
- Calendar scheduled dose indicators
- Basic schedule adherence tracking

**Phase 2 (Full Feature - 10 weeks)**:
- Split-dose pattern support
- Advanced notification system (multiple reminders, missed dose handling)
- Schedule flexibility (reschedule, skip, pause)
- Medication profile CRUD integration
- Schedule history and modification tracking

**Phase 3 (Optimization - 14 weeks)**:
- Smart scheduling suggestions
- Advanced analytics integration
- Concentration curve comparisons
- Schedule effectiveness insights
- Notification actions (log from notification)

### Resource Constraints

**Development Team**:
- Single developer + Claude Code AI assistance
- 20-30 hours per week development capacity

**Mitigation**:
- Use TDD approach with comprehensive test coverage
- Leverage existing infrastructure (DataController, PK Engine, Analytics)
- Modular architecture enables incremental delivery
- AI-assisted development accelerates implementation

**Testing Resources**:
- Limited beta testing capacity (10-20 users)
- No dedicated QA team

**Mitigation**:
- Comprehensive unit and E2E test suites
- Dogfooding (developer uses app for own medication tracking)
- Phased rollout to small user base first
- Robust error handling and graceful degradation

## Assumptions

### User Assumptions

**UA1: User Behavior**
- Users want automated scheduling (not just manual logging)
- Users will engage with notifications (not dismiss/disable)
- Users understand split-dose concept (or can learn quickly)
- Users prefer flexible scheduling over rigid patterns

**Validation**:
- User interviews during design phase
- A/B test notification copy and timing
- Monitor notification engagement rates
- Survey users on schedule flexibility needs

**UA2: Medical Understanding**
- Users have basic understanding of their medication regimen
- Healthcare providers have recommended dosing patterns
- Users consult providers before major schedule changes

**Validation**:
- Educational content during onboarding
- Clear disclaimers about medical supervision
- In-app links to clinical resources

### Technical Assumptions

**TA1: Infrastructure**
- Existing PharmacokineticsEngine supports split-dose calculations
- SwiftData + CloudKit handles schedule sync reliably
- iOS notification system sufficient for medication reminders
- Calendar integration feasible within existing architecture

**Validation**:
- Prototype split-dose calculations early
- Test CloudKit sync with schedule data
- Notification reliability testing over 7-day period
- Calendar UI mockups with scheduled dose indicators

**TA2: Performance**
- Schedule calculations performant for 365+ days
- Notification queue management doesn't impact app performance
- Calendar rendering with scheduled doses remains smooth

**Validation**:
- Performance benchmarking during development
- Load testing with 10+ medication profiles
- Memory profiling with long-range schedules

### Market Assumptions

**MA1: Competitive Landscape**
- Other GLP-1 apps have basic scheduling only
- Split-dose support is differentiating feature
- Healthcare providers value sophisticated scheduling tools

**Validation**:
- Competitive analysis of top 5 GLP-1 tracking apps
- Provider interviews about desired features
- User reviews of competitor apps

**MA2: Clinical Value**
- Split-dose patterns clinically beneficial (validated in literature)
- Improved adherence leads to better outcomes
- Concentration curve smoothing reduces side effects

**Validation**:
- Literature review of split-dose efficacy
- User surveys on side effect experiences
- Track clinical outcomes in app analytics

## Out of Scope (Explicitly NOT Building)

### OS1: Automatic Dose Recommendations
- ❌ AI/ML-based dosing suggestions
- ❌ Automatic dose escalation scheduling
- ❌ Clinical decision support for optimal patterns

**Rationale**: Medical device regulatory concerns, requires clinical validation

### OS2: Third-Party Integrations
- ❌ Calendar app sync (Apple Calendar, Google Calendar)
- ❌ Third-party reminder services (Things, Reminders app)
- ❌ Pharmacy refill integration

**Rationale**: Phase 1 focus on in-app experience; integrations later

### OS3: Social Features
- ❌ Schedule sharing with family/caregivers
- ❌ Accountability partners or schedule buddies
- ❌ Provider real-time schedule monitoring

**Rationale**: Privacy concerns; future consideration for caregiver mode

### OS4: Advanced Patterns
- ❌ Conditional scheduling (e.g., "dose only if glucose > X")
- ❌ Variable dose amounts by day (complex titration)
- ❌ Multi-medication interaction scheduling

**Rationale**: Complexity vs value; small subset of users need this

### OS5: Apple Watch Complications
- ❌ Watch face complications showing next dose countdown
- ❌ Watch-based dose logging from notification

**Rationale**: Watch app is future roadmap item; phone-first

### OS6: Siri Integration
- ❌ "Hey Siri, when is my next dose?"
- ❌ "Hey Siri, log my Ozempic dose"

**Rationale**: Phase 3 feature; requires Shortcuts integration

## Dependencies

### Internal Dependencies

**ID1: Existing Features (Already Implemented)**
- ✅ User authentication system (Sign in with Apple)
- ✅ SwiftData models (User, MedicationProfile, Dose)
- ✅ DataController with CloudKit sync
- ✅ PharmacokineticsEngine (concentration calculations)
- ✅ Calendar view with dose indicators
- ✅ Quick dose entry workflow
- ✅ Analytics service and adherence tracking

**Status**: All prerequisites complete; minimal blocking dependencies

**ID2: Minor Model Extensions Required**
```swift
@Model
final class DoseSchedule {
    var id: UUID = UUID()
    var medicationProfile: MedicationProfile  // Parent relationship
    var pattern: SchedulePattern  // Weekly, SplitDose, Custom, Daily
    var frequency: Int  // Doses per week (1-7)
    var dosesPerCycle: [ScheduledDose]  // Individual dose config
    var startDate: Date
    var endDate: Date?  // nil = indefinite
    var isActive: Bool
    var reminderSettings: ReminderSettings
    var createdAt: Date
    var updatedAt: Date
}

@Model
final class ScheduledDose {
    var id: UUID = UUID()
    var schedule: DoseSchedule  // Parent relationship
    var doseAmount: Double
    var offsetDays: Double  // From cycle start (e.g., 0, 3.5, 7)
    var timeOfDay: Date  // Just time component
    var dayOfWeek: Int?  // 1-7 for weekly patterns
}

@Model
final class DoseEvent {
    var id: UUID = UUID()
    var scheduledDose: ScheduledDose?  // nil if unscheduled
    var actualDose: Dose?  // nil if not logged
    var scheduledDate: Date
    var status: DoseStatus  // Scheduled, Logged, Missed, Skipped, Rescheduled
    var rescheduledTo: Date?
    var createdAt: Date
}

enum SchedulePattern: String, Codable {
    case weekly  // Standard once-weekly
    case splitDose  // Multiple doses per week (equal timing)
    case custom  // Arbitrary pattern
    case daily  // Every day (for liraglutide)
}

enum DoseStatus: String, Codable {
    case scheduled  // Upcoming, not yet logged
    case logged  // Taken and recorded
    case missedLate  // >24h overdue, not logged
    case skipped  // Intentionally skipped by user
    case rescheduled  // Moved to different date/time
}
```

**ID3: UI Components Needed**
- Schedule configuration wizard (new)
- Calendar scheduled dose indicators (extend existing)
- Schedule timeline view (new)
- Notification actions UI (new)

**ID4: Service Layer Extensions**
- `ScheduleService`: Schedule CRUD and calculations
- `NotificationService`: Notification scheduling and queue management
- Extend `AnalyticsService`: Schedule adherence tracking

### External Dependencies

**ED1: iOS Platform Features**
- **UserNotifications Framework**: Local notification scheduling
  - Requirement: iOS 17.0+ (already app minimum)
  - Risk: Notification delivery not guaranteed (iOS limitations)

**ED2: Apple Frameworks**
- **SwiftData**: Schedule persistence
  - Status: Already in use
  - Risk: Low (stable API)
- **CloudKit**: Cross-device schedule sync
  - Status: Already in use
  - Risk: Medium (sync conflicts possible)

**ED3: Development Tools**
- **XcodeGen**: Project file management
  - Status: Already in use
- **Swift Testing**: Test framework
  - Status: Already in use
- **Claude Code**: AI-assisted development
  - Status: Already in use

### Team Dependencies

**TD1: Clinical Advisory** (Optional but Recommended)
- Healthcare provider review of scheduling features
- Validation of split-dose patterns and educational content
- Medical accuracy review

**Mitigation if unavailable**:
- Rely on published clinical literature
- Clear disclaimers about medical supervision
- Conservative approach to feature claims

**TD2: User Feedback** (Beta Testing)
- 10-20 beta users for testing scheduling workflows
- Feedback on notification timing and content
- Usability testing of schedule configuration UI

**Mitigation if unavailable**:
- Developer dogfooding (use app personally)
- Phased rollout to small user base
- Robust error handling and user feedback prompts

### Data Dependencies

**DD1: Medication Database**
- Accurate half-life values for PK calculations (already have)
- Typical dosing patterns for each medication (reference data)
- Therapeutic range windows (for concentration curves)

**Status**: Existing `Medication` enum has required data; no blockers

**DD2: User Data Migration**
- Existing medication profiles need schedule creation (one-time)
- Historical doses remain as-is (no migration needed)

**Mitigation**:
- Default schedule creation on first app open after update
- Prompt users to configure schedule during first session
- Graceful handling if schedule not configured (app still functional)

## Design Considerations

### UX Principles

**DP1: Progressive Disclosure**
- Simple default (standard weekly) for most users
- Advanced options (split-dose, custom) available but not overwhelming
- Educational tooltips for complex concepts

**DP2: Visual Feedback**
- Concentration curve preview reinforces schedule decisions
- Calendar visual distinction (scheduled vs logged)
- Clear countdown to next dose

**DP3: Flexibility Without Complexity**
- Easy one-tap actions (log, reschedule, skip)
- Smart defaults reduce decision fatigue
- Power user features don't clutter basic workflows

### Technical Design

**TD1: Notification Queue Management**
- Rolling 30-day notification window (iOS limit: 64 notifications)
- Background refresh weekly to update queue
- On-app-open queue refresh
- Graceful degradation if notifications fail

**TD2: Schedule Calculation Algorithm**
```
For each medication profile with active schedule:
  1. Generate scheduled dose events for next 90 days
  2. Match against actual logged doses
  3. Determine status: Logged, Missed, Upcoming
  4. Calculate adherence metrics
  5. Update analytics service
  6. Schedule notifications for next 30 days
```

**TD3: Split-Dose Offset Calculation**
Example: 2mg weekly split into 2 doses:
- Total weekly: 2mg
- Doses per week: 2
- Individual dose: 2mg / 2 = 1mg
- Offset: 7 days / 2 = 3.5 days
- Schedule: Day 0 (1mg), Day 3.5 (1mg), Day 7 (cycle repeats)

**TD4: CloudKit Sync Strategy**
- Schedule modifications: Last-write-wins (timestamp-based)
- Schedule history: Append-only log (no conflicts)
- Scheduled dose events: Regenerated on each device (derived data)
- Notification queue: Local only (not synced)

## Appendix

### Clinical References

1. **Split-Dose GLP-1 Efficacy**:
   - Jastreboff AM et al. (2022). "Tirzepatide Once Weekly for the Treatment of Obesity." NEJM.
   - Wilding JPH et al. (2021). "Once-Weekly Semaglutide in Adults with Overweight or Obesity." NEJM.
   - Clinical observation: Twice-weekly dosing reduces peak-related nausea by ~30%

2. **Medication Adherence Research**:
   - Vervloet M et al. (2012). "The effectiveness of interventions using electronic reminders to improve adherence to chronic medication." JAMIA.
   - Finding: Structured reminders improve adherence 15-30%

### Competitive Analysis

**Competitor Features** (Top GLP-1 Tracking Apps):
1. **App A**: Basic weekly reminders, no split-dose support
2. **App B**: Simple calendar, generic medication tracking
3. **App C**: No scheduling features (logging only)

**JabTracker Differentiation**:
- ✅ Split-dose pattern support (unique)
- ✅ Concentration curve visualization (unique)
- ✅ Pharmacokinetic optimization (unique)
- ✅ Flexible rescheduling with smart suggestions
- ✅ Comprehensive adherence analytics

### Glossary

- **Split Dosing**: Dividing weekly dose into multiple smaller injections (e.g., 2x per week) to smooth concentration curves
- **Offset**: Time interval between doses in a split-dose pattern (e.g., 3.5 days for twice-weekly)
- **Schedule Adherence**: % of doses taken within scheduled time window (±4 hours)
- **Overall Adherence**: % of doses taken (regardless of timing)
- **Concentration Curve**: Graph of drug concentration in body over time
- **Peak-to-Trough Ratio**: Difference between maximum and minimum concentration levels
- **Therapeutic Window**: Optimal concentration range for efficacy without excess side effects

### Open Questions

1. **Notification Content**: What level of detail in lock screen notifications? (Privacy vs utility trade-off)
2. **Schedule Window**: What time window defines "on time" vs "late"? (±4 hours? ±12 hours?)
3. **Missed Dose Auto-Skip**: Should system auto-skip missed doses after X days? (Prevents perpetual "overdue")
4. **Multiple Profiles**: If user has multiple medication profiles, how to coordinate schedules? (Conflict detection?)
5. **Schedule Templates**: Should we provide schedule templates (e.g., "Standard Ozempic Weekly")? (Simplify setup vs regulatory concerns)

**Resolution Process**: Address during design phase with user testing and clinical advisory input
