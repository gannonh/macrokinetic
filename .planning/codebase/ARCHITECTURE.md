---
name: Architecture
created: 2025-12-22
last_modified: 2026-01-04
---

# Architecture

## Pattern Overview

**Overall:** MVVM with Service Layer

**Key Characteristics:**
- SwiftUI views with declarative state management
- ViewModels using `@Observable` (iOS 17+)
- Service layer for business logic coordination
- SwiftData models with CloudKit sync
- Singleton service coordinator (`AppServices`)

## Layers

**Presentation Layer (Views):**
- Purpose: SwiftUI UI components
- Contains: `*View.swift`, `*Sheet.swift`, `*Card.swift` files
- Location: `JabTracker/Views/**/*.swift`
- Depends on: ViewModels for state, Services for actions
- Used by: App entry point, navigation

**ViewModel Layer:**
- Purpose: View state and business logic coordination
- Contains: `@Observable` classes coordinating services
- Location: `JabTracker/ViewModels/*.swift`, some in `Views/` subdirectories
- Depends on: Services for operations, Models for data
- Used by: Views (via `@State` or `@ObservedObject`)

**Service Layer:**
- Purpose: Business logic, persistence, external integrations
- Contains: `*Service.swift`, `*Manager.swift`, `*Engine.swift` (28+ files)
- Location: `JabTracker/Services/*.swift`
- Depends on: Models, ModelContext, external APIs
- Used by: ViewModels, other Services

**Data Layer (Models):**
- Purpose: SwiftData entities, domain types
- Contains: `@Model` classes, enums, supporting types (39 files)
- Location: `JabTracker/Models/*.swift`
- Depends on: Nothing (pure data)
- Used by: All layers

## Data Flow

**Quick Dose Entry:**

1. User taps "+" tab → ContentView detects `Tab.add`
2. `ShortcutsSheet` appears (`Views/Shortcuts/ShortcutsSheet.swift`)
3. User taps "Log Dose" → `QuickDoseSheet` presented
4. `QuickDoseViewModel` loads smart defaults from ModelContext
5. User confirms → `DoseService.saveDose()` inserts into SwiftData
6. CloudKit syncs automatically via ModelContainer
7. `PharmacokineticsEngine` recalculates concentration
8. Dashboard updates with new concentration display

**Food Logging:**

1. User opens Food Log tab → `FoodLogView` displayed
2. User taps "+" → `FoodSearchSheet` presented
3. `FoodSearchSheetViewModel` coordinates:
   - `FoodService.search()` orchestrates local DB + API
   - Results categorized by source (History/Custom/Common/Branded)
4. User selects food → `FoodDetailSheet` shows macros
5. User adjusts serving → Bidirectional calculation (quantity ↔ target macro)
6. User saves → `MealLogService.logFood()` creates `FoodEntry`
7. CloudKit syncs, `NutritionSummaryCard` updates daily totals

**State Management:**
- SwiftData models persisted automatically
- CloudKit sync transparent to services
- UserDefaults for app preferences (`NotificationService+Persistence.swift`)

## Key Abstractions

**Services:**
- Purpose: Encapsulate business logic domains
- Examples: `ScheduleService`, `FoodService`, `PharmacokineticsEngine`, `NotificationService`
- Pattern: `@Observable` classes with extension-based organization
- Location: `JabTracker/Services/*.swift`

**SwiftData Models:**
- Purpose: Persistent data entities
- Examples: `User`, `Dose`, `MedicationProfile`, `Food`, `FoodEntry`
- Pattern: `@Model` macro with CloudKit-compatible defaults
- Location: `JabTracker/Models/*.swift`

**Coordinators:**
- Purpose: Flow state management
- Examples: `OnboardingCoordinator`, `DeeplinkHandler`
- Pattern: `@Observable` with step/state enums
- Location: `JabTracker/Onboarding/`, `JabTracker/App/`

**Service Coordinator:**
- Purpose: Dependency injection container
- Example: `AppServices.shared` - singleton
- Pattern: Initializes services with ModelContext on first use
- Location: `JabTracker/App/AppServices.swift`

## Entry Points

**App Entry:**
- Location: `JabTracker/App/JabTrackerApp.swift`
- Triggers: App launch
- Responsibilities: Initialize managers, manage auth state, provide ModelContainer

**Content View:**
- Location: `JabTracker/ContentView.swift`
- Triggers: After authentication
- Responsibilities: Tab navigation, service initialization, deep link routing

**Onboarding Coordinator:**
- Location: `JabTracker/Onboarding/OnboardingCoordinator.swift`
- Triggers: First launch or `--force-onboarding`
- Responsibilities: Step progression, data collection, schedule setup

## Error Handling

**Strategy:** Throw errors from services, catch at ViewModel/View level

**Patterns:**
- Services throw typed errors (e.g., `ScheduleServiceError`)
- ViewModels catch and expose `errorMessage` for UI
- Graceful degradation (CloudKit unavailable → local-only)
- `fatalError` for truly unrecoverable states (see CONCERNS.md)

## Cross-Cutting Concerns

**Logging:**
- OSLog framework with category-specific loggers
- Format: `Logger(subsystem: "com.gannonhall.JabTracker", category: "ServiceName")`

**Validation:**
- `DoseValidation` for medical input checking
- `ProfileValidation` for user profile data
- ViewModel-level validation before service calls

**Authentication:**
- `AuthenticationManager` handles Sign in with Apple
- `BiometricAuthManager` handles Face ID/Touch ID
- Both used at app launch before ContentView

**Notifications:**
- `NotificationService` with extensions for domains
- iOS 64-notification limit managed with rolling window
- Background refresh via BGTaskScheduler (incomplete - see CONCERNS.md)

---

*Architecture analysis: 2026-01-04*
*Update when major patterns change*
