---
created: 2026-01-13T11:42
title: Change drug concentration graph to histogram
area: analytics
files:
  - JabTracker/Views/Analytics/ConcentrationTimelineChart.swift:183-189
---

## Problem

The current drug concentration visualization uses `LineMark` to render a line chart showing medication concentration over time. This needs to be changed to a histogram format for better visualization of concentration levels.

Current implementation in `ConcentrationTimelineChart.swift`:
- Lines 183-189: Uses `LineMark` with concentration points
- Renders as a continuous line chart with rounded caps
- Shows concentration curve over time with dose markers

## Solution

TBD - Needs investigation of:
- Swift Charts histogram options (likely `RectangleMark` or `BarMark`)
- Appropriate bin width/interval for time-based concentration data
- How to handle dose markers in histogram format
- Visual design to maintain therapeutic range band display
- Accessibility considerations for histogram vs line chart
