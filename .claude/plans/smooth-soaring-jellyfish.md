# TDEE Calculation Bug in New Goal Flow

## Problem Statement

When creating a **New Goal** (which chains to ProgramWizard), the TDEE calculation uses wrong training level, resulting in ~500 kcal higher targets than expected.

**User's observation:**
- New Goal with sedentary training → targets = **1972** (wrong)
- Edit Goal with same settings → targets = **1357** (correct)
- Difference: ~600 kcal (matches 1.2x vs 1.55x multiplier difference)

## Root Cause

### Bug: TDEE Calculated Before Program Exists

**Location**: `ProgramWizard.swift` lines 1070-1088

```
New Goal → ProgramWizard flow:

1. User selects training level (sedentary) in wizard
2. Before confirmation step → showCalculatingThenConfirmation() called
3. calculateAndApplyTDEE() runs (line 1088)
4. ❌ goal.program is still nil - program hasn't been created yet!
5. TDEEService uses: goal.program?.training ?? .lifting → defaults to .lifting (1.55x)
6. User sees wrong TDEE (calculated with lifting multiplier)
7. User presses "Create Program" → program saved with sedentary
```

**In TDEEService.swift:236:**
```swift
let trainingLevel = trainingLevelOverride ?? goal.program?.training ?? .lifting
```

Since `goal.program` is nil when TDEE is calculated, it defaults to `.lifting` even though the user selected sedentary in the wizard.

### Why Edit Goal Works Correctly

In Edit Goal flow:
1. Goal already has a program attached
2. When `recalculateProgramTargets()` is called
3. `goal.program?.training` returns the correct value (sedentary)
4. Correct multiplier (1.2x) is used

## Fix

### Solution: Pass Training Level to TDEE Calculation

The `calculateAndApplyFullTDEE` method already has a `trainingLevelOverride` parameter that isn't being used.

**File**: `JabTracker/Views/Nutrition/ProgramWizard.swift`

**Change** `calculateAndApplyTDEE()` to pass the wizard's selected training level:

```swift
// Line 1141 - BEFORE (bug):
try await service.calculateAndApplyFullTDEE(for: user, goal: goal)

// AFTER (fix):
try await service.calculateAndApplyFullTDEE(
    for: user,
    goal: goal,
    trainingLevelOverride: viewModel.trainingLevel
)
```

This ensures the user's selected training level is used even before the program is created.

## Files to Modify

1. `JabTracker/Views/Nutrition/ProgramWizard.swift`
   - Line 1141: Add `trainingLevelOverride: viewModel.trainingLevel` parameter

## Verification Steps

1. **Manual Test**:
   - Create New Goal
   - In ProgramWizard, select sedentary training level
   - Verify the confirmation screen shows correct (lower) targets
   - Verify targets match what Edit Goal shows with same settings

2. **Unit Test** (optional):
   - Test that `calculateAndApplyFullTDEE` with `trainingLevelOverride` uses the override value instead of `goal.program?.training`

## Summary

The bug is a simple timing issue: TDEE is calculated before the program entity is created, so the wizard's selected training level isn't accessible via `goal.program?.training`. The fix is to explicitly pass the training level from the wizard using the existing `trainingLevelOverride` parameter.
