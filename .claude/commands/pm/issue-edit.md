---
description: Edit issue details (title, description, labels) locally and on GitHub.
argument-hint: Issue number (e.g., 42)
allowed-tools: Read, Write, Edit, Bash, LS
---

# Issue Edit

Edit issue details locally and on GitHub.

## Instructions

### Agent Mode

engage ULTRATHINK.

### 1. Get Current Issue State

```bash
# Get from GitHub
gh issue view $ARGUMENTS --json title,body,labels

# Find local task file
# Search for file with github:.*issues/$ARGUMENTS
```

### 2. Interactive Edit

Ask user what to edit:
1. Title
2. Description/Body
3. Labels
4. Acceptance criteria (local only)
5. Priority/Size (local only)
6. Defer issue (postpone indefinitely for future re-assessment)
7. Close issue - As not planned or no longer needed (if complete use /pm:issue-close instead)

### 3. Update Local File

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update task file with changes:
- Update frontmatter `name` if title changed
- Update body content if description changed
- Update `updated` field with current datetime

### 4. Update GitHub

If title changed:
```bash
gh issue edit $ARGUMENTS --title "{new_title}"
```

If body changed:
```bash
gh issue edit $ARGUMENTS --body-file {updated_task_file}
```

If labels changed:
```bash
gh issue edit $ARGUMENTS --add-label "{new_labels}"
gh issue edit $ARGUMENTS --remove-label "{removed_labels}"
```

### 5. Issue Deferment Process

If user chooses to defer the issue:

#### 5.1 Update Issue Title and Labels (GitHub)
```bash
# Get current issue title
current_title=$(gh issue view $ARGUMENTS --json title --jq '.title')

# Add [deferred] prefix if not already present
if [[ ! "$current_title" =~ ^\[deferred\] ]]; then
    new_title="[deferred] $current_title"
    gh issue edit $ARGUMENTS --title "$new_title"
fi

# Add deferment labels
gh issue edit $ARGUMENTS --add-label "deferred,backlog"
```

#### 5.2 Add Deferment Note to Issue
Append to issue body:
```
---
**DEFERRED**: {timestamp} - {optional_reason}
Issue postponed indefinitely for future re-assessment. No longer part of current epic scope.
```

#### 5.3 Update and Rename Local Task File
- Set `status: deferred` in frontmatter
- Add `deferred_at: {timestamp}` field
- Add `deferred_reason: "{reason}"` if provided
- Rename file to include "-deferred" suffix:
```bash
# Extract issue number from current filename
issue_num=$(basename {task_file_path} .md)
new_filename="${issue_num}-deferred.md"
new_path="$(dirname {task_file_path})/$new_filename"

# Rename the file
mv {task_file_path} "$new_path"
```

#### 5.4 Update Epic Files

**Find epic directory:**
```bash
# Extract epic name from task file path
epic_name=$(dirname {task_file_path} | basename)
epic_dir=".claude/epics/${epic_name}"
```

**Update epic.md:**
In the "Tasks Created" section, mark task as deferred:
```
- [deferred] #{issue_number} - {task_name} (deferred: {timestamp})
```

**Update execution-status.md:**
Move from current section to new "Deferred Issues" section:
```markdown
## Deferred Issues
- **Issue #{issue_number} - {task_name}** 🚫 DEFERRED ({timestamp})
  - Reason: {deferred_reason}
  - Moved from: {previous_section}
```

#### 5.5 Update Context Progress
Update `.claude/context/progress.md`:
- Move issue from active epic status to deferred section
- Recalculate epic progress percentage (exclude deferred issues)
- Add entry to update history

### 6. Output

For regular edits:
```
✅ Updated issue #$ARGUMENTS
  Changes:
    {list_of_changes_made}

Synced to GitHub: ✅
```

For deferment:
```
🚫 Deferred issue #$ARGUMENTS
  Reason: {deferred_reason}

Updates made:
  ✅ GitHub labels: added 'deferred', 'backlog'
  ✅ Issue body: added deferment note
  ✅ Local task file: status set to 'deferred'
  ✅ Epic files: moved to deferred section
  ✅ Progress tracking: updated epic progress
```

## Important Notes

Always update local first, then GitHub.
Preserve frontmatter fields not being edited.
Follow `/rules/frontmatter-operations.md`.

### Deferment Guidelines
- Deferment is for issues postponed indefinitely, not temporary blocks
- Deferred issues are excluded from epic progress calculations
- Always ask for optional reason when deferring
- Deferment can be reversed by changing status back to 'open' and removing labels
- Update all related tracking files to maintain consistency