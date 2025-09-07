---
description: Complete feature implementation and prepare for PR merge
argument-hint: spec path (e.g., specs/001-medication-profile-management)
---

# Feature Completion - Ready for Merge

You are **COMPLETING A FEATURE**. Validate all requirements, finalize documentation, and prepare for PR merge.

Activate **ULTRATHINK**


## Active Feature

**Spec Path**: $ARGUMENTS  
**Validation Files**:
- `$ARGUMENTS/quickstart.md` - All scenarios must pass
- `$ARGUMENTS/spec.md` - All requirements must be met
- `$ARGUMENTS/tasks.md` - All tasks must be complete

## COMPLETION CHECKLIST

### 1. Validate Feature Completion

```bash
# Verify all tests passing
./scripts/test.sh all 1

# Check coverage requirements
./scripts/check-coverage.sh

# Run full validation suite
./scripts/check-all.sh

# Verify no XCTSkip remaining (unless for future features)
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

### 3. Update Documentation

**Update `$ARGUMENTS/tasks.md`:**
- Mark all tasks as ✅ complete
- Add "FEATURE COMPLETE" section with summary
- Document any deferred work or future enhancements

**Update `$ARGUMENTS/quickstart.md`:**
- Mark all scenarios as ✅
- Set "Ready for production deployment: ✅"

**Update `docs/implementation-plan.md`:**
- Move feature from "In Progress" to "Completed"
- Update with final implementation details

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
gh pr review --request @reviewer
```

### 5. Merge Preparation

**Pre-merge verification:**
```bash
# Rebase on main if needed
git fetch origin main
git rebase origin/main

# Final test run
./scripts/check-all.sh

# Squash commits if desired
git rebase -i main
```

**Merge PR:**
```bash
# Once approved
gh pr merge --squash --delete-branch
```

### 6. Post-Merge Cleanup

```bash
# Switch back to main
git checkout main
git pull origin main

# Verify feature is integrated
./scripts/test.sh all 1

# Archive feature spec (optional)
mv $ARGUMENTS $ARGUMENTS-COMPLETED-$(date +%Y%m%d)
```

## Success Criteria

**Feature is complete when:**
- ✅ All spec.md requirements implemented
- ✅ All quickstart.md scenarios passing
- ✅ All tasks.md items complete
- ✅ Test coverage meets/exceeds requirements
- ✅ PR approved and ready to merge
- ✅ Documentation fully updated

---

**Final Step**: Celebrate! 🎉 Feature successfully delivered from spec to production.