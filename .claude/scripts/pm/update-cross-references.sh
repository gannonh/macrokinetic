#!/bin/bash

# Update cross-references in task files from old task IDs to new GitHub issue numbers
# Usage: update-cross-references.sh <epic-name>

epic_name="$1"

if [ -z "$epic_name" ]; then
  echo "❌ Usage: update-cross-references.sh <epic-name>"
  exit 1
fi

if [ ! -f "/tmp/issue-mapping.txt" ]; then
  echo "❌ Mapping file not found: /tmp/issue-mapping.txt"
  exit 1
fi

echo "Updating cross-references..."

# For each renamed task file
for task_file in .claude/epics/$epic_name/[0-9]*.md; do
  [ -f "$task_file" ] || continue

  # Create temp file
  temp_file="${task_file}.tmp"
  cp "$task_file" "$temp_file"

  # Apply each mapping
  while IFS=: read -r old_num new_num; do
    # Skip comment lines
    if echo "$old_num" | grep -q "^#"; then
      continue
    fi

    # Replace in task_id, depends_on, and conflicts_with fields
    sed -i.bak \
      -e "/^task_id:/s/$old_num/$new_num/g" \
      -e "/^depends_on:/s/$old_num/$new_num/g" \
      -e "/^conflicts_with:/s/$old_num/$new_num/g" \
      "$temp_file"
    rm -f "${temp_file}.bak"
  done < /tmp/issue-mapping.txt

  # Replace original file with updated version
  mv "$temp_file" "$task_file"
done

echo "✅ Cross-references updated"
