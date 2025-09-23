---
created: 2025-09-11T16:54:56Z
last_updated: 2025-09-23T14:14:43Z
version: 1.6
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

## Testing Framework Insights (Issue #41 Learnings)
### CloudKit vs Testing
- **CloudKit Requirements**: All relationships need proper inverses, but tests should disable CloudKit entirely
- **Test Environment Detection**: DataController properly detects test environment and disables CloudKit automatically
- **SwiftData Testing**: Requires proper ModelContainer setup in tests (see testing-config.md for critical anti-patterns)

### SwiftUI Accessibility Hierarchy (Critical for UI Tests)
- **List Rendering**: SwiftUI List renders as CollectionView (not Table/ScrollView as expected)
- **NavigationStack**: Renders as CollectionView in accessibility hierarchy
- **Element Queries**: XCUIElementQuery has `.count` property, not `.isEmpty` (SwiftLint auto-fix incorrectly converts)
- **Text Field Interaction**: XCUITest text clearing requires delete character string approach, not selectAll() or keys["Delete"]

### Framework Limitations and Workarounds
- **SwiftLint Auto-fix Issues**: "Empty Count" rule breaks XCUIElementQuery usage by converting `.count == 0` to `.isEmpty`
- **Element Targeting**: SwiftUI accessibility hierarchy doesn't match visual structure - requires debug-first approach
- **Test Reliability**: Complex element targeting needs systematic debugging with TestUtilities.debugElements()

### SwiftUI Calendar Integration (Issue #42 Learnings)
- **SwiftUI Calendar Rendering**: Native Calendar components in XCUITest environment require specialized element finding
- **XCUIElementQuery vs Array**: XCUIElementQuery doesn't have `.isEmpty` property but Array does - causes compilation errors
- **SwiftLint Integration Conflicts**: Remove `empty_count` rule to prevent UI testing framework compatibility issues
- **Accessibility Identifier Reliability**: Complex SwiftUI hierarchies may have unreliable accessibility identifiers requiring fallback strategies

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
- **SwiftLint Type Body Length**: Large service classes require specific disable syntax (`// swiftlint:disable:next type_body_length`)
- **Medical Service Classes**: ChartDataProcessor and similar services may exceed default line limits for comprehensive medical functionality
- **Targeted Disables**: Use `swiftlint:disable:next` instead of blanket disables to maintain code quality standards

### Testing Data Generation Patterns
- **Test Data Generation**: Sparse vs dense data generation impacts interpolation algorithm testing effectiveness
- **Medical Test Scenarios**: Edge cases in medical calculations require comprehensive test data patterns
- **Vulnerability Testing**: Security testing requires intentionally invalid data to verify crash prevention

## Update History
- 2025-09-23T14:14:43Z: Added Security & Crash Prevention section with Swift Charts security patterns, SwiftLint management, and testing patterns from Issue #55 security fixes
- 2025-09-23T13:29:15Z: Added Medical Visualization section with Swift Charts integration patterns from Issue #55, XcodeGen project management insights
- 2025-09-16T22:39:56Z: Added SwiftUI calendar integration patterns from Issue #42, XCUIElementQuery limitations
- 2025-09-15T18:21:44Z: Added testing framework insights from Issue #41, SwiftUI accessibility hierarchy patterns
- 2025-09-12T16:35:25Z: Added Claude Code PM system (CCPM) details - 49 commands, agent system, workflow integration