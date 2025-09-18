# Branch Operations

There is a 1-to-1-to-1 mapping between Issue, Branch, and PR.

## Creating Branches

Always create branches from a clean main branch:
```bash
# Ensure main is up to date
git checkout main
git pull origin main

# Create branch for issue
# where {name} is [issue-number]-[issue-name], e.g. 1234-add-login
git checkout -b issue/{name}
git push -u origin issue/{name}
```

The branch will be created and pushed to origin with upstream tracking.

## Draft Pull Request Creation

A draft PR should be created immediately when the branch is created:
```bash
# Create draft PR after pushing branch
gh pr create --draft --title "Issue #XX: Brief description" --body "Resolves #XX

## Summary
Brief description of what this issue addresses.

## Implementation
- [ ] Task 1
- [ ] Task 2
- [ ] Tests added
"
```

This allows for early feedback and tracks progress on the issue.

## Working in Branches

### Determine current issue number

Try these methods in order until you find the issue number:

1. **Branch name** (check first):
   ```bash
   git branch --show-current
   ```
   - Look for patterns like `issue-42`, `issue/42`, `feat/issue-42-description`
   - Extract: `git branch --show-current | grep -oE 'issue-?[0-9]+' | grep -oE '[0-9]+'`

2. **PR name/description** (if branch has an open PR):
   ```bash
   gh pr view --json title,body,number
   ```
   - Check PR title for `#42` or `issue #42`
   - Check PR body for linked issues
   - The PR itself might be the issue number

3. **Recent commits** (if not found above):
   ```bash
   git log --oneline -10 | grep -i "issue\|#"
   ```
   - Look for patterns like `#42`, `issue #42`, `fixes #42`, `closes #42`
   - Extract: `git log --oneline -10 | grep -oE '#[0-9]+' | head -1 | tr -d '#'`

4. **If still unsure, ask the user**:
   - "I couldn't determine the issue number from the branch name, PR, or recent commits. What issue number should I use?"
   - This ensures accuracy rather than guessing


### Agent Commits
- Agents commit directly to the branch
- Use small, focused commits
- Commit message format: `Issue #{number}: {description}`
- Example: `Issue #1234: Add user authentication schema`

### File Operations
```bash
# Working directory is the current directory
# (no need to change directories like with worktrees)

# Normal git operations work
git add {files}
git commit -m "Issue #{number}: {change}"

# View branch status
git status
git log --oneline -5
```

## Parallel Work in Same Branch

Multiple agents can work in the same branch if they coordinate file access:
```bash
# Agent A works on API
git add src/api/*
git commit -m "Issue #1234: Add user endpoints"

# Agent B works on UI (coordinate to avoid conflicts!)
git pull origin issue/{name}  # Get latest changes
git add src/ui/*
git commit -m "Issue #1235: Add dashboard component"
```

## Merging Branches

Branch merging is PR-driven. When issue is complete:

1. **Mark PR as ready for review**:
```bash
# Convert draft to ready PR
gh pr ready
```

2. **Request and complete PR review process**:
```bash
# Request review from team members
gh pr review --request-reviewer @username

# Check PR status and reviews
gh pr status
gh pr view 12

# Address review feedback if needed
# Make additional commits to address comments
```

3. **Merge via GitHub PR** (after approval):
```bash
# Merge PR #12 only after review approval
gh pr merge 12 --squash --delete-branch
```

4. **Alternative: Manual merge** (if needed):
```bash
# From main repository
git checkout main
git pull origin main

# Merge issue branch
git merge issue/{name}

# If successful, clean up
git branch -d issue/{name}
git push origin --delete issue/{name}
```

The PR-driven approach provides better tracking and ensures all checks pass before merging.

## Handling Conflicts

If merge conflicts occur:
```bash
# Conflicts will be shown
git status

# Human resolves conflicts
# Then continue merge
git add {resolved-files}
git commit
```

## Branch Management

### List Active Branches
```bash
git branch -a
```

### Remove Stale Branch
```bash
# Delete local branch
git branch -d issue/{name}

# Delete remote branch
git push origin --delete issue/{name}
```

### Check Branch Status
```bash
# Current branch info
git branch -v

# Compare with main
git log --oneline main..issue/{name}
```

## Best Practices

1. **One branch per issue** - One focused branch per GitHub issue
2. **Clean before create** - Always start from updated main
3. **Commit frequently** - Small commits are easier to merge
4. **Pull before push** - Get latest changes to avoid conflicts
5. **Use descriptive branches** - `issue/feature-name` not `feature`

## Common Issues

### Branch Already Exists
```bash
# Delete old branch first
git branch -D issue/{name}
git push origin --delete issue/{name}
# Then create new one
```

### Cannot Push Branch
```bash
# Check if branch exists remotely
git ls-remote origin issue/{name}

# Push with upstream
git push -u origin issue/{name}
```

### Merge Conflicts During Pull
```bash
# Stash changes if needed
git stash

# Pull and rebase
git pull --rebase origin issue/{name}

# Restore changes
git stash pop
```
