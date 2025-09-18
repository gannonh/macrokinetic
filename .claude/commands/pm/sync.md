---
description: Full bidirectional sync between local and GitHub.
argument-hint: Epic name to sync (e.g., dose-tracking)
allowed-tools: Read, Write, LS
---

# Sync

Full bidirectional sync between local and GitHub.

If epic_name provided, sync only that epic. Otherwise sync all.

## Instructions

### 1. Pull from GitHub

Get current state of all issues:
```bash
# Get all epic and task issues
gh issue list --label "epic" --limit 1000 --json number,title,state,body,labels,updatedAt
gh issue list --label "task" --limit 1000 --json number,title,state,body,labels,updatedAt
```

### 2. Validate Local Files

Before syncing, ensure all local files have proper format:
```bash
# Check for files without frontmatter
invalid_files=()
for epic_dir in .claude/epics/*/; do
  [ -d "$epic_dir" ] || continue

  for task_file in "$epic_dir"[0-9][0-9][0-9].md; do
    [ -f "$task_file" ] || continue

    # Skip analysis/review files
    if [[ "$(basename "$task_file")" == *"-analysis.md" ]] || [[ "$(basename "$task_file")" == *"-review.md" ]]; then
      continue
    fi

    # Check for frontmatter
    if ! grep -q "^---$" "$task_file"; then
      invalid_files+=("$task_file")
    fi
  done
done

if [ ${#invalid_files[@]} -gt 0 ]; then
  echo "❌ Found ${#invalid_files[@]} task files without proper YAML frontmatter:"
  printf "   %s\n" "${invalid_files[@]}"
  echo ""
  echo "Fix with: /pm:validate-tasks"
  echo "Or continue anyway? (y/N)"
  read -r continue_sync
  if [[ "$continue_sync" != "y" && "$continue_sync" != "Y" ]]; then
    echo "Sync cancelled. Please fix task formats first."
    exit 1
  fi
fi
```

### 3. Update Local from GitHub

For each GitHub issue:
- Find corresponding local file by issue number
- Compare states:
  - If GitHub state newer (updatedAt > local updated), update local
  - If GitHub closed but local open, close local
  - If GitHub reopened but local closed, reopen local
- Update frontmatter to match GitHub state (only for files with frontmatter)

### 4. Push Local to GitHub

For each local task/epic:
- If has GitHub URL but GitHub issue not found, it was deleted - mark local as archived
- If no GitHub URL, create new issue (like epic-sync)
- If local updated > GitHub updatedAt, push changes:
  ```bash
  gh issue edit {number} --body-file {local_file}
  ```

### 5. Handle Conflicts

If both changed (local and GitHub updated since last sync):
- Show both versions
- Ask user: "Local and GitHub both changed. Keep: (local/github/merge)?"
- Apply user's choice

### 6. Update Sync Timestamps

Update all synced files with last_sync timestamp.

### 7. Output

```
🔄 Sync Complete

Pulled from GitHub:
  Updated: {count} files
  Closed: {count} issues
  
Pushed to GitHub:
  Updated: {count} issues
  Created: {count} new issues
  
Conflicts resolved: {count}

Status:
  ✅ All files synced
  {or list any sync failures}
```

## Important Notes

Follow `/rules/github-operations.md` for GitHub commands.
Follow `/rules/frontmatter-operations.md` for local updates.
Always backup before sync in case of issues.