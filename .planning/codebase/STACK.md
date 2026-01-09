---
name: Technology Stack
created: 2025-12-22
last_modified: 2026-01-09
---

# Technology Stack

## Languages

**Primary:**
- Swift 5.9+ - All application code (`project.yml`, all `.swift` files)

**Secondary:**
- Python 3 - Data processing scripts (`scripts/process_usda_data.py`, `scripts/process-off-data.py`)

## Runtime

**Environment:**
- iOS 17.0+ (minimum deployment target) - `project.yml` line 5
- Xcode 26.2 required - `project.yml` line 8

**Package Manager:**
- None (Apple frameworks only)
- No Package.swift, Podfile, or Cartfile

## Frameworks

**Core:**
- SwiftUI - UI Framework (137+ files)
- SwiftData - Data persistence with `@Model` macro (`JabTracker/DataController.swift`, `JabTracker/Models/*.swift`)
- CloudKit - iCloud sync (`JabTracker/JabTracker.entitlements`, `JabTracker/DataController.swift`)

**Testing:**
- Swift Testing - Unit tests (iOS 17+ `@Test` macro) - `JabTrackerTests/`
- XCUITest - UI/E2E tests - `JabTrackerUITests/`

**Build/Dev:**
- XcodeGen - Project generation (`project.yml`)
- SwiftLint - Code linting (`.swiftlint.yml`)
- SwiftFormat - Code formatting
- xcbeautify - Build output formatting

## Key Dependencies

**Zero External Dependencies** - Project uses only Apple frameworks.

**Critical Apple Frameworks:**
- AuthenticationServices - Sign in with Apple (`JabTracker/AuthenticationManager.swift`)
- LocalAuthentication - Face ID/Touch ID (`JabTracker/BiometricAuthManager.swift`)
- StoreKit 2 - Subscription management (`JabTracker/Services/SubscriptionManager.swift`)
- Swift Charts - Data visualization (`JabTracker/Views/Analytics/`)
- UserNotifications - Dose/meal reminders (`JabTracker/Services/NotificationService.swift`)
- HealthKit - Weight data integration (`JabTracker/JabTracker.entitlements`)

**Infrastructure:**
- SQLite3 - Local food database with FTS5 (`JabTracker/Services/LocalFoodDatabase.swift`)
- Foundation - Core APIs, URL networking

## Configuration

**Environment:**
- No external environment variables required
- Launch arguments for test modes (`--ui-testing`, `--reset-app-data`, `--seed-test-7d`)
- CloudKit container: `iCloud.com.gannonhall.JabTracker` (`JabTracker/JabTracker.entitlements`)

**Build:**
- `project.yml` - XcodeGen project configuration
- `JabTracker/Info.plist` - App metadata, permissions, URL schemes
- `JabTracker/JabTracker.entitlements` - Capabilities (CloudKit, HealthKit, Sign in with Apple)
- `JabTrackerStoreKit.storekit` - StoreKit 2 test configuration
- `.swiftlint.yml` - Code quality rules (root + directory-specific overrides)

## Platform Requirements

**Development:**
- macOS (Xcode 26.2)
- No external dependencies or Docker required

**Production:**
- iOS 17.0+ devices
- iCloud account (optional, for sync)
- App Store distribution via TestFlight

---

*Stack analysis: 2026-01-09*
*Update after major dependency changes*
