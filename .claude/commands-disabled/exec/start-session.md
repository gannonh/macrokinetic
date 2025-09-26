---
description: Continue work on an in-progress feature
argument-hint: spec path (e.g., specs/001-medication-profile-management)
---

# Continue Feature - Spec-Driven Outside-In TDD

You are starting a new SESSION to continue work on an **IN-PROGRESS FEATURE**. Load context and continue implementation.

Activate **ULTRATHINK**

## Outside-In TDD Flow

**E2E Tests** → **Integration Tests** → **Unit Tests** → **Implementation**

Each outer layer defines the acceptance criteria and contracts for the inner layers. E2E tests are the ultimate acceptance criteria that define when a feature is truly "done" from the user's perspective.

## Active Context

**Spec Path**: $ARGUMENTS  
**Required Files**:
- `$ARGUMENTS/tasks.md` - Task list to execute
- `$ARGUMENTS/plan.md` - Technical context and structure
- `$ARGUMENTS/spec.md` - Feature requirements
- `$ARGUMENTS/quickstart.md` - Test scenarios

## Core Principles

1. **Tasks.md is Truth** - Execute tasks in exact order specified
2. **Outside-In TDD** - Start with E2E acceptance tests that define user-facing success, then work inward through integration and unit tests before implementation. E2E tests are the ultimate acceptance criteria.
3. **TDD Mandatory** - Tests MUST fail before implementation (RED → GREEN → REFACTOR)
4. **Medical Accuracy** - All calculations must match medical literature
5. **Minimal Implementation** - Write only enough code to pass tests
6. **No Improvisation** - Don't add features not in the spec
7. **Verify Continuously** - Run tests after every change

## THE PROCESS

### Step 1: Setup & Context
- [ ] Load `$ARGUMENTS/tasks.md` to identify current task
- [ ] Load `$ARGUMENTS/plan.md` to extract technical context and structure
- [ ] Load `$ARGUMENTS/spec.md` to review feature requirements
- [ ] Load `$ARGUMENTS/quickstart.md` to review test scenarios
- [ ] Check git status: `git status`
- [ ] Verify on correct branch (from`$ARGUMENTS/plan.md`)
- [ ] Read task dependencies and parallel execution notes
- [ ] Ask user: "Executing Task #X: [Description]. Proceed?" → WAIT for confirmation

### Step 2: E2E Acceptance Test (Outside-In TDD)
- [ ] For user-facing features, write an E2E acceptance test in JabTrackerUITests that defines what "done" looks like for the user. This test must fail before implementation begins.
- [ ] Run E2E test to verify it FAILS (RED phase)
- [ ] Commit failing E2E test with message: `test: add failing E2E test for [feature]`

### Step 3: Test Implementation (Unit tests)
**For test tasks marked "MUST FAIL":**
- [ ] Write test according to contract/quickstart scenario
- [ ] Run test to verify it FAILS (RED phase)
- [ ] Commit failing test with message: `test: add failing test for [feature]`

```bash
# Unit tests
./scripts/test.sh unit 1

# Specific test file
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -only-testing:JabTrackerTests/[TestClass]
```

### Step 4: Core Implementation
**Only after tests are failing:**
- [ ] Write minimal code to pass the test
- [ ] Run test to verify it PASSES (GREEN phase)
- [ ] Refactor if needed while keeping tests green
- [ ] Update `coverage-config.json` for new files
- [ ] Commit with message: `feat: implement [feature]`

### Step 5: Parallel Execution
**For tasks marked [P]:**
- Can be executed simultaneously with other [P] tasks
- Different files = no conflicts
- Example from tasks.md shows groupings

### Step 6: Verification Gates

**After each implementation:**
- [ ] Run relevant tests (unit, integration, E2E)
- [ ] Check coverage: `./scripts/coverage-json.sh [file]`
- [ ] Verify medical accuracy for calculations
- [ ] Performance: <50ms for calculations

**Before moving to next phase:**
- [ ] All tests (unit, integration, E2E) in current phase passing
- [ ] Coverage thresholds met
- [ ] SwiftLint clean: `swiftlint`
- [ ] Run: `./scripts/check-all.sh`

## Task Types Quick Reference

### Model Tasks
```swift
// JabTracker/Models/Medication.swift
enum Medication: String, CaseIterable, Codable {
    case semaglutide
    // Medical properties as computed properties
    var halfLifeDays: Double { /* values from spec */ }
}
```

### Service Tasks 
```swift
// JabTracker/Services/MedicationManager.swift
class MedicationManager: MedicationManagerProtocol {
    // Implement contract methods
}
```

### UI Tasks
```swift
// JabTracker/Views/Settings/MedicationProfileSettingsView.swift
struct MedicationProfileSettingsView: View {
    // SwiftUI implementation
}
```

## Critical Commands

```bash
# After creating new Swift files
xcodegen generate

# Run tests by type
./scripts/test.sh unit 1    # Unit tests

# Coverage analysis
./scripts/check-coverage.sh
./scripts/coverage-detail.sh [FileName]

# Full validation
./scripts/check-all.sh --skip-ui
```

## Stop and Clarify When

- Task dependencies unclear
- Medical calculations need verification
- Test contract ambiguous
- Coverage requirements not met
- Performance targets missed

## Completion Checklist

**Per Task:**
- [ ] Test written and failing (if test task)
- [ ] Implementation passes test (if implementation task)
- [ ] Coverage adequate
- [ ] SwiftLint clean
- [ ] Committed with conventional message

**Per Phase:**
- [ ] All phase tasks complete
- [ ] Integration tests passing
- [ ] quickstart.md scenarios validated
- [ ] Performance verified
- [ ] Documentation updated

---

**Remember**: You're picking up active work. Context is already established in the feature documentation. Continue where the last session ended.