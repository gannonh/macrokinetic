---
status: testing
phase: 42-serving-unit-mapping
source: [42-FIX-SUMMARY.md]
started: 2026-01-16T22:06:00Z
updated: 2026-01-16T22:06:00Z
---

## Current Test

number: 1
name: Fractional Cup Validation Fixed
expected: |
  Search for "rice" and find a product with fractional cup serving.
  Products like "0.25 cup (49g)" should now show "cup" as an available
  serving option (not sanitized to "serving"), since 49g is reasonable
  for a quarter cup.
awaiting: user response

## Tests

### 1. Fractional Cup Validation Fixed
expected: Search for "rice" and find products with fractional cups (0.25 cup, 1/4 cup). These should now show "cup" as an available serving option since the gram amount is validated against a scaled range (e.g., 49g for 0.25 cup validates against [20, 75] range).
result: issue
reported: "Issue remains for basmati rice (365 Everyday Value Indian Basmati Rice shows 'serving • 49g' with no cup option), but works for other products like chicken tenders."
severity: major

### 2. Full Cup Validation Unchanged
expected: Foods with full cup (1 cup) serving labels that have unrealistic gram amounts (less than 80g or more than 300g) should still be sanitized to "serving". The fix only affects fractional quantities.
result: [pending]

### 3. Fraction Format Support
expected: Foods with fraction-format quantities (1/4, 1/2, 1/3 cup) should also correctly show "cup" as serving option when grams are reasonable for that fraction.
result: [pending]

## Summary

total: 3
passed: 0
issues: 1
pending: 2
skipped: 0

## Gaps

- truth: "Fractional cups should show 'cup' as serving option"
  status: failed
  reason: "User reported: Basmati rice (0.25 cup) still shows 'serving' instead of 'cup'"
  severity: major
  test: 1
  root_cause: |
    Bug in ServingOption.parseOption() regex (FoodService.swift line 121).
    Regex (.+?) captures EVERYTHING before LAST parens, including middle parens.
    For "0.25 cup (49 g) (49g)" -> description = "cup (49 g)" instead of "cup".
    Then Int(0.25) = 0 -> label becomes "0 cup (49 g)".
    ServingPillPicker parses quantity as 0, creating range [0,0], so 49g is suspicious.
  artifacts:
    - path: "JabTracker/Services/FoodService.swift"
      issue: "servingOptionRegex on line 121 uses .+? which captures too much"
  missing:
    - "Change regex to [^(]+ to stop at first parenthesis"
    - "Preserve fractional quantity (0.25) instead of Int(0.25)=0"
