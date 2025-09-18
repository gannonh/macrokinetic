---
description: Validate and fix task file formats, converting Markdown metadata to YAML frontmatter
argument-hint: Epic name (optional - validates all epics if not provided)
allowed-tools: Read, Write, LS
---

# Validate Tasks

Validate and fix task file formats, converting Markdown metadata to YAML frontmatter.

## Usage
```
/pm:validate-tasks [epic_name]
```

If epic_name provided, validate only that epic. Otherwise validate all epics.

## Instructions

### 1. Find Task Files

```bash
if [ -n "$ARGUMENTS" ]; then
  # Validate specific epic
  epic_dirs=(".claude/epics/$ARGUMENTS/")
else
  # Validate all epics
  epic_dirs=(.claude/epics/*/)
fi

total_tasks=0
fixed_tasks=0
error_tasks=0
```

### 2. Validate Each Epic

For each epic directory:

```bash
for epic_dir in "${epic_dirs[@]}"; do
  [ -d "$epic_dir" ] || continue
  epic_name=$(basename "$epic_dir")

  echo "🔍 Validating epic: $epic_name"
  echo ""

  # Find numbered task files
  for task_file in "$epic_dir"[0-9][0-9][0-9].md; do
    [ -f "$task_file" ] || continue

    # Skip analysis and review files
    task_basename=$(basename "$task_file")
    if [[ "$task_basename" == *"-analysis.md" ]] || [[ "$task_basename" == *"-review.md" ]]; then
      continue
    fi

    ((total_tasks++))

    # Check if file has frontmatter
    if grep -q "^---$" "$task_file"; then
      echo "✅ $task_basename: Already has YAML frontmatter"
    else
      echo "🔄 $task_basename: Converting Markdown to YAML frontmatter"
      convert_task_format "$task_file" && ((fixed_tasks++)) || ((error_tasks++))
    fi
  done

  echo ""
done
```

### 3. Conversion Function

```bash
convert_task_format() {
  local task_file="$1"
  local temp_file=$(mktemp)
  local task_basename=$(basename "$task_file")
  local task_number=$(echo "$task_basename" | sed 's/\.md$//')

  # Extract metadata from Markdown format
  local task_title=$(grep "^# Task" "$task_file" | sed 's/^# Task [0-9]*: *//')
  local created_date=$(grep "^\*\*Created\*\*:" "$task_file" | sed 's/^\*\*Created\*\*: *//')
  local dependencies=$(grep "^\*\*Dependencies\*\*:" "$task_file" | sed 's/^\*\*Dependencies\*\*: *//')
  local priority=$(grep "^\*\*Priority\*\*:" "$task_file" | sed 's/^\*\*Priority\*\*: *//')

  # Get current timestamp
  local current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Determine parallel flag based on dependencies
  local parallel="true"
  if [[ "$dependencies" =~ \[[0-9] ]]; then
    parallel="false"  # Has dependencies, likely sequential
  fi

  # Convert dependencies format
  local deps_yaml="[]"
  if [[ "$dependencies" =~ \[([0-9, ]*)\] ]]; then
    local deps_content="${BASH_REMATCH[1]}"
    if [ -n "$deps_content" ]; then
      deps_yaml="[$(echo "$deps_content" | sed 's/ //g')]"
    fi
  fi

  # Create YAML frontmatter
  cat > "$temp_file" << EOF
---
name: $task_title
status: open
created: ${created_date:-$current_date}
updated: $current_date
github:
depends_on: $deps_yaml
parallel: $parallel
conflicts_with: []
---

# Task: $task_title

## Description
EOF

  # Extract content after first Overview/Description section
  sed -n '/^## Overview/,$ p; /^## Description/,$ p; /^## Requirements/,$ p' "$task_file" | \
    sed '1s/^## Overview/## Description/' >> "$temp_file"

  # Replace original file
  if mv "$temp_file" "$task_file"; then
    echo "   ✅ Converted to YAML frontmatter"
    return 0
  else
    echo "   ❌ Failed to convert"
    rm -f "$temp_file"
    return 1
  fi
}
```

### 4. Validate Dependencies

After conversion, check dependency references:

```bash
validate_dependencies() {
  local epic_dir="$1"
  local epic_name=$(basename "$epic_dir")

  echo "🔍 Validating dependencies in $epic_name..."

  for task_file in "$epic_dir"[0-9][0-9][0-9].md; do
    [ -f "$task_file" ] || continue

    # Skip analysis files
    task_basename=$(basename "$task_file")
    if [[ "$task_basename" == *"-analysis.md" ]] || [[ "$task_basename" == *"-review.md" ]]; then
      continue
    fi

    # Check each dependency exists
    local deps=$(grep "^depends_on:" "$task_file" | sed 's/^depends_on: *\[//' | sed 's/\]//' | tr ',' ' ')

    for dep in $deps; do
      dep=$(echo "$dep" | tr -d ' ')
      if [ -n "$dep" ] && [ "$dep" != "depends_on:" ]; then
        local dep_file="$epic_dir$(printf "%03d" "$dep").md"
        if [ ! -f "$dep_file" ]; then
          echo "⚠️  $(basename "$task_file"): Dependency $dep not found"
        fi
      fi
    done
  done
}
```

### 5. Output Summary

```
📊 Validation Summary
====================

Total tasks checked: $total_tasks
Tasks fixed: $fixed_tasks
Tasks with errors: $error_tasks
Tasks already valid: $((total_tasks - fixed_tasks - error_tasks))

✅ All tasks now have proper YAML frontmatter
```

## Error Handling

- If conversion fails, preserve original file
- Report specific errors for each task
- Continue processing other tasks even if some fail
- Never leave tasks in broken state

## Validation Rules

1. **YAML Frontmatter Required**: All tasks must have `---` delimited frontmatter
2. **Required Fields**: `name`, `status`, `created`, `updated`, `depends_on`, `parallel`
3. **Status Values**: Must be `open`, `closed`, or `completed`
4. **Dependencies**: Must reference existing task numbers
5. **Parallel Flag**: Set based on dependencies and potential conflicts

This command ensures all task files follow the standard format expected by other PM system commands.