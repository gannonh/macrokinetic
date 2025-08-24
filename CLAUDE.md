# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

JabTracker is a native iOS SwiftUI application for tracking injectable GLP-1 medication doses (Ozempic, Wegovy, Mounjaro) with pharmacokinetic modeling for drug concentration calculations.

**Technology Stack:**
- Framework: SwiftUI (iOS 16.0+)
- Backend: CloudKit (Sync, Storage, User Management)
- Data: Core Data + CloudKit Sync (NSPersistentCloudKitContainer)
- Charts: Swift Charts
- Health: HealthKit integration
- Auth: Sign in with Apple (sole authentication method)

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15' build

# Install and launch app on simulator (manual testing)
xcrun simctl install <SIMULATOR_ID> "<APP_PATH>"
xcrun simctl launch <SIMULATOR_ID> com.example.JabTracker
```

### Testing Commands
```bash
# Run all tests (unit + UI)
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15'

# Run only unit tests
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:JabTrackerTests

# Run only UI tests (E2E)
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:JabTrackerUITests

# Run specific test method
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:JabTrackerTests/JabTrackerTests/testUserCreation

# Find available simulators
xcrun simctl list devices | grep iPhone

# Pretty output with xcpretty (install with: gem install xcpretty)
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15' | xcpretty --test --color

# Generate HTML test report
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15' | xcpretty --report html --output build/reports/tests.html
```

### Documentation
```bash
# Generate Swift documentation (if using DocC)
xcodebuild docbuild -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15'

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
- ✅ Unit tests
- ✅ UI tests
- ✅ SwiftFormat style checks (if installed)

**Pre-merge checklist:**
1. Run `./scripts/check-all.sh`
2. All checks must pass ✅
3. Fix any issues with `swiftlint --fix` and `swiftformat .`
4. Re-run until all checks pass

## Architecture & Code Structure

### Core Data Models
The app uses three primary Core Data entities:
- `User`: Profile information including weight, timezone, medication preferences
- `Dose`: Individual dose records with timestamp, amount, injection site, notes
- `MedicationProfile`: Medication details, current dose, refill dates

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
2. Doses stored in Core Data with CloudKit sync
3. PharmacokineticsEngine calculates real-time concentrations
4. Charts display concentration timeline and trends
5. Notifications remind users of upcoming doses

### Key Features to Implement

**Phase 1 (MVP):**
- Core Data setup with User/Dose/MedicationProfile entities
- Sign in with Apple authentication
- Face ID/Touch ID for app access security
- Single medication support (start with semaglutide)
- Basic dose entry and history
- Concentration calculations with PharmacokineticsEngine
- Simple local notifications for dose reminders

**Phase 2:**
- Multiple medication support with enum-based medication definitions
- Swift Charts integration for concentration timeline
- PDF export using PDFKit for healthcare provider reports
- CloudKit sync for multi-device support
- HealthKit integration for weight/health data

### Design System

**Colors:** Primary gradient from #667eea to #764ba2
**Typography:** System fonts with rounded design for large titles
**Components:** Follow Human Interface Guidelines with accessibility support

### Testing Strategy
- Unit tests for pharmacokinetic calculations (100% coverage goal)
- UI tests for critical user flows (90% coverage goal)
- Core Data operations testing (95% coverage goal)
- XCTest framework for unit testing, XCUITest for UI testing

### Privacy & Security
- Core Data encryption enabled
- Keychain storage for sensitive data
- Face ID/Touch ID authentication
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
- GitHub Repo: https://github.com/gannonh/jab-tracker-ios

# Reminders
- Use NavigationStack instead of NavigationBView: https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types