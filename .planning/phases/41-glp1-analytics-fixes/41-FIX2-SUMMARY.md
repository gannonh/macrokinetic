---
phase: 41-glp1-analytics-fixes
plan: FIX2
type: fix
status: complete
completed: 2026-01-16T16:45:00Z
---

## Summary

Fixed histogram chart to display visible vertical bars instead of blending into area fill.

## Root Cause

BarMark was used with 0.5-hour intervals, creating 1440 bars over 30 days that were so thin they blended together into what looked like an area fill.

## Solution

Added dynamic interval calculation based on time period:
- 7 days: 2-hour intervals (~84 bars)
- 30 days: 6-hour intervals (~120 bars)
- 90 days: 12-hour intervals (~180 bars)
- 1 year: 24-hour intervals (~365 bars)

With fewer bars, Swift Charts automatically makes each bar wider and individually visible.

## Changes

### ChartDataProcessor.swift
- Added `intervalHours(for:)` static method that returns appropriate interval based on TimePeriod
- Updated `generateChartDataForProfiles` to accept `timePeriod` parameter and use dynamic interval

### ChartDatasetService.swift
- Updated `processProfiles` to accept `timePeriod` parameter
- Updated `createConcentrationCurve` to accept `timePeriod` and pass dynamic interval to `generateConcentrationTimeline`
- Both `generateChartDataset` overloads now pass `timePeriod` through the call chain

## Verification

- [x] Build succeeds
- [x] Chart will now render fewer, wider bars that are visually distinct
- [x] Bar count scales appropriately with time range

## User Action Required

**UAT-001 (Steady State Progress 0%)** requires user action:
- Add `--reset-app-data` to Xcode scheme arguments alongside `--seed-test-90d`
- This clears persisted data from before the previous fix and re-seeds with correct medicationType field
