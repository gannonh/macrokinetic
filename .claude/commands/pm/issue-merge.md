---
allowed-tools: Read, Write, Bash(gh pr view:*), Bash(gh issue:*)
description: Merge completed PR from branch to main using GitHub Pull Request workflow
argument-hint: [pr-number]
model: claude-sonnet-4-20250514
---

# PR Merge

Merge completed PR from branch to main using GitHub Pull Request workflow.

**ULTRATHINK** and use TodoWrite to keep track of your tasks.

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

The merge process is multi-step. It is possible the user is starting from Step 1, or resuming from a later step in the process. Therefore, your first task is to ask te user what step they would like to start from:

```bash
At which step would you like to start? (1-8)"
1. Pre-Merge Validation"
2. Run Checks & Fix Issues"
3. Mark PR as Ready for Review"
4. Request Review"
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

#### 4.1 Deploy Review Agents

Deploy code-quality-analyzer and test-quality-analyzer agents in parallel to the PR: $ARGUMENTS

#### 4.2 Request GitHub Reviewers
Ask user to requests reviewers on github, monitor status, then resume this merge process from Step 5 once he comments are in. 

Format as follows:

---
Step 4: Request Review

  Action Required:
  1. Go to the PR URL: https://github.com/gannonh/jab-tracker-ios/pull/$ARGUMENTS
  2. Request reviewers from your team members
  3. Monitor the PR for review comments and approvals
  4. Once all reviews are completed, come back and resume this merge process from Step 5: `/pm:issue-merge $ARGUMENTS`
---

### 5. Process PR Comments

#### Instructions

1. Inform the user:
```
I'll create a new GitHub issue for each PR comment. 
```

2. Create issues from comments
```bash
# Create new issue for each comment
gh pr view $ARGUMENTS --comments --json comments -q '.comments[] | {body: .body, author: .author.login, createdAt: .createdAt}' | while read -r comment; do
  issue_title="PR #$ARGUMENTS - [issue-title]"
  issue_body="Comment by $(echo "$comment" | jq -r .author) on $(echo "$comment" | jq -r .createdAt):\n\n$(echo "$comment" | jq -r .body)"
  gh issue create --title "$issue_title" --body "$issue_body"
done

```
3. Evaluate and prioritize issues

- Evaluate each new issue
- Read the issue
- Read the relevant code files for context
- Prioritize each issue based on severity and impact using GitHub labels:
  - [P0] Critical: Must be fixed before merge
  - [P1] Important: Should be fixed before merge
  - [P2] Optional: Can be deferred until after merge
  - [P3] Low: Minor improvement, no immediate action needed
  - [wont-fix] Won't fix: Not applicable or not worth addressing
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

#### Evaluation Criteria

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

4. Present to the user
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

After receiving approval:
```bash
# Merge PR with rebase (preserves individual commits)
gh pr merge $ARGUMENTS --rebase --delete-branch

✅ PR #$ARGUMENTS merged and branch deleted"
```

### 7. Post-Merge Cleanup

After merge completes:
```bash
# Get branch name for cleanup
branch_name=$(gh pr view $ARGUMENTS --json headRefName -q .headRefName)

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