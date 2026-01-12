---
created: 2026-01-12T17:32:42Z
title: Restore concentration widget to dashboard
area: ui
files:
  - JabTracker/Views/Dashboard/ConcentrationCard.swift
  - JabTracker/Views/Dashboard/ConcentrationDisplay.swift
  - JabTracker/Models/MedicationProfile.swift
---

## Problem

The drug concentration widget was previously displayed on the dashboard but was removed during the v0.7.0 Dashboard Widget UX milestone. Users with medication profiles need to see their current GLP-1 concentration level on the dashboard.

The widget should only be shown when:
- User has an active medication profile configured
- Position: last item in the dashboard widget grid

The components still exist (`ConcentrationCard.swift`, `ConcentrationDisplay.swift`) but need to be re-integrated into the new widget-based dashboard layout.

## Solution

1. Add `ConcentrationCard` (or wrap in new `ConcentrationWidget`) as the last standard widget in dashboard
2. Add conditional visibility based on `MedicationProfile` existence
3. Query user's medication profile to determine if widget should render
4. Follow existing widget patterns from Phase 32 (InsightsWidgetSection)
