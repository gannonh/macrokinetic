---
description: Begin work on a GitHub issue with parallel agents based on work stream analysis.
argument-hint: Issue number (e.g., 42)
allowed-tools: Read, Write, Edit, LS, Task
---

# Issue Start

Begin work on a GitHub issue with parallel agents based on work stream analysis.

## Usage
```
/pm:issue-start <issue_number>
```

## Quick Check

1. **Get issue details:**
   ```bash
   gh issue view $ARGUMENTS --json state,title,labels,body
   ```
   If it fails: "❌ Cannot access issue #$ARGUMENTS. Check number or run: gh auth login"

2. **Find local task file:**
   - First check if `.claude/epics/*/$ARGUMENTS.md` exists (new naming)
   - If not found, search for file containing `github:.*issues/$ARGUMENTS` in frontmatter (old naming)
   - If not found: "❌ No local task for issue #$ARGUMENTS. This issue may have been created outside the PM system."

3. **Check for analysis:**
   ```bash
   test -f .claude/epics/*/$ARGUMENTS-analysis.md || echo "❌ No analysis found for issue #$ARGUMENTS
   
   Run: /pm:issue-analyze $ARGUMENTS first
   ```
   If no analysis exists and no --analyze flag, stop execution.

## Instructions

### 1. Create Issue Branch

Create a new branch for this specific issue:
```bash
# Extract issue name from task file or create descriptive name
issue_name={extracted_from_task_file_or_derived_from_title}

# Ensure main is up to date
git checkout main
git pull origin main

# Create new issue branch
git checkout -b issue/$issue_name
git push -u origin issue/$issue_name

echo "✅ Created branch: issue/$issue_name"
```

### 2. Create Draft Pull Request

Create a draft PR for the issue to track progress and enable collaboration:

```bash
# Check if PR already exists for issue branch
if gh pr view issue/$issue_name >/dev/null 2>&1; then
   echo "✅ Pull Request already exists for issue/$issue_name"
   pr_url=$(gh pr view issue/$issue_name --json url -q .url)
   echo "   URL: $pr_url"
else
   # Get issue details from GitHub
   issue_title=$(gh issue view $ARGUMENTS --json title -q .title)
   issue_body=$(gh issue view $ARGUMENTS --json body -q .body)

   # Create comprehensive PR description
   pr_body="## Issue #$ARGUMENTS: $issue_title

   Resolves #$ARGUMENTS

   ### Summary
   $issue_body

   ### Status
   🚧 **WORK IN PROGRESS** - This is a draft PR for tracking issue development

   ### Implementation
   - [ ] Task 1
   - [ ] Task 2
   - [ ] Tests added

   ### Development Notes
   - Issue developed using parallel agent workflow
   - Multiple commits will be added as work progresses
   - PR will be marked ready for review when issue is complete

   ### Testing Checklist
   - [ ] Unit tests pass
   - [ ] UI tests pass
   - [ ] Manual testing completed
   - [ ] Code review completed

   ---
   *This PR was auto-created by issue-start workflow*"

   # Create draft PR
   gh pr create \
      --title "Issue #$ARGUMENTS: $issue_title" \
      --body "$pr_body" \
      --base main \
      --head issue/$issue_name \
      --draft

   pr_url=$(gh pr view issue/$issue_name --json url -q .url)
   echo "✅ Draft PR created: $pr_url"
fi
```

### 3. Read Analysis

Read `.claude/epics/{epic_name}/$ARGUMENTS-analysis.md`:
- Parse parallel streams
- Identify which can start immediately
- Note dependencies between streams

### 4. Setup Progress Tracking

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Create workspace structure:
```bash
mkdir -p .claude/epics/{epic_name}/updates/$ARGUMENTS
```

Update task file frontmatter `updated` field with current datetime.

### 5. Launch Parallel Agents

For each stream that can start immediately:

Create `.claude/epics/{epic_name}/updates/$ARGUMENTS/stream-{X}.md`:
```markdown
---
issue: $ARGUMENTS
stream: {stream_name}
agent: {agent_type}
started: {current_datetime}
status: in_progress
---

# Stream {X}: {stream_name}

## Scope
{stream_description}

## Branch
issue/{issue_name}

## Files
{file_patterns}

## Progress
- Starting implementation
```

Launch agent using Task tool:
```yaml
Task:
  description: "Issue #$ARGUMENTS Stream {X}"
  subagent_type: "{agent_type}"
  prompt: |
    You are working on Issue #$ARGUMENTS on branch issue/{issue_name}.

    Branch: issue/{issue_name}
    Your stream: {stream_name}

    Your scope:
    - Files to modify: {file_patterns}
    - Work to complete: {stream_description}

    Requirements:
    1. Read full task from: .claude/epics/{epic_name}/{task_file}
    2. Work ONLY in your assigned files in the current directory
    3. Commit frequently with format: "Issue #$ARGUMENTS: {specific change}"
    4. Update progress in: {main_project_root}/.claude/epics/{epic_name}/updates/$ARGUMENTS/stream-{X}.md
    5. Add new files to coverage-config.json
    6. Follow coordination rules in /rules/agent-coordination.md

    IMPORTANT - Outside-In TDD flow:
    
    - Follow Outside-In TDD: Start with E2E acceptance tests that define "done"
    - Write tests but DO NOT run them (to avoid conflicts with other streams)

    Typical workflow:
    1. Stub E2E acceptance tests (criteria only) for your feature scope (defines user-facing success)
       - Commit: "Issue #$ARGUMENTS: add E2E acceptance criteria for {feature}"
    2. Write failing integration/unit tests (defines component contracts)  
       - Commit: "Issue #$ARGUMENTS: add unit tests for {feature}"
    3. Implement minimal code to satisfy the unit/integration tests
       - Commit: "Issue #$ARGUMENTS: implement {feature}"
    4. Mark in progress file: "ready_for_testing: true"
    
    Test Writing Guidelines:
    - E2E tests: Define user-facing acceptance criteria (XCUITest)
    - Integration tests: Define component interactions
    - Unit tests: Define individual component behavior
    - ALL streams write E2E tests for their features first
    - DO NOT run tests (coordinator will handle this)
    - For unit tests write actual tests but do not run them.
    - For E2E tests, stub non-functional test methods that use comments to descrtibe the intended behavior. 
      Example:

      // MARK: - ACCEPTANCE CRITERION: Swipe actions work correctly (edit, delete, skip, duplicate)
      func test_doseHistory_swipeActionsEditDose() throws {
         // IMPORTANT: 1. Follow patterns established with prior tests in this file ☝️
         //            2. Don't make assumptions! Look at the actual implementation.
         //            3. For most operations reuse or create new, reusable TestUtilities methods.

         // GIVEN: A dose exists in history

         // WHEN: User swipes left on dose row

         // THEN: Edit action appears and functions correctly

         // THEN: Dose entry sheet opens with pre-populated data
      }
    
    Outside-In TDD Flow:
    E2E Tests (written/non-functional - red) → Unit Tests (written/functional - red) → Implementation → [Coordination Point] → Tests Run (green) → Refactor (as needed)
    
    Coordination Checkpoint:
    - Update your stream file with "ready_for_testing: true"
    - List which test files you created
    - Wait for coordinator to run full test suite
    - Fix any issues found during coordination
    
    If you need to modify files outside your scope:
    - Check if another stream owns them
    - Wait if necessary
    - Update your progress file with coordination notes
    
    Complete your stream's work and mark as completed when done.
```

### 6. GitHub Assignment

```bash
# Assign to self and mark in-progress
gh issue edit $ARGUMENTS --add-assignee @me --add-label "in-progress"
```

### 7. Output

```
✅ Started parallel work on issue #$ARGUMENTS

Issue: {issue_name}
Branch: issue/{issue_name}

Launching {count} parallel agents:
  Stream A: {name} (Agent-1) ✓ Started
  Stream B: {name} (Agent-2) ✓ Started
  Stream C: {name} - Waiting (depends on A)

Progress tracking:
  .claude/epics/{epic_name}/updates/$ARGUMENTS/

Monitor with: /pm:issue-status $ARGUMENTS
Sync updates: /pm:issue-sync $ARGUMENTS
```

## Error Handling

If any step fails, report clearly:
- "❌ {What failed}: {How to fix}"
- Continue with what's possible
- Never leave partial state

## Important Notes

Follow `/rules/datetime.md` for timestamps.
Keep it simple - trust that GitHub and file system work.