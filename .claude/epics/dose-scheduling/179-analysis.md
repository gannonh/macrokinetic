---
issue: 179
title: Medication Profile CRUD
analyzed: 2025-10-18T18:43:30Z
estimated_hours: 16
parallelization_factor: 2.5
---

# Parallel Work Analysis: Issue #179

## Overview
Integrate comprehensive schedule management into medication profile editing. This adds schedule CRUD operations (create, read, update, delete), pause/resume functionality, schedule history timeline, and schedule summary display to the existing MedicationProfileSettingsView. Users can fully manage their dose schedules from the medication profile screen.

## Scope Reassessment

### Current State Validation
✅ **Dependencies Complete**: Tasks 174 (SwiftData Models) and 175 (ScheduleService) are closed
✅ **Relevant Work**: Schedule management is core functionality for dose tracking application
✅ **No Prior Implementation**: MedicationProfileSettingsView exists but has no schedule integration
✅ **Scope Appropriate**: Task focuses on UI integration with existing backend services

### Work Remaining
This task extends existing medication profile UI with schedule management features:
- Add "Dose Schedule" section to MedicationProfileSettingsView
- Create 4 new UI components (ScheduleSummaryView, DoseScheduleEditView, PauseScheduleSheet, ScheduleHistoryRow)
- Extend MedicationProfileViewModel with schedule CRUD methods
- Add E2E tests for schedule management workflows

## Parallel Streams

### Stream A: UI Components
**Scope**: Create reusable schedule UI components that display schedule information and provide editing/management interfaces

**Implementation Files**:
- `JabTracker/Views/Settings/Components/ScheduleSummaryView.swift`
- `JabTracker/Views/Settings/Components/PauseScheduleSheet.swift`
- `JabTracker/Views/Settings/Components/ScheduleHistoryRow.swift`
- `JabTracker/Views/Settings/Components/ScheduleHistoryItem.swift`

**Unit/Integration Testing Files**:
- `JabTrackerTests/ScheduleSummaryViewTests.swift`
- `JabTrackerTests/PauseScheduleSheetTests.swift`
- `JabTrackerTests/ScheduleHistoryRowTests.swift`

**E2E Testing Files**:
- Not applicable (components tested via parent view E2E tests in Stream C)

**Product Area**: frontend
**Can Start**: immediately
**Estimated Hours**: 6
**Dependencies**: none

**Testing Strategy**: Unit tests for component logic (time formatting, pause duration calculations, history item display). Components will be validated through parent view E2E tests in Stream C.

---

### Stream B: ViewModel & Integration
**Scope**: Extend MedicationProfileViewModel with schedule management methods and integrate schedule section into MedicationProfileSettingsView

**Implementation Files**:
- `JabTracker/Views/Settings/MedicationProfileViewModel.swift` (extend)
- `JabTracker/Views/Settings/MedicationProfileSettingsView.swift` (extend)
- `JabTracker/Views/Settings/DoseScheduleEditView.swift`

**Unit/Integration Testing Files**:
- `JabTrackerTests/MedicationProfileViewModelScheduleTests.swift`
- `JabTrackerTests/DoseScheduleEditViewTests.swift`

**E2E Testing Files**:
- Not applicable (integration tested via Stream C E2E tests)

**Product Area**: fullstack
**Can Start**: immediately (parallel with Stream A)
**Estimated Hours**: 6
**Dependencies**: none (uses existing ScheduleService from Task 175)

**Testing Strategy**: Unit tests for ViewModel schedule CRUD methods (loadActiveSchedule, updateSchedule, pauseSchedule, resumeSchedule, deactivateSchedule). Integration tests for ScheduleService + ViewModel coordination. E2E validation handled by Stream C.

---

### Stream C: E2E Testing & Validation
**Scope**: Comprehensive E2E tests for schedule management workflows, accessibility validation, and performance testing

**Implementation Files**:
- None (testing only)

**Unit/Integration Testing Files**:
- Not applicable

**E2E Testing Files**:
- `JabTrackerUITests/MedicationProfileScheduleManagementUITests.swift`

**Product Area**: frontend
**Can Start**: after Streams A & B reach 80% completion
**Estimated Hours**: 4
**Dependencies**: Streams A & B (needs UI components and ViewModel integration)

**Testing Strategy**: E2E tests covering:
- AC4: Edit existing schedule and verify changes
- AC5: Pause schedule and verify "Paused" status
- AC6: Resume paused schedule and verify active status
- AC7: Deactivate schedule and verify removal
- AC8: Create new schedule for medication without one
- AC9: VoiceOver navigation through schedule management
- AC11-13: Titration warning display and navigation
- NFR1-2: Performance validation (schedule save <500ms, history load <200ms)

## Coordination Points

### Shared Files
- `JabTracker/Views/Settings/MedicationProfileSettingsView.swift` - Stream B only (no conflict)
- `JabTracker/Views/Settings/MedicationProfileViewModel.swift` - Stream B only (no conflict)

### Sequential Requirements
1. **Stream A & B Complete** → Stream C can start E2E testing
2. **UI Components (Stream A)** → Referenced by parent view (Stream B)
3. **ViewModel Extensions (Stream B)** → Used by UI components (Stream A) via @Bindable

### Integration Strategy
- **Stream A** creates standalone UI components with mock data/bindings
- **Stream B** integrates components into parent view with real ViewModel
- **Stream C** validates end-to-end workflows once A & B are substantially complete

## Conflict Risk Assessment
- **Low Risk**: Clear file ownership, no overlap between streams
- **Component Dependencies**: Stream A components used by Stream B, but interface contracts are clear from task specification
- **Testing Coordination**: Stream C waits for A & B completion, preventing premature E2E testing

## Parallelization Strategy

**Recommended Approach**: hybrid

**Phase 1 (Parallel)**: Launch Streams A & B simultaneously
- Stream A: Build UI components independently with mock data
- Stream B: Extend ViewModel and parent view, stubbing component usage initially

**Phase 2 (Sequential)**: Stream C after A & B reach 80%
- Stream C: E2E testing and validation once UI and ViewModel integration complete

**Rationale**:
- Streams A & B are independent (different files, clear interfaces)
- Stream C requires substantial completion of A & B for meaningful E2E testing
- 2.5x parallelization efficiency with minimal coordination overhead

## Expected Timeline

**With parallel execution**:
- Wall time: **10 hours** (6h for A & B in parallel, then 4h for C)
- Total work: 16 hours
- Efficiency gain: **37.5%**

**Without parallel execution**:
- Wall time: 16 hours (6h + 6h + 4h sequentially)

## Notes

### Reusable Components
- **SchedulePatternPicker**: Reuse from Task 004 onboarding (not created in this task)
- **ScheduleService**: Use existing service from Task 175 (no modifications needed)

### Edge Cases to Address
1. **No Active Schedule**: Show "Create Dose Schedule" button (Stream B)
2. **Indefinite Pause**: Handle nil pauseUntil date (Stream A - PauseScheduleSheet)
3. **Schedule History Empty**: Don't display history section (Stream B)
4. **Titration Warning**: Conditionally display based on ScheduleService.getTitrationWarning() (Stream A - ScheduleSummaryView)

### Accessibility Requirements
- All interactive controls need accessibility labels (Stream A components)
- VoiceOver navigation validation (Stream C E2E tests)
- Schedule status announcements for pause/resume (Stream B ViewModel)

### Performance Considerations
- **Schedule history**: Limit to last 50 entries, paginate if needed (Stream B)
- **Next dose calculation**: Cache result in ViewModel, refresh on schedule changes (Stream B)
- **Notification queue**: Update via NotificationService when schedule changes (Stream B integration)

### TDD Approach
**Stream A**: Unit tests for time formatting, duration calculations, history item display
**Stream B**: Unit tests for ViewModel methods, integration tests for ScheduleService coordination
**Stream C**: E2E acceptance tests for complete user workflows

Each stream follows outside-in TDD:
1. Stub E2E acceptance criteria (Stream C defines success)
2. Unit tests → implementation → refactor (Streams A & B)
3. Integration tests → implementation → refactor (Stream B)
4. Full E2E tests (Stream C validates entire feature)
