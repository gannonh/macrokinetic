---
created: 2025-09-11T16:54:56Z
last_updated: 2025-09-11T16:54:56Z
version: 1.0
author: Claude Code PM System
---

# Project Style Guide

## Code Style Standards

### Swift Coding Conventions

#### Naming Conventions
```swift
// Classes and Structs: PascalCase
class AuthenticationManager: ObservableObject
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
    @StateObject private var authManager = AuthenticationManager()
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

### SwiftUI Patterns

#### View Structure
```swift
struct MedicationListView: View {
    // Properties first (StateObject, State, Binding, Environment)
    @StateObject private var medicationManager = MedicationManager()
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

## Testing Standards

### Test Organization
```swift
// Test class naming: SourceClassNameTests
final class AuthenticationManagerTests {
    
    // Setup and teardown
    override func setUpWithError() throws {
        // Test setup
    }
    
    // Test method naming: test + WhatIsBeingTested + ExpectedOutcome
    func testSignInWithApple_ValidCredentials_CreatesUser() throws {
        // Given
        let expectedEmail = "test@example.com"
        
        // When
        let result = authManager.signInWithApple(email: expectedEmail)
        
        // Then
        XCTAssertEqual(result.email, expectedEmail)
    }
}
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
class MedicationManager: ObservableObject {
    weak var delegate: MedicationManagerDelegate?
    
    // Proper async/await usage
    @MainActor
    func updateUI() async {
        // UI updates on main actor
    }
}
```