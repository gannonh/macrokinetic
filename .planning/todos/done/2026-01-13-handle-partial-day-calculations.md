---
created: 2026-01-13T10:45
title: Handle partial day calculations in dashboard
area: analytics
files:
  - JabTracker/Views/Dashboard/Widgets/DailyNutritionHeroWidget.swift
  - JabTracker/Views/Dashboard/Widgets/WeeklyNutritionHeroWidget.swift
  - JabTracker/Views/Dashboard/Widgets/EnergyBalanceHeroWidget.swift
---

## Problem

When a user logs only breakfast (or any partial day's food), the dashboard calculations are misleading. The current implementation treats the day as complete, showing metrics like "You consumed 400 calories" when the user hasn't finished logging for the day.

This affects:
- Daily nutrition summaries showing incomplete data as if it's final
- Weekly averages that include partial "today" data, skewing the average down
- Energy balance calculations that compare partial intake to full day targets

The core issue: **How do we know when a day's logging is "complete"?**

## Solution

TBD - Possible approaches to explore:

1. **Prior day only**: Only calculate/display completed days (yesterday and before). Today shown separately with "in progress" indicator.

2. **User signals completion**: Add a "Done logging for today" button that marks the day as complete.

3. **Time-based heuristic**: Consider a day "complete" after a certain hour (e.g., 10 PM) or after no new entries for X hours.

4. **Hybrid approach**: Show "today so far" with different styling, use only complete days for averages/trends.

5. **Projection**: Show "on track" / "projected" based on time of day and logged meals.

Need to decide which approach provides best UX without adding friction to logging flow.
