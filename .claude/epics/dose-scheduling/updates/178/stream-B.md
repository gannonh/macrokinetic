---
issue: 178
stream: B - Action Sheet UI & Dose Management
agent: parallel-stream-developer
started: 2025-10-13T18:16:00Z
status: in_progress
simulator: 2
simulator_uuid: BFE552DA-1CB4-4736-821D-270EC6307512
test_command: "./scripts/test.sh unit 2"
phase: 2
---

# Stream B: Action Sheet UI & Dose Management

## Scope
Create action sheets for dose management (log, reschedule, skip) with QuickDoseSheet integration
- **REMINDER**: Follow TDD approach with immediate test feedback
- **PHASE 2 STREAM**: Builds upon Stream A's foundation

## Branch
issue/178-calendar-integration

## Testing
- **Assigned Simulator**: 2 (iPhone 15 Pro Max)
- **Simulator UUID**: BFE552DA-1CB4-4736-821D-270EC6307512
- **Test Command**: `./scripts/test.sh unit 2`
- **UI Test Command**: `./scripts/test.sh ui 2 CalendarDoseActionsUITests`

## Implementation Files
- `JabTracker/Views/History/Components/DoseActionSheet.swift` (new - action sheet for dose management)
- `JabTracker/Views/History/Components/RescheduleDoseSheet.swift` (new - reschedule UI with date picker)
- `JabTracker/Views/History/DoseCalendarView.swift` (extend - add long-press gesture handling)

## Unit/Integration Test Files
- `JabTrackerTests/Views/DoseActionSheetTests.swift` (unit tests for action handling)
- `JabTrackerTests/Views/RescheduleDoseSheetTests.swift` (unit tests for reschedule validation)

## E2E Test Files
- `JabTrackerUITests/CalendarDoseActionsUITests.swift` (E2E: long-press, log, reschedule, skip)
- `JabTrackerUITests/CalendarQuickDoseIntegrationUITests.swift` (E2E: QuickDoseSheet pre-population)

## Acceptance Criteria for Stream B
- [ ] **AC3**: Long-press on calendar day with scheduled dose opens DoseActionSheet
- [ ] **AC4**: DoseActionSheet displays: Log Dose, Reschedule, Skip, Dismiss actions
- [ ] **AC5**: "Log Dose" action opens QuickDoseSheet with pre-populated scheduled dose details
- [ ] **AC6**: "Reschedule" action opens RescheduleDoseSheet with date/time picker and smart suggestions
- [ ] **AC7**: "Skip" action marks dose as skipped and removes from calendar scheduled indicators

## Non-Functional Requirements for Stream B
- [ ] **NFR2**: Long-press gesture detection <300ms response time
- [ ] **NFR4**: VoiceOver support for all dose actions

## Testing Requirements for Stream B
- [ ] **Test5**: E2E test: Long-press scheduled dose → open action sheet → log dose
- [ ] **Test6**: E2E test: Long-press scheduled dose → reschedule → verify updated calendar
- [ ] **Test7**: E2E test: Long-press scheduled dose → skip → verify removed from calendar

## Progress
- Phase 2: Building upon Stream A's calendar extension foundation
- Waiting to start after Stream A completion
