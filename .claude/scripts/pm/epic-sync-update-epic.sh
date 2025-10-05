#!/bin/bash

# Update epic.md with GitHub URL and task list
# Usage: epic-sync-update-epic.sh <epic-name>

epic_name="$1"

if [ -z "$epic_name" ]; then
  echo "❌ Usage: epic-sync-update-epic.sh <epic-name>"
  exit 1
fi

epic_file=".claude/epics/$epic_name/epic.md"
epic_number=$(cat /tmp/epic-number.txt)

echo "Updating epic.md..."

# Update epic frontmatter
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
epic_url="https://github.com/$repo/issues/$epic_number"
current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Update github field
sed -i.bak "s|^github:.*|github: $epic_url|" "$epic_file"
# Update updated field
sed -i.bak "s|^updated:.*|updated: $current_date|" "$epic_file"
rm "${epic_file}.bak"

# Build new Tasks Created section
cat > /tmp/tasks-section.md << 'EOF'
## Tasks Created
EOF

# Add each task in numeric order
for task_file in $(ls ".claude/epics/$epic_name/"[0-9]*.md 2>/dev/null | sort -V); do
  [ -f "$task_file" ] || continue

  issue_num=$(basename "$task_file" .md)
  task_title=$(grep '^title:' "$task_file" | sed 's/^title: *//')

  echo "- [ ] #${issue_num} - ${task_title}" >> /tmp/tasks-section.md
done

# Add statistics
total_count=$(ls ".claude/epics/$epic_name/"[0-9]*.md 2>/dev/null | wc -l | tr -d ' ')
parallel_count=$(grep -l '^parallel: true' ".claude/epics/$epic_name/"[0-9]*.md 2>/dev/null | wc -l | tr -d ' ')
sequential_count=$((total_count - parallel_count))

cat >> /tmp/tasks-section.md << EOF

Total tasks: ${total_count}
Parallel tasks: ${parallel_count}
Sequential tasks: ${sequential_count}
EOF

# Replace Tasks Created section in epic.md using perl
perl -i -pe '
  BEGIN { undef $/; }
  s/## Tasks Created.*?(?=\n## |\z)/`cat \/tmp\/tasks-section.md`/se
' "$epic_file"

echo "✅ Epic file updated"
