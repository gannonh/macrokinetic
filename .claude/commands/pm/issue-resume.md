---
description: Resume work on an in-progress GitHub issue by analyzing current state and continuing work streams.
argument-hint: Issue number (e.g., 42)
allowed-tools: Read, Write, LS, Task
---

# Issue Resume

Resume work on an in-progress GitHub issue by analyzing current state and continuing appropriate work streams.


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

### 1. Ensure Issue Branch Exists

Check if issue branch exists and switch to it:
```bash
# Find issue name from local task file
issue_name={extracted_from_task_file_or_path}

# Check if issue branch exists
if ! git show-ref --verify --quiet refs/heads/issue/{issue_name}; then
  echo "❌ No branch issue/{issue_name} for issue #$ARGUMENTS. Run: /pm:issue-start $ARGUMENTS"
  exit 1
fi

# Switch to issue branch
git checkout issue/{issue_name}
git pull origin issue/{issue_name}
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
# Check git status on issue branch
# (already on correct branch from step 1)
git status --short
git log --oneline -5

# Check for uncommitted work
git diff --stat

# Check PR status
gh pr view issue/{issue_name} --json state,isDraft -q '.state + " (draft: " + (.isDraft|tostring) + ")"'
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
    You are resuming work on Issue #$ARGUMENTS in the current directory on branch issue/{issue_name}.

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
      8. **ASSIGNED SIMULATOR**: {X} ({simulator_name})
      9. **TEST COMMAND**: ./scripts/test.sh unit {X}
      10. **UI TEST COMMAND**: ./scripts/test.sh ui {X} {TestClassName}

      Outside-In TDD Flow

      Each outer layer defines the acceptance criteria and contracts for the inner layers. E2E tests are the ultimate acceptance criteria that define when a feature is truly "done" from the user's perspective.

      1. E2E Acceptance Criteria: Stub E2E acceptance test to define user-facing success (criteria only)

      // MARK: - ACCEPTANCE CRITERION: Swipe actions work correctly (edit, delete, skip, duplicate)
         func testNameOfTestMethod() throws {
            // GIVEN: A dose exists in history
            // WHEN: User swipes left on dose row
            // THEN: Edit action appears and functions correctly
            // THEN: Dose entry sheet opens with pre-populated data
         }

      2. Unit Tests (RED PHASE): Write failing unit tests that test isolated business logic and component contracts
      3. Implementation: Minimal code to satisfy the unit tests
      4. Unit Tests (GREEN PHASE): Run unit tests to verify correctness
      5. Integration Tests (RED PHASE): Write failing integration tests that verify component interactions
      6. Implementation: Implement minimal code to satisfy the integration tests
      7. Integration Tests (GREEN PHASE): Run integration tests to verify correctness
      8. E2E Tests (GREEN PHASE - ACCEPTANCE): Write full E2E tests that verify the entire user flow

      E2E Testing Element Targeting (CRITICAL)

      Element targeting is the primary challenge in E2E testing.

      Before writing the actual e2e tests, FIRST use `TestUtilities.debugElements()` to print and inspect the actual accessibility hierarchy. SwiftUI often renders elements differently than expected (e.g. List → CollectionView).

      Debug-First Approach

      1. Print the hierarchy FIRST
      
      // ALWAYS start with debugging the accessibility hierarchy
      TestUtilities.debugElements(in: app, containing: "dose-history")

         // Example output reveals actual element types:
         // 🔍 DEBUG: Tables: []
         // 🔍 DEBUG: ScrollViews: []
         // 🔍 DEBUG: CollectionViews: ["dose-history-view"]

      2. Read the raw logs to understand the actual element types and identifiers: logs/

      cat logs/latest_SIMULATOR_ID/raw_output.txt | grep "DEBUG"

      Common SwiftUI → Accessibility Mismatches
      - **SwiftUI List** → renders as **CollectionView** (not Table)
      - **NavigationStack** → renders as **CollectionView** (not ScrollView)
      - **Form toggles** → require coordinate-based tapping, not direct `.tap()`
      - **XCUIElementQuery** → has `.count` property, not `.isEmpty` (SwiftLint auto-fix breaks this)

      ### Essential Utilities
      - **`TestUtilities.debugElements()`** - Debug accessibility hierarchy
      - **`TestUtilities.clearAndEnterText()`** - Reliable text field interaction
      - Use **debug output** to identify correct element types before writing selectors

      ### Systematic Process
      1. Test fails to find element → Add `TestUtilities.debugElements()`
      2. Analyze debug output → Identify actual element type and identifier
      3. Update test selector → Use correct element type (collectionViews/tables/buttons)
      4. Remove debug code → Clean up after fixing selector
      5. Document learning → Update style guide for future reference

      ## ⚠️ CRITICAL TESTING ANTI-PATTERNS - AVOID AT ALL COSTS

      ### SwiftData Relationship Crashes (MOST COMMON BUG)
      **NEVER assign arrays to SwiftData relationships in tests:**

      // ❌ THIS WILL CRASH THE APP - NEVER DO THIS
      medicationProfile.doses = existingDoses
      user.medicationProfiles = [profile1, profile2]

      // ✅ CORRECT - Use individual property setters instead
      for dose in existingDoses {
         dose.medication = medicationProfile  // Sets individual relationship
      }
      // OR avoid relationships entirely in test-only code
      _ = existingDoses  // Keep for test setup but don't assign to relationship
      
      **Why this crashes:**
      - SwiftData uses computed properties with complex setter logic
      - Direct array assignment bypasses SwiftData's relationship management
      - Causes crashes in `@__swiftmacro_` generated code
      - Test environment makes this worse due to lack of proper ModelContext

      **Safe testing patterns:**
      1. **Pass arrays directly to engine methods** instead of using relationships
      2. **Use ModelContainer with proper context** when relationships are required
      3. **Comment why relationships are avoided** in test-only scenarios
      4. **Test relationship-dependent methods with empty profiles** to verify graceful handling

      ## Test Execution Notes
      - All test runs automatically log to `./logs/{test_type}_YYYY-MM-DD_HH-MM-SS/`
      - Latest test results always available via `logs/latest` symlink
      - Swift Testing framework handles unit tests with modern syntax
      - UI tests use XCUITest with accessibility-based element selection
      - **PREFER specific UI test classes** over running all UI tests (performance)
      - Coverage reports saved to test log directory and `/tmp/jab-tracker-coverage.xcresult`
      - Manual authentication tests require Xcode for interactive Apple ID flow
      - Log files include: `raw_output.txt`, `results.xcresult`, `coverage.json` (if --coverage used)
    
      Coordination Checkpoint:
      - Update your stream file with "ready_for_testing: true"
      - List which test files you created and their test results
      - Report any test failures or issues discovered during TDD
      - Continue TDD cycles until your stream's tests are green
      
      If you need to modify files outside your scope:
      - Check if another stream owns them
      - Wait if necessary
      - Update your progress file with coordination notes
        
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