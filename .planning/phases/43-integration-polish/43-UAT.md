---
status: complete
phase: 43-integration-polish
source: [43-01-SUMMARY.md, 43-02-SUMMARY.md]
started: 2026-01-16T22:30:00Z
updated: 2026-01-17T07:15:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Energy Balance Hero Average - New User
expected: Dashboard Energy Balance Hero widget shows accurate average based on actual days of data (not divided by 30). If you have 5 days of data, average is total/5, not total/30.
result: issue
reported: "fail. see image. --seed-2-week-active shows Last 0 Days, Nutrition 0, Difference -2,000"
severity: major

### 2. Energy Balance Hero Label - Dynamic Range
expected: Energy Balance Hero label dynamically shows "Last N Days" reflecting actual data range (e.g., "Last 5 Days" for 5 days of data, "Last 30 Days" when full 30 days exist).
result: issue
reported: "fail. no data per prior question."
severity: major

### 3. Next Dose - Weekly Schedule
expected: For a weekly GLP-1 schedule, the "Next Dose" date shows exactly 7 days after your last taken dose (not offset from the schedule creation date).
result: pass

### 4. Next Dose - Calendar View
expected: In Calendar view, the projected next dose appears on the correct day based on your actual dosing pattern.
result: pass

## Summary

total: 4
passed: 2
issues: 2
pending: 0
skipped: 0

## Gaps

- truth: "Energy Balance Hero widget shows accurate average based on actual days of data"
  status: failed
  reason: "User reported: fail. see image. --seed-2-week-active shows Last 0 Days, Nutrition 0, Difference -2,000"
  severity: major
  test: 1
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Energy Balance Hero label dynamically shows Last N Days reflecting actual data range"
  status: failed
  reason: "User reported: fail. no data per prior question."
  severity: major
  test: 2
  artifacts: []
  missing: []
  debug_session: ""
