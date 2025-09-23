#!/bin/bash
echo "Getting status..."
echo ""
echo ""

echo "📋 Next Available Tasks"
echo "======================="
echo ""

# Find tasks that are open and have no dependencies or whose dependencies are closed
found=0
deferred_count=0

for epic_dir in .claude/epics/*/; do
  [ -d "$epic_dir" ] || continue
  epic_name=$(basename "$epic_dir")

  for task_file in "$epic_dir"[0-9]*.md; do
    [ -f "$task_file" ] || continue

    # Skip analysis and review files
    task_basename=$(basename "$task_file")
    if [[ "$task_basename" == *"-analysis.md" ]] || [[ "$task_basename" == *"-review.md" ]] || [[ "$task_basename" == *"-code-quality.md" ]] || [[ "$task_basename" == *"-test-quality.md" ]]; then
      continue
    fi

    # Skip files without frontmatter
    if ! grep -q "^---$" "$task_file"; then
      echo "⚠️  Skipping $task_basename: Missing YAML frontmatter (run /pm:validate-tasks to fix)"
      continue
    fi

    # Check task status
    status=$(grep "^status:" "$task_file" | head -1 | sed 's/^status: *//')

    # Skip deferred tasks but count them
    if [ "$status" = "deferred" ]; then
      ((deferred_count++))
      continue
    fi

    # Skip other non-open tasks
    [ "$status" != "open" ] && [ -n "$status" ] && continue

    # Check dependencies
    deps=$(grep "^depends_on:" "$task_file" | head -1 | sed 's/^depends_on: *\[//' | sed 's/\]//')

    # If no dependencies or empty, task is available
    if [ -z "$deps" ] || [ "$deps" = "depends_on:" ]; then
      task_name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
      task_num=$(basename "$task_file" .md)
      parallel=$(grep "^parallel:" "$task_file" | head -1 | sed 's/^parallel: *//')

      echo "✅ Ready: #$task_num - $task_name"
      echo "   Epic: $epic_name"
      [ "$parallel" = "true" ] && echo "   🔄 Can run in parallel"
      echo ""
      ((found++))
    else
      # Check if all dependencies are satisfied
      dependencies_met=true

      # Split dependencies by comma and check each one
      IFS=',' read -ra dep_array <<< "$deps"
      for dep in "${dep_array[@]}"; do
        # Remove whitespace
        dep=$(echo "$dep" | tr -d ' ')

        # Find the dependency file in current epic
        dep_file="$epic_dir$dep.md"

        if [ -f "$dep_file" ]; then
          dep_status=$(grep "^status:" "$dep_file" | head -1 | sed 's/^status: *//')
          if [ "$dep_status" != "closed" ] && [ "$dep_status" != "completed" ]; then
            dependencies_met=false
            break
          fi
        else
          # Dependency file not found - assume not met
          dependencies_met=false
          break
        fi
      done

      # If all dependencies are satisfied, task is ready
      if [ "$dependencies_met" = "true" ]; then
        task_name=$(grep "^name:" "$task_file" | head -1 | sed 's/^name: *//')
        task_num=$(basename "$task_file" .md)
        parallel=$(grep "^parallel:" "$task_file" | head -1 | sed 's/^parallel: *//')

        echo "✅ Ready: #$task_num - $task_name"
        echo "   Epic: $epic_name"
        [ "$parallel" = "true" ] && echo "   🔄 Can run in parallel"
        echo ""
        ((found++))
      fi
    fi
  done
done

if [ $found -eq 0 ]; then
  echo "No available tasks found."
  echo ""
  echo "💡 Suggestions:"
  echo "  • Check blocked tasks: /pm:blocked"
  echo "  • View all tasks: /pm:epic-list"
  if [ $deferred_count -gt 0 ]; then
    echo "  • Review deferred tasks: /pm:issue-edit {issue_number} to reactivate"
  fi
fi

echo ""
echo "📊 Summary: $found tasks ready to start"
if [ $deferred_count -gt 0 ]; then
  echo "🚫 Deferred: $deferred_count tasks postponed (excluded from next task selection)"
fi

exit 0
