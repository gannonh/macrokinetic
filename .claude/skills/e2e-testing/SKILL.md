---
name: e2e-testing
description: End-to-end testing with XCUITest for JabTracker iOS app - debug-first element targeting, test data seeding, timing patterns, and screenshot capture
---

# E2E Testing Skill

This skill provides comprehensive guidance for writing, debugging, and executing end-to-end (E2E) tests using XCUITest for the JabTracker iOS application.

## When to Use This Skill

Use this skill when you need to:
- Write new E2E acceptance tests for features
- Debug failing E2E tests with element targeting issues
- Set up test data for E2E scenarios
- Optimize E2E test performance
- Capture screenshots for design review or debugging
- Understand SwiftUI → XCUITest accessibility mapping

## Core Principles

### 1. Debug-First Element Targeting (CRITICAL)

**Element targeting is the #1 challenge in E2E testing.**

Before writing test code, ALWAYS use `TestUtilities.debugElements()` to inspect the actual accessibility hierarchy. SwiftUI often renders elements differently than expected.

```swift
func testSpecificFeature() throws {
    let app = TestUtilities.launchAppWithTestMode()

    // Step 1: ALWAYS start with debugging elements
    TestUtilities.debugElements(in: app, containing: "your-feature")

    // Step 2: Read debug output from logs
    // cat logs/latest/raw_output.txt | grep "DEBUG"

    // Step 3: Write test based on ACTUAL element types found
    // (not assumptions about SwiftUI → accessibility mapping)

    // Step 4: Run this single test to verify it works
    // ./scripts/test.sh ui 1 YourTestClass/testSpecificFeature
}
```

**Common SwiftUI → Accessibility Mismatches:**
- **SwiftUI List** → renders as **CollectionView** (not Table)
- **NavigationStack** → renders as **CollectionView** (not ScrollView)
- **Form toggles** → require coordinate-based tapping, not direct `.tap()`
- **XCUIElementQuery** → has `.count` property, not `.isEmpty`

### 2. Iterative E2E Test Implementation

**⚠️ NEVER write all E2E tests at once before running them.**

Follow this strict iterative process:

1. **Stub acceptance criteria** for all E2E tests (define what needs testing)
2. **Pick ONE test** to implement first
3. **Start with debug utilities** - Use `TestUtilities.debugElements()`
4. **Write the single test** - Implement only one complete test method
5. **Run and verify** - `./scripts/test.sh ui 1 YourTestClass/testSpecificMethod`
6. **Refactor if needed** - Fix element targeting, timing, or logic issues
7. **Commit the test** - Save working test before moving on
8. **Move to next test** - Repeat process

**Common Mistakes:**
- ❌ Writing 5+ tests before running any
- ❌ Assuming element types without debugging first
- ❌ Batch testing multiple new methods
- ❌ Skipping debug utilities and guessing selectors

**Correct Flow:**
- ✅ One test at a time, debug-first approach
- ✅ Run each test individually: `./scripts/test.sh ui 1 TestClass/testMethod`
- ✅ Commit working tests before adding new ones
- ✅ Use `TestUtilities.debugElements()` liberally during development

### 3. Outside-In TDD Flow

E2E tests are the ultimate acceptance criteria that define when a feature is truly "done":

**Step 1: Stub E2E Acceptance Criteria**

Start with the E2E Test Template: `JabTrackerUITests/Utils/UITestTemplateTest.swift`

```swift
// MARK: - ACCEPTANCE CRITERION: Feature works as expected
func testFeatureBehavior() throws {
    // GIVEN: Initial state
    // WHEN: User performs action
    // THEN: Expected outcome occurs
}
```

**Step 2: Unit & Integration Test Development**
- Write failing unit tests for business logic
- Implement minimal code to satisfy unit tests
- Write integration tests for component interactions

**Step 3: Iterative E2E Test Implementation**
- Follow the iterative process above (one test at a time)

## Test Data Seeding

### E2E Test Seeding (Launch Argument Approach)

**Why Launch Arguments?**
XCUITests run in a separate process and cannot directly access the app's SwiftData. The app must detect test mode via launch arguments and seed its own data.

#### Preset-Based Approach (Recommended)

```swift
// E2E tests use launch arguments to trigger seeding
func testChartWithSeededData() throws {
    // Launch app with pre-seeded data using preset
    let app = TestUtilities.launchAppWithSeededData(preset: .thirtyDays)

    // App automatically seeds 30 days of data at startup
    // No UI interaction needed - data is instantly available

    let analyticsTab = app.tabBars.buttons["Analytics"]
    analyticsTab.tap()

    let chart = app.otherElements["concentration-timeline-chart"].firstMatch
    XCTAssertTrue(chart.waitForExistence(timeout: 10))
}
```

**Available Presets:**
```swift
.sevenDays   // 7 days, 1-2 doses
.thirtyDays  // 30 days, ~4-5 doses, realistic adherence
.ninetyDays  // 90 days, ~13 doses, performance testing
.oneYear     // 365 days, ~52 doses, performance testing
.twoYears    // 730 days, ~104 doses, stress testing
```

#### Custom Parameter Approach

For tests requiring specific data configurations:

```swift
// Using setupDoseHistoryTest() convenience method (RECOMMENDED)
func test_doseHistory_medicationFiltering() throws {
    let app = TestUtilities.setupDoseHistoryTest(
        app: XCUIApplication(),
        doseCount: 3,
        medicationProfiles: 2,
        medicationName: "semaglutide",
        brandName: "Ozempic",
        dose: "0.25"
    )

    TestUtilities.navigateToHistoryView(in: app)
    // Test implementation...
}

// Using .custom() preset directly (ALTERNATIVE)
func testCustomDataConfiguration() throws {
    let customPreset = TestUtilities.TestDataPreset.custom(
        doseCount: 5,
        medicationProfiles: 1,
        medication: "tirzepatide",
        brand: "Mounjaro",
        dose: "5.0",
        adherence: 0.95,
        variability: true
    )

    let app = TestUtilities.launchAppWithSeededData(preset: customPreset)
    // Test implementation...
}
```

### Performance Notes

**E2E Test Seeding (Launch Arguments):**
- **All dataset sizes**: Instant from test perspective (seeding happens during app launch)
- **No UI interaction**: Data pre-populated before first screen renders
- **Consistent performance**: Same fast startup regardless of dataset size

**⚠️ NEVER use UI-based dose creation for E2E performance tests:**
- Creating 52 doses via UI would take 5-10 minutes
- Creating 365 doses would take hours
- Launch argument seeding is instant and reliable

## E2E Test Timing Patterns

### The Sleep() Anti-Pattern - NEVER USE

**❌ WRONG:**
```swift
// ❌ ANTI-PATTERN: Arbitrary delays are unreliable and slow
saveButton.tap()
sleep(2)  // BAD: Waiting arbitrary time
let editScheduleButton = app.buttons["edit-schedule-button"]
```

**✅ CORRECT:**
```swift
// ✅ CORRECT: Wait for specific element state
saveButton.tap()
let editScheduleButton = app.buttons["edit-schedule-button"]
XCTAssertTrue(
    editScheduleButton.waitForExistence(timeout: 5),
    "Edit schedule button should appear after creating schedule")
```

### Wait Pattern Best Practices

**Positive Assertions** (element should appear):
```swift
XCTAssertTrue(
    element.waitForExistence(timeout: 5),
    "Element should exist after action")
```

**Negative Assertions** (sheet dismissal verification):
```swift
// Verify sheet dismissed by checking save button no longer exists
XCTAssertFalse(
    saveButton.waitForExistence(timeout: 3),
    "Sheet should dismiss after save")
```

### Performance Improvement Example

**Performance Improvement from Issue #179:**
- **Before**: Manual medication profile creation + 18 sleep() calls = 228 seconds for 8 tests
- **After**: TestDataSeeding via launch arguments + proper wait conditions = 80-120 seconds (2-3x faster)

**Key Techniques:**
1. **Pre-seed data in setUp()** - Eliminate navigation overhead
2. **Use launch environment variables** - `TEST_DATA_SEED`, `TEST_DATA_MEDICATION`, etc.
3. **Replace all sleep() with waitForExistence()** - Reliable, fast element validation
4. **Negative assertions for dismissal** - `XCTAssertFalse(element.waitForExistence(timeout:))`

## Element Interaction Patterns

### Two-Step Picker Interaction

```swift
// Medication picker requires two taps
let medicationPicker = app.buttons["medication-picker"]
medicationPicker.tap()  // Step 1: Open picker
let semaglutideOption = app.buttons["medication-semaglutide"]
semaglutideOption.tap()  // Step 2: Select option
```

### StaticText vs Button

```swift
// Injection site selections render as StaticText, not Button
let injectionSite = app.staticTexts["add-injection-site-abdomen"]
injectionSite.tap()
```

## Essential Utilities

### Debug Elements

```swift
// Print accessibility hierarchy
TestUtilities.debugElements(in: app, containing: "dose-history")

// Example output:
// 🔍 DEBUG: Tables: []
// 🔍 DEBUG: ScrollViews: []
// 🔍 DEBUG: CollectionViews: ["dose-history-view"]
```

### Clear and Enter Text

```swift
// Reliable text field interaction
TestUtilities.clearAndEnterText(element: textField, text: "New Value")
```

### Launch App with Test Mode

```swift
// Launch with authentication bypass
let app = TestUtilities.launchAppWithTestMode()

// Launch with seeded data
let app = TestUtilities.launchAppWithSeededData(preset: .thirtyDays)

// Navigate to specific view
TestUtilities.navigateToHistoryView(in: app)
```

## Screenshot Capture

### Setup

```swift
var screenshotCapture: ScreenshotCapture!

override func setUp() {
    super.setUp()
    let app = XCUIApplication()
    screenshotCapture = ScreenshotCapture(app: app, testCase: self, phase: "baseline")
}
```

### Capture During Test

```swift
screenshotCapture.capture(
    section: "analytics-navigation",
    description: "before-tap",
    metadata: ["state": "ready", "navigation_time_ms": "1250.5"]
)
```

### Benefits

- **Systematic Documentation**: Captures UI state at critical test points
- **Performance Measurement**: Includes timing metadata for performance analysis
- **Organized Naming**: Uses section-description-timestamp format
- **Rich Metadata**: Custom metadata helps understand test context
- **Xcode Integration**: Screenshots appear as named attachments in test results

## Viewing Test Results

### Xcode Test Results Browser (Highly Recommended)

```bash
# Run any UI test, then open results in Xcode
./scripts/test.sh ui 1 ConcentrationTimelineChartUITests/testConcentrationTimelineDisplaysCorrectly
open logs/latest/results.xcresult
```

**In Xcode Test Results:**
1. **Navigate to specific test**: Expand `JabTracker` → `Tests` → find your test class → click specific test method
2. **View test execution timeline**: The Activities panel shows every step with timestamps
3. **Step through test execution**: Click any activity to see the app state at that moment
4. **View screenshots**: Screenshots captured via `ScreenshotCapture` utility appear as attachments
5. **Analyze performance**: Activity timestamps show where tests spend time
6. **Debug element targeting**: See exact UI state when element queries execute

### View Raw Logs

```bash
# View latest test output
cat logs/latest/raw_output.txt

# Search for debug output
cat logs/latest/raw_output.txt | grep "DEBUG"
```

## Running E2E Tests

### Recommended Commands

```bash
# Run specific UI test method (RECOMMENDED)
./scripts/test.sh ui 1 OnboardingUITests/testCompleteOnboardingFlow

# Run specific UI test class
./scripts/test.sh ui 1 OnboardingUITests

# Run with simulator reset
./scripts/test.sh ui 1 OnboardingUITests --reset

# View help
./scripts/test.sh --help
```

### Launch Arguments

The app supports several launch arguments for testing:

**`--ui-testing`**:
- Bypasses real Sign in with Apple authentication
- Creates mock user (`test@uitesting.com`, "UI Test User")

**`--reset-app-data`**:
- Clears all SwiftData users from database
- Clears onboarding completion status
- Resets to fresh app state

**`--bypass-onboarding`**:
- Skips onboarding flow
- Takes priority over `--force-onboarding`

**`--force-onboarding`**:
- Forces onboarding flow to show

**Test Data Seeding Arguments:**
- `--seed-test-7d`: 7 days of test data
- `--seed-test-30d`: 30 days of test data
- `--seed-test-90d`: 90 days of test data
- `--seed-test-1y`: 365 days of test data

## Systematic Element Targeting Process

When a test fails to find an element:

1. **Add debug code** → Insert `TestUtilities.debugElements(in: app, containing: "element-id")`
2. **Analyze debug output** → Read logs to identify actual element type and identifier
3. **Update test selector** → Use correct element type (collectionViews/tables/buttons/staticTexts)
4. **Run test again** → Verify element is now found
5. **Remove debug code** → Clean up after fixing selector
6. **Document learning** → Update test comments or style guide for future reference

## Common Pitfalls to Avoid

### ❌ Anti-Patterns

1. **Writing all tests before running any**
   - Leads to debugging chaos
   - Hard to isolate issues

2. **Using sleep() for timing**
   - Unreliable and slow
   - Always use `waitForExistence(timeout:)`

3. **Assuming element types without debugging**
   - SwiftUI rendering is unpredictable
   - Always debug first

4. **Batch testing multiple new methods**
   - Can't isolate failures
   - Wastes time

5. **Creating test data via UI**
   - Extremely slow for large datasets
   - Use launch argument seeding instead

### ✅ Best Practices

1. **One test at a time with debug-first approach**
2. **Use `waitForExistence(timeout:)` for all element checks**
3. **Debug actual element types before writing selectors**
4. **Run tests individually during development**
5. **Pre-seed test data via launch arguments**
6. **Capture screenshots for documentation and debugging**
7. **Commit working tests before adding new ones**

## Example: Complete E2E Test

```swift
import XCTest

final class ScheduleSetupUITests: XCTestCase {
    var app: XCUIApplication!
    var screenshotCapture: ScreenshotCapture!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]

        screenshotCapture = ScreenshotCapture(
            app: app,
            testCase: self,
            phase: "schedule-setup"
        )
    }

    // MARK: - ACCEPTANCE CRITERION: User can select schedule pattern

    func testSchedulePatternSelection() throws {
        // GIVEN: App launched in onboarding schedule setup
        app = TestUtilities.launchAppWithTestMode()

        // Navigate to schedule setup step
        // ... navigation code ...

        // Debug elements first (remove after test works)
        TestUtilities.debugElements(in: app, containing: "schedule-pattern")

        // WHEN: User taps weekly pattern card
        let weeklyPatternCard = app.buttons["schedule-pattern-weekly"]
        XCTAssertTrue(
            weeklyPatternCard.waitForExistence(timeout: 5),
            "Weekly pattern card should be visible"
        )

        screenshotCapture.capture(
            section: "pattern-selection",
            description: "before-selection"
        )

        weeklyPatternCard.tap()

        // THEN: Weekly pattern is selected
        let selectedIndicator = app.images["checkmark-circle-fill"]
        XCTAssertTrue(
            selectedIndicator.waitForExistence(timeout: 2),
            "Selected indicator should appear"
        )

        screenshotCapture.capture(
            section: "pattern-selection",
            description: "after-selection"
        )

        // THEN: Continue button becomes enabled
        let continueButton = app.buttons["continue-button"]
        XCTAssertTrue(continueButton.isEnabled)
    }
}
```

## Test Categories

### UI Tests (XCUITest Framework)
- **Authentication Flow**: AuthenticationUITests, ManualAuthenticationUITests
- **Onboarding**: OnboardingUITests
- **Medication Management**: MedicationProfile*UITests
- **Pharmacokinetics Engine**: PKEngineUITests (8 E2E acceptance tests)
- **Subscription Flow**: SubscriptionUI*Tests
- **Design System**: DesignSystemUITests
- **CloudKit Integration**: CloudKitIntegrationUITests

## Available Simulators

1. **PRIMARY** iPhone 15,OS=17.5 (UUID: 336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB)
2. **SECONDARY** iPhone 15 Pro Max,OS=17.5 (UUID: BFE552DA-1CB4-4736-821D-270EC6307512)
3. **TERTIARY** iPhone SE (3rd generation),OS=17.5 (UUID: FF190E2B-E6A1-461F-BEAF-E9A827038FA1)

## Summary

This skill provides a comprehensive framework for E2E testing with XCUITest. The key principles are:

1. **Debug-first element targeting** - Always inspect actual accessibility hierarchy
2. **Iterative test implementation** - One test at a time, commit working tests
3. **Launch argument data seeding** - Fast, reliable test data setup
4. **Proper wait conditions** - Never use sleep(), always use waitForExistence()
5. **Screenshot capture** - Document test execution and aid debugging

Follow these patterns to write reliable, maintainable, and fast E2E tests that truly validate user-facing functionality.
