---
description: Full bidirectional sync between local and GitHub.
argument-hint: Epic name to sync (e.g., dose-tracking)
allowed-tools: Read, Write, LS
---

# Sync

Full bidirectional sync between local and GitHub.

If epic_name provided, sync only that epic. Otherwise sync all (with confirmation).

epic_name: $ARGUMENTS

## Instructions

### 1. Confirm Global Sync (if no epic specified)

If no epic_name argument provided:
```bash
echo "⚠️  WARNING: You are about to sync ALL epics and tasks from GitHub."
echo "This will pull all issues with 'epic' and 'task' labels."
echo ""
echo "Continue with global sync? (y/N)"
read -r confirm_global
if [[ "$confirm_global" != "y" && "$confirm_global" != "Y" ]]; then
  echo "Sync cancelled. Use '/pm:sync <epic-name>' to sync a specific epic."
  exit 0
fi
```

### 2. Pull from GitHub

Get current state of issues:
```bash
if [ -n "$epic_name" ]; then
  # Sync specific epic and its tasks
  echo "Syncing epic: $epic_name"

  # Find the epic issue number by name/title
  epic_number=$(gh issue list --label "epic" --limit 1000 --json number,title | jq -r '.[] | select(.title | test("'$epic_name'"; "i")) | .number')

  if [ -z "$epic_number" ]; then
    echo "❌ Epic '$epic_name' not found"
    exit 1
  fi

  echo "Found epic #$epic_number"

  # Get epic details
  gh issue view "$epic_number" --json number,title,state,body,labels,updatedAt

  # Get all sub-issues (tasks) for this epic using gh sub-issue extension
  # Note: body field not supported, use valid fields only
  gh sub-issue list "$epic_number" --json number,title,state,url

else
  # Global sync - get all epics and their sub-issues
  echo "Performing global sync..."

  # Get all epic issues
  epic_data=$(gh issue list --label "epic" --limit 1000 --json number,title,state,body,labels,updatedAt)
  echo "$epic_data"

  # For each epic, get its sub-issues
  for epic_number in $(echo "$epic_data" | jq -r '.[].number'); do
    echo "Getting sub-issues for epic #$epic_number"
    # Use --state all to get both open and closed sub-issues
    gh sub-issue list "$epic_number" --state all --json number,title,state,url || true
  done

  # Also get any orphaned tasks (tasks without parent issues)
  all_task_numbers=$(gh issue list --label "task" --limit 1000 --json number | jq -r '.[].number')
  epic_task_numbers=$(gh issue list --label "epic" --limit 1000 | while read epic_num _; do gh sub-issue list "$epic_num" --json number 2>/dev/null | jq -r '.[].number' || true; done | sort -u)
  orphaned_tasks=$(comm -23 <(echo "$all_task_numbers" | sort) <(echo "$epic_task_numbers" | sort))

  if [ -n "$orphaned_tasks" ]; then
    echo "Found orphaned tasks (no parent epic): $orphaned_tasks"
    for task_num in $orphaned_tasks; do
      gh issue view "$task_num" --json number,title,state,body,labels,updatedAt
    done
  fi
fi
```

### 2. Validate Local Files

Before syncing, ensure all local files have proper format:
```bash
# Check for files without frontmatter
invalid_files=()

if [ -n "$epic_name" ]; then
  # Only validate the specific epic
  epic_dir=".claude/epics/$epic_name"
  if [ -d "$epic_dir" ]; then
    # Use a more robust file matching approach
    for task_file in "$epic_dir"/*.md; do
      [ -f "$task_file" ] || continue

      # Get just the filename
      filename=$(basename "$task_file")

      # Skip analysis, review, deferred files, and epic.md
      if [[ "$filename" == *"-analysis.md" ]] || [[ "$filename" == *"-review.md" ]] || [[ "$filename" == *"-deferred.md" ]] || [[ "$filename" == "epic.md" ]] || [[ "$filename" == "github-mapping.md" ]]; then
        continue
      fi

      # Only check numbered task files
      if [[ "$filename" =~ ^[0-9]+\.md$ ]]; then
        # Check for frontmatter
        if ! grep -q "^---$" "$task_file"; then
          invalid_files+=("$task_file")
        fi
      fi
    done
  fi
else
  # Global validation
  for epic_dir in .claude/epics/*/; do
    [ -d "$epic_dir" ] || continue

    for task_file in "$epic_dir"/*.md; do
      [ -f "$task_file" ] || continue

      filename=$(basename "$task_file")

      # Skip analysis, review, deferred files, and epic.md
      if [[ "$filename" == *"-analysis.md" ]] || [[ "$filename" == *"-review.md" ]] || [[ "$filename" == *"-deferred.md" ]] || [[ "$filename" == "epic.md" ]] || [[ "$filename" == "github-mapping.md" ]]; then
        continue
      fi

      # Only check numbered task files
      if [[ "$filename" =~ ^[0-9]+\.md$ ]]; then
        # Check for frontmatter
        if ! grep -q "^---$" "$task_file"; then
          invalid_files+=("$task_file")
        fi
      fi
    done
  done
fi

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
else
  echo "✅ All task files have proper frontmatter"
fi
```

### 3. Update Local from GitHub

For each epic and its sub-issues:

```bash
# Process epics
for epic in $(echo "$epic_data" | jq -r '.[] | @base64'); do
  epic_json=$(echo "$epic" | base64 -d)
  epic_number=$(echo "$epic_json" | jq -r '.number')
  epic_title=$(echo "$epic_json" | jq -r '.title')

  # Determine epic folder name (lowercase, spaces to hyphens)
  epic_folder=$(echo "$epic_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

  # Create epic directory if it doesn't exist
  mkdir -p ".claude/epics/$epic_folder"

  # Update or create epic.md file
  echo "Updating epic: $epic_folder (#$epic_number)"
  # ... existing epic update logic ...
done

# Process tasks using sub-issue relationships
for epic_number in $(echo "$epic_data" | jq -r '.[].number'); do
  epic_title=$(echo "$epic_data" | jq -r ".[] | select(.number == $epic_number) | .title")
  epic_folder=$(echo "$epic_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

  # Get sub-issues for this epic (use --state all to get both open and closed)
  sub_issues=$(gh sub-issue list "$epic_number" --state all --json number,title,state,url 2>/dev/null || echo "[]")

  for task in $(echo "$sub_issues" | jq -r '.[] | @base64'); do
    task_json=$(echo "$task" | base64 -d)
    task_number=$(echo "$task_json" | jq -r '.number')

    # Determine correct location for this task
    target_dir=".claude/epics/$epic_folder"
    target_file="$target_dir/${task_number}.md"

    # Check if task exists in wrong location
    wrong_location=$(find .claude/epics -name "${task_number}.md" -o -name "${task_number}-*.md" | grep -v "^$target_file")

    if [ -n "$wrong_location" ]; then
      echo "⚠️  Moving task #$task_number from $wrong_location to $target_file"
      mkdir -p "$target_dir"
      mv "$wrong_location" "$target_file"
    fi

    # Update task file in correct epic folder
    echo "Updating task: $epic_folder/#$task_number"
    # ... existing task update logic ...
  done
done

# Handle orphaned tasks (place in backlog)
if [ -n "$orphaned_tasks" ]; then
  mkdir -p ".claude/epics/backlog"
  for task_num in $orphaned_tasks; do
    target_file=".claude/epics/backlog/${task_num}.md"

    # Move from wrong location if exists
    wrong_location=$(find .claude/epics -name "${task_num}.md" -o -name "${task_num}-*.md" | grep -v "^$target_file")
    if [ -n "$wrong_location" ]; then
      echo "⚠️  Moving orphaned task #$task_num to backlog"
      mv "$wrong_location" "$target_file"
    fi

    echo "Updating orphaned task: backlog/#$task_num"
    # ... existing task update logic ...
  done
fi
```

For each issue:
- Find corresponding local file by issue number (in correct epic folder)
- Compare states:
  - If GitHub state newer (updatedAt > local updated), update local
  - If GitHub closed but local open, close local
  - If GitHub reopened but local closed, reopen local
  - If task moved between epics, move local file to correct epic folder
- Update frontmatter to match GitHub state (only for files with frontmatter)

### 4. Push Local to GitHub

For each local task/epic:
- If has GitHub URL but GitHub issue not found, it was deleted - mark local as archived
- If no GitHub URL, create new issue (like epic-sync)
- If local updated > GitHub updatedAt, push changes:
  ```bash
  # Extract content after frontmatter for GitHub body
  temp_file=$(mktemp)
  sed -n '/^---$/,/^---$/d; /^---$/,$p' {local_file} > "$temp_file"
  gh issue edit {number} --body-file "$temp_file"
  rm "$temp_file"
  ```

### 5. Handle Conflicts

If both changed (local and GitHub updated since last sync):
- Show both versions
- Ask user: "Local and GitHub both changed. Keep: (local/github/merge)?"
- Apply user's choice

### 6. Update Sync Timestamps

Update all synced files with last_sync timestamp:
```bash
# Update sync timestamps for synced files
current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# For each synced file, add or update last_sync timestamp
for synced_file in "${synced_files[@]}"; do
  if grep -q "last_sync:" "$synced_file"; then
    # Update existing timestamp
    sed -i "" "s/last_sync:.*/last_sync: $current_time/" "$synced_file"
  else
    # Add timestamp after conflicts_with line
    sed -i "" "/conflicts_with: \[\]/a\\
last_sync: $current_time" "$synced_file"

    # Fix any formatting issues (ensure proper line break)
    sed -i "" "s/last_sync: ${current_time}---/last_sync: ${current_time}\\
---/" "$synced_file"
  fi
done
```

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

## Common Issues and Solutions

### Issue 1: gh sub-issue JSON field errors
**Problem:** `gh sub-issue list` fails with "invalid field: body" error
**Solution:** Use only valid fields: `number,title,state,url` (body field not supported)

### Issue 2: Missing closed sub-issues
**Problem:** `gh sub-issue list` only returns open issues by default
**Solution:** Always use `--state all` flag to get both open and closed sub-issues

### Issue 3: File pattern matching failures
**Problem:** Bash globbing fails with "no matches found" for `[0-9][0-9][0-9].md` pattern
**Solution:** Use `*.md` pattern and filter with conditional logic checking `^[0-9]+\.md$` regex

### Issue 4: Variable name conflicts
**Problem:** Using `status` as variable name conflicts with shell built-in
**Solution:** Use different variable names like `task_status` or `issue_status`

### Issue 5: Frontmatter formatting issues
**Problem:** sed operations can break YAML frontmatter formatting
**Solution:** Use careful sed patterns and post-process to fix line breaks:
```bash
sed -i "" "s/last_sync: ${current_time}---/last_sync: ${current_time}\\
---/" "$synced_file"
```

### Issue 6: Content extraction for GitHub updates
**Problem:** Need to remove frontmatter when updating GitHub issue bodies
**Solution:** Use sed to extract content after frontmatter:
```bash
sed -n '/^---$/,/^---$/d; /^---$/,$p' {local_file}
```