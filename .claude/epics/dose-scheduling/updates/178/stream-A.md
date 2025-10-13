---
issue: 178
stream: A - Calendar UI Extensions & Dose Indicators
agent: parallel-stream-developer
started: 2025-10-13T17:14:19Z
status: in_progress
simulator: 1
simulator_uuid: 336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB
test_command: "./scripts/test.sh unit 1"
phase: 1
---

# Stream A: Calendar UI Extensions & Dose Indicators

## Scope
Extend existing calendar views to display scheduled doses with visual indicators
- **REMINDER**: Follow TDD approach with immediate test feedback
- **PHASE 1 RESPONSIBILITY**: Establish foundation for DoseCalendarView extensions that Phase 2 streams will build upon

## Branch
issue/178-calendar-integration

## Testing
- **Assigned Simulator**: 1 (iPhone 15)
- **Simulator UUID**: 336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB
- **Test Command**: `./scripts/test.sh unit 1`
- **UI Test Command**: `./scripts/test.sh ui 1 CalendarScheduledDosesUITests`

## Implementation Files
- `JabTracker/Views/History/DoseCalendarView.swift` (extend - add scheduled dose loading)
- `JabTracker/Views/History/CalendarDayView.swift` (extend - add scheduled dose indicators)
- `JabTracker/Views/History/Components/ScheduledDoseIndicator.swift` (new - visual indicators)
- `JabTracker/Views/History/Components/DoseIndicatorsView.swift` (new - combined display)

## Unit/Integration Test Files
- `JabTrackerTests/Views/DoseCalendarViewTests.swift` (unit tests for dose loading logic)
- `JabTrackerTests/Views/CalendarDayViewTests.swift` (unit tests for indicator display)
- `JabTrackerTests/Views/ScheduledDoseIndicatorTests.swift` (unit tests for visual indicators)

## E2E Test Files
- `JabTrackerUITests/CalendarScheduledDosesUITests.swift` (E2E: viewing scheduled doses on calendar)
- `JabTrackerUITests/CalendarAccessibilityUITests.swift` (E2E: VoiceOver for dose indicators)

## Acceptance Criteria for Stream A
- [ ] **AC1**: Scheduled dose indicators appear on calendar days with scheduled doses
- [ ] **AC2**: Visual distinction between scheduled (blue outline), logged (blue filled), missed (red), skipped (gray) doses
- [ ] **AC9**: Calendar refreshes properly when doses are loaded

## Non-Functional Requirements for Stream A
- [ ] **NFR1**: Calendar rendering with scheduled doses <500ms for 90-day view
- [ ] **NFR3**: Scheduled dose calculation lazy-loaded per month (not all future dates)
- [ ] **NFR5**: Accessibility labels describe dose status clearly

## Testing Requirements for Stream A
- [ ] **Test1**: Unit tests for scheduled dose filtering logic
- [ ] **Test2**: Unit tests for indicator display logic
- [ ] **Test4**: E2E test: View calendar with scheduled doses displayed
- [ ] **Test8**: Accessibility test: VoiceOver describes scheduled vs logged doses correctly

## Progress
- Phase 1: Establishing foundation for DoseCalendarView scheduled dose infrastructure
- This stream completes first - Phase 2 streams (B & C) will build on this foundation
