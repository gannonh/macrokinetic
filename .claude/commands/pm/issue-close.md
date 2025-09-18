---
description: Mark an issue as complete and close it on GitHub
argument-hint: issue number (e.g., 42)
allowed-tools: Bash, Read, Write, LS
model: claude-sonnet-4-20250514
---

# Issue Close

Mark an issue as complete and close it on GitHub.

## Instructions

### 1. Verify PR is Merged

First check that the issue's PR has been merged:
```bash
# Check if PR exists and is merged
if gh pr view issue/{issue_name} >/dev/null 2>&1; then
  pr_state=$(gh pr view issue/{issue_name} --json state -q .state)
  if [ "$pr_state" != "MERGED" ]; then
    echo "❌ PR for issue #$ARGUMENTS is not merged yet"
    echo "   Current state: $pr_state"
    echo "   Run: /pm:issue-merge $ARGUMENTS first"
    exit 1
  fi
else
  echo "⚠️  No PR found for issue #$ARGUMENTS - proceed to close issue directly?"
fi
```

### 2. Find Local Task File

First check if `.claude/epics/*/$ARGUMENTS.md` exists (new naming).
If not found: "❌ No local task for issue #$ARGUMENTS"

### 3. Update Local Status

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update task file frontmatter:
```yaml
status: closed
updated: {current_datetime}
```

### 4. Update Progress File

If progress file exists at `.claude/epics/{epic}/updates/$ARGUMENTS/progress.md`:
- Set completion: 100%
- Add completion note with timestamp
- Update last_sync with current datetime

### 5. Close on GitHub

Add completion comment and close:
```bash
# Add final comment
echo "✅ Task completed

Issue #$ARGUMENTS

---
Closed at: {timestamp}" | gh issue comment $ARGUMENTS --body-file -

# Close the issue
gh issue close $ARGUMENTS
```

### 6. Update Epic Task List on GitHub

Check the task checkbox in the epic issue:

```bash
# Get epic name from local task file path
epic_name={extract_from_path}

# Get epic issue number from epic.md
epic_issue=$(grep 'github:' .claude/epics/$epic_name/epic.md | grep -oE '[0-9]+$')

if [ ! -z "$epic_issue" ]; then
  # Get current epic body
  gh issue view $epic_issue --json body -q .body > /tmp/epic-body.md
  
  # Check off this task
  sed -i "s/- \[ \] #$ARGUMENTS/- [x] #$ARGUMENTS/" /tmp/epic-body.md
  
  # Update epic issue
  gh issue edit $epic_issue --body-file /tmp/epic-body.md
  
  echo "✓ Updated epic progress on GitHub"
fi
```

### 7. Update Epic Progress

- Count total tasks in epic
- Count closed tasks
- Calculate new progress percentage
- Update epic.md frontmatter progress field

### 8. Capture Session Learnings

Add learnings section to issue file if significant discoveries were made:

```markdown
## Learnings & Knowledge Capture

### Technical Patterns → system-patterns.md
- {testing patterns, architecture decisions, implementation approaches}

### Technology Insights → tech-context.md  
- {framework-specific knowledge, tool discoveries, integration insights}

### Process Insights → progress.md
- {debugging approaches, workflow improvements, coordination lessons}

### Product Insights → product-context.md
- {user experience discoveries, feature insights, requirement clarifications}

### Project Structure → project-structure.md
- {file organization learnings, structure improvements}

**Learnings Status**: `learnings_captured: false`
```

Update frontmatter:
```yaml
learnings_captured: false  # flag for context/update.md to process
```
Commit documentation updates.

### 9. Output

```
✅ Closed issue #$ARGUMENTS
  PR: Merged and branch deleted ✓
  Local: Task marked complete ✓
  GitHub: Issue closed & epic updated ✓
  Epic progress: {new_progress}% ({closed}/{total} tasks complete)

Next: Run /pm:next for next priority task
```

## Important Notes

Follow `/rules/frontmatter-operations.md` for updates.
Follow `/rules/github-operations.md` for GitHub commands.
Always sync local state before GitHub.