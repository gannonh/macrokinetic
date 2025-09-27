---
framework: xcodebuild_swift_testing
test_command: ./scripts/test.sh
created: 2025-01-22T04:47:23Z
---

# Test Driven Development

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

## ⚠️ CRITICAL TESTING ANTI-PATTERNS - AVOID AT ALL COSTS

### SwiftData Relationship Crashes (MOST COMMON BUG)
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

## Test Categories

### Unit & Integration Tests (Swift Testing Framework)
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
- **Pharmacokinetics Engine**: PKEngineUITests (8 E2E acceptance tests)
- **Subscription Flow**: SubscriptionUI*Tests
- **Design System**: DesignSystemUITests
- **CloudKit Integration**: CloudKitIntegrationUITests

## Commands (All tests automatically log to ./logs directory)

- **Run Unit Tests**: `./scripts/test.sh unit 1` (RECOMMENDED)
- **Run Specific Unit Test Suite**: `./scripts/test.sh unit 1 AuthenticationManagerCoreTests` (RECOMMENDED)
- **Run Specific UI Test Class**: `./scripts/test.sh ui 1 OnboardingUITests` (RECOMMENDED)
- **Run PKEngine E2E Tests**: `./scripts/test.sh ui 1 PKEngineUITests` (RECOMMENDED)
- **Run Specific UI Test Method**: `./scripts/test.sh ui 1 OnboardingUITests/testCompleteOnboardingFlow` (RECOMMENDED)
- **Run Specific Test File**: `./scripts/test.sh {unit|ui} 1 {TestFileName}`
- **Run with Coverage**: `./scripts/test.sh unit 1 --coverage`
- **Run with Simulator Reset**: `./scripts/test.sh ui 1 OnboardingUITests --reset`
- **Help**: `./scripts/test.sh --help`

### Logging Flags
- **No Logging**: `./scripts/test.sh unit 1 --no-log`
- **Log Only (Silent)**: `./scripts/test.sh unit 1 --log-only`

### ⚠️ AVOID (Very Slow - Use Only for Final Verification)
- **All UI Tests**: `./scripts/test.sh ui 1` (takes 10+ minutes)
- **All Tests**: `./scripts/test.sh all 1` (very long running)

## Launch Arguments for Testing

The app supports several launch arguments for testing and development:

**`--ui-testing`**:
- Bypasses real Sign in with Apple authentication
- Creates mock user (`test@uitesting.com`, "UI Test User")
- Used by XCUITest for reliable automated testing
- Can be enabled in Xcode scheme for manual testing without authentication

**`--reset-app-data`**:
- Clears all SwiftData users from database on launch
- Clears onboarding completion status from UserDefaults
- Resets to fresh app state (like first-time install)
- Useful for testing onboarding and first-run experiences

**`--force-onboarding`**:
- Forces onboarding flow to show even if user has completed it
- Useful for repeatedly testing onboarding flow during development
- Overrides normal onboarding completion logic

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
- **Log Access**: `cat logs/latest/raw_output.txt` or `open logs/latest/results.xcresult`


## Special Test Cases
- **Manual Authentication Tests**: Excluded from automated runs, require real Apple ID interaction
- **UI Testing Mode**: Uses --ui-testing launch argument for authentication bypass
- **Coverage Policy**: 5-tier system with different thresholds per component type
- **File-Based Organization**: Swift Testing uses file-based test structure for efficiency

## Swift Testing Framework Limitations

### Unit Test Targeting Support
- ✅ **Target Level**: `./scripts/test.sh unit 1` (all unit tests)
- ✅ **Suite Level**: `./scripts/test.sh unit 1 AuthenticationManagerCoreTests` (specific test suite)
- ❌ **Method Level**: Swift Testing doesn't support individual method isolation

### UI Test Targeting Support
- ✅ **Target Level**: `./scripts/test.sh ui 1` (all UI tests)
- ✅ **Class Level**: `./scripts/test.sh ui 1 OnboardingUITests` (specific test class)
- ✅ **Method Level**: `./scripts/test.sh ui 1 OnboardingUITests/testCompleteOnboardingFlow` (specific method)

**Note**: Unlike XCTest, Swift Testing framework doesn't support running individual unit test methods. When you specify a method name for unit tests, the entire test suite will run. For granular testing, organize tests into focused test suites/classes.

## Common Test Commands (All automatically log to ./logs)
```bash
# Quick unit test run (RECOMMENDED)
./scripts/test.sh unit 1

# Run specific unit test suite (RECOMMENDED)
./scripts/test.sh unit 1 AuthenticationManagerCoreTests

# Run specific UI test method (RECOMMENDED)
./scripts/test.sh ui 1 OnboardingUITests/testCompleteOnboardingFlow

# Specific UI test class
# ⚠️ May be slow if class has many tests - specific methods preferred
./scripts/test.sh ui 1 OnboardingUITests

# Specific test with coverage
./scripts/test.sh unit 1 AuthenticationManagerCoreTests --coverage

# Reset simulator and run specific UI tests
./scripts/test.sh ui 1 OnboardingUITests --reset

# Coverage analysis in background
./scripts/test.sh unit 1 --coverage --log-only

# View latest test results
cat logs/latest/raw_output.txt

# ⚠️ AVOID unless final verification (very slow):
# ./scripts/test.sh ui 1              # ALL UI tests - takes 10+ minutes
# ./scripts/test.sh all 1 --coverage   # ALL tests with coverage - very slow
```
---

## Coverage Policy & Reporting

- Coverage config: `coverage-config.json`
  
```bash
# Enable coverage in Xcode scheme (already configured)
# codeCoverageEnabled = "YES" in JabTracker.xcscheme

# Validate coverage config (REQUIRED)
./scripts/check-coverage-config.sh
# Update coverage config (if needed): `coverage-config.json`

# Check coverage policy compliance (RECOMMENDED)
./scripts/check-coverage.sh

# Run tests with coverage (automatically enabled)
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5'

# View coverage in Xcode UI:
# 1. Run tests with coverage enabled
# 2. Open Report Navigator (⌘9) 
# 3. Select test result -> Coverage tab

# Generate code coverage reports (EASY WAY - use test script)
./scripts/test.sh unit 1 --coverage     # Unit tests with coverage

# COVERAGE ANALYSIS TOOLS (use these for detailed investigation)
./scripts/coverage-detail.sh                    # Full coverage report
./scripts/coverage-detail.sh DataController     # Specific file coverage
./scripts/coverage-detail.sh AuthenticationManager  # Specific file coverage
./scripts/coverage-json.sh --summary           # Quick file overview sorted by coverage
./scripts/coverage-json.sh --functions         # Show uncovered functions only
./scripts/coverage-json.sh DataController      # JSON data for specific file

# Manual coverage generation (if needed)
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -enableCodeCoverage YES -resultBundlePath /tmp/coverage.xcresult -only-testing:JabTrackerTests
xcrun xccov view --report /tmp/coverage.xcresult

# Raw xccov commands (coverage-detail.sh and coverage-json.sh are easier)
xcrun xccov view --report --json /tmp/coverage.xcresult | jq
xcrun xccov view --file-list /tmp/coverage.xcresult
```

**Coverage Policy (5-Tier System):**
- **Tier 1 - Pure Business Logic (90%)**: PharmacokineticsEngine, Models (User, Dose, MedicationProfile, Medication), ReconstitutionCalculator, DoseTitration
- **Tier 2 - Infrastructure (62%)**: DataController, MedicationManager
- **Tier 3 - Framework Integration (42%)**: AuthenticationManager, BiometricAuthManager, SubscriptionManager
- **Tier 4 - View Models (85%)**: OnboardingViewModel
- **Tier 5 - Utilities (75%)**: ProfileValidation, Array+Unique, SubscriptionProducts
- **SwiftUI Views**: No coverage requirements (view bodies cannot be unit tested)
- **Overall Coverage**: ~20% (informational only, not a requirement)

#### Coverage Analysis Tips

**Understanding xccov Output:**
- Coverage shows function-level and line-level detail
- `0.00% (0/X)` means completely uncovered function with X executable lines
- Private methods need indirect testing through public methods that call them
- Async methods may need `Task.sleep()` waits in tests for proper coverage

**Current Coverage Gaps (as of Session 8):**
- **AuthenticationManager**: 39% (below 42% threshold) - needs additional credential handling tests
- **PharmacokineticsEngine**: Not yet implemented - future core requirement
- **SubscriptionProducts**: Not found in coverage report - check test inclusion

**Common Coverage Issues:**
- Result bundle not found: Run tests with `--coverage` first
- Private method coverage: Use public methods that invoke them
- Async method coverage: Add `Task.sleep()` waits in tests
- Delegate method coverage: Create proper mock controllers/requests


## Outside-In TDD Flow

Each outer layer defines the acceptance criteria and contracts for the inner layers. E2E tests are the ultimate acceptance criteria that define when a feature is truly "done" from the user's perspective.

### 1. Stub E2E Acceptance Criteria (All Tests)
Tip: Start with the E2E Test Template: `JabTrackerUITests/Utils/UITestTemplateTest.swift`

First, create stub acceptance tests to define user-facing success criteria:

```swift
 // MARK: - ACCEPTANCE CRITERION: Swipe actions work correctly (edit, delete, skip, duplicate)
      func testNameOfTestMethod() throws {
         // GIVEN: A dose exists in history
         // WHEN: User swipes left on dose row
         // THEN: Edit action appears and functions correctly
         // THEN: Dose entry sheet opens with pre-populated data
      }
```

### 2. Unit & Integration Test Development
2. Write failing unit tests that test isolated business logic and component contracts
3. Implement minimal code to satisfy the unit tests
4. Run unit tests to verify correctness
5. Write failing integration tests that verify component interactions
6. Implement minimal code to satisfy the integration tests
7. Run integration tests to verify correctness

### 3. Iterative E2E Test Implementation (CRITICAL PROCESS)

**⚠️ NEVER write all E2E tests at once before running them - this causes major problems.**

Follow this strict iterative process for E2E test development:

#### Step-by-Step E2E Implementation Process:
1. **Stub acceptance criteria** for all E2E tests to validate the feature (already done in step 1)
2. **Pick ONE test** to implement first
3. **Start with debug utilities** - Use `TestUtilities.debugElements()` to output elements hierarchy
4. **Write the single test** - Implement only one complete test method
5. **Run and verify** - `./scripts/test.sh ui 1 YourTestClass/testSpecificMethod`
6. **Refactor if needed** - Fix element targeting, timing, or logic issues
7. **Commit the test** - Save working test before moving on
8. **Move to next test** - Repeat process for the next test method

#### Debug-First E2E Pattern (Essential):
```swift
func testSpecificFeature() throws {
    let app = TestUtilities.launchAppWithTestMode()
    // Step 1: ALWAYS start with debugging elements
    TestUtilities.debugElements(in: app, containing: "your-feature")

    // Step 2: Read debug output from logs
    // cat logs/latest/raw_output.txt | grep "DEBUG"

    // Step 3: Write test based on actual element types found
    // (not assumptions about SwiftUI → accessibility mapping)

    // Step 4: Run this single test to verify it works
    // ./scripts/test.sh ui 1 YourTestClass/testSpecificFeature
}
```

#### Common E2E Implementation Mistakes:
- ❌ Writing 5+ tests before running any
- ❌ Assuming element types without debugging first
- ❌ Batch testing multiple new methods
- ❌ Skipping debug utilities and guessing selectors

#### Correct E2E Development Flow:
- ✅ One test at a time, debug-first approach
- ✅ Run each test individually: `./scripts/test.sh ui 1 TestClass/testMethod`
- ✅ Commit working tests before adding new ones
- ✅ Use `TestUtilities.debugElements()` liberally during development
---

## E2E Testing Element Targeting (CRITICAL)

**Element targeting is the #1 challenge in E2E testing.** 

Before writing the actual e2e tests, FIRST use `TestUtilities.debugElements()` to print and inspect the actual accessibility hierarchy. SwiftUI often renders elements differently than expected (e.g. List → CollectionView).

### Debug-First Approach

1. Print the hierarchy FIRST:

```swift
// ALWAYS start with debugging the accessibility hierarchy
TestUtilities.debugElements(in: app, containing: "dose-history")

// Example output reveals actual element types:
// 🔍 DEBUG: Tables: []
// 🔍 DEBUG: ScrollViews: []
// 🔍 DEBUG: CollectionViews: ["dose-history-view"]
```

2. Read the raw logs to understand the actual element types and identifiers:

```bash
cat logs/latest/raw_output.txt | grep "DEBUG"
```

### Common SwiftUI → Accessibility Mismatches
- **SwiftUI List** → renders as **CollectionView** (not Table)
- **NavigationStack** → renders as **CollectionView** (not ScrollView)
- **Form toggles** → require coordinate-based tapping, not direct `.tap()`
- **XCUIElementQuery** → has `.count` property, not `.isEmpty` (SwiftLint auto-fix breaks this)

### Essential Utilities
- **`TestUtilities.debugElements()`** - Debug accessibility hierarchy
- **`TestUtilities.clearAndEnterText()`** - Reliable text field interaction
- Use **debug output** to identify correct element types before writing selectors

### Systematic Process
1. Test fails to find element → Add `TestUtilities.debugElements()`
2. Analyze debug output → Identify actual element type and identifier
3. Update test selector → Use correct element type (collectionViews/tables/buttons)
4. Remove debug code → Clean up after fixing selector
5. Document learning → Update style guide for future reference

## Test Execution Notes
- All test runs automatically log to `./logs/{test_type}_YYYY-MM-DD_HH-MM-SS/`
- Latest test results always available via `logs/latest` symlink
- Swift Testing framework handles unit tests with modern syntax
- UI tests use XCUITest with accessibility-based element selection
- **PREFER specific UI test classes** over running all UI tests (performance)
- Coverage reports saved to test log directory and `/tmp/jab-tracker-coverage.xcresult`
- Manual authentication tests require Xcode for interactive Apple ID flow
- Log files include: `raw_output.txt`, `results.xcresult`, `coverage.json` (if --coverage used)