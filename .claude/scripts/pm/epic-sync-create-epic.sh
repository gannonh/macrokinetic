#!/bin/bash

# Create epic issue on GitHub
# Usage: epic-sync-create-epic.sh <epic-name>

epic_name="$1"

if [ -z "$epic_name" ]; then
  echo "❌ Usage: epic-sync-create-epic.sh <epic-name>"
  exit 1
fi

epic_file=".claude/epics/$epic_name/epic.md"

# Extract epic content (strip frontmatter)
sed '1,/^---$/d; 1,/^---$/d' "$epic_file" > /tmp/epic-body.md

# Get epic title from frontmatter or use epic name
epic_title=$(grep '^name:' "$epic_file" | sed 's/^name: *//')
if [ -z "$epic_title" ]; then
  epic_title="$epic_name"
fi

# Store epic title for later use
echo "$epic_title" > /tmp/epic-title.txt

# Create epic issue
echo "Creating epic issue..."
url=$(gh issue create \
  --title "Epic: $epic_title" \
  --body-file /tmp/epic-body.md \
  --label "epic,feature")

# Extract epic number from URL
epic_number=$(echo "$url" | grep -o '[0-9]*$')

echo "✅ Created epic: #$epic_number"
echo "$epic_number" > /tmp/epic-number.txt

# Validate epic was created
if ! gh issue view "$epic_number" > /dev/null 2>&1; then
  echo "❌ Failed to verify epic #$epic_number"
  exit 1
fi

echo "✅ Epic #$epic_number verified"
