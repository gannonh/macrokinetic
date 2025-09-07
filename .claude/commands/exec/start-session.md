---
description: Continue work on an in-progress feature
argument-hint: spec path (e.g., specs/001-medication-profile-management)
---

# Continue Session - Pick Up Where We Left Off

You are continuing work on an **IN-PROGRESS FEATURE**. Load context and continue implementation.

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

# Check test status
./scripts/test.sh unit 1
./scripts/test.sh ui 1
```

### 2. Identify Next Tasks
- [ ] Read **"PRIORITY WORK FOR NEXT SESSION"** in tasks.md
- [ ] Check **"Current Status"** section for what's complete vs pending
- [ ] Review **"Key Technical Learnings"** for important patterns
- [ ] Note any **XCTSkip** tests that need to be enabled after implementation

### 3. Continue Implementation

**Follow the established patterns from the codebase:**
- TDD: Write failing tests first (RED → GREEN → REFACTOR)
- Use existing services and patterns documented in tasks.md
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
- Implement calculator UI views (ReconstitutionCalculatorView, PenClickCalculatorView)
- Connect UI to existing backend services
- Remove XCTSkip from tests once features are implemented
- Update functionality that's scaffolded but not connected

**Testing Patterns:**
- SwiftUI Form toggles: `coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()`
- Static accessibility IDs for pickers: `medication-picker`
- List items are Buttons, not Cells in SwiftUI

## Start Workflow

1. **Present Plan**: "Based on tasks.md, the next priority is [X]. Current status shows [Y] is complete. I'll implement [Z]. Proceed?"
2. **Wait for Confirmation**: Get user approval before starting
3. **Execute**: Implement with TDD, following existing patterns
4. **Verify**: Run tests and coverage checks
5. **Commit**: Use conventional commit messages

---

**Remember**: You're picking up active work. Context is already established in the feature documentation. Focus on the PRIORITY WORK section and continue where the last session ended.