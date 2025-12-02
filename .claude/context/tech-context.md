---
created: 2025-09-11T16:54:56Z
last_updated: 2025-10-30T14:59:15Z
version: 2.9
author: Claude Code PM System
---

# Technology Context

## Core Technology Stack
- **Platform**: iOS 17.0+ (native)
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (NavigationStack architecture)
- **Data Persistence**: SwiftData with CloudKit sync
- **Backend**: CloudKit (iCloud sync, user management)
- **Authentication**: Sign in with Apple + Biometric (Face ID/Touch ID)

## Development Frameworks
- **Testing**: Swift Testing (unit tests) + XCUITest (UI tests)
- **Charts**: Swift Charts (for analytics visualization) - see Medical Visualization section below
- **Health**: HealthKit integration (weight and health data)
- **Notifications**: User Notifications Framework
- **Security**: Keychain Services for credential storage
- **Build System**: XcodeGen for project file management

## Dependencies and Tools
- **Build Tools**:
  - Xcode 15.0+
  - XcodeGen (project.yml configuration)
  - SwiftLint (code quality enforcement)
  - SwiftFormat (code formatting)
  - xcbeautify (enhanced build output)

- **Testing Tools**:
  - Swift Testing framework (modern test syntax)
  - XCUITest (end-to-end testing)
  - XcodeBuildMCP (UI testing and simulator automation)

## Architecture Patterns
- **MVVM**: Model-View-ViewModel with SwiftUI
- **Offline-First**: Full functionality without internet connection
- **Graceful Degradation**: CloudKit sync with local-only fallback
- **Design System**: Reusable components with accessibility
- **TDD Approach**: Test-driven development with Red-Green-Refactor

## AnalyticsService Architecture (Issue #54)
- **Modern @Observable Architecture**: AnalyticsService successfully demonstrates @Observable pattern implementation for cross-model analytics coordination
- **SwiftData ModelContext Integration**: Centralized analytics service architecture integrates seamlessly with SwiftData ModelContext for cross-model calculations
- **Cross-Model Analytics Coordination**: Proven patterns for coordinating User, Dose, and MedicationProfile models through centralized service architecture
- **Performance Optimization**: Analytics calculations optimized for large historical datasets (700+ dose records) through efficient SwiftData querying

## Data Architecture
- **SwiftData Models**: CloudKit-compatible with default values
- **Relationship Management**: Proper inverse relationships and cascade rules
- **Sync Strategy**: Real-time CloudKit sync with status monitoring
- **Data Validation**: Form validation with user-friendly error handling

### UserDefaults for Device-Specific Settings (Issue #260)

**Use Case**: Notification preferences and device-specific app settings

**Decision**: Use UserDefaults instead of SwiftData for notification settings persistence

**Rationale**:
- **Device-Specific**: Settings should not sync across devices (notification preferences are per-device)
- **Simple Storage**: Boolean and integer values don't require SwiftData complexity
- **Performance**: Faster access than SwiftData queries for frequently accessed settings
- **Platform Conventions**: iOS apps traditionally use UserDefaults for app-specific preferences
- **Separation of Concerns**: App settings vs user data stored separately

**Implementation Pattern**:
```swift
// NotificationService+Persistence.swift
extension NotificationService {
    func saveState() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(reminderMinutesBefore, forKey: "reminderMinutesBefore")
    }

    func loadState() {
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        reminderMinutesBefore = UserDefaults.standard.integer(forKey: "reminderMinutesBefore")
        if reminderMinutesBefore == 0 {
            reminderMinutesBefore = 60 // Default 1 hour
        }
    }
}
```

**When to Use UserDefaults vs SwiftData**:
- ✅ **UserDefaults**: App preferences, UI state, device-specific settings, feature flags
- ✅ **SwiftData**: User-generated content, data requiring sync, complex relationships, searchable data

## Security Implementation
- **Authentication**: Sign in with Apple (sole method)
- **Biometric Security**: Face ID/Touch ID for app access
- **Credential Storage**: Secure Keychain integration
- **Privacy Compliance**: On-device processing preference
- **Test Bypasses**: Authentication bypass for UI testing

## Build and CI/CD
- **Local Scripts**:
  - `./scripts/build.sh` - Project building
  - `./scripts/test.sh` - Test execution (unit/UI/all)
  - `./scripts/check-all.sh` - Comprehensive quality checks
  - `./scripts/coverage-detail.sh` - Code coverage analysis

- **Quality Gates**:
  - SwiftLint code quality checks
  - SwiftFormat style compliance
  - Unit test coverage (tiered system)
  - UI test end-to-end validation
  - Build verification

## Development Environment
- **macOS**: Required for iOS development
- **Xcode**: Primary IDE with full Swift ecosystem
- **Simulators**: iOS Simulator for testing (iPhone 15, iOS 17.5)
- **Git**: Version control with GitHub integration
- **Claude Code**: AI-assisted development with comprehensive PM system (CCPM)
  - **PM Commands**: 49 command implementations for epic/issue management
  - **Agent System**: Specialized agents (code-analyzer, file-analyzer)
  - **Context Management**: Automated documentation and project tracking
  - **Workflow Integration**: GitHub issue sync, epic decomposition, parallel execution
- **MCP Servers**: Context7 (library docs), Perplexity (research), XcodeBuildMCP (simulator automation)

## Medical Domain Specifics
- **GLP-1 Medications**: Semaglutide, Tirzepatide, Liraglutide, Dulaglutide
- **Pharmacokinetics**: Half-life calculations, concentration modeling
- **Medical Accuracy**: Critical for dosing calculations and safety
- **Healthcare Integration**: PDF exports for provider reports
- **Regulatory Awareness**: FDA compliance considerations

## Performance Targets
- **App Launch**: < 2 seconds
- **Calculation Updates**: < 50ms
- **Memory Usage**: < 100MB
- **Offline Capability**: Full functionality without network
- **ProMotion Support**: 120Hz display optimization

## Testing Framework Integration
> **Note**: For comprehensive testing patterns, anti-patterns, E2E processes, and test configuration, see `.claude/context/testing.md`

### Key Technology-Testing Integration Points
- **CloudKit + Testing**: Tests must disable CloudKit entirely (`cloudKitDatabase: .none`) to avoid relationship validation errors
- **SwiftUI Accessibility**: List renders as CollectionView, NavigationStack renders as CollectionView in XCUITest accessibility hierarchy
- **XcodeGen + Testing**: Run `xcodegen generate` after adding test files for them to appear in test runs

## Medical Visualization (Issue #55)

### Swift Charts Integration
- **Advanced Data Structures**: Medical visualization requires sophisticated chart point types with interpolation metadata and confidence intervals
- **Pharmacokinetic Modeling**: Concentration timeline visualization uses exponential decay algorithms for realistic medication curves
- **Performance Requirements**: Processing 365 doses in <100ms achievable with optimized data transformation algorithms
- **Memory Efficiency**: Large dataset handling (1+ year of medication data) requires lazy sequence processing and batch operations

### Chart Data Architecture
- **ChartDataProcessor**: Centralized service for transforming SwiftData models into Swift Charts-compatible structures
- **Multiple Interpolation Types**: Linear, pharmacokinetic, spline, and bezier algorithms for different visualization needs
- **Adaptive Density Control**: Intelligent data point sampling preserves timeline features while optimizing chart performance
- **Medical Accuracy**: All chart transformations maintain pharmacokinetic precision required for healthcare applications

### Performance Benchmarking
- **1 Year Datasets**: 365 doses processed in ~60ms (target: <100ms)
- **Memory Optimization**: 17,520+ concentration points handled through lazy processing
- **Data Validation**: Swift Charts compatibility verification with medical data constraints
- **Integration Overhead**: Minimal performance impact from service coordination with PharmacokineticsEngine

### XcodeGen Project Management (Issue #55)
- **Automatic File Inclusion**: Adding 8+ new Swift files automatically included in project with regeneration
- **Coverage Configuration**: New test files automatically registered in coverage-config.json
- **Build Integration**: No manual project file modifications needed for parallel stream development
- **Test Target Management**: All test files properly categorized in unit vs UI test targets

## Security & Crash Prevention (Issue #55 Security Fixes)

### Swift Charts Security Patterns
- **Swift Charts Crash Prevention**: Infinite/NaN values in chart data can crash Swift Charts rendering
- **Data Validation Requirements**: Chart data must be validated for finite numbers before rendering
- **Medical Grade Input Validation**: Healthcare applications require defensive programming at every data entry point
- **Production Safety**: Charts must handle malformed data gracefully without crashing

### SwiftLint Management for Large Files
- **SwiftLint Type Body Length**: Threshold increased to 350 lines (from 300) to accommodate complex service classes like AuthenticationManager
- **Medical Service Classes**: ChartDataProcessor and similar services may exceed default line limits for comprehensive medical functionality
- **Configuration Over Comments**: Prefer adjusting `.swiftlint.yml` thresholds over using disable comments to avoid blanket disable violations
- **Targeted Disables**: When disables are necessary, use `swiftlint:disable:next` for specific rules instead of blanket disables

### Testing Data Generation Patterns
- **Test Data Generation**: Sparse vs dense data generation impacts interpolation algorithm testing effectiveness
- **Medical Test Scenarios**: Edge cases in medical calculations require comprehensive test data patterns
- **Vulnerability Testing**: Security testing requires intentionally invalid data to verify crash prevention

## DatePicker & Calendar Integration (Issue #56)

### SwiftUI DatePicker Implementation Patterns
- **Range-Restricted DatePicker**: `(Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())...Date()` enables historical dose entry with safe unwrapping
- **Modal Calendar Interaction**: DatePicker calendar requires element-based dismissal through accessible form fields rather than coordinate-based tapping
- **Historical Data Entry**: 30-day historical dose entry enables patients to catch up on missed doses or correct entry errors

### SwiftLint Integration with Testing
- **Pre-commit Integration**: Pre-commit hooks enable catch-and-fix workflow during development
- **XCUITest Considerations**: XCUIElementQuery has `.count` property but not `.isEmpty` - SwiftLint auto-fixes can break UI tests

> **For E2E testing patterns, element targeting, CodeGen integration, and test quality frameworks**, see `.claude/context/testing.md`

## Swift Charts & Advanced UI Integration (Issue #56 Completion)

### SwiftUI Sheet Presentation & Export Patterns
- **SwiftUI Sheet Presentation**: Export functionality requires careful coordination between @State management and NavigationStack integration for professional medical apps
- **Async Export Operations**: ChartExportView demonstrates proper async export patterns with progress tracking for large medical datasets
- **Sheet Dismissal Coordination**: Export functionality changes accessibility context - requires proper coordination between chart state and modal presentation

### Performance & Memory Optimization
- **Swift Charts Performance Optimization**: Large dataset handling (365+ doses) achievable in <500ms with optimized data processing and chart rendering
- **Memory Efficiency**: SwiftUI gesture handling with complex chart interactions optimized for medical-grade responsiveness
- **Chart Rendering Standards**: <10s load time validation and <8s interaction response essential for medical app patient safety requirements

### Component Architecture Excellence
- **SwiftUI Gesture Integration**: Successful separation of chart content from gesture handling enables complex interactions while maintaining performance
- **Public API Design**: Chart control public API pattern (setZoomLevel, setPanOffset, resetZoomAndPan) provides programmatic control with proper encapsulation
- **Accessibility Architecture**: Comprehensive VoiceOver support with dynamic descriptions and trend analysis requires thoughtful component design patterns

### SwiftUI Property Wrapper Patterns (Issue #260)

**@ObservedObject with AppServices Coordinator**:
```swift
// In SwiftUI View:
@ObservedObject private var appServices = AppServices.shared

// Access nested service properties:
if let notificationService = appServices.notificationService {
    Toggle("Notifications", isOn: $notificationService.notificationsEnabled)
}
```

**Binding to Nested Service Properties**:
```swift
// When service property is not directly bindable:
Toggle("", isOn: Binding(
    get: { notificationService.notificationsEnabled },
    set: { newValue in
        notificationService.notificationsEnabled = newValue
        Task {
            if newValue { await activateNotifications() }
            else { await deactivateNotifications() }
        }
    }
))
```

**Property Wrapper Decision Matrix**:
- **@State**: Value types AND @Observable classes (iOS 17+)
- **@StateObject**: ObservableObject classes (view owns the object)
- **@ObservedObject**: ObservableObject classes (object passed in or accessed from coordinator)
- **@Bindable**: Two-way binding with @Observable classes

**Key Insight**: AppServices uses ObservableObject (not @Observable) to remain compatible with SwiftUI's observation system while providing coordinator functionality.

## Medical App Quality & Testing
> **For testing patterns, coverage management, Swift Testing framework usage, and medical app testing standards**, see `.claude/context/testing.md`

### Key Medical Testing Insights
- **Medical Calculation Accuracy**: Business logic validation critical for patient safety
- **Weekly vs Daily Dosing**: Algorithm design must account for different medication schedules
- **SwiftData Testing**: Test environment requires special handling to avoid relationship crashes

## Analytics UI/UX Integration (Issue #59)

### iOS HIG Compliance Patterns
- **Segmented Control Visual Feedback**: Segmented controls should show selected state with clear visual feedback (primary color background, white text, semibold font) - standard iOS pattern expectations
- **Touch Target Minimums**: All interactive elements must meet 44×44pt minimum - especially critical for medical apps where precision is important
- **Color Independence**: Color coding needs text/icon backup for accessibility - never rely on color alone to convey information

### Performance Standards for Medical Apps
- **Analytics Navigation Timing**: 500-2000ms acceptable but can optimize to <500ms with skeleton loading states for professional feel
- **Chart Rendering Standards**: Medical app charts should render <500ms for 365+ dose datasets - consider progressive rendering for larger datasets
- **Perceived Performance**: Skeleton screens and loading indicators improve perceived performance even when actual timing is acceptable

### Accessibility Requirements
- **VoiceOver Chart Descriptions**: Chart accessibility labels should describe trends dynamically (e.g., "improving from 60% to 100% over 4 weeks") - not just static element names
- **Touch Target Sizing**: Calendar dots and small interactive elements need verification against 44×44pt minimum
- **High Contrast Support**: Ensure chart elements remain visible and distinguishable in high contrast modes

## Dose Scheduling Models Integration (Issue #174)

### SwiftData Model Requirements
- **CloudKit Relationship Optionality**: All SwiftData relationships must be optional for CloudKit sync compatibility - non-optional relationships cause sync failures
- **Schema Evolution**: When adding new models (DoseSchedule, ScheduledDose, DoseEvent), consider impact on existing queries and entity counts

### Parallel Stream Development Success
- **4-Stream Coordination**: Successfully completed 4 parallel streams with no merge conflicts
- **File Ownership Strategy**: Clear file ownership prevents conflicts - each stream owns specific model files
- **Integration Validation**: Dedicated integration stream validates cross-model interactions

> **For SwiftData testing anti-patterns, test coverage patterns, and ModelConfiguration requirements**, see `.claude/context/testing.md`

## ScheduleService Architecture (Issue #175)

### Swift Extension Compilation Requirements
- **Base Class Dependency**: Base class must exist and be committed before extensions can compile - critical for parallel stream coordination with extension-based architecture
- **Compilation Order Matters**: Stream A must commit ScheduleService base class before Streams B & C can compile their extension files (ScheduleService+Modifications, +Adherence, +Titration)
- **Extension Pattern for Parallel Development**: Using Swift extensions for domain-specific functionality prevents file conflicts during parallel development while maintaining clean separation of concerns

### ScheduleConfiguration Codable Pattern
- **JSON Persistence in SwiftData**: Using Codable struct for schedule configuration enables JSON persistence in SwiftData baseSchedule field (stored as Data)
- **Structured Configuration**: ScheduleConfiguration with TimeComponents and CustomRecurrence provides type-safe scheduling configuration
- **Flexibility for Patterns**: Supports weekly, split-dose, and custom patterns through optional fields in single Codable struct

### SwiftData Soft Delete Pattern
- **Mark Inactive Instead of Delete**: Delete operations mark entities as inactive (`isActive = false`) rather than hard delete to preserve referential integrity
- **Cascade Relationships Preserved**: Soft delete maintains relationships while preventing logical deletion from affecting dependent entities
- **Audit Trail**: Soft delete enables schedule history and audit trail for medical compliance

### OSLog Category Organization
- **Subsystem Pattern**: Using subsystem "com.gannonhall.JabTracker" with category "ScheduleService" for structured logging across extensions
- **Category Per Service**: Each service gets its own logging category for easy filtering and debugging
- **Extension Logging**: Extensions inherit logging category from base service for consistent log organization

## Onboarding Integration (Issue #177)

### Concentration Chart Preview Performance
- **Chart Rendering**: Concentration curve preview renders reliably in < 1 second during onboarding schedule setup - meets NFR1 requirement
- **Pattern Update Performance**: Chart updates on schedule pattern change complete within appropriate timeouts (< 1s)
- **Swift Charts Integration**: PharmacokineticsEngine integration with Swift Charts demonstrates medical-grade chart rendering

> **For onboarding E2E testing patterns, XCUITest element access, and navigation timing**, see `.claude/context/testing.md`

## NotificationService Architecture (Issue #176)

### iOS User Notifications Framework Integration
- **UNUserNotificationCenterDelegate Integration**: Requires careful coordination with @Observable pattern - delegate methods run on background threads requiring ModelContext management
- **Notification Queue Management**: 30-day rolling window with 64-notification iOS limit requires prioritization logic and periodic refresh
- **SwiftData ModelContext Thread Safety**: Notification action handling requires careful ModelContext access from background threads - @MainActor isolation critical for data integrity

> **For NotificationService testing patterns, protocol-based abstraction, and mock framework design**, see `.claude/context/testing.md`

## Calendar Integration Technology Insights (Issue #178)

### SwiftUI DatePicker Range Behavior
- **Silent Date Clamping**: DatePicker with `in: startDate...endDate` parameter silently clamps selected dates to range boundaries without throwing error or showing warning
- **No User Feedback**: Users have no indication that date selection is being restricted - can lead to confusion when selected date doesn't match intended date
- **Business Logic Impact**: Range restrictions cause subtle bugs when user workflow expectations don't match programmatic range constraints
- **Example Bug**: QuickDoseSheet DatePicker restricted to past/present dates (`in: ...Date()`) caused future scheduled dose logging to show today's date instead of scheduled date

### ScheduleService ModelContext Integration Requirements
- **Context Dependency**: ScheduleService requires `ModelContext` parameter in initializer: `ScheduleService(context: ModelContext)`
- **Cannot Store as Property**: Cannot create ScheduleService instance as ViewModel property due to ModelContext requirement
- **Solution Pattern**: Create ScheduleService instance inside methods that have access to ModelContext parameter
- **Example**: `func generateTrendData(for user: User, profiles: [MedicationProfile], context: ModelContext)` creates `ScheduleService(context: context)` internally

### ChartDataProcessor Performance Characteristics
- **Sampling Density Impact**: Sampling interval directly controls chart generation performance - smaller intervals = more points = longer generation time
- **0.5h Sampling**: 0.5-hour intervals create ~6,860 concentration points for 90-day dataset (163 seconds generation time)
- **6h Sampling**: 6-hour intervals create ~600 concentration points for 90-day dataset (~10-15 seconds generation time)
- **Performance Improvement**: 12x performance improvement achieved by adjusting sampling density from 0.5h to 6h
- **Visual Quality**: 6-hour intervals maintain smooth curves for weekly GLP-1 medications without visible degradation
- **General Guideline**: Target <1,000 chart points for <10s generation, <10,000 points for <60s generation on typical iOS devices

### AnalyticsViewModel ModelContext Threading
- **Method Signature Pattern**: Methods requiring ScheduleService access must accept ModelContext as parameter
- **Thread Safety**: AnalyticsView passes `modelContext` from SwiftUI environment directly to ViewModel methods
- **Service Instantiation**: Create service instances locally within methods rather than storing as properties
- **MedicationProfile Relationship**: Access schedules via `profiles.compactMap { $0.schedules?.first }` for primary schedule

## Titration Workflow Integration (Issue #286)

### SwiftUI Confirmation Dialog Patterns
- **Multi-Action Dialogs**: TitrationConfirmationDialog demonstrates `.confirmationDialog()` modifier with 3 actions (Complete, Reschedule, Remind Later)
- **State Management**: Proper use of `@State` for dialog presentation - `showingTitrationDialog` boolean controls visibility
- **Action Handler Patterns**: Each action has dedicated handler method in ViewModel for separation of concerns
- **Medical Safety UI**: Confirmation dialogs critical for medication changes - prevent auto-apply of dose increases

### DateFormatter Display Patterns
- **Dual Format Requirements**: Two DateFormatter patterns needed for different UI contexts
- **Display Format**: `"MMM d, yyyy"` for static text displays (e.g., "Oct 29, 2025")
- **Picker Format**: `"EEEE, MMMM d"` for iOS date picker buttons (e.g., "Tuesday, October 29")
- **Consistency Importance**: Using consistent formats across app improves user experience and reduces confusion

### NotificationService Titration Integration
- **Action Handler Architecture**: NotificationService+Actions extension successfully integrates titration notification handlers
- **Three-Action Pattern**: Complete/Reschedule/Remind Later actions work identically in notifications and in-app dialogs
- **Background Context Management**: Notification actions require proper ModelContext management for background thread execution
- **User Experience Consistency**: Notification actions mirror in-app dialog actions for predictable user experience

### TDD Coverage Excellence
- **Comprehensive Test Suites**: QuickDoseViewModelTitrationTests (406 tests) demonstrates comprehensive test-driven approach
- **ViewModel Testing Patterns**: Titration detection, dialog presentation, and action handling all covered by unit tests
- **E2E Validation**: TitrationConfirmationDialogUITests (582 lines) validates complete user workflows
- **Medical App Quality**: High test coverage essential for patient safety in medication management features

## Update History
- 2025-10-30T14:59:15Z: Added Issue #260 technology insights - UserDefaults for device-specific settings, SwiftUI property wrapper patterns (@ObservedObject with AppServices), binding to nested service properties
- 2025-10-29T18:20:27Z: Added Titration Workflow Integration section (Issue #286) - SwiftUI confirmation dialog patterns, DateFormatter display patterns, NotificationService titration integration, and TDD coverage excellence for medical app quality
- 2025-10-15T18:06:05Z: Added Calendar Integration Technology Insights from Issue #178 - SwiftUI DatePicker range behavior, ScheduleService ModelContext integration requirements, ChartDataProcessor performance characteristics, and AnalyticsViewModel threading patterns
- 2025-10-09T20:27:54Z: Added Onboarding Integration E2E Testing section (Issue #177) - XCUITest back button access patterns, onboarding flow E2E testing patterns, and concentration chart preview performance validation for schedule setup integration
- 2025-10-08T20:37:55Z: Added NotificationService Architecture section (Issue #176) - iOS User Notifications Framework integration, UNUserNotificationCenter testing patterns, protocol-based abstraction, and mock framework design for notification workflows
- 2025-10-06T20:59:29Z: Added ScheduleService Architecture section (Issue #175) - Swift extension compilation requirements, ScheduleConfiguration Codable pattern, SwiftData soft delete pattern, and OSLog category organization for parallel service development
- 2025-10-05T23:08:25Z: Added Dose Scheduling Models Integration section (Issue #174) with SwiftData testing anti-patterns, coverage patterns for computed properties, and parallel development success patterns
- 2025-10-02T17:09:51Z: Updated SwiftLint Management section - increased type_body_length threshold to 350, prefer configuration changes over disable comments
- 2025-10-01T20:00:09Z: Added Analytics UI/UX Integration section (Issue #59) with iOS HIG compliance patterns, performance standards, and accessibility requirements from Phase 2 design review
- 2025-09-27T14:51:11Z: Added CodeGen-Enhanced E2E Testing Framework section with CodeGen element access patterns, TestUtilities enhancements, and test quality framework integration from Issue #57 completion
- 2025-09-26T01:23:01Z: Added AdherenceInsights Technology Integration section with Swift Testing framework debugging patterns and medical algorithm testing insights from Issue #57 business logic validation
- 2025-09-25T19:11:47Z: Added Medical App Testing & Coverage Management section with coverage configuration management, Swift Testing framework enhancements, and quality gates from Issue #71 test coverage improvements
- 2025-09-25T18:58:42Z: Added Swift Charts & Advanced UI Integration section with SwiftUI sheet presentation patterns, performance optimization insights, and component architecture excellence from Issue #56 completion
- 2025-09-24T13:21:27Z: Added DatePicker & Calendar Integration section with SwiftUI DatePicker patterns, XCUITest calendar interaction, and SwiftLint integration enhancements from Issue #56
- 2025-09-23T14:14:43Z: Added Security & Crash Prevention section with Swift Charts security patterns, SwiftLint management, and testing patterns from Issue #55 security fixes
- 2025-09-23T13:29:15Z: Added Medical Visualization section with Swift Charts integration patterns from Issue #55, XcodeGen project management insights
- 2025-09-16T22:39:56Z: Added SwiftUI calendar integration patterns from Issue #42, XCUIElementQuery limitations
- 2025-09-15T18:21:44Z: Added testing framework insights from Issue #41, SwiftUI accessibility hierarchy patterns
- 2025-09-12T16:35:25Z: Added Claude Code PM system (CCPM) details - 49 commands, agent system, workflow integration