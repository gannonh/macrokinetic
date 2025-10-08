---
created: 2025-09-11T16:54:56Z
last_updated: 2025-10-07T22:25:40Z
version: 2.0
author: Claude Code PM System
---

# Project Structure

## Root Directory Organization
```
jab-tracker-ios/
├── .claude/                    # Claude Code PM system files (231+ files)
│   ├── agents/                 # Sub-agent configurations (code-analyzer, file-analyzer, etc.)
│   ├── commands/              # Custom command implementations (49 command files)
│   │   ├── context/           # Context management (create, update, prime)
│   │   ├── pm/                # Project management (epic/issue workflows)
│   │   └── testing/           # Test execution and analysis
│   ├── context/               # Project context documentation (this directory)
│   ├── epics/                 # Epic and feature tracking
│   │   ├── analytics/         # Analytics epic (COMPLETED 2025-10-04)
│   │   ├── dose-tracking/     # Dose tracking epic (COMPLETED)
│   │   └── dose-scheduling/   # Dose scheduling epic (BACKLOG - NEW)
│   ├── hooks/                 # Development workflow hooks
│   ├── prds/                  # Product Requirements Documents
│   ├── rules/                 # Development rules and guidelines (10+ rule files)
│   ├── scripts/               # PM automation scripts (shell implementations)
│   └── settings.json          # PM system configuration
├── ccpm/                      # Claude Code Project Management tools
├── docs/                      # Project documentation
│   ├── spec-master-prd.md     # Master Product Requirements
│   └── implementation-plan.md # Development implementation tracking
├── specs/                     # Feature specifications and contracts
│   └── 001-medication-profile-management/
├── scripts/                   # Build and automation scripts
├── JabTracker/               # Main application source code
├── JabTrackerTests/          # Unit test suite
├── JabTrackerUITests/        # UI/E2E test suite
└── project.yml               # XcodeGen project configuration
```

## Source Code Organization (/JabTracker/)
```
JabTracker/
├── Design/                    # Design system components
│   ├── DesignTokens.swift    # Colors, typography, spacing
│   ├── CardComponents.swift  # Reusable card UI elements
│   ├── ButtonComponents.swift # Button design system
│   └── ButtonStyles.swift    # Button style definitions
├── Models/                   # SwiftData models
│   ├── User.swift           # User profile model
│   ├── Dose.swift           # Dose tracking model
│   ├── MedicationProfile.swift # Medication profile model
│   ├── DoseSchedule.swift   # Dose schedule model (Issue #174)
│   ├── ScheduledDose.swift  # Scheduled dose model (Issue #174)
│   ├── PendingNotification.swift # Notification queue data structures (Issue #176)
│   ├── ChartData.swift      # Chart configuration and layout structures (Issue #55)
│   ├── ChartDataTypes.swift # Advanced chart point and marker types (Issue #55)
│   └── ChartDataEnums.swift # Chart styling and status enums (Issue #55)
├── Views/                    # SwiftUI view layer
│   ├── Authentication/      # Auth-related views
│   ├── Onboarding/         # User onboarding flow
│   ├── Settings/           # Settings and profile management
│   └── Dashboard/          # Main dashboard views
├── Services/               # Business logic and services
│   ├── AnalyticsService.swift        # Cross-model analytics coordination
│   ├── AuthenticationManager.swift
│   ├── BiometricAuthManager.swift
│   ├── MedicationManager.swift
│   ├── ScheduleService.swift         # Dose schedule management (Issue #175)
│   ├── ScheduleService+Projection.swift # Schedule projection and upcoming doses (Issue #175)
│   ├── ScheduleService+Modifications.swift # Schedule modifications (Issue #175)
│   ├── ScheduleService+Adherence.swift # Adherence tracking (Issue #175)
│   ├── ScheduleService+Titration.swift # Dose titration (Issue #175)
│   ├── NotificationService.swift     # Core notification infrastructure (Issue #176)
│   ├── NotificationService+Actions.swift # Action handling & missed dose detection (Issue #176)
│   ├── NotificationService+Background.swift # Background refresh & badge management (Issue #176)
│   ├── ChartDataProcessor.swift      # Core chart data transformation service (Issue #55)
│   ├── ChartDataProcessor+Filtering.swift # Filtering and aggregation extensions (Issue #55)
│   └── ChartDataProcessor+Interpolation.swift # Advanced interpolation methods (Issue #55)
├── Utilities/             # Utility functions and helpers
│   └── TimeConstants.swift # Centralized time constants for schedule calculations (Issue #175)
└── App/                   # App-level configuration
    ├── JabTrackerApp.swift # Main app entry point
    └── DataController.swift # SwiftData + CloudKit setup
```

## Testing Structure
- **JabTrackerTests/**: Swift Testing framework unit tests
- **JabTrackerUITests/**: XCUITest end-to-end testing
- **File-based organization**: Tests organized by feature area
- **Analytics Integration Tests**: AnalyticsServiceIntegrationTests.swift for cross-model testing
- **ChartDataProcessor Test Suite**: Comprehensive testing across 5 specialized test files (Issue #55):
  - ChartDataProcessorTests.swift (core functionality)
  - ChartDataProcessorInterpolationTests.swift (advanced interpolation)
  - ChartDataProcessorFilteringTests.swift (filtering and aggregation)
  - ChartDataProcessorPerformanceTests.swift (performance benchmarks)
  - ChartDataProcessorIntegrationTests.swift (service coordination)
- **ScheduleService Test Suite**: Comprehensive testing across 5 specialized test files (Issue #175):
  - ScheduleServiceTests.swift (CRUD operations)
  - ScheduleServiceProjectionTests.swift (schedule projection)
  - ScheduleServiceModificationTests.swift (schedule modifications)
  - ScheduleServiceAdherenceTests.swift (adherence tracking)
  - ScheduleServiceTitrationTests.swift (dose titration)
- **NotificationService Test Suite**: Comprehensive testing across 4 specialized test files (Issue #176):
  - NotificationServiceTests.swift (authorization & queue management - 25 tests)
  - NotificationServiceBackgroundTests.swift (background refresh & badge - 15 tests)
  - NotificationServiceActionTests.swift (action handling & missed dose - 20 tests)
  - PendingNotificationTests.swift (model coverage - 10 tests)
- **Mock utilities**: Shared test utilities and factories

## Build System
- **XcodeGen**: Project file generation (project.yml)
- **SwiftLint**: Code quality and style enforcement
- **xcbeautify**: Enhanced build output formatting
- **Scripts**: Automated build, test, and quality check scripts

## Documentation Patterns
- **CLAUDE.md**: Main development guidance (root level)
- **docs/**: Technical specifications and implementation plans
- **specs/**: Feature-specific contracts and specifications
- **.claude/**: Claude Code PM system and context files

## File Naming Conventions
- **Swift Files**: PascalCase for types, camelCase for files
- **Views**: Descriptive names ending in "View"
- **Models**: Singular noun representing the entity
- **Services**: Descriptive name ending in "Manager" or "Service"
- **Tests**: Matching source file name + "Tests" suffix

## Module Organization Principles
- **Feature-based grouping**: Related functionality grouped together
- **Separation of concerns**: UI, business logic, and data layers separated
- **Reusable components**: Design system components for consistency
- **Test colocation**: Tests organized to mirror source structure

## Calendar Feature Structure Insights (Issue #42)
- **Calendar feature modularization**: Implemented across Views/ViewModels/Tests structure following established patterns
- **Stream-based development organization**: Complex UI features benefit from parallel development streams (UI, Statistics, Integration)
- **Test utilities enhancement**: Enhanced TestUtilities with calendar-specific debugging for improved E2E testing reliability
- **SwiftLint configuration management**: Different code patterns require careful SwiftLint rule management to prevent framework conflicts

## ChartDataProcessor Structure Insights (Issue #55)
- **Service Extension Pattern**: ChartDataProcessor+Filtering and ChartDataProcessor+Interpolation demonstrate clean extension organization
- **Parallel Development Architecture**: 4-stream development with clear file ownership prevents conflicts during parallel implementation
- **Test Organization Excellence**: Separate test files for core, interpolation, filtering, performance, and integration enable focused testing
- **Model-Service Separation**: Chart data structures in Models/ directory separate from processing logic in Services/
- **Medical Data Architecture**: Specialized chart data types for healthcare visualization with pharmacokinetic modeling support

## AdherenceInsights Structure Insights (Issue #57)
- **Stream Dependency Management**: UI streams (A, B) depend on business logic accuracy from Stream C - discovered during Issue #57 implementation
- **Critical Issue Identification Workflow**: Business logic validation essential before marking streams complete - prevents false completion status
- **Three-Stream Architecture Validation**: Parallel development requires validation of integration points between streams before final completion
- **Medical Algorithm Service Structure**: AdherenceInsightsService requires comprehensive business logic validation separate from UI implementation
- **Service-View Separation**: UI excellence in streams A and B meaningless without medically accurate backend algorithms in stream C
- **Healthcare App Architecture Requirements**: Medical applications require rigorous validation of core business logic before UI integration

## Dose Scheduling Models Structure Insights (Issue #174)
- **SwiftData Model Location Pattern**: All persistent models (`DoseSchedule.swift`, `ScheduledDose.swift`) placed in `JabTracker/Models/` directory alongside existing User, Dose, MedicationProfile models
- **Calculated Entity Organization**: Non-persistent calculated entities (`DoseEvent.swift` struct) also stored in `JabTracker/Models/` for discoverability and logical grouping
- **Test File Parallel Structure**: Model tests follow strict parallel organization - `DoseSchedule.swift` → `JabTrackerTests/DoseScheduleTests.swift`, maintaining 1:1 mapping
- **Parallel Stream File Ownership**: 4-stream development succeeded through clear file ownership (Stream A: ScheduledDose, Stream B: DoseSchedule, Stream C: DoseEvent, Stream D: Integration tests)
- **Integration Test Organization**: Integration tests (`DoseSchedulingIntegrationTests.swift`) validate cross-model relationships and belong in dedicated integration test files
- **Model Extension Pattern**: Updated existing models (`MedicationProfile.swift`, `Dose.swift`) to add new relationships - maintains cohesion within model files

## ScheduleService Structure Insights (Issue #175)

### Service Extension Organization
- **Base + Extensions Pattern**: `JabTracker/Services/ScheduleService.swift` (base class) with domain-specific extensions (`+Projection`, `+Modifications`, `+Adherence`, `+Titration`)
- **Extension File Naming**: Consistent pattern: `ScheduleService+DomainName.swift` for each functional area
- **Clear Separation of Concerns**: CRUD operations in base, projections in +Projection, modifications in +Modifications, adherence in +Adherence, titration in +Titration

### Test File Parallel Structure
- **One-to-One Mapping**: Each implementation file has corresponding test file for clear ownership
  - `ScheduleService.swift` → `ScheduleServiceTests.swift` (CRUD tests)
  - `ScheduleService+Projection.swift` → `ScheduleServiceProjectionTests.swift` (projection tests)
  - `ScheduleService+Modifications.swift` → `ScheduleServiceModificationTests.swift`
  - `ScheduleService+Adherence.swift` → `ScheduleServiceAdherenceTests.swift`
  - `ScheduleService+Titration.swift` → `ScheduleServiceTitrationTests.swift`
- **Stream Ownership**: Each parallel stream owns both implementation extension and corresponding test file

### Parallel Development File Organization
- **No Shared Files**: Each stream works on dedicated extension files - prevents merge conflicts
- **Base Class Foundation**: Stream A creates base class first, then other streams add extensions
- **Error Enum in Base**: Centralized error enum (`ScheduleServiceError.swift`) in base class with stream-specific cases

## NotificationService Structure Insights (Issue #176)

### NotificationService File Organization
- **Extension-Based Organization**: NotificationService.swift base + NotificationService+Actions.swift + NotificationService+Background.swift enables clear separation of concerns and parallel development
- **Test File Parallel Structure**: One-to-one mapping between implementation and test files (NotificationService → NotificationServiceTests, NotificationService+Actions → NotificationServiceActionTests, NotificationService+Background → NotificationServiceBackgroundTests) maintains clear ownership
- **Mock Utilities Location**: MockNotificationCenter.swift in JabTrackerTests/Mocks/ directory establishes pattern for framework protocol mocks - reusable across test suites
- **PendingNotification Model Location**: Notification-specific data structures in JabTracker/Models/ alongside other domain models - maintains consistency with existing project organization

## Update History
- 2025-10-08T20:37:55Z: Added NotificationService Structure Insights (Issue #176) - extension-based organization, test file parallel structure, mock utilities location, and notification model organization patterns
- 2025-10-07T22:25:40Z: Added NotificationService files (NotificationService.swift, +Actions.swift, +Background.swift) and PendingNotification.swift model (Issue #176), updated test suite structure with 4 new test files (70 tests total)
- 2025-10-07T18:35:45Z: Added Utilities directory with TimeConstants.swift for centralized time constants (Issue #175)
- 2025-10-06T20:59:29Z: Added ScheduleService structure insights from Issue #175 - service extension organization pattern, test file parallel structure, and parallel development file organization for extension-based services
- 2025-10-05T23:08:25Z: Added Dose Scheduling Models structure insights from Issue #174 - SwiftData model organization, test file parallel structure, and parallel stream file ownership patterns
- 2025-09-26T01:23:01Z: Added AdherenceInsights structure insights from Issue #57, stream dependency management, critical issue identification workflow, and healthcare app architecture requirements
- 2025-09-23T13:29:15Z: Added ChartDataProcessor structure insights from Issue #55, parallel development architecture, new Models and Services files
- 2025-09-16T22:39:56Z: Added calendar feature structure insights from Issue #42 development
- 2025-09-12T16:35:25Z: Added PM system structure details (231+ files, hooks, settings), dose-tracking epic organization