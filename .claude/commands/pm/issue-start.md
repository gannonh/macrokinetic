---
description: Begin work on a GitHub issue with parallel agents based on work stream analysis.
argument-hint: [Issue number]
allowed-tools: Read, Write, Edit, LS, Task
---

# Issue Start

Begin or resume work on a GitHub issue with parallel agents based on work stream analysis.

**ULTRATHINK**

## Quick Check

1. **Get issue details:**
   ```bash
   gh issue view $ARGUMENTS --json state,title,labels,body
   ```

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
# Use issue title captured in Quick Check to construct branch name
# Convert title to branch-friendly format (lowercase, replace spaces/special chars with hyphens)
# Example: Issue #42 "Calendar Integration" becomes "42-calendar-integration"
issue_name="$ARGUMENTS-$(echo "$issue_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')"

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

### 5. Launch Parallel Agents using TDD

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

For this stage, first present to the user your plan for launching agents to ensure alignment. Example:

---
🚀 Launch plan for parallel agents for issue #$ARGUMENTS

[your plan for each agent and rationale]

Please let me know if I may proceed or if you would like to discuss further before proceeding.

---

Proceed with launching agents only after user confirmation.

For each stream that can start immediately:

Create `.claude/epics/{epic_name}/updates/$ARGUMENTS/stream-{X}.md`:
```markdown
---
issue: $ARGUMENTS
stream: {stream_name}
agent: {agent_type}
started: {current_datetime}
status: in_progress
simulator: {X}
simulator_uuid: {simulator_uuid}
test_command: "./scripts/test.sh unit {X}"
---

# Stream {X}: {stream_name}

## Scope
{stream_description}
- **REMINDER**: Follow TDD approach with immediate test feedback

## Branch
issue/{issue_name}

## Testing
- **Assigned Simulator**: {X} ({simulator_name})
- **Simulator UUID**: {simulator_uuid}
- **Test Command**: `./scripts/test.sh unit {X}`
- **UI Test Command**: `./scripts/test.sh ui {X} {TestClassName}`

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
Update progress with: /pm:issue-update $ARGUMENTS
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