---
status: diagnosed
phase: 41-glp1-analytics-fixes
source: [41-FIX-SUMMARY.md, 41-FIX2-SUMMARY.md]
started: 2026-01-16T17:00:00Z
updated: 2026-01-16T17:10:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Steady State Progress Display (Retest)
expected: ConcentrationCard shows steady state progress as a percentage between 0-100% (e.g., ~36% for 9 days on medication)
result: issue
reported: "Still shows 0% with --seed-test-90d"
severity: major

### 2. Concentration Histogram Bars (Retest)
expected: Concentration chart displays as distinct vertical bars (histogram format). Bars should be individually visible, not blended together. With 30-day view, expect ~120 bars at 6-hour intervals.
result: pass
note: "User feedback - Y axis should auto-scale to data range so bars take up more vertical space (enhancement)"

### 3. Therapeutic Range Band (Retest)
expected: Blue therapeutic range band is visible behind/through the concentration bars
result: pass

## Summary

total: 3
passed: 2
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "Steady state progress shows correct percentage (0-100%) based on time on medication"
  status: failed
  reason: "User reported: Still shows 0% with --seed-test-90d"
  severity: major
  test: 1
  root_cause: "TestDataSeeding.swift:170-178 creates MedicationProfile without startDate parameter, so it defaults to Date() (now). This makes timeOnMedicationHours ≈ 0, causing steadyStateProgress to return 0%."
  artifacts:
    - path: "JabTracker/Utils/TestDataSeeding.swift"
      issue: "Lines 170-178 - MedicationProfile init missing startDate"
    - path: "JabTracker/Models/MedicationProfile.swift"
      issue: "Line 15 - startDate defaults to Date()"
  missing:
    - "Set startDate to match first dose timestamp in generated dose history"
