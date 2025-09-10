---
description: Complete feature implementation and prepare for PR merge
argument-hint: spec path (e.g., specs/001-medication-profile-management)
---

# Feature Completion - Ready for Merge

You are **COMPLETING A FEATURE**. Validate all requirements, finalize documentation, and prepare for PR merge.

Activate **ULTRATHINK**

**IMPORTANT:** If at any time you find the feature to be incomplete, notify the user and await further instruction. 

## Active Feature

**Spec Path**: $ARGUMENTS  
**Validation Files**:
- `$ARGUMENTS/quickstart.md` - All scenarios must pass
- `$ARGUMENTS/spec.md` - All requirements must be met
- `$ARGUMENTS/tasks.md` - All tasks must be complete

## WORK REVIEW

- [ ] Review full scope of branch/PR

## COMPLETION CHECKLIST

### 1. Validate Feature Completion

```bash
# Verify all tests passing
./scripts/test.sh all 1

# Check coverage requirements
./scripts/check-coverage.sh

# Run full validation suite
./scripts/check-all.sh --skip-ui # Assume the user is handling ui test validation

# Verify no XCTSkip remaining 
# Exceptions: JabTrackerUITests/CodeGen.swift and JabTrackerUITests/ManualAuthenticationUITests.swift may be skipped
grep -r "XCTSkip" JabTrackerUITests/ JabTrackerTests/
```

### 2. Review Quickstart Scenarios

**Check each scenario in `$ARGUMENTS/quickstart.md`:**
- [ ] Scenario 1: ✅ (must be fully passing)
- [ ] Scenario 2: ✅ (must be fully passing)
- [ ] Scenario 3: ✅ (must be fully passing)
- [ ] Scenario 4: ✅ (must be fully passing)
- [ ] Scenario 5: ✅ (must be fully passing)

**Verify completion criteria:**
- [ ] Performance targets met
- [ ] Integration tests pass
- [ ] Error handling verified
- [ ] Accessibility validated
- [ ] Security requirements met

### 3a. Update Feature-Level Documentation

**Update `$ARGUMENTS/tasks.md`:**
- Mark all tasks as ✅ complete
- Add "FEATURE COMPLETE" section with summary
- Document any deferred work or future enhancements

**Update `$ARGUMENTS/spec.md`:**
- Mark all requirements as ✅ complete

**Update `$ARGUMENTS/quickstart.md`:**
- Mark all scenarios as ✅
- Set "Ready for production deployment: ✅"

### 3b. Update Project-level Documentation

**Update `docs/implementation-plan.md`:**
- Move feature from "In Progress" to "Completed"
- Update with final implementation details

**Update `docs/spec-master-prd.md`:**
- Mark feature as complete in master PRD
- Document any project level changes

**Update `CLAUDE.md`:**
- Change status emoji from 🔄 to ✅
- Add feature to completed features section
- Document any new patterns or learnings

### 4. Finalize Git/GitHub

```bash
# Ensure working tree is clean
git status

# Update PR from draft to ready
gh pr ready

# Add comprehensive PR description
gh pr edit --body "$(cat <<EOF
## ✅ Feature Complete: [Feature Name]

### Implementation Summary
- All requirements from spec.md implemented
- All quickstart.md scenarios passing
- Test coverage exceeds requirements
- No outstanding issues or TODOs

### Test Results
- Unit Tests: ✅ XXX passing
- UI Tests: ✅ XX passing  
- Coverage: ✅ XX% (exceeds requirements)

### Validation
- [ ] All tests passing
- [ ] Coverage requirements met
- [ ] SwiftLint clean
- [ ] Performance validated
- [ ] Accessibility tested
- [ ] Security reviewed

### Documentation
- [ ] tasks.md updated
- [ ] quickstart.md validated
- [ ] implementation-plan.md current
- [ ] CLAUDE.md updated

Ready for review and merge.
EOF
)"

# Request review
gh pr review --request @claude
```


## Success Criteria

**Feature is complete when:**
- ✅ All spec.md requirements implemented
- ✅ All quickstart.md scenarios passing
- ✅ All tasks.md items complete
- ✅ Test coverage meets/exceeds requirements
- ✅ PR under review
- ✅ Documentation fully updated

