---
created: 2025-12-19T14:51:30Z
last_updated: 2025-12-20T17:50:53Z
---

# Technology Context

## Core Stack

| Layer | Technology |
|-------|------------|
| Platform | iOS 17.0+ |
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Data Persistence | SwiftData |
| Cloud Sync | CloudKit |
| Authentication | Sign in with Apple |
| Charts | Swift Charts |

## Build System

- **Project Generation**: XcodeGen (`project.yml`)
- **IDE**: Xcode 16.4+
- **Code Quality**: SwiftLint
- **Code Formatting**: SwiftFormat
- **Build Output**: xcbeautify

### XcodeGen Workflow

After adding new Swift files, always regenerate the project:

```bash
xcodegen generate
```

## Key Dependencies

### Apple Frameworks
- **SwiftUI** - Declarative UI with NavigationStack architecture
- **SwiftData** - Modern persistence with @Model macro
- **CloudKit** - iCloud sync for cross-device data
- **HealthKit** - Weight and health data integration
- **UserNotifications** - Scheduled reminders and alerts
- **LocalAuthentication** - Face ID/Touch ID
- **StoreKit 2** - Subscription management
- **Swift Charts** - Data visualization

### No External Dependencies
The project uses only Apple frameworks - no SPM packages or CocoaPods.

## Architecture

### MVVM Pattern
```
View (SwiftUI) → ViewModel (@Observable) → Service → Model (SwiftData)
```

### Observable Pattern (iOS 17+)
New ViewModels use `@Observable` macro:
```swift
@Observable
class ViewModel {
    var state: State = .initial
}

// In View:
@State private var viewModel = ViewModel()
```

### Service Layer
Services are `@Observable` classes injected via `AppServices` coordinator:
```swift
@MainActor
final class AppServices: ObservableObject {
    static let shared = AppServices()
    private(set) var scheduleService: ScheduleService?
    private(set) var notificationService: NotificationService?

    func initialize(with modelContext: ModelContext) { ... }
}
```

## SwiftData Models

### Core Entities
- **User** - Profile with email, name, weight
- **MedicationProfile** - Medication settings and dose configuration
- **Dose** - Individual dose records with timestamp, amount, site
- **DoseSchedule** - Schedule configuration (weekly, split-dose, custom)
- **ScheduledDose** - Generated upcoming dose instances
- **DoseTitration** - Dose escalation tracking

### CloudKit Compatibility
- All fields have non-optional defaults
- Relationships use `@Relationship(inverse:)` on parent side only
- Child entities use plain properties (no `@Relationship`)

```swift
// Parent
@Model
final class User {
    @Relationship(deleteRule: .cascade, inverse: \Dose.user)
    var doses: [Dose]?
}

// Child - NO @Relationship attribute
@Model
final class Dose {
    var user: User?  // Plain property
}
```

## Key Services

### PharmacokineticsEngine
Calculates drug concentration using exponential decay:
- Current, peak, trough levels
- Half-life based on medication type
- Steady-state progress percentage

### ScheduleService
Manages dose scheduling:
- `+Projection` - Generate upcoming doses
- `+Modifications` - Edit schedules
- `+Adherence` - Track compliance
- `+Titration` - Dose escalation

### NotificationService
Handles reminders:
- `+Actions` - Notification response handling
- `+Background` - Badge and refresh
- `+Persistence` - UserDefaults storage

### ChartDataProcessor
Transforms data for Swift Charts:
- `+Filtering` - Data aggregation
- `+Interpolation` - Curve smoothing

### LocalFoodDatabase
SQLite FTS5 database with 1.7M+ foods:
- Bundled offline database (~382 MB)
- Full-text search via FTS5
- Barcode lookup support
- USDA Foundation/SR Legacy + Open Food Facts data

### FoodService
Orchestrates food search across sources:
- Local database first (instant, offline)
- Open Food Facts API fallback
- Categorizes results by source (history, custom, common, branded)
- Recent foods tracking

### MealLogService
Manages food entry CRUD:
- Log food with serving size and meal section
- Daily totals calculation
- Macro aggregation

## Testing Stack

- **Unit Tests**: Swift Testing framework (`@Test`, `#expect`)
- **UI Tests**: XCUITest
- **Output Formatter**: xcbeautify
- **Coverage**: 5-tier policy (90% for business logic)

See `testing.md` for detailed testing patterns.

## Environment & Launch Arguments

### Authentication Bypass (Development)
```swift
// In project.yml run scheme:
"--ui-testing": true  // Bypasses Sign in with Apple
```

### Test Data Seeding
```swift
"--seed-test-7d": true   // 7 days of test data
"--seed-test-30d": true  // 30 days
"--seed-test-90d": true  // 90 days
"--seed-test-1y": true   // 1 year
```

### Other Flags
```swift
"--reset-app-data": true     // Clear all data on launch
"--force-onboarding": true   // Show onboarding flow
"--bypass-onboarding": true  // Skip onboarding
```

## Performance Targets

- App launch: < 2 seconds
- Calculation updates: < 50ms
- Memory usage: < 100MB
- Chart rendering (365 doses): < 500ms

## Medical Domain Notes

### Supported Medications
| Generic | Brands | Typical Schedule |
|---------|--------|------------------|
| Semaglutide | Ozempic, Wegovy, Rybelsus | Weekly |
| Tirzepatide | Mounjaro, Zepbound | Weekly |
| Liraglutide | Victoza, Saxenda | Daily |
| Dulaglutide | Trulicity | Weekly |

### Pharmacokinetics
- Half-life varies by medication (e.g., ~7 days for semaglutide)
- Concentration modeled with exponential decay
- Therapeutic range tracking for effectiveness

## Update History

- 2025-12-20T17:50:53Z: Added nutrition services (LocalFoodDatabase, FoodService, MealLogService)
- 2025-12-19T14:51:30Z: Initial context creation
