---
description: Address test quality issues from analysis report
argument-hint: report file path (e.g. docs/reports/test-quality-report-18.md)
---

# Fix Test Quality Issues

You are an expert iOS Test Engineer specializing in Swift Testing and XCUITest frameworks. Use **ULTRATHINK**.

**Task**: Address the critical test quality issues identified in the specified report.

- Read and analyze the test quality report: `$ARGUMENTS`
- Use TodoWrite tool to track progress through identified issues
- Focus on **Critical (🔴) and High Priority (🟡)** issues first
- Follow TDD principles: Red-Green-Refactor cycle
- Validate all fixes meet coverage policy requirements

## Core Implementation Principles

### 1. Test Validity Requirements
**Every test must fail when the tested behavior is broken.**
- Write assertions that validate behavior, not just execution
- Ensure tests fail when expected behavior doesn't occur
- Replace construction-only tests with behavioral validation
- Never suppress errors in tests without explicit validation

### 2. Coverage Policy Compliance
**Follow SwiftUI-aware coverage targets from `coverage-config.json`:**
- **Business Logic**: 90% minimum (Models, Core Logic)
- **View Models**: 85% minimum (ObservableObject classes)  
- **Framework Integration**: 42% minimum (Authentication, Data)
- **Infrastructure & Data**: 62% minimum (DataController)
- **Utilities**: 75% minimum (Helper functions, extensions)

### 3. TDD Implementation Workflow
**Red-Green-Refactor Approach:**
1. **Red**: Write failing test that captures expected behavior
2. **Green**: Implement minimal code to make test pass
3. **Refactor**: Clean up code while keeping tests green
4. **Verify**: Run `./scripts/check-coverage.sh` to confirm policy compliance

## Priority-Based Fix Strategy

### 🔴 Critical Issues (Address First)
Focus on coverage policy violations and invalid tests that provide false confidence:
- Coverage gaps in pure business logic (target: 90%)
- Coverage gaps in view models (target: 85%)  
- Disabled test suites for critical functionality
- Tests that always pass regardless of code behavior

### 🟡 High Priority Issues  
Address significant gaps in test effectiveness:
- Missing behavioral validation in existing tests
- Uncovered critical methods in framework integration
- Missing negative test cases and error scenarios

### 🟢 Medium Priority Issues
Improve overall test quality:
- Construction-only tests → behavioral tests
- Environment-dependent test reliability
- Test maintainability and organization

## Implementation Commands

### Coverage Analysis
```bash
# Fresh coverage data generation
./scripts/test.sh unit 1 --coverage

# Check policy compliance  
./scripts/check-coverage.sh

# Detailed file analysis
./scripts/coverage-detail.sh [FileName]
./scripts/coverage-json.sh --functions  # Show uncovered functions
```

### Test Development
```bash
# Run specific test during development
./scripts/test.sh unit 1 --filter "TestClassName"

# Run all tests to verify no regressions
./scripts/test.sh unit 1

# Full quality check before completion
./scripts/check-all.sh
```

## Quality Validation

### Before Marking Issues Complete
1. **Run Coverage Check**: `./scripts/check-coverage.sh` shows GREEN ✅ 
2. **Test Behavior**: Manually break code to verify tests fail
3. **Run Full Suite**: `./scripts/test.sh unit 1` passes without errors
4. **Verify TDD**: Tests were written before implementation code

### Success Criteria
- All critical coverage policy violations resolved
- Tests validate behavior, not just code execution  
- No disabled critical test suites remain
- Coverage targets met for all tiers in `coverage-config.json`
- Tests follow modern Swift Testing framework patterns

## Report Update
After completing fixes:
- Document resolved issues in report comments
- Note any issues requiring architectural changes
- Update overall assessment based on improvements
- Provide before/after coverage metrics

## Important Notes

- **Never modify production code** just to increase coverage artificially
- **Focus on meaningful tests** that prevent real regressions
- **Use Swift Testing framework** (@Test) for new/updated unit tests
- **Maintain E2E test quality** - don't break existing UI test patterns
- **Medical app requirements**: Extra precision needed for dose/medication logic testing
- **SwiftUI constraints**: Don't attempt to unit test view body getters (use E2E instead)

Remember: Test quality is measured by effectiveness at preventing bugs, not just coverage percentages.