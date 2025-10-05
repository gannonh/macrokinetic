#!/bin/bash

# Display epic sync summary
# Usage: epic-sync-summary.sh <epic-name>

epic_name="$1"

if [ -z "$epic_name" ]; then
  echo "❌ Usage: epic-sync-summary.sh <epic-name>"
  exit 1
fi

epic_number=$(cat /tmp/epic-number.txt)
epic_title=$(cat /tmp/epic-title.txt)
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
epic_url="https://github.com/$repo/issues/$epic_number"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Epic Sync Complete"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Epic: #$epic_number - $epic_title"
echo "  → $epic_url"
echo ""

# Count tasks
total_count=$(ls ".claude/epics/$epic_name/"[0-9]*.md 2>/dev/null | wc -l | tr -d ' ')
echo "Tasks created: $total_count"

# Show mapping if available
if [ -f "/tmp/issue-mapping.txt" ]; then
  echo ""
  echo "Task Mapping (old → new):"
  while IFS=: read -r old_num new_num; do
    # Skip comment lines
    if echo "$old_num" | grep -q "^#"; then
      continue
    fi

    task_title=$(grep '^title:' ".claude/epics/$epic_name/${new_num}.md" | sed 's/^title: *//')
    printf "  %s → #%-3s  %s\n" "$old_num" "$new_num" "$task_title"
  done < /tmp/issue-mapping.txt
fi

echo ""
echo "Next steps:"
echo "  • View epic: gh issue view $epic_number --web"
echo "  • Start work: /pm:issue-start <issue_number>"
echo "  • Analyze task: /pm:issue-analyze <issue_number>"
echo ""
