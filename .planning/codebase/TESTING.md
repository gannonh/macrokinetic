# Testing Patterns

**Analysis Date:** 2025-12-22

## Test Framework

**Runner:**
- Swift Testing (iOS 17+) - Unit tests
- XCUITest - UI/E2E tests
- Config: `project.yml` test schemes

**Assertion Library:**
- Swift Testing: `#expect()`, `#require()`
- XCUITest: `XCTAssert*` family

**Run Commands:**
```bash
./scripts/test.sh unit 1                              # Run all unit tests
./scripts/test.sh unit 1 FoodServiceTests             # Single test class
./scripts/test.sh unit 1 --coverage                   # With coverage
./scripts/test.sh ui 1 NutritionFlowUITests           # UI test class
./scripts/test.sh ui 1 OnboardingUITests/testComplete # Single method
```

## Test File Organization

**Location:**
- Unit tests: `JabTrackerTests/` (144+ files)
- UI tests: `JabTrackerUITests/` (60+ files)
- Test utilities: `JabTrackerUITests/Utils/TestUtilities.swift`
- Mocks: `JabTrackerTests/Mocks/`

**Naming:**
- Unit tests: `{ClassName}Tests.swift`
- UI tests: `{Feature}UITests.swift`
- Integration: `{Feature}IntegrationTests.swift`

**Structure:**
```
JabTrackerTests/
├── Models/                  # Model entity tests
├── Services/                # Service logic tests
├── ViewModels/              # ViewModel tests
├── Onboarding/              # Onboarding tests
├── Integration/             # Integration tests
└── Mocks/                   # Test doubles

JabTrackerUITests/
├── Analytics/               # Analytics E2E
├── Utils/TestUtilities.swift
├── NutritionFlowUITests.swift
├── OnboardingUITests.swift
└── CalendarIntegrationUITests.swift
```

## Test Structure

**Swift Testing (Unit Tests):**
```swift
import Testing
@testable import JabTracker

@Suite("FoodService Tests")
struct FoodServiceTests {

    @Test("Search returns local results first")
    @MainActor
    func testSearchReturnsLocalFirst() async {
        // Given
        let (context, container) = createTestContext()
        _ = container  // Keep alive
        let service = FoodService(context: context)

        // When
        let results = await service.search(query: "apple")

        // Then
        #expect(results.count > 0)
        #expect(results.first?.source == .local)
    }
}
```

**XCUITest (E2E Tests):**
```swift
import XCTest

final class NutritionFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
    }

    func testSearchFoodAndLog() throws {
        // Navigate to Food Log
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        // Verify view loaded
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5))

        // Search for food
        app.buttons["add-food-button"].tap()
        // ... continue flow
    }
}
```

**Patterns:**
- Use `// Given:`, `// When:`, `// Then:` comments
- `@MainActor` for SwiftData/UI tests
- Keep container alive when using ModelContext

## Mocking

**Framework:**
- Protocol-based mocking (no external framework)
- Mock implementations in `JabTrackerTests/Mocks/`

**Patterns:**
```swift
// Protocol
protocol NotificationCenterProtocol {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
}

// Production
extension UNUserNotificationCenter: NotificationCenterProtocol {}

// Mock
class MockNotificationCenter: NotificationCenterProtocol {
    var authorizationResult = true
    var addedRequests: [UNNotificationRequest] = []

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        return authorizationResult
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }
}
```

**What to Mock:**
- External services (NotificationCenter, URLSession)
- System frameworks (HealthKit, StoreKit)
- Time-dependent operations

**What NOT to Mock:**
- Internal services (test with real implementations)
- SwiftData (use in-memory container)
- Pure functions

## Fixtures and Factories

**SwiftData Test Setup (CRITICAL):**
```swift
// ✅ CORRECT: Return both context AND container
func createTestContext() -> (context: ModelContext, container: ModelContainer) {
    let schema = Schema([User.self, Dose.self, Food.self, FoodEntry.self])
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none  // Critical for tests
    )
    let container = try! ModelContainer(for: schema, configurations: [config])
    return (container.mainContext, container)
}

// In test - MUST capture container
@Test func testExample() {
    let (context, container) = createTestContext()
    _ = container  // Keep alive for duration of test

    // Now context.insert() will work
}

// ❌ WRONG: Container deallocates, context becomes invalid
func createTestContext() -> ModelContext {
    let container = try! ModelContainer(...)
    return container.mainContext  // Crash on insert!
}
```

**Factory Functions:**
```swift
private func createTestUser(in context: ModelContext) -> User {
    let user = User(
        email: "test@example.com",
        name: "Test User",
        appleUserId: "test-apple-id"
    )
    context.insert(user)
    return user
}
```

**Location:**
- Factory functions: Define in test file near usage
- Shared fixtures: `JabTrackerTests/Mocks/` or test file

## Coverage

**Requirements (5-Tier Policy):**
- Tier 1 - Pure Business Logic (90%): `PharmacokineticsEngine`, Models
- Tier 2 - Infrastructure (62%): `DataController`, `MedicationManager`
- Tier 3 - Framework Integration (42%): `AuthenticationManager`, `BiometricAuthManager`
- Tier 4 - View Models (85%): `OnboardingViewModel`
- Tier 5 - Utilities (75%): `ProfileValidation`, helpers
- SwiftUI Views: No requirements (cannot be unit tested)

**Configuration:**
- Coverage config: `coverage-config.json`
- Run: `./scripts/test.sh unit 1 --coverage`
- Check policy: `./scripts/check-coverage.sh`

**View Coverage:**
```bash
./scripts/coverage-detail.sh
./scripts/coverage-json.sh --summary
open logs/latest/results.xcresult
```

## Test Types

**Unit Tests:**
- Scope: Single class/function in isolation
- Mocking: External dependencies only
- Speed: Each test <100ms
- Examples: `FoodServiceTests.swift`, `PharmacokineticsEngineTests.swift`

**Integration Tests:**
- Scope: Multiple components together
- Mocking: Only external boundaries
- Setup: In-memory SwiftData
- Examples: `CalendarPerformanceTests.swift`

**E2E Tests:**
- Framework: XCUITest
- Scope: Full user flows
- Setup: Launch arguments for test mode
- Location: `JabTrackerUITests/`

## Common Patterns

**Async Testing:**
```swift
@Test("Async operation succeeds")
@MainActor
func testAsyncOperation() async {
    let result = await service.performAsync()
    #expect(result.isSuccess)
}
```

**Error Testing:**
```swift
@Test("Throws on invalid input")
func testThrowsOnInvalid() {
    #expect(throws: ValidationError.self) {
        try service.validate(nil)
    }
}
```

**UI Test Utilities:**
```swift
enum TestUtilities {
    static func launchAppWithTestMode(resetData: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = resetData
            ? ["--ui-testing", "--reset-app-data"]
            : ["--ui-testing"]
        app.launch()
        return app
    }

    static func navigateToTab(_ app: XCUIApplication, tabName: String) {
        app.tabBars.buttons[tabName].tap()
    }
}
```

**Accessibility Identifiers:**
```swift
// In View
.accessibilityIdentifier("food-detail-sheet")

// In Test
let sheet = app.otherElements["food-detail-sheet"]
XCTAssertTrue(sheet.waitForExistence(timeout: 5))
```

## Test Data Seeding

**Launch Arguments:**
- `--ui-testing` - Bypass authentication
- `--reset-app-data` - Clear all data
- `--seed-test-7d` - 7 days of test data
- `--seed-test-30d` - 30 days
- `--seed-test-90d` - 90 days
- `--seed-test-1y` - 1 year

**Usage:**
```swift
app.launchArguments = ["--ui-testing", "--seed-test-7d"]
app.launch()
```

---

*Testing analysis: 2025-12-22*
*Update when test patterns change*
