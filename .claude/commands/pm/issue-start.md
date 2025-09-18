---
description: Begin work on a GitHub issue with parallel agents based on work stream analysis.
argument-hint: [Issue number] [Agent mode (optional)]
allowed-tools: Read, Write, Edit, LS, Task
---

# Issue Start

Begin work on a GitHub issue with parallel agents based on work stream analysis.

$2

## Quick Check

1. **Get issue details:**
   ```bash
   gh issue view 45 --json state,title,labels,body
   ```

2. **Find local task file:**
   - First check if `.claude/epics/*/$1.md` exists (new naming)
   - If not found, search for file containing `github:.*issues/$1` in frontmatter (old naming)
   - If not found: "❌ No local task for issue #$1. This issue may have been created outside the PM system."

3. **Check for analysis:**
   ```bash
   test -f .claude/epics/*/$1-analysis.md || echo "❌ No analysis found for issue #$1
   
   Run: /pm:issue-analyze $1 first
   ```
   If no analysis exists and no --analyze flag, stop execution.

## Instructions

### 1. Create Issue Branch

Create a new branch for this specific issue:
```bash
# Use issue title captured in Quick Check to construct branch name
# Convert title to branch-friendly format (lowercase, replace spaces/special chars with hyphens)
# Example: Issue #42 "Calendar Integration" becomes "42-calendar-integration"
issue_name="$1-$(echo "$issue_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')"

echo "🌿 Branch name: issue/$issue_name"

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
   issue_title=$(gh issue view $1 --json title -q .title)
   issue_body=$(gh issue view $1 --json body -q .body)

   # Create comprehensive PR description
   pr_body="## Issue #$1: $issue_title

   Resolves #$1

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
      --title "Issue #$1: $issue_title" \
      --body "$pr_body" \
      --base main \
      --head issue/$issue_name \
      --draft

   pr_url=$(gh pr view issue/$issue_name --json url -q .url)
   echo "✅ Draft PR created: $pr_url"
fi
```

### 3. Read Analysis

Read `.claude/epics/{epic_name}/$1-analysis.md`:
- Parse parallel streams
- Identify which can start immediately
- Note dependencies between streams

### 4. Setup Progress Tracking

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Create workspace structure:
```bash
mkdir -p .claude/epics/{epic_name}/updates/$1
```

Update task file frontmatter `updated` field with current datetime.

### 5. Launch Parallel Agents using TDD

**TDD Approach for Parallel Streams**: Each agent practices proper Test-Driven Development:
- **Backend agents**: Write failing unit tests → implement code → refactor (Red-Green-Refactor)
- **Frontend agents**: Stub E2E acceptance tests → write unit tests → implement UI → refactor
- **Integration agents**: Write integration tests → implement integrations → refactor
- **No separate testing stream needed** - each agent owns their domain's tests
- **CRITICAL**: Agents write tests but DO NOT run them to avoid simulator conflicts

**Why No Test Execution**: Parallel agents avoid running tests simultaneously because they compete for the same simulators, causing conflicts and unreliable results. As coordinator, you and the User will run the full test suite after all streams complete their implementation work.

This eliminates redundant testing streams since each specialist writes tests for their own implementation domain.

For this stage, first present to the user your plan for launching agents to ensure alignment. Example:

---
🚀 Launch plan for parallel agents for issue #$1

[your plan for each agent and rationale]

Please let me know if I may proceed or if you would like to discuss further before proceeding.

---

Proceed with launching agents only after user confirmation.

For each stream that can start immediately:

Create `.claude/epics/{epic_name}/updates/$1/stream-{X}.md`:
```markdown
---
issue: $1
stream: {stream_name}
agent: {agent_type}
started: {current_datetime}
status: in_progress
---

# Stream {X}: {stream_name}

## Scope
{stream_description}
- **REMINDER**: Follow TDD approach (write tests but DO NOT run them)

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
  description: "Issue #$1 Stream {X}"
  subagent_type: "{agent_type}"
  prompt: |
    You are working on Issue #$1 on branch issue/{issue_name}.

    Branch: issue/{issue_name}
    Your stream: {stream_name}

    Your scope:
    - Files to modify: {file_patterns}
    - Work to complete: {stream_description}

    Requirements:
    1. Read full task from: .claude/epics/{epic_name}/{task_file}
    2. Work ONLY in your assigned files in the current directory
    3. Commit frequently with format: "Issue #$1: {specific change}"
    4. Update progress in: {main_project_root}/.claude/epics/{epic_name}/updates/$1/stream-{X}.md
    5. Add new files to coverage-config.json
    6. Follow coordination rules in /rules/agent-coordination.md
    7. For user facing features/components, stub E2E acceptance tests that define "done"
    8. Write tests but DO NOT run them (to avoid conflicts with other streams)

    Typical workflow:
    1. Stub E2E acceptance tests (criteria only) for your feature scope (defines user-facing success)
       - Commit: "Issue #$1: add E2E acceptance criteria for {feature}"
    2. Write failing integration/unit tests (defines component contracts)  
       - Commit: "Issue #$1: add unit tests for {feature}"
    3. Implement minimal code to satisfy the unit/integration tests
       - Commit: "Issue #$1: implement {feature}"
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
      func testNameOfTestMethod() throws {
         // IMPORTANT: 1. Follow patterns established with prior tests in this file ☝️
         //            2. Don't make assumptions! Look at the actual implementation.
         //            3. For most operations reuse or create new, reusable TestUtilities methods.

         // GIVEN: A dose exists in history

         // WHEN: User swipes left on dose row

         // THEN: Edit action appears and functions correctly

         // THEN: Dose entry sheet opens with pre-populated data
      }
    
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
gh issue edit $1 --add-assignee @me --add-label "in-progress"
```

### 7. Output

```
✅ Started parallel work on issue #$1

Issue: {issue_name}
Branch: issue/{issue_name}

Launching {count} parallel agents:
  Stream A: {name} (Agent-1) ✓ Started
  Stream B: {name} (Agent-2) ✓ Started
  Stream C: {name} - Waiting (depends on A)

Progress tracking:
  .claude/epics/{epic_name}/updates/$1/

Monitor with: /pm:issue-status $1
Sync updates: /pm:issue-sync $1
```

## Error Handling

If any step fails, report clearly:
- "❌ {What failed}: {How to fix}"
- Continue with what's possible
- Never leave partial state

## Important Notes

Follow `/rules/datetime.md` for timestamps.
Keep it simple - trust that GitHub and file system work.