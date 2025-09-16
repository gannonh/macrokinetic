---
allowed-tools: Read, Write
description: Merge completed issue from branch to main using GitHub Pull Request workflow
argument-hint: Issue number (e.g., 42)
---

# Issue Merge

Merge completed issue from branch to main using GitHub Pull Request workflow.

## Quick Check

1. **Determine issue name***
   ```bash
   issue_name=$(gh issue view $ARGUMENTS --json title -q .title | tr ' ' '-')
   echo "Issue branch name: issue/${issue_name}"
   ```

2. **Verify branch exists:**
   ```bash
   git branch | grep "issue/{issue_name}" || echo "❌ No branch for issue: $ARGUMENTS"
   ```

3. **Check PR status:**
   ```bash
   gh pr view issue/{issue_name} --json state,isDraft -q '.state + " (draft: " + (.isDraft|tostring) + ")"' || echo "❌ No PR found for issue branch"
   ```

## Instructions

### 1. Pre-Merge Validation

Check current branch status:
```bash
# Ensure we're on the issue branch
git checkout issue/{issue_name}

# Check for uncommitted changes
if [[ $(git status --porcelain) ]]; then
  echo "⚠️ Uncommitted changes in branch:"
  git status --short
  echo "Commit or stash changes before merging"
  exit 1
fi

# Update branch with latest changes
git fetch origin
git push origin issue/{issue_name}
git status -sb
```

### 2. Run Checks 

1. Run final checks: `./scripts/check-all.sh --skip-ui`
2. If ANY failures or violations:
   - **⚠️ STOP MERGE PROCESS ⚠️**
   - Provide summary of issues found, eg:
     ```
     ❌ 3 lint errors
     ❌ 2 failed tests
     ❌ 1 security vulnerability
     ```
  - Wait for further instruction
3. If all checks pass, proceed to next step

### 3. Mark PR as Ready for Review

If PR is still a draft:
```bash
# Convert draft to ready PR
gh pr ready issue/{issue_name}
echo "✅ PR marked as ready for review"
```

### 4. Request Review

```bash
# PR should already exist from issue-start
# Request review from team members
gh pr review issue/{issue_name} --request-reviewer @username

# Check PR status and reviews
gh pr status
gh pr view issue/{issue_name}

echo "🔍 Waiting for code review approval..."
echo "Monitor PR at: $(gh pr view issue/{issue_name} --json url -q .url)"
```

### 5. Merge After Approval

After receiving approval:
```bash
# Get PR number
pr_number=$(gh pr view issue/{issue_name} --json number -q .number)

# Merge PR with squash
gh pr merge $pr_number --squash --delete-branch

echo "✅ PR #$pr_number merged and branch deleted"
```

### 6. Post-Merge Cleanup

After merge completes:
```bash
# Switch to main and update
git checkout main
git pull origin main

# Verify merge completed
if git log --oneline -5 | grep -q "#$ARGUMENTS"; then
  echo "✅ Issue #$ARGUMENTS successfully merged to main"
else
  echo "❌ Issue #$ARGUMENTS not found in main branch history"
  exit 1
fi

# Clean up local branch
git branch -d issue/{issue_name}
echo "✅ Local branch deleted: issue/{issue_name}"
```

### 7. Next Steps

```bash
echo "
🎯 Next: Close the issue
  Run: /pm:issue-close $ARGUMENTS

This will:
  - Close GitHub issue #$ARGUMENTS
  - Update epic progress
  - Capture learnings
"
```

### 8. Final Output

```
✅ Issue #$ARGUMENTS Merge Complete

Pull Request:
  PR #$pr_number: Merged ✓
  Branch: issue/{issue_name} → main (deleted)

Status:
  ✓ PR reviewed and approved
  ✓ Merged with squash commit
  ✓ Branch cleaned up
  ✓ Tests passed

Next Step:
  Run: /pm:issue-close $ARGUMENTS
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

Recommend using **"Squash and merge"** for epic branches:
- Creates clean commit history
- Preserves epic context in commit message
- Easier to revert if needed

## Important Notes

- PR should already exist from /pm:issue-start
- Always wait for review approval before merging
- Use squash merge to keep main branch clean
- Run /pm:issue-close after merge to close the issue
- Consider CI/CD pipeline requirements