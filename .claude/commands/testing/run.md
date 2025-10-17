---
description: Run the test suite or specific tests.
argument-hint: [test-target] [additional-context]
allowed-tools: Read, LS, Task
---

# Run Tests

Execute tests per `.claude/context/testing.md`.

Test Target (if any): $1

Additional Context (if any): $2

## Quick Check

```bash
# Check if testing is configured
test -f .claude/context/testing.md || echo "❌ Testing not configured. Run /testing:prime first"
```

If test target provided, verify it exists and determine literal filepath/test pattern/method name: {test_target}

**IMPORTANT** 
- `$1` may or may not be a literal file path
- It is your job to determine and verify correct `{test_target}` based on the provided arguments: `$1`

## Instructions

### 1. Determine Test Command

Read testing configuration from `.claude/context/testing.md` in its entirety.

Based on `.claude/context/testing.md` and target:
- No arguments → Run full test suite from config
- File path → Run specific test file
- Pattern → Run tests matching pattern

### 2. Execute Tests

Run tests with verbose output.

Requirements:
- Run with verbose output for debugging
- No mocks - use real services
- Capture full output including stack traces
- If test fails, check test structure before assuming code issue

### 3. Monitor Execution

- Show test progress
- Capture stdout and stderr
- Note execution time

### 4. Report Results

**Success:**
```
✅ All tests passed ({count} tests in {time}s)
```

**Failure:**
```
❌ Test failures: {failed_count} of {total_count}

{test_name} - {file}:{line}
  Error: {error_message}
  Likely: {test issue | code issue}
  Fix: {suggestion}

Run with more detail: /testing:run {specific_test}
```

**Mixed:**
```
Tests complete: {passed} passed, {failed} failed, {skipped} skipped

Failed:
- {test_1}: {brief_reason}
- {test_2}: {brief_reason}
```

### 5. Cleanup

- Kill any hanging test processes


## Error Handling

- Test command fails → "❌ Test execution failed: {error}. Check test framework is installed."
- Timeout → Kill process and report: "❌ Tests timed out after {time}s"
- No tests found → "❌ No tests found matching: $1"

## IMPORTANT REMINDERS

- No mocking - real services only
- Check test structure if failures occur
- Keep output focused on failures
- By far the most common cause of UI test failures is incorrect accessibility identifiers or labels. Use the debug methods in `JabTrackerUITests/TestUtilities.swift` to inspect the view hierarchy and verify identifiers.