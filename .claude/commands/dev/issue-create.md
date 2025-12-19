---
description: Create a new GitHub feature issue using the standard template.
argument-hint: [feature name or short description]
---

## Purpose

Create a well-structured GitHub feature issue using the project's standard template format. This ensures consistency and completeness for all feature requests.

Input: $ARGUMENTS

## Process

### Step 1: Gather Feature Information

Based on the input, ask the user clarifying questions to fill out the template sections:

1. **Overview**: What does this feature do? (1-2 sentences)
2. **Requirements**: What are the specific requirements? (bullet points)
3. **User Stories**: What user stories does this address? Format: "As a user, I want X, so that Y"
4. **Key Design Decisions**: Any architectural or design choices to document?

If the user has already provided detailed requirements, extract the information directly.

### Step 2: Draft the Issue

Using the template structure from `.claude/plans/feat-template.md`, draft the issue body with:

```markdown
# Feature: [Feature Name]

## Overview

[Description]

## Requirements

- [Requirement 1]
- [Requirement 2]

## User Stories

- **As a user**, I want [X], so that [Y].

## Key Design Decisions

1. **[Decision]** - [Rationale]

## Implementation Plan

_To be completed during planning phase_

## Acceptance Criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]
```

### Step 3: Create the Issue

Present the draft to the user for approval, then create the issue:

```bash
gh issue create \
  --title "feat: [Feature Name]" \
  --label "feature" \
  --label "backlog" \
  --body "$(cat <<'EOF'
[Issue body here]
EOF
)"
```

### Step 4: Confirm Creation

After creating, output:
- Issue number and URL
- Suggest next step: `/pm:issue-start [issue-number]` to begin implementation

## Notes

- Use `feature` and `backlog` labels by default
- Title format: `feat: [Short descriptive title]`
- Implementation Plan section left empty (filled during `/pm:issue-start`)
- Keep Acceptance Criteria high-level and testable
