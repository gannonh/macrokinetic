---
created: 2025-12-19T14:56:14Z
last_updated: 2025-12-19T14:56:14Z
---

# Project Style Guide

## Naming Conventions

### Files
| Type | Convention | Example |
|------|------------|---------|
| Views | `*View.swift` | `DashboardView.swift` |
| ViewModels | `*ViewModel.swift` | `AnalyticsViewModel.swift` |
| Services | `*Service.swift` or `*Manager.swift` | `NotificationService.swift` |
| Models | Singular noun | `Dose.swift`, `User.swift` |
| Extensions | `Type+Feature.swift` | `Medication+Pharmacokinetics.swift` |
| Tests | `*Tests.swift` | `ScheduleServiceTests.swift` |

### Swift Code
```swift
// Classes/Structs/Enums: PascalCase
class AuthenticationManager { }
struct MedicationProfile { }
enum OnboardingStep { }

// Variables/Functions: camelCase
var currentUser: User?
func calculateConcentration() -> Double { }

// Constants: camelCase
let defaultDoseAmount = 1.0
static let maxRetryAttempts = 3

// Enum cases: camelCase
enum Tab {
    case dashboard
    case history
    case analytics
}
```

## Code Organization

### File Structure
```swift
import SwiftUI
import SwiftData

// MARK: - Type Definition
struct ContentView: View {

    // MARK: - Properties
    @State private var viewModel = ViewModel()
    @State private var showingSheet = false

    // MARK: - Body
    var body: some View {
        // ...
    }

    // MARK: - Private Methods
    private func handleAction() {
        // ...
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
```

### Property Order in Views
1. Environment properties (`@Environment`, `@EnvironmentObject`)
2. State properties (`@State`, `@StateObject`, `@ObservedObject`)
3. Bindings (`@Binding`)
4. Regular properties
5. Computed properties

## SwiftUI Patterns

### View Composition
```swift
// Break down complex views into smaller components
var body: some View {
    VStack {
        headerSection
        contentSection
        footerSection
    }
}

private var headerSection: some View {
    // ...
}
```

### Accessibility
```swift
Button("Add Dose") { }
    .accessibilityIdentifier("add-dose-button")
    .accessibilityLabel("Add new dose")
    .accessibilityHint("Opens dose entry form")
```

### Modifiers Order
```swift
Text("Hello")
    .font(.headline)           // Appearance first
    .foregroundColor(.primary)
    .padding()                 // Layout
    .background(.secondary)    // Background
    .cornerRadius(8)           // Shape
    .accessibilityLabel("...")  // Accessibility last
```

## Documentation

### File Headers
```swift
//
//  ScheduleService.swift
//  JabTracker
//
//  Created by [Author] on [Date].
//
```

### Function Documentation
```swift
/// Calculates the current drug concentration based on dose history.
///
/// Uses exponential decay modeling with medication-specific half-life values.
///
/// - Parameters:
///   - doses: Array of historical doses
///   - medication: Medication type with PK parameters
///   - date: Date at which to calculate (defaults to now)
/// - Returns: Concentration value in ng/mL equivalent
/// - Note: Assumes first-order elimination kinetics
func calculateConcentration(
    doses: [Dose],
    medication: Medication,
    at date: Date = Date()
) -> Double {
    // ...
}
```

## Error Handling

### Custom Errors
```swift
enum ScheduleServiceError: LocalizedError {
    case invalidSchedule
    case scheduleNotFound
    case contextError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidSchedule:
            return "Invalid schedule configuration"
        case .scheduleNotFound:
            return "Schedule not found"
        case .contextError(let error):
            return "Database error: \(error.localizedDescription)"
        }
    }
}
```

### Try-Catch Pattern
```swift
func saveDose() async {
    do {
        try await doseService.save(dose)
    } catch {
        errorMessage = error.localizedDescription
        showError = true
    }
}
```

## Logging

### Use OSLog
```swift
import os

private let logger = Logger(
    subsystem: "com.gannonhall.JabTracker",
    category: "ScheduleService"
)

func createSchedule() {
    logger.debug("Creating schedule with parameters: \(parameters)")
    // ...
    logger.info("Schedule created successfully: \(schedule.id)")
}
```

### Log Levels
- `debug` - Development debugging
- `info` - Normal operations
- `notice` - Important but normal
- `warning` - Potential issues
- `error` - Recoverable errors
- `fault` - Critical failures

## SwiftLint Rules

Key rules enforced:
- `line_length: 120` - Maximum line length
- `type_body_length: 300` - Maximum type body
- `function_body_length: 50` - Maximum function body
- `force_unwrapping: error` - No force unwrapping
- `force_cast: error` - No force casting

### Disabling Rules
```swift
// Disable for specific line
// swiftlint:disable:next force_unwrapping
let value = optional!

// Disable for block (avoid)
// swiftlint:disable force_unwrapping
// ... code ...
// swiftlint:enable force_unwrapping
```

## Git Conventions

### Branch Naming
```
issue/123-feature-description
fix/456-bug-description
```

### Commit Messages
```
feat: Add dose scheduling notifications
fix: Resolve calendar date selection bug
test: Add ScheduleService unit tests
docs: Update API documentation
refactor: Extract dose validation logic
```

Format: `type: Brief description`

Types:
- `feat` - New feature
- `fix` - Bug fix
- `test` - Adding/fixing tests
- `docs` - Documentation
- `refactor` - Code restructuring
- `chore` - Maintenance tasks

## Testing Style

### Swift Testing Framework
```swift
import Testing
@testable import JabTracker

@Test("Calculate concentration for single dose")
@MainActor
func testSingleDoseConcentration() async {
    let engine = PharmacokineticsEngine()
    let dose = Dose(amount: 1.0)

    let concentration = engine.calculateConcentration(doses: [dose])

    #expect(concentration > 0)
    #expect(concentration < 2.0)
}
```

### Test Naming
```swift
// Pattern: test[Feature][Scenario][ExpectedResult]
@Test("Get upcoming doses returns empty for no schedule")
func testGetUpcomingDosesEmptyForNoSchedule() { }

@Test("Save dose updates concentration calculation")
func testSaveDoseUpdatesConcentration() { }
```

## Code Quality Rules

### No Force Unwrapping
```swift
// Bad
let user = users.first!

// Good
guard let user = users.first else {
    logger.warning("No users found")
    return
}
```

### No Magic Numbers
```swift
// Bad
if doses.count > 7 { }

// Good
private let weeklyDoseCount = 7
if doses.count > weeklyDoseCount { }
```

### Prefer Guard for Early Exit
```swift
func processUser(_ user: User?) {
    guard let user = user else {
        logger.debug("No user provided")
        return
    }

    // Main logic with unwrapped user
}
```

## Update History

- 2025-12-19T14:56:14Z: Initial context creation
