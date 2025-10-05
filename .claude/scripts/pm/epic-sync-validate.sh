#!/bin/bash

# Pre-validation for epic sync
# Usage: epic-sync-validate.sh <epic-name>

epic_name="$1"

if [ -z "$epic_name" ]; then
  echo "❌ Usage: epic-sync-validate.sh <epic-name>"
  exit 1
fi

# Check epic exists
if [ ! -f ".claude/epics/$epic_name/epic.md" ]; then
  echo "❌ Epic not found: .claude/epics/$epic_name/epic.md"
  echo "Run: /pm:prd-parse $epic_name"
  exit 1
fi

# Count task files
task_count=$(ls ".claude/epics/$epic_name/"*.md 2>/dev/null | grep -v epic.md | wc -l | tr -d ' ')

if [ "$task_count" -eq 0 ]; then
  echo "❌ No tasks found in .claude/epics/$epic_name/"
  echo "Run: /pm:epic-decompose $epic_name"
  exit 1
fi

echo "✅ Found epic with $task_count tasks"
echo "$task_count" > /tmp/task-count.txt
