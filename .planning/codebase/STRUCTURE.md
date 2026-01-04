---
name: Codebase Structure
created: 2025-12-22
last_modified: 2026-01-04
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
- Source: Generated by `/gsd:*` commands
- Committed: Yes (planning artifacts)

---

*Structure analysis: 2026-01-04*
*Update when directory structure changes*
