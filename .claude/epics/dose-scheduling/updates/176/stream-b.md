---
issue: 176
stream: Background Refresh & Badge Management
agent: parallel-stream-developer
started: 2025-10-07T19:54:58Z
status: waiting
simulator: 2
simulator_uuid: BFE552DA-1CB4-4736-821D-270EC6307512
test_command: "./scripts/test.sh unit 2"
depends_on: stream-a
---

# Stream B: Background Refresh & Badge Management

## Scope
Background refresh integration, badge count management, and notification content creation
- **REMINDER**: Follow TDD approach with immediate test feedback

## Branch
issue/176-notificationservice-smart-dose-reminders-and-notification-management

## Testing
- **Assigned Simulator**: 2 (BFE552DA-1CB4-4736-821D-270EC6307512)
- **Simulator Name**: iPhone 15 Pro Max,OS=17.5
- **Test Command**: `./scripts/test.sh unit 2 NotificationServiceBackgroundTests`

## Implementation Files
- `JabTracker/Services/NotificationService+Background.swift` (extension)

## Unit/Integration Test Files
- `JabTrackerTests/NotificationServiceBackgroundTests.swift` (15 test methods)
  - Background refresh tests (10 tests)
  - Badge count tests (5 tests)

## E2E Test Files
- None (background service functionality)

## Key Responsibilities
- `performBackgroundRefresh()` orchestration
- `updateBadgeCount()` calculation
- `createDoseReminderContent()`, `createMissedDoseContent()`
- Localization support (NSLocalizedString)
- Unit tests for background refresh scenarios
- Badge count accuracy validation

## Dependency Status
⏳ **WAITING**: Stream A must commit base class before this stream can start
- Need: NotificationService.swift base class with @Observable pattern
- Once available: Pull latest and begin extension implementation

## Progress

### Session 1: 2025-10-07T18:40:00Z - Initial Setup & Dependency Check
- ✅ Reviewed task file `.claude/epics/dose-scheduling/176.md`
- ✅ Reviewed analysis `.claude/epics/dose-scheduling/176-analysis.md`
- ✅ Confirmed simulator assignment (Simulator 2, UUID: BFE552DA-1CB4-4736-821D-270EC6307512)
- ✅ Verified test command: `./scripts/test.sh unit 2 NotificationServiceBackgroundTests`
- ❌ Checked for base class `JabTracker/Services/NotificationService.swift` - NOT FOUND
- ⏳ **STATUS**: Waiting for Stream A to complete and commit base class

**Dependency Check Results**:
```bash
$ git pull origin issue/176-notificationservice-smart-dose-reminders-and-notification-management
Already up to date.

$ test -f JabTracker/Services/NotificationService.swift
Base class NOT FOUND
```

**Ready to Begin When**:
1. Stream A commits `NotificationService.swift` with:
   - @Observable pattern implementation
   - ModelContext dependency injection
   - Core properties: isAuthorized, pendingRequests, etc.
   - Authorization methods: requestAuthorization(), checkAuthorizationStatus()
2. Pull latest changes from feature branch
3. Verify base class structure meets requirements
4. Begin TDD implementation

**My Implementation Plan** (when unblocked):

**Phase 1: Test Stubs** (5 min)
- Create `NotificationServiceBackgroundTests.swift` with 15 test method stubs
- All tests marked with GIVEN/WHEN/THEN comments

**Phase 2: Background Refresh Tests** (30 min)
- Implement 10 background refresh tests one at a time
- Test orchestration: queue refresh → missed dose detection → badge update
- Test error handling and graceful degradation

**Phase 3: Badge Count Tests** (15 min)
- Implement 5 badge count tests
- Test pending notification counting
- Test app icon badge updates

**Phase 4: Content Creation Tests** (20 min)
- Test dose reminder content creation
- Test missed dose content creation
- Verify localization support

**Phase 5: Implementation** (45 min)
- Create `NotificationService+Background.swift` extension
- Implement methods following TDD cycle
- Run tests after each implementation: `./scripts/test.sh unit 2 NotificationServiceBackgroundTests/testMethodName`

**Phase 6: Validation** (10 min)
- Run full test suite: `./scripts/test.sh unit 2 NotificationServiceBackgroundTests`
- Verify 70%+ coverage
- SwiftLint check
- Update stream status to completed

**Estimated Total Time**: ~2 hours after Stream A completes

**Next Action**:
- Monitor for Stream A commit notification
- Periodically check: `git pull && test -f JabTracker/Services/NotificationService.swift`
