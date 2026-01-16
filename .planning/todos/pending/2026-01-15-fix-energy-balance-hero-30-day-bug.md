---
created: 2026-01-15T21:45
title: Fix energy balance hero 30-day calculation bug
area: analytics
files:
  - JabTracker/ViewModels/EnergyBalanceHeroViewModel.swift
  - JabTracker/Views/Dashboard/Widgets/EnergyBalanceHeroWidget.swift
  - JabTracker/ViewModels/EnergyBalanceWidgetViewModel.swift (reference - correct)
  - JabTracker/Views/Dashboard/DetailViews/EnergyBalanceDetailView.swift (reference - correct)
---

## Problem

Energy balance dashboard hero displays incorrect calculation - appears to include 30 days in the calculation even when there are only a few days of actual data. 

The energy balance widget detail view calculates correctly using the actual data range.

This suggests EnergyBalanceHeroViewModel has a hardcoded 30-day period or is not properly filtering to available data, while EnergyBalanceWidgetViewModel (used by detail view) correctly handles the data range.

User reports: Hero shows wrong values with ~4 days of data, while detail view is correct.

## Solution

Compare EnergyBalanceHeroViewModel calculation logic against EnergyBalanceWidgetViewModel (which is correct):

1. Check if hero is hardcoding 30-day lookback instead of using actual data range
2. Ensure hero filters to days with actual data (non-zero entries)
3. Match the calculation logic between hero and detail view

Likely issue: Hero using fixed 30-day period, detail view using actual data days.
