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

### Launch Arguments for Testing

The app supports several launch arguments for testing and development:

**`--ui-testing`**:
- Bypasses real Sign in with Apple authentication
- Creates mock user (`test@uitesting.com`, "UI Test User")
- Used by XCUITest for reliable automated testing
- Can be enabled in Xcode scheme for manual testing without authentication

**`--reset-app-data`**:
- Clears all SwiftData users from database on launch
- Clears onboarding completion status from UserDefaults
- Resets to fresh app state (like first-time install)
- Useful for testing onboarding and first-run experiences

**`--force-onboarding`**:
- Forces onboarding flow to show even if user has completed it
- Useful for repeatedly testing onboarding flow during development
- Overrides normal onboarding completion logic

**Usage Patterns:**

**In XCUITest:**
```swift
app.launchArguments = ["--ui-testing", "--reset-app-data"]
// Bypasses auth + gives fresh state for each test
```

**In Xcode Scheme (for Manual Testing):**
- Edit Scheme → Run → Arguments → Arguments Passed On Launch
- Enable flags as needed for different testing scenarios
- `--ui-testing`: Skip authentication during development
- `--reset-app-data`: Test first-run experience
- `--force-onboarding`: Test onboarding flow repeatedly

**Production:**
- All flags should be disabled for normal user experience

### XcodeBuildMCP Simulator Usage

**IMPORTANT**: When using XcodeBuildMCP tools, prefer `simulatorId` over `simulatorName` to avoid OS version parsing issues:

```bash
# ❌ This can cause "option 'OS' may only be provided once" errors
build_run_sim({ simulatorName: "iPhone 15,OS=17.5" })

# ✅ Use UUID instead (get from list_sims)
build_run_sim({ simulatorId: "336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB" })

# Get available simulator UUIDs
list_sims()
```

**Simulator UUID vs Name:**
- `simulatorName`: "iPhone 15" (without OS version) - can be unreliable
- `simulatorId`: Full UUID from `list_sims()` - always works correctly
- OS version is automatically detected when using UUID

### Documentation
```bash
# Generate Swift documentation (if using DocC)
xcodebuild docbuild -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5'

# Or use the convenience script
./scripts/docs.sh
```

### Coverage Policy & Reporting

- Coverage config: `coverage-config.json`
- Coverage policy: `coverage-policy.md`

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

# COVERAGE ANALYSIS TOOLS (use these for detailed investigation)
./scripts/coverage-detail.sh                    # Full coverage report
./scripts/coverage-detail.sh DataController     # Specific file coverage
./scripts/coverage-detail.sh AuthenticationManager  # Specific file coverage
./scripts/coverage-json.sh --summary           # Quick file overview sorted by coverage
./scripts/coverage-json.sh --functions         # Show uncovered functions only
./scripts/coverage-json.sh DataController      # JSON data for specific file

# Manual coverage generation (if needed)
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -enableCodeCoverage YES -resultBundlePath /tmp/coverage.xcresult -only-testing:JabTrackerTests
xcrun xccov view --report /tmp/coverage.xcresult

# Raw xccov commands (coverage-detail.sh and coverage-json.sh are easier)
xcrun xccov view --report --json /tmp/coverage.xcresult | jq
xcrun xccov view --file-list /tmp/coverage.xcresult
```

**Coverage Policy (SwiftUI-Aware):**
- **Business Logic (90% minimum)**: AuthenticationManager, BiometricAuthManager, DataController, Models
- **View Models (85% minimum)**: ObservableObject classes with business logic (none defined yet)
- **SwiftUI Views**: No coverage requirements (view bodies cannot be unit tested)
- **Overall Coverage**: ~23% (informational only, not a requirement)

See `docs/coverage-policy.md` for detailed requirements and rationale.

#### Coverage Analysis Tips

**Understanding xccov Output:**
- Coverage shows function-level and line-level detail
- `0.00% (0/X)` means completely uncovered function with X executable lines
- Private methods need indirect testing through public methods that call them
- Async methods may need `Task.sleep()` waits in tests for proper coverage

**Key Coverage Targets from Analysis:**
- `DataController.checkiCloudStatus()`: 0% (30 lines) - Test via `retryCloudKitSetup()`  
- `DataController.checkCloudKitStatus()`: 0% (5 lines) - Test via initialization paths
- `AuthenticationManager.resetAppData()`: 0% (20 lines) - Test via `--reset-app-data` argument
- `AuthenticationManager.processAppleIDCredential(_:)`: 0% (32 lines) - Test via delegate methods

**Common Coverage Issues:**
- Result bundle not found: Run tests with `--coverage` first
- Private method coverage: Use public methods that invoke them
- Async method coverage: Add `Task.sleep()` waits in tests
- Delegate method coverage: Create proper mock controllers/requests

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
- Details: `docs/testing-strategy.md`

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

## GitHub Sub-Issue Management (gh-sub-issue Integration)

Claude Code: Use the `gh-sub-issue` GitHub CLI extension to maintain hierarchical task structures (epic → tasks) and compute progress metrics automatically.

### TL;DR Essentials
- Parent issue = "Epic" / feature container (title prefix: `Epic:` or `Feature:`)
- Sub-issues = actionable tasks (title prefix: none / verb-led)
- Commands: `create` (new sub-issue), `add` (link existing), `list` (query state / metrics), `remove` (unlink)
- Always prefer JSON output for automation (`--json number,title,state` + meta fields)
- Progress metric: `openCount/total` from `list --json parent.number,total,openCount`
- Keep parent issue body updated with an auto-generated checklist (OPTIONAL enhancement)

### Installation (idempotent)
```bash
gh extension install yahsan2/gh-sub-issue  # safe if already installed
```

### Core Command Patterns
```bash
# Create new sub-issue (preferred way to add work)
gh sub-issue create --parent <PARENT_NUM> --title "Implement dose history export" --label backend

# Link existing issue
gh sub-issue add <PARENT_NUM> <CHILD_NUM>

# List (TTY human view)
gh sub-issue list <PARENT_NUM> --state all

# List (machine JSON)
gh sub-issue list <PARENT_NUM> --json number,title,state,parent.number,total,openCount

# Remove linkage (keeps child issue alive)
gh sub-issue remove <PARENT_NUM> <CHILD_NUM> --force
```

### JSON Automation Examples
Progress snapshot (Bash):
```bash
progress_json=$(gh sub-issue list "$PARENT" --json parent.number,total,openCount 2>/dev/null)
total=$(echo "$progress_json" | jq -r '.parent.total // .total // 0')
open=$(echo "$progress_json" | jq -r '.parent.openCount // .openCount // 0')
echo "EPIC #$PARENT: $((total-open)) closed / $total total ($open open)"
```

Enumerate open tasks (titles only):
```bash
gh sub-issue list "$PARENT" --state open --json number,title | jq -r '.subIssues[] | "#\(.number) - \(.title)"'
```

### Repository Conventions
- Parent (epic) titles: `Epic: <High-Level Goal>` or `Feature: <User-Facing Capability>`
- Sub-issue titles: Imperative, single responsibility, fits in < 80 chars
- Labels:
  - `epic` (apply manually to parent issues only)
  - Functional area labels (e.g. `auth`, `persistence`, `ui`, `pharmacokinetics`)
  - Priority (`p0`, `p1`, `p2`) optional
- Milestones: attach to parent; inherit manually for critical children
- Close rule: Parent closes automatically only when all sub-issues closed (enforced manually / by future automation script)

### Recommended Workflow for New Feature
1. Create parent epic (manual): `gh issue create --title "Epic: Onboarding Flow" --body "Summary..." --label epic,onboarding`
2. Decompose into concrete tasks: use `gh sub-issue create` for each
3. Link any pre-existing issues with `gh sub-issue add`
4. Periodically compute progress (script snippet above) → update epic body checklist (optional)
5. When all sub-issues closed, verify no hidden work → close epic

### Epic Body Checklist Pattern (Optional Automation)
Maintain a checklist block delimited by HTML comments to allow safe regeneration.
```
<!-- sub-issue-checklist:start -->
- [ ] #123 Implement core DataController sync improvements
- [x] #140 Add unit tests for BiometricAuthManager
<!-- sub-issue-checklist:end -->
```
Automation script can:
1. Fetch current list JSON
2. Rebuild checklist lines with `[ ]` or `[x]`
3. Replace block via sed/perl; post with `gh issue edit`

### Integration Guidelines for Claude
- Prefer creating sub-issues instead of expanding epic description with untracked tasks.
- Use JSON mode for any reasoning requiring counts or progress metrics.
- Before starting new task work: confirm it's linked under an epic (create if missing).
- Avoid nesting >1 level (tool supports only single parent layer effectively for now).
- If an issue spans multiple epics, split into smaller issues rather than dual-link.

### Edge Cases & Handling
- Parent not found: validate existence via `gh issue view <num>` before sub-issue operations.
- Cross-repo linking not currently used; omit `--repo` unless explicitly needed later.
- Removing a sub-issue does not close or delete; verify if re-homing to a different epic is required and then `add` to new parent.
- Large epics: paginate manually with `--limit` if output > default (30); run multiple list calls if needed.

### Minimal Decision Heuristics (for Claude Automation)
| Situation                             | Action                                        |
| ------------------------------------- | --------------------------------------------- |
| Need to track new chunk of work       | `sub-issue create` under appropriate epic     |
| Existing issue logically part of epic | `sub-issue add`                               |
| Epic progress update needed           | `sub-issue list --json` → recompute checklist |
| Child out of scope now                | `sub-issue remove` (keep issue open)          |
| Epic has 0 openCount                  | Propose closing epic                          |

### Quick Sanity Check Command
```bash
gh sub-issue list <PARENT> --json total,openCount || echo "Sub-issue extension or parent missing"
```

### Troubleshooting Cheatsheet
| Symptom                        | Likely Cause                | Resolution                  |
| ------------------------------ | --------------------------- | --------------------------- |
| `gh: Could not find extension` | Extension not installed     | Re-run install command      |
| Empty JSON fields              | Missing `--json` args       | Supply explicit field list  |
| `parent issue not found`       | Wrong number / private repo | Verify number & permissions |
| `rate limit exceeded`          | Heavy automation loop       | Add delays / ensure auth    |

### Future Automation Opportunities
- Auto-close epic when all children complete
- CI job generating progress badge (open vs total)
- Weekly epic status summary comment bot

This section is the authoritative minimal contract for hierarchical issue management tooling in this repo.

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

## Architectural Lessons Learned
- All-optional SwiftData models create unnecessary complexity and runtime uncertainty
- Missing relationship configurations cause CloudKit sync and cascade delete issues
- Authentication flows can accumulate duplicate code that needs regular consolidation
- Medical apps need especially reliable data models with meaningful defaults
- Code quality analysis reveals architectural decisions that need documentation

## User Onboarding Implementation Patterns
- **Step-Based Navigation**: Use enum-driven state machines for multi-step flows (OnboardingStep enum with computed properties)
- **Coordinator Pattern**: Separate navigation logic (OnboardingCoordinator) from business logic (OnboardingViewModel)
- **Testing Arguments**: Command-line arguments are essential for reliable UI testing (`--force-onboarding`, `--ui-testing`)
- **Permission Flow**: Always explain value proposition before requesting permissions (notifications, HealthKit)
- **State Persistence**: Use UserDefaults for completion tracking, SwiftData for user-generated content
- **Medical Data Modeling**: Enum-based medication system with computed properties ensures data consistency and medical accuracy

## XcodeBuildMCP UI Testing & Accessibility

### describe_ui Tool for Precise Element Location
**CRITICAL**: Always use `describe_ui` to get precise coordinates for UI interactions instead of guessing from screenshots.

```bash
# Get complete accessibility hierarchy with precise coordinates
describe_ui({ simulatorUuid: "SIMULATOR_UUID" })

# Returns JSON with AXFrame data for every accessible element
# Use frame coordinates for interactions: center = (x + width/2, y + height/2)
```

**Key Benefits:**
- **Precise Coordinates**: Exact pixel locations for tap, swipe, and gesture actions
- **Accessibility Identifiers**: Find elements by their `AXUniqueId` for reliable test selectors
- **Element State**: See if elements are enabled, selected, or have specific values
- **Element Types**: Distinguish between Button, TextField, Group, StaticText, etc.

### Accessibility Configuration Requirements
For `describe_ui` to work properly, the simulator must have accessibility enabled:

**Common Issue**: `describe_ui` returns empty JSON hierarchy
- **Cause**: Accessibility not properly configured in simulator
- **Solution**: Enable accessibility via command line:
```bash
xcrun simctl spawn 336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB defaults write com.apple.Accessibility VoiceOverTouchEnabled -bool true

# Then restart the app:
stop_app_sim({ simulatorUuid: "336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB", bundleId: "com.gannonhall.JabTracker" })
launch_app_sim({ simulatorUuid: "336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB", bundleId: "com.gannonhall.JabTracker", args: ["--ui-testing", "--force-onboarding"] })
```

After this, `describe_ui` will return proper accessibility hierarchy with full coordinates and element data.

### UI Testing Element Selector Patterns
Based on onboarding flow implementation analysis:

**Dose Selection Components:**
- Dose buttons use pattern: `dose-button-{amount}` (e.g., `dose-button-1.0`, `dose-button-0.25`)
- NOT TextField with `dose-amount-input` - use individual dose buttons instead
- Each dose button shows selected state in `AXValue` field

**Medication Selection:**
- Medication buttons use pattern: `medication-{medication}` (e.g., `medication-semaglutide`)
- Selection state indicated in `AXValue`: "Selected" or "Not selected"

**Navigation Elements:**
- Continue button: `onboarding-continue-button`
- Back button: `onboarding-back-button`
- Progress indicator: `onboarding-progress`

**Common UI Testing Mistakes:**
- Looking for TextField when implementation uses Button components
- Assuming element visibility without checking if scrolling is required
- Using screenshots for coordinates instead of `describe_ui` data

## Medication Profile Management ✅

### Core Medication Types
The app supports exactly 4 GLP-1 medications with medically accurate properties:
- **Semaglutide** (Ozempic/Wegovy): 7-day half-life, 0.25-2.4mg doses, weekly
- **Tirzepatide** (Mounjaro/Zepbound): 5-day half-life, 2.5-15mg doses, weekly
- **Liraglutide** (Victoza/Saxenda): 0.54-day half-life, 0.6-3.0mg doses, daily
- **Dulaglutide** (Trulicity): 4.7-day half-life, 0.75-4.5mg doses, weekly

### Calculation Services (Implemented)
- **ReconstitutionCalculator**: For compounded medications - calculates water volume and units per dose
  - Validates vial strength, target dose, and water volume
  - Returns units per dose, concentration, and total units
  - Common scenarios pre-calculated for quick reference
- **PenClickCalculator**: For branded pens - calculates clicks needed for dose adjustments
  - Supports all major pen types (Ozempic, Wegovy, Mounjaro, Victoza, Saxenda, Trulicity)
  - Handles both adjustable and fixed-dose pens
  - Medication-specific pen recommendations
- **MedicationManager**: CRUD operations for medication profiles with validation
  - Profile creation with compounding/pen support
  - Dose validation against medication ranges
  - Escalation dose recommendations
  - Refill date tracking

### SwiftData Model Enhancements ✅
- Enhanced `MedicationProfile` with new fields:
  - `isCompounded`: Boolean for medication type
  - `vialStrength` & `reconstitutionVolume`: For compounded meds
  - `penType`: For branded pen tracking
  - `notes`, `createdAt`, `updatedAt`: Audit and user data
- `Medication` enum already exists with computed medical properties
- Integrated with existing CloudKit sync and User relationships

### Testing Coverage ✅
- **ReconstitutionCalculatorTests**: 11 comprehensive tests for all calculation scenarios
- **PenClickCalculatorTests**: 15 tests covering all pen types and edge cases
- Medical accuracy validated with real-world dosing scenarios
- Performance targets met: <50ms calculation updates

# Reminders
- Use NavigationStack instead of NavigationView: https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types
- Always test iCloud sync scenarios: available, unavailable, not signed in
- Swift Testing framework docs: https://developer.apple.com/documentation/testing
- XcodeBuildMCP provides a range of useful tools for working with the project.
- Simulator name always includes OS: `iPhone 15,OS=17.5`
- **ALWAYS use `describe_ui` for precise coordinates** - never guess from screenshots
- **Medical accuracy is critical** - validate all calculations and dose ranges
- Easiest way to run tests is using the convenience script:
  - `./scripts/test.sh unit 1    # Unit tests only on iPhone 15`
  - `./scripts/test.sh ui 1     # UI tests only on iPhone 15`
  - `./scripts/test.sh all 1    # All tests on iPhone 15`