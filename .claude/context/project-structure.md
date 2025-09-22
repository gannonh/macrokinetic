---
created: 2025-09-11T16:54:56Z
last_updated: 2025-09-22T14:31:53Z
version: 1.3
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
│   └── MedicationProfile.swift # Medication profile model
├── Views/                    # SwiftUI view layer
│   ├── Authentication/      # Auth-related views
│   ├── Onboarding/         # User onboarding flow
│   ├── Settings/           # Settings and profile management
│   └── Dashboard/          # Main dashboard views
├── Services/               # Business logic and services
│   ├── AnalyticsService.swift        # Cross-model analytics coordination (NEW)
│   ├── AuthenticationManager.swift
│   ├── BiometricAuthManager.swift
│   └── MedicationManager.swift
└── App/                   # App-level configuration
    ├── JabTrackerApp.swift # Main app entry point
    └── DataController.swift # SwiftData + CloudKit setup
```

## Testing Structure
- **JabTrackerTests/**: Swift Testing framework unit tests
- **JabTrackerUITests/**: XCUITest end-to-end testing
- **File-based organization**: Tests organized by feature area
- **Analytics Integration Tests**: AnalyticsServiceIntegrationTests.swift for cross-model testing (NEW)
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

## Update History
- 2025-09-16T22:39:56Z: Added calendar feature structure insights from Issue #42 development
- 2025-09-12T16:35:25Z: Added PM system structure details (231+ files, hooks, settings), dose-tracking epic organization