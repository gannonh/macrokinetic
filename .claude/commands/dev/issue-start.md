---
description: Begin fresh work on a feature from GitHub issue, local file, or pasted requirements.
argument-hint: [GitHub issue number | file path | paste requirements]
model: claude-opus-4-5
---

# Issue Start

Input: $1

> **Note**: To resume work on an in-progress issue, use `/pm:issue-resume` instead.

---

## Phase 0: Pre-flight

1. Switch the user to Plan mode.

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

---

## Phase 2: Codebase Exploration

**Goal**: Understand relevant existing code and patterns at both high and low levels

**Actions**:
1. Launch 2-3 code-explorer agents in parallel. Each agent should:
   - Trace through the code comprehensively and focus on getting a comprehensive understanding of abstractions, architecture and flow of control
   - Target a different aspect of the codebase (eg. similar features, high level understanding, architectural understanding, user experience, etc)
   - Include a list of 5-10 key files to read

   **Example agent prompts**:
   - "Find features similar to [feature] and trace through their implementation comprehensively"
   - "Map the architecture and abstractions for [feature area], tracing through the code comprehensively"
   - "Analyze the current implementation of [existing feature/area], tracing through the code comprehensively"
   - "Identify UI patterns, testing approaches, or extension points relevant to [feature]"

2. Once the agents return, please read all files identified by agents to build deep understanding

---

## Phase 3: Architecture Design

**Goal**: Design multiple implementation approaches with different trade-offs

**Actions**:
1. Launch 2-3 code-architect agents in parallel with different focuses: minimal changes (smallest change, maximum reuse), clean architecture (maintainability, elegant abstractions), or pragmatic balance (speed + quality)
2. Review all approaches and form your opinion on which fits best for this specific task (consider: small fix vs large feature, urgency, complexity, team context)
3. Present to user: brief summary of each approach, trade-offs comparison, **your recommendation with reasoning**, concrete implementation differences
4. **Ask user which approach they prefer**

---

## Phase 4: Create Plan

1. **Write Implementation Plan**:
   - Break down into logical implementation steps
   - Identify files to create/modify
   - Define unit test coverage requirements
   - If frontend work: define E2E acceptance criteria (stubs only)

2. **Present Plan to User**:
   Present the plan and ask for approval before proceeding.

---

## Phase 5: Setup

### 1. TodoWrite Update

With the plan accepted, revise your TodoWrite list based on the implementation plan and steps in the process. It is very important that your TodoWrite list includes all of the steps in this process, plus the detailed steps of the implementation plan:

- [X] Phase 1: Gather Requirements
- [X] Phase 2: Codebase Exploration
- [X] Phase 4: Codebase Exploration
- [X] Phase 5: Create Plan
- [ ] Phase 6: Setup <--- CURRENT STEP
- [ ] Phase 7: Implementation (TDD)
- [ ] Phase 7.1: [implementation detail 1]
- [ ] Phase 7.2: [implementation detail 2]
- [ ] Phase 8: Quality Review
- [ ] Phase 9: Manual Smoke Test
- [ ] Phase 10: E2E Tests
- [ ] Phase 11: Final GitHub Issue Update

⚠️ **IMPORTANT**: Ask the user to approve the TodoWrite list before proceeding. ⚠️

### 2. GitHub Issue Management

   - If input was GitHub issue: Update issue with implementation plan as issue body
   - If input was file/pasted: Create new GitHub issue with plan
   - Add "in-progress" label
   - Add appropriate "type" label: feature, enhancement, bug, test, refactor
   - ⚠️ **IMPORTANT**: For features use the following as a guide: @.claude/plans/feat-template.md

### 3. Create Draft PR Branch

   - Check current branch
   - If not on feature branch: Create `feat/{issue-number}-{short-description}` (or bug/test/refactor as appropriate)
   - Create initial commit (edit and use `init.md` if nothing to commit yet)
   - Push branch to origin
   - Create draft PR linking to issue with plan summary in description

---

## Phase 6: Implementation (TDD)

Dispatch the `dev` agent to perform TDD implementation following these rules:

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

---

## Phase 7: Quality Review

**Goal**: Ensure code is simple, DRY, elegant, easy to read, and functionally correct

**Actions**:
1. Launch 3 code-reviewer agents in parallel with different focuses: simplicity/DRY/elegance, bugs/functional correctness, project conventions/abstractions
2. Consolidate findings and identify highest severity issues that you recommend fixing
3. **Present findings to user and ask what they want to do** (fix now, fix later, or proceed as-is)
4. Address issues based on user decision

---

## Phase 8: Manual Smoke Test

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

---

## Phase 9: E2E Tests

**⚠️ IMPORTANT**: Load Skill(ios-e2e-testing) before proceeding. ⚠️

1. **After user approval of functionality**:
   - Implement the E2E tests that were stubbed earlier
   - Ensure all E2E tests pass

2. **Final verification**:
   - Run full test suite
   - Confirm all quality gates pass

## Phase 10: Final GitHub Issue Update

1. **Update GitHub issue** with final status and link to PR
2. **Close the issue** if all is well

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
