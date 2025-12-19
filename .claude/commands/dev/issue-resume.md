---
description: Resume work on an in-progress GitHub issue with existing branch/PR.
argument-hint: [GitHub issue number] [additional context]
model: claude-opus-4-5
---

# Issue Resume

Issue Number: $1

Resume work on an in-progress GitHub issue.

Additional context: $2

## Phase 1: Detect Issue State

### 1.1 Check Issue Status

```bash
# Get issue labels and check for Update Log
gh api repos/gannonh/jab-tracker-ios/issues/$1 --jq '{
  title: .title,
  state: .state,
  labels: [.labels[].name],
  hasUpdateLog: (.body | contains("## Update Log"))
}'
```

### 1.2 Check for Existing Branch/PR

```bash
# Find branch matching issue number
git fetch origin
existing_branch=$(git branch -r | grep -E "origin/(feat|fix|test|refactor)/$1" | head -1 | xargs)

# Check for open PR linked to issue
gh pr list --search "$1" --json number,headRefName,state,url
```

### 1.3 Verify Resume Conditions

This command is for resuming in-progress work. Verify that:
- Issue has `in-progress` label
- Branch exists for the issue

If these conditions are not met, inform the user:
```
Issue #$1 does not appear to be in progress.

Use `/pm:issue-start $1` to begin fresh work on this issue.
```

Otherwise, proceed with the resume workflow:
```
Resume Issue #$1

Branch: feat/$1-description
PR: #XX (draft)
Last Update: YYYY-MM-DD (commit abc1234)

Resuming from where you left off...
```

---

## Phase 2: Checkout and Sync

### 2.1 Checkout Existing Branch

```bash
git checkout $existing_branch
git pull origin $existing_branch
```

### 2.2 Read Update Log

Extract last update info from issue body:
```bash
gh api repos/gannonh/jab-tracker-ios/issues/$1 --jq '.body' > /tmp/issue-$1-body.md

# Get last commit from Update Log
last_commit=$(grep -A1 "## Update Log" /tmp/issue-$1-body.md | grep -o '`[a-f0-9]\{7\}`' | head -1 | tr -d '`')
```

### 2.3 Show Progress Since Last Session

```bash
echo "=== Commits since last update ==="
git log --oneline ${last_commit}..HEAD

echo "=== Files changed ==="
git diff --name-only ${last_commit}..HEAD
```

## Phase 3: Analyze Remaining Work

Parse the issue body to identify:
1. **Completed items**: `- [x]` in Implementation Plan
2. **Remaining items**: `- [ ]` in Implementation Plan
3. **Acceptance Criteria status**: Which are verified vs pending

Present summary to user:
```
Issue #$1 Progress Summary

Implementation Plan:
  Completed: N items
  Remaining: M items

Acceptance Criteria:
  Verified: X criteria
  Pending: Y criteria

Next steps based on remaining work...
```

## Phase 4: Ask User Where to Resume

```
Where would you like to resume?

1. Continue Implementation - default
2. Manual Smoke Test
3. E2E Tests
4. Review full plan first
```

Build your todo list based on the remaining work and steps in the process.

Then continue with the appropriate phase from the original issue-start workflow:
- **Implementation**: TDD cycle (write failing tests, implement, refactor)
- **Manual Smoke Test**: Request user testing, iterate on feedback
- **E2E Tests**: Implement stubbed E2E tests, run full suite
