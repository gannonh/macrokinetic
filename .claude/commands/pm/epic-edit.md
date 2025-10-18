---
description: Edit epic details after creation.
argument-hint: [Epic name (e.g., dose-tracking)] [Additional context (optional)]
allowed-tools: Read, Write, LS
---

# Epic Edit

Edit epic details after creation.

Addition context (optional): $2


## Instructions

### 1. Read Current Epic

Read `.claude/epics/$1/epic.md`:
- Parse frontmatter
- Read content sections

### 2. Interactive Edit

Ask user what to edit:
- Name/Title
- Description/Overview
- Architecture decisions
- Technical approach
- Dependencies
- Success criteria

### 3. Update Epic File

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update epic.md:
- Preserve all frontmatter except `updated`
- Apply user's edits to content
- Update `updated` field with current datetime

### 4. Option to Update GitHub

If epic has GitHub URL in frontmatter:
Ask: "Update GitHub issue? (yes/no)"

If yes:
```bash
gh issue edit {issue_number} --body-file .claude/epics/$1/epic.md
```

### 5. Output

```
✅ Updated epic: $1
  Changes made to: {sections_edited}
  
{If GitHub updated}: GitHub issue updated ✅

View epic: /pm:epic-show $1
```

## Important Notes

Preserve frontmatter history (created, github URL, etc.).
Don't change task files when editing epic.
Follow `/rules/frontmatter-operations.md`.