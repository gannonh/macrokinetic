---
created: 2026-01-13T10:48
title: Mark fast days to exclude from calculations
area: analytics
files:
  - JabTracker/Views/Dashboard/Widgets/WeeklyNutritionHeroWidget.swift
  - JabTracker/Views/Dashboard/Widgets/EnergyBalanceHeroWidget.swift
  - JabTracker/Models/FoodEntry.swift
---

## Problem

Users who practice intermittent fasting or have occasional fast days will have their analytics skewed. A day with zero (or minimal) food logged throws off:

- Weekly/monthly calorie averages (average drops significantly)
- Adherence calculations (fast day looks like "missed logging")
- Trend analysis (creates artificial dips)
- Energy balance tracking (shows massive deficit)

Without a way to mark a day as intentional fasting, the system can't distinguish between:
1. User forgot to log
2. User intentionally fasted
3. User is in the middle of logging (partial day - related todo)

## Solution

TBD - Possible approaches:

1. **Explicit fast day marker**: Add a "Mark as fast day" button in daily view. Store as flag on day or as special FoodEntry type.

2. **Day status enum**: Each day has status: `logging`, `complete`, `fasting`, `skipped`. Used in all aggregate calculations.

3. **Automatic detection + confirmation**: If day has <200 calories logged, prompt "Was this a fast day?" next morning.

4. **Calendar integration**: Allow marking days in calendar view as fast days (past or planned).

Related to: Handle partial day calculations todo (both need concept of "day completeness status")
