#!/bin/bash

# Final validation for epic sync
# Usage: epic-sync-final-validate.sh <epic-name>

epic_name="$1"

if [ -z "$epic_name" ]; then
  echo "❌ Usage: epic-sync-final-validate.sh <epic-name>"
  exit 1
fi

epic_number=$(cat /tmp/epic-number.txt)

echo ""
echo "Running final validation..."

# Validate epic exists on GitHub
if ! gh issue view "$epic_number" > /dev/null 2>&1; then
  echo "❌ Epic #$epic_number not found on GitHub"
  exit 1
fi

# Validate all task files exist with GitHub numbers
validation_failed=false

if [ -f "/tmp/issue-mapping.txt" ]; then
  while IFS=: read -r old_num new_num; do
    # Skip comment lines
    if echo "$old_num" | grep -q "^#"; then
      continue
    fi

    # Check file exists
    if [ ! -f ".claude/epics/$epic_name/${new_num}.md" ]; then
      echo "❌ File missing: ${new_num}.md (was ${old_num}.md)"
      validation_failed=true
    fi

    # Check GitHub issue exists
    if ! gh issue view "$new_num" > /dev/null 2>&1; then
      echo "❌ GitHub issue #$new_num not found"
      validation_failed=true
    fi
  done < /tmp/issue-mapping.txt
fi

if [ "$validation_failed" = true ]; then
  echo "❌ Validation failed"
  exit 1
fi

echo "✅ All validations passed"
