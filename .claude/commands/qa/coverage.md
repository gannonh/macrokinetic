---
description: Fill test coverage gaps until thresholds met.
argument-hint: Additional context (optional)
tools: Glob, Grep, LS, Read, WebFetch, TodoWrite, WebSearch, Search, Task, Agent, Bash
---

# Test Coverage

Fill test coverage gaps until thresholds met.

## Steps

1. Have test-coverage-engineer assess test coverage and report back.
2. Communicate findings to user and confirm that the user would like to proceed with filling gaps.
3. Re-deploy test-coverage-engineer to fill gaps.
4. Validate success criteria below.
5. If not successful, iterate from step 3.

## Success Criteria

- All swift files are accounted for in `coverage-config.json`.
- All coverage gaps are filled.
- Coverage thresholds are met for all files.
- New tests are reliable, meaningful, and valid.
- No SwiftData relationship anti-patterns are introduced.
- All final checks pass:
  - `./scripts/check-coverage-config.sh` runs with no errors or warnings
  - `./scripts/check-coverage.sh` shows all files meeting their tier thresholds
  - `./scripts/test.sh unit 1` passes with no errors
  - `swiftlint` shows zero violations

## Notes

- Follow existing test patterns and structures.
- Ensure tests validate actual behavior, not just coverage.

Additional Context (if any): $ARGUMENTS