# JabTracker Testing Strategy

## Overview

JabTracker employs a comprehensive testing strategy that balances unit testing for business logic with end-to-end (E2E) integration testing for external services. This approach ensures both fast, reliable unit tests and realistic integration validation.

## Testing Framework Stack

- **Unit Testing**: Swift Testing framework (`@Test`, `#expect`)
- **E2E Testing**: XCUITest framework for UI and integration testing
- **Build Tools**: xcbeautify for enhanced test output formatting
- **Coverage Analysis**: Xcode Code Coverage with policy-based validation

## Testing Tiers

### 1. Unit Tests (Fast, Isolated)

**Purpose**: Test business logic, data models, and internal algorithms without external dependencies.

**Coverage Targets**:
- Pure Business Logic: 90% (Medication, User, Dose, MedicationProfile, PharmacokineticsEngine)
- View Models: 85% (OnboardingViewModel)
- Infrastructure: 62% (DataController - business logic only)
- Framework Integration: 42% (AuthenticationManager, BiometricAuthManager - state management)
- Utilities: 75% (ProfileValidation, extensions)

**Characteristics**:
- No network calls
- No real Apple framework API calls
- Use mocks/stubs for external dependencies
- Fast execution (< 1 second per test)
- Deterministic results

**Examples**:
```swift
@Test("Medication properties are medically accurate")
func medicationPropertiesAccuracy() throws {
    #expect(Medication.semaglutide.halfLifeDays == 7.0)
    #expect(Medication.semaglutide.frequency == .weekly)
}

@Test("DataController sync status messages")
func syncStatusMessages() throws {
    let controller = DataController.testContainer()
    controller.syncStatus = .available
    #expect(controller.syncStatusMessage == "Syncing with iCloud")
}
```

### 2. End-to-End Integration Tests (Realistic, External Services)

**Purpose**: Test real integrations with Apple services and validate complete user flows.

**Coverage Areas**:
- Real Sign in with Apple authentication
- Actual CloudKit integration and sync
- Complete onboarding flows
- Data persistence across app launches
- Error handling with real service failures

**Characteristics**:
- Use real Apple ID credentials
- Make actual CloudKit API calls
- Test on real devices/simulators with network connectivity
- Slower execution (5-30 seconds per test)
- May have environmental dependencies

**Examples**:
```swift
@MainActor
func testCompleteSignInWithAppleFlow() throws {
    let app = TestUtilities.launchAppWithRealAuth()
    TestUtilities.signInWithApple(app)
    TestUtilities.verifyAuthenticatedState(app)
}

@MainActor  
func testCloudKitSyncStatusDisplay() throws {
    let app = TestUtilities.launchAppWithConfiguration(testMode: false)
    // Tests real CloudKit status detection and UI updates
}
```

## Service-Specific Testing Approaches

### CloudKit Integration

**Problem**: CloudKit requires real iCloud account and network connectivity, making traditional unit testing impractical.

**Solution**: Hybrid approach
- **Unit Tests**: Mock CloudKit responses to test business logic around sync status handling
- **E2E Tests**: Use real CloudKit integration to validate actual sync behavior

**Unit Test Example**:
```swift
@Test("DataController handles all CloudKit status scenarios")
func dataControllerHandlesAllCloudKitStatusScenarios() throws {
    let controller = DataController.testContainer()
    
    controller.syncStatus = .available
    #expect(controller.willSyncAcrossDevices == true)
    #expect(controller.syncStatusMessage == "Syncing with iCloud")
}
```

**E2E Test Coverage** (`CloudKitIntegrationUITests.swift`):
- Real iCloud account status detection
- Actual sync status UI updates  
- Data persistence with CloudKit enabled
- Fallback behavior when CloudKit unavailable
- Retry functionality with real CloudKit API calls

### Authentication (Sign in with Apple)

**Approach**: Parallel testing strategies

**Unit Tests**: Mock authentication scenarios
- Error handling and state management
- Keychain integration security
- Authentication persistence logic

**E2E Tests**: Real Apple ID authentication
- Complete sign-in flow with actual Apple services
- Biometric authentication on real devices
- Authentication state persistence across app launches

## Test Organization

### File Structure
```
JabTrackerTests/
├── Unit/
│   ├── Models/           # User, Dose, MedicationProfile tests
│   ├── BusinessLogic/    # Medication, PharmacokineticsEngine tests  
│   ├── Infrastructure/   # DataController business logic tests
│   └── Utilities/        # ProfileValidation, extension tests
└── Integration/          # Complex multi-component unit tests

JabTrackerUITests/
├── AuthenticationUITests.swift        # Real Sign in with Apple
├── CloudKitIntegrationUITests.swift   # Real CloudKit testing
├── OnboardingUITests.swift            # Complete user flows
└── TestUtilities.swift                # Shared UI test helpers
```

### Test Naming Conventions

**Unit Tests**: Focus on behavior being tested
```swift
@Test("Weight validation accepts valid ranges")  
@Test("Medication half-life values are medically accurate")
@Test("DataController provides user-friendly sync status messages")
```

**E2E Tests**: Focus on user flows and integration scenarios  
```swift
func testCompleteSignInWithAppleFlow()
func testCloudKitSyncStatusDisplay()
func testDataPersistenceWithCloudKitEnabled()
```

## Coverage Policy

### What We Measure
- **Line Coverage**: Percentage of executable lines hit by tests
- **Function Coverage**: Percentage of functions called by tests
- **Branch Coverage**: Percentage of decision branches taken

### What We Don't Measure
- **SwiftUI View Bodies**: Cannot be unit tested due to framework limitations
- **External Service Integration**: Covered by E2E tests instead of unit tests

### Special Cases

**Environment-Blocked Code**: Some methods have test environment guards that prevent execution during unit testing:

```swift
// This method cannot reach 100% unit test coverage
private func checkiCloudStatus() async {
    guard self.isCloudKitEnabled else { return } // Blocks in test environment
    // CloudKit API calls here...
}
```

**Solution**: Document these methods as E2E-only and validate through integration tests.

## Test Execution

### Local Development
```bash
# Fast unit test feedback loop
./scripts/test.sh unit 1    # Unit tests on iPhone 15

# Comprehensive integration testing  
./scripts/test.sh ui 1      # UI tests on iPhone 15

# Full validation before PR
./scripts/test.sh all 1     # All tests
```

### Coverage Analysis
```bash
# Check policy compliance
./scripts/check-coverage.sh

# Detailed coverage investigation  
./scripts/coverage-detail.sh DataController
./scripts/coverage-json.sh --functions  # Find uncovered functions
```

### Continuous Integration
```bash
# Pre-merge validation
./scripts/check-all.sh   # Lint, build, test, format
```

## Test Data Management

### Unit Tests
- Use `DataController.testContainer()` for isolated, in-memory storage
- Create minimal test data focused on the specific behavior being tested
- Clean up automatically through test container disposal

### E2E Tests  
- Use `--reset-app-data` launch argument for clean state
- Use `--ui-testing` for bypassing authentication when testing other flows
- Use real authentication when specifically testing auth integration

## Best Practices

### Unit Testing
1. **Test Behavior, Not Implementation**: Focus on observable outcomes
2. **Minimal Test Data**: Create only the data needed for the specific test
3. **Clear Expectations**: Use descriptive assertions with custom messages
4. **Fast Execution**: Keep tests under 1 second each

### E2E Testing
1. **Realistic Scenarios**: Test complete user workflows
2. **Environmental Tolerance**: Handle network issues and service unavailability gracefully  
3. **Clear User Actions**: Use TestUtilities for common UI operations
4. **Proper Timeouts**: Allow sufficient time for real service responses

### General
1. **TDD Approach**: Write failing tests before implementation
2. **Single Responsibility**: Each test validates one specific behavior
3. **Descriptive Names**: Test names should explain what is being validated
4. **Documentation**: Comment complex test setups and expectations

## Troubleshooting Common Issues

### Unit Test Coverage Not Updating
- Ensure explicit property access in tests (coverage tool requires actual execution)
- Check for guard conditions that prevent code execution in test environment
- Use business logic tests with mocks instead of trying to call external services

### E2E Tests Flaky or Failing
- Increase timeouts for network-dependent operations
- Add proper wait conditions for UI elements
- Verify test device has proper iCloud account configuration
- Use `describe_ui` tool for precise element location instead of screenshots

### Authentication Testing Issues  
- Use `--ui-testing` flag to bypass real authentication for non-auth flows
- Test real authentication separately with dedicated test methods
- Handle biometric authentication simulator limitations

## Future Considerations

### Potential Improvements
1. **Snapshot Testing**: Consider SwiftUI snapshot testing for complex views
2. **Performance Testing**: Add automated performance regression testing
3. **Accessibility Testing**: Expand automated accessibility validation
4. **Device Matrix**: Test on wider range of devices and OS versions

### Scaling Strategy  
- As app grows, maintain clear separation between unit and E2E tests
- Consider test parallelization for faster CI execution
- Evaluate property-based testing for complex business logic
- Add contract testing for any future API integrations

## Resources

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [XCUITest Best Practices](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [Code Coverage in Xcode](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/07-code_coverage.html)
- Project Coverage Policy: `coverage-config.json`
- Test Utilities: `JabTrackerUITests/TestUtilities.swift`