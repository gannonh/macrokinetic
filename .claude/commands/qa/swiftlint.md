---
description: Run the SwiftLint and SwiftFormat QA workflow with test verification.
argument-hint: Additional context (optional)
---

# SwiftLint QA Command

This command runs the complete SwiftLint and SwiftFormat quality assurance workflow with test verification.

## Steps

1. Run SwiftFormat to apply automatic formatting
2. Run SwiftLint with automatic fixes
3. Verify all unit tests still pass
4. Run SwiftLint to check for remaining violations
5. Fix ALL remaining violations manually
6. Verify all unit tests still pass after manual fixes

## Execution

Run the following commands in sequence:

```bash
# 1. Apply automatic formatting
swiftformat .

# 2. Apply automatic SwiftLint fixes
swiftlint --fix

# 3. Verify tests pass after automatic fixes
./scripts/test.sh unit 1

# 4. Check for remaining violations
swiftlint

# 5. Fix any remaining violations manually (edit files as needed)
# (Aalyze violations and fix them one by one)

# 6. Verify tests pass after manual fixes
./scripts/test.sh unit 1
```

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