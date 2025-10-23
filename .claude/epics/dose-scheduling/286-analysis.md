---
issue: 286
title: Implement comprehensive titration completion workflow with user confirmation dialog
analyzed: 2025-10-23T20:15:24Z
estimated_hours: 22
parallelization_factor: 2.5
---

# Parallel Work Analysis: Issue #286

## Overview
Implement comprehensive titration completion workflow to ensure medical safety when dose increases are scheduled. The system currently has no user-facing notifications or prompts when titration dates arrive, creating a patient safety risk. This issue implements a multi-touchpoint UX flow: 30-day warning banners, dose entry confirmation dialogs, manual completion button updates, and notification integration.

**Critical Medical Safety Requirement**: Users must explicitly confirm dose increases rather than having them auto-apply. GLP-1 dose titrations are frequently delayed due to side effects, patient tolerance, or doctor's orders.

## Scope Reassessment

### Current State Validation
✅ **Scope remains valid** - This is critical medical safety functionality that:
- Addresses patient safety risk identified in production code (TODO comment)
- Builds on existing titration infrastructure (`ScheduleService+Titration.swift`)
- Has clear dependencies on related work (Issue #260 for notifications)
- Follows established patterns for confirmation dialogs and warning banners

### Dependencies Check
- ✅ **Issue #289 (CLOSED)**: ScheduleService error handling - prerequisite complete
- 🔄 **Issue #260 (OPEN)**: Notification UI & Configuration - Stream D coordinates with this
- ⚠️ **Issue #285**: reminderMinutes field (P2) - optional enhancement, not blocking

### Strategic Assessment
This issue should proceed as planned because:
1. **Patient Safety Priority**: Addresses critical safety gap where dose increases happen silently
2. **Natural Parallelization**: Four independent streams with minimal overlap
3. **Incremental Value**: Each stream delivers standalone value (banner, dialog, button, notifications)
4. **Existing Foundation**: Builds on completed ScheduleService+Titration infrastructure

## Parallel Streams

### Stream A: Warning Banner Integration (30-day Advance Notice)
**Scope**: Integrate existing `getTitrationWarning()` method into Settings UI with tap navigation to Dose Titration Plan

**Implementation Files**:
- `JabTracker/Views/Settings/MedicationProfileViewModel.swift` - Add titration warning fetch
- `JabTracker/Views/Settings/Components/ScheduleSummaryView.swift` - Display warning banner with tap handling
- `JabTracker/Views/Settings/Components/MedicationScheduleSection.swift` - Pass titration warning to ScheduleSummaryView

**Unit/Integration Testing Files**:
- `JabTrackerTests/MedicationProfileViewModelTests.swift` - Test warning data fetch (NEW or extend existing)
- `JabTrackerTests/ScheduleService+TitrationTests.swift` - Verify getTitrationWarning() logic (may exist)

**E2E Testing Files**:
- `JabTrackerUITests/TitrationWarningBannerUITests.swift` (NEW) - Tests:
  - Warning banner displays when titration within 30 days (AC1)
  - Banner shows correct message format (AC2)
  - Tapping banner navigates to Dose Titration Plan (AC3)
  - Warning uses getTitrationWarning() method (integration verification) (AC4)

**Product Area**: frontend (SwiftUI views + ViewModel)
**Can Start**: immediately
**Estimated Hours**: 5
**Dependencies**: none

**Acceptance Criteria**: AC1-AC4

---

### Stream B: Dose Entry Confirmation Dialog
**Scope**: Add titration check in dose entry flow and create TitrationConfirmationDialog component with three user actions

**Implementation Files**:
- `JabTracker/Views/Dashboard/QuickDoseViewModel.swift` - Add titration check before dose entry
- `JabTracker/Services/DoseService.swift` - Add titration confirmation logic
- `JabTracker/Views/Dose/TitrationConfirmationDialog.swift` (NEW) - SwiftUI dialog component
- `JabTracker/Services/ScheduleService+Titration.swift` - Add reschedule method if needed

**Unit/Integration Testing Files**:
- `JabTrackerTests/QuickDoseViewModelTests.swift` - Test titration check logic (extend existing)
- `JabTrackerTests/DoseServiceTests.swift` - Test confirmation flow logic
- `JabTrackerTests/ScheduleService+TitrationTests.swift` - Test reschedule and markCompleted methods

**E2E Testing Files**:
- `JabTrackerUITests/TitrationConfirmationDialogUITests.swift` (NEW) - Tests:
  - Dialog appears on/after scheduled titration date (AC5)
  - Dialog shows correct title and dose amounts (AC6)
  - "Complete Now" marks titration completed and updates currentDose (AC7)
  - "Complete Now" uses new dose amount for current entry (AC8)
  - "Reschedule" opens date picker and updates date (AC9)
  - "Remind Me Later" dismisses and prompts again next time (AC10)

**Product Area**: fullstack (ViewModel + Service + SwiftUI)
**Can Start**: immediately
**Estimated Hours**: 9
**Dependencies**: none

**Acceptance Criteria**: AC5-AC10

---

### Stream C: Manual Completion Button Updates
**Scope**: Update "Complete" button behavior in Dose Titration Plan screen to disable/hide after scheduled date passes

**Implementation Files**:
- `JabTracker/Views/MedicationProfile/DoseTitrationView.swift` - Update Complete button state logic

**Unit/Integration Testing Files**:
- `JabTrackerTests/DoseTitrationViewTests.swift` (NEW if needed) - Test button state logic

**E2E Testing Files**:
- `JabTrackerUITests/DoseTitrationManualCompletionUITests.swift` (NEW) - Tests:
  - "Complete" button works for early completion (AC11)
  - Button disables/hides after scheduled date (AC12)
  - Screen shows "Use dose entry to complete" message after date (AC13)

**Product Area**: frontend (SwiftUI view logic)
**Can Start**: immediately
**Estimated Hours**: 3
**Dependencies**: none

**Acceptance Criteria**: AC11-AC13

---

### Stream D: Notification Integration
**Scope**: Add titration notification scheduling with notification actions (coordinate with Issue #260)

**Implementation Files**:
- `JabTracker/Services/NotificationService+Actions.swift` - Add titration notification actions (Complete, Reschedule, Remind)
- `JabTracker/Services/NotificationService.swift` - Add titration notification scheduling method
- `JabTracker/Services/ScheduleService+Titration.swift` - Coordinate notification scheduling

**Unit/Integration Testing Files**:
- `JabTrackerTests/NotificationServiceActionTests.swift` - Test titration notification actions (extend existing)
- `JabTrackerTests/NotificationServiceTests.swift` - Test titration notification scheduling

**E2E Testing Files**:
- `JabTrackerUITests/TitrationNotificationUITests.swift` (NEW) - Tests:
  - Notification sent on titration date with correct message (AC14)
  - Notification actions (Complete, Reschedule, Remind) work correctly (AC15)

**Product Area**: backend (notification service)
**Can Start**: after coordination checkpoint with Issue #260
**Estimated Hours**: 5
**Dependencies**: Issue #260 (coordinate notification patterns)

**Acceptance Criteria**: AC14-AC15

**⚠️ Coordination Note**: This stream requires coordination with Issue #260 to ensure consistent notification action patterns. Recommend brief sync before starting implementation.

---

## Coordination Points

### Shared Files
The following files may be modified by multiple streams:

- `JabTracker/Services/ScheduleService+Titration.swift`
  - Stream B: May add reschedule method
  - Stream D: May add notification scheduling hook
  - **Risk**: LOW - extension file with clear method separation
  - **Mitigation**: Coordinate method naming/signatures before implementation

- `JabTracker/Services/DoseService.swift`
  - Stream B: Add titration confirmation logic
  - **Risk**: LOW - single stream owner

### Sequential Requirements
No strict sequential dependencies. All streams can start in parallel with one coordination checkpoint:

1. **Stream D Coordination Checkpoint**: Brief sync with Issue #260 before starting to align notification action patterns

### Cross-Stream Integration Points

**Stream A → Stream C**: Both touch titration UI in Settings
- **Integration**: Warning banner (A) and Manual completion button (C) appear in same Settings area
- **Testing**: Verify visual layout doesn't conflict

**Stream B → Stream D**: Dose entry dialog and notifications
- **Integration**: Both trigger titration confirmation flow (one via dose entry, one via notification)
- **Testing**: Ensure consistent behavior between dialog triggers

## Conflict Risk Assessment

- **Low Risk**:
  - Streams A, C work on completely separate view files
  - Clear file ownership with minimal overlap

- **Medium Risk**:
  - Stream B and D both may touch `ScheduleService+Titration.swift`
  - Manageable through coordination of method additions

- **High Risk**:
  - None identified - streams are well-isolated

## Parallelization Strategy

**Recommended Approach**: Hybrid Parallel with Coordination Checkpoint

**Execution Plan**:
1. **Phase 1 (Parallel)**: Launch Streams A, B, C simultaneously
   - All three can proceed independently
   - No file conflicts expected

2. **Phase 2 (Coordinated Start)**: Launch Stream D after coordination checkpoint
   - Brief sync with Issue #260 to align notification patterns
   - Can overlap with Phase 1 streams after checkpoint

**Why Hybrid?**
- Streams A, B, C are completely independent and can run in parallel
- Stream D requires coordination but doesn't block other work
- Coordination checkpoint is brief (15-30 minutes discussion)

## Expected Timeline

### With Parallel Execution:
- **Phase 1** (Parallel A+B+C): ~9 hours (longest stream)
- **Phase 2** (Stream D after checkpoint): ~5 hours
- **Wall time**: ~14 hours (with coordination overhead)
- **Total work**: 22 hours
- **Efficiency gain**: 36% (22h → 14h)

### Without Parallel Execution:
- **Wall time**: 22 hours (sequential)

## Testing Strategy

### Unit/Integration Tests (Outside-In TDD - RED Phase First)
Each stream follows TDD approach:
1. Write failing unit tests for business logic
2. Implement minimal code to pass tests
3. Write integration tests for component interactions
4. Refactor as needed

**Expected Test Count**:
- Stream A: 4-6 unit tests
- Stream B: 8-12 unit tests (most complex logic)
- Stream C: 2-4 unit tests
- Stream D: 4-6 unit tests
- **Total**: ~18-28 unit/integration tests

### E2E Tests (Outside-In TDD - GREEN Phase Acceptance)
After unit/integration tests pass, write comprehensive E2E tests:
- Stream A: 4 E2E tests (AC1-AC4)
- Stream B: 6 E2E tests (AC5-AC10)
- Stream C: 3 E2E tests (AC11-AC13)
- Stream D: 2 E2E tests (AC14-AC15)
- **Total**: 15 E2E tests

**E2E Test Execution**:
- Individual test execution during development
- Full suite run before PR merge
- VoiceOver accessibility validation for all new UI

## Notes

### Medical Safety Considerations
- **User Confirmation Required**: All streams must enforce explicit user confirmation for dose increases
- **No Auto-Apply**: System must NEVER automatically increase dose without user action
- **Clear Messaging**: All UI must clearly indicate old dose → new dose amounts

### Implementation Guidelines
- Use existing `ScheduleService+Titration.swift` methods where possible
- Follow established dialog patterns from `JabTracker/Views/Settings/Components/`
- Ensure all new UI has proper accessibility identifiers for E2E testing
- Coordinate Stream D with Issue #260 before implementation

### Definition of Done (All Streams)
- [ ] All acceptance criteria validated through tests
- [ ] Unit tests written and passing (TDD RED → GREEN)
- [ ] Integration tests written and passing
- [ ] E2E tests written and passing (TDD ACCEPTANCE)
- [ ] VoiceOver accessibility tested for new UI components
- [ ] Code review complete
- [ ] Documentation updated for new user-facing features
- [ ] Coordination with Issue #260 completed (Stream D)
