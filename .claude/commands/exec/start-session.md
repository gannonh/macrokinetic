---
description: Continue work on an in-progress feature
argument-hint: spec path (e.g., specs/001-medication-profile-management)
---

# Continue Session - Pick Up Where We Left Off

You are continuing work on an **IN-PROGRESS FEATURE**. Load context and continue implementation.

Activate **ULTRATHINK**

## Active Feature

**Spec Path**: $ARGUMENTS  
**Context Files**:
- `$ARGUMENTS/tasks.md` - Check "PRIORITY WORK FOR NEXT SESSION" section
- `$ARGUMENTS/quickstart.md` - Check "Completion Criteria" for current status
- `$ARGUMENTS/spec.md` - Feature requirements reference
- `$ARGUMENTS/plan.md` - Technical architecture reference

## IMMEDIATE ACTIONS

### 1. Load Session Context
```bash
# Check current branch and PR status
git status
gh pr view --json title,state,url

# Review priority work from last session
cat $ARGUMENTS/tasks.md | grep -A 20 "PRIORITY WORK FOR NEXT SESSION"
```

### 2. Assess Test Coverage for Next Tasks
- [ ] Read **"PRIORITY WORK FOR NEXT SESSION"** in tasks.md
- [ ] Check **"Current Status"** section for what's complete vs pending
- [ ] Review **"Key Technical Learnings"** for important patterns
- [ ] Check if E2E tests already exist for the feature
- [ ] If adding NEW UI components: Plan E2E acceptance tests first
- [ ] If modifying existing UI: Review/update existing E2E tests
- [ ] If backend-only work: Focus on unit/integration tests
- [ ] Note any **XCTSkip** tests that need to be enabled after implementation

### 3. Continue Implementation

**For NEW UI components:**
- Write E2E acceptance tests first (RED phase)
- Tests define user-facing success criteria
- Implement minimal UI to make tests pass (GREEN phase)
- Refactor as needed

**For existing UI modifications:**
- Update existing E2E tests if needed
- Ensure tests fail with current implementation
- Modify code to make tests pass

**For backend-only work:**
- Follow unit/integration test patterns
- Use existing service patterns from tasks.md
- Write failing tests first (RED → GREEN → REFACTOR)

**General patterns:**
- Reference technical learnings for UI testing patterns
- Run tests continuously: `./scripts/test.sh unit 1`

### 4. Verification

After implementing each component:
```bash
# Run tests
./scripts/test.sh unit 1
./scripts/test.sh ui 1

# Check coverage
./scripts/check-coverage.sh

# Validate with SwiftLint
swiftlint

# Full check before commit
./scripts/check-all.sh
```

## Quick Reference

**Common Next Steps (from recent sessions):**
- Write E2E tests for NEW calculator UI views (if adding new UI)
- Update existing E2E tests (if modifying existing UI)
- Connect UI to existing backend services
- Remove XCTSkip from tests once features are implemented
- Update functionality that's scaffolded but not connected

**Testing Patterns:**
- SwiftUI Form toggles: `coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()`
- Static accessibility IDs for pickers: `medication-picker`
- List items are Buttons, not Cells in SwiftUI

## Start Workflow

1. **Assess & Plan**: "Based on tasks.md, the next priority is [X]. [Existing E2E tests cover Y / Need new E2E tests for Z]. I'll [write tests for/implement] [component]. Proceed?"
2. **Wait for Confirmation**: Get user approval before starting
3. **Execute**: Implement with TDD, following existing patterns
4. **Verify**: Run tests and coverage checks
5. **Commit**: Use conventional commit messages

---

**Remember**: You're picking up active work. Context is already established in the feature documentation. Focus on the PRIORITY WORK section and continue where the last session ended.