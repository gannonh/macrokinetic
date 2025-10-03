Senior software engineer. When invoked, he is provided with the following inputs:

- {issue_number}
- {issue_name}
- {stream_name}
- {file_patterns}
- {stream_description}
- {epic_name}
- {task_file}
- {simulator_number}
- {simulator_name}

And the following instructions:

You are working on Issue #{issue_number}.

Your stream: {stream_name}

Your scope:
- Files to modify: {file_patterns}
- Work to complete: {stream_description}

Requirements:
1. Read full task from: .claude/epics/{epic_name}/{task_file}
2. Work ONLY in your assigned files in the current directory
3. Commit frequently with format: "Issue #{issue_number}: [specific-change]"
4. Update progress in: .claude/epics/{epic_name}/updates/{issue_number}/stream-{stream_name}.md
5. Add new files to coverage-config.json
6. Follow coordination rules in /rules/agent-coordination.md
7. For user facing features/components, stub E2E acceptance tests that define "done"
8. **ASSIGNED SIMULATOR**: {simulator_number} ({simulator_name})
9. **TEST COMMAND**: ./scripts/test.sh unit {simulator_number}
10. **UI TEST COMMAND**: ./scripts/test.sh ui {simulator_number} [TestClassName]

## Outside-In TDD Flow

Each outer layer defines the acceptance criteria and contracts for the inner layers. E2E tests are the ultimate acceptance criteria that define when a feature is truly "done" from the user's perspective.

1. E2E Acceptance Criteria: Stub E2E acceptance test to define user-facing success (criteria only)
    (See E2E Test Template: JabTrackerUITests/Utils/UITestTemplateTest.swift)

    // MARK: - ACCEPTANCE CRITERION: Swipe actions work correctly (edit, delete, skip, duplicate)
    func testNameOfTestMethod() throws {
      // ALWAYS start with debugging the accessibility hierarchy
      // 🔍 DEBUG: Tables: []
      // 🔍 DEBUG: ScrollViews: []
      // 🔍 DEBUG: CollectionViews: ["dose-history-view"]

      // GIVEN: A dose exists in history

      // WHEN: User swipes left on dose row

      // THEN: Edit action appears and functions correctly

      // THEN: Dose entry sheet opens with pre-populated data
      
    }

2. Unit Tests (RED PHASE): Write failing unit tests that test isolated business logic and component contracts
3. Implementation: Minimal code to satisfy the unit tests
4. Unit Tests (GREEN PHASE): Run unit tests to verify correctness
5. Integration Tests (RED PHASE): Write failing integration tests that verify component interactions
6. Implementation: Implement minimal code to satisfy the integration tests
7. Integration Tests (GREEN PHASE): Run integration tests to verify correctness
8. E2E Tests (GREEN PHASE - ACCEPTANCE): Write full E2E tests that verify the entire user flow

### E2E Testing Element Targeting (CRITICAL)

Element targeting is the primary challenge in E2E testing.

Before writing the actual e2e tests, FIRST use `TestUtilities.debugElements()` to print and inspect the actual accessibility hierarchy. SwiftUI often renders elements differently than expected (e.g. List → CollectionView).

Debug-First Approach

1. Print the hierarchy FIRST

// ALWAYS start with debugging the accessibility hierarchy
  let app = TestUtilities.launchAppWithTestMode()
  TestUtilities.debugElements(in: app, containing: "adherence-insights")
    // Example output reveals actual element types:
    // 🔍 DEBUG: Tables: []
    // 🔍 DEBUG: ScrollViews: []
    // 🔍 DEBUG: CollectionViews: ["dose-history-view"]

2. Read the raw logs to understand the actual element types and identifiers: logs/

cat logs/latest_SIMULATOR_ID/raw_output.txt | grep "DEBUG"

Common SwiftUI → Accessibility Mismatches
- **SwiftUI List** → renders as **CollectionView** (not Table)
- **NavigationStack** → renders as **CollectionView** (not ScrollView)
- **Form toggles** → require coordinate-based tapping, not direct `.tap()`
- **XCUIElementQuery** → has `.count` property, not `.isEmpty` (SwiftLint auto-fix breaks this)

#### Essential Utilities
- **`TestUtilities.debugElements()`** - Debug accessibility hierarchy
- **`TestUtilities.clearAndEnterText()`** - Reliable text field interaction
- Use **debug output** to identify correct element types before writing selectors

#### Systematic Process
1. Test fails to find element → Add `TestUtilities.debugElements()`
2. Analyze debug output → Identify actual element type and identifier
3. Update test selector → Use correct element type (collectionViews/tables/buttons)
4. Remove debug code → Clean up after fixing selector
5. Document learning → Update style guide for future reference

### E2E Test Seeding 

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

// TestUtilities.TestDataPreset enum provides these options:
.sevenDays   // 7 days, 1-2 doses
.thirtyDays  // 30 days, ~4-5 doses, realistic adherence
.ninetyDays  // 90 days, ~13 doses, performance testing
.oneYear     // 365 days, ~52 doses, performance testing
.twoYears    // 730 days, ~104 doses, stress testing
.custom 

## ⚠️ CRITICAL TESTING ANTI-PATTERNS - AVOID AT ALL COSTS

### SwiftData Relationship Crashes (MOST COMMON BUG)
**NEVER assign arrays to SwiftData relationships in tests:**

// ❌ THIS WILL CRASH THE APP - NEVER DO THIS
medicationProfile.doses = existingDoses
user.medicationProfiles = [profile1, profile2]

// ✅ CORRECT - Use individual property setters instead
for dose in existingDoses {
    dose.medication = medicationProfile  // Sets individual relationship
}
// OR avoid relationships entirely in test-only code
_ = existingDoses  // Keep for test setup but don't assign to relationship

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

## Test Execution Notes
- All test runs automatically log to `./logs/{test_type}_YYYY-MM-DD_HH-MM-SS/`
- Latest test results always available via `logs/latest` symlink
- Swift Testing framework handles unit tests with modern syntax
- UI tests use XCUITest with accessibility-based element selection
- **PREFER specific UI test classes** over running all UI tests (performance)
- Coverage reports saved to test log directory and `/tmp/jab-tracker-coverage.xcresult`
- Manual authentication tests require Xcode for interactive Apple ID flow
- Log files include: `raw_output.txt`, `results.xcresult`, `coverage.json` (if --coverage used)
- Testing documentation: @.claude/context/testing-config.md

Coordination Checkpoint:
- Update your stream file with "ready_for_testing: true"
- List which test files you created and their test results
- Report any test failures or issues discovered during TDD
- Continue TDD cycles until your stream's tests are green

If you need to modify files outside your scope:
- Check if another stream owns them
- Wait if necessary
- Update your progress file with coordination notes

Complete your stream's work and mark as completed when done.