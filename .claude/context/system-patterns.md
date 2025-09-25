---
created: 2025-09-11T16:54:56Z
last_updated: 2025-09-25T18:58:42Z
version: 1.9
author: Claude Code PM System
---

# System Patterns

## Architectural Patterns

### MVVM with SwiftUI
- **Views**: SwiftUI declarative UI components
- **ViewModels**: @Observable classes managing business logic (migrating from ObservableObject - see Issue #51)
- **Models**: SwiftData entities with CloudKit sync
- **Services**: @Observable classes for cross-cutting concerns
- **Analytics Service**: Centralized cross-model analytics coordination

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

### E2E Testing Patterns (Issues #41, #42 & #45 Learnings)
- **SwiftData Relationship Testing**: Critical pattern for tests accessing relationships (dose.medication, user.doses) - must use proper ModelContainer with CloudKit disabled
- **Test Container Setup**: ModelConfiguration with `isStoredInMemoryOnly: true, cloudKitDatabase: .none` prevents CloudKit relationship validation errors
- **Context Management**: Always insert models into context BEFORE setting relationships, then save context
- **E2E Element Targeting**: TestUtilities.debugElements() is essential for identifying correct element types and selectors
- **Text Field Utilities**: TestUtilities.clearAndEnterText() provides reliable text field interaction across all tests
- **Debug Utilities**: Comprehensive element type mapping and accessibility hierarchy debugging prevents guesswork

### Iterative E2E Testing Process (CRITICAL ANTI-PATTERN PREVENTION)
**⚠️ NEVER write all E2E tests at once - this causes major implementation problems.**

#### Correct E2E Development Process:
1. **Stub all acceptance criteria** - Create test stubs with GIVEN/WHEN/THEN comments
2. **One test at a time** - Pick one test method to implement fully
3. **Debug-first approach** - Always start with `TestUtilities.debugElements()`
4. **Single test verification** - Run: `./scripts/test.sh ui 1 TestClass/testMethod`
5. **Commit working test** - Save progress before moving to next test
6. **Iterate** - Repeat for each remaining test method

#### E2E Implementation Anti-Patterns:
- ❌ **Batch Implementation**: Writing 5+ tests before running any
- ❌ **Element Guessing**: Assuming SwiftUI → accessibility mappings without debugging
- ❌ **Multi-Test Execution**: Testing multiple new methods simultaneously
- ❌ **Skip Debug Phase**: Writing selectors without `TestUtilities.debugElements()`

### PKEngine E2E Testing Patterns (Issue #45)
- **Debug-first approach mandatory**: Always use TestUtilities.debugElements() before writing element selectors
- **Multiple element handling**: Use `.element(boundBy:)` indexing when multiple elements share accessibility identifiers
- **SwiftUI rendering reality**: Lists render as CollectionViews in XCUITest, not Tables - check actual element types
- **Performance timeout adjustments**: E2E tests require 5-10s timeouts vs 50ms unit test expectations
- **Accessibility identifier child elements**: When parent uses `.accessibilityElement(children: .ignore)`, child elements need explicit identifiers
- **Quick Dose Sheet pattern**: Preferred UI pattern over individual dose buttons for streamlined dose entry workflows
- **Real-time calculation validation**: Test concentration recalculation after dose entry with appropriate wait times

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

### Observable Pattern (iOS 17+ - Preferred for New Code)
```swift
@Observable
class ViewModel {
    var isAuthenticated: Bool = false
    var currentUser: User?
    var syncStatus: CloudKitSyncStatus = .idle
}
// In View: @State private var viewModel = ViewModel()
```

### Legacy ObservableObject Pattern (Being Migrated - Issue #51)
```swift
class ViewModel: ObservableObject {
    @Published var isAuthenticated: Bool
    @Published var currentUser: User?
    @Published var syncStatus: CloudKitSyncStatus
}
// In View: @StateObject private var viewModel = ViewModel()
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

### ⚠️ CRITICAL: SwiftData Relationship Testing Anti-Patterns
**NEVER assign arrays to SwiftData relationships in tests - this ALWAYS crashes:**

```swift
// ❌ CRASH: Never do this in tests
medicationProfile.doses = existingDoses
user.medicationProfiles = [profile1, profile2]

// ✅ SAFE: Use individual setters or avoid relationships
dose.medication = medicationProfile  // Individual setter OK
// OR pass arrays directly to methods without using relationships
```

### SwiftData Relationship Testing Patterns (Refer to testing-config.md for full anti-patterns)
- **Insert Order Critical**: Must insert parent entities (User, MedicationProfile) BEFORE child entities (Dose) to prevent duplicate registration crashes
- **Test Container Setup**: Use DataController.testContainer() consistently instead of creating custom ModelContainers
- **CloudKit Test Environment**: Use ModelConfiguration with `isStoredInMemoryOnly: true, cloudKitDatabase: .none` for tests
- **Context Management**: Always insert models into context BEFORE setting relationships, then save context

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
- Use `@Published` properties for real-time sync status updates (or plain properties with @Observable)
- Provide clear user feedback about sync status with actionable guidance

### Observable Migration Strategy (Issue #51)
- **NEW CODE**: Always use `@Observable` pattern for new ViewModels and Services
- **EXISTING CODE**: Gradually migrate `ObservableObject` classes to `@Observable`
- **VIEW PROPERTY WRAPPERS**:
  - Use `@State` for `@Observable` classes
  - Use `@StateObject`/`@ObservedObject` for `ObservableObject` classes
- **BENEFITS**: Simpler syntax, better performance, automatic observation of all properties
- **REQUIREMENTS**: iOS 17+ (already required by app)

## Analytics Service Patterns

### Cross-Model Analytics Architecture
- **Centralized Service**: AnalyticsService coordinates calculations across User, Dose, and MedicationProfile models
- **PharmacokineticsEngine Integration**: Concentration calculations for therapeutic range analysis
- **@Observable Pattern**: Real-time analytics updates with iOS 17+ observer pattern
- **Performance-First Design**: Optimized for large datasets (700+ dose records)
- **SwiftData Relationship Testing**: Critical patterns for analytics calculations accessing relationships across multiple models
- **Cross-Model Coordination**: AnalyticsService successfully coordinates User, Dose, and MedicationProfile models through centralized service architecture

### Analytics Data Structures
```swift
struct UserAnalyticsSummary {
    let overallAdherence: Double
    let medicationEffectiveness: [MedicationEffectiveness]
    let concentrationTrends: [ConcentrationTrend]
    let adherenceInsights: [AdherenceInsight]
}
```

### Medical Accuracy Patterns
- **Therapeutic Range Analysis**: Concentration optimality scoring based on medication windows
- **Multi-Factor Effectiveness**: `baseEffectiveness * adherenceFactor * concentrationOptimality`
- **Insight Generation**: Priority-based actionable recommendations
- **Edge Case Handling**: Graceful degradation for incomplete data

### Testing Patterns for Analytics
- **@MainActor Compliance**: Required for SwiftData ModelContext access in tests
- **Relationship Setup**: Insert parent entities (User, MedicationProfile) before children (Dose)
- **Test Isolation**: Use `DataController.testContainer().container` with CloudKit disabled
- **Performance Testing**: Validate <1 second execution time for comprehensive analytics

### SwiftUI Calendar & Modal Testing Patterns (Issue #56)
- **SwiftUI Calendar Modal Dismissal**: Complex calendar popover dismissal solved by tapping form elements (Notes field) below the calendar - navigation bar tapping fails due to modal overlay coverage
- **XCUITest Calendar Interaction**: SwiftUI DatePicker calendar requires element-based dismissal rather than coordinate-based tapping; successful pattern: tap accessible form fields outside calendar bounds
- **Historical Data Creation Patterns**: `createHistoricalChartData()` demonstrates robust pattern for E2E test data with date calculation, calendar navigation, and dose creation across multiple time periods
- **SwiftLint Test Complexity Management**: Medical test functions require `// swiftlint:disable cyclomatic_complexity` blocks for comprehensive E2E scenarios while maintaining code quality standards

## Parallel Development Patterns (Issue #55)

### Multi-Stream Development Architecture
- **Stream Coordination**: Successfully coordinate 4+ parallel agents with 2.5x speedup over sequential development
- **Dependency Management**: Sequential launch (A→C) and parallel (A+B) strategies for optimal workflow
- **Simulator Isolation**: Dedicated simulator assignment prevents test conflicts during parallel development
- **Integration Points**: Clear file ownership prevents conflicts, with coordination through extension patterns

### TDD at Scale
- **Embedded Testing**: Each stream follows rigorous TDD with embedded testing, eliminating separate test streams
- **Stream Ownership**: Each agent owns both implementation and testing for their domain
- **Performance Validation**: Real-time test feedback enables immediate TDD cycles
- **Quality Gates**: All streams maintain test-driven approach with immediate feedback loops

### Service Integration Patterns
- **Extension Architecture**: ChartDataProcessor+Filtering demonstrates clean extension organization
- **Lazy Processing**: Memory-efficient processing through lazy sequence generation for large datasets
- **Service Coordination**: Clean integration patterns between PharmacokineticsEngine and AnalyticsService
- **Performance Optimization**: Batch operations and adaptive density control for handling 1+ year datasets efficiently

## Security & Defensive Programming Patterns (Issue #55)

### Medical App Crash Prevention
- **Input Validation Priority**: Critical importance of input validation in medical calculations to prevent patient safety risks
- **Swift Range Safety**: Always validate range parameters before creating ranges (`1..<n` requires `n > 1`)
- **Finite Number Validation**: Medical calculations must validate `isFinite` to prevent infinite/NaN crashes in chart rendering
- **Data Sanitization Patterns**: Sanitize data at model constructor level to prevent corrupted data propagation
- **Graceful Degradation**: Medical apps must continue functioning even with malicious/corrupted input data
- **Test-Driven Security**: Security vulnerabilities caught through comprehensive test scenarios and edge case validation

### Healthcare Application Security Standards
- **Defensive Programming**: Every data entry point requires validation for medical-grade reliability
- **Crash Vulnerability Prevention**: Proactive identification and elimination of potential crash scenarios
- **Medical Data Integrity**: Ensure calculations remain valid and finite throughout data processing pipeline
- **Production Safety**: Apps must handle corrupted or malicious data without compromising patient safety

## E2E Testing & Accessibility Patterns (Issue #56)

### SwiftUI Accessibility Testing Patterns
- **SwiftUI Accessibility Hierarchy Override Prevention**: Parent-level accessibility identifiers (`accessibilityIdentifier("analytics-concentration-chart")`) override all child button identifiers - remove parent identifiers to enable proper child element targeting
- **Multiple Element Matching Solutions**: `.firstMatch` pattern essential for XCUITest when multiple elements share identifiers - prevents "Multiple matching elements found" errors in complex UI hierarchies
- **E2E Test Debug-First Methodology**: Use `TestUtilities.debugElements()` at start of every failing test to identify actual element types and identifiers before writing selectors
- **Export Sheet Handling in E2E Tests**: Export functionality changes accessibility context - use `app.sheets.firstMatch.swipeDown()` for dismissal and verify chart functionality after modal interactions

### Medical App E2E Testing Excellence
- **Comprehensive E2E Testing Implementation**: Systematic approach (display → interaction → time periods → accessibility → performance) covers all user acceptance criteria for medical applications
- **Accessibility Debugging Workflow**: Parent accessibility override → child element debug → identifier removal → test validation enables systematic accessibility issue resolution
- **E2E Test Verification Strategy**: Individual test method validation before full suite run prevents long debugging cycles in complex medical app testing

## SwiftUI Calendar & Modal Testing Patterns (Issue #56)

### SwiftUI Calendar Integration Patterns
- **SwiftUI Calendar Modal Dismissal**: Complex calendar popover dismissal solved by tapping form elements (Notes field) below the calendar - navigation bar tapping fails due to modal overlay coverage
- **XCUITest Calendar Interaction**: SwiftUI DatePicker calendar requires element-based dismissal rather than coordinate-based tapping; successful pattern: tap accessible form fields outside calendar bounds
- **Historical Data Creation Patterns**: `createHistoricalChartData()` demonstrates robust pattern for E2E test data with date calculation, calendar navigation, and dose creation across multiple time periods
- **SwiftLint Test Complexity Management**: Medical test functions require `// swiftlint:disable cyclomatic_complexity` blocks for comprehensive E2E scenarios while maintaining code quality standards

### SwiftUI Component Architecture Patterns
- **SwiftUI Gesture Integration**: Successful implementation of complex gesture handling (pinch-zoom, drag-pan) with state management in ConcentrationTimelineChart
- **Medical App Accessibility Excellence**: Comprehensive VoiceOver implementation with dynamic descriptions, trend analysis, and gesture instruction integration
- **Professional Export Architecture**: ChartExportView demonstrates proper sheet presentation patterns with async operations and progress tracking
- **Chart State Management**: Public API pattern (setZoomLevel, setPanOffset, resetZoomAndPan) enables programmatic control while maintaining encapsulation

### SwiftUI Unit Testing Anti-Patterns
- **Direct @State Manipulation Prevention**: Direct @State manipulation in tests doesn't work - use proper component initialization testing instead
- **SwiftUI Accessibility Label Inheritance**: VStack accessibility modifiers override all child labels - remove parent `.accessibilityLabel()` to preserve individual button labels
