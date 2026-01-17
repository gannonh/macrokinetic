---
created: 2026-01-15T18:30
title: Fix food entry unit conversion when editing
area: ui
files:
  - JabTracker/Views/Nutrition/FoodEntryEditSheet.swift
---

## Problem

When editing a food entry that uses "1 serving" as the unit, changing the unit to grams incorrectly converts to "1 g" instead of the proper gram equivalent based on the food's serving size.

Example scenario:
1. User has food entry: "1 serving" (where 1 serving = 50g)
2. User edits and changes unit from "serving" to "g"
3. Bug: Amount stays as "1" resulting in "1 g"
4. Expected: Amount should convert to "50 g" (the gram equivalent of the serving)

The unit conversion logic is not calculating the equivalent amount when switching between units.

## Solution

TBD - Investigate:

1. Check `FoodEntryEditSheet.swift` for unit change handling
2. Ensure conversion factors are properly applied when switching units
3. When changing from "serving" to "g", multiply amount by serving_weight_grams
4. When changing from "g" to "serving", divide amount by serving_weight_grams
5. Handle edge cases like serving_weight_grams being nil or zero
