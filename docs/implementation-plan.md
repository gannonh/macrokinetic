# JabTracker iOS Implementation Plan

## Phase 0: Testing Infrastructure (TDD First)
1. **Create Xcode project** with test targets
2. **Set up Swift Testing** for unit/integration tests
3. **Configure XCUITest** for E2E tests
4. **Create test utilities** (mock data factories, test helpers)
5. **Write initial failing tests** for core functionality

## Phase 1: Project Foundation & App Scaffold
1. **Basic app structure**
   - TabView with 5 tabs (Dashboard, Add, History, Analytics, Settings)
   - Navigation structure with NavigationStack
   - Dark/Light mode support with system preference
   - Launch screen and app icon placeholder
2. **Core Data Stack**
   - Set up Core Data with CloudKit (NSPersistentCloudKitContainer)
   - Create initial entities (User, Dose, MedicationProfile)
   - CloudKit schema configuration
3. **Design System**
   - Color scheme (primary gradient #667eea to #764ba2)
   - Typography styles
   - Reusable view components
   - Accessibility support (VoiceOver, Dynamic Type)
4. **Project Structure**
   ```
   JabTracker/
   ├── App/
   │   ├── JabTrackerApp.swift
   │   └── ContentView.swift
   ├── Core/
   │   ├── Models/
   │   ├── Data/
   │   └── Services/
   ├── Features/
   │   ├── Dashboard/
   │   ├── DoseEntry/
   │   ├── History/
   │   ├── Analytics/
   │   └── Settings/
   ├── Shared/
   │   ├── Views/
   │   ├── ViewModifiers/
   │   └── Extensions/
   └── Resources/
   ```

## Phase 2: Core Architecture
1. **Authentication**
   - Sign in with Apple implementation
   - Face ID/Touch ID for app access
   - Keychain integration for secure storage
2. **Data Layer**
   - Repository pattern for Core Data operations
   - CloudKit sync service
   - Offline-first data strategy
3. **Business Logic**
   - Medication enum with properties (half-life, doses, frequency)
   - PharmacokineticsEngine for concentration calculations
   - Dose scheduling and reminder logic

## Phase 3: MVP Features
1. **Dose Tracking**
   - Quick add dose functionality
   - Dose history with CRUD operations
   - Calendar view integration
2. **Concentration Monitoring**
   - Real-time concentration calculations
   - Current/peak/trough level displays
   - Time to next dose indicator
3. **Basic Analytics**
   - Swift Charts integration
   - Concentration timeline graph
   - Adherence tracking

## Testing Strategy Throughout:
- **Red-Green-Refactor** cycle for all features
- **Unit tests** for PharmacokineticsEngine (100% coverage target)
- **Integration tests** for Core Data operations
- **E2E tests** for critical user flows (onboarding, dose entry)
- **Accessibility tests** for VoiceOver support

## Key Principles:
- TDD approach - no feature without failing test first
- Minimal dependencies - native Apple tech only
- Offline-first with CloudKit sync
- Medical accuracy as top priority
- Clean architecture with MVVM pattern

## Technology Stack:
- Framework: SwiftUI (iOS 16.0+)
- Backend: CloudKit (Sync, Storage, User Management)
- Data: Core Data + CloudKit Sync (NSPersistentCloudKitContainer)
- Charts: Swift Charts
- Health: HealthKit integration
- Auth: Sign in with Apple (sole authentication method)
- Testing: Swift Testing (unit/integration) + XCUITest (E2E)