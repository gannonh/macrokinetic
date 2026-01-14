---
created: 2026-01-14T08:42
title: Persist serving units for custom and history foods
area: database
files:
  - JabTracker/Models/FoodEntry.swift
  - JabTracker/Models/Food.swift
  - JabTracker/Views/Nutrition/FoodDetailSheet.swift
  - JabTracker/Services/FoodService.swift
---

## Problem

Serving unit options (eg. "1 serving", "1 pouch", "1 bar", "1 cup") displayed in FoodDetailSheet are not being persisted when:

1. **Saving to custom foods** — Custom foods lose their serving unit options
2. **Using foods from history** — Historical food entries don't retain available serving units
3. **Editing food entries** — When editing a previously logged entry, only gram-based serving is available

The serving unit options come from the LocalFoodDatabase (parsed from USDA/OFF data), but this metadata is not being saved to:
- `FoodEntry` when logging a food
- `Food` model when saving as custom food

Result: Users can select "1 pouch" the first time they use a food from the database, but on subsequent uses (from history or custom), they can only see gram-based entry.

## Solution

TBD - Need to investigate:

1. **Check current models**: Review `FoodEntry` and `Food` (custom) to see what serving-related fields exist
2. **Trace the data flow**: How do serving options get to FoodDetailSheet, and why aren't they round-tripped?
3. **Possible approaches**:
   - Add `servingOptions` field to `FoodEntry` to store available units at time of logging
   - Add `servingOptions` field to custom `Food` when saving from database food
   - Create a separate `ServingOption` model with relationship to Food/FoodEntry
4. **Consider**: Storage cost vs. user experience for preserving all serving options
