## Overview

**JabTracker** - iOS app for tracking GLP-1 medication doses, nutrition, and health metrics.

- SwiftUI + SwiftData with CloudKit sync
- Pharmacokinetics engine for concentration tracking
- Food logging with 1.7M+ foods (USDA + Open Food Facts)
- Analytics, adherence tracking, and progress photos

## Essential Context

## Important Reminders

- Do not run build commands when iterating with the user. The user needs to run build to see the changes. When you run build after making a change he has to wait for your build to complete before running the app.

## E2E Testing Rules

### MANDATORY: When E2E Tests Fail, Debug First

**STOP. Before changing ANY code when a test fails, you MUST run these debug steps:**

### Step 1: Capture Screenshot
```swift
// Add this line RIGHT BEFORE the failing assertion
TestUtilities.debugScreenshot(app, name: "before-failure")
```

### Step 2: Print Element Hierarchy
```swift
// Add this line RIGHT BEFORE the failing assertion
print(app.debugDescription)
```

### Step 3: Run Test and Examine Output
```bash
./scripts/test.sh ui 1 YourTestClass/testMethod
open logs/latest/screenshots/
```

### Step 4: Analyze BEFORE Changing Code
- **Screenshot shows**: What the UI actually looks like
- **debugDescription shows**: What elements exist and their identifiers
- **Together they answer**: Why can't the test find/interact with the element?

### DO NOT:
- Guess at element types or identifiers
- Change accessibility identifiers without seeing the hierarchy
- Add arbitrary timeouts hoping it fixes timing
- Modify SwiftUI views without confirming the element structure

### ALWAYS:
- Capture visual evidence of the failure state
- Print the element tree to see actual identifiers
- Compare expected vs actual element types
- Only then make targeted fixes based on evidence

**This debug-first approach is not optional. Skipping it leads to wasted effort and incorrect fixes.**




---
name: Architecture
created: 2025-12-22
last_modified: 2026-01-09
---

# Architecture

## Pattern Overview

**Overall:** MVVM with Service Layer

**Key Characteristics:**
- SwiftUI views with declarative state management
- ViewModels using `@Observable` (iOS 17+)
- Service layer for business logic coordination
- SwiftData models with CloudKit sync
- Singleton service coordinator (`AppServices`)

## Layers

**Presentation Layer (Views):**
- Purpose: SwiftUI UI components
- Contains: `*View.swift`, `*Sheet.swift`, `*Card.swift` files
- Location: `JabTracker/Views/**/*.swift`
- Depends on: ViewModels for state, Services for actions
- Used by: App entry point, navigation

**ViewModel Layer:**
- Purpose: View state and business logic coordination
- Contains: `@Observable` classes coordinating services
- Location: `JabTracker/ViewModels/*.swift`, some in `Views/` subdirectories
- Depends on: Services for operations, Models for data
- Used by: Views (via `@State` or `@ObservedObject`)

**Service Layer:**
- Purpose: Business logic, persistence, external integrations
- Contains: `*Service.swift`, `*Manager.swift`, `*Engine.swift` (28+ files)
- Location: `JabTracker/Services/*.swift`
- Depends on: Models, ModelContext, external APIs
- Used by: ViewModels, other Services

**Data Layer (Models):**
- Purpose: SwiftData entities, domain types
- Contains: `@Model` classes, enums, supporting types (39 files)
- Location: `JabTracker/Models/*.swift`
- Depends on: Nothing (pure data)
- Used by: All layers

## Data Flow

**Quick Dose Entry:**

1. User taps "+" tab → ContentView detects `Tab.add`
2. `ShortcutsSheet` appears (`Views/Shortcuts/ShortcutsSheet.swift`)
3. User taps "Log Dose" → `QuickDoseSheet` presented
4. `QuickDoseViewModel` loads smart defaults from ModelContext
5. User confirms → `DoseService.saveDose()` inserts into SwiftData
6. CloudKit syncs automatically via ModelContainer
7. `PharmacokineticsEngine` recalculates concentration
8. Dashboard updates with new concentration display

**Food Logging:**

1. User opens Food Log tab → `FoodLogView` displayed
2. User taps "+" → `FoodSearchSheet` presented
3. `FoodSearchSheetViewModel` coordinates:
   - `FoodService.search()` orchestrates local DB + API
   - Results categorized by source (History/Custom/Common/Branded)
4. User selects food → `FoodDetailSheet` shows macros
5. User adjusts serving → Bidirectional calculation (quantity ↔ target macro)
6. User saves → `MealLogService.logFood()` creates `FoodEntry`
7. CloudKit syncs, `NutritionSummaryCard` updates daily totals

**State Management:**
- SwiftData models persisted automatically
- CloudKit sync transparent to services
- UserDefaults for app preferences (`NotificationService+Persistence.swift`)

**Dashboard Hero Widget Carousel (NEW - Phase 31):**

1. User views Dashboard tab → `DashboardView` section in ContentView
2. `HeroWidgetContainer` renders carousel with 3 widgets
3. Container applies `@State displayMode` via environment
4. Environment propagation: `.environment(\.heroDisplayMode, displayMode)`
5. Widgets read: `@Environment(\.heroDisplayMode) private var displayMode`
6. User toggles consumed/remaining → environment updates all widgets
7. TabView page navigation with custom page indicators

## Key Abstractions

**Services:**
- Purpose: Encapsulate business logic domains
- Examples: `ScheduleService`, `FoodService`, `PharmacokineticsEngine`, `NotificationService`
- Pattern: `@Observable` classes with extension-based organization
- Location: `JabTracker/Services/*.swift`

**SwiftData Models:**
- Purpose: Persistent data entities
- Examples: `User`, `Dose`, `MedicationProfile`, `Food`, `FoodEntry`
- Pattern: `@Model` macro with CloudKit-compatible defaults
- Location: `JabTracker/Models/*.swift`

**Coordinators:**
- Purpose: Flow state management
- Examples: `OnboardingCoordinator`, `DeeplinkHandler`
- Pattern: `@Observable` with step/state enums
- Location: `JabTracker/Onboarding/`, `JabTracker/App/`

**Service Coordinator:**
- Purpose: Dependency injection container
- Example: `AppServices.shared` - singleton
- Pattern: Initializes services with ModelContext on first use
- Location: `JabTracker/App/AppServices.swift`

**Dashboard Widgets (NEW - Phase 31):**
- Purpose: Modular dashboard display components
- Protocol: `DashboardWidget` defines `id`, `title`, `content`
- Examples: `WeeklyNutritionHeroWidget`, `DailyNutritionHeroWidget`, `EnergyBalanceHeroWidget`
- Pattern: Protocol-based composition with environment state management
- Location: `JabTracker/Views/Dashboard/Widgets/*.swift`

**Environment-based Display Modes (NEW):**
- Purpose: Propagate display state through widget hierarchy
- Examples: `HeroDisplayModeKey` (consumed/remaining), `EnergyDisplayModeKey` (expenditure/targets)
- Pattern: Custom `EnvironmentKey` + `EnvironmentValues` extension
- Location: `JabTracker/Views/Dashboard/Widgets/HeroWidgetContainer.swift`

## Entry Points

**App Entry:**
- Location: `JabTracker/App/JabTrackerApp.swift`
- Triggers: App launch
- Responsibilities: Initialize managers, manage auth state, provide ModelContainer

**Content View:**
- Location: `JabTracker/ContentView.swift`
- Triggers: After authentication
- Responsibilities: Tab navigation, service initialization, deep link routing

**Onboarding Coordinator:**
- Location: `JabTracker/Onboarding/OnboardingCoordinator.swift`
- Triggers: First launch or `--force-onboarding`
- Responsibilities: Step progression, data collection, schedule setup

## Error Handling

**Strategy:** Throw errors from services, catch at ViewModel/View level

**Patterns:**
- Services throw typed errors (e.g., `ScheduleServiceError`)
- ViewModels catch and expose `errorMessage` for UI
- Graceful degradation (CloudKit unavailable → local-only)
- `fatalError` for truly unrecoverable states (see CONCERNS.md)

## Cross-Cutting Concerns

**Logging:**
- OSLog framework with category-specific loggers
- Format: `Logger(subsystem: "com.gannonhall.JabTracker", category: "ServiceName")`

**Validation:**
- `DoseValidation` for medical input checking
- `ProfileValidation` for user profile data
- ViewModel-level validation before service calls

**Authentication:**
- `AuthenticationManager` handles Sign in with Apple
- `BiometricAuthManager` handles Face ID/Touch ID
- Both used at app launch before ContentView

**Notifications:**
- `NotificationService` with extensions for domains
- iOS 64-notification limit managed with rolling window
- Background refresh via BGTaskScheduler (incomplete - see CONCERNS.md)

---

*Architecture analysis: 2026-01-04*
*Update when major patterns change*



---
name: Codebase Concerns
created: 2025-12-22
last_modified: 2026-01-09
---

# Codebase Concerns

## Tech Debt

**Incomplete split-dose UI:**
- Issue: Settings UI missing second time picker for split-dose schedules
- File: `JabTracker/Views/Settings/DoseScheduleEditView.swift:368`
- Why: Deferred to Phase 3 during initial implementation
- Impact: Users can't configure split-dose medications via UI
- Fix approach: Add second time picker, connect to `ScheduleConfiguration.secondTimeOfDay`

**Incomplete background task scheduling:**
- Issue: BGTaskScheduler registration is a placeholder (no-op)
- File: `JabTracker/Services/NotificationService+Background.swift:21`
- Why: Deferred during notification system implementation
- Impact: Notification queue doesn't refresh when app is backgrounded
- Fix approach: Implement BGTaskScheduler.register() and scheduling

**Duplicate food deduplication logic:**
- Issue: Food deduplication implemented in two places
- Files: `JabTracker/Services/FoodService.swift:223-230`, `JabTracker/ViewModels/FoodSearchSheetViewModel.swift`
- Why: Evolved organically during nutrition feature development
- Impact: Maintenance burden, potential inconsistencies
- Fix approach: Consolidate into FoodService, remove from ViewModel

**Debug print statements in production code:**
- Issue: 19+ `print()` statements instead of OSLog
- Files (partial list):
  - `JabTracker/Models/Dose.swift` - Emoji debugging prints
  - `JabTracker/ViewModels/DoseHistoryViewModel.swift` - Debug printing
  - `JabTracker/Views/Settings/Components/PauseScheduleSheet.swift` - Console debugging
  - `JabTracker/Views/Settings/MedicationProfileSettingsView.swift` - Error printing
  - `JabTracker/Views/Dashboard/QuickDoseButton.swift` - Print statements
  - `JabTracker/Views/Dashboard/Widgets/*.swift` - Various debug prints
- Why: Quick debugging during development, not cleaned up
- Impact: Console noise in production, inconsistent logging practices
- Fix approach: Replace all `print()` calls with OSLog using existing logger instances
- Status: Still present as of 2026-01-09

**Scattered UserDefaults string keys:**
- Issue: UserDefaults keys are string literals without centralized constants
- Files: `JabTracker/AuthenticationManager.swift:195-198`, `JabTracker/BiometricAuthManager.swift:54,63`
- Why: Keys added ad-hoc during feature development
- Impact: Typos could cause silent failures, difficult to refactor
- Fix approach: Create `UserDefaultsKeys` enum with all key constants

## Known Bugs

**None critical identified during analysis.**

Minor issues:
- Regex parsing for serving descriptions may fail silently on malformed data
- File: `JabTracker/Views/Nutrition/EditFoodEntrySheet.swift:53-59`
- Workaround: Falls back to `entry.servingGrams`
- Root cause: No logging when parse fails

## Security Considerations

**URL construction - RESOLVED:**
- ~~Risk: Barcode directly interpolated into URL path~~
- File: `JabTracker/Services/OpenFoodFactsService.swift:88-92`
- Status: Fixed - Uses `addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)`
- Note: URL encoding is now properly implemented

**No rate limiting on API calls:**
- Risk: Excessive API calls if user types quickly in search
- File: `JabTracker/Services/OpenFoodFactsService.swift`
- Current mitigation: Debouncing exists in `FoodSearchSheet.swift` (200ms) at view level
- Recommendations: Add service-level rate limiting for calls from other entry points

## Performance Bottlenecks

**Regex compilation on every parse:**
- Problem: Serving option regex compiled for each food item
- File: `JabTracker/Services/FoodService.swift:132`
- Measurement: Not measured, but called per-item in search results
- Cause: Regex pattern `#"^([\d.]+)\s*(\w+)\s*\((\d+(?:\.\d+)?)g\)$"#` created inline
- Improvement path: Compile once as static property

**Large view files approaching limits:**
- Files exceeding 300 lines:
  - `WeeklyNutritionHeroWidget.swift` (421 lines)
  - `DailyNutritionHeroWidget.swift` (300 lines)
  - `EnergyBalanceHeroWidget.swift` (260 lines)
- SwiftLint warning threshold: 350 lines
- Improvement path: Extract computed subviews into separate files or extensions

## Fragile Areas

**Fatal errors in production paths:**
- Files with `fatalError`:
  - `JabTracker/DataController.swift:142` - ModelContainer creation failure
  - `JabTracker/Views/Nutrition/FoodSearchSheet.swift:106` - Missing service injection
  - `JabTracker/AuthenticationManager.swift:1089` - No window for Sign in with Apple (presentationAnchor)
- Why fragile: App crashes immediately instead of graceful error handling
- Common failures: Missing dependencies, unusual device states, window management
- Safe modification: Replace with error states or fallback behavior
- Test coverage: Not tested (fatalError paths untestable)

**Bidirectional macro calculation:**
- File: `JabTracker/Views/Nutrition/FoodDetailSheet.swift`
- Why fragile: Complex state transitions between quantity and target modes
- Common failures: Values reset unexpectedly when switching modes
- Safe modification: Read system-patterns.md section on bidirectional calculation
- Test coverage: E2E tests cover happy path, unit tests limited

## Scaling Limits

**Local food database:**
- Current capacity: 1.7M+ foods, 382 MB
- Limit: Memory pressure on older devices during large result sets
- Symptoms at limit: App may be terminated by iOS memory pressure
- Scaling path: Pagination in FTS5 queries (already has LIMIT)

## Dependencies at Risk

**None identified.**
- Project uses only Apple frameworks (no third-party dependencies)
- All frameworks are actively maintained by Apple

## Missing Critical Features

**Error tracking/crash reporting:**
- Problem: No Sentry, Crashlytics, or similar service
- Current workaround: OSLog only (requires device access)
- Blocks: Production issue investigation, crash analysis
- Implementation complexity: Low (add Sentry SDK)

**Analytics:**
- Problem: No usage analytics or feature tracking
- Current workaround: None
- Blocks: Understanding user behavior, feature prioritization
- Implementation complexity: Low (add analytics SDK)

## Test Coverage Gaps

**FoodSearchSheet initialization errors:**
- What's not tested: fatalError path when services are nil
- Risk: Crash in production if injection fails
- Priority: High
- Difficulty to test: Cannot test fatalError in unit tests

**LocalFoodDatabase missing bundle:**
- What's not tested: Behavior when bundled SQLite file is missing
- Risk: Silent failure, empty search results
- Priority: Medium
- Difficulty to test: Would need to modify bundle in test

**Service error propagation:**
- What's not tested: OpenFoodFacts API errors distinguishable from empty results
- Risk: User can't tell if search failed vs no results
- Priority: Medium
- Difficulty to test: Need to inject URLSession mock

---

## Summary by Priority

**Critical (must fix before release):**
1. Replace `fatalError` in `DataController.swift:142` with graceful error handling
2. Replace `fatalError` in `FoodSearchSheet.swift:106` with optional service pattern
3. Replace `fatalError` in `AuthenticationManager.swift:1089` with error state

**High Priority:**
1. Implement BGTaskScheduler for background notification refresh
2. Remove all `print()` statements - replace with OSLog
3. Add error/crash reporting service

**Medium Priority:**
1. Complete split-dose UI (Phase 3 TODO)
2. Consolidate food deduplication logic
3. Add service-level rate limiting to food search
4. Static regex compilation for performance
5. Centralize UserDefaults keys in enum

---

*Concerns audit: 2026-01-09*
*Update as issues are fixed or new ones discovered*



---
name: Coding Conventions
created: 2025-12-22
last_modified: 2026-01-10
---

# Coding Conventions

## Naming Patterns

**Files:**
- `*View.swift` - SwiftUI views (e.g., `DashboardView.swift`, `FoodDetailSheet.swift`)
- `*ViewModel.swift` - ViewModels (e.g., `AnalyticsViewModel.swift`)
- `*Service.swift` - Services (e.g., `FoodService.swift`, `ScheduleService.swift`)
- `*Manager.swift` - Managers (e.g., `MedicationManager.swift`, `AuthenticationManager.swift`)
- `Type+Feature.swift` - Extensions (e.g., `ScheduleService+Projection.swift`, `Colors+Extensions.swift`)
- `*Tests.swift` - Test files co-located by layer

**Functions:**
- camelCase for all functions (e.g., `calculateConcentration()`, `logFood()`)
- No special prefix for async functions
- `handle*` for event handlers (e.g., `handleDismiss`, `handleSave`)

**Variables:**
- camelCase for variables (e.g., `servingCount`, `quantityInGrams`)
- camelCase for constants (e.g., `defaultQuantity`, `maxRetryAttempts`)
- No underscore prefix for private members

**Types:**
- PascalCase for classes/structs/enums (e.g., `LocalFoodDatabase`, `MealSection`)
- No prefix conventions (no `I` for interfaces)
- Enum cases use camelCase (e.g., `.breakfast`, `.lunch`, `.snacks`)

## Code Style

**Formatting:**
- SwiftLint with `.swiftlint.yml` (root + directory-specific)
- Line length: warning at 120, error at 150
- 4 space indentation (Swift default)
- Trailing commas disabled

**Linting:**
- SwiftLint with custom rules per directory
- Tests: Relaxed rules (no function_body_length, force_unwrapping allowed)
- Services/Views: Extended file/type length limits
- Run: `swiftlint` or `swiftlint --fix`

**SwiftLint Rule Exceptions:**
- Prefer directory-level `.swiftlint.yml` files over inline `// swiftlint:disable` comments
- Directory configs apply to all files in that directory, reducing scattered inline comments
- Example: `JabTracker/Views/Dashboard/Widgets/.swiftlint.yml` disables `large_tuple` for widget files
- Only use inline disable comments for one-off exceptions affecting a single line

**Key SwiftLint Settings (`.swiftlint.yml`):**
```yaml
line_length: warning: 120, error: 150
type_body_length: warning: 350, error: 400
function_body_length: warning: 50, error: 80
cyclomatic_complexity: warning: 10, error: 20
```

**Design System Enforcement (Custom Rules):**
- `prefer_design_tokens_colors`: Warn when using raw `Color(.system...)` instead of `DesignTokens.Colors`
- `prefer_design_tokens_backgrounds`: Warn when using raw `Color()` for backgrounds instead of design tokens

## Import Organization

**Order:**
1. Apple frameworks (SwiftUI, SwiftData, Foundation)
2. Project imports (rarely needed due to single module)

**Grouping:**
- No blank lines required between groups
- Alphabetical sorting not enforced

**Path Aliases:**
- Not applicable (single-module app, no SPM)

## Error Handling

**Patterns:**
- Throw typed errors from services (e.g., `ScheduleServiceError`)
- Catch at ViewModel/View level, expose `errorMessage` property
- Use `try?` sparingly (prefer explicit error handling)

**Error Types:**
```swift
enum ScheduleServiceError: LocalizedError {
    case invalidSchedule
    case scheduleNotFound
    case contextError(Error)

    var errorDescription: String? { ... }
}
```

**Async:**
- Use `async/await` with `try` (no `.catch()` chains)
- Annotate with `@MainActor` when touching UI state

## Logging

**Framework:**
- OSLog via `Logger` class
- Subsystem: `com.gannonhall.JabTracker`
- Category: Per-service (e.g., `ScheduleService`, `FoodService`)

**Patterns:**
```swift
private let logger = Logger(
    subsystem: "com.gannonhall.JabTracker",
    category: "FoodService"
)
logger.debug("Searching for: \(query)")
logger.error("Failed to save: \(error)")
```

**When:**
- Log state transitions and external calls
- Log errors with context before throwing
- Avoid logging sensitive data

## Comments

**When to Comment:**
- Explain why, not what
- Document business rules and medical calculations
- Complex algorithms get inline explanation
- MARK sections for file organization

**MARK Comments:**
```swift
// MARK: - Properties
// MARK: - Initialization
// MARK: - Public Methods
// MARK: - Private Helpers
```

**Documentation:**
```swift
/// Log a food entry
/// - Parameters:
///   - food: Food item to log
///   - servingGrams: Serving size in grams
/// - Returns: The created FoodEntry
func logFood(food: Food, servingGrams: Double) -> FoodEntry
```

**TODO Comments:**
- Format: `// TODO: description`
- Link issues when available: `// TODO: (Issue #123)`

## Function Design

**Size:**
- Keep under 50 lines (warning), 80 lines (error)
- Extract helpers for complex logic
- Use extension files for service domains

**Parameters:**
- Max 3-4 parameters before considering options object
- Use trailing closure syntax for completion handlers
- Default parameters for common cases

**Return Values:**
- Explicit return statements
- Return early with guard clauses
- Use optionals for "not found" cases

## Module Design

**Exports:**
- Single module app (no explicit exports)
- All types internal by default
- `public` only for test targets (`@testable import`)

**Service Extensions:**
- Split large services into focused extensions:
  - `ScheduleService.swift` - Base class
  - `ScheduleService+Projection.swift` - Generate doses
  - `ScheduleService+Adherence.swift` - Track compliance

## SwiftUI Patterns

**Property Order in Views:**
1. Regular properties (`let food: Food`)
2. Environment (`@Environment(\.dismiss)`)
3. State (`@State var count: Int`)
4. Computed properties (`var total: Double`)
5. Static constants

**View Composition:**
```swift
var body: some View {
    VStack {
        headerSection
        contentSection
        footerSection
    }
}

private var headerSection: some View { ... }
```

**Accessibility:**
```swift
.accessibilityIdentifier("food-detail-sheet")
.accessibilityLabel("Daily calorie total")
```

## SwiftData Patterns

**CloudKit Compatibility:**
- All properties have default values (non-optional)
- Parent uses `@Relationship(inverse:)`, child uses plain property
- Relationships are optional arrays

```swift
// Parent
@Relationship(deleteRule: .cascade, inverse: \Dose.user)
var doses: [Dose]?

// Child - NO @Relationship
var user: User?
```

## Observable Patterns

**iOS 17+ (`@Observable`):**
```swift
@Observable
class ViewModel {
    var state: State = .initial
}

// In View:
@State private var viewModel = ViewModel()
```

**Service Coordinator:**
```swift
@MainActor
final class AppServices: ObservableObject {
    static let shared = AppServices()
    private(set) var foodService: FoodService?

    func initialize(with modelContext: ModelContext) { ... }
}
```

## Widget Patterns (Phase 31)

**Protocol-Based Widgets:**
```swift
protocol DashboardWidget: Identifiable {
    associatedtype Content: View
    var id: String { get }
    var title: String { get }
    @ViewBuilder var content: Content { get }
}
```

**Environment-Based State Management:**
```swift
// Define custom environment key
private struct HeroDisplayModeKey: EnvironmentKey {
    static let defaultValue: HeroDisplayMode = .consumed
}

// Extend EnvironmentValues
extension EnvironmentValues {
    var heroDisplayMode: HeroDisplayMode {
        get { self[HeroDisplayModeKey.self] }
        set { self[HeroDisplayModeKey.self] = newValue }
    }
}

// Container propagates state
.environment(\.heroDisplayMode, displayMode)

// Widgets read from environment
@Environment(\.heroDisplayMode) private var displayMode
```

**Widget File Naming:**
- `*HeroWidget.swift` - Full-width carousel widgets
- `*Widget.swift` - Standard grid widgets
- `WidgetCard.swift` - Shared card wrapper component

---

*Convention analysis: 2026-01-09*
*Update when patterns change*



---
name: External Integrations
created: 2025-12-22
last_modified: 2026-01-09
---

# External Integrations

**Analysis Date:** 2026-01-04

## APIs & External Services

**Open Food Facts API:**
- Service: Open Food Facts REST API - Food search fallback
  - Base URL: `https://world.openfoodfacts.org` - `JabTracker/Services/OpenFoodFactsService.swift`
  - Auth: None (public API)
  - Timeout: 30s request, 60s resource
  - Endpoints: `/cgi/search.pl` (search), `/api/v0/product/{barcode}.json` (barcode lookup)
  - Rate limits: Undocumented (should add throttling)

**No Other External APIs:**
- All other functionality uses Apple frameworks or local data

## Data Storage

**Databases:**
- SwiftData + CloudKit - Primary user data store
  - Connection: Automatic via ModelContainer
  - Client: SwiftData `@Model` entities
  - Sync: CloudKit with graceful fallback to local-only
  - Container: `iCloud.com.gannonhall.JabTracker` - `JabTracker/JabTracker.entitlements`

- SQLite3 Local Food Database - Bundled offline database
  - Size: 382 MB with 1.7M+ foods
  - Path: `JabTracker/Resources/usda_foods.sqlite`
  - Client: `JabTracker/Services/LocalFoodDatabase.swift`
  - Technology: SQLite FTS5 (Full-Text Search)
  - Sources: USDA Foundation/SR Legacy + Open Food Facts dump

**File Storage:**
- Not applicable (no user file uploads)

**Caching:**
- `ChartDatasetCache` - In-memory chart data caching (`JabTracker/Services/ChartDatasetCache.swift`)
- No external caching service

## Authentication & Identity

**Auth Provider:**
- Sign in with Apple - Sole authentication method
  - Implementation: `JabTracker/AuthenticationManager.swift`
  - Token storage: Keychain via Security framework
  - Session management: Apple-managed credentials

**OAuth Integrations:**
- None (Sign in with Apple only)

**Biometric Auth:**
- Face ID/Touch ID - App access protection
  - Implementation: `JabTracker/BiometricAuthManager.swift`
  - Framework: LocalAuthentication

## Monitoring & Observability

**Error Tracking:**
- None currently (no Sentry, Crashlytics, etc.)

**Analytics:**
- None (no Mixpanel, Firebase, etc.)

**Logs:**
- OSLog framework - Local device logs only
  - Subsystem: `com.gannonhall.JabTracker`
  - Retention: iOS system log rotation

## CI/CD & Deployment

**Hosting:**
- App Store - Distribution via TestFlight
  - Bundle ID: `com.gannonhall.JabTracker`
  - Team: `ZBZKKWF95G`

**CI Pipeline:**
- Local scripts (`scripts/check-all.sh`, `scripts/test.sh`)
- No external CI service documented

## Environment Configuration

**Development:**
- Required: Xcode 26.2, macOS
- Launch arguments for testing: `--ui-testing`, `--reset-app-data`, `--seed-test-*`
- No secrets required (Apple APIs use system credentials)

**Production:**
- CloudKit container auto-configured via entitlements
- StoreKit products configured in App Store Connect

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## Data Sources Summary

| Source                           | Type       | Format    | Coverage               |
| -------------------------------- | ---------- | --------- | ---------------------- |
| USDA FoodData Central Foundation | Bundled    | SQLite    | ~7,000 foods           |
| USDA SR Legacy                   | Bundled    | SQLite    | ~8,000 foods           |
| Open Food Facts dump             | Bundled    | SQLite    | ~1.7M branded products |
| Open Food Facts API              | Remote     | REST JSON | Fallback search        |
| CloudKit                         | Cloud sync | SwiftData | User data              |

---

*Integration audit: 2026-01-09*
*Update when adding/removing external services*



---
name: Technology Stack
created: 2025-12-22
last_modified: 2026-01-09
---

# Technology Stack

## Languages

**Primary:**
- Swift 5.9+ - All application code (`project.yml`, all `.swift` files)

**Secondary:**
- Python 3 - Data processing scripts (`scripts/process_usda_data.py`, `scripts/process-off-data.py`)

## Runtime

**Environment:**
- iOS 17.0+ (minimum deployment target) - `project.yml` line 5
- Xcode 26.2 required - `project.yml` line 8

**Package Manager:**
- None (Apple frameworks only)
- No Package.swift, Podfile, or Cartfile

## Frameworks

**Core:**
- SwiftUI - UI Framework (137+ files)
- SwiftData - Data persistence with `@Model` macro (`JabTracker/DataController.swift`, `JabTracker/Models/*.swift`)
- CloudKit - iCloud sync (`JabTracker/JabTracker.entitlements`, `JabTracker/DataController.swift`)

**Testing:**
- Swift Testing - Unit tests (iOS 17+ `@Test` macro) - `JabTrackerTests/`
- XCUITest - UI/E2E tests - `JabTrackerUITests/`

**Build/Dev:**
- XcodeGen - Project generation (`project.yml`)
- SwiftLint - Code linting (`.swiftlint.yml`)
- SwiftFormat - Code formatting
- xcbeautify - Build output formatting

## Key Dependencies

**Zero External Dependencies** - Project uses only Apple frameworks.

**Critical Apple Frameworks:**
- AuthenticationServices - Sign in with Apple (`JabTracker/AuthenticationManager.swift`)
- LocalAuthentication - Face ID/Touch ID (`JabTracker/BiometricAuthManager.swift`)
- StoreKit 2 - Subscription management (`JabTracker/Services/SubscriptionManager.swift`)
- Swift Charts - Data visualization (`JabTracker/Views/Analytics/`)
- UserNotifications - Dose/meal reminders (`JabTracker/Services/NotificationService.swift`)
- HealthKit - Weight data integration (`JabTracker/JabTracker.entitlements`)

**Infrastructure:**
- SQLite3 - Local food database with FTS5 (`JabTracker/Services/LocalFoodDatabase.swift`)
- Foundation - Core APIs, URL networking

## Configuration

**Environment:**
- No external environment variables required
- Launch arguments for test modes (`--ui-testing`, `--reset-app-data`, `--seed-test-7d`)
- CloudKit container: `iCloud.com.gannonhall.JabTracker` (`JabTracker/JabTracker.entitlements`)

**Build:**
- `project.yml` - XcodeGen project configuration
- `JabTracker/Info.plist` - App metadata, permissions, URL schemes
- `JabTracker/JabTracker.entitlements` - Capabilities (CloudKit, HealthKit, Sign in with Apple)
- `JabTrackerStoreKit.storekit` - StoreKit 2 test configuration
- `.swiftlint.yml` - Code quality rules (root + directory-specific overrides)

## Platform Requirements

**Development:**
- macOS (Xcode 26.2)
- No external dependencies or Docker required

**Production:**
- iOS 17.0+ devices
- iCloud account (optional, for sync)
- App Store distribution via TestFlight

---

*Stack analysis: 2026-01-09*
*Update after major dependency changes*



---
name: Codebase Structure
created: 2025-12-22
last_modified: 2026-01-09
---

# Codebase Structure

## Directory Layout

```
jab-tracker-ios/
├── .claude/                    # Claude Code configuration
│   ├── commands/               # Slash commands (context/, dev/, qa/, audit/)
│   ├── context/                # Project context documentation
│   └── skills/                 # Skill definitions (ios-dev, testing)
├── .planning/                  # GSD planning documents
│   └── codebase/               # This codebase analysis
├── JabTracker/                 # Main application source
├── JabTrackerTests/            # Unit tests (144+ files)
├── JabTrackerUITests/          # UI/E2E tests (60+ files)
├── scripts/                    # Build and test scripts
├── logs/                       # Test output logs (gitignored)
├── project.yml                 # XcodeGen configuration
├── CLAUDE.md                   # Claude Code instructions
└── .swiftlint.yml              # SwiftLint configuration
```

## Directory Purposes

**JabTracker/App/**
- Purpose: App entry and coordination
- Contains: `JabTrackerApp.swift`, `AppServices.swift`, `DeeplinkHandler.swift`
- Key files: `JabTrackerApp.swift` (@main entry point)

**JabTracker/Models/**
- Purpose: SwiftData entities and domain types
- Contains: `@Model` classes, enums, extensions
- Key files: `User.swift`, `Dose.swift`, `Food.swift`, `FoodEntry.swift`, `Tab.swift`
- Subdirectories: None (flat structure)

**JabTracker/Services/**
- Purpose: Business logic layer (28 files)
- Contains: `*Service.swift`, `*Manager.swift`, `*Engine.swift`
- Key files: `FoodService.swift`, `ScheduleService.swift`, `PharmacokineticsEngine.swift`, `LocalFoodDatabase.swift`
- Pattern: Base service + extensions (e.g., `ScheduleService+Projection.swift`)

**JabTracker/Views/**
- Purpose: SwiftUI presentation layer (23 feature subdirectories)
- Contains: View files organized by feature
- Subdirectories:
  - `Analytics/` - Charts, trends, insights
  - `Dashboard/` - Main dashboard, concentration cards
    - `Widgets/` - Hero carousel and standard grid widgets (Phase 31)
  - `DoseEntry/` - Quick dose entry, titration dialogs
  - `FoodLog/` - Today's meals view
  - `History/` - Calendar and list views
  - `More/` - Overflow menu (settings access)
  - `Nutrition/` - Food search, detail, serving input
  - `Settings/` - Profile, medications, preferences
  - `Shortcuts/` - Quick action buttons
  - `Shots/` - Combined analytics/history tab
  - `Strategy/` - GLP-1 program guidance
  - `Metrics/` - Body metrics tracking
  - `Photos/` - Progress photos
  - `Weight/` - Weight tracking views
  - `Components/` - Reusable UI components
  - `MedicationProfile/` - Medication setup

**JabTracker/ViewModels/**
- Purpose: MVVM coordination layer
- Contains: `*ViewModel.swift`
- Key files: `FoodSearchSheetViewModel.swift`, `AnalyticsViewModel.swift`
- Note: Some ViewModels live in Views/ subdirectories

**JabTracker/Onboarding/**
- Purpose: First-run onboarding flow
- Contains: Coordinator, ViewModel, step views
- Key files: `OnboardingCoordinator.swift`, `OnboardingViewModel.swift`
- Subdirectories: `Views/` (onboarding step screens)

**JabTracker/Design/**
- Purpose: Design system tokens and components
- Contains: `DesignTokens.swift`, `*Components.swift`, `*Styles.swift`
- Key files: `CircularProgressRing.swift`, `Colors+Extensions.swift`

**JabTracker/Utilities/** and **JabTracker/Utils/**
- Purpose: Shared helpers
- Contains: Validation, constants, test data seeding
- Key files: `DoseValidation.swift`, `TestDataSeeding.swift`, `ProfileValidation.swift`

## Key File Locations

**Entry Points:**
- `JabTracker/App/JabTrackerApp.swift` - @main app entry
- `JabTracker/ContentView.swift` - Main tab navigation
- `JabTracker/App/AppServices.swift` - Service coordinator

**Configuration:**
- `project.yml` - XcodeGen project configuration
- `JabTracker/Info.plist` - App metadata, permissions
- `JabTracker/JabTracker.entitlements` - CloudKit, HealthKit, Sign in with Apple
- `.swiftlint.yml` - Linting rules (root + per-directory)

**Core Logic:**
- `JabTracker/Services/FoodService.swift` - Food search orchestration
- `JabTracker/Services/LocalFoodDatabase.swift` - SQLite FTS5 (1.7M foods)
- `JabTracker/Services/ScheduleService.swift` - Dose scheduling
- `JabTracker/Services/PharmacokineticsEngine.swift` - Concentration calculations
- `JabTracker/DataController.swift` - SwiftData + CloudKit setup

**Testing:**
- `JabTrackerTests/` - Unit tests (Swift Testing framework)
- `JabTrackerUITests/` - E2E tests (XCUITest)
- `JabTrackerUITests/Utils/TestUtilities.swift` - Shared test helpers


## Naming Conventions

**Files:**
- `*View.swift` - SwiftUI views (e.g., `DashboardView.swift`)
- `*ViewModel.swift` - ViewModels (e.g., `AnalyticsViewModel.swift`)
- `*Service.swift` - Services (e.g., `FoodService.swift`)
- `*Manager.swift` - Managers (e.g., `MedicationManager.swift`)
- `Type+Feature.swift` - Extensions (e.g., `ScheduleService+Projection.swift`)
- `*Tests.swift` - Test files (e.g., `FoodServiceTests.swift`)

**Directories:**
- PascalCase for feature directories (e.g., `Nutrition/`, `Dashboard/`)
- Plural for collections (e.g., `Models/`, `Services/`, `Views/`)

**Special Patterns:**
- Service extensions: `ServiceName+Domain.swift`
- Design components: `*Components.swift`, `*Styles.swift`
- Test utilities: `TestUtilities.swift`, `Mock*.swift`

## Where to Add New Code

**New Feature:**
- Primary code: `JabTracker/Views/{FeatureName}/`
- ViewModel: `JabTracker/ViewModels/{Feature}ViewModel.swift` or in Views subdir
- Services: `JabTracker/Services/{Feature}Service.swift`
- Tests: `JabTrackerTests/{layer}/{Feature}Tests.swift`

**New SwiftData Model:**
- Implementation: `JabTracker/Models/{ModelName}.swift`
- Add to schema in `JabTracker/DataController.swift`
- Tests: `JabTrackerTests/Models/{ModelName}Tests.swift`

**New Service:**
- Implementation: `JabTracker/Services/{Name}Service.swift`
- Extensions: `JabTracker/Services/{Name}Service+{Domain}.swift`
- Registration: Add to `JabTracker/App/AppServices.swift`
- Tests: `JabTrackerTests/Services/{Name}ServiceTests.swift`

**New UI Component:**
- Shared component: `JabTracker/Design/{Name}Component.swift`
- Feature-specific: `JabTracker/Views/{Feature}/{Name}.swift`

**Utilities:**
- Shared helpers: `JabTracker/Utilities/` or `JabTracker/Utils/`
- Test utilities: `JabTrackerTests/Mocks/` or `JabTrackerUITests/Utils/`

## Special Directories

**logs/**
- Purpose: Test output logs
- Source: Generated by `scripts/test.sh`
- Committed: No (gitignored)
- Structure: `logs/{test_type}_YYYY-MM-DD_HH-MM-SS/`

**scripts/**
- Purpose: Build and test automation
- Key files: `test.sh`, `build.sh`, `check-all.sh`, `coverage-detail.sh`
- Data processing: `process_usda_data.py`, `process-off-data.py`

**.planning/**
- Purpose: GSD planning documents
- Source: Generated by `/pm-*` commands
- Committed: Yes (planning artifacts)

---

*Structure analysis: 2026-01-09*
*Update when directory structure changes*



---
name: Testing Patterns
created: 2025-12-22
last_modified: 2026-01-09
---

# Testing Patterns

**Analysis Date:** 2026-01-04

## Available Simulators

> **CRITICAL**: Xcode 26.2 requires iOS 26.2 simulators to avoid SwiftData/CloudKit crashes with older runtimes.

| Priority    | Simulator                  | UUID                                 |
| ----------- | -------------------------- | ------------------------------------ |
| **PRIMARY** | iPhone 17 Pro, OS=26.2     | F10F879D-2403-4529-8850-91DE259C1312 |
| SECONDARY   | iPhone 17, OS=26.2         | 63B35940-1E74-4D29-821B-4DB5CAB5FA9C |
| TERTIARY    | iPhone 17 Pro Max, OS=26.2 | 38218630-EBEC-4196-80A2-92AB0A855715 |

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

**TestDataPreset Enum (Unit Tests):**
```swift
enum TestDataPreset {
    case empty
    case sevenDays
    case thirtyDays
    case ninetyDays
    case oneYear

    var dateRange: ClosedRange<Date> { ... }
}

// Usage in tests
let preset = TestDataPreset.sevenDays
seedTestData(for: preset, in: context)
```

**CloudKit Testing Mode:**
```swift
// Disable CloudKit sync for unit tests
let config = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: true,
    cloudKitDatabase: .none  // Critical for test isolation
)
```

---

*Testing analysis: 2026-01-09*
*Update when test patterns change*



# Project Milestones: MacroKinetic

## v0.7.0 Dashboard Widget UX (Shipped: 2026-01-12)

**Delivered:** Unified dashboard with widget-based UI featuring hero carousel (Weekly Nutrition, Daily Nutrition, Energy Balance), standard insights grid (4 widgets), detail views with time filtering and Swift Charts, and TDEE history tracking infrastructure.

**Phases completed:** 30-34 (14 plans total, including decimal phase 33.1)

**Key accomplishments:**

- DashboardWidget protocol and container components (WidgetCard, HeroWidgetContainer, StandardWidgetGroup)
- Hero carousel with 3 swipeable widgets using environment-based display mode toggles
- Standard insights grid with 4 widgets (Expenditure, Weight Trend, Energy Balance, Goal Progress)
- Detail views for Weight Trend, Expenditure, and Energy Balance with time period filtering and Swift Charts
- TDEESnapshot model for historical TDEE tracking with daily backfill logic
- Live data wiring with MVVM ViewModels and comprehensive E2E test suite

**Stats:**

- 151 files modified
- +20,324 / -2,173 lines (net +18,151)
- 6 phases (including 1 decimal phase), 14 plans, 296 min execution time (~5 hours)
- 5 days from start to ship (Jan 8-12, 2026)

**Git range:** `feat(30-01)` → `feat(34-04)`

**What's next:** Protein Alerts, Analytics enhancements, Subscription Management, or Recipe Builder

---

## v0.6.0 Onboarding Redux (Shipped: 2026-01-07)

**Delivered:** Complete rewrite of onboarding focused on core experience — USP showcase with mint brand identity, streamlined goal/program setup, permission screens (HealthKit, Face ID, Notifications), and animated completion flow with smooth transition to main app.

**Phases completed:** 25-29 (6 plans total)

**Key accomplishments:**

- Archived legacy GLP-1 onboarding to Legacy/, created new 17-step @Observable OnboardingViewModel with TDD (21+ tests)
- Welcome screen with AppLogo and 4-feature USP carousel (Adaptive TDEE, Precision Tracking, Calorie Adjustments, GLP-1 Support)
- Streamlined GoalSetupStepView and ProgramSetupStepView with GoalProgramService for smart defaults
- Permission screens for HealthKit, Face ID (dynamic biometric detection), and Notifications with enable/skip options
- CompletionStepView with animated checkmark, personalized summary card, and numbered next-steps guidance
- Comprehensive E2E test navigating through all 17 onboarding steps

**Stats:**

- 102 files modified
- +10,098 / -1,583 lines (net +8,515)
- 5 phases, 6 plans, 245 min execution time (~4 hours)
- 3 days from start to ship (Jan 5-7, 2026)

**Git range:** `770d03d` → `e9a156b`

**What's next:** Protein Preservation Alerts, Analytics Dashboard, Subscription Management, or Recipe Builder

---

## v0.5.0 Navigation Refinement (Shipped: 2026-01-05)

**Delivered:** Streamlined navigation by consolidating GLP-1 features under More tab, promoting Strategy to a top-level tab with check-in badge, and modernizing the Add button with a floating 44pt icon-only design.

**Phases completed:** 22-24 (4 plans total)

**Key accomplishments:**

- Extracted reusable section components (ConcentrationSection, AdherenceSection, HistorySection) from ShotsView with full TDD coverage (10 tests)
- Created unified GLP1ProgramsView consolidating GLP-1 analytics and medication management under More tab
- Promoted Strategy to top-level tab with target icon and weekly check-in badge indicator
- Replaced Add tab item with floating 44pt icon-only button overlay for visual prominence
- Standardized navigation bar styling (inline titles, circle buttons) across app

**Stats:**

- 52 files modified
- +3,285 / -436 lines (net +2,849)
- 3 phases, 4 plans, 80 min execution time
- 2 days from start to ship (Jan 4-5, 2026)

**Git range:** `feat(22-01)` → `feat(24-01)`

**What's next:** Protein Preservation Alerts, Analytics Dashboard, Subscription Management, or Recipe Builder

---

## v0.4.0 Calorie Expenditure Enhancements (Shipped: 2026-01-04)

**Delivered:** Enhanced calorie targets with real-time burned calories from HealthKit, rollover unused calories to next day, and predictive activity adjustments based on 7-day historical trends with goal-type multipliers.

**Phases completed:** 18-21 (4 plans total)

**Key accomplishments:**

- Real-time burned calories from HealthKit added back to daily calorie targets with flame indicator
- Rollover calories feature carrying up to 200 unused calories from yesterday to today
- Predictive activity adjustment using 7-day average with goal-type multipliers (0.8/1.0/1.2)
- CalorieAdjustmentService pipeline with extensible provider architecture
- Calorie breakdown UI showing burned/rollover/predictive adjustments in FoodLogView
- 13 E2E tests for burned calories feature validation and toggle behavior

**Stats:**

- 85 files modified
- +8,945 / -1,610 lines (net +7,335)
- 4 phases, 4 plans, 56 min execution time
- 2 days from start to ship (Jan 3-4, 2026)

**Git range:** `feat(18-01)` → `feat(21-01)`

**What's next:** Protein Preservation Alerts, Analytics Dashboard, or Recipe Builder

---

## v0.3.0 Goals & Nutrition Programs (Shipped: 2026-01-02)

**Delivered:** Goal-based nutrition tracking with customizable programs, adaptive TDEE engine, weekly check-ins, and refined settings experience.

**Phases completed:** 12-17 (20 plans total, including decimal phases 15.1 and 15.2)

**Key accomplishments:**

- NutritionGoal and NutritionProgram data models with User integration
- Separate Goal and Program wizards with Strategy view entry points
- Three program styles: Coached (auto-calculated), Collaborative (per-day editing), Manual (user-defined)
- Adaptive TDEE engine with Mifflin-St Jeor BMR and EWMA weight smoothing
- HealthKit biometrics integration for height, weight, sex, DOB
- Daily progress rings for NutritionSummaryCard with color thresholds
- Weekly check-ins with ProgramOptimizationSheet for goal/program adjustments
- More tab refinements with Security & Privacy, Notifications, and placeholder screens

**Stats:**

- 160 files modified
- +28,655 / -8,034 lines (net +20,621)
- 8 phases (including 2 decimal phases), 20 plans
- 7 days from start to ship (Dec 27, 2025 - Jan 2, 2026)

**Git range:** `feat(12-01)` → `feat(17-03)`

**What's next:** Calorie Expenditure Enhancements (v0.4.0)

---

## v0.2.0 Enhanced Tracking (Shipped: 2025-12-27)

**Delivered:** Enhanced daily tracking with week calendar navigation, food library management, quick macro entry, weight tracking with HealthKit sync, body metrics with progress photos, and feature settings for metrics visibility and units of measure.

**Phases completed:** 5-11 (11 plans total)

**Key accomplishments:**

- Week calendar navigation in Food Log with day selection updating macro summary
- Tap-to-edit food entries with FoodDetailSheet reuse
- Dedicated Food Library screen with Foods tab, sort options, and Your Foods shortcut
- Quick Add macro entry without food lookup via FoodSearchSheet tab
- Weight and body fat tracking with HealthKit sync and unit conversion
- Body metrics (waist, chest, hips, etc.) with configurable visibility and HealthKit sync
- Progress photo capture with camera/library support and photo type configuration
- Feature settings for body metrics visibility toggles and units of measure

**Stats:**

- 127 files created/modified
- +18,659 / -3,032 lines (net +15,627)
- 7 phases, 11 plans, ~4.25 hours execution time
- 4 days from start to ship (Dec 24-27, 2025)

**Git range:** `feat(05-01)` → `feat(11-02)`

**What's next:** Macro Goals & Daily Tracking, Protein Preservation Alerts, or Analytics Dashboard

---

## v0.1.0 Custom Foods (Shipped: 2025-12-24)

**Delivered:** Custom food creation and management with barcode scanning, enabling users to create personalized foods and quickly look them up by scanning product barcodes.

**Phases completed:** 1-4 (6 plans total)

**Key accomplishments:**

- CustomFoodService with full CRUD, validation, barcode uniqueness, and CloudKit sync
- CreateFoodSheet UI with "To Custom" prefill flow and "Create & Add" save-and-log action
- "My Foods" section in search with swipe-to-edit/delete and custom food prioritization
- Barcode scanner using AVFoundation with debouncing, haptic feedback, and ShortcutsSheet integration
- Comprehensive testing with 31+ unit tests and E2E test stubs for all flows
- Full offline support with custom foods persisted locally and synced via CloudKit

**Stats:**

- 71 files created/modified
- ~41,000 lines of Swift
- 4 phases, 6 plans, ~40 minutes execution time
- 3 days from start to ship (Dec 22-24, 2025)

**Git range:** `feat(01-01)` → `feat(04-02)`

**What's next:** Macro Goals & Daily Tracking, Protein Preservation Alerts, or HealthKit Integration

---



# MacroKinetic

## Current State (Updated: 2026-01-12)

**Shipped:** v0.7.0 Dashboard Widget UX (2026-01-12)
**Status:** Development / TestFlight
**Codebase:** ~71,000 lines Swift, SwiftUI/SwiftData, iOS 17+

**v0.7.0 Delivered:**
- Unified dashboard with widget-based UI and DashboardWidget protocol
- Hero carousel with 3 swipeable widgets (Weekly Nutrition, Daily Nutrition, Energy Balance)
- Standard insights grid with 4 widgets (Expenditure, Weight Trend, Energy Balance, Goal Progress)
- Detail views for Weight Trend, Expenditure, and Energy Balance with Swift Charts
- TDEESnapshot model for historical TDEE tracking with daily backfill
- Environment-based display mode toggles for widget state sharing
- Live data wiring with MVVM ViewModels and comprehensive E2E test suite

## Next Milestone Goals

**Vision:** See PRD for planned features - Protein Alerts, Analytics, or Subscription

**Candidates:**
- Protein Preservation Alerts - Minimum protein thresholds and notifications
- Subscription Management - StoreKit 2 integration and paywall
- Recipe Builder - Combine foods into calculated recipes
- GLP-1 Medication Correlation - Connect dose timing with appetite/nutrition patterns

## Vision

MacroKinetic is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management. The app serves anyone on a weight loss or nutrition journey, with specialized features for GLP-1 medication users wanting integrated medication + nutrition tracking.

See [project-prd.md](./project-prd.md) for complete product requirements and feature status.

## Problem

Weight management apps either focus purely on calorie counting (ignoring medication effects) or medication tracking (ignoring nutrition). Users on GLP-1 medications experience appetite changes that affect eating patterns, but no app connects these dots. Additionally, food databases are often inaccurate, and users need the ability to create and manage custom foods for their specific needs.

## Success Criteria

How we know this worked:

- [x] Custom food creation and barcode scanning for personalized entries
- [x] Complete nutrition tracking with macro goals and progress tracking
- [ ] GLP-1 medication tracking with pharmacokinetics modeling
- [ ] Medication-nutrition correlation insights
- [x] CloudKit sync across all user devices
- [x] Offline-first functionality

## Scope

### Completed (v0.1.0)
- Custom food creation and management
- Barcode scanning for quick food lookup
- Food Library with "My Foods" section

### Future Milestones (see PRD)
- Macro Goals & Daily Tracking
- Protein Preservation Alerts
- HealthKit Integration
- Medication-Nutrition Correlation
- Unified Dashboard & Analytics

### Not Building
- Recipe builder (combining multiple foods into calculated recipe) - deferred
- Social features / sharing custom foods
- Micronutrient tracking beyond basic macros

## Context

**Current State:** Brownfield — MacroKinetic has complete food database infrastructure (1.7M+ foods), meal logging UI, medication tracking, dose scheduling, pharmacokinetics engine, CloudKit sync, and now custom foods with barcode scanning.

**Existing Architecture:**
- `Food` model for database foods (SQLite FTS5)
- `CustomFoodService` for user-created foods (SwiftData + CloudKit)
- `FoodEntry` model for logged meals (SwiftData + CloudKit)
- `FoodService` orchestrates search across sources
- Complete medication tracking subsystem
- MVVM architecture with @Observable ViewModels

## Constraints

- **CloudKit Sync**: All user data must sync across devices via iCloud
- **Offline-First**: Full functionality without network; sync when available
- **MVVM Architecture**: @Observable ViewModels, service layer conventions
- **iOS 17+**: Modern SwiftUI and SwiftData APIs
- **Testing**: 85%+ coverage for business logic and view models

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Data Model | Reuse `Food` model with source = .userCreated | Existing infrastructure supports custom foods without new model |
| Food Database | SQLite FTS5 with 1.7M+ foods | Fast full-text search, offline-first, includes barcodes |
| Medication Modeling | Exponential decay pharmacokinetics | Accurate concentration tracking for GLP-1 medications |
| Barcode Scanning | AVFoundation with debouncing | Native performance, 2-second debounce prevents duplicates |

## Open Questions

- [ ] Optimal approach for medication-nutrition correlation engine
- [ ] HealthKit integration scope and permissions flow
- [ ] Subscription tier structure and paywall placement

---
*Initialized: 2025-12-22*
*v0.1.0 Shipped: 2025-12-24*



# Roadmap: MacroKinetic

## Overview

MacroKinetic is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management. See [project-prd.md](./project-prd.md) for complete product requirements.

## Domain Expertise

- ~/.claude/skills/ios-dev/SKILL.md

## Completed Milestones

- ✅ [v0.7.0 Dashboard Widget UX](milestones/v0.7.0-ROADMAP.md) (Phases 30-34) - SHIPPED 2026-01-12
- ✅ [v0.6.0 Onboarding Redux](milestones/v0.6.0-ROADMAP.md) (Phases 25-29) - SHIPPED 2026-01-07
- ✅ [v0.5.0 Navigation Refinement](milestones/v0.5.0-ROADMAP.md) (Phases 22-24) - SHIPPED 2026-01-05
- ✅ [v0.4.0 Calorie Expenditure Enhancements](milestones/v0.4.0-ROADMAP.md) (Phases 18-21) - SHIPPED 2026-01-04
- ✅ [v0.3.0 Goals & Nutrition Programs](milestones/v0.3.0-ROADMAP.md) (Phases 12-17) - SHIPPED 2026-01-02
- ✅ [v0.2.0 Enhanced Tracking](milestones/v0.2.0-ROADMAP.md) (Phases 5-11) - SHIPPED 2025-12-27
- ✅ [v0.1.0 Custom Foods](milestones/v0.1.0-ROADMAP.md) (Phases 1-4) - SHIPPED 2025-12-24

## Milestones

- 🚧 **v0.8.0 Food Search & Library** - Phases 35-38 (in progress)

## Phases

### 🚧 v0.8.0 Food Search & Library (In Progress)

**Milestone Goal:** Dramatically improve food search UX with better performance, ranking, and serving size handling

#### Phase 35: Search Performance & UX

**Goal**: Fix sluggish typing, auto-focus input, expand amount field tap target, polish search header
**Depends on**: Previous milestone complete
**Research**: Unlikely (internal patterns)
**Plans**: TBD

Plans:
- [x] 35-01: Search UX fixes (debounce, auto-focus, tap targets)

#### Phase 35.1: Food Search Header Indicators (INSERTED)

**Goal**: Update Food Search sheet header to show kcal and protein remaining indicators matching the Food Log view style (progress bars with "X left" labels)
**Depends on**: Phase 35
**Research**: Unlikely (internal patterns - reuse existing FoodLogView indicators)
**Plans**: TBD

Plans:
- [x] 35.1-01: Food Search header indicators

#### Phase 36: Search Ranking & Recall

**Goal**: Improve FTS5 ranking so common foods surface easily (apples, eggs, etc.)
**Depends on**: Phase 35
**Research**: Unlikely (FTS5 optimization, internal)
**Plans**: TBD

Plans:
- [ ] 36-01: TBD

#### Phase 37: Unit/Serving Strategy

**Goal**: Research competitors and implement serving size improvements (1 large egg, 1 medium apple)
**Depends on**: Phase 36
**Research**: Likely (competitive analysis required)
**Research topics**: How other apps handle serving sizes, common consumption units from OFF/USDA data
**Plans**: 1

Plans:
- [x] 37-01: Horizontal pill picker for serving unit selection

#### Phase 38: Bug Fixes & Cleanup

**Goal**: Fix barcode scanner bug, remove API fallback
**Depends on**: Phase 37
**Research**: Unlikely (internal fixes)
**Plans**: 1

Plans:
- [x] 38-01: Fix barcode scanner, remove Open Food Facts API, fix ISS-001

## Progress

**Execution Order:**
Phases execute in numeric order within each milestone.

| Phase                              | Milestone | Plans Complete | Status      | Completed  |
| ---------------------------------- | --------- | -------------- | ----------- | ---------- |
| 35. Search Performance & UX        | v0.8.0    | 1/1            | Complete    | 2026-01-12 |
| 35.1 Header Indicators (INSERTED)  | v0.8.0    | 1/1            | Complete    | 2026-01-12 |
| 36. Search Ranking & Recall        | v0.8.0    | 0/0            | Skipped     | -          |
| 37. Unit/Serving Strategy          | v0.8.0    | 1/1            | Complete    | 2026-01-12 |
| 38. Bug Fixes & Cleanup            | v0.8.0    | 1/1            | Complete    | 2026-01-13 |

<details>
<summary>✅ v0.7.0 Dashboard Widget UX (Phases 30-34) - SHIPPED 2026-01-12</summary>

| Phase                           | Plans Complete | Status   | Completed  |
| ------------------------------- | -------------- | -------- | ---------- |
| 30. Dashboard Foundation        | 2/2            | Complete | 2026-01-08 |
| 31. Main Widget (Hero)          | 2/2            | Complete | 2026-01-09 |
| 32. Standard Widgets - Insights | 1/1            | Complete | 2026-01-09 |
| 33. Detail Views                | 3/3            | Complete | 2026-01-10 |
| 33.1 TDEE History (INSERTED)    | 2/2            | Complete | 2026-01-11 |
| 34. Integration & Polish        | 4/4            | Complete | 2026-01-12 |

</details>

<details>
<summary>✅ v0.6.0 Onboarding Redux (Phases 25-29) - SHIPPED 2026-01-07</summary>

| Phase                               | Plans Complete | Status   | Completed  |
| ----------------------------------- | -------------- | -------- | ---------- |
| 25. Onboarding Foundation           | 2/2            | Complete | 2026-01-06 |
| 26. USP Showcase Screens            | 1/1            | Complete | 2026-01-06 |
| 27. Simplified Goal & Program Setup | 1/1            | Complete | 2026-01-06 |
| 28. Permission Setup Screens        | 1/1            | Complete | 2026-01-07 |
| 29. Integration & Polish            | 1/1            | Complete | 2026-01-07 |

</details>

<details>
<summary>✅ v0.5.0 Navigation Refinement (Phases 22-24) - SHIPPED 2026-01-05</summary>

| Phase                            | Plans Complete | Status   | Completed  |
| -------------------------------- | -------------- | -------- | ---------- |
| 22. GLP-1 Programs Consolidation | 2/2            | Complete | 2026-01-05 |
| 23. Strategy Tab Promotion       | 1/1            | Complete | 2026-01-05 |
| 24. Add Button Redesign          | 1/1            | Complete | 2026-01-05 |

</details>

<details>
<summary>✅ v0.4.0 Calorie Expenditure Enhancements (Phases 18-21) - SHIPPED 2026-01-04</summary>

| Phase                              | Plans Complete | Status   | Completed  |
| ---------------------------------- | -------------- | -------- | ---------- |
| 18. Complete Add Burned Calories   | 1/1            | Complete | 2026-01-03 |
| 19. Rollover Calories              | 1/1            | Complete | 2026-01-03 |
| 20. Predictive Activity Adjustment | 1/1            | Complete | 2026-01-03 |
| 21. Integration & Polish           | 1/1            | Complete | 2026-01-04 |

</details>

<details>
<summary>✅ v0.3.0 Goals & Nutrition Programs (Phases 12-17) - SHIPPED 2026-01-02</summary>

| Phase                             | Plans Complete | Status   | Completed  |
| --------------------------------- | -------------- | -------- | ---------- |
| 12. Goal Data Model               | 2/2            | Complete | 2025-12-27 |
| 13. Goal Configuration Wizard     | 2/2            | Complete | 2025-12-28 |
| 14. Adaptive TDEE Engine          | 3/3            | Complete | 2025-12-28 |
| 15. Daily Tracking Dashboard      | 1/1            | Complete | 2025-12-28 |
| 15.1 Initial TDEE Integration     | 3/3            | Complete | 2025-12-28 |
| 15.2 Program Style Implementation | 4/4            | Complete | 2025-12-30 |
| 16. Weekly Check-ins              | 2/2            | Complete | 2025-12-31 |
| 17. More Tab Refinements          | 3/3            | Complete | 2026-01-01 |

</details>

<details>
<summary>✅ v0.2.0 Enhanced Tracking (Phases 5-11) - SHIPPED 2025-12-27</summary>

| Phase                 | Plans Complete | Status   | Completed  |
| --------------------- | -------------- | -------- | ---------- |
| 5. Food Log Calendar  | 1/1            | Complete | 2025-12-24 |
| 6. Food Entry Editing | 1/1            | Complete | 2025-12-24 |
| 7. Food Library       | 1/1            | Complete | 2025-12-24 |
| 8. Quick Add          | 1/1            | Complete | 2025-12-25 |
| 9. Weight Tracking    | 3/3            | Complete | 2025-12-25 |
| 10. Metrics & Photos  | 2/2            | Complete | 2025-12-26 |
| 11. Feature Settings  | 2/2            | Complete | 2025-12-26 |

</details>

<details>
<summary>✅ v0.1.0 Custom Foods (Phases 1-4) - SHIPPED 2025-12-24</summary>

| Phase                         | Plans Complete | Status   | Completed  |
| ----------------------------- | -------------- | -------- | ---------- |
| 1. CustomFood Model & Storage | 1/1            | Complete | 2025-12-22 |
| 2. Create Food UI             | 2/2            | Complete | 2025-12-22 |
| 3. Food Library Integration   | 1/1            | Complete | 2025-12-23 |
| 4. Barcode Assignment         | 2/2            | Complete | 2025-12-23 |

</details>



# Project State

## Project Summary

**Building:** MacroKinetic — iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management.

**Last shipped:** v0.7.0 Dashboard Widget UX (2026-01-12)

**Core value:** Adaptive calorie targets based on real expenditure data with unified dashboard visualization.

## Current Position

Phase: 38 of 38 (Bug Fixes & Cleanup)
Plan: 1 of 1 complete
Status: Phase complete - Milestone complete
Last activity: 2026-01-13 - Completed 38-01-PLAN.md (barcode fix, API removal, tap target)

Progress: ██████████ 100%

## GitHub Tracking

Issue: N/A
PR: N/A
Branch: feat/v0.8.0-food-search-library

## Performance Metrics

**v0.8.0 Velocity:**
- Total plans completed: 5 (including 35.1 inserted phase)
- Average duration: 10 min
- Total execution time: ~50 min

**By Phase:**

| Phase | Plans | Total   | Avg/Plan |
|-------|-------|---------|----------|
| 35    | 1     | ~15 min | 15 min   |
| 35.1  | 1     | ~10 min | 10 min   |
| 36    | 0     | skipped | -        |
| 37    | 1     | ~15 min | 15 min   |
| 38    | 1     | 7 min   | 7 min    |

## Accumulated Context

### Decisions Made

**v0.8.0 decisions:**
- Removed ALL Open Food Facts API code - local database (1.7M foods) is sufficient
- If barcode not found locally, user creates custom food (no API fallback)
- Horizontal pill picker for serving unit selection
- Header indicators in Food Search matching Food Log style

### Deferred Issues

No open issues in `.planning/ISSUES.md`.
- ISS-001 resolved in Phase 38-01

### Pending Todos

7 todos in `.planning/todos/pending/`

### Roadmap Evolution

- Milestone v0.8.0 complete: Food Search & Library, 5 phases (Phase 35-38)
- Phase 35.1 inserted after Phase 35: Food Search Header Indicators
- Phase 36 (Search Ranking) skipped - to be revisited in future milestone

### Blockers/Concerns Carried Forward

None.

## Project Alignment

Last checked: 2026-01-13
Status: ✓ Aligned
Assessment: v0.8.0 milestone complete, ready for completion workflow.
Drift notes: None

## Session Continuity

Last session: 2026-01-13T15:25:42Z
Stopped at: Completed 38-01-PLAN.md (barcode fix, API removal, tap target)
Resume file: None



---
paths: **/*.swift
---

# iOS Development 

## SwiftUI Patterns

- Use `@Observable` (iOS 17+), never `ObservableObject`
- Apply `@MainActor` to ViewModels and Services that touch UI
- Extract reusable components to separate files
- Keep functions under 30 lines
- Use `NavigationStack` for navigation architecture

## SwiftData Patterns

- Non-optional properties with sensible defaults
- Include `createdAt` and `updatedAt` timestamps
- Parent declares `@Relationship(inverse:)`, child uses plain property
- Test environment configuration:
  ```swift
  let configuration = ModelConfiguration(
      isStoredInMemoryOnly: true,
      cloudKitDatabase: .none
  )
  ```

## Swift Naming Conventions

| Type                | Convention        | Example               |
| ------------------- | ----------------- | --------------------- |
| Types/Classes       | PascalCase        | `UserViewModel`       |
| Variables/Functions | camelCase         | `currentUser`         |
| Constants           | camelCase         | `maxStreakCount`      |
| Protocols           | -able/-ing suffix | `Trackable`           |
| Files               | PascalCase        | `UserViewModel.swift` |

## XcodeGen Workflow

After adding any new Swift file, you MUST run:
```bash
xcodegen generate
```

New files won't appear in builds or tests until the project is regenerated.

## Build & Verification Commands

```bash
# Build project
./scripts/build.sh

# Run SwiftLint
swiftlint

# Full CI check
./scripts/check-all.sh --skip-ui
```

## iOS Test Commands

```bash
# Run unit tests
./scripts/test.sh unit 1 <TestClassName>

# Run all unit tests
./scripts/test.sh unit 1

# Run with coverage
./scripts/test.sh unit 1 --coverage

# Run E2E tests
./scripts/test.sh ui 1 <TestClassName>
```

## iOS-Specific Critical Rules

1. **NSFaceIDUsageDescription**: Required in Info.plist before using LocalAuthentication
2. **CloudKit Test Environment**: Always disable CloudKit sync in tests
3. **iOS 26.1 Simulators**: Required for Xcode 26 to avoid SwiftData crashes
4. **Large Navigation Titles**: Use custom scrolling titles to avoid iOS 26.1 visual artifacts
5. **Lint violation exceptions**: To overide siwftlint violations, update or create a .swiftlint.yml in the file's directory. This is easier to manage than inline overrides.



---
paths: **/*UITests.swift
---

# iOS UI Testing (XCUITest)

**Two core principles eliminate 90% of UI test failures:**

1. **Use accessibility identifiers** - Target elements by explicit identifiers, not labels or element hierarchy
2. **Wait for conditions, not timeouts** - Use `waitForExistence(timeout:)` and predicates instead of `sleep()`

---

## ⛔️ MANDATORY: When Tests Fail, Debug First

**STOP. Before changing ANY code when a test fails, you MUST run these debug steps:**

### Step 1: Capture Screenshot
```swift
// Add this line RIGHT BEFORE the failing assertion
TestUtilities.debugScreenshot(app, name: "before-failure")
```

### Step 2: Print Element Hierarchy
```swift
// Add this line RIGHT BEFORE the failing assertion
print(app.debugDescription)
```

### Step 3: Run Test and Examine Output
```bash
./scripts/test.sh ui 1 YourTestClass/testMethod
open logs/latest/screenshots/
```

### Step 4: Analyze BEFORE Changing Code
- **Screenshot shows**: What the UI actually looks like
- **debugDescription shows**: What elements exist and their identifiers
- **Together they answer**: Why can't the test find/interact with the element?

### ❌ DO NOT:
- Guess at element types or identifiers
- Change accessibility identifiers without seeing the hierarchy
- Add arbitrary timeouts hoping it fixes timing
- Modify SwiftUI views without confirming the element structure

### ✅ ALWAYS:
- Capture visual evidence of the failure state
- Print the element tree to see actual identifiers
- Compare expected vs actual element types
- Only then make targeted fixes based on evidence

**This debug-first approach is not optional. Skipping it leads to wasted effort and incorrect fixes.**

---

## Adding Accessibility Identifiers (SwiftUI)

Every testable element needs an accessibility identifier in the source code.

```swift
// ✅ Add identifiers to SwiftUI views
Button("Save") { save() }
    .accessibilityIdentifier("saveButton")

TextField("Enter name", text: $name)
    .accessibilityIdentifier("nameTextField")

Toggle("Enable notifications", isOn: $enabled)
    .accessibilityIdentifier("notificationsToggle")

Text("Welcome, \(user.name)")
    .accessibilityIdentifier("welcomeMessage")

// ✅ For List rows, add identifier to the row content
List(items) { item in
    ItemRow(item: item)
        .accessibilityIdentifier("itemRow-\(item.id)")
}

// ✅ For navigation titles or screen identification
VStack { /* content */ }
    .accessibilityIdentifier("settingsScreen")
```

### Naming Convention

Use consistent, descriptive identifiers:

| Element Type | Pattern                             | Example                             |
| ------------ | ----------------------------------- | ----------------------------------- |
| Buttons      | `{action}Button`                    | `saveButton`, `deleteButton`        |
| Text fields  | `{field}TextField`                  | `nameTextField`, `emailTextField`   |
| Toggles      | `{feature}Toggle`                   | `notificationsToggle`               |
| Static text  | `{purpose}Text` or `{purpose}Label` | `welcomeText`, `errorLabel`         |
| Screens      | `{screen}Screen`                    | `settingsScreen`, `dashboardScreen` |
| Rows         | `{type}Row-{id}`                    | `itemRow-123`                       |

## Debugging Element Hierarchy (CRITICAL)

**Before writing any test query, debug the actual element hierarchy:**

### Print Element Tree
```swift
// In test - print entire app hierarchy
print(app.debugDescription)

// Print specific container
print(app.otherElements["myContainer"].debugDescription)
```

### Use Accessibility Inspector
1. Open Xcode → Open Developer Tool → Accessibility Inspector
2. Target the simulator
3. Hover over elements to see their type, identifier, and label

### Debug Query Results
```swift
// See how many elements match a query
let matches = app.descendants(matching: .any).matching(identifier: "myId")
print("Found \(matches.count) matches")
print(matches.debugDescription)
```

### Interpret Sparse Tree Errors
When XCUITest reports "Multiple matching elements found", it shows a sparse tree:
```
StaticText, identifier: 'calendar-day-20', label: 'Dec 20'
Other, identifier: 'calendar-day-20', label: 'Dec 20'
```
This means SwiftUI created duplicate accessibility elements (see below for fix).

## Debug Screenshots (CRITICAL for Debugging)

**Capture screenshots during test execution to see exactly what the UI looks like:**

### Quick Debug Screenshot
```swift
// Capture at any point during test
TestUtilities.debugScreenshot(app, name: "after-login")
TestUtilities.debugScreenshot(app, name: "error-dialog", context: "unexpected state")

// Sequential screenshots with step numbers
TestUtilities.debugScreenshot(app, step: 1, description: "initial-state")
TestUtilities.debugScreenshot(app, step: 2, description: "after-tap")
TestUtilities.debugScreenshot(app, step: 3, description: "form-submitted")
```

### Capture on Test Failure
```swift
override func tearDown() {
    if testRun?.hasSucceeded == false {
        TestUtilities.captureFailureScreenshot(app, testName: name)
    }
    super.tearDown()
}
```

### Viewing Screenshots
Screenshots are saved to `logs/latest/screenshots/` as PNG files:
```bash
# Open screenshots folder in Finder
open logs/latest/screenshots/

# View a specific screenshot
open logs/latest/screenshots/after-login.png

# List all screenshots
ls -la logs/latest/screenshots/
```

### When to Use Debug Screenshots
| Scenario             | Usage                                                 |
| -------------------- | ----------------------------------------------------- |
| Element not found    | Capture before the failing assertion to see actual UI |
| Wrong element tapped | Capture before and after tap to compare               |
| Timing issues        | Capture at multiple steps to see animation state      |
| Test flakiness       | Capture on failure to see inconsistent state          |
| Debugging hierarchy  | Screenshot + `print(app.debugDescription)` together   |

### Screenshot vs debugDescription
- **Screenshots**: Show visual layout, actual text, colors, positioning
- **debugDescription**: Shows accessibility hierarchy, identifiers, element types
- **Use both together**: Screenshot for "what does it look like?" + debugDescription for "how do I target it?"

## Querying Elements (XCUITest)

Query elements by their accessibility identifier:

```swift
// ✅ Query by accessibility identifier
let saveButton = app.buttons["saveButton"]
let nameField = app.textFields["nameTextField"]
let toggle = app.switches["notificationsToggle"]
let welcomeText = app.staticTexts["welcomeMessage"]

// ✅ Always wait for existence before interacting
XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save button should appear")
saveButton.tap()
```

### SwiftUI Element Type Mapping

SwiftUI components map to XCUITest element types:

| SwiftUI             | XCUITest Query                             |
| ------------------- | ------------------------------------------ |
| Button              | `app.buttons["id"]`                        |
| Text                | `app.staticTexts["id"]`                    |
| TextField           | `app.textFields["id"]`                     |
| SecureField         | `app.secureTextFields["id"]`               |
| Toggle              | `app.switches["id"]`                       |
| Picker              | `app.pickers["id"]` or `app.buttons["id"]` |
| DatePicker          | `app.datePickers["id"]`                    |
| List                | `app.collectionViews["id"]`                |
| NavigationStack     | `app.collectionViews.firstMatch`           |
| View + onTapGesture | `app.otherElements["id"]` ⚠️ NOT buttons    |

### Views with onTapGesture are NOT Buttons

**Critical:** SwiftUI views using `.onTapGesture` are exposed as `otherElements`, NOT `buttons`:

```swift
// SwiftUI source
VStack { Text("Day 20") }
    .onTapGesture { selectDay() }
    .accessibilityIdentifier("calendar-day-20")

// ❌ WRONG - won't find it
let day = app.buttons["calendar-day-20"]  // Returns nothing!

// ✅ CORRECT
let day = app.otherElements["calendar-day-20"]
```

### Handling Multiple Matches with .firstMatch

When a query returns multiple elements, use `.firstMatch`:

```swift
// ❌ Crashes with "Multiple matching elements found"
let element = app.descendants(matching: .any)["myId"]
element.tap()

// ✅ Gets first match
let element = app.descendants(matching: .any)["myId"].firstMatch
element.tap()
```

## Condition-Based Waiting

**Never use `sleep()` in UI tests.** It's unreliable and slow.

### Wait for Element to Appear

```swift
// ✅ Wait for element with timeout
let element = app.buttons["submitButton"]
XCTAssertTrue(element.waitForExistence(timeout: 5), "Submit button should appear")
element.tap()
```

### Wait for Element to Disappear

```swift
func waitForDisappearance(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
    let predicate = NSPredicate(format: "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
}

// Usage: Wait for loading spinner to disappear
let spinner = app.activityIndicators["loadingSpinner"]
XCTAssertTrue(waitForDisappearance(spinner), "Loading should complete")
```

### Wait for Specific State

```swift
func waitForEnabled(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
    let predicate = NSPredicate(format: "isEnabled == true")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
}

// Usage: Wait for button to become enabled after validation
let submitButton = app.buttons["submitButton"]
XCTAssertTrue(waitForEnabled(submitButton), "Submit should enable after input")
submitButton.tap()
```

### Timeout Guidelines

| Operation        | Timeout |
| ---------------- | ------- |
| UI animations    | 2-3s    |
| Local operations | 5s      |
| Network requests | 10s     |
| Complex flows    | 30s max |

## Common Patterns

### System Dialogs (Alerts, Action Sheets)

**Exception to identifier rule:** System dialogs cannot have accessibility identifiers. Query by label text:

```swift
// ✅ Alerts - query by title text
let alert = app.alerts["Delete Account"]  // Uses alert title
XCTAssertTrue(alert.waitForExistence(timeout: 3))

// ✅ Alert buttons - query by button label
let cancelButton = alert.buttons["Cancel"]
let deleteButton = alert.buttons["Delete"]
deleteButton.tap()

// ✅ Action sheets - same pattern
let sheet = app.sheets["Choose Option"]
sheet.buttons["Share"].tap()
```

**Why:** SwiftUI's `.alert()` and `.confirmationDialog()` don't accept `.accessibilityIdentifier()`. These are system-provided UI, so query by their visible text.

### Toggle Interaction (SwiftUI Forms)

SwiftUI Toggles in Forms require coordinate-based tapping:

```swift
// ✅ Tap the switch control (right side of toggle)
let toggle = app.switches["notificationsToggle"]
XCTAssertTrue(toggle.waitForExistence(timeout: 5))
toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
```

### Text Field Entry

```swift
let nameField = app.textFields["nameTextField"]
XCTAssertTrue(nameField.waitForExistence(timeout: 5))
nameField.tap()
nameField.typeText("John Doe")
```

### Verifying Element State

```swift
// ✅ Use isHittable for visibility checks (safe)
if element.exists && element.isHittable {
    element.tap()
}

// ❌ Avoid frame checks (can throw errors)
// if element.frame.width > 0 { }
```

## DisclosureGroup Testing

### Check Default Expansion State

DisclosureGroups have a default expansion state in the ViewModel. **Don't assume they start collapsed.**

```swift
// In ViewModel - check these defaults!
var isDailyEngagementExpanded: Bool = true   // Starts EXPANDED
var isStreakExpanded: Bool = false           // Starts COLLAPSED
```

If section starts expanded, test collapse then expand. If starts collapsed, test expand then collapse.

### Tapping DisclosureGroups

**Don't tap the button directly** - tap the cell containing it:

```swift
// ❌ This often doesn't trigger expansion
let sectionButton = app.buttons["sectionIdentifier"]
sectionButton.tap()

// ✅ Tap the cell containing the disclosure group
let sectionCell = app.cells.containing(.button, identifier: "sectionIdentifier").firstMatch
XCTAssertTrue(sectionCell.waitForExistence(timeout: 5))
sectionCell.tap()
```

## SwiftUI Toggle Identifiers Often Fail

SwiftUI Toggles in Forms often **don't expose their accessibility identifier**. Query by label text instead:

```swift
// ❌ Identifier may not work
let toggle = app.switches["loveTapReminderToggle"]  // Often returns nothing

// ✅ Query by the visible label text
let toggle = app.switches["Love Tap Reminders"]
```

**Always verify in Accessibility Inspector** - actual labels may differ from what you expect:
- Code says "Streak Notifications" but label is "Enable Streak Notifications"

## Index Queries for Multiple Similar Elements

When multiple elements share a parent identifier (e.g., multiple time pickers in a section):

```swift
// ❌ This might match the wrong picker
let timePicker = app.datePickers["sectionId"]

// ✅ Use index query to get specific element
let loveTapTimePicker = app.datePickers.matching(identifier: "dailyEngagementSection").element(boundBy: 0)
let actionTimePicker = app.datePickers.matching(identifier: "dailyEngagementSection").element(boundBy: 1)
```

## Nested Element Queries

For elements inside sections, scope the query using the section identifier:

```swift
// ✅ Find toggle inside a specific section
let intimacyToggle = app.switches["intimacyNotificationSection"].switches.firstMatch
```

## SwiftUI Duplicate Accessibility Elements (CRITICAL)

SwiftUI often creates **duplicate accessibility elements** when a view contains Text and has an identifier:

```
// Error: "Multiple matching elements found"
StaticText, identifier: 'calendar-day-20'
Other, identifier: 'calendar-day-20'
```

### Source Code Fix

Use `.accessibilityElement(children: .combine)` to create a single element:

```swift
// ❌ Creates duplicate elements
VStack {
    Text("20")
    Image(systemName: "circle.fill")
}
.accessibilityIdentifier("calendar-day-20")

// ✅ Creates single combined element
VStack {
    Text("20")
    Image(systemName: "circle.fill")
}
.accessibilityElement(children: .combine)  // Add this!
.accessibilityIdentifier("calendar-day-20")
.accessibilityLabel("December 20")
```

### Options for .accessibilityElement

| Option     | Behavior                                                      |
| ---------- | ------------------------------------------------------------- |
| `.combine` | Merges all children into one element (most common fix)        |
| `.ignore`  | Hides children, only parent is accessible                     |
| `.contain` | Parent and children are separate (default, causes duplicates) |

## Common Mistakes

| Mistake                              | Problem                         | Solution                                        |
| ------------------------------------ | ------------------------------- | ----------------------------------------------- |
| Using `sleep()`                      | Slow, unreliable                | `waitForExistence(timeout:)`                    |
| Querying by label text               | Breaks with localization        | Use accessibility identifiers                   |
| No identifier in source              | Element not findable            | Add `.accessibilityIdentifier("id")`            |
| Not waiting before tap               | Element not ready               | Always `waitForExistence` first                 |
| Using `.frame` checks                | Throws invalid frame errors     | Use `.isHittable` instead                       |
| Assuming element types               | SwiftUI maps differently        | Check element type mapping table                |
| Adding identifier to alert           | Doesn't work on system dialogs  | Query alerts/sheets by title text               |
| Tapping DisclosureGroup button       | Doesn't expand section          | Tap the containing cell instead                 |
| Assuming toggle identifiers work     | SwiftUI Forms don't expose them | Query by label text                             |
| Assuming sections start collapsed    | May start expanded              | Check ViewModel defaults                        |
| View with Text + identifier          | Creates duplicate elements      | Add `.accessibilityElement(children: .combine)` |
| Using `app.buttons` for onTapGesture | Wrong element type              | Use `app.otherElements` instead                 |

## Test Structure

```swift
func testFeatureBehavior() throws {
    // GIVEN: Set up initial state
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    // Navigate to screen
    let tab = app.tabBars.buttons["Settings"]
    XCTAssertTrue(tab.waitForExistence(timeout: 5))
    tab.tap()

    // WHEN: Perform action
    let toggle = app.switches["notificationsToggle"]
    XCTAssertTrue(toggle.waitForExistence(timeout: 5))
    toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

    // THEN: Verify outcome
    let confirmation = app.staticTexts["settingsSavedText"]
    XCTAssertTrue(confirmation.waitForExistence(timeout: 5), "Confirmation should appear")
}
```

## Quick Reference

**In SwiftUI (add identifiers):**
```swift
.accessibilityIdentifier("myIdentifier")
```

**In XCUITest (query elements):**
```swift
let element = app.buttons["myIdentifier"]
XCTAssertTrue(element.waitForExistence(timeout: 5))
element.tap()
```

**Two rules that prevent flaky tests:**
1. Every testable element has an accessibility identifier
2. Every interaction waits for condition, never sleeps



## Simulator Conflicts

When running tests, ensure no conflicting simulators are active. Use:

```bash
xcrun simctl list
```

Use 1 of 3 the 3 available iPhone 17 Pro simulators to avoid conflicts. E,g:
```bash
./scripts/scripts.sh ui 3
```



---
paths: *Tests/**/*.swift, !*UITests/**/*.swift
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
| Tests pass but 0% coverage | `executionCount: 0` for all functions | Verify tests actually call production code, not mocks     |
| Private method not covered | Can't test directly                   | Test via public methods that invoke them                  |
| Async method low coverage  | Race conditions                       | Add `try await Task.sleep(for: .milliseconds(100))` waits |
| Extension file 0% coverage | Swift coverage attribution            | Check if tests call the correct module/class              |
| Result bundle not found    | Missing `.coverage/`                  | Run tests with `--coverage` or `-enableCodeCoverage YES`  |

### Coverage Configuration File

Create `coverage-config.json` in project root:

```json
{
  "policy": {
    "tiers": {
      "pure_business_logic": {
        "threshold": 90,
        "files": ["Models/User.swift", "Services/Calculator.swift"]
      },
      "infrastructure": {
        "threshold": 60,
        "files": ["Services/DataService.swift", "Services/AuthService.swift"]
      }
    }
  },
  "exclusions": {
    "files": ["Utils/TestHelpers.swift"]
  }
}
```

## Running Unit Tests

### Using Project Scripts (Recommended)

```bash
# Quick unit test run
./scripts/test.sh unit 1

# Run specific unit test suite
./scripts/test.sh unit 1 MyServiceTests

# Run with coverage
./scripts/test.sh unit 1 --coverage

# Silent mode (log only, no console output)
./scripts/test.sh unit 1 --coverage --log-only

# View latest test results
cat logs/latest/raw_output.txt
```

### Using xcodebuild Directly

```bash
# Run all unit tests
xcodebuild test \
  -scheme AppName \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  -only-testing:AppNameTests \
  | xcbeautify

# Run with coverage enabled
xcodebuild test \
  -scheme AppName \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  -enableCodeCoverage YES \
  -resultBundlePath .coverage/coverage.xcresult \
  -only-testing:AppNameTests \
  | xcbeautify

# Run specific test suite
xcodebuild test \
  -scheme AppName \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  -only-testing:AppNameTests/MyServiceTests \
  | xcbeautify
```

### Swift Testing Framework Limitations

**Unit Test Targeting Support:**
- ✅ **Target Level**: `-only-testing:AppNameTests` (all unit tests)
- ✅ **Suite Level**: `-only-testing:AppNameTests/MyServiceTests` (specific test suite)
- ❌ **Method Level**: Swift Testing doesn't support individual method isolation

**Note**: Unlike XCTest, Swift Testing framework doesn't support running individual unit test methods. When you specify a method name for unit tests, the entire test suite will run. For granular testing, organize tests into focused test suites/classes.

## Test Execution Notes

- Coverage result bundles: `.coverage/coverage.xcresult` (project convention)
- Log files (if using scripts): `logs/latest/raw_output.txt`, `logs/latest/coverage.json`
- Swift Testing uses `@Test` attribute, XCTest uses `func test...()` prefix
- Always use `-enableCodeCoverage YES` when you need coverage data

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
@testable import AppName

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

## Simulator Conflicts

When running tests, ensure no conflicting simulators are active. Use:

```bash
xcrun simctl list
```

Use 1 of 3 the 3 available iPhone 17 Pro simulators to avoid conflicts. E,g:
```bash
./scripts/scripts.sh unit 1
```


