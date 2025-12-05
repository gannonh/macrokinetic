---
description: Update GitHub issue with session progress, completed work, and remaining tasks.
argument-hint: [issue#] [additional context]
---

# Issue Update

Update GitHub issue #$1 with work completed during this session.

- **Issue Number**: $1 (required)
- **Additional Context**: $2 (optional)

## Phase 1: Gather Information

### 1.1 Fetch Current Issue

```bash
# Get current issue body and metadata
gh api repos/gannonh/tender-app-ios/issues/$1 > /tmp/issue-$1.json

# Extract body to temp file for editing
gh api repos/gannonh/tender-app-ios/issues/$1 --jq '.body' > /tmp/issue-$1-body.md

# Save original for diff comparison
cp /tmp/issue-$1-body.md /tmp/issue-$1-original.md
```

### 1.2 Read Update Log

The issue body contains an **Update Log** section that tracks all agent updates:

```markdown
## Update Log

- **2025-11-27 10:30** (`abc1234`): Completed data layer, started service layer
- **2025-11-26 14:15** (`def5678`): Initial implementation plan added
```

**Extract the last update:**
```bash
# Get the most recent log entry's commit hash (first match after "Update Log")
last_commit=$(grep -A1 "## Update Log" /tmp/issue-$1-body.md | grep -o '`[a-f0-9]\{7\}`' | head -1 | tr -d '`')

echo "Last commit tracked: ${last_commit:-none}"
```

### 1.3 Get Git History Since Last Update

```bash
# If we have a last commit from the log, use it for accurate history
if [ -n "$last_commit" ]; then
  echo "Getting commits since $last_commit..."
  git log --oneline $last_commit..HEAD
  git diff --name-only $last_commit..HEAD
else
  # Fallback: get commits from current branch not in main
  echo "No previous update found. Getting all branch commits..."
  git log --oneline main..HEAD
  git diff --name-only main..HEAD
fi
```

### 1.4 Analyze Session Work

Review and compile:
1. **Conversation history**: What tasks were discussed and completed this session
2. **Git commits**: What was committed (messages and file changes)
3. **Additional context**: Any user-provided context from arguments

## Phase 2: Update Issue Body

### 2.1 Read Current Issue Structure

The issue body typically contains these sections (from feat-template.md):
- Overview
- Requirements
- User Stories
- Key Design Decisions
- Implementation Plan (with `- [ ]` checkboxes)
- Acceptance Criteria (with `- [ ]` checkboxes)
- Technical Notes

### 2.2 Determine Completed Items

Based on session analysis, identify:
1. **Implementation Plan tasks** that are now complete (change `- [ ]` to `- [x]`)
2. **Acceptance Criteria** that are now verified (change `- [ ]` to `- [x]`)
3. **Any blockers or issues** encountered
4. **Remaining work** still to be done

### 2.3 Edit the Issue Body

Edit `/tmp/issue-$1-body.md` to:

1. **Check off completed Implementation Plan items**
   - Only mark items as complete that were actually implemented this session
   - Be conservative - if unsure, leave unchecked

2. **Check off completed Acceptance Criteria**
   - Only mark criteria that have been verified/tested
   - Include brief verification notes if helpful

3. **Add Session Summary** (append before Technical Notes if significant progress):
   ```markdown
   ## Session Log

   ### [DATE] - [Brief Description]

   **Commits:**
   - `abc1234` feat: Description of commit
   - `def5678` fix: Description of fix

   **Files Changed:**
   - `TenderApp/Models/NewModel.swift` (added)
   - `TenderApp/Services/ExistingService.swift` (modified)

   **Progress:**
   - Completed X, Y, Z
   - Remaining: A, B, C

   **Blockers/Notes:**
   - Any issues encountered or decisions made
   ```

4. **Add Update Log Entry**:

   Add a new entry to the Update Log section (create section if it doesn't exist):

   ```markdown
   ## Update Log

   - **YYYY-MM-DD HH:MM** (`commit`): Brief summary of what was done
   ```

   **Entry format:**
   - Date/time in local timezone
   - Short commit hash in backticks
   - Brief summary (one line) of session work

   **Example entries:**
   ```markdown
   - **2025-11-27 14:30** (`abc1234`): Completed Phase 1 data layer, all unit tests passing
   - **2025-11-27 10:15** (`def5678`): Added AdviceService with suggestion engine
   - **2025-11-26 16:45** (`ghi9012`): Initial implementation plan added
   ```

   **Placement:** Update Log section goes at the end of the issue body, before any HTML comments if present. Newest entries at top.

### 2.4 Review Changes

Before updating, present the diff to the user:
```bash
# Show what will be changed
diff /tmp/issue-$1-original.md /tmp/issue-$1-body.md || echo "Changes ready for review"
```

Ask user to confirm the update.

## Phase 3: Update GitHub Issue

### 3.1 Apply Update

```bash
# Update the issue with new body
gh api repos/gannonh/tender-app-ios/issues/$1 \
  -X PATCH \
  -F body=@/tmp/issue-$1-body.md

echo "✅ Issue #$1 updated successfully"
```

### 3.2 Cleanup

```bash
# Remove temp files
rm -f /tmp/issue-$1.json /tmp/issue-$1-body.md /tmp/issue-$1-original.md
```

## Phase 4: Summary

Present update summary:
```
📝 Issue #$1 Updated

Implementation Progress:
  - [X] Completed tasks: N items
  - [ ] Remaining tasks: M items

Acceptance Criteria:
  - [X] Verified: N criteria
  - [ ] Pending: M criteria

Session Commits: N commits (since last update)
Files Changed: M files

Update Log: Added entry for commit $current_commit

View issue: https://github.com/gannonh/tender-app-ios/issues/$1
```

## Guidelines

### What to Update
- Check off items that were ACTUALLY completed this session
- Add meaningful session logs for significant work
- Include commit hashes for traceability
- Note any blockers or decisions made

### What NOT to Update
- Don't check off items that are only partially complete
- Don't add session logs for trivial changes
- Don't modify the original structure of the issue
- Don't remove or alter existing checked items

### Checkbox Rules
- `- [ ]` → `- [x]` only when task is fully complete
- Leave partially complete items as `- [ ]` with a note
- Never uncheck already checked items without explicit user request

### Session Log Frequency
- Add session log section for significant implementation sessions
- Skip for minor fixes or documentation updates
- Group related commits together in the log

### Update Log System

The issue body contains a visible **Update Log** section at the bottom:

```markdown
## Update Log

- **2025-11-27 14:30** (`abc1234`): Completed Phase 1 data layer
- **2025-11-26 16:45** (`def5678`): Initial implementation plan
```

**How it works:**
- **Reading**: Parse the most recent entry to get the last commit hash for git history
- **Writing**: Prepend new entry with current timestamp, HEAD commit, and summary
- **First run**: If no Update Log exists, create the section and fall back to `main..HEAD`
- **Human readable**: Full history visible to anyone viewing the issue

**Entry format:**
- `**YYYY-MM-DD HH:MM** (`commit`): Summary`
- Newest entries at top
- One line per update session

**Benefits:**
- Humans can see full update history at a glance
- Agent can parse last commit for accurate git diff
- Self-contained in the issue - no external state needed
- Provides audit trail of all work sessions
