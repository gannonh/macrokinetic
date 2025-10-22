---
description: Merge completed PR from branch to main using GitHub Pull Request workflow
argument-hint: [pr-number]
---

# PR Merge

Merge completed PR from branch to main using GitHub Pull Request workflow.

## Quick Check

1. **Check PR status:**
   ```bash
   gh pr view $ARGUMENTS --json state,isDraft,headRefName -q '.state + " (draft: " + (.isDraft|tostring) + ") - Branch: " + .headRefName' || ❌ PR #$ARGUMENTS not found"
   ```

2. **Get branch name from PR:**
   ```bash
   branch_name=$(gh pr view $ARGUMENTS --json headRefName -q .headRefName)
   📋 PR #$ARGUMENTS uses branch: $branch_name"
   ```

## Instructions

The merge process is multi-step. It is possible the user is starting from Step 1, or resuming from a later step in the process. Therefore, your first task is to ask the user from which step they would like to start:

```bash
At which step would you like to start? (1-8)"
1. Pre-Merge Validation"
2. Run Checks & Fix Issues"
3. Mark PR as Ready for Review"
4. Request Reviews"
5. Process PR Comments"
6. Merge After Approval"
7. Post-Merge Cleanup"
8. Next Steps"
```

Based on the user's response, proceed to that step and continue through the remaining steps in order.

### 1. Pre-Merge Validation

Check current branch status:
```bash
# Get branch name from PR
branch_name=$(gh pr view $ARGUMENTS --json headRefName -q .headRefName)

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

### 2. Run Checks & Fix Issues

1. Run `./scripts/check-coverage-config.sh` add any missing files to `coverage-config.json` if needed
2. Run final checks: `./scripts/check-all.sh --skip-ui`
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

### 3. Mark PR as Ready for Review

If PR is still a draft:
```bash
gh pr ready $ARGUMENTS
✅ PR #$ARGUMENTS marked as ready for review"
```

### 4. Request Reviews

#### 4.0 CodeRabbit Review

Ask the user to...

1. Run CodeRabbit
2. Process CodeRabbit comments with `/qa:code-rabbit [paste comments]`
3. Return here when done to give the go-ahead for continuing to Step 4.1

**IMPORTANT:** Do NOT proceed to Step 4.1 until you receive explicit permission from the user.

#### 4.1 Deploy Review Agents

Deploy code-quality-analyzer and test-quality-analyzer agents in parallel to the PR: $ARGUMENTS

#### 4.2 Request GitHub Reviewers
Ask user to requests reviewers on github, monitor status, then resume this merge process from Step 5 once comments are in. 

Format as follows:

---
Step 4: Request Review

  Action Required:
  1. Go to the PR URL: https://github.com/gannonh/jab-tracker-ios/pull/$ARGUMENTS
  2. Request reviewers from your team members
  3. Monitor the PR for review comments and approvals
  4. Once all reviews are completed, come back and resume this merge process from Step 5: `/pm:issue-merge $ARGUMENTS`
---

**important:** Do NOT proceed to Step 5 until explicitly asked to do so by the user.

### 5. Process PR Comments

#### 5.1. Create GitHub Issues from PR Feedback

**Your Task:**
Read ALL PR feedback sources, analyze the content, present summary to user, and create individual GitHub issues for each distinct actionable recommendation.

**Step 1: Fetch All Feedback Sources**

Use these commands to retrieve all types of feedback:

```bash
# 1. PR-level conversation comments
gh pr view $ARGUMENTS --json comments --jq '.comments[] | {
  author: .author.login,
  created: .createdAt,
  body: .body
}'

# 2. Inline code review comments (line-specific)
gh api repos/OWNER/REPO/pulls/$ARGUMENTS/comments --jq '.[] | {
  author: .user.login,
  file: .path,
  line: .line,
  body: .body
}'

# 3. Review summaries (overall review state and comments)
gh pr view $ARGUMENTS --json reviews --jq '.reviews[] | {
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
  --title "PR #$ARGUMENTS - [descriptive title]" \
  --body "[detailed description with context]"
```

**Guidelines for Issue Creation:**

- **Large analyzer reports** (test quality, code quality): Parse them to extract **individual issues**
  - Example: 
    - DO NOT: create 1 issue for "test quality report"
    - DO: create Issue for "6 placeholder tests", separate issue for "missed dose coverage", etc.
- **Related recommendations**: Group similar items into one issue when it makes sense
  - Example: 4 Copilot comments about "hardcoded scheduledDoseId" → 1 grouped issue
- **Individual comments**: Each specific recommendation gets its own issue
- **Context**: Include enough detail so the issue can be understood without reading the PR
- **Traceability**: Always prefix with "PR #$ARGUMENTS - "

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
3. 🔄 Once all critical issues are resolved, resume this merge process from Step 6: `/pm:pr-merge $ARGUMENTS`
```

### 6. Merge After Approval

1. Run final checks:
```bash
# Ensure no regressions since last check
./scripts/check-all.sh 
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

3.  Merge PR with rebase (preserves individual commits)
```bash
# Only if explicitly approved by user
gh pr merge $ARGUMENTS --rebase --delete-branch

✅ PR #$ARGUMENTS merged and branch deleted"
```

### 7. Post-Merge Cleanup

After merge completes:
```bash
# Get branch name from pr title for cleanup
gh pr view $ARGUMENTS --json title -q .title

# Switch to main and update
git checkout main
git pull origin main

# Verify merge completed
if git log --oneline -5 | grep -q "#$ARGUMENTS"; then
  ✅ PR #$ARGUMENTS successfully merged to main"
else
  ❌ PR #$ARGUMENTS not found in main branch history"
  exit 1
fi

# Clean up local branch (if it exists)
if git branch | grep -q "$branch_name"; then
  git branch -d $branch_name
  ✅ Local branch deleted: $branch_name"
else
  ℹ️ Local branch $branch_name already deleted"
fi
```

### 8. Next Steps

```bash
# Extract issue number from PR title (format: "Issue #42: Title")
issue_number=$(gh pr view $ARGUMENTS --json title -q .title | sed -n 's/.*Issue #\([0-9]*\):.*/\1/p')

if [ -n "$issue_number" ]; then
  
🎯 Next: Close the associated issue
  Run: /pm:issue-close $issue_number

This will:
  - Close GitHub issue #$issue_number
  - Update epic progress
  - Capture learnings
"
else
  
ℹ️ No associated issue found in PR title
PR #$ARGUMENTS has been merged successfully
"
fi
```

### 9. Final Output

```bash

✅ PR #$ARGUMENTS Merge Complete

Pull Request:
  PR #$ARGUMENTS: Merged ✓
  Branch: $branch_name → main (deleted)

Status:
  ✓ PR reviewed and approved
  ✓ Merged with squash commit
  ✓ Branch cleaned up
  ✓ Tests passed
"

# Show next step if issue number was found
if [ -n "$issue_number" ]; then
  Next Step: Run /pm:issue-close $issue_number"
fi
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

- PR should already exist from /pm:issue-start
- Always wait for review approval before merging
- Use rebase merge to preserve development history while keeping main branch linear
- Run /pm:issue-close after merge to close the issue
- Consider CI/CD pipeline requirements