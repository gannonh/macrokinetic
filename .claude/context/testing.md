---
framework: xcodebuild_swift_testing
test_command: ./scripts/test.sh
created: 2025-01-22T04:47:23Z
last_updated: 2025-10-23T20:15:00Z
---

# Testing Framework Overview

## Quick Reference

- **Framework**: Xcode with Swift Testing (unit) + XCUITest (E2E)
- **Test Command**: `./scripts/test.sh`
- **Unit Tests**: JabTrackerTests/ (42+ files, Swift Testing framework)
- **E2E Tests**: JabTrackerUITests/ (25+ files, XCUITest framework)
- **Output Formatter**: xcbeautify
- **Coverage Policy**: 5-tier system (90% for business logic, 42-85% for other tiers)

## Testing Skills

For detailed testing guidance, use these specialized skills:

### Unit & Integration Testing
**Skill**: `/unit-testing`

Comprehensive guidance for:
- Swift Testing framework patterns
- SwiftData test data management
- Coverage policy compliance
- Async testing and @MainActor requirements
- Integration testing patterns

### E2E Testing
**Skill**: `/e2e-testing`

Comprehensive guidance for:
- Debug-first element targeting
- Iterative E2E test implementation
- Launch argument data seeding
- Timing patterns and wait conditions
- Screenshot capture and analysis

## Common Commands

### Unit Tests
```bash
# Run all unit tests (RECOMMENDED)
./scripts/test.sh unit 1

# Run specific test suite (RECOMMENDED)
./scripts/test.sh unit 1 AuthenticationManagerCoreTests

# Run with coverage
./scripts/test.sh unit 1 --coverage

# Coverage analysis
./scripts/coverage-detail.sh
./scripts/coverage-json.sh --summary
```

### E2E Tests
```bash
# Run specific test method (RECOMMENDED)
./scripts/test.sh ui 1 OnboardingUITests/testCompleteOnboardingFlow

# Run specific test class
./scripts/test.sh ui 1 OnboardingUITests

# Run with simulator reset
./scripts/test.sh ui 1 OnboardingUITests --reset

# ⚠️ AVOID: All UI tests (very slow - 10+ minutes)
# ./scripts/test.sh ui 1
```

### Coverage Commands
```bash
# Validate coverage config
./scripts/check-coverage-config.sh

# Check coverage policy compliance
./scripts/check-coverage.sh

# Run comprehensive quality checks
./scripts/check-all.sh --skip-ui
```

## Coverage Policy (5-Tier System)

- **Tier 1 - Pure Business Logic (90%)**: PharmacokineticsEngine, Models, Medical Calculations
- **Tier 2 - Infrastructure (62%)**: DataController, MedicationManager
- **Tier 3 - Framework Integration (42%)**: AuthenticationManager, BiometricAuthManager
- **Tier 4 - View Models (85%)**: OnboardingViewModel
- **Tier 5 - Utilities (75%)**: ProfileValidation, Helpers
- **SwiftUI Views**: No requirements (cannot be unit tested)

## Test Logs

### All Tests Log Automatically
- Location: `./logs/{test_type}_YYYY-MM-DD_HH-MM-SS/`
- Latest: `logs/latest` symlink
- Files: `raw_output.txt`, `results.xcresult`, `coverage.json` (if --coverage used)

### View Results
```bash
# View latest test output
cat logs/latest/raw_output.txt

# Open in Xcode Test Results Browser (RECOMMENDED)
open logs/latest/results.xcresult

# Search for debug output
cat logs/latest/raw_output.txt | grep "DEBUG"
```

## Available Simulators

> **Note**: Xcode 26 requires iOS 26.1 simulators to avoid SwiftData/CloudKit crashes with older runtimes.

1. **PRIMARY**: iPhone 17 Pro,OS=26.1 (UUID: BA8D09E4-EE1F-49BB-A7D2-5705EC4C513D)
2. **SECONDARY**: iPhone 17,OS=26.1 (UUID: 4E249318-06A8-442B-9E84-BBD450936DE5)
3. **TERTIARY**: iPhone 17 Pro Max,OS=26.1 (UUID: 7E5A0A90-D04A-4013-996A-585296E0FFC8)
