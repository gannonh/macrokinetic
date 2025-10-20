---
created: 2025-09-11T16:54:56Z
last_updated: 2025-10-20T14:22:56Z
version: 2.9
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
> **For comprehensive testing patterns, E2E processes, test data management, UI testing approaches, and test quality standards**, see `.claude/context/testing.md`

### Key Testing Integration Points
- **SwiftData + Testing**: Test environment requires special handling to avoid relationship crashes
- **XcodeGen + Testing**: Run `xcodegen generate` after adding test files
- **Medical Testing Standards**: Patient safety requires rigorous testing of business logic

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

### SwiftLint Management Patterns (Issue #57)
- **Targeted Disable Strategy**: Use `// swiftlint:disable:next orphaned_doc_comment` instead of blanket disables to avoid blanket_disable_command violations
- **Doc Comment Attachment**: SwiftLint requires doc comments directly attached to declarations without intervening disable comments
- **Complex Function Handling**: Use `// swiftlint:disable:next cyclomatic_complexity` immediately before function declaration for complex test utilities
- **Pre-commit Integration**: Pre-commit hooks enable catch-and-fix workflow for violations during implementation
- **Iterative Fix Approach**: Systematic violation resolution (force unwrapping → for-where → cyclomatic complexity) while maintaining functionality

### Test Coverage Strategy
- **Tiered Coverage**: Different coverage targets by component type
- **Critical Path**: 100% coverage for medical calculations
- **Business Logic**: 85%+ coverage for core functionality
- **UI Components**: Focus on business logic, not view rendering

> **For SwiftData relationship testing anti-patterns, test container setup, and ModelConfiguration requirements**, see `.claude/context/testing.md`

## Version Control Patterns

### Commit Verification Discipline
- **Verify Before Commit**: Never commit code changes until they are verified to work correctly
- **Test-Driven Commits**: Run relevant tests and verify functionality before committing fixes
- **Avoid False History**: Multiple commits claiming to "fix" the same issue creates misleading and confusing git history
- **Atomic Commits**: Each commit should represent a complete, working change that builds and functions as intended
- **Commit Message Accuracy**: Commit messages should accurately reflect what was accomplished, not what was attempted

**Anti-pattern Example:**
```bash
# ❌ WRONG: Committing unverified fixes creates confusing history
git commit -m "fix: Resolve authentication bug"              # Not verified, bug still exists
git commit -m "fix: Actually fix authentication bug"          # Still broken
git commit -m "fix: Fix authentication bug for real"          # Misleading git history
```

**Correct Pattern:**
```bash
# ✅ CORRECT: Verify before commit
./scripts/test.sh unit 1 AuthenticationTests  # Run relevant tests first
# Verify tests pass and functionality works
git commit -m "fix: Resolve authentication state persistence issue"  # Single accurate commit
```

### Verification Checklist Before Commit
1. **Run Relevant Tests**: Execute unit tests for changed code areas
2. **Manual Verification**: Test the specific functionality that was modified
3. **Build Verification**: Ensure the project builds without errors or warnings
4. **Lint Checks**: Run SwiftLint to catch code quality violations (`swiftlint`)
5. **Integration Check**: Verify changes don't break related functionality

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


## Parallel Development Patterns (Issue #55)

### Multi-Stream Development Architecture
- **Stream Coordination**: Successfully coordinate 4+ parallel agents with 2.5x speedup over sequential development
- **Dependency Management**: Sequential launch (A→C) and parallel (A+B) strategies for optimal workflow
- **Simulator Isolation**: Dedicated simulator assignment prevents test conflicts during parallel development
- **Integration Points**: Clear file ownership prevents conflicts, with coordination through extension patterns

### TDD at Scale
- **Embedded Testing**: Each stream follows rigorous TDD with embedded testing
- **Stream Ownership**: Each agent owns both implementation and testing for their domain

> **For TDD patterns, test-driven parallel streams, and testing workflows**, see `.claude/context/testing.md`

### Service Integration Patterns
- **Extension Architecture**: ChartDataProcessor+Filtering demonstrates clean extension organization
- **Lazy Processing**: Memory-efficient processing through lazy sequence generation for large datasets
- **Service Coordination**: Clean integration patterns between PharmacokineticsEngine and AnalyticsService
- **Performance Optimization**: Batch operations and adaptive density control for handling 1+ year datasets efficiently

### Hybrid Parallel Development Strategy (Issue #175)
- **Phase-Based Parallelization**: Phase 1 (Sequential foundation) → Phase 2 (Parallel execution) enables 2.4x speedup while respecting Swift compilation dependencies
- **Extension-Based Service Architecture**: Using Swift extensions (ScheduleService+Projection, +Modifications, +Adherence, +Titration) prevents file conflicts during parallel development
- **@Observable Service Pattern**: ScheduleService successfully implements iOS 17+ @Observable pattern for real-time updates with ModelContext dependency injection
- **Error Enum Coordination**: Centralized error enum in base class with stream-specific cases prevents duplication
- **Commit Strategy for Dependencies**: Stream A committed base class early (Phase 1) to unblock dependent streams - critical when extensions depend on base class compilation

### NotificationService Parallel Development Patterns (Issue #176)
- **3-Stream Parallel Success**: Successfully coordinated 3 parallel agents with extension-based architecture (Stream A: Core Infrastructure, Stream B: Background Refresh, Stream C: Action Handling)
- **Extension Architecture for Parallel Services**: NotificationService+Actions.swift and NotificationService+Background.swift pattern prevents file conflicts
- **Protocol-Based Testability**: NotificationCenterProtocol abstraction enables comprehensive unit testing without requiring actual UNUserNotificationCenter

> **For parallel testing patterns, test-driven parallel development, simulator isolation, and quality gate validation**, see `.claude/context/testing.md`

### E2E Testing Excellence Patterns (Issue #177)

#### Iterative E2E Development Process
- **One-Test-at-a-Time Implementation**: Implementing each test individually (vs batch implementation) prevents debugging chaos and achieved 100% pass rate on first full suite run
- **Debug-First Methodology**: Always use `TestUtilities.debugElements()` before writing selectors - saves significant time and reveals actual element types
- **Commit After Each Test**: Individual commits for passing tests provides clear progress tracking and easy rollback points
- **Full Suite Verification**: Running all tests together ensures no interdependencies or conflicts

#### XCUITest Element Targeting
- **Back Button Access Pattern**: Use explicit accessibility identifier (`app.buttons["onboarding-back-button"]`) rather than navigation bar queries
- **Multiple Element Handling**: Use `.element(boundBy: 0)` for accessing specific elements when multiple share same identifier
- **Debug Output Analysis**: Raw logs reveal actual element types and identifiers more reliably than assumptions
- **Strategic Sleep Placement**: Use `sleep(3)` for navigation/rendering, `usleep(50_000)` for UI updates

#### Performance Testing for E2E
- **E2E Timeout Expectations**: E2E tests require < 1 second timeouts (not < 200ms unit test expectations)
- **Chart Preview Performance**: Concentration curve preview renders < 1 second meeting NFR requirements
- **Pattern Update Responsiveness**: Chart updates complete within E2E-appropriate timeouts

#### Accessibility Testing Without Simulation
- **VoiceOver Property Validation**: Comprehensive testing validates properties (labels, values, hints) without simulating actual VoiceOver
- **State Announcement Verification**: Toggle and button values correctly indicate current state for assistive technologies
- **Accessibility Label Coverage**: All interactive elements have descriptive labels enabling full VoiceOver navigation

## Security & Defensive Programming Patterns (Issue #55)

### Medical App Crash Prevention
- **Input Validation Priority**: Critical importance of input validation in medical calculations to prevent patient safety risks
- **Swift Range Safety**: Always validate range parameters before creating ranges (`1..<n` requires `n > 1`)
- **Finite Number Validation**: Medical calculations must validate `isFinite` to prevent infinite/NaN crashes in chart rendering
- **Data Sanitization Patterns**: Sanitize data at model constructor level to prevent corrupted data propagation
- **Graceful Degradation**: Medical apps must continue functioning even with malicious/corrupted input data

### Healthcare Application Security Standards
- **Defensive Programming**: Every data entry point requires validation for medical-grade reliability
- **Crash Vulnerability Prevention**: Proactive identification and elimination of potential crash scenarios
- **Medical Data Integrity**: Ensure calculations remain valid and finite throughout data processing pipeline
- **Production Safety**: Apps must handle corrupted or malicious data without compromising patient safety

> **For test-driven security and edge case validation testing**, see `.claude/context/testing.md`

## SwiftUI Component Architecture Patterns

### SwiftUI Gesture Integration
- **Complex Gesture Handling**: Successful implementation of pinch-zoom, drag-pan with state management in ConcentrationTimelineChart
- **Medical App Accessibility**: Comprehensive VoiceOver implementation with dynamic descriptions and trend analysis
- **Professional Export Architecture**: ChartExportView demonstrates proper sheet presentation patterns with async operations
- **Chart State Management**: Public API pattern (setZoomLevel, setPanOffset, resetZoomAndPan) enables programmatic control

### SwiftUI Accessibility Best Practices
- **Accessibility Label Inheritance**: VStack accessibility modifiers override all child labels - remove parent `.accessibilityLabel()` to preserve individual button labels
- **VoiceOver Excellence**: Comprehensive support with dynamic descriptions for medical data

> **For E2E testing patterns, accessibility testing, CodeGen integration, medical app testing excellence, and test-driven validation**, see `.claude/context/testing.md`

## AdherenceInsights Business Logic Patterns (Issue #57)

### Medical Algorithm Design
- **Weekly Medication Patterns**: Weekly medication patterns require different logic than daily medication assumptions
- **Test-First Validation**: Tests revealed fundamental flaws in weekend gap detection and dose escalation algorithms
- **Medical App Development Standards**: Test workarounds compromise patient safety - always fix root cause business logic

> **For SwiftData relationship testing patterns and test-driven debugging**, see `.claude/context/testing.md`

## Design Review & Polish Patterns (Issue #59)

### Phase-Based UX/UI Development Process
- **Phase 1: E2E Screenshot Capture** - Comprehensive test suite captures all analytics views for baseline documentation
- **Phase 2: Design Review & Analysis** - Systematic UI/UX review with structured feedback (ratings, priorities, recommendations)
- **Phase 3: UI/UX Implementation** - Execute agreed-upon improvements based on design review findings
- **Phase 4: State & Performance Optimization** - Profile and optimize for production performance standards

### Priority-Based Implementation Framework
- **Must Have (5 items)**: Critical fixes blocking clinical value (therapeutic range, axis labels, visual feedback, accessibility, terminology)
- **Should Have (6 items)**: Important improvements for professional polish (loading states, streak icons, historical markers)
- **Nice to Have (7 items)**: Future enhancements for advanced features (tooltips, haptics, pattern fills)

### Visual Baseline Documentation Patterns
- **Screenshot-Driven Analysis**: E2E test screenshots enable thorough visual review without repeated simulator runs
- **Structured Feedback Organization**: Organize by view section (above fold, below fold, controls) with ratings and specific improvements
- **Before/After Comparison**: Visual baselines provide clear communication for design decisions and implementation validation
- **Cross-Cutting Concerns**: Analyze accessibility, performance, and consistency across all views to reveal systemic vs component-specific issues

### Design Review Output Structure
- **Executive Summary**: Overall assessment with key strengths and critical gaps
- **Section-by-Section Analysis**: Detailed review of each view with design questions and feedback
- **Priority Issues & Opportunities**: Categorized by severity (high/medium/low priority)
- **Recommendations Summary**: Actionable next steps with clear must-have/should-have/nice-to-have breakdown
- **Review History**: Track feedback and implementation status over time

## Calendar Integration Patterns (Issue #178)

### SwiftUI DatePicker Range Validation
- **Silent Clamping Behavior**: DatePicker with `in: startDate...endDate` range silently clamps selected dates to range boundaries without error
- **Business Requirements Alignment**: Always validate DatePicker range matches business requirements (e.g., future dose logging requires future date range)
- **User Expectation Mismatch**: Range restrictions can cause subtle bugs when user expectations don't match range constraints - "Log Dose Now" for Oct 21 scheduled dose showed Oct 14 when range limited to past/present
- **Solution Pattern**: Extend DatePicker range to accommodate all valid use cases: `(Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())...Calendar.current.date(byAdding: .day, value: 30, to: Date())!` for 30-day historical + 30-day future logging

### Placeholder Method Anti-Pattern
- **Never Commit Placeholders**: Never commit placeholder methods with random/hardcoded data to production code
- **Proper Alternatives**: Use TODO comments, feature flags, or commented-out implementation notes instead
- **Detection Strategy**: Search codebase for "random", "sample", "placeholder" keywords before release
- **Real-World Impact**: AnalyticsViewModel had `generateTrendData()` with `Double.random(in: 0.6...0.95)` and `generateMissedDosePatterns()` with hardcoded "Saturday: 2, Sunday: 3" - showed fake declining adherence even with 100% perfect adherence

### Chart Performance Tuning Patterns
- **Sampling Density Trade-off**: Chart sampling intervals must balance visual smoothness with generation performance
- **Weekly GLP-1 Optimization**: 6-hour intervals provide smooth concentration curves for weekly medications while maintaining <10s generation time
- **Performance Impact**: 0.5h sampling created 6,860 points for 90 days (163s generation), 6h sampling created ~600 points (<15s generation) - 12x performance improvement
- **General Guideline**: Aim for <1,000 chart points for <10s generation, <10,000 points for <60s generation on typical iOS devices

## Update History
- 2025-10-20T14:22:56Z: Added E2E Testing Excellence Patterns from Issue #177 - iterative E2E development process, XCUITest element targeting, performance testing for E2E, and accessibility testing without simulation
- 2025-10-15T18:06:05Z: Added Calendar Integration Patterns from Issue #178 - SwiftUI DatePicker range validation, placeholder method anti-pattern, and chart performance tuning for medical apps
- 2025-10-14T17:00:00Z: Added Version Control Patterns section with commit verification discipline - emphasizes verifying work before committing to avoid false git history with multiple failed fix attempts
- 2025-10-09T20:27:54Z: Updated for Issues #175, #176, #177 - Hybrid parallel development strategy, NotificationService parallel patterns, and onboarding integration E2E testing patterns
- 2025-10-08T20:37:55Z: Added NotificationService Parallel Development Patterns from Issue #176 - 3-stream parallel coordination, extension architecture, protocol-based testability, and UNUserNotificationCenter testing limitations
- 2025-10-06T20:59:29Z: Added Hybrid Parallel Development Strategy from Issue #175 - phase-based parallelization, extension architecture, @Observable service pattern, error enum coordination, and commit strategies for parallel streams
- 2025-10-05T23:08:25Z: Added SwiftData CloudKit relationship patterns from Issue #174 (dose scheduling models) - CloudKit requirements, circular reference prevention, timing precision, and ModelConfiguration completeness
- 2025-10-01T20:00:09Z: Added Design Review & Polish Patterns section (Issue #59) with phase-based UX development, priority framework, visual baseline documentation, and structured design review outputs
- 2025-09-27T14:51:11Z: Added CodeGen-Enhanced E2E Testing Patterns and SwiftLint Management Patterns from Issue #57 completion
- 2025-09-26T01:23:01Z: Added AdherenceInsights Business Logic Patterns from Issue #57 business logic validation
