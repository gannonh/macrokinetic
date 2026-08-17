## Agent Instructions

**JabTracker** - iOS app for tracking GLP-1 medication doses, nutrition, and health metrics.

- SwiftUI + SwiftData targeting iOS 17.5+, with CloudKit sync
- Pharmacokinetics engine for concentration tracking
- Offline-first food logging with a local SQLite FTS5 database containing 1.7M+ foods
- Analytics, adherence tracking, and progress photos

## Current State

- Version 0.10.1, build 16; development/TestFlight.
- Latest completed work: Food Log clear-day deletion, destructive delete styling, and Monday-first weeks.
- Manual custom-food creation from the Food Library is the likely next focused feature.
- Open product decisions: medication-nutrition correlation insights, subscription tiers, and paywall placement.

## Architectural Invariants

- User data must remain CloudKit-compatible and sync across devices.
- Core flows must continue to work offline.
- Use `@Observable` for new stateful types and follow the established service-layer/MVVM structure.
- Nutrition must work as a standalone experience; GLP-1 tracking remains optional.
- `project.yml` is the source of truth for the generated Xcode project.

## Source of Truth

- `AGENTS.md` contains repository working conventions and durable product context.
- GitHub Issues and `.agents/skills/plan-build-verify/` contain specs, the backlog, and the Plan/Build/Verify workflow.
- Focused files under `docs/features/` contain complex domain behavior.
- Git history, tags, and release notes contain historical work.

### Important Documentation

Read these documents when working in the corresponding domain:

@docs/features/algorithms/TDEE-CALORIE-ALGORITHMS.md
@docs/features/onboarding-strategy-checkin-flows/FLOWS.md


## Important Reminders

- Do not run build commands when iterating with the user. The user needs to run build to see the changes. When you run build after making a change he has to wait for your build to complete before running the app.

## E2E Testing Rules

### MANDATORY: When E2E Tests Fail, Debug First

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
./scripts/test.sh ui YourTestClass/testMethod
open logs/latest/screenshots/
```

### Step 4: Analyze BEFORE Changing Code
- **Screenshot shows**: What the UI actually looks like
- **debugDescription shows**: What elements exist and their identifiers
- **Together they answer**: Why can't the test find/interact with the element?

### DO NOT:
- Guess at element types or identifiers
- Change accessibility identifiers without seeing the hierarchy
- Add arbitrary timeouts hoping it fixes timing
- Modify SwiftUI views without confirming the element structure

### ALWAYS:
- Capture visual evidence of the failure state
- Print the element tree to see actual identifiers
- Compare expected vs actual element types
- Only then make targeted fixes based on evidence

**This debug-first approach is not optional. Skipping it leads to wasted effort and incorrect fixes.**
