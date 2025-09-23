## Development Commands

### Convenience Scripts

**IMPORTANT**: It is highly recommended to use the provided **Convenience Scripts** for building, testing, and other common tasks. These scripts handle logging, formatting, and other best practices automatically.

#### Building

```bash
# Build project
./scripts/build.sh
```
#### Testing

```bash
# Run tests with automatic logging to ./logs directory
./scripts/test.sh unit 1              # Unit tests with logging
./scripts/test.sh ui 1 OnboardingUITests  # Run specific UI test class (RECOMMENDED)
./scripts/test.sh ui 1 OnboardingUITests/testCompleteOnboardingFlow  # Run specific UI test method
./scripts/test.sh unit 1 --coverage   # Unit tests with coverage
./scripts/test.sh unit 1 --no-log     # Unit tests without logging
./scripts/test.sh unit 1 --log-only   # Unit tests with logging but no console output
./scripts/test.sh --help              # Show all available options

# ⚠️  AVOID: Running ALL UI tests (very slow, use only for final checks)
# ./scripts/test.sh ui 1              # Takes 10+ minutes, use sparingly

# View test results
cat logs/latest/raw_output.txt           # Latest test output
```
#### Fulll CI Check Suite

```bash
# Run full CI check suite (recommended before PR merge)
./scripts/check-all.sh --skip-ui   # Runs SwiftLint, build, unit tests, UI tests, and SwiftFormat
```

This script runs:
- ✅ SwiftLint code quality checks
- ✅ Build verification
- ✅ Unit tests (Swift Testing framework)
- ✅ UI tests (XCUITest framework)
- ✅ SwiftFormat style checks (if installed)

**Note:** All scripts use xcbeautify for better output formatting and Swift Testing support.

**Pre-merge checklist:**
1. Run `./scripts/check-all.sh --skip-ui`
2. All checks must pass ✅
3. Fix any issues with `swiftlint --fix` and `swift-format --in-place --recursive .`
4. Re-run until all checks pass

### Direct XcodeBuild Commands

**IMPORTATNT**: It is highly recommended to use the provided convenience scripts described above instead of these direct commands. They are provided here as a fallback and for reference.

#### Building the Project

```bash
# Build the project
xcodebuild -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' build

# Install and launch app on simulator (manual testing)
xcrun simctl install <SIMULATOR_ID> "<APP_PATH>"
xcrun simctl launch <SIMULATOR_ID> com.example.JabTracker
```

#### Testing Commands
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

#### UI Testing with Authentication
```bash
# Launch app in UI testing mode (bypasses real authentication)
app.launchEnvironment["UI_TESTING"] = "true"
app.launchArguments.append("--ui-testing")

# Reset app data for clean test state
app.launchArguments.append("--reset-app-data")
```

#### XcodeBuildMCP Authentication Bypass
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

