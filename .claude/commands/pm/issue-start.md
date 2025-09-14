---
description: Begin work on a GitHub issue with parallel agents based on work stream analysis.
argument-hint: Issue number (e.g., 42)
allowed-tools: Bash, Read, Write, LS, Task
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
   Or: /pm:issue-start $ARGUMENTS --analyze to do both"
   ```
   If no analysis exists and no --analyze flag, stop execution.

## Instructions

### 1. Ensure Epic Branch Exists

Check if epic branch exists and switch to it:
```bash
# Find epic name from task file
epic_name={extracted_from_path}

# Check branch exists
if ! git show-ref --verify --quiet refs/heads/epic/$epic_name; then
  echo "❌ No branch for epic. Run: /pm:epic-start $epic_name"
  exit 1
fi

# Switch to epic branch
git checkout epic/$epic_name
git pull origin epic/$epic_name
```

### 2. Read Analysis

Read `.claude/epics/{epic_name}/$ARGUMENTS-analysis.md`:
- Parse parallel streams
- Identify which can start immediately
- Note dependencies between streams

### 3. Setup Progress Tracking

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Create workspace structure:
```bash
mkdir -p .claude/epics/{epic_name}/updates/$ARGUMENTS
```

Update task file frontmatter `updated` field with current datetime.

### 4. Launch Parallel Agents

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
epic/{epic_name}

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
    You are working on Issue #$ARGUMENTS in the current directory on branch epic/{epic_name}.

    Branch: epic/{epic_name}
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
    1. Write E2E acceptance tests (criteria only) for your feature scope (defines user-facing success)
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
    - For E2E tests, create non-functional test methods that use comments to descrtibe the intended behavior. 
      Example:

      // MARK: - ACCEPTANCE CRITERION: Swipe actions work correctly (edit, delete, skip, duplicate)
      func test_doseHistory_swipeActionsEditDose() throws {
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

### 5. GitHub Assignment

```bash
# Assign to self and mark in-progress
gh issue edit $ARGUMENTS --add-assignee @me --add-label "in-progress"
```

### 6. Output

```
✅ Started parallel work on issue #$ARGUMENTS

Epic: {epic_name}
Branch: epic/{epic_name}

Launching {count} parallel agents:
  Stream A: {name} (Agent-1) ✓ Started
  Stream B: {name} (Agent-2) ✓ Started
  Stream C: {name} - Waiting (depends on A)

Progress tracking:
  .claude/epics/{epic_name}/updates/$ARGUMENTS/

Monitor with: /pm:epic-status {epic_name}
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