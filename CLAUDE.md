# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

JabTracker is a native iOS SwiftUI application for tracking injectable GLP-1 medication doses (Ozempic, Wegovy, Mounjaro) with pharmacokinetic modeling for drug concentration calculations.

**Technology Stack:**
- Framework: SwiftUI (iOS 17.0+)
- Backend: CloudKit (Sync, Storage, User Management)  
- Data: SwiftData + CloudKit Sync (with graceful fallback to local-only storage)
- Charts: Swift Charts
- Health: HealthKit integration
- Auth: Sign in with Apple (sole authentication method)
- Testing: Swift Testing for unit tests, XCUITest for UI tests

## Development Commands

**IMPORTANT:** 
- XcodeBuildMCP provides a range of useful tools for working with the project.

### Building and Running

```bash
# Build the project
xcodebuild -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' build

# Install and launch app on simulator (manual testing)
xcrun simctl install <SIMULATOR_ID> "<APP_PATH>"
xcrun simctl launch <SIMULATOR_ID> com.example.JabTracker
```

### Testing Commands
```bash
# Run all tests (unit + UI)
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5'

# Run only unit tests
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -only-testing:JabTrackerTests

# Run only UI tests (E2E)
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -only-testing:JabTrackerUITests

# Run specific test method
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -only-testing:JabTrackerTests/JabTrackerTests/testUserCreation

# Find available simulators
xcrun simctl list devices | grep iPhone

# Pretty output with xcbeautify (install with: brew install xcbeautify)
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' | xcbeautify

# xcbeautify provides better Swift Testing support than xcpretty
```

### UI Testing with Authentication
```bash
# Launch app in UI testing mode (bypasses real authentication)
app.launchEnvironment["UI_TESTING"] = "true"
app.launchArguments.append("--ui-testing")

# Reset app data for clean test state
app.launchArguments.append("--reset-app-data")
```

### XcodeBuildMCP Authentication Bypass
When using XcodeBuildMCP tools for manual testing or debugging, you can bypass authentication:

```bash
# Launch app with authentication bypass using XcodeBuildMCP
launch_app_sim({ 
  simulatorUuid: "SIMULATOR_UUID", 
  bundleId: "com.gannonhall.JabTracker", 
  args: ["--ui-testing"] 
})

# This will:
# - Skip Sign in with Apple authentication flow
# - Create mock user data (test@uitesting.com, "UI Test User")
# - Go directly to main app interface with all tabs accessible
# - Enable full app functionality for testing without real Apple ID

# Alternative: Build and run with bypass in one step
build_run_sim({ 
  projectPath: "/path/to/JabTracker.xcodeproj", 
  scheme: "JabTracker", 
  simulatorName: "iPhone 15",
  extraArgs: ["--ui-testing"]  # Note: This may not work - use launch_app_sim instead
})
```

### Documentation
```bash
# Generate Swift documentation (if using DocC)
xcodebuild docbuild -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5'

# Or use the convenience script
./scripts/docs.sh
```

### Coverage Policy & Reporting
```bash
# Enable coverage in Xcode scheme (already configured)
# codeCoverageEnabled = "YES" in JabTracker.xcscheme

# Check coverage policy compliance (RECOMMENDED)
./scripts/check-coverage.sh

# Run tests with coverage (automatically enabled)
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5'

# View coverage in Xcode UI:
# 1. Run tests with coverage enabled
# 2. Open Report Navigator (⌘9) 
# 3. Select test result -> Coverage tab

# Generate code coverage reports (EASY WAY - use test script)
./scripts/test.sh unit 1 --coverage     # Unit tests with coverage
./scripts/test.sh all --coverage        # All tests with coverage

# Manual coverage generation (if needed)
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -enableCodeCoverage YES -resultBundlePath /tmp/coverage.xcresult -only-testing:JabTrackerTests
xcrun xccov view --report /tmp/coverage.xcresult

# Generate JSON coverage report with summary
xcrun xccov view --report --json /tmp/coverage.xcresult | jq

# View detailed file-by-file coverage
xcrun xccov view --file-list /tmp/coverage.xcresult
```

**Coverage Policy (SwiftUI-Aware):**
- **Business Logic (90% minimum)**: AuthenticationManager, BiometricAuthManager, DataController, Models
- **View Models (85% minimum)**: ObservableObject classes with business logic (none defined yet)
- **SwiftUI Views**: No coverage requirements (view bodies cannot be unit tested)
- **Overall Coverage**: ~23% (informational only, not a requirement)

See `docs/coverage-policy.md` for detailed requirements and rationale.

### Convenience Scripts
```bash
# Build project
./scripts/build.sh

# Run tests
./scripts/test.sh unit    # Unit tests only
./scripts/test.sh ui      # UI tests only
./scripts/test.sh all     # All tests

# Generate documentation
./scripts/docs.sh

# Run full CI check suite (recommended before PR merge)
./scripts/check-all.sh    # Runs SwiftLint, build, unit tests, UI tests, and SwiftFormat
```

### Local CI Verification
Since GitHub Actions can be unreliable, use the comprehensive check script before merging PRs:

```bash
./scripts/check-all.sh
```

This script runs:
- ✅ SwiftLint code quality checks
- ✅ Build verification  
- ✅ Unit tests (Swift Testing framework)
- ✅ UI tests (XCUITest framework)
- ✅ SwiftFormat style checks (if installed)

**Note:** All scripts use xcbeautify for better output formatting and Swift Testing support.

**Pre-merge checklist:**
1. Run `./scripts/check-all.sh`
2. All checks must pass ✅
3. Fix any issues with `swiftlint --fix` and `swiftformat .`
4. Re-run until all checks pass

### XcodeGen Project Regeneration
This project uses XcodeGen for project file management. **Important**: When adding new Swift files (especially test files), you must regenerate the Xcode project:

```bash
# Regenerate Xcode project after adding new files
xcodegen generate
```

**Common Issue**: New test files not appearing in test runs
- **Symptom**: Tests don't run or show "0 tests executed" even though test files exist
- **Cause**: XcodeGen hasn't included the new files in the Xcode project
- **Solution**: Run `xcodegen generate` then run tests again

**When to regenerate:**
- After adding new Swift files to JabTracker/, JabTrackerTests/, or JabTrackerUITests/
- After modifying project.yml configuration
- If build/test targets seem missing files
- When file references appear broken in Xcode

## Architecture & Code Structure

### SwiftData Models
The app uses three primary SwiftData models with CloudKit sync:
- `User`: Profile information including weight, timezone, medication preferences
  - ✅ `appleUserId` for authentication linking
  - ✅ `updatedAt` for tracking profile modifications
  - ✅ Weight unit conversion between kg/lbs with real-time validation
- `Dose`: Individual dose records with timestamp, amount, injection site, notes
- `MedicationProfile`: Medication details, current dose, refill dates

**DataController Features:**
- Automatic CloudKit sync with iCloud availability detection
- Graceful fallback to local-only storage when iCloud is unavailable
- Real-time sync status monitoring (`SyncStatus` enum)
- User-friendly sync status display with actionable guidance

### Key Components

**Medication Support:**
- Semaglutide (Ozempic, Wegovy) - 7 day half-life, weekly dosing
- Tirzepatide (Mounjaro, Zepbound) - 5 day half-life, weekly dosing  
- Liraglutide (Victoza, Saxenda) - 0.54 day half-life, daily dosing
- Dulaglutide (Trulicity) - 4.7 day half-life, weekly dosing

**Pharmacokinetics Engine:**
Core calculation logic for drug concentration modeling using exponential decay based on medication half-lives. Located in `PharmacokineticsEngine` class.

**Authentication System:**
- `AuthenticationManager`: Handles Sign in with Apple, credential management, state persistence
- `BiometricAuthManager`: Face ID/Touch ID integration with fallback to device passcode  
- `AuthenticationView`: Clean Sign in with Apple UI following HIG
- `UserProfileView`: Complete profile management with weight conversion, validation
- Authentication state persistence across app launches using Keychain

**Navigation Structure:**
TabView with 5 main tabs:
- Dashboard (Home) - Current levels, next dose
- Add Dose - Quick entry and manual logging
- History - Dose tracking and calendar view
- Analytics - Charts and insights using Swift Charts
- Settings - Profile, notifications, export

### Data Flow
1. User logs doses through AddDoseView
2. Doses stored in SwiftData with automatic CloudKit sync (when available)
3. PharmacokineticsEngine calculates real-time concentrations
4. Charts display concentration timeline and trends
5. Notifications remind users of upcoming doses
6. SyncStatusCard displays real-time iCloud sync status to users

### Project Status

**Current Phase**: Core Functionality Implementation  
**Completed**: Foundation & Infrastructure (GitHub Issues #1-4) + ✅ Authentication & User Profile (GitHub Issue #11)  
**Next Up**: User Onboarding Flow & Dose Tracking Features

For detailed progress tracking and roadmap, see `docs/implementation-plan.md`.  
For product vision and feature specifications, see `docs/spec.md`.

### Design System

**Colors:** Primary gradient from #667eea to #764ba2
**Typography:** System fonts with rounded design for large titles
**Components:** Follow Human Interface Guidelines with accessibility support

### Testing Strategy
- Unit tests using Swift Testing framework for modern testing approach
- UI tests using XCUITest for end-to-end user flow testing
- SwiftData model and persistence testing (comprehensive coverage implemented)
- Design system component testing for accessibility and functionality
- ✅ Authentication unit tests (`AuthenticationTests`) - comprehensive coverage
- ✅ Authentication UI tests (`AuthenticationUITests`) - complete E2E testing
- ✅ Biometric authentication testing with mock scenarios
- ✅ Keychain integration security testing
- xcbeautify for enhanced test output formatting with Swift Testing support

### Privacy & Security
- SwiftData encryption enabled
- CloudKit private database for user data protection
- Graceful handling of iCloud availability without compromising functionality
- ✅ Keychain storage for sensitive authentication credentials (implemented)
- ✅ Face ID/Touch ID authentication with BiometricAuthManager (implemented)
- ✅ Sign in with Apple as sole authentication method (implemented)
- ✅ Secure authentication state management with AuthenticationManager (implemented)
- HIPAA compliance considerations
- App Tracking Transparency implementation

## Development Notes

- Follow TDD approach especially for pharmacokinetic calculations
- Implement authentication early to establish user context for all features
- Use environment variables to differentiate test vs production authentication
- Always provide UI testing bypass for authentication flows
- Prioritize accessibility with VoiceOver, Dynamic Type, and Reduced Motion support
- Implement offline-first functionality with CloudKit sync
- Use ProMotion (120Hz) support for smooth animations
- Target < 2 second app launch time and < 50ms calculation updates
- Keep medical accuracy as top priority - validate all pharmacokinetic formulas

## Regulatory Considerations

This app handles medical data and dosing information. Ensure:
- FDA medical device classification compliance
- Clinical validation of pharmacokinetic models
- Proper disclaimers about not replacing medical advice
- Adverse event reporting mechanisms if required

## Resources

- Project Spec: @docs/spec.md
- Implementation Plan: @docs/implementation-plan.md
- GitHub Repo: https://github.com/gannonh/jab-tracker-ios

## Security Implementation Guidelines

- Never log sensitive authentication credentials in production code
- Store Apple ID credentials securely in Keychain with proper access controls
- Implement biometric authentication with proper fallback to device passcode
- Handle authentication errors gracefully with user-friendly guidance messages
- Clear authentication state properly on sign out to prevent credential leakage
- Use `@MainActor` for authentication UI updates to ensure thread safety
- Validate authentication state on app launch for proper flow control
- Implement test authentication bypass for reliable UI testing

# Technical Learnings & Best Practices

## Authentication Testing Patterns
- Use `--ui-testing` launch argument for predictable test authentication
- Reset app data with `--reset-app-data` for clean test states
- Mock authentication in UI tests to avoid Apple ID dependencies
- Separate test user creation for isolated test scenarios
- Handle biometric authentication differently in test vs production
- Use environment variables to differentiate test behavior
- UserDefaults can be unreliable in UI tests - use in-memory storage when needed

## CloudKit + SwiftData Integration
- Always implement graceful fallback when CloudKit is unavailable
- Check for test environment before enabling CloudKit to avoid test conflicts
- Use `@Published` properties for real-time sync status updates
- Provide clear user feedback about sync status with actionable guidance

## Testing Framework Migration
- Swift Testing provides cleaner, more modern test syntax than XCTest
- xcbeautify offers better Swift Testing output support than xcpretty
- Never use `CODE_SIGNING_ALLOWED=NO` for UI tests - prevents app launch
- File-based test organization improves maintainability

## Info.plist Configuration
- Custom Info.plist required for CloudKit background notifications
- `remote-notification` background mode essential for CloudKit push notifications
- XcodeGen's auto-generated Info.plist doesn't handle all CloudKit requirements

## Development Tooling
- xcbeautify > xcpretty for modern Xcode output formatting
- Clean DerivedData resolves filesystem/result bundle issues
- Comprehensive pre-merge checks prevent integration issues

## XcodeGen Workflow
- **CRITICAL**: Always run `xcodegen generate` after adding new Swift files
- Project uses XcodeGen for automatic project file management
- New test files won't appear in test runs until project is regenerated
- Auto-includes all Swift files in respective directories (JabTracker/, JabTrackerTests/, JabTrackerUITests/)

## Authentication Implementation Gotchas
- UI testing with real Sign in with Apple is not feasible - use mock authentication
- Biometric authentication simulator limitations - test on real devices for accuracy
- UserDefaults can be unreliable in UI tests - use in-memory storage when needed
- Authentication state must be checked on app launch for proper flow control
- Face ID prompt timing can cause test flakiness - add appropriate waits and timeouts
- Environment variables and launch arguments are key for test/production differentiation
- Always provide authentication bypass for UI testing to avoid external dependencies
- Keychain access can fail in test scenarios - implement proper error handling

## SwiftData Model Design Best Practices
- **Avoid All-Optional Properties**: Make required fields non-optional with sensible defaults
- **Use Proper Relationship Attributes**: Always specify `@Relationship` with appropriate `inverse` and `deleteRule`
- **Include Apple ID Linking**: Add `appleUserId` field for Sign in with Apple authentication
- **Provide Sensible Defaults**: Use defaults like `UUID()`, `Date()`, and reasonable values for required fields
- **Maintain Audit Trail**: Include `createdAt` and `updatedAt` timestamps for all models
- **Test Model Relationships**: Comprehensive testing of SwiftData relationships prevents runtime issues
- **Use `final` Classes**: Mark SwiftData model classes as `final` for better performance
- **Explicit Default Values**: Set explicit defaults (`= nil`, `= ""`, `= 0.0`) for clarity and consistency

## Code Quality Improvement Patterns
- **Consolidate Duplicate Code**: Look for similar methods and consolidate them (e.g., duplicate sign-in handlers)
- **Remove Unsafe Force Unwrapping**: Replace `fatalError` with graceful error handling in production code
- **Conditional Debug Logging**: Use `#if DEBUG` for development-only console output
- **Model Validation**: Ensure required fields have appropriate defaults rather than optionals
- **Authentication Flow Simplification**: Reduce complexity by consolidating authentication state handling
- **Relationship Configuration**: Fix missing `@Relationship` attributes that cause sync and cascade issues

## SwiftData Model Architecture Lessons
- All-optional model properties create runtime uncertainty and complex nil-checking throughout the app
- Required fields should have non-optional types with sensible defaults to prevent crashes
- Missing authentication linking fields (`appleUserId`) cause integration issues with Sign in with Apple
- Proper relationship configuration with `inverse` prevents cascade delete and CloudKit sync problems
- Code quality improvements often reveal architectural inconsistencies that need addressing
- Medical apps require especially careful data modeling - weight, doses, timestamps must be reliable
- Audit trails (`createdAt`, `updatedAt`) are essential for debugging and data integrity
- Default values should be meaningful - empty strings for required text, sensible numbers for medical data

# Recent Major Improvements

## Issue #16 Code Quality Improvements (PR #17)
**Completed**: August 26, 2025  
**Impact**: Foundational architecture improvements and data integrity fixes

### What Was Fixed
- ✅ **SwiftData Model Optionality**: Changed from all-optional properties to required fields with defaults
- ✅ **Authentication Flow Consolidation**: Removed duplicate sign-in handling methods
- ✅ **Relationship Configuration**: Added proper `@Relationship` attributes with `inverse` parameters  
- ✅ **Apple ID Integration**: Added missing `appleUserId` field for authentication linking
- ✅ **Error Handling**: Replaced unsafe `fatalError` patterns with graceful error handling
- ✅ **Test Suite Updates**: Updated all tests to work with improved model structure

### Architectural Lessons Learned
- All-optional SwiftData models create unnecessary complexity and runtime uncertainty
- Missing relationship configurations cause CloudKit sync and cascade delete issues
- Authentication flows can accumulate duplicate code that needs regular consolidation
- Medical apps need especially reliable data models with meaningful defaults
- Code quality analysis reveals architectural decisions that need documentation

### Files Updated
- `Models/User.swift`, `Models/Dose.swift`, `Models/MedicationProfile.swift` - Fixed optionality
- `AuthenticationManager.swift` - Consolidated duplicate methods, improved error handling
- `DataController.swift` - Enhanced CloudKit configuration
- All test files - Updated for new model structure
- Documentation updated to reflect actual implementation patterns

This work established a much stronger foundation for continued feature development.

# Reminders
- Use NavigationStack instead of NavigationView: https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types
- Always test iCloud sync scenarios: available, unavailable, not signed in
- Swift Testing framework docs: https://developer.apple.com/documentation/testing
- XcodeBuildMCP provides a range of useful tools for working with the project.
- Simulator name always includes OS: `iPhone 15,OS=17.5`
- Easiest way to run tests is using the convenience script:
  - `./scripts/test.sh unit 1    # Unit tests only on iPhone 15`
  - `./scripts/test.sh ui 1     # UI tests only on iPhone 15`
  - `./scripts/test.sh all 1    # All tests on iPhone 15`