---
issue: 177
stream: A - UI Components & Concentration Preview
agent: parallel-stream-developer
started: 2025-10-08T22:47:33Z
status: in_progress
simulator: 1
simulator_uuid: 336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB
test_command: "./scripts/test.sh unit 1"
---

# Stream A: UI Components & Concentration Preview

## Scope
Build all SwiftUI view components for schedule setup step including:
- ScheduleSetupView (main view)
- SchedulePatternPicker + SchedulePatternCard (pattern selection)
- ConcentrationCurvePreview (chart with PK engine integration)
- ConcentrationLabel (peak/trough labels)
- ReminderPreferencesView (reminder configuration)
- **REMINDER**: Follow TDD approach with immediate test feedback

## Branch
issue/177-onboarding-integration

## Testing
- **Assigned Simulator**: 1 (iPhone 15)
- **Simulator UUID**: 336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB
- **Test Command**: `./scripts/test.sh unit 1`
- **UI Test Command**: `./scripts/test.sh ui 1 OnboardingScheduleSetupUITests`

## Implementation Files
- `JabTracker/Onboarding/Views/ScheduleSetupView.swift`
- `JabTracker/Onboarding/Components/SchedulePatternPicker.swift`
- `JabTracker/Onboarding/Components/SchedulePatternCard.swift`
- `JabTracker/Onboarding/Components/ConcentrationCurvePreview.swift`
- `JabTracker/Onboarding/Components/ConcentrationLabel.swift`
- `JabTracker/Onboarding/Components/ReminderPreferencesView.swift`

## Unit/Integration Test Files
- `JabTrackerTests/Onboarding/ScheduleSetupViewTests.swift`
- `JabTrackerTests/Onboarding/ConcentrationCurvePreviewTests.swift`

## E2E Test Files
- `JabTrackerUITests/OnboardingScheduleSetupUITests.swift` (stub only - full implementation in Stream C)

## Key Requirements
- ConcentrationCurvePreview integrates with existing PharmacokineticsEngine
- Pattern selection uses card-based UI with visual feedback
- Reminder preferences use standard SwiftUI pickers and toggles
- Performance requirement: Chart preview must render in <1 second

## Coordination with Stream B
- Wait for Stream B to add `pkEngine` property to OnboardingViewModel
- Use OnboardingStep.scheduleSetup enum case from Stream B
- Can mock ViewModel initially if needed

## Progress
- Starting implementation with TDD approach
