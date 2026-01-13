---
created: 2026-01-12T17:32:42Z
title: Add concentration card to Analytics view
area: ui
files:
  - JabTracker/Views/Dashboard/ConcentrationCard.swift
  - JabTracker/Views/Dashboard/ConcentrationDisplay.swift
  - JabTracker/Views/Analytics/ConcentrationView.swift
---

## Problem

The drug concentration widget was previously displayed on the dashboard but was removed during the v0.7.0 Dashboard Widget UX milestone. Users with medication profiles need to see their current GLP-1 concentration level.

Rather than adding it back to the dashboard (which would clutter the new widget-based layout), the concentration display should be added to the GLP-1 Programs > Analytics > Concentration View, above the existing chart.

This is a temporary placement until the Analytics section is redesigned.

## Solution

1. Add `ConcentrationCard` (or similar component) to `ConcentrationView.swift`
2. Position above the existing concentration chart
3. Reuse existing `ConcentrationCard.swift` and `ConcentrationDisplay.swift` components
4. This is temporary - will be reconsidered during Analytics redesign
