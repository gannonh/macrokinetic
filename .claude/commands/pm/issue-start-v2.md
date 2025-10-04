---
description: Begin or resume work on a GitHub issue.
argument-hint: [Issue number] [additional context (optional)]
allowed-tools: Bash, Read, Write, Edit, LS, Task
---

# Issue Start/Resume

Begin or resume work on a GitHub issue.

**ULTRATHINK** and use TodoWrite to keep track of your tasks.

Additional context (if any): $2

## Preflight

1. **Get issue details:**
   ```bash
   gh issue view $1 --json state,title,labels,body,assignees
   ```

2. **Identify issue type:**
   There are two fundamental types of issues of relevance to this command/process:

   1. **PR Issues** - New issues resulting from the PR Review process
      - These issues are identified by their titles, which are **prefixed by "PR #"**
      - These issues are typically small, focused tasks that can be completed quickly
      - They often relate to code changes, bug fixes, or minor enhancements
      - They do not have a corresponding local markdown file.
   2. **Task Issues** - Larger issues that are part of an epic.
      - These issues are **identified by the label "task"**
      - They often involve multiple steps, dependencies, and require more time to complete
      - They may include design considerations, architectural changes, or significant new functionality

**THE FOLLOWING INSTRUCTION SETS ARE MUTUALLY EXCLUSIVE BASED ON ISSUE TYPE.**

## Instructions for PR Issues

1. Read the issue description and recommended solution (if any) from GitHub.
2. Label the issue as `in-progress` in GitHub
3. Assess the implementation requirements and acceptance criteria.
4. Determine if any additional context or clarification is needed - if so, as the human for clarification.
5. Present to the user your recommended solution and implementation plan for approval: Iterate until approved.
6. Implement the solution.
7. Ensure all checks pass: `./scripts/check-all.sh`
8. Commit your work, referencing the issue number: `git commit -m "Fix for #$1: [description of work]"`
9. Push to GitHub: `git push`
10. Remove the `in-progress` label and close the issue on GitHub: `gh issue close $1 --comment "Fix implemented in PR #[pr-number]"`

## Instructions for Task Issues

### 1. Find Local Task File

   - First check if `.claude/epics/*/$1.md` exists (new naming)
   - If not found, search for file containing `github:.*issues/$1` in frontmatter (old naming)
   - If not found: "❌ No local task for issue #$1. This issue may have been created outside the PM system."

### 2. Check Work Status

   ```bash
   # Check if issue branch already exists
   if git branch -r | grep -q "origin/issue/.*$1"; then
     echo "🔄 Found existing issue branch - RESUMING work"
     WORK_MODE="resume"
   else
     echo "🆕 No existing branch found - STARTING new work"
     WORK_MODE="start"
   fi

   # Check for existing progress tracking
   if [ -d ".claude/epics/*/updates/$1" ]; then
     echo "📊 Found existing progress tracking"
     ls -la .claude/epics/*/updates/$1/
   fi
   ```
### 3. Check for Analysis
   ```bash
   test -f .claude/epics/*/$1-analysis.md || echo "❌ No analysis found for issue #$1

   Run: /pm:issue-analyze $1 first
   ```
   If no analysis exists and no --analyze flag, stop execution.

### 4. Create or Checkout Issue Branch

Handle branch creation for new work or checkout existing branch for resume:
```bash
# Use issue title captured in Quick Check to construct branch name
# Convert title to branch-friendly format (lowercase, replace spaces/special chars with hyphens)
# Example: Issue #42 "Calendar Integration" becomes "42-calendar-integration"
issue_name="$1-$(echo "$issue_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')"

echo "🌿 Branch name: issue/$issue_name"

if [ "$WORK_MODE" = "resume" ]; then
   # Resume: checkout existing branch
   echo "🔄 Resuming work - checking out existing branch"

   # Find the actual branch name (in case of slight naming differences)
   actual_branch=$(git branch -r | grep "origin/issue/.*$1" | head -1 | sed 's/origin\///' | xargs)

   if [ -n "$actual_branch" ]; then
      echo "🔄 Found branch: $actual_branch"
      git checkout main
      git pull origin main
      git checkout "$actual_branch"
      git pull origin "$actual_branch"
      echo "✅ Resumed branch: $actual_branch"
      issue_name=$(echo "$actual_branch" | sed 's/issue\///')
   else
      echo "❌ Could not find existing branch for issue #$1"
      exit 1
   fi
else
   # Start: create new branch
   echo "🆕 Starting new work - creating branch"

   # Ensure main is up to date
   git checkout main
   git pull origin main

   # Check if branch already exists locally (edge case)
   if git branch | grep -q "issue/$issue_name"; then
      echo "🔄 Local branch exists, switching to it"
      git checkout "issue/$issue_name"
   else
      # Create new issue branch
      git checkout -b "issue/$issue_name"
   fi

   git push -u origin "issue/$issue_name"
   echo "✅ Created branch: issue/$issue_name"
fi
```

### 5. Create or Update Draft Pull Request

Create a draft PR for new work or confirm existing PR for resumed work:

```bash
# Check if PR already exists for issue branch
if gh pr view "issue/$issue_name" >/dev/null 2>&1; then
   echo "✅ Pull Request already exists for issue/$issue_name"
   pr_url=$(gh pr view "issue/$issue_name" --json url -q .url)
   pr_state=$(gh pr view "issue/$issue_name" --json state -q .state)
   echo "   URL: $pr_url"
   echo "   State: $pr_state"

   if [ "$WORK_MODE" = "resume" ]; then
      echo "🔄 Resuming work with existing PR"
   fi
else
   # Get issue details from GitHub
   issue_title=$(gh issue view $1 --json title -q .title)
   issue_body=$(gh issue view $1 --json body -q .body)

   if [ "$WORK_MODE" = "start" ]; then
      # Create initial commit to enable PR creation (only for new work)
      echo "Issue #$1: Initialize branch for issue tracking" > init.md
      git add init.md
      git commit -m "Issue #$1: Initialize branch for issue tracking"
      git push
   fi

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
      --head "issue/$issue_name" \
      --draft

   pr_url=$(gh pr view "issue/$issue_name" --json url -q .url)
   echo "✅ Draft PR created: $pr_url"
fi
```

### 6. Read Analysis

Read `.claude/epics/{epic_name}/$1-analysis.md`:
- Parse parallel streams
- Identify which can start immediately
- Note dependencies between streams

### 7. Setup or Resume Progress Tracking

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Handle progress tracking for start or resume:
```bash
# Create workspace structure if it doesn't exist
mkdir -p .claude/epics/{epic_name}/updates/$1

if [ "$WORK_MODE" = "resume" ]; then
   echo "🔄 Resuming progress tracking"

   # Show existing stream files
   if [ -d ".claude/epics/{epic_name}/updates/$1" ]; then
      echo "📊 Existing streams:"
      ls -la .claude/epics/{epic_name}/updates/$1/

      # Check status of existing streams
      for stream_file in .claude/epics/{epic_name}/updates/$1/stream-*.md; do
         if [ -f "$stream_file" ]; then
            stream_name=$(basename "$stream_file")
            status=$(grep "^status:" "$stream_file" | cut -d' ' -f2 || echo "unknown")
            echo "   $stream_name: $status"
         fi
      done
   fi
else
   echo "🆕 Setting up new progress tracking"
fi
```

Update task file frontmatter `updated` field with current datetime.

### 8. Launch or Resume Parallel Agents using TDD

**TDD Approach for Parallel Streams**: Each agent practices proper Test-Driven Development:
- **Backend agents**: Write failing unit tests → implement code → refactor (Red-Green-Refactor)
- **Frontend agents**: Stub E2E acceptance tests → write unit tests → implement UI → refactor
- **Integration agents**: Write integration tests → implement integrations → refactor
- **No separate testing stream needed** - each agent owns their domain's tests
- **Simulator Isolation**: Each agent gets assigned a dedicated simulator (1, 2, or 3) for isolated testing

**Simulator Assignment**: Agents are assigned simulators sequentially to avoid conflicts:
- Stream A: Simulator 1 (iPhone 15) - UUID: 336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB
- Stream B: Simulator 2 (iPhone 15 Pro Max) - UUID: BFE552DA-1CB4-4736-821D-270EC6307512
- Stream C: Simulator 3 (iPhone SE 3rd gen) - UUID: FF190E2B-E6A1-461F-BEAF-E9A827038FA1

This eliminates redundant testing streams since each specialist writes tests for their own implementation domain and can run them immediately for TDD feedback.

**For Starting New Work:**
Present to the user your plan for launching agents to ensure alignment. Example:

---
🚀 Launch plan for parallel agents for issue #$1

[your plan for each agent and rationale]

Please let me know if I may proceed or if you would like to discuss further before proceeding.

---

**For Resuming Work:**
Analyze existing stream status and determine next actions:

---
🔄 Resume plan for issue #$1

Current stream status:
- Stream A: [status] - [next action needed]
- Stream B: [status] - [next action needed]
- Stream C: [status] - [next action needed]

Resume strategy: [explain which streams to resume/complete]

Please confirm the resume approach or request modifications.

---

Proceed with launching/resuming agents only after user confirmation.

**For Starting New Work - Create Stream Files:**

For new work or resumed work that requires a new Stream, create `.claude/epics/{epic_name}/updates/$1/stream-{stream_letter}.md`:
```markdown
---
issue: $1
stream: {stream_name}
agent: {agent_type}
started: {current_datetime}
status: in_progress
simulator: {simulator_number}
simulator_uuid: {simulator_uuid}
test_command: "./scripts/test.sh unit {simulator_number}"
---

# Stream {stream_letter}: {stream_name}

## Scope
{stream_description}
- **REMINDER**: Follow TDD approach with immediate test feedback

## Branch
issue/{issue_name}

## Testing
- **Assigned Simulator**: {simulator_number} ({simulator_uuid})
- **Simulator UUID**: {simulator_uuid}
- **Test Command**: `./scripts/test.sh unit {simulator_number}`
- **UI Test Command**: `./scripts/test.sh ui {simulator_number} {TestClassName}`

## Implementation Files
{file_patterns}

## Unit/Integration Test Files
{file_patterns}

## E2E Test Files
{file_patterns}

## Progress
- Starting implementation
```

**For Resuming Work - Update Stream Files:**

For existing streams, update the stream file with resume information:
```markdown
## Progress (Updated: {current_datetime})
- RESUMED: {current_datetime}
- Previous status: {previous_status}
- Next actions: {next_actions_based_on_analysis}
```

Launch parallel-stream-developer agent, providing the following inputs: 
- **issue_number**: The GitHub issue they're implementing: $1
- **issue_name**: Human-readable issue description
- **stream_name**: Their specific stream identifier (e.g., "A", "B", "C")
- **file_patterns**: Exact files they own and can modify
- **stream_description**: Their specific work scope
- **epic_name**: Parent epic for context
- **task_file**: Full task specification location
- **simulator_number**: Their assigned simulator (1, 2, or 3)
- **simulator_uuid**: Simulator device name

### 9. GitHub Assignment

```bash
if [ "$WORK_MODE" = "start" ]; then
   # Assign to self and mark in-progress for new work
   gh issue edit $1 --add-assignee @me --add-label "in-progress"
   echo "✅ Assigned issue #$1 to self and marked in-progress"
else
   # For resume, just confirm current assignment
   current_assignee=$(gh issue view $1 --json assignees -q '.assignees[0].login // "unassigned"')
   current_labels=$(gh issue view $1 --json labels -q '.labels[].name' | tr '\n' ',' | sed 's/,$//')
   echo "✅ Issue #$1 currently assigned to: $current_assignee"
   echo "   Current labels: $current_labels"
fi
```

### 10. Output

**For Starting New Work:**
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
Update progress with: /pm:issue-update $1
Sync updates: /pm:issue-sync $1
```

**For Resuming Work:**
```
🔄 Resumed parallel work on issue #$1

Issue: {issue_name}
Branch: issue/{issue_name} (existing)
PR: {pr_url} ({pr_state})

Resuming {count} agents:
  Stream A: {name} (Agent-1) ✓ Resumed
  Stream B: {name} (Agent-2) ✓ Completed (skipped)
  Stream C: {name} (Agent-3) ✓ Resumed

Progress tracking:
  .claude/epics/{epic_name}/updates/$1/

Monitor with: /pm:issue-status $1
Update progress with: /pm:issue-update $1
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