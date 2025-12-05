---
description: Begin fresh work on a feature from GitHub issue, local file, or pasted requirements.
argument-hint: [GitHub issue number | file path | paste requirements]
model: claude-opus-4-5
---

# Issue Start

Input: $1

⚠️ **IMPORTANT**: Before anything switch the user to Plan mode.

> **Note**: To resume work on an in-progress issue, use `/pm:issue-resume` instead.

## Phase 1: Gather Requirements

1. **Determine Input Type**:
   - If numeric: Fetch GitHub issue via `gh issue view $1 --json title,body,labels`
   - If file path: Read the file contents
   - If neither: Treat as pasted requirements

2. **Clarify Requirements**:
   Ask the user clarifying questions to ensure full understanding of:
   - Core functionality and acceptance criteria
   - Edge cases and error handling expectations
   - UI/UX preferences (if frontend work)
   - Integration points with existing code

   Continue clarifying until confident you can create a robust plan.

## Phase 2: Create Plan

1. **Write Implementation Plan**:
   - Break down into logical implementation steps
   - Identify files to create/modify
   - Define unit test coverage requirements
   - If frontend work: define E2E acceptance criteria (stubs only)

2. **Present Plan to User**:
   Present the plan and ask for approval before proceeding.

## Phase 3: Setup

With the plan accepted, revise your todo list based on the implementation plan and steps in the process. 

⚠️ **IMPORTANT**: Ask the user to approve the todo list before proceeding. ⚠️

1. **GitHub Issue Management**:
   - If input was GitHub issue: Update issue with implementation plan as issue body
   - If input was file/pasted: Create new GitHub issue with plan
   - Add "in-progress" label
   - Add appropriate "type" label: feature, enhancement, bug, test, refactor
   - ⚠️ **IMPORTANT**: For features use the following as a guide: @.claude/plans/feat-template.md

2. **Create Draft PR Branch**:
   - Check current branch
   - If not on feature branch: Create `feat/{issue-number}-{short-description}` (or bug/test/refactor as appropriate)
   - Create initial commit (edit and use `init.md` if nothing to commit yet)
   - Push branch to origin
   - Create draft PR linking to issue with plan summary in description

## Phase 4: Implementation (TDD)

Dispatch the `ios-dev` agent to perform TDD implementation following these rules:

1. **For each implementation step**:
   - Write failing unit tests first (RED)
   - Implement minimal code to pass (GREEN)
   - Refactor if needed (REFACTOR)
   - Commit frequently with descriptive messages

2. **Frontend Work** (if applicable):
   - Create E2E test file with full method stubs:
     - Descriptive test method names (e.g., `testUserCanSubmitFormWithValidData`)
     - Acceptance criteria documented in comments within each method
     - Empty implementation body - DO NOT implement actual test logic yet
   - Focus on unit tests for ViewModels/Services

3. **Continue until**:
   - All planned implementation complete
   - All unit tests passing
   - OR user input needed

⚠️ **IMPORTANT** ⚠️:
   - Ensure TDD cycle is strictly followed
   - Verify all unit tests pass after each implementation step
   - YOU ARE RESPONSIBLE for quality and correctness of code
   - You are the single point of contact for the user
   - If subagents are struggling, intervene directly and take over to maintain quality
   - CONTINUE ITERATING until all functionality is implemented and all unit tests pass

## Phase 5: Manual Smoke Test

1. **Update GitHub issue** with implementation status (milestone update)

⚠️ **STOP HERE AND REQUEST USER TESTING** ⚠️ 

2. **Pause and request user testing**:
   "Implementation complete. Please manually test the feature and let me know:
   - What works well
   - What needs adjustment
   - Any bugs or issues"

3. **Iterate based on feedback**:
   - If bug found: Write failing test FIRST (strict TDD), then fix
   - Continue until user is satisfied

## Phase 6: E2E Tests

1. **After user approval of functionality**:
   - Implement the E2E tests that were stubbed earlier
   - Ensure all E2E tests pass

2. **Final verification**:
   - Run full test suite
   - Confirm all quality gates pass

3. **Final GitHub issue update** with completion status

## Workflow Summary

```
Phase 1 (requirements) → Phase 2 (plan) → Phase 3 (setup) →
Phase 4 (TDD) → Phase 5 (smoke test) → Phase 6 (E2E) → Done
```

## GitHub Issue Milestone Updates

Update the GitHub issue at these key points:
1. **After plan approval**: Add implementation plan to issue body
2. **After implementation complete**: Comment with status, ready for smoke test
3. **After E2E tests pass**: Comment with completion summary

## Commit Frequently

Throughout implementation:
- Commit after each logical unit of work
- Use conventional commit format (feat:, fix:, test:, refactor:)
- Push regularly to remote
