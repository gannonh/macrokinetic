---
issue: 286
stream: Warning Banner Integration
agent: parallel-stream-developer
started: 2025-10-23T20:25:33Z
status: in_progress
simulator: 1
simulator_uuid: 336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB
test_command: "./scripts/test.sh unit 1"
---

# Stream A: Warning Banner Integration

## Scope
Integrate existing `getTitrationWarning()` method into Settings UI with 30-day advance warning banner and tap navigation to Dose Titration Plan.

**REMINDER**: Follow TDD approach with immediate test feedback

## Branch
issue/286-implement-comprehensive-titration-completion-workflow-with-user-confirmation-dialog

## Testing
- **Assigned Simulator**: 1 (iPhone 15)
- **Simulator UUID**: 336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB
- **Test Command**: `./scripts/test.sh unit 1`
- **UI Test Command**: `./scripts/test.sh ui 1 TitrationWarningBannerUITests`

## Implementation Files
- `JabTracker/Views/Settings/MedicationProfileViewModel.swift` - Add titration warning fetch
- `JabTracker/Views/Settings/Components/ScheduleSummaryView.swift` - Display warning banner with tap handling
- `JabTracker/Views/Settings/Components/MedicationScheduleSection.swift` - Pass titration warning to ScheduleSummaryView

## Unit/Integration Test Files
- `JabTrackerTests/MedicationProfileViewModelTests.swift` - Test warning data fetch (extend existing)
- `JabTrackerTests/ScheduleService+TitrationTests.swift` - Verify getTitrationWarning() logic (may exist)

## E2E Test Files
- `JabTrackerUITests/TitrationWarningBannerUITests.swift` (NEW) - Tests:
  - Warning banner displays when titration within 30 days (AC1)
  - Banner shows correct message format (AC2)
  - Tapping banner navigates to Dose Titration Plan (AC3)
  - Warning uses getTitrationWarning() method (integration verification) (AC4)

## Acceptance Criteria
- [ ] AC1: Warning banner displays when titration within 30 days
- [ ] AC2: Banner shows correct message: "Your dose will increase to {new_dose}mg on {date} per your titration plan"
- [ ] AC3: Tapping banner navigates to Dose Titration Plan screen
- [ ] AC4: Warning uses existing `getTitrationWarning(for: schedule)` method

## Progress
- Starting implementation with TDD approach
