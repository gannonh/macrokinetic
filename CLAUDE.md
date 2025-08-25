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

### Documentation
```bash
# Generate Swift documentation (if using DocC)
xcodebuild docbuild -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5'

# Or use the convenience script
./scripts/docs.sh
```

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
**Completed**: Foundation & Infrastructure (GitHub Issues #1-4)  
**Next Up**: Authentication & Dose Tracking (GitHub Issues #5-7)

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
- xcbeautify for enhanced test output formatting with Swift Testing support

### Privacy & Security
- SwiftData encryption enabled
- CloudKit private database for user data protection
- Graceful handling of iCloud availability without compromising functionality
- Keychain storage for sensitive data (planned)
- Face ID/Touch ID authentication (planned)
- HIPAA compliance considerations
- App Tracking Transparency implementation

## Development Notes

- Follow TDD approach especially for pharmacokinetic calculations
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

# Technical Learnings & Best Practices

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

# Reminders
- Use NavigationStack instead of NavigationView: https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types
- Always test iCloud sync scenarios: available, unavailable, not signed in
- Swift Testing framework docs: https://developer.apple.com/documentation/testing