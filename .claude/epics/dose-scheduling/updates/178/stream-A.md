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

### Session 1 - 2025-10-13 (TDD Phases 1-2 Complete)

**✅ Phase 1: E2E Test Stubs (Complete)**
- Created `CalendarScheduledDosesUITests.swift` with 8 E2E acceptance test stubs
- Created `CalendarAccessibilityUITests.swift` with 5 accessibility E2E test stubs
- All tests properly structured with GIVEN/WHEN/THEN acceptance criteria

**✅ Phase 2: Unit Test Framework (Complete)**
- Created `ScheduledDoseIndicatorTests.swift` - 10 tests for visual indicator component
- Created `DoseCalendarScheduledDosesTests.swift` - 9 tests for scheduled dose loading logic
- Created `CalendarDayScheduledDosesTests.swift` - 12 tests for day view indicator display
- All tests properly failing with descriptive error messages
- Tests cover AC1, AC2, AC9, NFR1, NFR3, NFR5, Test1, Test2, Test4, Test8

**Commits:**
- `59a3791` - Issue #178: Add E2E test stubs for Stream A (calendar scheduled dose indicators)
- `60051a7` - Issue #178: Add failing unit tests for Stream A (scheduled dose indicators and calendar extensions)

**Next Steps:**
- Phase 3: Implement ScheduledDoseIndicator and DoseIndicatorsView components
- Phase 4: Extend DoseCalendarView with scheduled dose loading methods
- Phase 5: Extend CalendarDayView to display scheduled dose indicators
- Phase 6: Implement E2E tests one at a time following debug-first approach

**Architecture Notes:**
- Existing codebase uses @Query pattern directly in DoseCalendarView (no separate ViewModel)
- Will extend DoseCalendarView following existing patterns
- Will use DoseEvent model for combining scheduled and logged doses
- Phase 1 responsibility: establish foundation for Phase 2 streams to build upon
