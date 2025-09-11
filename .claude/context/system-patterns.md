---
created: 2025-09-11T16:54:56Z
last_updated: 2025-09-11T20:59:06Z
version: 1.0
author: Claude Code PM System
---

# System Patterns

## Architectural Patterns

### MVVM with SwiftUI
- **Views**: SwiftUI declarative UI components
- **ViewModels**: ObservableObject classes managing business logic
- **Models**: SwiftData entities with CloudKit sync
- **Services**: Singleton managers for cross-cutting concerns

### Data Flow Architecture
```
User Interaction → SwiftUI View → ViewModel → Service Layer → SwiftData Model → CloudKit Sync
```

### Offline-First Design
- **Local Storage Primary**: SwiftData as source of truth
- **Sync Layer**: CloudKit sync with graceful degradation
- **Status Monitoring**: Real-time sync status with user feedback
- **Conflict Resolution**: CloudKit automatic conflict handling

## Design System Patterns

### Component Hierarchy
```
DesignTokens (Colors, Typography) 
    ↓
Base Components (DesignCard, PrimaryButton)
    ↓ 
Feature Components (MedicationCard, DoseEntry)
    ↓
Screen Views (DashboardView, SettingsView)
```

### Accessibility Integration
- **VoiceOver**: Semantic accessibility labels throughout
- **Dynamic Type**: Responsive typography scaling
- **Contrast**: High contrast mode support
- **Navigation**: Logical focus order and keyboard navigation

## Authentication Patterns

### Sign in with Apple Flow
1. **Credential Request** → AuthenticationManager
2. **Apple ID Validation** → Keychain Storage
3. **User Entity Creation** → SwiftData persistence
4. **Biometric Setup** → BiometricAuthManager
5. **Session Management** → Authentication state tracking

### Security Layers
- **Network**: Sign in with Apple (OAuth2)
- **Device**: Face ID/Touch ID biometric authentication
- **Storage**: Keychain Services for credential persistence
- **Session**: Published authentication state management

## Testing Patterns

### Test Organization Strategy
```
XCTestCase (Base) 
    ↓
Feature Test Suites (AuthenticationTests, MedicationTests)
    ↓
Individual Test Methods (testUserCreation, testDoseCalculation)
```

### Test Data Management
- **Factories**: Centralized test data creation
- **Mocks**: Minimal mocking, prefer real objects where possible
- **Cleanup**: Automatic test data cleanup between tests
- **Isolation**: Independent test execution without dependencies

### UI Testing Approach
- **Authentication Bypass**: `--ui-testing` launch argument
- **Clean State**: `--reset-app-data` for fresh test environment
- **Element Selection**: Accessibility identifiers over UI hierarchy
- **Coordinate Precision**: `describe_ui` tool for exact element locations

## Error Handling Patterns

### Graceful Degradation
- **Network Errors**: Continue with local-only functionality
- **Authentication Failures**: Clear error messages with retry options
- **Data Validation**: Inline validation with helpful guidance
- **System Errors**: Fallback behaviors with user notification

### Error Communication
- **User-Facing**: Clear, actionable error messages
- **Developer**: Detailed logging with context
- **Recovery**: Automatic retry mechanisms where appropriate
- **Escalation**: Clear escalation paths for unresolvable errors

## State Management Patterns

### Published Properties
```swift
@Published var isAuthenticated: Bool
@Published var currentUser: User?
@Published var syncStatus: CloudKitSyncStatus
```

### SwiftData Relationships
```swift
@Relationship(deleteRule: .cascade, inverse: \Child.parent)
var children: [Child] = []
```

### Computed Properties
- **Derived State**: Medication dose calculations
- **UI State**: Form validation status
- **Business Logic**: Pharmacokinetic computations

## Navigation Patterns

### TabView Architecture
- **Dashboard**: Home screen with key metrics
- **Add**: Quick dose entry functionality
- **History**: Historical dose tracking
- **Analytics**: Charts and insights
- **Settings**: User profile and preferences

### Modal Presentation
- **Onboarding**: Full-screen modal for first-time setup
- **Forms**: Sheet presentation for data entry
- **Alerts**: System alerts for critical actions
- **Confirmations**: ActionSheet for destructive operations

## Code Quality Patterns

### SwiftLint Integration
- **Automatic Formatting**: SwiftLint auto-fix on commit
- **Quality Gates**: Build fails on lint violations
- **Custom Rules**: Project-specific lint configurations
- **Consistent Style**: Enforced across entire codebase

### Test Coverage Strategy
- **Tiered Coverage**: Different coverage targets by component type
- **Critical Path**: 100% coverage for medical calculations
- **Business Logic**: 85%+ coverage for core functionality
- **UI Components**: Focus on business logic, not view rendering