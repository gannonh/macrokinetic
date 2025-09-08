---
description: Wrap up the session
argument-hint: spec path (e.g., specs/001-medication-profile-management)
---

We are wrapping up this session and preparing the project for the next session to pick up where we left off.

Activate **ULTRATHINK**

**CURRENT FEATURE**: $ARGUMENTS  

## Review and update feature-level documentation (as needed)

 **IMPORTANT** 
 
 - Include any context needed for the next session to continue seamlessly.
 - If you determine that the feature is complete, complete the tasks below and notify the user of the completion status.

1. `$ARGUMENTS/tasks.md` - Task list to execute
   - **PRIORITY WORK FOR NEXT SESSION**: Clear list of next tasks
   - **Current Status**: What's complete vs pending
   - **Key Technical Learnings**: Important patterns discovered
   - **Files Modified/Created**: Complete list for context
   - **Git Status**: Branch, PR status, working tree state
2. `$ARGUMENTS/plan.md` - Technical context and structure
3. `$ARGUMENTS/spec.md` - Feature requirements
4. `$ARGUMENTS/quickstart.md` - Test scenarios
   - **Completion Criteria**: Update status of each scenario
   - **Current Test Status**: Note passing/failing/skipped tests
   - Mark scenarios as ✅ complete, ⏳ in progress, or ❌ not started
5. `$ARGUMENTS/data-model.md` - Data model and relationships

## Critical Sections to Update in tasks.md

Before wrapping up, ensure these sections are current:

- [ ] **PRIORITY WORK FOR NEXT SESSION** - What should be tackled first next time?
- [ ] **Current Status** - Update completed/pending items
- [ ] **Key Technical Learnings** - Document any patterns, gotchas, or solutions
- [ ] **Test Coverage Status** - Note any XCTSkip tests and why
- [ ] **Session Notes** - What was done this session?

## Document Test Status

Update test information for next session:
- E2E tests written this session
- Tests currently skipped with XCTSkip
- Test coverage for new components
- Known failing tests that need attention

## Review and update project-level documentation (as needed)

1. `docs/spec-master-prd.md` - Master Product Requirements Specification
2. `docs/implementation-plan.md` - Implementation plan and progress
3. `CLAUDE.md` - Update based on learnings or changes made for this PR

## Final Git Checks
- Commit all changes with clear messages
- Name commit with the prefix `SESSION-HANDOFF: ` followed by a brief summary