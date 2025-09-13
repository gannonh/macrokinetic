---
description: Run the test suite or specific tests using the configured test-runner agent.
argument-hint: Optional test target (file path, pattern, or suite name)
allowed-tools: Bash, Read, Write, LS, Task
---

# Run Tests

Execute tests with the configured test-runner agent.

## Usage
```
/testing:run [test_target]
```

Where `test_target` can be:
- Empty (run all tests)
- Test file path
- Test pattern
- Test suite name

## Quick Check

```bash
# Check if testing is configured
test -f .claude/testing-config.md || echo "❌ Testing not configured. Run /testing:prime first"
```

If test target provided, verify it exists and determine literal filepath/test pattern/method name: {test_target}

**IMPORTANT** 
- `$ARGUMENTS` may or may not be a literal file path
- Unless otherwise mentioned in `$ARGUMENTS`, assume the test should be run **in the current branch**.
- It is your job to determine and verify correct `{test_target}` based on the provided arguments: `$ARGUMENTS`

## Instructions

### 1. Determine Test Command

Based on `.claude/testing-config.md` and target:
- No arguments → Run full test suite from config
- File path → Run specific test file
- Pattern → Run tests matching pattern

### 2. Execute Tests

Use the test-runner agent from `.claude/agents/test-runner.md`:

```markdown
Execute tests for: `{test_target}` (or "all" if empty)

Requirements:
- Run with verbose output for debugging
- No mocks - use real services
- Capture full output including stack traces
- If test fails, check test structure before assuming code issue
```

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
- No tests found → "❌ No tests found matching: $ARGUMENTS"

## Important Notes

- Always use test-runner agent for analysis
- No mocking - real services only
- Check test structure if failures occur
- Keep output focused on failures