---
status: diagnosed
phase: 41-glp1-analytics-fixes
source: [41-01-SUMMARY.md, 41-02-SUMMARY.md]
started: 2026-01-16T03:05:00Z
updated: 2026-01-16T06:45:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Steady State Progress Display
expected: ConcentrationCard shows steady state progress as a percentage between 0-100% (not 2416% or other inflated values)
result: issue
reported: "Shows 0% instead of expected ~36% (9 days on medication / 25 days to steady state)"
severity: major

### 2. Concentration Chart Histogram Format
expected: Concentration chart displays as vertical bars (histogram) instead of a line. Bars should have slight transparency (0.8 opacity) so the therapeutic range band shows through.
result: issue
reported: "Shows single vertical bar at one time point instead of multiple bars across time axis. Not a histogram - should show concentration values at regular intervals (hourly) over the time period."
severity: major

### 3. Therapeutic Range Band Visibility
expected: Blue therapeutic range band is visible behind/through the concentration bars
result: issue
reported: "No therapeutic range band visible on the chart"
severity: major

### 4. Dose Markers on Chart
expected: Green dots marking injection times are visible on or near the concentration bars
result: pass

## Summary

total: 4
passed: 1
issues: 3
pending: 0
skipped: 0

## Gaps

- truth: "Steady state progress shows correct percentage (0-100%) based on time on medication"
  status: failed
  reason: "User reported: Shows 0% instead of expected ~36% (9 days on medication / 25 days to steady state)"
  severity: major
  test: 1
  root_cause: "MedicationProfile created without explicit medicationType parameter in AuthenticationManager.swift:1297. The fallback logic leaves medicationType as empty string, causing medicationProfile.medication to return nil, which makes calculateSteadyStateProgress return 0.0"
  artifacts:
    - path: "JabTracker/AuthenticationManager.swift"
      issue: "Line 1297 creates MedicationProfile without medicationType parameter"
    - path: "JabTracker/Models/MedicationProfile.swift"
      issue: "Lines 64-68 fallback logic doesn't complete successfully"
    - path: "JabTracker/Services/PharmacokineticsEngine.swift"
      issue: "Line 147 guard returns 0.0 when medication is nil"
  missing:
    - "Add medicationType: config.medication.rawValue to MedicationProfile initialization"

- truth: "Concentration chart displays as histogram with multiple time-distributed bars"
  status: failed
  reason: "User reported: Shows single vertical bar at one time point instead of multiple bars across time axis. Not a histogram - should show concentration values at regular intervals (hourly) over the time period."
  severity: major
  test: 2
  root_cause: "Insufficient data point density. Chart uses BarMark correctly but concentration data is sampled at 2-hour intervals instead of 30-minute intervals, resulting in too few data points to form a proper histogram."
  artifacts:
    - path: "JabTracker/Models/ChartData.swift"
      issue: "Lines 160-165 InterpolationSettings defaults to intervalHours: 2.0 (should be 0.5)"
    - path: "JabTracker/Services/ChartDatasetService.swift"
      issue: "Line 746 uses intervalHours: 2.0 instead of 0.5"
  missing:
    - "Change intervalHours from 2.0 to 0.5 in InterpolationSettings.pharmacokinetic"
    - "Update ChartDatasetService to use finer sampling interval"

- truth: "Blue therapeutic range band is visible behind/through the concentration bars"
  status: failed
  reason: "User reported: No therapeutic range band visible on the chart"
  severity: major
  test: 3
  root_cause: "Default chart configuration uses ConcentrationRange.automatic instead of .therapeuticWindow. The RectangleMark rendering is guarded by pattern match on .therapeuticWindow which never succeeds."
  artifacts:
    - path: "JabTracker/Services/ChartDatasetService.swift"
      issue: "Lines 54-58, 89-93 create configuration with .default which uses .automatic instead of therapeutic window"
    - path: "JabTracker/Models/ChartData.swift"
      issue: "Lines 29-38 default configuration uses ConcentrationRange.automatic"
  missing:
    - "ChartDatasetService.generateChartDataset() must extract medication therapeutic window values"
    - "Pass .therapeuticWindow(min:max:optimal:) to configuration instead of using .default"
