---
name: Coding Conventions
created: 2025-12-22
last_modified: 2026-01-09
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
