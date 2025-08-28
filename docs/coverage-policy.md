# JabTracker Test Coverage Policy

## Overview

Due to SwiftUI's architecture limitations, traditional 80% overall coverage targets are not realistic. We use a tiered coverage policy that focuses on testable business logic while acknowledging UI layer limitations.

## Coverage Tiers

### Tier 1: Business Logic (90% minimum required)
**Files containing core business logic, data processing, and critical app functionality:**

- `AuthenticationManager.swift` - Authentication flows and state management
- `BiometricAuthManager.swift` - Biometric authentication logic  
- `DataController.swift` - SwiftData and CloudKit sync logic
- `PharmacokineticsEngine.swift` - Medical calculation algorithms
- `User.swift` - User data model and validation
- `Dose.swift` - Dose data model and business rules
- `MedicationProfile.swift` - Medication data model and logic

**Rationale:** These components contain the most critical business logic where bugs have the highest impact. Medical calculation accuracy is paramount.

### Tier 2: View Models (85% minimum required)
**ObservableObject classes that contain testable business logic:**

- Currently none defined (SwiftUI views handle state directly)
- Future ViewModels should be added here as architecture evolves

**Rationale:** View models contain presentation logic that's easily testable and critical for proper UI behavior.

### Tier 3: Utilities & Extensions (75% minimum required)
**Helper functions, extensions, and utility classes:**

- Array extensions
- String validation helpers  
- Date formatting utilities
- Conversion functions

**Rationale:** While important, utilities typically have lower complexity and impact than core business logic.

### Tier 4: SwiftUI Views (No coverage requirement)
**View structs and their body properties:**

- All `View` conforming structs
- View modifiers and styling code
- SwiftUI-specific presentation logic

**Rationale:** SwiftUI view bodies cannot be unit tested due to framework architecture. These require UI testing instead.

## Enforcement

### Manual Enforcement
```bash
# Run coverage check script
./scripts/check-coverage.sh

# View detailed coverage in Xcode
# 1. Run tests with coverage enabled
# 2. Open Report Navigator (⌘9)  
# 3. Select test result → Coverage tab
```

### CI/CD Integration
Add coverage check to your CI pipeline:

```yaml
- name: Check Coverage Policy
  run: ./scripts/check-coverage.sh
```

## Coverage Reporting

### Xcode UI Coverage
- Shows raw percentages for all files
- Does not enforce policy automatically
- Use for detailed line-by-line coverage analysis

### Script-Based Policy
- Enforces tiered requirements
- Fails CI if policies not met
- Provides actionable feedback

### Coverage Report Generation
```bash
# Generate JSON report
xcrun xccov view --report --json /tmp/coverage.xcresult > coverage.json

# View file-specific coverage
xcrun xccov view --file /path/to/file.swift /tmp/coverage.xcresult
```

## Policy Updates

When adding new files:

1. **Business Logic**: Add to Tier 1 (90% requirement) if contains:
   - Medical calculations
   - Authentication logic
   - Data persistence logic
   - Critical business rules

2. **View Models**: Add to Tier 2 (85% requirement) if contains:
   - ObservableObject with business logic
   - Presentation state management
   - User interaction handling

3. **Utilities**: Add to Tier 3 (75% requirement) if contains:
   - Helper functions
   - Extensions
   - Formatting logic

4. **Views**: No coverage requirement for SwiftUI View structs

## Current Status

**Business Logic Coverage:** Varies by file (see `./scripts/check-coverage.sh` output)
**View Models:** None defined yet
**Overall App Coverage:** ~23% (informational only, not a requirement)

## Best Practices

1. **Test business logic separately from UI** - Extract complex logic from view bodies into testable functions
2. **Use internal visibility** - Make validation and business logic methods `internal` for testing
3. **Focus on edge cases** - Ensure all business logic paths are tested
4. **Mock external dependencies** - Use dependency injection for CloudKit, authentication
5. **Validate test quality** - Every test must fail when the behavior it tests is broken