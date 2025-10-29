---
issue: 260
stream: Deeplink Handling & Onboarding Integration
agent: parallel-stream-developer
started: 2025-10-29T18:48:25Z
status: pending
simulator: 3
simulator_uuid: FF190E2B-E6A1-461F-BEAF-E9A827038FA1
test_command: "./scripts/test.sh unit 3"
---

# Stream C: Deeplink Handling & Onboarding Integration

## Scope
Implement notification deeplink handling (`jab-tracker://` URL scheme) and complete onboarding integration. Enable NotificationService when user grants permission during onboarding.

- **REMINDER**: Follow TDD approach with immediate test feedback
- **DEPENDENCY**: Wait for Stream B to complete enable() method before starting

## Branch
issue/260-notification-ui-configuration-settings-integration-and-permission-management

## Testing
- **Assigned Simulator**: 3 (FF190E2B-E6A1-461F-BEAF-E9A827038FA1)
- **Simulator UUID**: FF190E2B-E6A1-461F-BEAF-E9A827038FA1
- **Test Command**: `./scripts/test.sh unit 3`
- **UI Test Command**: `./scripts/test.sh ui 3 NotificationDeeplinkUITests`

## Implementation Files
- `JabTracker/App/JabTrackerApp.swift` (modify - add onOpenURL handler)
- `JabTracker/App/DeeplinkHandler.swift` (new - dedicated deeplink parsing and routing)
- `JabTracker/Onboarding/OnboardingViewModel.swift` (modify - enable NotificationService when permission granted)
- `Info.plist` (modify - add URL type for jab-tracker:// scheme)

## Unit/Integration Test Files
- `JabTrackerTests/DeeplinkHandlerTests.swift` (new - 12+ tests)
- `JabTrackerTests/OnboardingNotificationIntegrationTests.swift` (new - 8+ tests)

## E2E Test Files
- `JabTrackerUITests/NotificationDeeplinkUITests.swift` (new - 5 tests)
- `JabTrackerUITests/OnboardingNotificationFlowUITests.swift` (new - 4 tests)

## Progress
- Waiting for Stream B to complete (requires NotificationService.enable() method)
- Will start after Stream B Phase 1 completes
