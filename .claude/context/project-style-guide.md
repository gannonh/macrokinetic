---
created: 2025-09-11T16:54:56Z
last_updated: 2025-09-11T20:59:06Z
version: 1.0
author: Claude Code PM System
---

# Project Style Guide

## Code Style Standards

### Swift Coding Conventions

#### Naming Conventions
```swift
// Classes and Structs: PascalCase
@Observable class AuthenticationManager  // New pattern (iOS 17+)
class LegacyViewModel: ObservableObject  // Legacy pattern (being migrated)
struct MedicationProfile

// Variables and Functions: camelCase
var currentUser: User?
func calculateConcentration() -> Double

// Constants: camelCase
let defaultDoseAmount = 1.0
static let maxRetryAttempts = 3

// Enums: PascalCase with camelCase cases
enum OnboardingStep {
    case welcome
    case medicationSelection
    case doseEntry
}
```

#### File Organization
```swift
// MARK: - Imports (grouped and sorted)
import SwiftUI
import SwiftData
import HealthKit

// MARK: - Type Definition
struct ContentView: View {
    
    // MARK: - Properties
    @State private var authManager = AuthenticationManager()  // For @Observable classes
    @StateObject private var legacyVM = LegacyViewModel()    // For ObservableObject classes
    @State private var showingSettings = false
    
    // MARK: - Body
    var body: some View {
        // Implementation
    }
    
    // MARK: - Private Methods
    private func handleAuthentication() {
        // Implementation
    }
}
```

### Observable Pattern (iOS 17+ - Preferred for New Code)

#### @Observable Classes
```swift
// ✅ CORRECT: Modern @Observable pattern
@Observable
class PharmacokineticsEngine {
    var concentration: Double = 0.0  // All properties automatically observable
    var lastCalculation: Date?

    func recalculate() {
        // No need for @Published
    }
}

// In View:
@State private var pkEngine = PharmacokineticsEngine()
```

#### Legacy ObservableObject Pattern (Being Migrated - Issue #51)
```swift
// ⚠️ LEGACY: Still in use but being migrated
class DoseHistoryViewModel: ObservableObject {
    @Published var doses: [Dose] = []
    @Published var isLoading = false
}

// In View:
@StateObject private var viewModel = DoseHistoryViewModel()
```

#### Property Wrapper Usage Guide
- **@State**: Use for value types AND @Observable classes
- **@StateObject**: Use for ObservableObject classes (view owns the object)
- **@ObservedObject**: Use for ObservableObject classes (object passed in)
- **@Bindable**: Use for two-way binding with @Observable classes

### SwiftUI Patterns

#### View Structure
```swift
struct MedicationListView: View {
    // Properties first (State for @Observable, StateObject for ObservableObject)
    @State private var medicationManager = MedicationManager()  // If using @Observable
    @StateObject private var legacyManager = LegacyManager()   // If using ObservableObject
    @State private var showingAddView = false
    
    var body: some View {
        NavigationStack {
            List {
                // Content
            }
            .navigationTitle("Medications")
            .toolbar {
                // Toolbar items
            }
        }
    }
}
```

#### Accessibility Integration
```swift
Button("Add Medication") {
    showingAddView = true
}
.accessibilityIdentifier("add-medication-button")
.accessibilityLabel("Add new medication profile")
.accessibilityHint("Opens medication creation form")
```

### SwiftData Model Conventions

#### Model Structure
```swift
@Model
final class MedicationProfile {
    var id: UUID = UUID()
    var genericName: String = ""
    var brandName: String = ""
    var currentDose: Double = 0.0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Dose.medicationProfile)
    var doses: [Dose] = []

    init(genericName: String, brandName: String, currentDose: Double) {
        self.genericName = genericName
        self.brandName = brandName
        self.currentDose = currentDose
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

### SwiftData + CloudKit Relationship Patterns

#### The One-Side Rule
- **ONLY the parent/owning side** should have `@Relationship` attributes
- **Child/referenced side** uses plain properties (no `@Relationship`)
- **CloudKit requires explicit inverse specification** in the parent's `@Relationship`
- **Never add `@Relationship` to both sides** - this creates circular references that break SwiftData

#### Correct Pattern Example:
```swift
// ✅ CORRECT: Parent (User) - HAS @Relationship with inverse
@Model
final class User {
    @Relationship(deleteRule: .cascade, inverse: \Dose.user)
    var doses: [Dose]?

    @Relationship(deleteRule: .cascade, inverse: \MedicationProfile.user)
    var medicationProfiles: [MedicationProfile]?
}

// ✅ CORRECT: Child (Dose) - Plain property, NO @Relationship
@Model
final class Dose {
    var user: User?  // Plain property - NO @Relationship attribute
    var medication: MedicationProfile?  // Plain property - NO @Relationship attribute
}

// ✅ CORRECT: Another Parent (MedicationProfile) with its own children
@Model
final class MedicationProfile {
    var user: User?  // Plain property - this is a child reference

    @Relationship(deleteRule: .cascade, inverse: \Dose.medication)
    var doses: [Dose]?  // Parent relationship to Doses
}
```

#### Common Mistakes to Avoid:
```swift
// ❌ WRONG: Adding @Relationship to both sides creates circular references
@Model
final class Dose {
    @Relationship(inverse: \User.doses)  // ❌ Don't do this!
    var user: User?
}
```

#### Testing Pattern for SwiftData Relationships:
```swift
// Tests must disable CloudKit to avoid relationship validation errors
let schema = Schema([User.self, Dose.self, MedicationProfile.self])
let config = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: true,
    cloudKitDatabase: .none  // Critical: Disable CloudKit for tests
)
let container = try ModelContainer(for: schema, configurations: [config])
```

## Testing Standards

> **For comprehensive E2E testing patterns, element targeting best practices, iterative development process, and debug-first approaches**, see `.claude/context/testing-config.md`

### Key Testing Style Points
- **SwiftUI → Accessibility Mapping**: List renders as CollectionView, NavigationStack renders as CollectionView in XCUITest
- **Debug-First Approach**: Always use `TestUtilities.debugElements()` before writing element selectors
- **XCUIElementQuery**: Use `.count` property (not `.isEmpty` which doesn't exist)
- **Iterative E2E Development**: Implement one test at a time, run individually, commit before moving on

### Swift Testing Framework Patterns

#### Test Organization and Naming
```swift
// Use @Test attribute with descriptive names
@Test("Calculate next scheduled dose for weekly medication")
@MainActor
func testGetNextScheduledDoseTimeWeekly() async {
    let context = createTestContext()
    let profile = createTestMedicationProfile(
        context: context,
        genericName: "semaglutide"
    )
    
    // Add a dose from 1 week ago
    _ = createTestDose(context: context, medication: profile)
    
    let viewModel = QuickDoseViewModel()
    viewModel.selectedMedicationProfile = profile
    
    let nextDoseTime = viewModel.getNextScheduledDoseTime()
    
    // Use #expect for modern assertions
    #expect(nextDoseTime != nil, "Expected getNextScheduledDoseTime() to return a non-nil value")
    
    // Safe unwrapping to avoid crashes
    guard let nextDoseTime = nextDoseTime else {
        #expect(Bool(false), "nextDoseTime was nil when it shouldn't be")
        return
    }
    
    // Verify timing with tolerance
    let timeDifference = abs(nextDoseTime.timeIntervalSinceNow)
    #expect(timeDifference < 24 * 60 * 60, "Time difference should be within 24 hours")
}
```

#### Async Testing Best Practices
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

#### Safe Unwrapping Patterns in Tests
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

#### Tolerance-Based Assertions for Time/Dates
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

### Test Data Patterns
```swift
// Test data factories for consistency
extension User {
    static func testUser(
        email: String = "test@example.com",
        name: String? = "Test User",
        weight: Double = 70.0
    ) -> User {
        User(email: email, name: name, weight: weight)
    }
}

// Context creation helpers
func createTestContext() -> ModelContext {
    let schema = Schema([User.self, MedicationProfile.self, Dose.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return ModelContext(container)
}
```

### Modern Swift Testing vs XCTest Migration
```swift
// ✅ Swift Testing - Modern, cleaner syntax
@Test("User creation with valid data")
func testUserCreation() {
    let user = User(email: "test@example.com", name: "Test User")
    #expect(user.email == "test@example.com")
    #expect(user.name == "Test User")
}

// ❌ XCTest - Legacy syntax (avoid in new tests)
func testUserCreation() throws {
    let user = User(email: "test@example.com", name: "Test User")
    XCTAssertEqual(user.email, "test@example.com")
    XCTAssertEqual(user.name, "Test User")
}
```

## Documentation Standards

### Code Documentation
```swift
/**
 * Calculates the current drug concentration based on dose history and pharmacokinetic parameters.
 * 
 * Uses exponential decay modeling with medication-specific half-life values to determine
 * the remaining concentration at a given time point.
 * 
 * - Parameters:
 *   - doses: Array of historical doses with timestamps and amounts
 *   - medication: Medication type containing half-life and other PK parameters
 *   - date: Date at which to calculate concentration (defaults to current time)
 * 
 * - Returns: Concentration value in arbitrary units (typically ng/mL equivalent)
 * 
 * - Note: This calculation assumes first-order elimination kinetics
 * - Warning: Results should not be used for clinical decision-making
 */
func calculateConcentration(doses: [Dose], medication: Medication, at date: Date = Date()) -> Double {
    // Implementation
}
```

### README and Markdown Style
```markdown
# Section Headers (H1 for main sections)

## Subsections (H2 for major topics)

### Details (H3 for specific items)

- Bullet points for lists
- **Bold** for emphasis
- `Code snippets` for technical terms
- [Links](url) for references

```swift
// Code blocks with language specification
func example() {
    print("Hello, World!")
}
```

## File Naming Conventions

### Source Files
- **Swift Files**: PascalCase matching the primary type
  - `AuthenticationManager.swift`
  - `MedicationProfile.swift`
  - `DashboardView.swift`

- **Test Files**: Source name + "Tests"
  - `AuthenticationManagerTests.swift`
  - `MedicationProfileTests.swift`

### Documentation Files
- **Markdown Files**: kebab-case for readability
  - `implementation-plan.md`
  - `spec-master-prd.md`
  - `coverage-analysis.md`

- **Configuration Files**: Standard naming
  - `project.yml` (XcodeGen)
  - `.swiftlint.yml` (SwiftLint config)
  - `Package.swift` (Swift Package Manager)

## Comment Style

### Code Comments
```swift
// MARK: - Section headers for organization

// Single line comments for brief explanations
let maxDosage = 2.4 // Maximum semaglutide dose in mg

/*
 * Multi-line comments for detailed explanations
 * when single line is insufficient
 */

// TODO: Implement dose escalation warnings
// FIXME: Handle edge case when dose is zero
// NOTE: This follows FDA guidance for GLP-1 medications
```

### Absolute Rules Adherence

#### NO PARTIAL IMPLEMENTATION
```swift
// ❌ Wrong
func calculateDose() -> Double {
    // TODO: Implement actual calculation
    return 1.0
}

// ✅ Correct  
func calculateDose(currentDose: Double, escalationWeeks: Int) -> Double {
    let escalationFactor = Double(escalationWeeks) * 0.25
    return min(currentDose + escalationFactor, 2.4)
}
```

#### NO CODE DUPLICATION
```swift
// ❌ Wrong - duplicated validation logic
func validateSemaglutideDose(_ dose: Double) -> Bool {
    return dose >= 0.25 && dose <= 2.4
}

func validateTirzepatideDose(_ dose: Double) -> Bool {
    return dose >= 2.5 && dose <= 15.0
}

// ✅ Correct - reusable validation
func validateDose(_ dose: Double, for medication: Medication) -> Bool {
    let range = medication.doseRange
    return dose >= range.lowerBound && dose <= range.upperBound
}
```

#### CONSISTENT NAMING
```swift
// ✅ Consistent naming patterns
protocol MedicationManaging {
    func createMedication() -> MedicationProfile
    func updateMedication(_ profile: MedicationProfile)
    func deleteMedication(_ profile: MedicationProfile)
}

class AuthenticationManager: AuthenticationManaging {
    func signIn() async throws -> User
    func signOut() async throws
    func checkAuthStatus() async -> Bool
}
```

## Error Handling Patterns

### Error Types
```swift
enum MedicationError: LocalizedError {
    case invalidDose(Double)
    case unsupportedMedication(String)
    case calculationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidDose(let dose):
            return "Invalid dose amount: \(dose)mg"
        case .unsupportedMedication(let name):
            return "Unsupported medication: \(name)"
        case .calculationFailed:
            return "Pharmacokinetic calculation failed"
        }
    }
}
```

### Error Handling
```swift
// Graceful error handling with user-friendly messages
func calculateConcentration() async throws -> Double {
    do {
        let result = try performCalculation()
        return result
    } catch MedicationError.invalidDose(let dose) {
        logger.error("Invalid dose: \(dose)")
        throw MedicationError.invalidDose(dose)
    } catch {
        logger.error("Unexpected calculation error: \(error)")
        throw MedicationError.calculationFailed
    }
}
```

## Performance Guidelines

### SwiftData Best Practices
```swift
// Use @Relationship properly with inverse
@Relationship(deleteRule: .cascade, inverse: \Dose.medicationProfile)
var doses: [Dose] = []

// Efficient queries with predicates
#Predicate<Dose> { dose in
    dose.timestamp > startDate && dose.timestamp < endDate
}
```

### Memory Management
```swift
// Use weak references to prevent retain cycles
@Observable class MedicationManager {  // Preferred pattern
    weak var delegate: MedicationManagerDelegate?
    
    // Proper async/await usage
    @MainActor
    func updateUI() async {
        // UI updates on main actor
    }
}
```