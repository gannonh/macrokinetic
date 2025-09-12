---
framework: xcodebuild_swift_testing
test_command: ./scripts/test.sh
created: 2025-01-22T04:47:23Z
---

# Testing Configuration

## Framework
- Type: Xcode with Swift Testing + XCUITest  
- Version: Xcode (via xcodebuild)
- Config File: JabTracker.xcodeproj
- Output Formatter: xcbeautify

## Test Structure
- Unit Test Directory: JabTrackerTests/
- UI Test Directory: JabTrackerUITests/
- Unit Test Files: 42 files found
- UI Test Files: 25 files found
- Naming Pattern: *Tests.swift

## Test Categories
### Unit Tests (Swift Testing Framework)
- **Authentication**: AuthenticationManager*, BiometricAuth*, Authentication*
- **Data Management**: DataController*, MedicationManager*, Persistence*  
- **Models**: User*, Medication*, DoseTitration*, ReconstitutionCalculator*
- **UI Components**: DesignSystem*, ButtonStyle*, UserProfileView*
- **Business Logic**: OnboardingViewModel*, SubscriptionManager*, PricingCalculator*
- **Medical Calculations**: Pharmacokinetics*, ProfileValidation*

### UI Tests (XCUITest Framework)  
- **Authentication Flow**: AuthenticationUITests, ManualAuthenticationUITests
- **Onboarding**: OnboardingUITests
- **Medication Management**: MedicationProfile*UITests
- **Subscription Flow**: SubscriptionUI*Tests
- **Design System**: DesignSystemUITests
- **CloudKit Integration**: CloudKitIntegrationUITests

## Commands
- **Run All Tests**: `./scripts/test.sh all`
- **Run Unit Tests Only**: `./scripts/test.sh unit`
- **Run UI Tests Only**: `./scripts/test.sh ui`
- **Run Specific Test File**: `./scripts/test.sh {unit|ui} 1 {TestFileName}`
- **Run with Coverage**: `./scripts/test.sh unit 1 --coverage`
- **Run with Simulator Reset**: `./scripts/test.sh ui 1 --reset`

## Available Simulators
1. **PRIMARY** iPhone 15,OS=17.5 (Default - UUID: 336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB)
2. **SECONDARY** iPhone 15 Pro Max,OS=17.5 (UUID: BFE552DA-1CB4-4736-821D-270EC6307512)
3. **TERTIARY** iPhone SE (3rd generation),OS=17.5 (UUID: FF190E2B-E6A1-461F-BEAF-E9A827038FA1)

## Environment
- **Required Tools**: xcodebuild, xcbeautify, xcrun simctl
- **iOS Target**: iOS 17.0+  
- **Test Devices**: iOS Simulator
- **Launch Arguments**: --ui-testing (auth bypass), --reset-app-data, --force-onboarding
- **Coverage**: Available via xccov with --coverage flag

## Test-Runner Agent Configuration
- Use test-runner agent for all test executions
- Maximum verbosity enabled for debugging
- Sequential execution (no parallel testing)
- Real services - no mocking
- Complete output capture including stack traces  
- Test structure validation before assuming code issues
- Coverage analysis when requested

## Special Test Cases
- **Manual Authentication Tests**: Excluded from automated runs, require real Apple ID interaction
- **UI Testing Mode**: Uses --ui-testing launch argument for authentication bypass
- **Coverage Policy**: 5-tier system with different thresholds per component type
- **File-Based Organization**: Swift Testing uses file-based test structure for efficiency

## Common Test Commands
```bash
# Quick unit test run
./scripts/test.sh unit 1

# Full UI test suite (excludes manual tests)  
./scripts/test.sh ui 1

# Specific test with coverage
./scripts/test.sh unit 1 AuthenticationManagerCoreTests --coverage

# Reset simulator and run UI tests
./scripts/test.sh ui 1 --reset

# All tests with coverage report
./scripts/test.sh all 1 --coverage
```

## Test Execution Notes
- Always use test-runner agent for consistent output formatting
- Swift Testing framework handles unit tests with modern syntax
- UI tests use XCUITest with accessibility-based element selection  
- Coverage reports saved to `/tmp/jab-tracker-coverage.xcresult`
- Manual authentication tests require Xcode for interactive Apple ID flow