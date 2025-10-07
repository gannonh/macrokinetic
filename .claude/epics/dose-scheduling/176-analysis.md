---
issue: 176
title: NotificationService - Smart Dose Reminders and Notification Management
analyzed: 2025-10-07T19:50:20Z
estimated_hours: 24
parallelization_factor: 3.0
---

# Parallel Work Analysis: Issue #176

## Overview
Implement comprehensive notification management service for dose scheduling system. This includes smart dose reminders, actionable notifications (take, skip, snooze), background refresh for notification queue updates, missed dose detection, and full UNUserNotificationCenter integration.

## Scope Validation

✅ **Dependencies Complete**:
- Issue #174 (DoseSchedule, ScheduledDose models) - CLOSED
- Issue #175 (ScheduleService Core) - CLOSED

✅ **No Existing Implementation**:
- NotificationService.swift does not exist
- Only basic authorization exists in OnboardingViewModel
- No notification queue management, action handling, or background refresh

✅ **Scope Still Valid**:
- Notification system is essential for dose adherence
- Natural next step after schedule management
- Well-defined requirements with clear acceptance criteria

## Parallel Streams

### Stream A: Core Notification Infrastructure
**Scope**: Service architecture, authorization, notification categories, and queue management
**Implementation Files**:
- `JabTracker/Services/NotificationService.swift` (base class)
- `JabTracker/Models/PendingNotification.swift` (data structures)
**Unit/Integration Testing Files**:
- `JabTrackerTests/NotificationServiceTests.swift` (25 test methods)
  - Authorization tests (5 tests)
  - Notification queue tests (15 tests)
  - 64-notification limit tests (5 tests)
**E2E Testing Files**:
- None (service layer, not user-facing yet)
**Product Area**: backend
**Can Start**: immediately
**Estimated Hours**: 8
**Dependencies**: none

**Key Responsibilities**:
- `NotificationService.swift` base class with @Observable pattern
- `requestAuthorization()`, `checkAuthorizationStatus()`
- `registerNotificationCategories()` with DOSE_REMINDER and MISSED_DOSE categories
- `refreshNotificationQueue()` with 64-notification limit handling
- `scheduleDoseReminder()`, `cancelNotification()`
- `PendingNotification` and `NotificationContent` data structures
- Unit tests for authorization and queue management

### Stream B: Background Refresh & Badge Management
**Scope**: Background refresh integration, badge count management, and notification content creation
**Implementation Files**:
- `JabTracker/Services/NotificationService+Background.swift` (extension)
**Unit/Integration Testing Files**:
- `JabTrackerTests/NotificationServiceBackgroundTests.swift` (15 test methods)
  - Background refresh tests (10 tests)
  - Badge count tests (5 tests)
**E2E Testing Files**:
- None (background service functionality)
**Product Area**: backend
**Can Start**: after Stream A completes base class
**Estimated Hours**: 6
**Dependencies**: Stream A (needs NotificationService base class)

**Key Responsibilities**:
- `performBackgroundRefresh()` orchestration
- `updateBadgeCount()` calculation
- `createDoseReminderContent()`, `createMissedDoseContent()`
- Localization support (NSLocalizedString)
- Unit tests for background refresh scenarios
- Badge count accuracy validation

### Stream C: Action Handling & Missed Dose Detection
**Scope**: Notification action handling, missed dose detection, and SwiftData integration
**Implementation Files**:
- `JabTracker/Services/NotificationService+Actions.swift` (extension)
**Unit/Integration Testing Files**:
- `JabTrackerTests/NotificationServiceActionTests.swift` (20 test methods)
  - Action handling tests (15 tests)
  - Missed dose detection tests (5 tests)
- `JabTrackerTests/NotificationServiceIntegrationTests.swift` (10 test methods)
  - End-to-end notification flows
**E2E Testing Files**:
- None (notification actions tested via integration tests)
**Product Area**: backend
**Can Start**: after Stream A completes base class
**Estimated Hours**: 10
**Dependencies**: Stream A (needs NotificationService base class)

**Key Responsibilities**:
- `handleNotificationAction()` with SwiftData integration
- `handleNotificationResponse()` routing
- `detectMissedDoses()` query implementation
- `scheduleMissedDoseAlert()`, `processMissedDoses()`
- UNUserNotificationCenterDelegate implementation
- Integration tests for end-to-end flows
- Action handling with ScheduleService coordination

## Coordination Points

### Shared Files
**NotificationService.swift** - Stream A creates base class, Streams B & C add extensions:
- Stream A: Base class with core properties and CRUD operations
- Stream B: Background refresh extension methods
- Stream C: Action handling extension methods

### Sequential Requirements
1. **Stream A must complete base class** before Streams B & C can compile extensions
2. **All streams coordinate through extension pattern** - prevents file conflicts
3. **Integration tests in Stream C** depend on all functionality being implemented

### File Ownership
- **Stream A owns**: `NotificationService.swift`, `PendingNotification.swift`, `NotificationServiceTests.swift`
- **Stream B owns**: `NotificationService+Background.swift`, `NotificationServiceBackgroundTests.swift`
- **Stream C owns**: `NotificationService+Actions.swift`, `NotificationServiceActionTests.swift`, `NotificationServiceIntegrationTests.swift`

## Conflict Risk Assessment
- **Low Risk**: Extension-based architecture prevents file conflicts
- **Coordination via GitHub**: Stream A commits base class early, unblocks B & C
- **Clear Separation**: Each stream owns distinct functionality domains
- **Integration Point**: Stream C's integration tests validate all streams working together

## Parallelization Strategy

**Recommended Approach**: Hybrid (Phase 1: Sequential, Phase 2: Parallel)

**Phase 1 (Sequential - 2 hours)**:
1. Stream A creates `NotificationService.swift` base class
2. Stream A implements core properties, authorization, category registration
3. Stream A commits base class to enable parallel work

**Phase 2 (Parallel - 6 hours)**:
1. Stream A continues with queue management and unit tests
2. Stream B adds background refresh extension (depends on base class)
3. Stream C adds action handling extension (depends on base class)

**Phase 3 (Integration - 2 hours)**:
1. Stream C runs integration tests validating all streams
2. Fix any cross-stream issues discovered

## Expected Timeline

**With hybrid parallel execution**:
- Phase 1 (Sequential): 2 hours
- Phase 2 (Parallel): 6 hours (max of 6h, 6h, 10h streams running concurrently)
- Phase 3 (Integration): 2 hours
- **Wall time**: ~10 hours

**Without parallel execution**:
- Sequential implementation: 8h + 6h + 10h = 24 hours

**Efficiency gain**: 58% time reduction (14 hours saved)
**Parallelization factor**: 2.4x speedup

## Notes

### Extension Architecture Benefits
- **Proven Pattern**: Successfully used in Issue #175 (ScheduleService)
- **Conflict Prevention**: Each stream owns dedicated extension files
- **Clean Separation**: Background refresh, action handling, and core logic separated
- **Compilation Dependencies**: Base class must exist before extensions compile

### Testing Strategy
- **Total Tests**: 60+ test methods across 4 test files
- **Unit Tests**: Mock UNUserNotificationCenter for isolated testing
- **Integration Tests**: Real ScheduleService integration for end-to-end flows
- **Coverage Target**: 90%+ for business logic (Tier 1), 70%+ for framework integration (Tier 2)

### iOS-Specific Considerations
- **64-Notification Limit**: iOS constraint requires careful queue management
- **Background Refresh**: iOS may not always grant background time - need app foreground fallback
- **UNUserNotificationCenterDelegate**: Singleton pattern required for app-wide delegate access
- **SwiftData Context**: Careful ModelContext management in delegate methods

### Risk Mitigation
- **Notification Delivery**: Multiple strategies (reminders, missed dose alerts)
- **Authorization Handling**: Graceful degradation if notifications denied
- **Queue Refresh**: Both background refresh and foreground refresh for reliability
- **Action Handling Errors**: Comprehensive error logging with OSLog

## Streams Conduct Their Own Testing (TDD)
Each stream follows outside-in TDD:
1. **Stream A**: Unit tests embedded in stream development
2. **Stream B**: Unit tests embedded in stream development
3. **Stream C**: Unit tests + integration tests embedded in stream development

No separate testing streams needed - each stream owns both implementation and tests.
