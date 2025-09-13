---
allowed-tools: Bash, Read, Write
description: Merge completed epic from branch to main using GitHub Pull Request workflow
argument-hint: Epic name (e.g., dose-tracking)
---

# Epic Merge

Merge completed epic from branch to main using GitHub Pull Request workflow.

## Quick Check

1. **Verify branch exists:**
   ```bash
   git branch | grep "epic/$ARGUMENTS" || echo "❌ No branch for epic: $ARGUMENTS"
   ```

2. **Check for active agents:**
   Read `.claude/epics/$ARGUMENTS/execution-status.md`
   If active agents exist: "⚠️ Active agents detected. Stop them first with: /pm:epic-stop $ARGUMENTS"

## Instructions

### 1. Pre-Merge Validation

Check current branch status:
```bash
# Ensure we're on the epic branch
git checkout epic/$ARGUMENTS

# Check for uncommitted changes
if [[ $(git status --porcelain) ]]; then
  echo "⚠️ Uncommitted changes in branch:"
  git status --short
  echo "Commit or stash changes before merging"
  exit 1
fi

# Update branch with latest changes
git fetch origin
git push origin epic/$ARGUMENTS
git status -sb
```

### 2. Run Checks (Optional but Recommended)

```bash

./scripts/check-all.sh --skip-ui  || echo "⚠️ Checks failed. Continue anyway? (yes/no)"

```

### 3. Update Epic Documentation

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update `.claude/epics/$ARGUMENTS/epic.md`:
- Set status to "completed"
- Update completion date
- Add final summary

### 4. Create Pull Request

```bash
# Ensure branch is pushed to origin
git push origin epic/$ARGUMENTS

# Create PR with comprehensive description
pr_title="Epic: $ARGUMENTS"
pr_body="## Epic Summary

Completed epic: $ARGUMENTS

### Features Implemented
$(cd .claude/epics/$ARGUMENTS && ls *.md | grep -E '^[0-9]+' | while read f; do
  echo "- $(grep '^name:' $f | cut -d: -f2 | tr -d ' ')" 2>/dev/null || echo "- $(basename $f .md)"
done)

### Testing
- [ ] Unit tests pass
- [ ] UI tests pass
- [ ] Manual testing completed
- [ ] Code review completed

### Related Issues
$(grep 'github:' .claude/epics/$ARGUMENTS/epic.md | grep -oE '#[0-9]+' || echo "No linked issues")

### Deployment Notes
- Review changes before merging
- Consider deployment impact
- Update documentation if needed

## Checklist
- [x] All commits are clean and descriptive
- [x] Branch is up to date with main
- [x] Epic documentation updated
- [ ] Code review completed
- [ ] Ready to merge"

# Create the PR
gh pr create \
  --title "$pr_title" \
  --body "$pr_body" \
  --base main \
  --head epic/$ARGUMENTS \
  --draft=false

echo "✅ Pull Request created successfully"
```

### 5. Monitor PR Status

```bash
# Get PR number and URL
pr_url=$(gh pr view epic/$ARGUMENTS --json url -q .url)
pr_number=$(gh pr view epic/$ARGUMENTS --json number -q .number)

echo "
📋 Pull Request Details:
  Number: #$pr_number
  URL: $pr_url
  Branch: epic/$ARGUMENTS → main

Next Steps:
1. Review the PR in GitHub
2. Address any CI/CD checks
3. Request code review if needed
4. Merge when ready using GitHub UI
"
```

### 6. Post-Merge Cleanup (Run after GitHub merge)

After the PR is merged in GitHub UI:
```bash
# Switch to main and update
git checkout main
git pull origin main

# Verify merge completed
if git log --oneline -5 | grep -q "$ARGUMENTS"; then
  echo "✅ Epic successfully merged to main"
else
  echo "❌ Epic not found in main branch history"
  exit 1
fi

# Clean up local branch
git branch -d epic/$ARGUMENTS
echo "✅ Local branch deleted: epic/$ARGUMENTS"

# Archive epic locally
mkdir -p .claude/epics/archived/
mv .claude/epics/$ARGUMENTS .claude/epics/archived/
echo "✅ Epic archived: .claude/epics/archived/$ARGUMENTS"
```

### 7. Update GitHub Issues

Close related issues:
```bash
# Get issue numbers from epic
epic_issue=$(grep 'github:' .claude/epics/archived/$ARGUMENTS/epic.md | grep -oE '[0-9]+$')

# Close epic issue
if [ ! -z "$epic_issue" ]; then
  gh issue close $epic_issue -c "Epic completed and merged to main via PR #$pr_number"
fi

# Close task issues
for task_file in .claude/epics/archived/$ARGUMENTS/[0-9]*.md; do
  issue_num=$(grep 'github:' $task_file | grep -oE '[0-9]+$' 2>/dev/null)
  if [ ! -z "$issue_num" ]; then
    gh issue close $issue_num -c "Completed in epic merge via PR #$pr_number"
  fi
done
```

### 8. Final Output

```
✅ Epic Ready for Merge: $ARGUMENTS

Pull Request Created:
  PR #$pr_number: $pr_url
  Branch: epic/$ARGUMENTS → main
  Status: Ready for review

Epic Status:
  ✓ Branch pushed to GitHub
  ✓ PR created with details
  ✓ Epic documentation updated
  ✓ Tests validated

Next Steps:
  1. Review PR in GitHub: $pr_url
  2. Address any CI/CD feedback
  3. Merge PR when approved
  4. Run post-merge cleanup: /pm:epic-cleanup $ARGUMENTS

After Merge:
  - Clean up local branch
  - Archive epic documentation
  - Close related GitHub issues
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

- Always create PR instead of direct merge
- Use GitHub's review process for quality control
- Preserve epic history in PR description
- Archive epic data instead of deleting
- Close GitHub issues after successful merge
- Consider CI/CD pipeline requirements