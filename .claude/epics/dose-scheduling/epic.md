---
name: dose-scheduling
status: in-progress
created: 2025-10-04T22:00:03Z
progress: 60%
updated: 2025-10-20T14:20:12Z
prd: .claude/prds/dose-scheduling.md
github: https://github.com/gannonh/jab-tracker-ios/issues/173
---

# Epic: Dose Scheduling System

## Overview

Implement a flexible dose scheduling system that transforms JabTracker from passive logging to active medication management. The system will enable users to configure weekly/split-dose/custom patterns, receive smart notifications, and manage schedules with flexibility (reschedule, skip, pause). This leverages existing infrastructure (SwiftData, PharmacokineticsEngine, Calendar) while adding minimal new models and comprehensive scheduling logic.

**Key Technical Approach**: Extend existing SwiftData models with new `DoseSchedule`, `ScheduledDose`, and `DoseEvent` models. Create `ScheduleService` for schedule calculations and `NotificationService` for iOS notification queue management. Integrate scheduling into onboarding flow, medication profile management, and calendar view.

## Tasks Created
- [x] #174 - SwiftData Models - DoseSchedule, ScheduledDose, DoseEvent
- [x] #175 - ScheduleService Core - Schedule Management and Calculation Algorithms
- [x] #176 - NotificationService - Smart Dose Reminders and Notification Management
- [x] #177 - Onboarding Integration
- [x] #178 - Calendar Integration
- [ ] #179 - Medication Profile CRUD
- [ ] #260 - Notification UI & Configuration - Settings Integration and Permission Management
- [ ] #180 - Split-Dose Support
- [ ] #181 - Analytics Integration - Schedule Adherence Tracking & Timeline View
- [~] #182 - Testing Suite - Comprehensive Unit, Integration & E2E Tests for Scheduling (closed: not planned - TDD integrated into feature development)
- [ ] #183 - Performance & Polish - Optimization, Accessibility Audit & Edge Cases

**Total tasks:** 11
**Progress:** 5/10 complete (50%) - excluding closed/not planned task
**Parallel tasks:** 4
**Sequential tasks:** 7

## Architecture Decisions

### 1. SwiftData Model Design

**Decision**: Create three new models with clear separation of concerns:
- `DoseSchedule`: Configuration (pattern, frequency, reminders) - parent relationship to MedicationProfile
- `ScheduledDose`: Individual dose specification within a schedule (amount, offset, time)
- `DoseEvent`: Projected scheduled events matched against actual doses (calculated, not persisted long-term)

**Rationale**:
- Leverages existing SwiftData + CloudKit infrastructure
- Separation enables flexible schedule modifications without affecting historical doses
- `DoseEvent` as calculated entity prevents data bloat (regenerated as needed)

### 2. Notification Queue Management

**Decision**: Rolling 30-day notification window with weekly background refresh
- iOS limit: 64 pending notifications per app
- Schedule next 30 days of dose notifications
- Background refresh weekly + on-app-open to maintain queue
- Graceful degradation: In-app schedule view as backup if notifications fail

**Rationale**:
- Works within iOS notification limitations
- Balances coverage (30 days) with system constraints
- Background refresh ensures notifications stay current even if app not opened

### 3. Schedule Calculation Architecture

**Decision**: `ScheduleService` generates scheduled events on-demand rather than persisting all future doses
- Calculate upcoming scheduled doses for display/analytics
- Match against actual logged doses to determine status
- Regenerate schedule events when schedule modified

**Rationale**:
- Avoids database bloat from persisting thousands of future scheduled doses
- Schedule modifications don't require complex cascade updates
- Performance acceptable (<100ms for 90-day projection per requirement)

### 4. Split-Dose Offset Algorithm

**Decision**: Simple division for equal-split patterns with custom offset support
```swift
// Example: 2mg weekly split into 2 doses
totalWeeklyDose = 2.0mg
dosesPerWeek = 2
individualDose = totalWeeklyDose / dosesPerWeek = 1.0mg
offsetDays = 7.0 / dosesPerWeek = 3.5 days
// Schedule: Day 0 (1mg), Day 3.5 (1mg), repeat at Day 7
```

**Rationale**:
- Simple algorithm covers 90% of split-dose use cases
- Custom offset support enables advanced patterns (e.g., Mon/Thu = 3 day offset)
- Maintains medical accuracy (validates total dose consistency)

### 5. CloudKit Sync Strategy

**Decision**: Last-write-wins for schedule modifications, append-only for history
- Schedule modifications: timestamp-based conflict resolution
- Schedule history: append-only log (all changes tracked)
- Notification queue: local-only (not synced, regenerated per device)
- DoseEvents: calculated per device (not synced)

**Rationale**:
- Prevents complex conflict resolution (user's latest change wins)
- History tracking enables schedule modification rollback if needed
- Notification queue device-specific (no cross-device notification duplication)

## Technical Approach

### Frontend Components

#### 1. Onboarding Integration
**New: Schedule Configuration Step**
- `ScheduleSetupView`: New onboarding step after "Set Up Your First Dose"
- Three primary options: Standard Weekly, Split Dose (Twice Weekly), Custom Pattern
- Integrated concentration curve preview using `PharmacokineticsEngine`
- Reminder preferences configuration
- Continue button validates schedule before proceeding

**Reuse**: Existing `OnboardingViewModel` extended with schedule setup logic

#### 2. Medication Profile Management
**Extended: Edit Medication Screen**
- New "Dose Schedule" section in existing medication profile edit flow
- Display current schedule summary (pattern, frequency, next dose)
- "Edit Schedule" action sheet/modal for schedule modification
- Schedule history timeline
- Pause/deactivate schedule controls

**New Component**: `DoseScheduleEditView` (modal sheet)

#### 3. Calendar Integration
**Extended: Existing Calendar View**
- Add scheduled dose indicators (outlined circles vs filled for logged)
- Color coding: Scheduled (blue outline), Logged (blue filled), Missed (red), Skipped (gray)
- Long-press scheduled dose → action sheet (Log, Reschedule, Skip)
- Visual distinction between historical and future scheduled doses

**New Component**: `ScheduledDoseIndicator` (calendar day overlay)

#### 4. Schedule Timeline View
**New: Schedule Tab in History Section**
- Timeline showing next 30 days of scheduled doses
- Countdown timer to next dose
- Quick actions for each upcoming dose
- Filter: All schedules vs specific medication profile

**New Component**: `ScheduleTimelineView`

#### 5. Notification Actions UI
**New: Notification Response Handling**
- "Log Dose" action → Opens `QuickDoseSheet` with pre-populated data
- "Reschedule" action → Opens reschedule picker with smart suggestions
- "Skip" action → Records intentional skip, adjusts future schedule
- "Snooze" action → Re-notify in 15/30/60 minutes

**Reuse**: Existing `QuickDoseSheet` (already implemented)

### Backend Services

#### 1. ScheduleService (New)
**Responsibilities**:
- Schedule CRUD operations (create, read, update, deactivate)
- Generate scheduled dose events for date range (calculateScheduledDoses(from:to:))
- Match scheduled doses against actual doses (matchScheduleToActualDoses())
- Calculate schedule adherence metrics (scheduleAdherence, overallAdherence)
- Smart reschedule suggestions based on PK engine
- Schedule modification history tracking

**Key Methods**:
```swift
func createSchedule(for profile: MedicationProfile, pattern: SchedulePattern, config: ScheduleConfig) throws -> DoseSchedule
func calculateScheduledDoses(for schedule: DoseSchedule, from: Date, to: Date) -> [DoseEvent]
func matchScheduleToActualDoses(schedule: DoseSchedule) -> [DoseEvent]
func rescheduleEvent(_ event: DoseEvent, to newDate: Date) throws
func skipEvent(_ event: DoseEvent) throws
func pauseSchedule(_ schedule: DoseSchedule, until: Date?) throws
```

#### 2. NotificationService (New)
**Responsibilities**:
- Schedule local notifications for upcoming doses (next 30 days)
- Manage notification queue (rolling window, background refresh)
- Handle notification actions (log, reschedule, skip, snooze)
- Missed dose detection and escalating reminders
- Notification privacy mode configuration

**Key Methods**:
```swift
func scheduleNotifications(for schedule: DoseSchedule, days: Int = 30) async throws
func refreshNotificationQueue() async throws
func handleNotificationAction(_ action: NotificationAction, event: DoseEvent) async throws
func checkMissedDoses() async -> [DoseEvent]
```

#### 3. AnalyticsService Extensions (Existing Service)
**New Methods**:
- Calculate schedule adherence vs overall adherence
- Track schedule modification history impact on adherence
- Generate schedule effectiveness insights
- Concentration curve comparison (actual vs scheduled pattern)

**Integration**: Extend existing `AnalyticsService` with schedule-specific analytics

### Data Models

#### DoseSchedule (New SwiftData Model)
```swift
@Model
final class DoseSchedule {
    var id: UUID = UUID()
    var medicationProfile: MedicationProfile  // Parent relationship
    var pattern: SchedulePattern  // weekly, splitDose, custom, daily
    var frequency: Int = 1  // Doses per week (1-7)
    var startDate: Date = Date()
    var endDate: Date?  // nil = indefinite
    var isActive: Bool = true
    var reminderMinutesBefore: Int = 30
    var enableMultipleReminders: Bool = false
    var notificationPrivacyMode: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \ScheduledDose.schedule)
    var scheduledDoses: [ScheduledDose] = []
}
```

#### ScheduledDose (New SwiftData Model)
```swift
@Model
final class ScheduledDose {
    var id: UUID = UUID()
    var schedule: DoseSchedule  // Parent relationship (plain property, no @Relationship)
    var doseAmount: Double = 0.0
    var offsetDays: Double = 0.0  // From cycle start (e.g., 0, 3.5 for twice-weekly)
    var timeOfDay: Date = Date()  // Time component only
    var dayOfWeek: Int?  // 1-7 for weekly patterns, nil for offset-based
}
```

#### DoseEvent (Calculated Entity - Not Persisted Long-Term)
```swift
struct DoseEvent: Identifiable {
    let id: UUID
    let scheduledDose: ScheduledDose?
    let actualDose: Dose?
    let scheduledDate: Date
    var status: DoseStatus  // scheduled, logged, missedLate, skipped, rescheduled
    var rescheduledTo: Date?
    let createdAt: Date
}

enum DoseStatus: String, Codable {
    case scheduled, logged, missedLate, skipped, rescheduled
}

enum SchedulePattern: String, Codable {
    case weekly, splitDose, custom, daily
}
```

### Infrastructure

#### 1. Notification Queue Background Refresh
- **Approach**: Use iOS Background App Refresh capability
- **Frequency**: Weekly background refresh + on-app-open
- **Fallback**: Manual refresh prompt if background refresh unavailable

#### 2. Performance Optimization
- **Schedule Calculation Caching**: Cache generated DoseEvents for recently viewed date ranges
- **Lazy Loading**: Calendar view loads scheduled doses in monthly chunks
- **Concentration Curve Caching**: Reuse PK engine calculations for identical patterns

#### 3. Testing Infrastructure
- **Unit Tests**: ScheduleService calculations, notification queue management, adherence metrics
- **Integration Tests**: Schedule + PK engine, schedule + analytics, schedule + calendar
- **E2E Tests**: Onboarding schedule setup, schedule modification, notification actions, calendar interaction

## Implementation Strategy

### Phase 1: Foundation (Weeks 1-2)
**Goal**: Core schedule models and service layer

**Tasks**:
1. Create SwiftData models (DoseSchedule, ScheduledDose, DoseEvent)
2. Implement ScheduleService with basic CRUD operations
3. Implement schedule calculation algorithm (weekly pattern only)
4. Unit tests for ScheduleService and schedule calculations

**Deliverable**: Working schedule creation and calculation, no UI

### Phase 2: Onboarding Integration (Weeks 3-4)
**Goal**: Users can configure schedules during onboarding

**Tasks**:
1. Create ScheduleSetupView component
2. Integrate into OnboardingViewModel flow
3. Implement weekly pattern configuration UI
4. Add basic reminder preferences
5. E2E tests for onboarding schedule setup

**Deliverable**: New users create schedules during onboarding

### Phase 3: Notification System (Weeks 5-6)
**Goal**: Scheduled dose notifications delivered reliably

**Tasks**:
1. Implement NotificationService
2. Notification queue management (30-day rolling window)
3. Background refresh setup
4. Missed dose detection
5. Notification action handling (log, reschedule, skip)
6. Integration tests for notification scheduling

**Deliverable**: Users receive dose reminders and can act on them

### Phase 4: Calendar Integration (Week 7)
**Goal**: Scheduled doses visible in calendar view

**Tasks**:
1. Extend CalendarView with scheduled dose indicators
2. Implement ScheduledDoseIndicator component
3. Long-press action sheet (log, reschedule, skip)
4. E2E tests for calendar scheduled dose interaction

**Deliverable**: Calendar shows future scheduled doses

### Phase 5: Medication Profile Management (Week 8)
**Goal**: Users can modify schedules for existing medications

**Tasks**:
1. Create DoseScheduleEditView
2. Integrate into MedicationProfileEditView
3. Schedule history timeline
4. Pause/deactivate schedule controls
5. E2E tests for schedule modification

**Deliverable**: Full schedule CRUD from medication profile

### Phase 6: Split-Dose Support (Weeks 9-10)
**Goal**: Advanced split-dose patterns available

**Tasks**:
1. Extend ScheduleService with split-dose calculations
2. Add split-dose option to ScheduleSetupView
3. Concentration curve comparison UI
4. Offset calculation and validation
5. Unit tests for split-dose calculations

**Deliverable**: Users can configure twice-weekly split dosing

### Phase 7: Analytics Integration (Week 11)
**Goal**: Schedule adherence tracked and displayed

**Tasks**:
1. Extend AnalyticsService with schedule adherence metrics
2. Create ScheduleTimelineView
3. Schedule effectiveness insights
4. E2E tests for analytics integration

**Deliverable**: Schedule adherence visible in analytics

### Phase 8: Polish & Optimization (Week 12)
**Goal**: Performance optimization and edge case handling

**Tasks**:
1. Performance profiling and optimization
2. Edge case testing (missed doses, rescheduling, conflicts)
3. Accessibility audit (VoiceOver support)
4. Documentation updates

**Deliverable**: Production-ready feature

## Task Breakdown Preview

High-level task categories that will be created during epic decomposition:

- [X] **SwiftData Models**: Create DoseSchedule, ScheduledDose, DoseEvent models with proper relationships
- [X] **ScheduleService Core**: Implement schedule CRUD, calculation algorithms, adherence metrics
- [X] **NotificationService**: Build notification queue management, background refresh, action handling
- [X] **Onboarding Integration**: Add schedule setup step to onboarding flow with UI components
- [X] **Calendar Integration**: Extend calendar view with scheduled dose indicators and actions
- [ ] **Medication Profile CRUD**: Integrate schedule management into medication profile editing
- [ ] **Split-Dose Support**: Implement split-dose calculations and UI configuration
- [ ] **Notification UI & Configuration**: Settings screen integration, enable/disable toggle, reminder preferences, deeplink handling
- [ ] **Analytics Integration**: Extend AnalyticsService with schedule adherence tracking
- [~] **Testing Suite**: Comprehensive unit, integration, and E2E tests for all scheduling features (closed: not planned - TDD integrated into feature development)
- [ ] **Performance & Polish**: Optimize performance, accessibility audit, edge case handling

**Estimated Total Tasks**: 10 active (11 total, 1 closed as not planned - TDD integrated into feature development)

## Dependencies

### External Dependencies
- **iOS UserNotifications Framework**: Required for dose reminders (iOS 17.0+, already app minimum)
- **SwiftData + CloudKit**: Schedule persistence and sync (already in use, low risk)
- **Background App Refresh**: Weekly notification queue refresh (graceful fallback if unavailable)

### Internal Dependencies (Already Implemented)
- ✅ SwiftData models (User, MedicationProfile, Dose)
- ✅ DataController with CloudKit sync
- ✅ PharmacokineticsEngine (for concentration curve previews)
- ✅ Calendar view (extend with scheduled dose indicators)
- ✅ QuickDoseSheet (reuse for notification actions)
- ✅ AnalyticsService (extend with schedule adherence)

### Team Dependencies
- **Optional: Clinical Advisory** - Healthcare provider review of scheduling features and educational content
  - Mitigation: Rely on published clinical literature, clear disclaimers, conservative feature claims
- **Optional: Beta Testing** - 10-20 users for usability testing
  - Mitigation: Developer dogfooding, phased rollout, robust error handling

## Success Criteria (Technical)

### Performance Benchmarks
- **Schedule Calculation**: <100ms for 365-day projection (per NFR1)
- **Notification Scheduling**: <50ms per notification (per NFR1)
- **Calendar Rendering**: <500ms with scheduled doses for 90-day view (per NFR1)
- **Concentration Curve Preview**: <1s render time (per NFR1)

### Quality Gates
- **Unit Test Coverage**: 90%+ for ScheduleService and NotificationService (Tier 1 - Pure Business Logic)
- **Integration Test Coverage**: 85%+ for schedule + PK engine, schedule + analytics
- **E2E Test Coverage**: 100% of user journeys (onboarding setup, schedule modification, notification actions)
- **Accessibility**: Full VoiceOver support for all scheduling features (per NFR3)

### Acceptance Criteria
- **Onboarding**: 90% of new users can complete schedule setup in <2 minutes (per NFR3)
- **Schedule Modification**: Existing users can modify schedule in <1 minute (per NFR3)
- **Notification Reliability**: 95%+ notification delivery within 1 minute of scheduled time (per NFR2)
- **Medical Accuracy**: Split-dose calculations accurate to 0.01mg (per NFR4)
- **Data Integrity**: No schedule conflicts or double-dosing scenarios possible (per NFR4)

### Clinical Value Metrics (Tracked Post-Launch)
- **Schedule Adherence**: 70%+ of users achieve >90% schedule adherence within 30 days
- **Overall Adherence Improvement**: 15%+ increase vs pre-scheduling baseline
- **Feature Adoption**: 90% of new users configure schedules during onboarding
- **Split-Dose Adoption**: 25% of users choose split-dose patterns

## Estimated Effort

### Overall Timeline
**Total Duration**: 12 weeks (3 months) for full feature implementation

**Phase Breakdown**:
- Foundation: 2 weeks
- Onboarding Integration: 2 weeks
- Notification System: 2 weeks
- Calendar Integration: 1 week
- Medication Profile CRUD: 1 week
- Split-Dose Support: 2 weeks
- Analytics Integration: 1 week
- Polish & Optimization: 1 week

### Resource Requirements
- **Developer Time**: 20-30 hours per week (single developer + Claude Code AI assistance)
- **Total Effort**: ~240-360 hours over 12 weeks
- **Testing Time**: ~30% of development time (comprehensive unit, integration, E2E tests)

### Critical Path Items
1. **SwiftData Model Design** (Week 1) - Foundation for all subsequent work
2. **ScheduleService Core** (Weeks 1-2) - Enables all scheduling features
3. **NotificationService** (Weeks 5-6) - User-facing value depends on notifications
4. **Onboarding Integration** (Weeks 3-4) - New user adoption critical
5. **Split-Dose Support** (Weeks 9-10) - Key differentiating feature

### Risk Mitigation
- **Notification Reliability**: iOS limitations acknowledged; in-app schedule view as backup
- **CloudKit Sync Complexity**: Last-write-wins strategy simplifies conflict resolution
- **Performance**: Caching and lazy loading prevent performance degradation with large datasets
- **Scope Creep**: Phase 1 MVP (weeks 1-7) delivers core value; split-dose and analytics are Phase 2 enhancements

## Key Simplifications (Minimize Code, Maximize Leverage)

1. **Reuse Existing Infrastructure**: Leverages SwiftData, CloudKit, PharmacokineticsEngine, Calendar view, QuickDoseSheet - minimal new code
2. **Calculated DoseEvents**: Not persisting all future scheduled doses prevents database bloat and complex cascade updates
3. **Rolling Notification Window**: 30-day window within iOS limits, background refresh handles long-term scheduling
4. **Simple Split-Dose Algorithm**: Division-based offset calculation covers 90% of use cases without complex patterns
5. **Last-Write-Wins Sync**: Avoids complex conflict resolution for schedule modifications
6. **Extend Existing Services**: AnalyticsService and OnboardingViewModel extended rather than creating parallel systems
7. **Visual Feedback Over Complex Logic**: Concentration curve preview guides users, reducing need for automated recommendations
8. **Consolidation into 11 Tasks**: Grouping related work (e.g., backend notification service separate from UI configuration) enables focused delivery while maintaining clear separation of concerns

