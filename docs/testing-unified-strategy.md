# JabTracker Unified Testing Strategy

## Overview

JabTracker employs a comprehensive testing strategy that balances unit testing for business logic with end-to-end (E2E) integration testing for external services. This approach ensures fast, reliable unit tests alongside realistic integration validation.

## Testing Framework Stack

- **Unit Testing**: Swift Testing framework (`@Test`, `#expect`)
- **E2E Testing**: XCUITest framework for UI and integration testing
- **StoreKit Testing**: SKTestSession for subscription flows
- **Build Tools**: xcbeautify for enhanced test output formatting
- **Coverage Analysis**: Xcode Code Coverage with policy-based validation

## Testing Tiers

### 1. Unit Tests (Fast, Isolated)

**Purpose**: Test business logic, data models, and internal algorithms without external dependencies.

**Coverage Targets**:
- Pure Business Logic: 90% (Medication, User, Dose, MedicationProfile, PharmacokineticsEngine)
- View Models: 85% (OnboardingViewModel)
- Infrastructure: 62% (DataController - business logic only)
- Framework Integration: 42% (AuthenticationManager, BiometricAuthManager, SubscriptionManager - state management)
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
- StoreKit purchases and subscriptions
- Data persistence across app launches
- Error handling with real service failures

**Characteristics**:
- Use real Apple ID credentials (or sandbox testers for subscriptions)
- Make actual CloudKit/StoreKit API calls
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

### Subscription Management (StoreKit 2)

**Challenge**: StoreKit 2 product loading, purchase flows, and transaction listeners depend on App Store sandbox behavior that is slow and nondeterministic in a plain unit test context.

**Solution**: Multi-layer approach

#### StoreKit Testing Layers

| Layer                               | Purpose                            | Automation Level   | Apple Account Needed |
| ----------------------------------- | ---------------------------------- | ------------------ | -------------------- |
| StoreKit Configuration (.storekit)  | Fast deterministic simulator tests | Full (CI)          | No                   |
| SKTestSession Programmatic Control  | Edge cases & time travel           | Full (CI)          | No                   |
| Sandbox Testers (App Store Connect) | Real network/receipt pipeline      | Manual/Semi        | Yes (sandbox)        |
| TestFlight (Internal)               | Distribution realism               | Manual             | Sandbox Apple ID     |
| Production Canary (Passive)         | Runtime assurance                  | Observability only | Real users           |

**Unit Tests**: Extract deterministic business rules
- Status evaluation (`evaluateStatus`)
- Trial day calculation (`trialDaysRemaining`)
- Premium access logic
- Pure functions tested without mocks

**Integration Tests**: SKTestSession for automated flows
```swift
func testMonthlyPurchaseAndRenewal() async throws {
    let session = try SKTestSession(configurationFileNamed: "JabTrackerStoreKit")
    session.resetToInitialState()
    session.disableDialogs = true
    
    let products = try await Product.products(for: ["premium.monthly"])
    let monthly = try XCTUnwrap(products.first)
    let result = try await monthly.purchase()
    
    // Simulate time for renewals
    try session.advanceTime(by: 12 * 60)
    
    // Assert active entitlement
    let entitlements = await Transaction.currentEntitlements
    // Validation logic...
}
```

**Test Matrix for Subscriptions**:

| Scenario                       | Layer           | Automated? | Notes                          |
| ------------------------------ | --------------- | ---------- | ------------------------------ |
| Initial purchase (monthly)     | StoreKit Config | Yes        | Core path                      |
| Initial purchase (annual)      | StoreKit Config | Yes        | Pricing tier coverage          |
| Trial → first renewal          | SKTestSession   | Yes        | Time advance                   |
| Multiple renewals              | SKTestSession   | Yes        | Entitlement stability          |
| Grace period (billing failure) | SKTestSession   | Yes        | Enable failTransactionsEnabled |
| Restore on fresh install       | SKTestSession   | Yes        | Clear transactions & restore   |
| Refund/revocation              | SKTestSession   | Yes        | Revoke entitlements            |
| Real sandbox purchase          | Sandbox         | Manual     | Weekly regression              |

## Test Organization

### File Structure
```
JabTrackerTests/
├── Unit/
│   ├── Models/           # User, Dose, MedicationProfile tests
│   ├── BusinessLogic/    # Medication, PharmacokineticsEngine tests  
│   ├── Infrastructure/   # DataController business logic tests
│   └── Utilities/        # ProfileValidation, extension tests
└── Integration/          # Complex multi-component tests
    └── SubscriptionIntegrationTests.swift  # SKTestSession tests

JabTrackerUITests/
├── AuthenticationUITests.swift        # Real Sign in with Apple
├── CloudKitIntegrationUITests.swift   # Real CloudKit testing
├── OnboardingUITests.swift            # Complete user flows
├── SubscriptionUITests.swift          # StoreKit UI flows
└── TestUtilities.swift                # Shared UI test helpers
```

### Test Naming Conventions

**Unit Tests**: Focus on behavior being tested
```swift
@Test("Weight validation accepts valid ranges")  
@Test("Medication half-life values are medically accurate")
@Test("Entitlement evaluation handles revoked state")
```

**E2E Tests**: Focus on user flows and integration scenarios  
```swift
func testCompleteSignInWithAppleFlow()
func testCloudKitSyncStatusDisplay()
func testMonthlySubscriptionPurchaseAndRenewal()
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

// StoreKit transaction streams
private func listenForTransactions() {
    guard !isTestEnvironment else { return }
    // Transaction.currentEntitlements hangs in unit tests
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

# StoreKit integration tests (CI)
xcodebuild test -scheme JabTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' \
  -only-testing:JabTrackerTests/SubscriptionIntegrationTests
```

## Test Data Management

### Unit Tests
- Use `DataController.testContainer()` for isolated, in-memory storage
- Create minimal test data focused on specific behavior
- Clean up automatically through test container disposal

### E2E Tests  
- Use `--reset-app-data` launch argument for clean state
- Use `--ui-testing` for bypassing authentication when testing other flows
- Use real authentication when specifically testing auth integration

### Subscription Tests
- Use `.storekit` configuration file for deterministic product data
- Sandbox testers mapped in documentation (email → scenario)
- SKTestSession for time travel and transaction manipulation

## Best Practices

### Unit Testing
1. **Test Behavior, Not Implementation**: Focus on observable outcomes
2. **Minimal Test Data**: Create only data needed for specific test
3. **Clear Expectations**: Use descriptive assertions with custom messages
4. **Fast Execution**: Keep tests under 1 second each
5. **Pure Functions**: Extract business logic into testable pure functions

### E2E Testing
1. **Realistic Scenarios**: Test complete user workflows
2. **Environmental Tolerance**: Handle network issues and service unavailability gracefully  
3. **Clear User Actions**: Use TestUtilities for common UI operations
4. **Proper Timeouts**: Allow sufficient time for real service responses
5. **Stable Identifiers**: Use accessibility identifiers, not localized strings

### Subscription Testing
1. **Never Automate Real Purchases**: Use StoreKit configuration and sandbox only
2. **Time Travel**: Use SKTestSession.advanceTime(), not Task.sleep()
3. **Entitlement Contract**: Pure function for state evaluation
4. **Accessibility Identifiers**: Stable identifiers for UI elements
5. **Refund Testing**: First-class test cases for revocation scenarios

### General
1. **TDD Approach**: Write failing tests before implementation
2. **Single Responsibility**: Each test validates one specific behavior
3. **Descriptive Names**: Test names should explain what is being validated
4. **Documentation**: Comment complex test setups and expectations

## Troubleshooting Common Issues

### Unit Test Coverage Not Updating
- Ensure explicit property access in tests
- Check for guard conditions preventing code execution in test environment
- Use business logic tests with mocks instead of calling external services
- Extract pure functions from framework-dependent code

### E2E Tests Flaky or Failing
- Increase timeouts for network-dependent operations
- Add proper wait conditions for UI elements
- Verify test device has proper iCloud account configuration
- Use `describe_ui` tool for precise element location

### Authentication Testing Issues  
- Use `--ui-testing` flag to bypass real authentication for non-auth flows
- Test real authentication separately with dedicated test methods
- Handle biometric authentication simulator limitations

### Subscription Testing Issues
- Ensure `.storekit` configuration included in scheme
- Reset SKTestSession state between tests
- Use disableDialogs for automated flows
- Clear transactions for restore testing

## Entitlement Evaluation Contract

**Input**: Sequence<Transaction> (verified) + current date  
**Output**: `EntitlementState { case notSubscribed, trialEnds(Date), active(expiration: Date), inGrace(expiration: Date), revoked }`

**Pure function invariants**:
- Latest non-revoked subscription per product governs
- Trial recognized if `transaction.offerType == .introductory` and not previously consumed
- Grace/billing retry flagged if renewal transaction pending but last period expired

## Future Considerations

### Potential Improvements
1. **Snapshot Testing**: Consider SwiftUI snapshot testing for complex views
2. **Performance Testing**: Add automated performance regression testing
3. **Accessibility Testing**: Expand automated accessibility validation
4. **Device Matrix**: Test on wider range of devices and OS versions
5. **Server Receipt Validation**: Lightweight server receipt validation (hybrid: local preflight + remote trust)

### Scaling Strategy  
- Maintain clear separation between unit and E2E tests
- Consider test parallelization for faster CI execution
- Evaluate property-based testing for complex business logic
- Add contract testing for any future API integrations
- Telemetry-based flaky test auto-rerun for subscription suite

## Resources

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [XCUITest Best Practices](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [StoreKit Testing](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)
- [SKTestSession Documentation](https://developer.apple.com/documentation/storekittest/sktestsession)
- [Code Coverage in Xcode](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/07-code_coverage.html)
- Project Coverage Policy: `coverage-config.json`
- StoreKit Configuration: `JabTrackerStoreKit.storekit`
- Test Utilities: `JabTrackerUITests/TestUtilities.swift`