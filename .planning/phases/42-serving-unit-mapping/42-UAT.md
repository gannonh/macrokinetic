---
status: complete
phase: 42-serving-unit-mapping
source: [42-01-SUMMARY.md]
started: 2026-01-16T21:30:00Z
updated: 2026-01-16T21:38:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Suspicious Serving Labels Sanitized
expected: Search for "rice" and find foods with sanitized suspicious volume units. A food that would have had "cup" with unrealistic grams (like 5g) should instead show "serving" as the label.
result: issue
reported: "Rice product shows 'serving' instead of 'cup' but the 49g amount is reasonable for 0.25 cups. MacroFactor (also uses OFF) shows 'cup' for the same product. Expected cup to be available as a unit option."
severity: major

### 2. Valid Serving Labels Preserved
expected: Search for a common food like "chicken breast". Foods with reasonable gram-to-serving ratios should still show their original serving labels (like "oz", "breast", etc.) unchanged.
result: pass

### 3. Unit Conversion When Editing Entry
expected: Log a food entry. Edit it and switch from one serving unit to another (e.g., "serving" to "grams" or "grams" to "oz"). The quantity should automatically convert to match the new unit while keeping the same total grams.
result: pass

### 4. Edit Entry Preserves Nutrition
expected: After changing serving units while editing an entry, verify the displayed calories/macros remain the same (since you're consuming the same amount, just expressed in different units).
result: pass

## Summary

total: 4
passed: 3
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "Rice with reasonable cup-to-gram ratio should show 'cup' as serving option"
  status: failed
  reason: "User reported: Rice product shows 'serving' instead of 'cup' but the 49g amount is reasonable for 0.25 cups. MacroFactor (also uses OFF) shows 'cup' for the same product. Expected cup to be available as a unit option."
  severity: major
  test: 1
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
