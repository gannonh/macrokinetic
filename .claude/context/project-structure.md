---
created: 2025-09-11T16:54:56Z
last_updated: 2025-09-23T13:29:15Z
version: 1.4
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
│   │   └── dose-tracking/     # Current epic with 9 tasks and analysis
│   ├── hooks/                 # Development workflow hooks (NEW)
│   ├── prds/                  # Product Requirements Documents
│   ├── rules/                 # Development rules and guidelines (10+ rule files)
│   ├── scripts/               # PM automation scripts (shell implementations)
│   └── settings.json          # PM system configuration (NEW)
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
│   ├── ChartDataProcessor.swift      # Core chart data transformation service (Issue #55)
│   ├── ChartDataProcessor+Filtering.swift # Filtering and aggregation extensions (Issue #55)
│   └── ChartDataProcessor+Interpolation.swift # Advanced interpolation methods (Issue #55)
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

## Update History
- 2025-09-23T13:29:15Z: Added ChartDataProcessor structure insights from Issue #55, parallel development architecture, new Models and Services files
- 2025-09-16T22:39:56Z: Added calendar feature structure insights from Issue #42 development
- 2025-09-12T16:35:25Z: Added PM system structure details (231+ files, hooks, settings), dose-tracking epic organization