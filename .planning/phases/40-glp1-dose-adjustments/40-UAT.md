---
status: diagnosed
phase: 40-glp1-dose-adjustments
source: 40-01-SUMMARY.md
started: 2026-01-15T20:00:00Z
updated: 2026-01-15T21:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Stepper Controls Visible
expected: Open Quick Add Dose sheet. Dose Amount row shows stepper +/- controls instead of static text.
result: pass
notes: Fixed in 40-FIX - Stepper now visible using labelsHidden() pattern

### 2. Increase Dose Amount
expected: Tap the + button on the stepper. Dose amount increases by the step increment (0.25mg for compounded, varies for branded).
result: pass

### 3. Decrease Dose Amount
expected: Tap the - button on the stepper. Dose amount decreases by the step increment.
result: pass

### 4. Cannot Exceed Maximum
expected: Keep tapping + until you reach the maximum for your medication (e.g., 2.4mg for Semaglutide). Stepper should stop at max, not go higher.
result: pass

### 5. Cannot Go Below Minimum
expected: Keep tapping - until you reach the minimum (e.g., 0.25mg for Semaglutide). Stepper should stop at min, not go lower.
result: pass

### 6. Dose Resets on Medication Change
expected: Adjust dose to a non-default value. Change medication selection. Dose should reset to the new medication profile's default dose.
result: pass

### 7. Save Adjusted Dose
expected: Adjust dose to a different value, save the dose. Check History tab - the logged dose should show the adjusted amount you entered, not the profile default.
result: issue
reported: "Only issue is the rounding. This dose was .75 but shows as 0.8 mg"
severity: major
root_cause: DoseHistoryRow.swift:73 uses "%.1f" (1 decimal) instead of dose.formattedAmount which uses "%.2f" (2 decimals)

## Summary

total: 7
passed: 6
issues: 1
pending: 0
skipped: 0

## Issues for /gsd:plan-fix

- UAT-002: Dose display rounds incorrectly (0.75 shows as 0.8 mg) (major) - Test 7
  root_cause: DoseHistoryRow.swift:73 uses "%.1f" instead of dose.formattedAmount
