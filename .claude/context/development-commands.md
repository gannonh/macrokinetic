---
created: 2025-12-19T14:56:55Z
last_updated: 2025-12-19T14:56:55Z
---

# Development Commands

## Quick Reference

| Task | Command |
|------|---------|
| Build | `./scripts/build.sh` |
| Unit tests | `./scripts/test.sh unit 1` |
| UI tests (specific) | `./scripts/test.sh ui 1 OnboardingUITests` |
| Full CI check | `./scripts/check-all.sh --skip-ui` |
| Regenerate project | `xcodegen generate` |
| Lint fix | `swiftlint --fix` |

## Building

### Using Script (Recommended)
```bash
./scripts/build.sh
```

### Direct xcodebuild
```bash
xcodebuild -scheme JabTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' \
  build
```

## Testing

### Unit Tests

```bash
# Run all unit tests
./scripts/test.sh unit 1

# Run specific test class
./scripts/test.sh unit 1 ScheduleServiceTests

# Run with coverage
./scripts/test.sh unit 1 --coverage

# Run without logging
./scripts/test.sh unit 1 --no-log
```

### UI/E2E Tests

```bash
# Run specific test class (RECOMMENDED)
./scripts/test.sh ui 1 OnboardingUITests

# Run specific test method
./scripts/test.sh ui 1 OnboardingUITests/testCompleteOnboardingFlow

# Reset simulator before test
./scripts/test.sh ui 1 OnboardingUITests --reset

# AVOID: Running all UI tests (very slow, 10+ minutes)
# ./scripts/test.sh ui 1
```

### Test Logs

All tests log to `./logs/` automatically:

```bash
# View latest output
cat logs/latest/raw_output.txt

# Open in Xcode Results Browser
open logs/latest/results.xcresult

# Search for debug output
grep "DEBUG" logs/latest/raw_output.txt
```

## Coverage

```bash
# Check coverage policy compliance
./scripts/check-coverage.sh

# Detailed coverage analysis
./scripts/coverage-detail.sh

# JSON coverage output
./scripts/coverage-json.sh --summary

# Validate coverage configuration
./scripts/check-coverage-config.sh
```

## Quality Checks

### Full CI Suite
```bash
# Run everything except UI tests
./scripts/check-all.sh --skip-ui
```

This runs:
1. SwiftLint code quality
2. Build verification
3. Unit tests
4. SwiftFormat checks

### Individual Checks

```bash
# SwiftLint
swiftlint

# SwiftLint with auto-fix
swiftlint --fix

# SwiftFormat check
swift-format lint --recursive .

# SwiftFormat auto-fix
swift-format --in-place --recursive .
```

## XcodeGen

**CRITICAL**: Run after adding new Swift files:

```bash
xcodegen generate
```

Without this, new files won't be included in builds or tests.

## Simulator Management

### List Available Simulators
```bash
xcrun simctl list devices | grep iPhone
```

### Boot Simulator
```bash
xcrun simctl boot "iPhone 15"
```

### Install App
```bash
xcrun simctl install <SIMULATOR_ID> <APP_PATH>
```

### Launch App
```bash
xcrun simctl launch <SIMULATOR_ID> com.gannonhall.JabTracker
```

### Reset Simulator
```bash
xcrun simctl erase <SIMULATOR_ID>
```

## Launch Arguments

Configure in `project.yml` under `schemes.JabTracker.run.commandLineArguments`:

| Argument | Purpose |
|----------|---------|
| `--ui-testing` | Bypass Sign in with Apple |
| `--reset-app-data` | Clear all data on launch |
| `--force-onboarding` | Show onboarding flow |
| `--bypass-onboarding` | Skip onboarding |
| `--seed-test-7d` | Seed 7 days of test data |
| `--seed-test-30d` | Seed 30 days of test data |
| `--seed-test-90d` | Seed 90 days of test data |
| `--seed-test-1y` | Seed 1 year of test data |

### Enable/Disable in project.yml
```yaml
run:
  commandLineArguments:
    "--ui-testing": true   # Enable
    "--reset-app-data": false  # Disable
```

After changing, regenerate: `xcodegen generate`

## Git Workflow

### Create Feature Branch
```bash
git checkout main
git pull origin main
git checkout -b issue/123-feature-name
```

### Commit Changes
```bash
git add .
git commit -m "feat: Add dose scheduling"
```

### Push and Create PR
```bash
git push -u origin issue/123-feature-name
gh pr create --title "Issue #123: Feature name" --body "Description"
```

## Debugging

### View App Logs
```bash
# In Terminal while simulator running
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.gannonhall.JabTracker"'
```

### Clear Derived Data
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/JabTracker-*
```

### Reset Keychain (Simulator)
```bash
xcrun simctl keychain <SIMULATOR_ID> reset
```

## Common Issues

### Tests Not Running New Files
```bash
# Solution: Regenerate project
xcodegen generate
```

### Build Fails After Pull
```bash
# Solution: Clean and regenerate
rm -rf ~/Library/Developer/Xcode/DerivedData/JabTracker-*
xcodegen generate
./scripts/build.sh
```

### SwiftLint Violations
```bash
# Auto-fix what's possible
swiftlint --fix

# Then check remaining
swiftlint
```

### Authentication Not Bypassed
Check `project.yml` has `"--ui-testing": true` under the `run` scheme (not just `test`), then:
```bash
xcodegen generate
```

## Update History

- 2025-12-19T14:56:55Z: Initial context creation
