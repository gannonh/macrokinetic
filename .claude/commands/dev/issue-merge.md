---
description: Merge completed PR from branch to main using GitHub Pull Request workflow
argument-hint: pr-number | issue-number (optional)
---

# PR Merge

Merge completed PR from branch to main using GitHub Pull Request workflow.

## Quick Check

**Input:** `$ARGUMENTS` (can be either a PR number or an issue number)

⚠️ **IMPORTANT:** If user did not provide an input argument, assume the current PR branch.

1. **Determine if argument is a PR or Issue number:**
   ```bash
   # First, try to view it as a PR
   if gh pr view $ARGUMENTS --json number -q .number 2>/dev/null; then
     echo "✅ Argument $ARGUMENTS is a PR number"
     PR_NUMBER=$ARGUMENTS
   else
     # Not a valid PR, check if it's an issue with a linked PR
     echo "ℹ️ Argument $ARGUMENTS is not a PR, checking if it's an issue..."

     # Get linked PRs from the issue (look for PRs that reference this issue)
     LINKED_PR=$(gh pr list --search "linked:$ARGUMENTS" --json number -q '.[0].number' 2>/dev/null)

     if [ -z "$LINKED_PR" ]; then
       # Alternative: Search for PRs with issue number in branch name or title
       LINKED_PR=$(gh pr list --search "$ARGUMENTS in:title" --json number -q '.[0].number' 2>/dev/null)
     fi

     if [ -z "$LINKED_PR" ]; then
       # Alternative: Look for branch naming convention feat/<issue>-* or fix/<issue>-*
       LINKED_PR=$(gh pr list --json number,headRefName -q ".[] | select(.headRefName | test(\"(feat|fix)/$ARGUMENTS-\")) | .number" 2>/dev/null | head -1)
     fi

     if [ -n "$LINKED_PR" ]; then
       echo "✅ Found PR #$LINKED_PR linked to Issue #$ARGUMENTS"
       PR_NUMBER=$LINKED_PR
     else
       echo "❌ No PR found for Issue #$ARGUMENTS"
       echo "Please provide the PR number directly, or ensure:"
       echo "  - PR title contains the issue number"
       echo "  - PR branch follows naming convention: feat/<issue>-* or fix/<issue>-*"
       exit 1
     fi
   fi
   ```

2. **Check PR status:**
   ```bash
   gh pr view $PR_NUMBER --json state,isDraft,headRefName -q '.state + " (draft: " + (.isDraft|tostring) + ") - Branch: " + .headRefName' || echo "❌ PR #$PR_NUMBER not found"
   ```

3. **Get branch name from PR:**
   ```bash
   branch_name=$(gh pr view $PR_NUMBER --json headRefName -q .headRefName)
   echo "📋 PR #$PR_NUMBER uses branch: $branch_name"
   ```

**Note:** For the remainder of this workflow, use `$PR_NUMBER` (the resolved PR number) for all `gh pr` commands.

## Instructions

The merge process is multi-step. It is possible the user is starting from Step 1, or resuming from a later step in the process. Therefore, your first task is to ask the user from which step they would like to start:

```bash
At which step would you like to start? (1-9)"
1. Pre-Merge Validation"
2. Run Checks & Fix Issues"
3. Mark PR as Ready for Review"
4. PR Reviews"
5. Process PR Comments"
6. Update Context Docs"
7. Document Feature
8. Merge After Approval"
9. Post-Merge Cleanup"
10. Final Output"
```

Based on the user's response, proceed to that step and continue through the remaining steps in order.

---

### 1. Pre-Merge Validation

Check current branch status:
```bash
# Get branch name from PR (use $PR_NUMBER resolved in Quick Check)
branch_name=$(gh pr view $PR_NUMBER --json headRefName -q .headRefName)

# Ensure we're on the PR branch
git checkout $branch_name

# Check for uncommitted changes
if [[ $(git status --porcelain) ]]; then
  ⚠️ Uncommitted changes in branch:"
  git status --short
  Commit or stash changes before merging"
  exit 1
fi

# Update branch with latest changes
git fetch origin
git push origin $branch_name
git status -sb
```

---


### 2. Run Checks & Fix Issues

1. Run `./scripts/check-coverage-config.sh` add any missing files to `coverage-config.json` if needed
2. Run final checks: `./scripts/check-all.sh --skip-ui 2>&1 | tail -100`
3. If ANY failures or violations:
   - **⚠️ STOP MERGE PROCESS ⚠️**
   - Provide summary of issues found, eg:
     ```
     ❌ 3 lint errors
     ❌ 2 failed tests
     ❌ 1 security vulnerability
     ```
  - Fix all issues and proceed to next step
4. If all checks pass, proceed to next step

---

### 3. Mark PR as Ready for Review

If PR is still a draft:
```bash
gh pr ready $PR_NUMBER
echo "✅ PR #$PR_NUMBER marked as ready for review"
```

---

### 4. PR Reviews

#### 4.0 Run PR Review & Fix Issues

1. Run: `/pr-review-toolkit:review-pr all`
2. Address ALL issues found (not just critical/important)

#### 4.1 Run CodeRabbit Review & Fix Issues

1. Run `/qa:code-rabbit`
2. Address issues and ignore false positives

#### 4.2 Request GitHub Reviewers
Ask user to requests reviewers on github, monitor status, then resume this merge process from Step 5 once comments are in. 

Format as follows:

---
Step 4: Request Review

  Action Required:
  1. Go to the PR URL: https://github.com/gannonh/jab-tracker-ios/pull/$PR_NUMBER
  2. Request reviewers from your team members
  3. Monitor the PR for review comments and approvals
  4. Once all reviews are completed, come back and resume this merge process from Step 5: `/pm:issue-merge $PR_NUMBER`
---

**important:** Do NOT proceed to Step 5 until explicitly asked to do so by the user.

---

### 5. Process PR Comments

#### 5.1. Create GitHub Issues from PR Feedback

**Your Task:**
Read ALL PR feedback sources, analyze the content, present summary to user, and create individual GitHub issues for each distinct actionable recommendation.

**Step 1: Fetch All Feedback Sources**

Use these commands to retrieve all types of feedback:

```bash
# 1. PR-level conversation comments
gh pr view $PR_NUMBER --json comments --jq '.comments[] | {
  author: .author.login,
  created: .createdAt,
  body: .body
}'

# 2. Inline code review comments (line-specific)
gh api repos/OWNER/REPO/pulls/$PR_NUMBER/comments --jq '.[] | {
  author: .user.login,
  file: .path,
  line: .line,
  body: .body
}'

# 3. Review summaries (overall review state and comments)
gh pr view $PR_NUMBER --json reviews --jq '.reviews[] | {
  author: .author.login,
  state: .state,
  body: .body,
  submittedAt: .submittedAt
}'
```

**Step 2: Analyze All Feedback**

Read through every comment, review, and inline suggestion. For each piece of feedback:
- Identify distinct, actionable recommendations
- Note which items are related and could be grouped

**Step 3: Create Issues**

For each actionable item you identify:

```bash
gh issue create \
  --title "PR #$PR_NUMBER - [descriptive title]" \
  --body "[detailed description with context]"
```
**Step 4: Double Check Your Work**

Go back through the PR comments and the issues you created. Ensure:
- Every distinct recommendation has its own issue (or is grouped logically)
- No duplicates or missed items


**Guidelines for Issue Creation:**

- **Large analyzer reports** (test quality, code quality): Parse them to extract **individual issues**
  - Example: 
    - DO NOT: create 1 issue for "test quality report"
    - DO: create Issue for "6 placeholder tests", separate issue for "missed dose coverage", etc.
- **Related recommendations**: Group similar items into one issue when it makes sense
  - Example: 4 Copilot comments about "hardcoded scheduledDoseId" → 1 grouped issue
- **Individual comments**: Each specific recommendation gets its own issue
- **Context**: Include enough detail so the issue can be understood without reading the PR
- **Traceability**: Always prefix with "PR #$PR_NUMBER - "

**Important:**
- Use your judgment - this is NOT an automated process
- Parse long reports carefully to extract all actionable items
- Don't skip the analyzer reports - they contain the most important feedback
- Check for duplicates before creating issues
- Don't let anything slip through the cracks!

#### 5.2. Triage & Label GitHub Issues
For each newly created issue: evaluate, prioritize and label.

- Evaluate each new issue
- Read the relevant code files for context
- Prioritize each issue based on severity and impact using GitHub labels:
  - [P0] Critical: Must be fixed before merge
  - [P1] Important: Should be fixed before merge
  - [P2] Optional: Can be deferred until after merge
  - [P3] Low: Minor improvement, no immediate action needed
  - [wont-fix] Won't fix: Not applicable or not worth addressing

```bash
gh issue edit [issue-number] --add-label [label]
```

- Comment on each issue with your evaluation and reasoning:
```
**Priority Evaluation: [priority number] (priority-meaning)**

**Rationale:**
- **Is it correct?** [✅ Yes/❌ No] - (ex. SwiftLint rule conflicts are verified and cause development workflow issues)
- **Is it relevant?** [✅ Yes/❌ No] - (ex. Directly affects daily development workflow and code consistency)
- **Is it beneficial?** [✅ Yes/❌ No] - (ex. Fixing will eliminate auto-fix conflicts and improve developer experience)
- **Is it safe?** [✅ Yes/❌ No] - (ex. Configuration changes are low-risk)

**Impact:** [ex. HIGH - Development workflow efficiency, prevents continuous formatting conflicts.]

[ex. This is a critical development infrastructure issue that should be resolved before merge to prevent ongoing developer friction.]
```
**EVALUATION CRITERIA**

**Common High Priority Patterns**
- **Invalid Tests** (wrong assertions, missing cases, always passing, false confidence)
- **Actual bugs** (null checks, error handling)
- **Security vulnerabilities** (unless false positive)
- **Resource leaks** (unclosed connections, memory leaks)
- **Type safety issues** (TypeScript/type hints)
- **Logic errors** (off-by-one, incorrect conditions)
- **Missing error handling** 

**Common Low Priority Patterns**
- **Style preferences** that conflict with project conventions
- **Generic best practices** that don't apply to our specific use case
- **Performance optimizations** for code that isn't performance-critical
- **Accessibility suggestions** for internal tools
- **Security warnings** for already-validated patterns
- **Import reorganization** that would break our structure

**Decision Framework**
For each comment, consider:
1. **Is it correct?** - Does the issue actually exist?
2. **Is it relevant?** - Does it apply to our use case?
3. **Is it beneficial?** - Will fixing it improve the code?
4. **Is it safe?** - Could the change introduce problems?

Issues are high priority only if all answers are "yes" or the benefit clearly outweighs risks.

**Important Notes**
- Comments are helpful but lack context
- Trust your understanding of the codebase over generic suggestions
- Explain decisions briefly to maintain audit trail
- Standard issue grooming applies (close duplicates, non-issues, etc.)

#### 5.3. Present to the user
```
📋 Evaluation Summary

Comments Processed: {count}
  
P0 Issues (must fix before merge): 
- [link-to-new-issue-number]: {reason_for_priority}
P1 Issues (should fix before merge):
- [link-to-new-issue-number]: {reason_for_priority}
P2 Issues (can defer until after merge):
- [link-to-new-issue-number]: {reason_for_priority}
P3 Issues (minor improvement):
- [link-to-new-issue-number]: {reason_for_priority}
Won't Fix Issues (safe to close-not-planned):
- [link-to-new-issue-number]: {reason_for_priority}

Next Steps:
1. 📋 Review the issues created from PR comments
2. 🛠️ Address all P0 and P1 issues before proceeding with the merge
3. 🔄 Once all critical issues are resolved, resume this merge process from Step 6: `/pm:issue-merge $PR_NUMBER`
```

---

### 6. Update Context Docs

**Before merging**, update project documentation while you still have branch context:

Run Slash Command `/context:update` to document changes from this PR.

This captures what the PR accomplished while the branch diffs are still available.

---

### 7. Document Feature

If this is a major new feature, now is a good time to document it's functionality in the `docs/features/` folder.

- Primary purpose -  describe what the feature does, including algorithms, data flows, and architecture
- Easy to understand for a broad audience - Anyone should be able to read the documentation and understand how the feature works
- Visuals > code - Favor diagrams, flowcharts, and step-by-step explainatory text over code snippets where possible

If this is a refactoring of alorythmic business logic, find existing documentation in `docs/features/` and update it to reflect the new implementation.

---

### 8. Merge After Approval

1. Run final checks:
```bash
# Ensure no regressions since last check
./scripts/check-all.sh --skip-ui 2>&1 | tail -75 
```
2. Present summary to user:
```bash
✅ All checks passed successfully!

Proceed with merge?

# OR...

❌ Issues found:
- 2 lint errors: 
  [lint error details]
- 1 failed test:
  [test failure details]

Would you like me to fix these before merging?
```

3.  Merge PR (creates merge commit)
```bash
# Only if explicitly approved by user
gh pr merge $PR_NUMBER --merge --delete-branch

echo "✅ PR #$PR_NUMBER merged and branch deleted"
```

---

### 9. Post-Merge Cleanup

After merge completes:
```bash
# Get branch name from pr title for cleanup
gh pr view $PR_NUMBER --json title -q .title

# Switch to main and update
git checkout main
git pull origin main

# Verify merge completed
git log --oneline -10 | grep "#$PR_NUMBER" && echo "✅ PR #$PR_NUMBER successfully merged to main"

# Clean up local branch (if it exists)
git branch -d $branch_name 2>/dev/null && echo "✅ Local branch deleted: $branch_name" || echo "ℹ️ Local branch $branch_name already deleted"
```

---

### 10. Final Output

```bash
echo "
✅ PR #$PR_NUMBER Merge Complete

Pull Request:
  PR #$PR_NUMBER: Merged ✓
  Branch: $branch_name → main (deleted)

Status:
  ✓ PR reviewed and approved
  ✓ Merged with rebase
  ✓ Branch cleaned up
  ✓ Tests passed

Next Steps:
  - To deploy test build to TestFlight: /devops:deploy-testflight
"

```

## PR Review Guidelines

When reviewing the created PR:

1. **Code Quality**
   - All changes follow project conventions
   - No debug code or commented sections
   - Proper error handling implemented

2. **Testing**
   - Unit tests updated/added
   - UI tests pass
   - Manual testing completed

3. **Documentation**
   - README updated if needed
   - Code comments added for complex logic
   - Epic documentation complete

4. **Dependencies**
   - No unnecessary dependencies added
   - Existing dependencies updated safely
   - Breaking changes documented

## GitHub Merge Options

**Using "Rebase and merge" (default strategy):**
- Preserves individual commit history for development traceability
- Enables checkout to any point in development history
- Maintains clean linear history without merge commits
- Allows granular rollback of specific changes
- Better for debugging and development analysis

**Alternative merge strategies (if needed):**
- **Squash merge**: Clean single commit (use for very messy branches)
- **Regular merge**: Preserves branch structure (use for collaborative branches)

## Important Notes

- PR should already exist from /issue-start
- Always wait for review approval before merging
- Use rebase merge to preserve development history while keeping main branch linear
