## Essential Context

### Codebase Conventions & Structure

1. Technical stack: @.planning/codebase/STACK.md
2. Architecture: @.planning/codebase/ARCHITECTURE.md
3. Project structure: @.planning/codebase/STRUCTURE.md
4. Coding conventions: @.planning/codebase/CONVENTIONS.md
5. Testing: @.planning/codebase/TESTING.md
6. Integrations: @.planning/codebase/INTEGRATIONS.md
7. Known concerns: @.planning/codebase/CONCERNS.md

## Important Reminders

- Do not run build commands when iterating with the user. The user needs to run build to see the changes. When you run build after making a change he has to wait for your build to complete before running the app.

## E2E Testing R ules

### ⛔️ MANDATORY: When E2E Tests Fail, Debug First

**STOP. Before changing ANY code when a test fails, you MUST run these debug steps:**

### Step 1: Capture Screenshot
```swift
// Add this line RIGHT BEFORE the failing assertion
TestUtilities.debugScreenshot(app, name: "before-failure")
```

### Step 2: Print Element Hierarchy
```swift
// Add this line RIGHT BEFORE the failing assertion
print(app.debugDescription)
```

### Step 3: Run Test and Examine Output
```bash
./scripts/test.sh ui 1 YourTestClass/testMethod
open logs/latest/screenshots/
```

### Step 4: Analyze BEFORE Changing Code
- **Screenshot shows**: What the UI actually looks like
- **debugDescription shows**: What elements exist and their identifiers
- **Together they answer**: Why can't the test find/interact with the element?

### ❌ DO NOT:
- Guess at element types or identifiers
- Change accessibility identifiers without seeing the hierarchy
- Add arbitrary timeouts hoping it fixes timing
- Modify SwiftUI views without confirming the element structure

### ✅ ALWAYS:
- Capture visual evidence of the failure state
- Print the element tree to see actual identifiers
- Compare expected vs actual element types
- Only then make targeted fixes based on evidence

**This debug-first approach is not optional. Skipping it leads to wasted effort and incorrect fixes.**
