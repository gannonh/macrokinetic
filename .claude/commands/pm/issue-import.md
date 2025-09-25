---
description: Import existing GitHub issues into the PM system.
argument-hint: [issue-number] [epic-name] [github-label]  
allowed-tools: Read, Write, LS
---

# Import Issue

Import existing GitHub issues into the PM system.

## Options

- Issue Number: $1
- Epic Name: $2
- GitHub Label: $3

## Instructions

### 1. Fetch GitHub Issues

```bash
# If issue number provided, get specific github issue
if [[ -n "$1" ]]; then
  gh issue view "$1" --json number,title,body,state,labels,createdAt,updatedAt
fi
# if label provided, filter issues by label
if [[ -n "$3" ]]; then
  gh issue list --label "$3" --state open --json number,title,body,createdAt,updatedAt,labels
# if no label provided get all open issues
else
  gh issue list --state open --json number,title,body,createdAt,updatedAt,labels
fi
```

### 2. Identify Untracked Issues

For each GitHub issue:
- Find local file matching github issue number: `.claude/epics/$2/$1.md`
- If found, skip (already tracked)
- If not found, it's untracked and needs import

### 3. Categorize Issues

Based on GitHub issue labels:
- Issues with "epic" label → Create epic structure
- Issues with "task" label → Create task in appropriate epic
- Issues without "epic" or "task" label → Create task in appropriate epic
- Issues with "epic:{name}" label → Assign to that epic
- No PM labels → Ask user 

### 4. Create Local Structure

For each issue to import:

**If Epic:**
```bash
# Create epic.md with GitHub content and frontmatter
mkdir -p .claude/epics/$2$
touch .claude/epics/$2$/epic.md
```

**If Task:**
```bash
# Create task file with GitHub content
touch .claude/epics/$2/$1.md
```

Set frontmatter:
```yaml
name: {issue_title}
status: {open|closed based on GitHub}
created: {GitHub createdAt}
updated: {GitHub updatedAt}
github: https://github.com/{org}/{repo}/issues/$1
imported: true
```

### 5. Output

```
📥 Import Complete

Imported:
  Epics: {count}
  Tasks: {count}
  
Created structure:
  {epic_1}/
    - {count} tasks
  {epic_2}/
    - {count} tasks
    
Skipped (already tracked): {count}

Next steps:
  Run /pm:status to see imported work
  Run /pm:sync to ensure full synchronization
```

## Important Notes

Preserve all GitHub metadata in frontmatter.
Mark imported files with `imported: true` flag.
Don't overwrite existing local files.