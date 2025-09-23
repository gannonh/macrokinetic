---
issue: 56
stream: Date Selection Enhancement & E2E Completion
agent: general-purpose
started: 2025-09-23T22:42:29Z
status: in_progress
simulator: 1
simulator_uuid: 336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB
test_command: "./scripts/test.sh unit 1"
ui_test_command: "./scripts/test.sh ui 1 ConcentrationTimelineChartUITests"
---

# Stream D: Date Selection Enhancement & E2E Completion

## Scope
Add date picker to QuickDoseEntry and complete E2E tests that were left as stubs in Stream C
- **REMINDER**: Follow TDD approach with immediate test feedback

## Branch
issue/56-implement-concentrationtimelinechart

## Testing
- **Assigned Simulator**: 1 (iPhone 15)
- **Simulator UUID**: 336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB
- **Test Command**: `./scripts/test.sh unit 1`
- **UI Test Command**: `./scripts/test.sh ui 1 ConcentrationTimelineChartUITests`

## Files
- `JabTracker/Views/DoseEntry/QuickDoseEntry.swift` (add date picker)
- `JabTracker/Views/Dashboard/QuickDoseViewModel.swift` (separate date/time properties)
- `JabTrackerTests/Views/QuickDoseEntryTests.swift` (test date selection)
- `JabTrackerUITests/ConcentrationTimelineChartUITests.swift` (implement actual E2E tests)
- `JabTrackerUITests/ChartControlsUITests.swift` (implement actual E2E tests)

## Progress
- Starting implementation
- Need to add date picker functionality
- Need to complete E2E tests with debug-first approach