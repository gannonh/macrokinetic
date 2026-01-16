---
created: 2026-01-16T06:16
title: Fix concentration timeline showing single vertical bar
area: analytics
files:
  - JabTracker/Views/Analytics/ConcentrationTimelineChart.swift
---

## Problem

The Concentration Timeline chart (7d view) is showing a single vertical bar instead of a proper decay curve or histogram showing concentration over time.

Screenshot shows:
- Y-axis: 0.0 to 1.5 (concentration scale)
- X-axis: Not visible but labeled "Last Week"
- Single teal vertical bar from 0.0 to ~1.5 with green dot at top
- Expected: Multiple bars showing concentration decay over time, or proper histogram bins

This appears to be a rendering/data issue where:
1. All concentration data points may be collapsing to a single x-coordinate
2. Date binning may not be working correctly
3. The x-axis domain may be incorrect

Note: This is separate from the histogram format change (completed in Phase 41). The histogram should be working but is rendering incorrectly.

## Solution

TBD - Need to investigate:

1. Check the concentration data being passed to the chart
2. Verify x-axis (date) domain is correct for 7-day range
3. Check if BarMark width calculation is causing collapse
4. Verify ConcentrationCalculator is returning multiple time points, not just one
