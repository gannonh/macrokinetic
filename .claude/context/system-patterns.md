---
created: 2025-09-11T16:54:56Z
last_updated: 2025-09-16T22:39:56Z
version: 1.2
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

### UI Testing Essential Utilities
- **`TestUtilities.debugElements()`** - Debug accessibility hierarchy
- **`TestUtilities.clearAndEnterText()`** - Reliable text field interaction
- Use **debug output** to identify correct element types before writing selectors

### E2E Testing Patterns (Issues #41 & #42 Learnings)
- **SwiftData Relationship Testing**: Critical pattern for tests accessing relationships (dose.medication, user.doses) - must use proper ModelContainer with CloudKit disabled
- **Test Container Setup**: ModelConfiguration with `isStoredInMemoryOnly: true, cloudKitDatabase: .none` prevents CloudKit relationship validation errors
- **Context Management**: Always insert models into context BEFORE setting relationships, then save context
- **E2E Element Targeting**: TestUtilities.debugElements() is essential for identifying correct element types and selectors
- **Text Field Utilities**: TestUtilities.clearAndEnterText() provides reliable text field interaction across all tests
- **Debug Utilities**: Comprehensive element type mapping and accessibility hierarchy debugging prevents guesswork

### SwiftUI Calendar Testing Patterns (Issue #42)
- **Robust Element Finding**: Implement fallback logic for element targeting in dynamic UI components where accessibility identifiers may be unreliable
- **Calendar Component Testing**: SwiftUI Calendar components require specialized element finding strategies in XCUITest environment
- **Accessibility Identifier Implementation**: Use consistent patterns for calendar day cells, month headers, and navigation controls
- **Fallback Element Selection**: When primary accessibility identifiers fail, use content-based element finding with NSPredicate filtering

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

## Key Development Patterns

### SwiftData Model Architecture
- All models use CloudKit-compatible default values (avoids optionals where possible)
- Include `createdAt` and `updatedAt` timestamps for audit trails
- Use proper `@Relationship` attributes with `inverse` and `deleteRule` specifications
- **One-Side Relationship Rule**: Only parent entities use `@Relationship(inverse:)` - child entities use plain properties to avoid circular references
- Example: `MedicationProfile` with enhanced fields for compounding and dose escalation

### Authentication Implementation Gotchas
- Biometric authentication simulator limitations - test on real devices for accuracy
- UserDefaults can be unreliable in UI tests - use in-memory storage when needed
- Authentication state must be checked on app launch for proper flow control
- Face ID prompt timing can cause test flakiness - add appropriate waits and timeouts
- Environment variables and launch arguments are key for test/production differentiation
- Always provide authentication bypass for UI testing to avoid external dependencies
- Keychain access can fail in test scenarios - implement proper error handling

### Testing Framework Best Practices
- Swift Testing provides cleaner, more modern test syntax than XCTest
- xcbeautify offers better Swift Testing output support than xcpretty
- Never use `CODE_SIGNING_ALLOWED=NO` for UI tests - prevents app launch
- File-based test organization improves maintainability

### XcodeGen Workflow
- **CRITICAL**: Always run `xcodegen generate` after adding new Swift files
- Project uses XcodeGen for automatic project file management
- New test files won't appear in test runs until project is regenerated
- Auto-includes all Swift files in respective directories (JabTracker/, JabTrackerTests/, JabTrackerUITests/)

### CloudKit + SwiftData Integration
- Always implement graceful fallback when CloudKit is unavailable
- Check for test environment before enabling CloudKit to avoid test conflicts
- Use `@Published` properties for real-time sync status updates
- Provide clear user feedback about sync status with actionable guidance
