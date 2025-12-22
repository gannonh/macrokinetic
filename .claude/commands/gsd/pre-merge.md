---
description: Run PR review workflow before merging milestone
argument-hint: "[pr-number]"
allowed-tools:
  - Read
  - Bash
  - Write
  - Glob
  - Grep
  - Skill
  - Task
  - AskUserQuestion
---

<objective>
Run comprehensive PR review and quality checks before merging.

Purpose: Ensure code quality, test coverage, and adherence to project standards before completing a milestone.
Output: All review issues addressed, PR ready for merge via /gsd:complete-milestone.
</objective>

<context>
PR Number: $ARGUMENTS (auto-detect from current branch if not provided)

**Load project state:**
@.planning/STATE.md
@.planning/ROADMAP.md
</context>

<process>

<step name="identify_pr">
**Determine which PR to review:**

```bash
# Auto-detect PR if not provided
if [ -z "$ARGUMENTS" ]; then
  PR_NUMBER=$(gh pr view --json number -q .number 2>/dev/null)
  if [ -z "$PR_NUMBER" ]; then
    echo "ERROR: No PR found for current branch. Either:"
    echo "  1. Provide PR number: /gsd:pre-merge 123"
    echo "  2. Switch to a branch with an open PR"
    exit 1
  fi
else
  PR_NUMBER=$ARGUMENTS
fi

# Verify PR exists and get details
gh pr view $PR_NUMBER --json number,title,state,headRefName -q '"PR #\(.number): \(.title)\nState: \(.state)\nBranch: \(.headRefName)"'
```

If PR is already merged or closed, inform user and exit.
</step>

<step name="run_ci_checks">
**Run CI checks and fix any issues:**

1. **Validate coverage configuration:**
   ```bash
   ./scripts/check-coverage-config.sh
   ```
   If missing files found, add them to coverage-config.json.

2. **Run full check suite:**
   ```bash
   ./scripts/check-all.sh --skip-ui 2>&1 | tail -100
   ```

3. **If ANY failures or violations:**
   ```
   ❌ CI Check Failures Found

   [List of failures: lint errors, test failures, build errors]

   These must be fixed before proceeding with PR review.
   ```

   Fix all issues before continuing. Re-run checks until all pass.

4. **If all checks pass:**
   ```
   ✅ CI Checks Passed
   - SwiftLint: No violations
   - Build: Successful
   - Unit Tests: All passing
   - Coverage: Thresholds met

   Proceeding to PR review...
   ```
</step>

<step name="pr_review_toolkit">
**Run comprehensive PR review using pr-review-toolkit:**

```
/pr-review-toolkit:review-pr all
```

This launches specialized review agents:
- **code-reviewer**: Code quality, bugs, logic errors
- **pr-test-analyzer**: Test coverage completeness
- **silent-failure-hunter**: Error handling patterns
- **type-design-analyzer**: Type design quality
- **comment-analyzer**: Comment accuracy

**For each issue found:**

1. **Critical issues** - Must fix immediately
2. **Important issues** - Should fix before merge
3. **Suggestions** - Consider fixing

**Address ALL issues**, not just critical ones. The goal is a clean, high-quality merge.

Continue iterating until no issues remain:
```
Re-running /pr-review-toolkit:review-pr all...

[If issues found: fix and re-run]
[If no issues: proceed to next step]
```
</step>

<step name="code_rabbit_review">
**Run CodeRabbit review:**

```
/qa:code-rabbit
```

**For each CodeRabbit comment, evaluate using the decision framework:**

1. **Is it correct?** - Does the issue actually exist?
2. **Is it relevant?** - Does it apply to our use case?
3. **Is it beneficial?** - Will fixing it improve the code?
4. **Is it safe?** - Could the change introduce problems?

**Accept (all answers yes):**
- Actual bugs and logic errors
- Security vulnerabilities
- Resource leaks
- Type safety issues
- Missing error handling

**Ignore (any answer no):**
- Style preferences conflicting with project conventions
- Generic best practices not applicable here
- Performance suggestions for non-critical code
- Suggestions that would break project patterns

**For accepted issues:**
- Fix the issue
- Re-run relevant checks to confirm fix

**For ignored issues:**
- Document reasoning briefly for audit trail
</step>

<step name="final_validation">
**Run final validation to confirm everything is ready:**

```bash
# Final check suite
./scripts/check-all.sh --skip-ui 2>&1 | tail -50
```

**Present summary to user:**

```
✅ Pre-merge Validation Complete

PR #[PR_NUMBER]: [Title]
Branch: [branch_name]

Validation Results:
- CI Checks: ✅ Passing
- PR Review Toolkit: ✅ All issues addressed
- CodeRabbit: ✅ Reviewed and processed
- Final Checks: ✅ Passing

The PR is ready for merge.

---

## ▶ Next Steps

**Option A: Complete the milestone (recommended)**
`/gsd:complete-milestone [version]`

This will:
- Mark all phases complete
- Archive milestone documentation
- Merge the PR
- Create git tag

**Option B: Merge PR manually**
```bash
gh pr merge [PR_NUMBER] --merge --delete-branch
```

---
```
</step>

</process>

<success_criteria>
- [ ] PR identified and accessible
- [ ] All CI checks pass (lint, build, tests, coverage)
- [ ] /pr-review-toolkit:review-pr all - all issues addressed
- [ ] /qa:code-rabbit - all comments processed
- [ ] Final validation passes
- [ ] User knows next steps (complete-milestone or manual merge)
</success_criteria>

<critical_rules>
- **Fix ALL issues** - Don't skip "minor" issues; they compound
- **Re-run after fixes** - Confirm issues are resolved before proceeding
- **Document ignored CodeRabbit comments** - Explain why for audit trail
- **Don't skip steps** - Each review type catches different issues
- **Final validation required** - Confirm no regressions from fixes
</critical_rules>
