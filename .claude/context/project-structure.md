---
created: 2025-12-19T14:52:17Z
last_updated: 2025-12-20T17:50:53Z
---

# Project Structure

## Root Directory

```
jab-tracker-ios/
├── .claude/                    # Claude Code configuration
│   ├── agents/                 # Specialized agent definitions
│   ├── commands/               # Slash command implementations
│   │   ├── context/            # Context management commands
│   │   ├── dev/                # Development workflow commands
│   │   ├── devops/             # Deployment commands
│   │   ├── qa/                 # Quality assurance commands
│   │   └── audit/              # Audit commands
│   ├── context/                # Project context documentation
│   ├── rules/                  # Development rules and guidelines
│   ├── scripts/                # Automation scripts
│   └── skills/                 # Skill definitions
│       ├── ios-dev/            # iOS development patterns
│       ├── ios-e2e-testing/    # E2E testing patterns
│       ├── ios-unit-testing/   # Unit testing patterns
│       └── macos-dev/          # macOS development patterns
├── JabTracker/                 # Main application source
├── JabTrackerTests/            # Unit tests (144 files)
├── JabTrackerUITests/          # UI/E2E tests (60 files)
├── scripts/                    # Build and test scripts
├── logs/                       # Test output logs
├── project.yml                 # XcodeGen configuration
├── CLAUDE.md                   # Claude Code instructions
└── .swiftlint.yml              # SwiftLint configuration
```

## Source Code (JabTracker/)

```
JabTracker/
├── App/
│   ├── JabTrackerApp.swift     # App entry point (@main)
│   ├── AppServices.swift       # Service coordinator/DI
│   └── DeeplinkHandler.swift   # URL scheme handling
├── Models/                     # SwiftData entities
│   ├── User.swift
│   ├── Dose.swift
│   ├── MedicationProfile.swift
│   ├── DoseSchedule.swift
│   ├── ScheduledDose.swift
│   ├── DoseTitration.swift
│   ├── DoseEvent.swift
│   ├── Medication.swift
│   ├── Medication+Pharmacokinetics.swift
│   ├── PendingNotification.swift
│   ├── ChartData.swift
│   ├── ChartDataTypes.swift
│   ├── ChartDataEnums.swift
│   ├── AdherenceStatistics.swift
│   ├── AdherenceInsight.swift
│   ├── AdherencePattern.swift
│   ├── AdherenceTrendData.swift
│   ├── ConcentrationPoint.swift
│   ├── Food.swift              # Nutrition: Food entity
│   ├── FoodEntry.swift         # Nutrition: Logged food entry
│   ├── FoodSource.swift        # Nutrition: Data source enum
│   ├── MealSection.swift       # Nutrition: Meal category enum
│   └── Tab.swift               # Navigation: Type-safe tab enum
├── Views/
│   ├── Analytics/              # Charts and insights views
│   ├── Dashboard/              # Main dashboard components
│   ├── DoseEntry/              # Dose logging UI
│   ├── FoodLog/                # Today's meals view
│   │   └── FoodLogView.swift
│   ├── History/                # Calendar and list views
│   ├── MedicationProfile/      # Profile management
│   ├── More/                   # Overflow menu
│   │   └── MoreView.swift
│   ├── Nutrition/              # Food search and logging
│   │   ├── AddFoodSheet.swift
│   │   ├── FoodDetailSheet.swift
│   │   ├── FoodDetailSheet+InputSection.swift
│   │   ├── FoodSearchSheet.swift
│   │   ├── FoodSearchSheet+Sections.swift
│   │   ├── FoodSearchView.swift
│   │   ├── MealLogView.swift
│   │   ├── NutritionSummaryCard.swift
│   │   ├── SearchMethodTabs.swift
│   │   └── ServingInputView.swift
│   ├── Settings/               # Settings and preferences
│   ├── Shortcuts/              # Quick action buttons
│   │   ├── ShortcutButton.swift
│   │   ├── ShortcutRowButton.swift
│   │   └── ShortcutsSheet.swift
│   ├── Shots/                  # Combined analytics/history
│   │   └── ShotsView.swift
│   ├── Components/             # Reusable UI components
│   ├── AuthenticationView.swift
│   ├── SplashView.swift
│   └── UserProfileView.swift
├── ViewModels/
│   ├── AnalyticsViewModel.swift
│   ├── DoseCalendarViewModel.swift
│   ├── DoseHistoryViewModel.swift
│   └── FoodSearchSheetViewModel.swift
├── Services/
│   ├── AnalyticsService.swift
│   ├── ChartDataProcessor.swift
│   ├── ChartDataProcessor+Filtering.swift
│   ├── ChartDataProcessor+Interpolation.swift
│   ├── ChartDatasetCache.swift
│   ├── ChartDatasetService.swift
│   ├── DoseDataService.swift
│   ├── DoseSearchService.swift
│   ├── DoseService.swift
│   ├── MedicationManager.swift
│   ├── NotificationService.swift
│   ├── NotificationService+Actions.swift
│   ├── NotificationService+Background.swift
│   ├── NotificationService+Persistence.swift
│   ├── NotificationCenterProtocol.swift
│   ├── PharmacokineticsEngine.swift
│   ├── ReconstitutionCalculator.swift
│   ├── ScheduleService.swift
│   ├── ScheduleService+Projection.swift
│   ├── ScheduleService+Modifications.swift
│   ├── ScheduleService+Adherence.swift
│   ├── ScheduleService+Titration.swift
│   ├── SubscriptionManager.swift
│   ├── SubscriptionManager+Testing.swift
│   ├── FoodService.swift           # Nutrition: Search orchestrator
│   ├── LocalFoodDatabase.swift     # Nutrition: SQLite FTS5 database
│   ├── MealLogService.swift        # Nutrition: CRUD operations
│   └── OpenFoodFactsService.swift  # Nutrition: API fallback
├── Onboarding/
│   ├── Views/                  # Onboarding step views
│   └── OnboardingCoordinator.swift
├── Design/
│   ├── DesignTokens.swift      # Colors, typography, spacing
│   ├── CardComponents.swift
│   ├── ButtonComponents.swift
│   ├── ButtonStyles.swift
│   ├── Colors+Extensions.swift
│   └── CircularProgressRing.swift  # Macro visualization component
├── Utilities/
│   ├── TimeConstants.swift
│   ├── DoseValidation.swift
│   ├── DoseDefaults.swift
│   ├── PricingCalculator.swift
│   └── TitrationErrorMessages.swift
├── Utils/
│   ├── ProfileValidation.swift
│   └── TestDataSeeding.swift
├── Extensions/
│   └── Array+Unique.swift
├── AuthenticationManager.swift
├── BiometricAuthManager.swift
├── ContentView.swift
├── DataController.swift
└── Info.plist
```

## Test Structure

### Unit Tests (JabTrackerTests/)
```
JabTrackerTests/
├── Models/                     # Model tests
├── Services/                   # Service tests
│   ├── ScheduleServiceTests.swift
│   ├── ScheduleServiceProjectionTests.swift
│   ├── ScheduleServiceAdherenceTests.swift
│   ├── NotificationServiceTests.swift
│   └── ...
├── ViewModels/                 # ViewModel tests
├── Mocks/                      # Mock implementations
│   └── MockNotificationCenter.swift
└── Utilities/                  # Test utilities
```

### UI Tests (JabTrackerUITests/)
```
JabTrackerUITests/
├── Onboarding/                 # Onboarding flow tests
├── DoseEntry/                  # Dose logging tests
├── Calendar/                   # Calendar view tests
├── Analytics/                  # Analytics tests
├── Settings/                   # Settings tests
├── TestUtilities/              # Shared test helpers
│   └── TestUtilities.swift     # Element debugging, wait helpers
└── ...
```

## Scripts

```
scripts/
├── build.sh                    # Build project
├── test.sh                     # Run tests (unit/ui)
├── check-all.sh                # Full CI check suite
├── coverage-detail.sh          # Coverage analysis
├── coverage-json.sh            # Coverage JSON output
├── check-coverage.sh           # Coverage policy validation
├── check-coverage-config.sh    # Coverage config validation
├── process_usda_data.py        # USDA food data processor
├── process-off-data.py         # Open Food Facts processor
└── update-food-database.sh     # Rebuild food database
```

## Key Files

| File | Purpose |
|------|---------|
| `project.yml` | XcodeGen project configuration |
| `CLAUDE.md` | Claude Code development instructions |
| `.swiftlint.yml` | SwiftLint rules |
| `JabTrackerStoreKit.storekit` | StoreKit test configuration |
| `JabTracker.entitlements` | App capabilities |
| `Info.plist` | App metadata and permissions |

## Naming Conventions

- **Views**: `*View.swift` (e.g., `DashboardView.swift`)
- **ViewModels**: `*ViewModel.swift` (e.g., `AnalyticsViewModel.swift`)
- **Services**: `*Service.swift` or `*Manager.swift`
- **Models**: Singular noun (e.g., `Dose.swift`, `User.swift`)
- **Extensions**: `Type+Feature.swift` (e.g., `Medication+Pharmacokinetics.swift`)
- **Tests**: `*Tests.swift` matching source file name

## Update History

- 2025-12-20T17:50:53Z: Added nutrition views (FoodLog, More, Nutrition, Shortcuts, Shots), models (Food, FoodEntry, Tab), services (FoodService, LocalFoodDatabase, MealLogService), and database scripts
- 2025-12-19T14:52:17Z: Initial context creation
