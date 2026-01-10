---
created: 2024-01-15T00:00:00Z
updated: 2025-12-21T22:39:46Z
---

# MacroKinetic Product Requirements Document

## Overview

MacroKinetic is a comprehensive iOS weight management app combining precision nutrition tracking with optional GLP-1 medication management.

**Target Users:**
- Primary: Anyone on a weight loss or nutrition journey
- Secondary: GLP-1 medication users wanting medication + nutrition integration

**Tech Stack:** iOS 17+, Swift/SwiftUI, SwiftData, CloudKit, SQLite FTS5

---

## Feature Status Legend

| Status | Meaning     |
| ------ | ----------- |
| ✅      | Done        |
| 🔨      | In Progress |
| 📋      | Planned     |

---

## Features (Sequenced)

### ✅ Authentication

| Requirement                     | Done |
| ------------------------------- | ---- |
| Sign in with Apple              | ✅    |
| Face ID/Touch ID for app access | ✅    |
| Keychain credential storage     | ✅    |
| Persistent session state        | ✅    |

---

### ✅ User Onboarding (Medication Path)

| Requirement                                 | Done |
| ------------------------------------------- | ---- |
| Welcome screens with app benefits           | ✅    |
| Medication selection wizard (4 GLP-1 meds)  | ✅    |
| Initial dose entry with injection site      | ✅    |
| Schedule setup (weekly, split-dose, custom) | ✅    |
| Notification permissions                    | ✅    |
| Subscription screen placeholder             | ✅    |

---

### ✅ Medication Profile Management

| Requirement                                     | Done |
| ----------------------------------------------- | ---- |
| CRUD for medication profiles                    | ✅    |
| Support 4 GLP-1 medications with brand variants | ✅    |
| Brand-aware dose validation                     | ✅    |
| Dose escalation (titration) tracking            | ✅    |
| Reconstitution calculator for compounded meds   | ✅    |
| Injection site preferences                      | ✅    |

---

### ✅ Dose Tracking

| Requirement                                      | Done |
| ------------------------------------------------ | ---- |
| Quick dose entry via "+" tab button              | ✅    |
| Manual entry with date/time, amount, site, notes | ✅    |
| Calendar view with dose indicators               | ✅    |
| List view with search and filtering              | ✅    |
| Edit/delete past entries                         | ✅    |
| Statistics (adherence rates, streaks)            | ✅    |

---

### ✅ Pharmacokinetics Engine

| Requirement                                  | Done |
| -------------------------------------------- | ---- |
| Exponential decay concentration modeling     | ✅    |
| Medication-specific half-life values         | ✅    |
| Peak, trough, and current level calculations | ✅    |
| Steady-state progress tracking               | ✅    |
| ConcentrationCard dashboard display          | ✅    |

---

### ✅ Dose Scheduling

| Requirement                                    | Done |
| ---------------------------------------------- | ---- |
| Schedule creation (weekly, split-dose, custom) | ✅    |
| Upcoming dose projections                      | ✅    |
| Pause/resume schedules                         | ✅    |
| Modification history                           | ✅    |
| Titration completion workflow                  | ✅    |

---

### ✅ Notifications (Medication)

| Requirement                         | Done |
| ----------------------------------- | ---- |
| Scheduled dose reminders            | ✅    |
| Titration completion alerts         | ✅    |
| Missed dose notifications           | ✅    |
| Badge management                    | ✅    |
| Deep linking to entry screens       | ✅    |
| Action handling (log, snooze, skip) | ✅    |

---

### ✅ Analytics (Medication)

| Requirement                                | Done |
| ------------------------------------------ | ---- |
| Concentration timeline chart (interactive) | ✅    |
| Time period selection (7d, 30d, 90d, 1y)   | ✅    |
| Dose markers on timeline                   | ✅    |
| Future projections                         | ✅    |
| Adherence insights                         | ✅    |
| Streak tracking                            | ✅    |

---

### ✅ CloudKit Sync

| Requirement                      | Done |
| -------------------------------- | ---- |
| Automatic iCloud synchronization | ✅    |
| Real-time sync status monitoring | ✅    |
| Graceful offline-first fallback  | ✅    |
| Multi-device support             | ✅    |

---

### ✅ Food Database Infrastructure

Issue: [#314](https://github.com/gannonh/jab-tracker-ios/issues/314)

| Requirement                             | Done |
| --------------------------------------- | ---- |
| Food and FoodEntry SwiftData models     | ✅    |
| 1.7M+ foods from USDA + Open Food Facts | ✅    |
| SQLite FTS5 full-text search            | ✅    |
| Barcode column with index               | ✅    |
| Offline-first (entire database bundled) | ✅    |
| FoodService orchestrating search        | ✅    |
| LocalFoodDatabase service               | ✅    |
| OpenFoodFactsService API client         | ✅    |
| MealLogService for CRUD                 | ✅    |

---

### ✅ Meal Logging UI

Issue: [#314](https://github.com/gannonh/jab-tracker-ios/issues/314)

| Requirement                                           | Done |
| ----------------------------------------------------- | ---- |
| FoodSearchView - search with results list             | ✅    |
| FoodDetailView - nutrition facts, serving adjustment  | ✅    |
| MealLogView - today's meals by section                | ✅    |
| AddFoodSheet - quick add modal                        | ✅    |
| Four meal sections (breakfast, lunch, dinner, snacks) | ✅    |
| Serving size input with unit conversion               | ✅    |
| Edit and delete logged entries                        | ✅    |

---

### 📋 User Model Extension (Nutrition Goals)

| Requirement                    | Done |
| ------------------------------ | ---- |
| Daily calorie goal field       |      |
| Daily protein goal field       |      |
| Daily carb goal field          |      |
| Daily fat goal field           |      |
| FoodEntry relationship on User |      |

---

### 📋 Tab Navigation Update

| Requirement                              | Done |
| ---------------------------------------- | ---- |
| Update tab structure for nutrition focus |      |
| "+" button opens food/dose picker        |      |
| Combined history view (meals + doses)    |      |

---

### 📋 Macro Goals & Daily Tracking

| Requirement                                           | Done |
| ----------------------------------------------------- | ---- |
| Goal configuration UI (calories, protein, carbs, fat) |      |
| Progress rings/bars for each macro                    |      |
| Remaining vs consumed display                         |      |
| Color coding for under/over targets                   |      |
| Daily summary on dashboard                            |      |

---

### 📋 Protein Preservation Alerts

| Requirement                                              | Done |
| -------------------------------------------------------- | ---- |
| Minimum protein threshold based on body weight (1.6g/kg) |      |
| ProteinMonitoringService                                 |      |
| Evening notification if protein < 80% target             |      |
| Protein progress ring on dashboard (prominent)           |      |
| Color-coded severity (green/yellow/red)                  |      |
| High-protein food suggestions                            |      |
| Weekly protein trend analysis                            |      |

---

### 📋 HealthKit Integration

| Requirement                                | Done |
| ------------------------------------------ | ---- |
| HealthKitService                           |      |
| Request authorization                      |      |
| Sync weight from Apple Health              |      |
| Sync body fat percentage                   |      |
| Sync steps and active calories             |      |
| Display weight trend on dashboard          |      |
| Calculate net calories (consumed - burned) |      |

---

### 📋 Medication-Nutrition Correlation

| Requirement                                        | Done |
| -------------------------------------------------- | ---- |
| AppetiteEntry model (hunger, cravings, food noise) |      |
| Daily appetite check-in UI                         |      |
| NutritionCorrelationEngine                         |      |
| Concentration vs. appetite chart overlay           |      |
| Food noise reduction timeline                      |      |
| Eating patterns by medication cycle                |      |
| Optimal eating window calculation                  |      |
| Correlation insights generation                    |      |

---

### 📋 Barcode Scanning

| Requirement                     | Done |
| ------------------------------- | ---- |
| AVFoundation camera integration |      |
| Open Food Facts API lookup      |      |
| Quick-add flow after scan       |      |
| Handle "not found" gracefully   |      |

---

### 📋 AI Photo to Macros

| Requirement                                     | Done |
| ----------------------------------------------- | ---- |
| Camera capture for food photos                  |      |
| AI vision API integration (identify food items) |      |
| Portion size estimation from image              |      |
| Macro estimation based on identified foods      |      |
| User confirmation/adjustment before logging     |      |
| Fallback to manual search if low confidence     |      |

---

### 📋 Unified Dashboard

| Requirement                           | Done |
| ------------------------------------- | ---- |
| Concentration card (medication users) |      |
| Today's nutrition summary             |      |
| Prominent protein progress ring       |      |
| Appetite/food noise indicator         |      |
| Weight trend from HealthKit           |      |

---

### 📋 Combined Calendar View

| Requirement                                    | Done |
| ---------------------------------------------- | ---- |
| Dose markers (existing)                        |      |
| Meal indicators (breakfast/lunch/dinner icons) |      |
| Protein status dots (green/yellow/red)         |      |
| Weight data points                             |      |

---

### 📋 Unified Analytics

| Requirement                                    | Done |
| ---------------------------------------------- | ---- |
| Nutrition trends (calories, protein over time) |      |
| Concentration vs. daily calories chart         |      |
| Food noise by day post-dose chart              |      |
| Protein intake vs. weight change chart         |      |

---

### 📋 Export & Reporting

| Requirement                             | Done |
| --------------------------------------- | ---- |
| PDF report generation                   |      |
| CSV export                              |      |
| Combined medication + nutrition summary |      |
| Weight progress section                 |      |

---

### 📋 User Onboarding (Nutrition Path)

| Requirement                                            | Done |
| ------------------------------------------------------ | ---- |
| Welcome screens with nutrition benefits                |      |
| Goal selection (weight loss, maintenance, muscle gain) |      |
| Macro target setup                                     |      |
| Meal reminder preferences                              |      |
| Optional: Add medication tracking                      |      |

---

### 🔨 Subscription Management

| Requirement            | Done |
| ---------------------- | ---- |
| StoreKit 2 integration |      |
| Subscription tiers     |      |
| Paywall UI             |      |
| Restore purchases      |      |

---

## Non-Functional Requirements

### Performance
| Metric                        | Target      |
| ----------------------------- | ----------- |
| App launch                    | < 2 seconds |
| Food search                   | < 100ms     |
| Calculation updates           | < 50ms      |
| Chart rendering (365 entries) | < 500ms     |
| Memory usage                  | < 100MB     |

### Security & Privacy
- SwiftData encryption
- Keychain for credentials
- Biometric protection
- On-device processing preference
- No third-party analytics

### Accessibility
- VoiceOver support
- Dynamic Type scaling
- High Contrast mode
- Reduce Motion compatibility
- 44x44pt minimum touch targets

### Testing Coverage
- Business Logic: 90%
- View Models: 85%
- Infrastructure: 62%
- Framework Integration: 42%

---

## Competitive Advantages

| Feature                       | Competitors     | MacroKinetic           |
| ----------------------------- | --------------- | ---------------------- |
| Food database                 | 100K-1M         | 1.7M+ with barcodes    |
| Pharmacokinetics              | Basic estimates | True exponential decay |
| Medication-nutrition insights | None            | Correlation engine     |
| Protein preservation alerts   | None            | Yes                    |
| Offline food search           | Limited         | Full database offline  |
| Reconstitution calculator     | None            | Yes                    |
| Split-dose support            | None            | Yes                    |

---

## Update History

- 2025-12-20: Consolidated from macro-integration.md and project-prd.md into single sequenced PRD
- 2025-12-19: Initial nutrition infrastructure documentation



# Architecture

**Analysis Date:** 2025-12-22

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
- Contains: `*Service.swift`, `*Manager.swift` (28 files)
- Location: `JabTracker/Services/*.swift`
- Depends on: Models, ModelContext, external APIs
- Used by: ViewModels, other Services

**Data Layer (Models):**
- Purpose: SwiftData entities, domain types
- Contains: `@Model` classes, enums, supporting types
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

*Architecture analysis: 2025-12-22*
*Update when major patterns change*



# Codebase Concerns

**Analysis Date:** 2025-12-22

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

## Known Bugs

**None critical identified during analysis.**

Minor issues:
- Regex parsing for serving descriptions may fail silently on malformed data
- File: `JabTracker/Views/Nutrition/EditFoodEntrySheet.swift:53-59`
- Workaround: Falls back to `entry.servingGrams`
- Root cause: No logging when parse fails

## Security Considerations

**URL construction without encoding:**
- Risk: Barcode directly interpolated into URL path
- File: `JabTracker/Services/OpenFoodFactsService.swift:88`
- Current mitigation: Barcode trimmed of whitespace only
- Recommendations: Use proper URL encoding for barcode parameter

**No rate limiting on API calls:**
- Risk: Excessive API calls if user types quickly in search
- File: `JabTracker/Services/OpenFoodFactsService.swift`
- Current mitigation: None
- Recommendations: Add debounce/throttle to search, or implement at service level

## Performance Bottlenecks

**Regex compilation on every parse:**
- Problem: Serving option regex compiled for each food item
- File: `JabTracker/Services/FoodService.swift:132`
- Measurement: Not measured, but called per-item in search results
- Cause: Regex pattern `#"^([\d.]+)\s*(\w+)\s*\((\d+(?:\.\d+)?)g\)$"#` created inline
- Improvement path: Compile once as static property

## Fragile Areas

**Fatal errors in production paths:**
- Files with `fatalError`:
  - `JabTracker/DataController.swift:130` - ModelContainer creation failure
  - `JabTracker/Views/Nutrition/FoodSearchSheet.swift:56` - Missing service injection
  - `JabTracker/AuthenticationManager.swift:614` - No window for Sign in with Apple
- Why fragile: App crashes immediately instead of graceful error handling
- Common failures: Missing dependencies, unusual device states
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
1. Replace `fatalError` in `DataController.swift:130` with graceful error handling
2. Replace `fatalError` in `FoodSearchSheet.swift:56` with optional service pattern
3. Replace `fatalError` in `AuthenticationManager.swift:614` with error state

**High Priority:**
1. Implement BGTaskScheduler for background notification refresh
2. Add URL encoding for barcode API calls
3. Add error/crash reporting service

**Medium Priority:**
1. Complete split-dose UI (Phase 3 TODO)
2. Consolidate food deduplication logic
3. Add rate limiting to food search
4. Static regex compilation for performance

---

*Concerns audit: 2025-12-22*
*Update as issues are fixed or new ones discovered*



# Coding Conventions

**Analysis Date:** 2025-12-22

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

**Key SwiftLint Settings (`.swiftlint.yml`):**
```yaml
line_length: warning: 120, error: 150
type_body_length: warning: 350, error: 400
function_body_length: warning: 50, error: 80
cyclomatic_complexity: warning: 10, error: 20
```

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

---

*Convention analysis: 2025-12-22*
*Update when patterns change*



# External Integrations

**Analysis Date:** 2025-12-22

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

| Source | Type | Format | Coverage |
|--------|------|--------|----------|
| USDA FoodData Central Foundation | Bundled | SQLite | ~7,000 foods |
| USDA SR Legacy | Bundled | SQLite | ~8,000 foods |
| Open Food Facts dump | Bundled | SQLite | ~1.7M branded products |
| Open Food Facts API | Remote | REST JSON | Fallback search |
| CloudKit | Cloud sync | SwiftData | User data |

---

*Integration audit: 2025-12-22*
*Update when adding/removing external services*



# Technology Stack

**Analysis Date:** 2025-12-22

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

*Stack analysis: 2025-12-22*
*Update after major dependency changes*



# Codebase Structure

**Analysis Date:** 2025-12-22

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
- Purpose: SwiftUI presentation layer
- Contains: View files organized by feature
- Subdirectories:
  - `Analytics/` - Charts, trends, insights
  - `Dashboard/` - Main dashboard, concentration cards
  - `DoseEntry/` - Quick dose entry, titration dialogs
  - `FoodLog/` - Today's meals view
  - `History/` - Calendar and list views
  - `More/` - Overflow menu (settings access)
  - `Nutrition/` - Food search, detail, serving input
  - `Settings/` - Profile, medications, preferences
  - `Shortcuts/` - Quick action buttons
  - `Shots/` - Combined analytics/history tab
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

*Structure analysis: 2025-12-22*
*Update when directory structure changes*



# Testing Patterns

**Analysis Date:** 2025-12-22

## MANDATORY: Load Testing Skills First

**CRITICAL REQUIREMENT**: Before writing, debugging, or running any tests, you **MUST** load the appropriate skill:

| Test Type | Required Skill | Command |
|-----------|---------------|---------|
| Unit/Integration Tests | `/ios-unit-testing` | Run first |
| E2E/UI Tests | `/ios-e2e-testing` | Run first |

**Why this is mandatory:**
- Skills contain detailed patterns for Swift Testing framework and XCUITest
- SwiftData test data management requires specific patterns (container lifetime)
- E2E tests require debug-first element targeting approach
- Without skills, you will likely introduce bugs or flaky tests

**Always invoke the skill BEFORE:**
- Writing new test files
- Debugging failing tests
- Adding test coverage
- Fixing flaky tests
- Setting up test data

## Available Simulators

> **CRITICAL**: Xcode 26.2 requires iOS 26.2 simulators to avoid SwiftData/CloudKit crashes with older runtimes.

| Priority | Simulator | UUID |
|----------|-----------|------|
| **PRIMARY** | iPhone 17 Pro, OS=26.2 | F10F879D-2403-4529-8850-91DE259C1312 |
| SECONDARY | iPhone 17, OS=26.2 | 63B35940-1E74-4D29-821B-4DB5CAB5FA9C |
| TERTIARY | iPhone 17 Pro Max, OS=26.2 | 38218630-EBEC-4196-80A2-92AB0A855715 |

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



