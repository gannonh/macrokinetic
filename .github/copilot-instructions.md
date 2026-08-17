# JabTracker - AI Coding Agent Instructions

## Project Overview
iOS app for tracking GLP-1 medications, nutrition, and health metrics. SwiftUI + SwiftData with CloudKit sync.

## Architecture (MVVM + Services)
- **Views** (`JabTracker/Views/`): SwiftUI components, sheets, cards
- **ViewModels** (`JabTracker/ViewModels/`): `@Observable` classes coordinating services
- **Services** (`JabTracker/Services/`): Business logic - 28+ service files with extension-based organization (`ScheduleService+Projection.swift`)
- **Models** (`JabTracker/Models/`): SwiftData `@Model` entities (User, Dose, MedicationProfile, Food, FoodEntry)

Key singletons: `DataController.shared`, `AuthenticationManager`, `BiometricAuthManager.shared`

## Development Workflow

### Build & Test Commands
```bash
./scripts/build.sh                # Build on iPhone 17 Pro (default)
./scripts/test.sh unit            # Run unit tests
./scripts/test.sh ui              # Run UI tests
./scripts/test.sh unit --coverage # With coverage report
./scripts/test.sh ui FoodLogUITests/testMethod  # Single test
```
**Important:** Do NOT run build commands while user iterates - they need to run builds to see changes in the simulator.

### Simulator Requirements
Use the maintained iPhone 17 Pro iOS 26.5 simulator with Xcode 26.5.

## Key Code Patterns

### File Naming
- `*View.swift`, `*Sheet.swift`, `*Card.swift` - UI components
- `*Service.swift`, `*Manager.swift`, `*Engine.swift` - Business logic
- `*+Feature.swift` - Extensions (e.g., `ScheduleService+Titration.swift`)
- Tests: `{ClassName}Tests.swift`, `{Feature}UITests.swift`

### Service Extension Pattern
Large services split across multiple files:
- `ScheduleService.swift` (core) → `ScheduleService+Projection.swift`, `ScheduleService+Adherence.swift`
- `NotificationService.swift` → `NotificationService+Actions.swift`, `NotificationService+Reminders.swift`

### SwiftLint Configuration
Directory-level `.swiftlint.yml` files preferred over inline `// swiftlint:disable` comments. Check local configs in `JabTracker/`, `JabTracker/Views/`, `JabTracker/Services/`.

### Accessibility Identifiers (UI Testing)
All interactive elements need `.accessibilityIdentifier()` for E2E tests:
```swift
Button("Save") { ... }
    .accessibilityIdentifier("save-button")
```

## Testing Patterns

### UI Test Utilities (`JabTrackerUITests/Utils/TestUtilities.swift`)
```swift
// Launch with mock data
let app = TestUtilities.launchAppWithTestMode()
let app = TestUtilities.launchAppWithSeededData(preset: .thirtyDays)

// Navigation helpers
TestUtilities.navigateToHistoryView(in: app)
TestUtilities.navigateToAdherence(app)

// Debugging failed tests
TestUtilities.debugScreenshot(app, name: "before-failure")
TestUtilities.debugElements(in: app, containing: "button")
```

### E2E Test Debugging (MANDATORY)
When UI tests fail, capture evidence BEFORE changing code:
```swift
// 1. Add before failing assertion
TestUtilities.debugScreenshot(app, name: "before-failure")
print(app.debugDescription)

// 2. Run test and examine
./scripts/test.sh ui YourTestClass/testMethod
open logs/latest/screenshots/
```

## Domain-Specific Knowledge

### Pharmacokinetics Engine
`PharmacokineticsEngine.swift` calculates drug concentration using exponential decay. Medication parameters in `Medication.swift` include `halfLifeDays`, `peakTimeHours`, `subcutaneousBioavailability`.

### Food Database
1.7M+ foods via bundled SQLite (`usda_foods.sqlite`) with FTS5 search. `LocalFoodDatabase.swift` is an actor for thread-safe SQLite access. `FoodService.swift` orchestrates local DB + API results.

### Authentication
`AuthenticationManager` handles Sign in with Apple. UI testing mode (`--ui-testing` flag) bypasses real auth with mock data.

### CloudKit Sync
SwiftData models sync automatically via `DataController.container`. Test CloudKit with `TestUtilities.launchAppWithCloudKitTestMode()`.

## Project Generation
Uses XcodeGen (`project.yml`) - regenerate project with `xcodegen generate` after modifying project structure.
