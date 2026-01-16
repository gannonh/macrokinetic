---
status: diagnosed
phase: 41-glp1-analytics-fixes
source: [41-FIX-SUMMARY.md]
started: 2026-01-16T14:50:00Z
updated: 2026-01-16T16:15:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Steady State Progress Display
expected: ConcentrationCard shows steady state progress as a percentage between 0-100% (approximately 36% for 9 days on medication / 25 days to steady state)
result: issue
reported: "Still shows 0% with 90 days of seeded medication history (--seed-test-90d flag)"
severity: blocker

### 2. Concentration Chart Histogram Format
expected: Concentration chart displays as vertical bars (histogram) with multiple bars across the time axis. Bars should have slight transparency (0.8 opacity) so the therapeutic range band shows through.
result: issue
reported: "Chart displays as area/line chart with fill, not vertical histogram bars"
severity: major

### 3. Therapeutic Range Band Visibility
expected: Blue therapeutic range band is visible behind/through the concentration bars
result: skipped
reason: Cannot evaluate until chart is rendered as histogram (Test 2 must pass first)

## Summary

total: 3
passed: 0
issues: 2
pending: 0
skipped: 1

## Gaps

- truth: "Steady state progress shows correct percentage based on time on medication"
  status: failed
  reason: "User reported: Still shows 0% with 90 days of seeded medication history (--seed-test-90d flag)"
  severity: blocker
  test: 1
  root_cause: "User has persisted data from BEFORE the 41-FIX was applied. The old MedicationProfile lacks medicationType field. Fix is correct but requires app reinstall to get fresh seeded data."
  artifacts:
    - path: "JabTracker/AuthenticationManager.swift"
      issue: "Lines 277-281: isNewUser check skips seeding for existing users"
  missing:
    - "Delete and reinstall app to trigger fresh data seeding with medicationType fix"
  debug_session: ""

- truth: "Concentration chart displays as histogram with vertical bars"
  status: failed
  reason: "User reported: Chart displays as area/line chart with fill, not vertical histogram bars"
  severity: major
  test: 2
  root_cause: "Code IS using BarMark correctly, but 0.5-hour intervals over 30 days = 1440 bars that visually blend together. High-resolution time series with BarMark inherently looks like area fill. Either increase bar width or accept this is the expected visual rendering."
  artifacts:
    - path: "JabTracker/Views/Analytics/ConcentrationTimelineChart.swift"
      issue: "Line 183 uses BarMark correctly, visual result is dense bars that blend"
    - path: "JabTracker/Models/ChartData.swift"
      issue: "Line 162: intervalHours 0.5 creates 1440+ data points for 30-day view"
  missing:
    - "Either accept current rendering OR increase intervalHours for wider bars OR add explicit bar width"
  debug_session: ""
