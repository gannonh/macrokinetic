---
description: Resume work on an in-progress GitHub issue by analyzing current state and continuing work streams.
argument-hint: Issue number (e.g., 42)
allowed-tools: Read, Write, LS, Task
---

# Issue Resume

Resume work on an in-progress GitHub issue by analyzing current state and continuing appropriate work streams.

## Usage
```
/pm:issue-resume <issue_number>
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

3. **Verify issue is in progress:**
   - Check GitHub labels for "in-progress"
   - Check local task file status
   - If status is "todo": "❌ Issue #$ARGUMENTS not started yet. Run: /pm:issue-start $ARGUMENTS"
   - If status is "closed": "❌ Issue #$ARGUMENTS already closed. Nothing to resume."

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

### 2. Analyze Current Progress

**Read context files for full understanding:**

#### Epic Context
- Read `.claude/epics/{epic_name}/epic.md` - Overall epic goals and status
- Read `.claude/epics/{epic_name}/execution-status.md` - Epic-wide progress and coordination

#### Issue Context  
- Read `.claude/epics/{epic_name}/$ARGUMENTS.md` - Full issue requirements and acceptance criteria
- Check issue status, dependencies, and any recent updates
- Review any learnings captured from previous sessions

#### Stream Progress
Read existing progress files at `.claude/epics/{epic_name}/updates/$ARGUMENTS/`:

**For each existing stream file:**
- Check current status (in_progress, completed, blocked)
- Identify last completed work
- Note any blockers or dependencies
- Determine what needs to continue

**Analyze work state:**
```bash
# Check git status on epic branch
# (already on correct branch from step 1)
git status --short
git log --oneline -5

# Check for uncommitted work
git diff --stat
```

### 3. Determine Resume Strategy

Based on stream analysis:

**Active Streams (status: in_progress):**
- Resume with existing agent
- Provide context of last work completed
- Continue from last known state

**Ready Streams (ready_for_testing: true):**
- Check if testing was completed
- Resume testing/integration if needed
- Move to next phase if tests passed

**Blocked Streams:**
- Analyze blockers
- Determine if blockers are resolved
- Resume if unblocked, or coordinate resolution

**Completed Streams:**
- Verify completion
- Check if follow-up work needed
- Skip if truly complete

### 4. Update Progress Tracking

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update task file frontmatter:
```yaml
updated: {current_datetime}
status: in_progress  # ensure status is correct
resumed: {current_datetime}  # track when work resumed
```

### 5. Resume Appropriate Streams

For each stream that needs to continue:

**Update stream progress file:**
```markdown
### {Current Date} - Work Resumed
- **Previous State**: {summary of last completed work}
- **Resuming From**: {specific point of continuation}
- **Next Steps**: {immediate next actions}
- **Context**: {any relevant changes since last session}
```

**Launch continuation agent using Task tool:**
```yaml
Task:
  description: "Resume Issue #$ARGUMENTS Stream {X}"
  subagent_type: "{agent_type}"
  prompt: |
    You are resuming work on Issue #$ARGUMENTS in the current directory on branch epic/{epic_name}.

    Branch: epic/{epic_name}
    Your stream: {stream_name}
    
    RESUMING CONTEXT:
    - Previous work completed: {summary_of_last_work}
    - Current state: {current_stream_status}
    - Files in progress: {list_of_modified_files}
    - Last session notes: {last_progress_notes}
    
    Your continuation scope:
    - Files to continue working on: {file_patterns}
    - Work to complete: {remaining_work_description}
    - Blockers to resolve: {any_known_blockers}
    
    Requirements:
    1. Read full task from: .claude/epics/{epic_name}/{task_file}
    2. Review your stream progress: .claude/epics/{epic_name}/updates/$ARGUMENTS/stream-{X}.md
    3. Check git status on branch: git status, git diff
    4. Continue from where you left off - don't restart completed work
    5. Commit frequently with format: "Issue #$ARGUMENTS: {specific change}"
    6. Update progress in: .claude/epics/{epic_name}/updates/$ARGUMENTS/stream-{X}.md
    7. Add new files to coverage-config.json
    8. Follow coordination rules in rules/agent-coordination.md

    CONTINUATION STRATEGY:
    - If tests were written but not run: Resume with test execution
    - If implementation was partial: Continue implementation from last commit
    - If blocked: Attempt to resolve blockers or coordinate with other streams
    - If ready for testing: Begin integration testing phase
    
    TDD Continuation Guidelines:
    - Check what tests exist and their status
    - Resume from appropriate TDD phase (Red/Green/Refactor)
    - Don't re-write existing working tests
    - Continue with next failing test or implementation
    
    Coordination Notes:
    - Check if other streams have made progress that affects your work
    - Update your stream file with any coordination needs
    - Mark dependencies resolved if other streams completed required work
    
    Resume your stream's work and update status appropriately.
```

### 6. Skip Completed Work

**For streams marked as completed:**
- Verify completion is accurate
- Skip launching agents
- Note in resume summary

**For streams not applicable:**
- Check if dependencies changed
- Skip if still not ready
- Note dependency status

### 7. GitHub Status Update

```bash
# Add resume comment
echo "🔄 Resuming work on issue

**Resumed Streams:**
{list active streams being resumed}

**Completed Streams:**
{list completed streams}

**Current Focus:**
{primary work area}

---
Resumed at: {timestamp}" | gh issue comment $ARGUMENTS --body-file -
```

### 8. Output

```
🔄 Resumed work on issue #$ARGUMENTS

Epic: {epic_name}
Branch: epic/{epic_name}

Stream Status:
  Stream A: {name} - ✅ Completed (skipped)
  Stream B: {name} - 🔄 Resumed (Agent-1)
  Stream C: {name} - ⏸️ Blocked (waiting for dependency)

Progress tracking:
  .claude/epics/{epic_name}/updates/$ARGUMENTS/

Previous work: {summary_of_completed_work}
Resuming: {what_is_being_continued}

Monitor with: /pm:epic-status {epic_name}
Update progress: /pm:issue-update $ARGUMENTS
```

## Error Handling

If any step fails, report clearly:
- "❌ Cannot resume - issue not in progress"
- "❌ No previous work found - use /pm:issue-start instead"
- "❌ Epic branch missing - run /pm:epic-start first"
- Continue with what's possible
- Never leave inconsistent state

## Resume vs Start Decision Tree

**Use /pm:issue-resume when:**
- Issue has "in-progress" label
- Stream progress files exist
- Previous work was started but paused
- Resuming after break or coordination

**Use /pm:issue-start when:**
- Issue has "todo" status
- No stream progress files exist
- Starting fresh work
- First time working on issue

**Use /pm:issue-update when:**
- Currently working and want to capture progress
- No need to launch new agents
- Just updating tracking files

## Important Notes

- Always check git status on branch before resuming
- Don't restart completed work - continue from last state
- Respect coordination between streams
- Provide context to resumed agents about previous work
- Follow `/rules/datetime.md` for timestamps
- Trust existing progress files as source of truth