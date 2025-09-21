---
description: Run the SwiftLint and SwiftFormat QA workflow with test verification.
argument-hint: Additional context (optional)
---

# SwiftLint QA Command

Run the complete SwiftLint and SwiftFormat quality assurance workflow with test verification.

## Steps

1. Run SwiftFormat to apply automatic formatting: `swiftformat .`
2. Run SwiftLint with automatic fixes: `swiftlint --fix`
3. Verify all unit tests still pass: `./scripts/test.sh unit 1`
4. Fix failing unit tests (if any) until all tests pass
5. Run SwiftLint to check for remaining violations: `swiftlint`
6. Fix ALL remaining violations manually
7. Verify all unit tests still pass after manual fixes: `./scripts/test.sh unit 1`

## Success Criteria

- SwiftFormat applies cleanly without errors
- SwiftLint --fix completes without issues
- All unit tests pass after automatic fixes
- SwiftLint shows zero violations
- All unit tests pass after manual violation fixes

## Notes

- Fix violations systematically, one file at a time
- Re-run `swiftlint` after each manual fix to verify progress
- If tests fail at any step, investigate and fix the root cause before proceeding
- Never skip or ignore violations - fix ALL of them

Additional Context (if any): $ARGUMENTS