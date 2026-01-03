---
trigger: glob
globs: *Tests/**/*.swift, !*UITests/**/*.swift
---

# iOS Unit & Integration Testing (Swift Testing)

## Framework Overview

- **Framework**: Swift Testing (modern, preferred) + XCTest (legacy)
- **Version**: Xcode via xcodebuild
- **Config**: project.yml (XcodeGen) or .xcodeproj
- **Output Formatter**: xcbeautify
- **Unit Test Directory**: {ProjectName}Tests/
- **Naming Pattern**: *Tests.swift

## Swift Testing Framework (Modern Pattern)

### Basic Test Structure

```swift
import Testing
@testable import AppName

@Test("Calculate next scheduled event time")
@MainActor
func testGetNextScheduledTime() async {
    let context = createTestContext()
    let item = createTestItem(context: context)

    let viewModel = ScheduleViewModel()
    viewModel.selectedItem = item

    let nextTime = viewModel.getNextScheduledTime()

    // Use #expect for modern assertions
    #expect(nextTime != nil, "Expected getNextScheduledTime() to return a non-nil value")

    // Safe unwrapping to avoid crashes
    guard let nextTime = nextTime else {
        #expect(Bool(false), "nextTime was nil when it shouldn't be")
        return
    }

    // Verify timing with tolerance
    let timeDifference = abs(nextTime.timeIntervalSinceNow)
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
@testable import AppName

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

## Coverage Policy (Tiered System)

### Recommended Coverage Tiers

Projects should define coverage thresholds in a `coverage-config.json` file:

- **Tier 1 - Pure Business Logic (90%)**: Models, calculators, pure functions
- **Tier 2 - Infrastructure (60%)**: Services, data management
- **Tier 3 - Framework Integration (42%)**: Apple framework wrappers (Auth, Biometrics, Notifications)
- **Tier 4 - View Models (85%)**: ObservableObject classes with testable logic
- **Tier 5 - Utilities (75%)**: Helper functions, extensions
- **SwiftUI Views (15% or exempt)**: View bodies cannot be unit tested
- **Overall Coverage**: Informational only (SwiftUI architecture limits this)

### Coverage Workflow

**Step 1: Generate coverage data**
```bash
# Run tests with coverage enabled (saves to .coverage/coverage.xcresult)
./scripts/check-coverage.sh

# Or run tests first, then check coverage with existing data
./scripts/test.sh unit 1 --coverage
./scripts/check-coverage.sh --use-existing
```

**Step 2: Analyze coverage**
```bash
# Human-readable report (filter by file pattern)
./scripts/coverage-detail.sh                    # Full report
./scripts/coverage-detail.sh DateNightService   # Filter by pattern

# JSON-based queries for programmatic analysis
./scripts/coverage-json.sh --summary            # File overview sorted by %
./scripts/coverage-json.sh --functions          # Show uncovered functions only
./scripts/coverage-json.sh DateNightService     # JSON for specific file
```


### Understanding Coverage Output

**Coverage JSON structure:**
```json
{
  "name": "MyService.swift",
  "lineCoverage": 0.75,
  "coveredLines": 45,
  "executableLines": 60,
  "functions": [
    {
      "name": "myMethod()",
      "lineCoverage": 1.0,
      "coveredLines": 10,
      "executableLines": 10,
      "executionCount": 5
    }
  ]
}
```

**Key metrics:**
- `lineCoverage`: Percentage (0.0-1.0)
- `executionCount`: How many times a function was called (0 = never tested)
- `coveredLines / executableLines`: Line-level detail

**Common Coverage Issues:**

| Issue                      | Symptom                               | Solution                                                  |
| -------------------------- | ------------------------------------- | --------------------------------------------------------- |
| Tests pass but 0% coverage | `executionCount: 0` for all functio