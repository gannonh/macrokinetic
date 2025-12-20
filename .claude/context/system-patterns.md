---
created: 2025-12-19T14:55:18Z
last_updated: 2025-12-20T17:50:53Z
---

# System Patterns

## Architecture Overview

### MVVM with SwiftUI

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    View     │ ──▶ │  ViewModel  │ ──▶ │   Service   │ ──▶ │    Model    │
│  (SwiftUI)  │     │ (@Observable)│     │ (@Observable)│     │ (SwiftData) │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

### Data Flow
1. User interacts with SwiftUI View
2. View calls ViewModel methods
3. ViewModel coordinates with Services
4. Services perform business logic and persist to SwiftData
5. CloudKit syncs changes automatically

## Observable Patterns

### Modern @Observable (Preferred)
```swift
@Observable
class QuickDoseViewModel {
    var selectedMedication: MedicationProfile?
    var doseAmount: Double = 0.0
    var isLoading = false

    func saveDose() async throws { ... }
}

// In View:
@State private var viewModel = QuickDoseViewModel()
```

### Service Coordinator Pattern
```swift
@MainActor
final class AppServices: ObservableObject {
    static let shared = AppServices()

    private(set) var scheduleService: ScheduleService?
    private(set) var notificationService: NotificationService?

    func initialize(with modelContext: ModelContext) {
        guard scheduleService == nil else { return }
        let scheduleService = ScheduleService(context: modelContext)
        self.scheduleService = scheduleService
        self.notificationService = NotificationService(scheduleService: scheduleService)
    }
}

// Usage in View:
@ObservedObject private var appServices = AppServices.shared
```

## SwiftData Patterns

### Model Definition
```swift
@Model
final class Dose {
    var id: UUID = UUID()
    var amount: Double = 0.0
    var timestamp: Date = Date()
    var user: User?  // Child - plain property, no @Relationship
    var medication: MedicationProfile?

    init(amount: Double, timestamp: Date = Date()) {
        self.amount = amount
        self.timestamp = timestamp
    }
}
```

### Parent-Child Relationships
```swift
// Parent side - uses @Relationship with inverse
@Model
final class User {
    @Relationship(deleteRule: .cascade, inverse: \Dose.user)
    var doses: [Dose]?

    @Relationship(deleteRule: .cascade, inverse: \MedicationProfile.user)
    var medicationProfiles: [MedicationProfile]?
}

// Child side - plain property only
@Model
final class Dose {
    var user: User?  // NO @Relationship attribute
}
```

### CloudKit Compatibility Requirements
- All properties must have default values
- Only parent uses `@Relationship(inverse:)`
- Test with `cloudKitDatabase: .none` to avoid sync issues

## Service Extension Pattern

Services are split into focused extensions:

```swift
// Base service
@Observable
class ScheduleService {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }
}

// Extensions for specific domains
// ScheduleService+Projection.swift
extension ScheduleService {
    func getUpcomingDoses(for schedule: DoseSchedule) -> [ScheduledDose] { ... }
}

// ScheduleService+Adherence.swift
extension ScheduleService {
    func calculateAdherence(for schedule: DoseSchedule) -> Double { ... }
}
```

## Error Handling

### Service Errors
```swift
enum ScheduleServiceError: LocalizedError {
    case invalidSchedule
    case scheduleNotFound
    case contextError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidSchedule: return "Invalid schedule configuration"
        case .scheduleNotFound: return "Schedule not found"
        case .contextError(let error): return "Database error: \(error.localizedDescription)"
        }
    }
}
```

### Graceful Degradation
- CloudKit unavailable → Continue with local-only
- Network errors → Queue for retry
- Authentication failures → Clear error with retry option

## Testing Patterns

### SwiftData Test Setup

**CRITICAL: ModelContainer Lifetime**

When creating test helpers that return a ModelContext, you MUST also return and keep alive the ModelContainer. If a helper function creates a container but only returns the context, the container gets deallocated when the function returns, making the context invalid and causing `EXC_BREAKPOINT` crashes on `context.insert()`.

```swift
// ✅ CORRECT: Return both context and container
func createTestContext() -> (context: ModelContext, container: ModelContainer) {
    let schema = Schema([User.self, Dose.self, MedicationProfile.self])
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none  // Critical for tests
    )
    let container = try! ModelContainer(for: schema, configurations: [config])
    return (container.mainContext, container)
}

// In test: capture container to keep it alive
@Test("Example test")
func testExample() {
    let (context, container) = createTestContext()
    _ = container  // Keep container alive for duration of test

    // Now context.insert() will work
    context.insert(model)
}

// ❌ WRONG: Returns only context - container gets deallocated!
func createTestContext() -> ModelContext {
    let container = try! ModelContainer(...)
    return container.mainContext  // Container deallocated after return!
}
```

### Protocol-Based Mocking
```swift
protocol NotificationCenterProtocol {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
}

// Production
extension UNUserNotificationCenter: NotificationCenterProtocol {}

// Test
class MockNotificationCenter: NotificationCenterProtocol {
    var authorizationResult = true
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        return authorizationResult
    }
}
```

## UI Patterns

### Tab Navigation
```swift
enum Tab: Hashable {
    case dashboard
    case history
    case analytics
    case settings
}

@State private var selectedTab: Tab = .dashboard
@State private var showQuickDose = false

TabView(selection: $selectedTab) {
    DashboardView()
        .tag(Tab.dashboard)
        .tabItem { Label("Home", systemImage: "house") }

    // "+" button triggers sheet, not a tab
    Color.clear
        .tag(Tab.history)
        .tabItem { Label("Add", systemImage: "plus.circle.fill") }
        .onTapGesture { showQuickDose = true }

    HistoryView()
        .tag(Tab.history)
        .tabItem { Label("History", systemImage: "calendar") }
}
.sheet(isPresented: $showQuickDose) {
    QuickDoseSheet()
}
```

### Form Validation
```swift
@Observable
class FormViewModel {
    var amount: String = ""
    var isValid: Bool {
        guard let value = Double(amount) else { return false }
        return value > 0 && value <= maxDose
    }
    var validationError: String? {
        guard !amount.isEmpty else { return nil }
        guard let value = Double(amount) else { return "Enter a valid number" }
        if value <= 0 { return "Amount must be positive" }
        if value > maxDose { return "Amount exceeds maximum dose" }
        return nil
    }
}
```

## Notification Patterns

### Scheduling
```swift
func scheduleNotification(for dose: ScheduledDose) async throws {
    let content = UNMutableNotificationContent()
    content.title = "Time for your dose"
    content.body = "\(dose.medication.brandName) - \(dose.amount)mg"
    content.sound = .default

    let trigger = UNCalendarNotificationTrigger(
        dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dose.scheduledTime),
        repeats: false
    )

    let request = UNNotificationRequest(identifier: dose.id.uuidString, content: content, trigger: trigger)
    try await notificationCenter.add(request)
}
```

### Deep Linking
```swift
// In notification action handler:
let url = URL(string: "jabtracker://dose/quick?medicationId=\(id)")
await UIApplication.shared.open(url)

// In DeeplinkHandler:
func handle(_ url: URL) {
    guard url.scheme == "jabtracker" else { return }
    switch url.host {
    case "dose":
        handleDoseDeeplink(url)
    default:
        break
    }
}
```

## Persistence Patterns

### UserDefaults for Settings
```swift
extension NotificationService {
    private enum Keys {
        static let notificationsEnabled = "notificationsEnabled"
        static let reminderMinutesBefore = "reminderMinutesBefore"
    }

    func saveState() {
        UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
        UserDefaults.standard.set(reminderMinutesBefore, forKey: Keys.reminderMinutesBefore)
    }

    func loadState() {
        notificationsEnabled = UserDefaults.standard.bool(forKey: Keys.notificationsEnabled)
        reminderMinutesBefore = UserDefaults.standard.integer(forKey: Keys.reminderMinutesBefore)
        if reminderMinutesBefore == 0 { reminderMinutesBefore = 60 }
    }
}
```

### When to Use What
- **SwiftData**: User-generated content, synced data, complex relationships
- **UserDefaults**: App preferences, device-specific settings, simple values

## Nutrition UI Patterns

### Bidirectional Macro Calculation
The FoodDetailSheet supports two input modes that preserve quantity when switching:

```swift
enum ServingInputMode {
    case quantity  // Enter amount in unit (g, oz, item, lb)
    case target    // Enter target macro (cal, P, F, C) → calculates quantity
}

// When toggling modes, capture values BEFORE changing mode
func toggleInputMode() {
    if inputMode == .quantity {
        // Capture BEFORE switching - scaledCalories uses quantityInGrams
        let currentCalories = scaledCalories
        inputMode = .target
        targetValue = currentCalories
    } else {
        let grams = calculateGramsFromTarget()
        inputMode = .quantity
        servingCount = quantityInSelectedUnit(from: grams)
    }
}

// When switching macros, preserve gram weight
func switchToMacro(_ macro: TargetMacro) {
    let currentGrams = calculateGramsFromTarget()
    targetMacro = macro
    targetValue = macroValueForGrams(currentGrams, macro: macro)
}
```

### Unit Conversion with Preservation
```swift
enum ServingUnit: String, CaseIterable {
    case grams = "g"
    case ounces = "oz"
    case item = "item"
    case pounds = "lb"

    func toGrams(_ value: Double, itemGrams: Double) -> Double {
        switch self {
        case .grams: return value
        case .ounces: return value * 28.3495
        case .item: return value * itemGrams
        case .pounds: return value * 453.592
        }
    }
}

// Preserve gram weight when switching units
func switchToUnit(_ unit: ServingUnit) {
    let currentGrams = quantityInGrams
    selectedUnit = unit
    servingCount = quantityInSelectedUnit(from: currentGrams)
}
```

### Serving Options Parsing
Parse database serving descriptions like `["100g", "1.0 item (291g)"]`:

```swift
struct ServingOption {
    let label: String   // "1 item"
    let grams: Double   // 291.0
}

// Regex pattern for "1.0 item (291g)" format
let pattern = #"^([\d.]+)\s+([^(]+)\s*\((\d+(?:\.\d+)?)\s*g\)$"#
if let match = try? NSRegularExpression(pattern: pattern)... {
    let quantity = Double(String(option[quantityRange]))
    let unit = String(option[unitRange]).trimmingCharacters(in: .whitespaces)
    let grams = Double(String(option[gramsRange]))
}
```

## Update History

- 2025-12-20T17:50:53Z: Added Nutrition UI Patterns (bidirectional macro calculation, unit conversion, serving options parsing)
- 2025-12-19T20:28:49Z: Added critical ModelContainer lifetime warning for SwiftData tests
- 2025-12-19T14:55:18Z: Initial context creation
