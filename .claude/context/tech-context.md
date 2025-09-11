---
created: 2025-09-11T16:54:56Z
last_updated: 2025-09-11T20:59:06Z
version: 1.1
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
- **Charts**: Swift Charts (for analytics visualization)
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

## Data Architecture
- **SwiftData Models**: CloudKit-compatible with default values
- **Relationship Management**: Proper inverse relationships and cascade rules
- **Sync Strategy**: Real-time CloudKit sync with status monitoring
- **Data Validation**: Form validation with user-friendly error handling

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
- **Claude Code**: AI-assisted development with comprehensive PM system
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