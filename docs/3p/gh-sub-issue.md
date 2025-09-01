# gh-sub-issue Quick Reference

A GitHub CLI extension to manage hierarchical sub-issues within GitHub repositories.

## Core Commands

### Add existing issue as sub-issue
```bash
gh sub-issue add <parent> <child>
# Example: gh sub-issue add 123 456
```

### Create new sub-issue
```bash
gh sub-issue create --parent <issue> --title "<title>" [options]
# Options: --body, --label, --assignee, --milestone, --project
# Example: gh sub-issue create --parent 123 --title "Implement auth" --label "backend"
```

### List sub-issues
```bash
gh sub-issue list <parent> [--state all|open|closed] [--json fields]
# Example: gh sub-issue list 123 --state all
```

### Remove sub-issue link
```bash
gh sub-issue remove <parent> <child> [--force]
# Example: gh sub-issue remove 123 456
```

## Key Features
- Links issues in parent-child relationships
- Cross-repository support with `--repo owner/repo`
- Accepts issue numbers or URLs as arguments
- JSON output available with `--json` flag
- Preserves all standard GitHub issue features (labels, assignees, milestones)

## Common Workflow
```bash
# Create parent issue
gh issue create --title "Feature: Auth System"
# Returns: #100

# Add sub-tasks
gh sub-issue create --parent 100 --title "Database schema"
gh sub-issue create --parent 100 --title "JWT implementation"
gh sub-issue add 100 95  # Link existing issue

# Check progress
gh sub-issue list 100 --state all
```