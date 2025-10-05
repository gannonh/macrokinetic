#!/bin/bash

# Create GitHub sub-issues for all tasks in an epic sequentially
# Usage: create-tasks-sequential.sh <epic-name> <epic-number> <use-subissues>

epic_name="$1"
epic_number="$2"
use_subissues="$3"

if [ -z "$epic_name" ] || [ -z "$epic_number" ]; then
  echo "❌ Usage: create-tasks-sequential.sh <epic-name> <epic-number> <use-subissues>"
  exit 1
fi

# Initialize mapping file
echo "# Old to New Issue Number Mapping" > /tmp/issue-mapping.txt
echo "# Format: old_number:new_number" >> /tmp/issue-mapping.txt

# Get repository info once
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# Process each task file in order
for task_file in $(ls ".claude/epics/$epic_name/"*.md 2>/dev/null | grep -v epic.md | sort); do
  [ -f "$task_file" ] || continue

  # Get old task number (001, 002, etc.)
  old_num=$(basename "$task_file" .md)

  # Extract task title from frontmatter
  task_title=$(grep '^title:' "$task_file" | sed 's/^title: *//')
  if [ -z "$task_title" ]; then
    task_title=$(grep '^name:' "$task_file" | sed 's/^name: *//')
  fi

  # Read task body (strip frontmatter)
  task_body=$(sed '1,/^---$/d; 1,/^---$/d' "$task_file")

  echo "Creating task $old_num: $task_title"

  # Create sub-issue (or regular issue if gh-sub-issue not available)
  if [ "$use_subissues" = "true" ]; then
    url=$(gh sub-issue create \
      --parent "$epic_number" \
      --title "$task_title" \
      --body "$task_body" \
      --label "task" 2>&1 | grep 'https://github.com' | head -1)
  else
    url=$(gh issue create \
      --title "$task_title" \
      --body "$task_body" \
      --label "task" 2>&1 | tail -1)
  fi

  # Extract new issue number from URL
  new_num=$(echo "$url" | grep -o '[0-9]*$')

  echo "  → Created issue #$new_num"

  # Validate issue was created
  if ! gh issue view "$new_num" > /dev/null 2>&1; then
    echo "❌ Failed to verify issue #$new_num for task $old_num"
    exit 1
  fi

  # Record mapping
  echo "$old_num:$new_num" >> /tmp/issue-mapping.txt

  # Rename file immediately
  new_file=".claude/epics/$epic_name/${new_num}.md"
  mv "$task_file" "$new_file"
  echo "  → Renamed: $old_num.md → ${new_num}.md"

  # Update frontmatter with GitHub URL
  github_url="https://github.com/$repo/issues/$new_num"
  current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  sed -i.bak "s|^github:.*|github: $github_url|" "$new_file"
  sed -i.bak "s|^updated:.*|updated: $current_date|" "$new_file"
  rm "${new_file}.bak"

  echo "  → Updated frontmatter"
  echo ""
done

echo "✅ All tasks created and renamed"
