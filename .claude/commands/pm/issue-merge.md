---
allowed-tools: Read, Write, Bash(gh pr view:*), Bash(branch_name:*), Bash(echo:*)
description: Merge completed PR from branch to main using GitHub Pull Request workflow
argument-hint: [pr-number]
model: claude-sonnet-4-20250514
---

# PR Merge

Merge completed PR from branch to main using GitHub Pull Request workflow.

## Quick Check

1. **Check PR status:**
   ```bash
   gh pr view $ARGUMENTS --json state,isDraft,headRefName -q '.state + " (draft: " + (.isDraft|tostring) + ") - Branch: " + .headRefName' || echo "❌ PR #$ARGUMENTS not found"
   ```

2. **Get branch name from PR:**
   ```bash
   branch_name=$(gh pr view $ARGUMENTS --json headRefName -q .headRefName)
   echo "📋 PR #$ARGUMENTS uses branch: $branch_name"
   ```

## Instructions

The merge process is multi-step. It is possible the user is starting from Step 1, or resuming from a later step in the process. Therefore, your first task is to ask te user what step they would like to start from:

```bash
echo "At which step would you like to start? (1-8)"
echo "1. Pre-Merge Validation"
echo "2. Run Checks & Fix Issues"
echo "3. Mark PR as Ready for Review"
echo "4. Request Review"
echo "5. Document PR Comments & Action Items"
echo "6. Merge After Approval"
echo "7. Post-Merge Cleanup"
echo "8. Next Steps"
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
  echo "⚠️ Uncommitted changes in branch:"
  git status --short
  echo "Commit or stash changes before merging"
  exit 1
fi

# Update branch with latest changes
git fetch origin
git push origin $branch_name
git status -sb
```

### 2. Run Checks & Fix Issues

1. Run final checks: `./scripts/check-all.sh --skip-ui`
2. If ANY failures or violations:
   - **⚠️ STOP MERGE PROCESS ⚠️**
   - Provide summary of issues found, eg:
     ```
     ❌ 3 lint errors
     ❌ 2 failed tests
     ❌ 1 security vulnerability
     ```
  - Fix all issues and proceed to next step
3. If all checks pass, proceed to next step

### 3. Mark PR as Ready for Review

If PR is still a draft:
```bash
gh pr ready $ARGUMENTS
echo "✅ PR #$ARGUMENTS marked as ready for review"
```

### 4. Request Review

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


### 5. Document PR Comments & Action Items

Get Current DateTime
- Run: `date -u +"%Y-%m-%dT%H:%M:%SZ"`
- Store for updating `created_at` field in modified files

Extract issue number and download PR comments to create action documentation:
```bash
# Extract issue number from PR title (format: "Issue #42: Title")
issue_number=$(gh pr view $ARGUMENTS --json title -q .title | sed -n 's/.*Issue #\([0-9]*\):.*/\1/p')

if [ -z "$issue_number" ]; then
  echo "❌ Cannot extract issue number from PR title"
  echo "Expected format: 'Issue #XX: Description'"
  gh pr view $ARGUMENTS --json title -q .title
  exit 1
fi

# Find epic directory
epic_dir=""
for dir in .claude/epics/*/; do
  if [ -d "$dir" ]; then
    epic_dir="$dir"
    break
  fi
done

if [ -z "$epic_dir" ]; then
  echo "❌ No epic directory found in .claude/epics/"
  exit 1
fi

# Create issue documentation file
issue_doc_file="${epic_dir}${issue_number}-review.md"

echo "📝 Creating issue documentation: $issue_doc_file"

# Download PR comments and create documentation
cat > "$issue_doc_file" << EOF
# Issue #${issue_number} - PR Comments & Action Items

**PR**: #${ARGUMENTS}
**Date**: $created_at
**Epic**: $(basename "$epic_dir")

## PR Summary

$(gh pr view $ARGUMENTS --json title,body -q '.title + "\n\n" + .body')

## Comments & Reviews

$(gh pr view $ARGUMENTS --comments --json comments -q '.comments[] | "### Comment by @" + .author.login + " (" + .createdAt + ")\n\n" + .body + "\n"')

$(gh api repos/:owner/:repo/pulls/$ARGUMENTS/reviews --jq '.[] | "### Review by @" + .user.login + " (" + .submitted_at + ")\n\n**State**: " + .state + "\n\n" + .body + "\n"')

## Action Items to Resolve

<!-- Template for documenting actions needed before merge -->

### Code Changes Required
- [ ] **Action Item 1**: Description of required change
  - **Context**: Reference to specific comment/review
  - **Priority**: High/Medium/Low
  - **Files affected**: List of files

- [ ] **Action Item 2**: Description of required change
  - **Context**: Reference to specific comment/review
  - **Priority**: High/Medium/Low
  - **Files affected**: List of files

### Documentation Updates
- [ ] **Doc Update 1**: Description of documentation change needed
  - **Context**: Reference to comment requesting clarification
  - **Files to update**: List of documentation files

### Testing Requirements
- [ ] **Test Addition 1**: Description of additional test coverage needed
  - **Context**: Reference to review feedback
  - **Test files**: List of test files to modify/create

### Questions to Resolve
- [ ] **Question 1**: Description of unresolved question
  - **Context**: Reference to specific comment thread
  - **Stakeholder**: Who needs to provide answer

## Completion Checklist

- [ ] All code changes implemented and tested
- [ ] Documentation updates completed
- [ ] Additional tests added and passing
- [ ] All questions resolved with stakeholders
- [ ] Final review approval received
- [ ] Ready for merge

## Notes

<!-- Add any additional context, decisions made, or important information -->

EOF

echo "✅ Issue documentation created: $issue_doc_file"
echo ""
echo "📋 Next steps:"
echo "1. Review the downloaded comments and action items"
echo "2. Edit $issue_doc_file to add specific action items"
echo "3. Address all action items before proceeding to merge"
echo "4. Update checkboxes as items are completed"
echo ""
echo "📖 To view the documentation:"
echo "   cat $issue_doc_file"
```

### 6. Merge After Approval

After receiving approval:
```bash
# Merge PR with squash
gh pr merge $ARGUMENTS --squash --delete-branch

echo "✅ PR #$ARGUMENTS merged and branch deleted"
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
  echo "✅ PR #$ARGUMENTS successfully merged to main"
else
  echo "❌ PR #$ARGUMENTS not found in main branch history"
  exit 1
fi

# Clean up local branch (if it exists)
if git branch | grep -q "$branch_name"; then
  git branch -d $branch_name
  echo "✅ Local branch deleted: $branch_name"
else
  echo "ℹ️ Local branch $branch_name already deleted"
fi
```

### 8. Next Steps

```bash
# Extract issue number from PR title (format: "Issue #42: Title")
issue_number=$(gh pr view $ARGUMENTS --json title -q .title | sed -n 's/.*Issue #\([0-9]*\):.*/\1/p')

if [ -n "$issue_number" ]; then
  echo "
🎯 Next: Close the associated issue
  Run: /pm:issue-close $issue_number

This will:
  - Close GitHub issue #$issue_number
  - Update epic progress
  - Capture learnings
"
else
  echo "
ℹ️ No associated issue found in PR title
PR #$ARGUMENTS has been merged successfully
"
fi
```

### 9. Final Output

```bash
echo "
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
  echo "Next Step: Run /pm:issue-close $issue_number"
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