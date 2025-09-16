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

## Commands (All tests automatically log to ./logs directory)
- **Run Unit Tests**: `./scripts/test.sh unit 1` (RECOMMENDED)
- **Run Specific UI Test Class**: `./scripts/test.sh ui 1 OnboardingUITests` (RECOMMENDED)
- **Run Specific UI Test Method**: `./scripts/test.sh ui 1 OnboardingUITests/testCompleteOnboardingFlow` (RECOMMENDED)
- **Run Specific Test File**: `./scripts/test.sh {unit|ui} 1 {TestFileName}`
- **Run with Coverage**: `./scripts/test.sh unit 1 --coverage`
- **Run with Simulator Reset**: `./scripts/test.sh ui 1 OnboardingUITests --reset`
- **Help**: `./scripts/test.sh --help`

### New Logging Flags
- **No Logging**: `./scripts/test.sh unit 1 --no-log`
- **Log Only (Silent)**: `./scripts/test.sh unit 1 --log-only`

### ⚠️ AVOID (Very Slow - Use Only for Final Verification)
- **All UI Tests**: `./scripts/test.sh ui 1` (takes 10+ minutes)
- **All Tests**: `./scripts/test.sh all 1` (very long running)

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
- **Automatic Logging**: All test runs save to ./logs with timestamped directories
- **Log Access**: `cat logs/latest/output.txt` or `open logs/latest/results.xcresult`


## Special Test Cases
- **Manual Authentication Tests**: Excluded from automated runs, require real Apple ID interaction
- **UI Testing Mode**: Uses --ui-testing launch argument for authentication bypass
- **Coverage Policy**: 5-tier system with different thresholds per component type
- **File-Based Organization**: Swift Testing uses file-based test structure for efficiency

## Common Test Commands (All automatically log to ./logs)
```bash
# Quick unit test run (RECOMMENDED)
./scripts/test.sh unit 1

# Specific UI test class (RECOMMENDED)
./scripts/test.sh ui 1 OnboardingUITests

# Run specific UI test method (RECOMMENDED)
./scripts/test.sh ui 1 OnboardingUITests/testCompleteOnboardingFlow

# Specific test with coverage
./scripts/test.sh unit 1 AuthenticationManagerCoreTests --coverage

# Reset simulator and run specific UI tests
./scripts/test.sh ui 1 OnboardingUITests --reset

# Coverage analysis in background
./scripts/test.sh unit 1 --coverage --log-only

# View latest test results
cat logs/latest/output.txt

# ⚠️ AVOID unless final verification (very slow):
# ./scripts/test.sh ui 1              # ALL UI tests - takes 10+ minutes
# ./scripts/test.sh all 1 --coverage   # ALL tests with coverage - very slow
```

## Test Execution Notes
- All test runs automatically log to `./logs/{test_type}_YYYY-MM-DD_HH-MM-SS/`
- Latest test results always available via `logs/latest` symlink
- Swift Testing framework handles unit tests with modern syntax
- UI tests use XCUITest with accessibility-based element selection
- **PREFER specific UI test classes** over running all UI tests (performance)
- Coverage reports saved to test log directory and `/tmp/jab-tracker-coverage.xcresult`
- Manual authentication tests require Xcode for interactive Apple ID flow
- Log files include: `output.txt`, `results.xcresult`, `coverage.json` (if --coverage used)