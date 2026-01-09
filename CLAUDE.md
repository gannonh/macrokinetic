<!-- AUTO-MANAGED: project-description -->
## Overview

**JabTracker** - iOS app for tracking GLP-1 medication doses, nutrition, and health metrics.

- SwiftUI + SwiftData with CloudKit sync
- Pharmacokinetics engine for concentration tracking
- Food logging with 1.7M+ foods (USDA + Open Food Facts)
- Analytics, adherence tracking, and progress photos

<!-- END AUTO-MANAGED -->

<!-- AUTO-MANAGED: build-commands -->
## Build & Development Commands

```bash
# Generate Xcode project (required after project.yml changes)
xcodegen generate

# Build (do NOT run during iteration - user runs build to see changes)
./scripts/build.sh

# Run all checks (lint + tests + coverage)
./scripts/check-all.sh

# Unit tests
./scripts/test.sh unit 1                              # All unit tests
./scripts/test.sh unit 1 FoodServiceTests             # Single class
./scripts/test.sh unit 1 --coverage                   # With coverage

# Test Coverage
./scripts/check-coverage.sh                           # Check policy
./scripts/coverage-detail.sh                          # Detailed report

# JSON-based queries for programmatic coverage analysis
./scripts/coverage-json.sh --summary            # File overview sorted by %
./scripts/coverage-json.sh --functions          # Show uncovered functions only
./scripts/coverage-json.sh DateNightService     # JSON for specific file

# UI/E2E tests
./scripts/test.sh ui 1 NutritionFlowUITests           # Test class
./scripts/test.sh ui 1 OnboardingUITests/testComplete # Single method

# Linting
swiftlint                                             # Check
swiftlint --fix                                       # Auto-fix
```

<!-- END AUTO-MANAGED -->

<!-- AUTO-MANAGED: architecture -->
## Architecture

**Pattern**: MVVM with Service Layer

```
JabTracker/
├── App/           # Entry point, AppServices coordinator
├── Models/        # SwiftData @Model entities (37 files)
├── Services/      # Business logic layer (42 files)
├── ViewModels/    # @Observable view state
├── Views/         # SwiftUI views (119 files)
│   ├── Analytics/     Dashboard/      DoseEntry/
│   ├── FoodLog/       History/        MedicationProfile/
│   ├── Nutrition/     Settings/       Strategy/
│   └── Components/    Shortcuts/      Weight/
├── Design/        # Design tokens, colors, components
├── Onboarding/    # First-run flow
└── Utilities/     # Validation, constants
```

**Key Services**: `ScheduleService`, `FoodService`, `PharmacokineticsEngine`, `NotificationService`, `MedicationManager`

**Data Flow**: Views → ViewModels → Services → SwiftData → CloudKit

<!-- END AUTO-MANAGED -->

<!-- AUTO-MANAGED: conventions -->
## Code Conventions

**Naming**:
- Files: `*View.swift`, `*ViewModel.swift`, `*Service.swift`, `Type+Feature.swift`
- Functions/Variables: camelCase
- Types: PascalCase

**SwiftUI Views**:
1. Properties (`let`, `@Environment`, `@State`)
2. Computed properties
3. `body`
4. Private computed views
5. Private methods

**SwiftData**:
- All properties have default values (CloudKit compatibility)
- Parent: `@Relationship(inverse:)`, Child: plain property
- Relationships are optional arrays

**Testing**:
- Swift Testing: `@Test`, `#expect()`, `#require()`
- XCUITest: `XCTAssert*`, accessibility identifiers
- Always keep ModelContainer alive when testing SwiftData

<!-- END AUTO-MANAGED -->

<!-- AUTO-MANAGED: patterns -->
## Detected Patterns

**Service Extensions**: Split large services into domain-focused extensions
- `ScheduleService.swift` + `ScheduleService+Projection.swift` + `ScheduleService+Adherence.swift`

**Observable ViewModels**: iOS 17+ `@Observable` macro
```swift
@Observable class ViewModel { var state: State = .initial }
// In view: @State private var viewModel = ViewModel()
```

**Singleton Coordinator**: `AppServices.shared` manages service lifecycle

**Logging**: OSLog with category-specific loggers
```swift
private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "ServiceName")
```

<!-- END AUTO-MANAGED -->

<!-- MANUAL -->

## Essential Context

### Codebase Conventions & Structure

1. Technical stack: @.planning/codebase/STACK.md
2. Architecture: @.planning/codebase/ARCHITECTURE.md
3. Project structure: @.planning/codebase/STRUCTURE.md
4. Coding conventions: @.planning/codebase/CONVENTIONS.md
5. Testing: @.planning/codebase/TESTING.md
6. Integrations: @.planning/codebase/INTEGRATIONS.md
7. Known concerns: @.planning/codebase/CONCERNS.md

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

<!-- END MANUAL -->
