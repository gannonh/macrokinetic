---
description: Analyze a GitHub issue to identify parallel work streams for efficient execution.
argument-hint: [Issue number] 
---

# Issue Analyze

Analyze an issue to identify parallel work streams for maximum efficiency.

## Quick Check

1. **Find local task file:**
   - First check if `.claude/epics/*/$ARGUMENTS.md` exists (new naming convention)
   - If not found, search for file containing `github:.*issues/$ARGUMENTS` in frontmatter (old naming)
   - If not found: "❌ No local task for issue #$ARGUMENTS. Run: /pm:import first"

2. **Check for existing analysis:**
   ```bash
   test -f .claude/epics/*/$ARGUMENTS-analysis.md && echo "⚠️ Analysis already exists. Overwrite? (yes/no)"
   ```

## Outside-In TDD Flow

We practice outside-in TDD:

1. E2E Acceptance Criteria: Stub E2E acceptance test to define user-facing success (criteria only)
2. Unit Tests (RED PHASE): Write failing unit tests that test isolated business logic and component contracts
3. Implementation: Minimal code to satisfy the unit tests
4. Unit Tests (GREEN PHASE): Run unit tests to verify correctness
5. Integration Tests (RED PHASE): Write failing integration tests that verify component interactions
6. Implementation: Implement minimal code to satisfy the integration tests
7. Integration Tests (GREEN PHASE): Run integration tests to verify correctness
8. E2E Tests (GREEN PHASE - ACCEPTANCE): Write full E2E tests that verify the entire user flow

**Important reminders**:
- **TDD: STREAMS CONDUCT THEIR OWN TESTING AS PART OF THEIR DEVELOPMENT PROCESS**, therefore, in most cases, it does not make sense to have separate streams focused only on testing.
- Not every development task or stream requires unit, integration and e2e tests. The type and amount of testing should be appropriate to the scope:
  - Isolated backend tasks may only need unit tests.
  - Backend tasks that integrate with other services may require both unit and integration tests.
  - Full features or user flows likely need all three levels of testing.
  - Be thoughtful and use your discretion to determine the right balance of testing for each stream.

## Instructions

### 1. Read Issue Context

Get issue details from GitHub:
```bash
gh issue view $ARGUMENTS --json title,body,labels
```

Read local task file to understand:
- Technical requirements
- Acceptance criteria
- Dependencies
- Effort estimate

### 2. Reassess Scope of Work

- Does the scope of work as defined in the issue and local task still make sense within the broader context of the project?
- Has the work already been completed in a prior workstream?
- Is the issue still relevant or does it need to be closed or redefined?
- This is a crucial strategic assessment that requires big picture thinking.
- It is perfectly ok to be unsure, and to suggest further discussion or additional research.
- In any case, **if further discussion or a change of course is needed, present your findings to the human PM for review before proceeding.**

### 3. Identify Parallel Work Streams

Analyze the issue to identify independent work that can run in parallel:

**Common Patterns:**
- **Database Layer**: Schema, migrations, models
- **Service Layer**: Business logic, data access
- **API Layer**: Endpoints, validation, middleware
- **UI Layer**: Components, pages, styles
- **Test Layer**: Unit tests, integration tests
- **Documentation**: API docs, README updates

**Key Questions:**
- What files will be created/modified?
- Which changes can happen independently?
- What are the dependencies between changes?
- Where might conflicts occur?

### 4. Create Analysis File

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Create `.claude/epics/{epic_name}/$ARGUMENTS-analysis.md`:

```markdown
---
issue: $ARGUMENTS
title: {issue_title}
analyzed: {current_datetime}
estimated_hours: {total_hours}
parallelization_factor: {1.0-5.0}
---

# Parallel Work Analysis: Issue #$ARGUMENTS

## Overview
{Brief description of what needs to be done}

## Parallel Streams

### Stream A: {Stream Name}
**Scope**: {What this stream handles}
**Implementation Files**:
- {file_pattern_1}
- {file_pattern_2}
**Unit/Integration Testing Files**:
- {test_file_pattern_1}
- {test_file_pattern_2}
**E2E Testing Files**:
- {e2e_test_file_pattern_1}
- {e2e_test_file_pattern_2}
**Agent Type**: {backend|frontend|fullstack|database}-specialist
**Can Start**: immediately
**Estimated Hours**: {hours}
**Dependencies**: none

### Stream B: {Stream Name}
**Scope**: {What this stream handles}
**Implementation Files**:
- {file_pattern_1}
- {file_pattern_2}
**Unit/Integration Testing Files**:
- {test_file_pattern_1}
- {test_file_pattern_2}
**E2E Testing Files**:
- {e2e_test_file_pattern_1}
- {e2e_test_file_pattern_2}
**Agent Type**: {agent_type}
**Can Start**: immediately
**Estimated Hours**: {hours}
**Dependencies**: none

### Stream C: {Stream Name}
**Scope**: {What this stream handles}
**Implementation Files**:
- {file_pattern_1}
- {file_pattern_2}
**Unit/Integration Testing Files**:
- {test_file_pattern_1}
- {test_file_pattern_2}
**E2E Testing Files**:
- {e2e_test_file_pattern_1}
- {e2e_test_file_pattern_2}
**Agent Type**: {agent_type}
**Can Start**: after Stream A completes
**Estimated Hours**: {hours}
**Dependencies**: Stream A

## Coordination Points

### Shared Files
{List any files multiple streams need to modify}:
- `src/types/index.ts` - Streams A & B (coordinate type updates)
- `package.json` - Stream B (add dependencies)

### Sequential Requirements
{List what must happen in order}:
1. Database schema before API endpoints
2. API types before UI components
3. Core logic before UI integration

## Conflict Risk Assessment
- **Low Risk**: Streams work on different directories
- **Medium Risk**: Some shared type files, manageable with coordination
- **High Risk**: Multiple streams modifying same core files

## Parallelization Strategy

**Recommended Approach**: {sequential|parallel|hybrid}

{If parallel}: Launch Streams A, B simultaneously. Start C when A completes.
{If sequential}: Complete Stream A, then B, then C.
{If hybrid}: Start A & B together, C depends on A, D depends on B & C.

## Expected Timeline

With parallel execution:
- Wall time: {max_stream_hours} hours
- Total work: {sum_all_hours} hours
- Efficiency gain: {percentage}%

Without parallel execution:
- Wall time: {sum_all_hours} hours

## Notes
{Any special considerations, warnings, or recommendations}
```

### 5. Validate Analysis

Ensure:
- All major work is covered by streams
- File patterns don't unnecessarily overlap
- Dependencies are logical
- Agent types match the work type
- Time estimates are reasonable

### 6. Output

```
✅ Analysis complete for issue #$ARGUMENTS

The scope of work has been reassessed and validated.

Identified {count} parallel work streams:
  Stream A: {name} ({hours}h)
  Stream B: {name} ({hours}h)
  Stream C: {name} ({hours}h)
  
Parallelization potential: {factor}x speedup
  Sequential time: {total}h
  Parallel time: {reduced}h

Files at risk of conflict:
  {list shared files if any}

Next: Start work with /pm:issue-start $ARGUMENTS
```

## Important Notes

- Analysis is local only - not synced to GitHub
- Focus on practical parallelization, not theoretical maximum
- Consider agent expertise when assigning streams
- Account for coordination overhead in estimates
- Prefer clear separation over maximum parallelization
- **REMEMBER:** TDD is outside-in, **streams should include testing as part of their scope**