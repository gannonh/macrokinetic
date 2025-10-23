---
description: Create a new issue locally and on GitHub.
argument-hint: [epic name (e.g., dose-tracking)] [Additional context (optional)]
---

# Issue Create

- Create a new issue locally and on GitHub and associate with the relevant epic, or
- Associate an existing GitHub issue with a different epic

Epic: $1

Additional context (optional): $2

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `.claude/rules/datetime.md` - For getting real current date/time

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress ("I'm not going to ..."). Just do them and move on.

1. **Verify epic exists:**
   - Check if `.claude/epics/$1/epic.md` exists
   - If not found, tell user: "❌ Epic not found: $1. First create it with: /pm:prd-parse $1"
   - Stop execution if epic doesn't exist

2. **Get epic details:**
   - Read `.claude/epics/$1/epic.md` to understand epic context
   - Extract epic name from frontmatter

## Instructions

You are working with epic: **$1**

### Determine Issue Type

Ask the user:

1. Create new issue or associate existing GitHub issue?

Proceed accordingly based on issue type.

---

### For Existing Issues

When user wants to associate an existing GitHub issue with this epic:

#### 1. Get GitHub Issue Number and Clean Up Title
- Ask user for the GitHub issue number
- Fetch issue details: `gh issue view {issue_number} --json number,title,body,labels,url`

**Clean up title:**
```bash
# Get current title
current_title=$(gh issue view {issue_number} --json title --jq '.title')

# Remove PR prefix patterns like "PR #274: " or "PR#274: " or "PR #274 - "
cleaned_title=$(echo "$current_title" | sed -E 's/^PR #?[0-9]+[: -]+//')

# If title was modified, update it
if [ "$cleaned_title" != "$current_title" ]; then
  gh issue edit {issue_number} --title "$cleaned_title"
  echo "✅ Cleaned title: '$current_title' -> '$cleaned_title'"
fi
```

#### 2. Associate with Epic
```bash
# First, add task label (issues associated with epics are labeled "task")
gh issue edit {issue_number} --add-label "task"

# Then, extract parent epic issue number from epic.md and link as sub-issue
# Extract the github URL from epic.md frontmatter
parent_epic_url=$(grep '^github:' .claude/epics/$1/epic.md | sed 's/github: *//')

if [ -n "$parent_epic_url" ]; then
  # Extract issue number from URL (e.g., https://github.com/owner/repo/issues/173 -> 173)
  parent_epic_issue=$(echo "$parent_epic_url" | sed 's/.*\/issues\///')

  # Link as sub-issue
  gh sub-issue add "$parent_epic_issue" {issue_number}
  echo "✅ Linked issue #{issue_number} as sub-issue of epic #${parent_epic_issue}"
else
  echo "⚠️  No parent epic issue found in epic.md, skipping sub-issue link"
fi
```

#### 3. Create Local Issue File with Full Structure

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Determine task number:
- List existing task files in `.claude/epics/$1/`
- Use the GitHub issue number as the local task number
- Create file: `.claude/epics/$1/{issue_number}.md`

**Transform GitHub issue body into structured format:**

If the GitHub issue body is minimal or missing sections, expand it to include all required sections. Use the existing body as the "Objective" or starting point, then add:

**File Format:**
```markdown
---
task_id: {issue_number}
title: {Cleaned Issue Title from GitHub}
epic: {epic_name}
phase: "{Epic Phase from epic.md}"
status: open
created: {current_datetime}
updated: {current_datetime}
assignee: @gannonh
depends_on: []
parallel: true
conflicts_with: []
effort: M
priority: medium
github: {issue_url}
branch: [Will be updated when work starts]
pr: [Will be updated when PR created]
---

# {Cleaned Issue Title}

## Objective
{Use existing GitHub issue body content, or ask user for clarification}

## Technical Approach
{Ask user how to implement - high level, or infer from objective}

## Acceptance Criteria
- [ ] AC1: {Specific criterion - ask user or infer}
- [ ] AC2: {Specific criterion}
- [ ] AC3: {Specific criterion}

## Files to Modify
- `{file_path}` - {What changes - ask user or infer}
- `{file_path}` - {What changes}

## Testing Requirements
- [ ] Test1: {Test description - infer from acceptance criteria}
- [ ] Test2: {Test description}

## Implementation Notes
{Any important considerations from GitHub issue or ask user}

## Estimated Effort
**Size**: M (or ask user)
- **Total**: {estimated hours}

## Definition of Done
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] Code review complete
```

**Process:**
1. Take the GitHub issue body as starting content
2. If sections already exist (Objective, Acceptance Criteria, etc.), preserve them
3. If sections are missing, add them by:
   - Asking user for key details (acceptance criteria, files affected, etc.)
   - Offering to help expand minimal content into structured format
4. Create the local file with complete structure

#### 4. Update GitHub Issue Body

After creating the local file with full structure, update the GitHub issue to match:

```bash
# Create temporary body file without frontmatter
body_file=$(mktemp)
sed -n '/^---$/,/^---$/!p' .claude/epics/$1/{issue_number}.md > "$body_file"

# Update GitHub issue body with the structured content
gh issue edit {issue_number} --body-file "$body_file"

# Clean up temp file
rm "$body_file"

echo "✅ Updated GitHub issue #{issue_number} with structured format"
```

#### 5. Update Local Epic File

**Read epic.md:**
- Locate the "## Tasks Created" section
- If section doesn't exist, add it after technical approach

**Add task entry:**
```markdown
## Tasks Created
- [ ] {issue_number}.md - {Issue Title} (priority: medium, parallel: true)
```

**Update epic statistics:**
```markdown
Total tasks: {count}
Parallel tasks: {parallel_count}
Sequential tasks: {sequential_count}
```

#### 6. Update GitHub Epic Issue Body

Add the new task to the epic's task list on GitHub:

```bash
# Fetch the current epic issue body
epic_body=$(gh issue view "$parent_epic_issue" --json body --jq '.body')

# Create a temporary file with the updated body
epic_body_file=$(mktemp)
echo "$epic_body" > "$epic_body_file"

# Check if "## Tasks Created" section exists
if grep -q "## Tasks Created" "$epic_body_file"; then
  # Use awk to insert the new task at the end of the task list
  awk -v task="- [ ] #{issue_number} - {Issue Title}" '
  /## Tasks Created/ { in_tasks = 1; print; next }
  in_tasks && /^$/ {
    print task
    in_tasks = 0
  }
  in_tasks && /^\*\*Total tasks:/ {
    print task
    print ""
    in_tasks = 0
  }
  { print }
  ' "$epic_body_file" > "${epic_body_file}.new"

  mv "${epic_body_file}.new" "$epic_body_file"
else
  # Add Tasks Created section if it doesn't exist
  echo "" >> "$epic_body_file"
  echo "## Tasks Created" >> "$epic_body_file"
  echo "- [ ] #{issue_number} - {Issue Title}" >> "$epic_body_file"
fi

# Update the epic issue body on GitHub
gh issue edit "$parent_epic_issue" --body-file "$epic_body_file"

# Clean up
rm "$epic_body_file"

echo "✅ Added task #${issue_number} to epic #${parent_epic_issue} task list on GitHub"
```

**Note:** This adds a checkbox item to the epic's "Tasks Created" section on GitHub, creating the visual task list shown in the GitHub UI.

#### 7. Add Epic Association Comment

Add a comment to GitHub issue noting the epic association:
```bash
gh issue comment {issue_number} --body "Associated with epic: {epic_name} (#${parent_epic_issue})"
```

#### 8. Output

```
✅ Associated issue #{issue_number} with epic: {epic_name}

📁 Local file: .claude/epics/{epic_name}/{issue_number}.md
🔗 GitHub: {issue_url}

Next steps:
  1. Review issue details: gh issue view {issue_number}
  2. Start work: /pm:issue-start {issue_number}
  3. Or analyze for parallel streams: /pm:issue-analyze {issue_number}
```

---

### For New Issues

When user wants to create a new issue from scratch:

#### 1. Gather Issue Details

Ask user for the following information:

**Required Fields:**
1. **Issue Title**: Short, descriptive title (e.g., "Fix Split-Dose Medical Accuracy")
2. **Issue Description**: What needs to be done and why (brief summary)
3. **Priority**: high, medium, low (default: medium)
4. **Effort Estimate**: XS, S, M, L, XL (default: M)

**Optional Fields:**
5. **Dependencies**: Task numbers this depends on (e.g., [175, 176])
6. **Parallel**: Can this run in parallel with other tasks? (default: true)
7. **Conflicts With**: Tasks that modify same files (e.g., [180, 181])

**Issue Body Template:**
If user provides minimal description, offer to help expand it with:
- Objective section
- Technical approach
- Acceptance criteria
- Files affected
- Testing requirements
- Implementation notes
- Definition of done

#### 2. Create Local Task File First

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Determine next task number:
- List existing task files in `.claude/epics/$1/`
- Find highest number (e.g., 180.md → 180)
- Next task number = highest + 1
- Format as 3 digits if needed (e.g., 001, 002, ..., 180, 181)

Create temporary file: `.claude/epics/$1/{task_number}.md`

**File Format:**
```markdown
---
task_id: {task_number}
title: {Issue Title}
epic: {epic_name}
phase: "{Epic Phase from epic.md}"
status: open
created: {current_datetime}
updated: {current_datetime}
assignee: @gannonh
depends_on: [{dependencies}]
parallel: {true|false}
conflicts_with: [{conflicts}]
effort: {XS|S|M|L|XL}
priority: {high|medium|low}
github: [Will be updated after creation]
branch: [Will be updated when work starts]
pr: [Will be updated when PR created]
---

# {Issue Title}

## Objective
{What needs to be done and why}

## Technical Approach
{How to implement - high level}

## Acceptance Criteria
- [ ] AC1: {Specific criterion}
- [ ] AC2: {Specific criterion}
- [ ] AC3: {Specific criterion}

## Files to Modify
- `{file_path}` - {What changes}
- `{file_path}` - {What changes}

## Testing Requirements
- [ ] Test1: {Test description}
- [ ] Test2: {Test description}

## Implementation Notes
{Any important considerations}

## Estimated Effort
**Size**: {XS|S|M|L|XL}
- **Total**: {estimated hours}

## Definition of Done
- [ ] Implementation complete
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] Code review complete
```

#### 3. Create GitHub Issue

**Prepare Issue Body:**
- Read the local task file content
- Strip YAML frontmatter (everything between `---` markers)
- Use the remaining markdown as the issue body

**Create Issue:**
```bash
# Create temporary body file without frontmatter
body_file=$(mktemp)
sed -n '/^---$/,/^---$/!p' .claude/epics/$1/{task_number}.md > "$body_file"

# Create issue with task label (issues associated with epics are labeled "task")
gh issue create \
  --title "{Issue Title}" \
  --body-file "$body_file" \
  --label "task" \
  --assignee @me

# Clean up temp file
rm "$body_file"
```

**Capture Issue Details:**
```bash
# Get the created issue number and URL
issue_number=$(gh issue list --limit 1 --json number --jq '.[0].number')
issue_url=$(gh issue list --limit 1 --json url --jq '.[0].url')
```

#### 4. Associate with Epic using gh sub-issue

```bash
# Extract parent epic issue number from epic.md and link as sub-issue
# Extract the github URL from epic.md frontmatter
parent_epic_url=$(grep '^github:' .claude/epics/$1/epic.md | sed 's/github: *//')

if [ -n "$parent_epic_url" ]; then
  # Extract issue number from URL (e.g., https://github.com/owner/repo/issues/173 -> 173)
  parent_epic_issue=$(echo "$parent_epic_url" | sed 's/.*\/issues\///')

  # Link as sub-issue
  gh sub-issue add "$parent_epic_issue" "$issue_number"
  echo "✅ Linked issue #${issue_number} as sub-issue of epic #${parent_epic_issue}"
else
  echo "⚠️  No parent epic issue found in epic.md, skipping sub-issue link"
fi
```

#### 5. Update Local Task File with GitHub Info

Update the task file frontmatter with GitHub details:

```yaml
github: https://github.com/gannonh/jab-tracker-ios/issues/{issue_number}
```

Get current datetime again for updated field: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

**Important:** If the task number doesn't match the GitHub issue number:
- Rename file from `{task_number}.md` to `{issue_number}.md`
- Update `task_id` in frontmatter to match GitHub issue number
- This keeps local and GitHub in sync

#### 6. Update Local Epic Task List

**Read epic.md:**
- Locate the "## Tasks Created" section
- If section doesn't exist, add it after technical approach

**Add new task entry:**
```markdown
## Tasks Created
- [ ] {issue_number}.md - {Issue Title} (priority: {priority}, parallel: {true|false})
```

**Update epic statistics:**
```markdown
Total tasks: {count}
Parallel tasks: {parallel_count}
Sequential tasks: {sequential_count}
```

#### 7. Update GitHub Epic Issue Body

Add the new task to the epic's task list on GitHub:

```bash
# Fetch the current epic issue body
epic_body=$(gh issue view "$parent_epic_issue" --json body --jq '.body')

# Create a temporary file with the updated body
epic_body_file=$(mktemp)
echo "$epic_body" > "$epic_body_file"

# Check if "## Tasks Created" section exists
if grep -q "## Tasks Created" "$epic_body_file"; then
  # Use awk to insert the new task at the end of the task list
  awk -v task="- [ ] #{issue_number} - {Issue Title}" '
  /## Tasks Created/ { in_tasks = 1; print; next }
  in_tasks && /^$/ {
    print task
    in_tasks = 0
  }
  in_tasks && /^\*\*Total tasks:/ {
    print task
    print ""
    in_tasks = 0
  }
  { print }
  ' "$epic_body_file" > "${epic_body_file}.new"

  mv "${epic_body_file}.new" "$epic_body_file"
else
  # Add Tasks Created section if it doesn't exist
  echo "" >> "$epic_body_file"
  echo "## Tasks Created" >> "$epic_body_file"
  echo "- [ ] #{issue_number} - {Issue Title}" >> "$epic_body_file"
fi

# Update the epic issue body on GitHub
gh issue edit "$parent_epic_issue" --body-file "$epic_body_file"

# Clean up
rm "$epic_body_file"

echo "✅ Added task #${issue_number} to epic #${parent_epic_issue} task list on GitHub"
```

**Note:** This adds a checkbox item to the epic's "Tasks Created" section on GitHub, creating the visual task list shown in the GitHub UI.

#### 8. Output

For successful creation:
```
✅ Created issue #{issue_number}: {Issue Title}

📁 Local file: .claude/epics/{epic_name}/{issue_number}.md
🔗 GitHub: {issue_url}

Details:
  Epic: {epic_name}
  Priority: {priority}
  Effort: {effort_estimate}
  Parallel: {parallel}
  Dependencies: {depends_on}

Next steps:
  1. Review issue details on GitHub
  2. Start work: /pm:issue-start {issue_number}
  3. Or analyze for parallel streams: /pm:issue-analyze {issue_number}
```

For errors:
```
❌ Failed to create issue

Error: {error_message}

Troubleshooting:
  - Verify epic exists: .claude/epics/{epic_name}/epic.md
  - Check GitHub authentication: gh auth status
  - Verify issue body format is valid markdown
  - Check gh CLI version: gh --version
```

---

## Important Notes

### Task Numbering
- For existing issues: Use the GitHub issue number as task number
- For new issues: Initially use next sequential number, then rename to match GitHub issue number after creation
- Always use 3 digits with leading zeros for sequential numbers (001, 002, ..., 099, 100)
- Never reuse task numbers

### GitHub Integration
- Issue body comes from task file (minus frontmatter)
- Issues associated with epics are labeled "task"
- Epics themselves are labeled "epic, feature"
- Assignee defaults to current user (@me)
- Issue number and URL stored in local task file
- gh sub-issue extension used to create parent-child relationships

### Epic Synchronization
- Always update epic.md with new task entry
- Maintain task statistics (total, parallel, sequential)
- Keep task list in chronological order

### Frontmatter Consistency
- Follow exact format from template
- All date fields use ISO 8601 format (UTC)
- GitHub URL, branch, and PR initially empty (updated during workflow)
- Effort uses XS|S|M|L|XL scale
- Priority uses high|medium|low scale

### Validation
- Epic must exist before creating issues
- Issue title required (no default)
- Description can be minimal but should be expandable
- All frontmatter fields must be present (even if empty)

## Error Recovery

If any step fails:
- If local file created but GitHub fails: retry GitHub creation with same details
- If GitHub succeeds but local update fails: update local file with GitHub info
- If file numbering mismatch: rename local file to match GitHub issue number
- Never leave inconsistent state between local and GitHub
- Always provide clear error messages with recovery steps

## Additional Context Handling

If user provides additional context via $2:
- Parse additional context as issue description enhancement
- Combine with user answers to create comprehensive issue body
- Ask clarifying questions if context is ambiguous

Example:
```
/pm:issue-create dose-scheduling "Fix notification timing bug for split-dose schedules"
```
- Epic: dose-scheduling
- Title suggestion: "Fix notification timing bug for split-dose schedules"
- Ask user to confirm or modify title
- Ask for priority, effort, dependencies, etc.
