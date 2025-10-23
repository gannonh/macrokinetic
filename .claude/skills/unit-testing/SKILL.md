---
name: unit-testing
description: Unit and integration testing with Swift Testing framework for JabTracker iOS app - modern test patterns, SwiftData testing, coverage policy, and test organization
---

# Unit & Integration Testing Skill

This skill provides comprehensive guidance for writing, debugging, and executing unit and integration tests using the Swift Testing framework for the JabTracker iOS application.

## When to Use This Skill

Use this skill when you need to:
- Write new unit tests for business logic
- Write integration tests for component interactions
- Debug failing unit/integration tests
- Understand Swift Testing framework patterns
- Set up test data with SwiftData
- Work with the 5-tier coverage policy
- Handle async testing and MainActor requirements

## Framework Overview

- **Framework**: Swift Testing (modern, preferred) + XCTest (legacy)
- **Version**: Xcode via xcodebuild
- **Config**: JabTracker.xcodeproj
- **Output Formatter**: xcbeautify
- **Unit Test Directory**: JabTrackerTests/
- **Unit Test Files**: 42+ files
- **Naming Pattern**: *Tests.swift

## Swift Testing Framework (Modern Pattern)

### Basic Test Structure

```swift
import Testing
@testable import JabTracker

@Test("Calculate next scheduled dose for weekly medication")
@MainActor
func testGetNextScheduledDoseTimeWeekly() async {
    let context = createTestContext()
    let profile = createTestMedicationProfile(
        context: context,
        genericName: "semaglutide"
    )

    // Add a dose from 1 week ago
    _ = createTestDose(context: context, medication: profile)

    let viewModel = QuickDoseViewModel()
    viewModel.selectedMedicationProfile = profile

    let nextDoseTime = viewModel.getNextScheduledDoseTime()

    // Use #expect for modern assertions
    #expect(nextDoseTime != nil, "Expected getNextScheduledDoseTime() to return a non-nil value")

    // Safe unwrapping to avoid crashes
    guard let nextDoseTime = nextDoseTime else {
        #expect(Bool(false), "nextDoseTime was nil when it shouldn't be")
        return
    }

    // Verify timing with tolerance
    let timeDifference = abs(nextDoseTime.timeIntervalSinceNow)
    #expect(timeDifference < 24 * 60 * 60, "Time difference should be within 24 hours")
}
```

### Modern Swift Testing vs XCTest

**✅ Swift Testing - Modern, cleaner syntax:**
```swift
@Test("User creation with valid data")
func testUserCreation() {
    let user = User(email: "test@example.com", name: "Test User")
    #expect(user.email == "test@example.com")
    #expect(user.name == "Test User")
}
```

**❌ XCTest - Legacy syntax (avoid in new tests):**
```swift
func testUserCreation() throws {
    let user = User(email: "test@example.com", name: "Test User")
    XCTAssertEqual(user.email, "test@example.com")
    XCTAssertEqual(user.name, "Test User")
}
```

## Test Data Management

### Unit Test Seeding (Direct SwiftData Access)

Unit tests have direct access to SwiftData for fast, reliable test data:

```swift
// Unit tests have direct access to SwiftData
@Test("Test with seeded data")
@MainActor
func myTest() throws {
    let container = try TestDataSeeding.createTestContainer()
    let context = container.mainContext

    // Seed data with preset config
    let result = try TestDataSeeding.seedData(
        into: context,
        config: .medium  // 30 days, ~4-5 doses, 95% adherence
    )

    // Use seeded data
    #expect(result.doses.count > 0)
    #expect(result.adherenceRate >= 0.90)
}
```

### Available Preset Configurations

```swift
// Seven Days: 7 days, 100% adherence, no variability (quick tests)
let result = try TestDataSeeding.seedData(into: context, config: .sevenDays)

// Thirty Days: 30 days, 95% adherence, timing variability (standard tests)
let result = try TestDataSeeding.seedData(into: context, config: .thirtyDays)

// Ninety Days: 90 days, 93% adherence, realistic patterns (performance tests)
let result = try TestDataSeeding.seedData(into: context, config: .ninetyDays)

// One Year: 365 days, 92% adherence, realistic patterns (performance tests)
let result = try TestDataSeeding.seedData(into: context, config: .oneYear)

// Two Years: 730 days, 90% adherence (stress tests)
let result = try TestDataSeeding.seedData(into: context, config: .twoYears)
```

### Custom Configuration

```swift
let customConfig = TestDataSeedingConfig(
    daysOfHistory: 90,
    medication: .tirzepatide,
    brandName: "Mounjaro",
    doseAmount: 5.0,
    injectionSites: ["Abdomen", "Thigh"],
    adherenceRate: 1.0,
    addTimingVariability: false,
    includeSkippedDoses: false
)

let result = try TestDataSeeding.seedData(into: context, config: customConfig)
```

### Quick Helper Methods

```swift
// Create individual entities for testing
let user = TestDataSeeding.createTestUser()
let profile = TestDataSeeding.createTestMedicationProfile()
let doses = TestDataSeeding.createTestDoses(
    count: 10,
    amount: 0.5,
    daysApart: 7,
    profile: profile
)
```

### Test Data Result Structure

```swift
struct TestDataSeedingResult {
    let user: User
    let medicationProfile: MedicationProfile
    let doses: [Dose]                // Successfully taken doses
    let skippedDoses: [Dose]         // Missed/skipped doses
    let expectedDoseCount: Int       // Total scheduled doses
    let actualDoseCount: Int         // Actually taken doses
    let adherenceRate: Double        // Percentage adherence (0.0-1.0)
}
```

### Performance Notes

**Unit Test Seeding (Direct SwiftData):**
- **Small datasets** (7 days): ~10ms generation
- **Medium datasets** (30 days): ~30ms generation
- **Large datasets** (365 days): ~70ms generation
- **Extra large datasets** (730 days): ~170ms generation

## SwiftData Testing Patterns

### Creating Test Context

```swift
func createTestContext() -> ModelContext {
    let schema = Schema([User.self, MedicationProfile.self, Dose.self])
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none  // Critical: Disable CloudKit for tests
    )
    let container = try! ModelContainer(for: schema, configurations: [config])
    return ModelContext(container)
}
```

### ⚠️ CRITICAL: SwiftData Relationship Anti-Pattern

**NEVER assign arrays to SwiftData relationships in tests:**

```swift
// ❌ THIS WILL CRASH THE APP - NEVER DO THIS
medicationProfile.doses = existingDoses
user.medicationProfiles = [profile1, profile2]

// ✅ CORRECT - Use individual property setters instead
for dose in existingDoses {
    dose.medication = medicationProfile  // Sets individual relationship
}
// OR avoid relationships entirely in test-only code
_ = existingDoses  // Keep for test setup but don't assign to relationship
```

**Why this crashes:**
- SwiftData uses computed properties with complex setter logic
- Direct array assignment bypasses SwiftData's relationship management
- Causes crashes in `@__swiftmacro_` generated code
- Test environment makes this worse due to lack of proper ModelContext

**Safe testing patterns:**
1. **Pass arrays directly to engine methods** instead of using relationships
2. **Use ModelContainer with proper context** when relationships are required
3. **Comment why relationships are avoided** in test-only scenarios
4. **Test relationship-dependent methods with empty profiles** to verify graceful handling

## Async Testing Best Practices

### @MainActor for UI Components

```swift
// Always mark async tests with @MainActor when testing UI components
@Test("Verify medication profile selection updates state")
@MainActor
func testMedicationProfileSelection() async {
    let viewModel = OnboardingViewModel()
    let medication = Medication.semaglutide

    // Test async state changes
    await viewModel.selectMedication(medication)

    #expect(viewModel.selectedMedication == medication)
    #expect(viewModel.canProceedToNextStep == true)
}
```

## Safe Unwrapping Patterns

### Avoid Force Unwrapping

```swift
// ❌ Avoid force unwrapping that can crash tests
let result = viewModel.calculateDose()!

// ✅ Use safe unwrapping with explicit test failures
guard let result = viewModel.calculateDose() else {
    #expect(Bool(false), "calculateDose() returned nil unexpectedly")
    return
}

// ✅ Alternative pattern with nil validation
let result = viewModel.calculateDose()
#expect(result != nil, "Expected calculateDose() to return a value")
```

## Tolerance-Based Assertions

### Time/Date Comparisons

```swift
// ❌ Exact time comparisons can be flaky
#expect(nextDose == expectedDate)

// ✅ Use tolerance for time-based assertions
let timeDifference = abs(nextDose.timeIntervalSince(expectedDate))
#expect(timeDifference < 60, "Time should be within 1 minute tolerance")

// ✅ For dose scheduling (more generous tolerance)
let timeDifference = abs(nextDoseTime.timeIntervalSinceNow)
#expect(timeDifference < 24 * 60 * 60, "Next dose should be within 24 hours")
```

## Test Organization

### File-Based Organization

Swift Testing uses file-based test structure for efficiency:

```swift
// File: AuthenticationManagerTests.swift
import Testing
@testable import JabTracker

// All tests related to AuthenticationManager in one file
@Test("Sign in creates user successfully")
func testSignInCreatesUser() {
    // Test implementation
}

@Test("Sign out clears user data")
func testSignOutClearsData() {
    // Test implementation
}
```

### Test Categories

**Unit & Integration Tests (Swift Testing Framework):**
- **Authentication**: AuthenticationManager*, BiometricAuth*, Authentication*
- **Data Management**: DataController*, MedicationManager*, Persistence*
- **Models**: User*, Medication*, DoseTitration*, ReconstitutionCalculator*
- **UI Components**: DesignSystem*, ButtonStyle*, UserProfileView*
- **Business Logic**: OnboardingViewModel*, SubscriptionManager*, PricingCalculator*
- **Medical Calculations**: Pharmacokinetics*, ProfileValidation*

## Test Factories for Consistency

### Extension-Based Factories

```swift
extension User {
    static func testUser(
        email: String = "test@example.com",
        name: String? = "Test User",
        weight: Double = 70.0
    ) -> User {
        User(email: email, name: name, weight: weight)
    }
}

extension MedicationProfile {
    static func testProfile(
        genericName: String = "semaglutide",
        brandName: String = "Ozempic",
        currentDose: Double = 0.5
    ) -> MedicationProfile {
        MedicationProfile(
            genericName: genericName,
            brandName: brandName,
            currentDose: currentDose
        )
    }
}
```

## Coverage Policy (5-Tier System)

### Coverage Tiers

- **Tier 1 - Pure Business Logic (90%)**: PharmacokineticsEngine, Models (User, Dose, MedicationProfile, Medication), ReconstitutionCalculator, DoseTitration
- **Tier 2 - Infrastructure (62%)**: DataController, MedicationManager
- **Tier 3 - Framework Integration (42%)**: AuthenticationManager, BiometricAuthManager, SubscriptionManager
- **Tier 4 - View Models (85%)**: OnboardingViewModel
- **Tier 5 - Utilities (75%)**: ProfileValidation, Array+Unique, SubscriptionProducts
- **SwiftUI Views**: No coverage requirements (view bodies cannot be unit tested)
- **Overall Coverage**: ~20% (informational only, not a requirement)

### Checking Coverage Compliance

```bash
# Validate coverage config (REQUIRED)
./scripts/check-coverage-config.sh

# Check coverage policy compliance (RECOMMENDED)
./scripts/check-coverage.sh

# Run tests with coverage
./scripts/test.sh unit 1 --coverage
```

### Coverage Analysis Tools

```bash
# Full coverage report
./scripts/coverage-detail.sh

# Specific file coverage
./scripts/coverage-detail.sh DataController
./scripts/coverage-detail.sh AuthenticationManager

# Quick file overview sorted by coverage
./scripts/coverage-json.sh --summary

# Show uncovered functions only
./scripts/coverage-json.sh --functions

# JSON data for specific file
./scripts/coverage-json.sh DataController
```

### Understanding Coverage Output

**Coverage shows function-level and line-level detail:**
- `0.00% (0/X)` means completely uncovered function with X executable lines
- Private methods need indirect testing through public methods that call them
- Async methods may need `Task.sleep()` waits in tests for proper coverage

**Common Coverage Issues:**
- Result bundle not found: Run tests with `--coverage` first
- Private method coverage: Use public methods that invoke them
- Async method coverage: Add `Task.sleep()` waits in tests
- Delegate method coverage: Create proper mock controllers/requests

## Running Unit Tests

### Recommended Commands

```bash
# Quick unit test run (RECOMMENDED)
./scripts/test.sh unit 1

# Run specific unit test suite (RECOMMENDED)
./scripts/test.sh unit 1 AuthenticationManagerCoreTests

# Specific test with coverage
./scripts/test.sh unit 1 AuthenticationManagerCoreTests --coverage

# Coverage analysis in background
./scripts/test.sh unit 1 --coverage --log-only

# View latest test results
cat logs/latest/raw_output.txt
```

### Logging Flags

```bash
# No logging
./scripts/test.sh unit 1 --no-log

# Log only (silent console output)
./scripts/test.sh unit 1 --log-only
```

### Swift Testing Framework Limitations

**Unit Test Targeting Support:**
- ✅ **Target Level**: `./scripts/test.sh unit 1` (all unit tests)
- ✅ **Suite Level**: `./scripts/test.sh unit 1 AuthenticationManagerCoreTests` (specific test suite)
- ❌ **Method Level**: Swift Testing doesn't support individual method isolation

**Note**: Unlike XCTest, Swift Testing framework doesn't support running individual unit test methods. When you specify a method name for unit tests, the entire test suite will run. For granular testing, organize tests into focused test suites/classes.

## Test Execution Notes

- All test runs automatically log to `./logs/{test_type}_YYYY-MM-DD_HH-MM-SS/`
- Latest test results always available via `logs/latest` symlink
- Swift Testing framework handles unit tests with modern syntax
- Coverage reports saved to test log directory and `/tmp/jab-tracker-coverage.xcresult`
- Log files include: `raw_output.txt`, `results.xcresult`, `coverage.json` (if --coverage used)

## Integration Testing Patterns

### Testing Component Interactions

```swift
@Test("AnalyticsService coordinates User, Dose, and MedicationProfile correctly")
@MainActor
func testAnalyticsServiceIntegration() async throws {
    let context = createTestContext()

    // Seed realistic test data
    let result = try TestDataSeeding.seedData(
        into: context,
        config: .thirtyDays
    )

    let analyticsService = AnalyticsService(context: context)

    // Test cross-model analytics coordination
    let summary = await analyticsService.generateUserSummary(for: result.user)

    #expect(summary.overallAdherence >= 0.90)
    #expect(summary.medicationEffectiveness.count > 0)
    #expect(summary.concentrationTrends.count > 0)
}
```

### Service Integration Testing

```swift
@Test("ChartDataProcessor integrates with PharmacokineticsEngine correctly")
@MainActor
func testChartProcessorIntegration() async throws {
    let context = createTestContext()
    let result = try TestDataSeeding.seedData(into: context, config: .ninetyDays)

    let pkEngine = PharmacokineticsEngine()
    let chartProcessor = ChartDataProcessor()

    // Test integration between services
    let chartData = chartProcessor.generateConcentrationTimeline(
        doses: result.doses,
        medication: result.medicationProfile.medication,
        engine: pkEngine
    )

    #expect(chartData.points.count > 0)
    #expect(chartData.renderTime < 100) // < 100ms for 90 days
}
```

## Common Patterns

### Testing Error Handling

```swift
@Test("Invalid dose amount throws appropriate error")
func testInvalidDoseThrowsError() async {
    let validator = DoseValidator()

    await #expect(throws: MedicationError.invalidDose) {
        try validator.validate(dose: -1.0, medication: .semaglutide)
    }
}
```

### Testing State Changes

```swift
@Test("ViewModel updates state correctly on user action")
@MainActor
func testViewModelStateChange() async {
    let viewModel = OnboardingViewModel()

    // Initial state
    #expect(viewModel.currentStep == .welcome)
    #expect(viewModel.canProceedToNextStep == true)

    // Trigger state change
    await viewModel.proceedToNextStep()

    // Verify new state
    #expect(viewModel.currentStep == .medicationSelection)
}
```

### Testing Computed Properties

```swift
@Test("MedicationProfile computes next dose time correctly")
func testNextDoseTimeComputation() {
    let profile = MedicationProfile.testProfile()
    profile.frequency = .weekly
    profile.lastDoseDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 1 week ago

    let nextDose = profile.nextDoseTime

    // Should be approximately now (within 1 hour tolerance)
    let timeDifference = abs(nextDose.timeIntervalSinceNow)
    #expect(timeDifference < 3600)
}
```

## Best Practices

### ✅ Do This

1. **Use Swift Testing for new tests** - Modern, cleaner syntax
2. **Use @MainActor for UI components** - Ensures proper thread safety
3. **Safe unwrapping with guard** - Avoid force unwrapping
4. **Tolerance-based time assertions** - Account for timing variability
5. **Direct SwiftData access in tests** - Fast, reliable test data
6. **Disable CloudKit in test config** - Prevents relationship crashes
7. **Test factories for consistency** - Reusable test data creation
8. **File-based organization** - Group related tests in same file
9. **Coverage-driven development** - Meet tier requirements

### ❌ Don't Do This

1. **Don't use XCTest for new tests** - Legacy pattern, use Swift Testing
2. **Don't assign arrays to SwiftData relationships** - Causes crashes
3. **Don't force unwrap in tests** - Use safe unwrapping patterns
4. **Don't use exact time comparisons** - Always use tolerance
5. **Don't skip @MainActor** - Required for UI component testing
6. **Don't enable CloudKit in tests** - Causes relationship validation errors
7. **Don't duplicate test data setup** - Use factories and helpers
8. **Don't write tests without coverage check** - Maintain tier standards

## Example: Complete Unit Test

```swift
import Testing
@testable import JabTracker

final class PharmacokineticsEngineTests {

    // MARK: - Test Data Setup

    func createTestContext() -> ModelContext {
        let schema = Schema([User.self, MedicationProfile.self, Dose.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    // MARK: - Tests

    @Test("Calculate concentration for single dose")
    @MainActor
    func testSingleDoseConcentration() throws {
        let context = createTestContext()
        let engine = PharmacokineticsEngine()

        // Create test dose
        let dose = Dose(
            amount: 1.0,
            timestamp: Date().addingTimeInterval(-24 * 60 * 60), // 1 day ago
            medication: .semaglutide
        )

        // Calculate concentration
        let concentration = engine.calculateConcentration(
            doses: [dose],
            medication: .semaglutide,
            at: Date()
        )

        // Verify calculation
        #expect(concentration > 0.0)
        #expect(concentration < 1.0) // Should have decayed
    }

    @Test("Calculate steady state progress with multiple doses")
    @MainActor
    func testSteadyStateProgress() throws {
        let context = createTestContext()
        let result = try TestDataSeeding.seedData(
            into: context,
            config: .thirtyDays
        )

        let engine = PharmacokineticsEngine()
        let progress = engine.calculateSteadyStateProgress(
            doses: result.doses,
            medication: result.medicationProfile.medication
        )

        // Verify progress calculation
        #expect(progress >= 0.0)
        #expect(progress <= 1.0)

        // 30 days of weekly doses should be approaching steady state
        #expect(progress > 0.5)
    }

    @Test("Handle empty dose array gracefully")
    @MainActor
    func testEmptyDoseArray() {
        let engine = PharmacokineticsEngine()

        let concentration = engine.calculateConcentration(
            doses: [],
            medication: .semaglutide,
            at: Date()
        )

        #expect(concentration == 0.0)
    }
}
```

## Summary

This skill provides a comprehensive framework for unit and integration testing with Swift Testing. The key principles are:

1. **Modern Swift Testing framework** - Use `@Test` and `#expect` for new tests
2. **Direct SwiftData access** - Fast, reliable test data with proper configuration
3. **SwiftData relationship safety** - Never assign arrays to relationships
4. **Safe unwrapping patterns** - Avoid force unwrapping, use guard statements
5. **Tolerance-based assertions** - Account for timing variability in tests
6. **@MainActor compliance** - Required for UI component and ViewModel testing
7. **5-tier coverage policy** - Meet tier requirements for different component types
8. **Test factories** - Reusable test data creation for consistency
9. **Integration testing** - Verify component interactions and service coordination

Follow these patterns to write reliable, maintainable, and fast unit/integration tests that provide confidence in your code quality while meeting the project's coverage standards.
