---
created: 2026-01-13T10:52
title: Fix serving unit to gram mapping for foods
area: database
files:
  - JabTracker/Services/LocalFoodDatabase.swift
  - JabTracker/Views/Nutrition/FoodDetailSheet.swift
  - scripts/process-off-data.py
---

## Problem

Food "365 everyday value, indian basmati rice" displays incorrectly:
- Shows: 1 cup = 49g
- Expected: 1 cup dry rice ≈ 180g

The screenshot shows 170 calories for 1 "cup" at 49g. This suggests the source data has:
- Serving size: 49g (the actual reference amount)
- Serving unit: "cup" (incorrectly assumed or parsed)

The 49g is likely the **serving size in grams** from the nutrition label (typical "1/4 cup dry" = ~45g), but we're displaying it as if 1 full cup = 49g.

This is a data parsing/mapping issue where:
1. Source data may say "serving_size: 49g" and "serving_unit: cup" separately
2. We're treating them as "1 cup = 49g" instead of understanding the actual volume-to-weight relationship
3. Or the source data itself is malformed (Open Food Facts quality varies)

## Solution

TBD - Need to investigate:

1. **Check source data**: Query the SQLite database for this specific product to see raw data
   ```sql
   SELECT * FROM foods WHERE name LIKE '%365%basmati%';
   ```

2. **Review parsing logic**: Check `process-off-data.py` and `LocalFoodDatabase.swift` for how serving_size and serving_unit are mapped

3. **Possible fixes**:
   - Validate serving unit makes sense for the gram weight
   - Use density data for common foods (rice, flour, etc.) to sanity check
   - Fall back to grams-only if unit mapping is suspicious
   - Flag items with unrealistic unit-to-gram ratios for review

4. **Consider**: Should we show "serving" instead of "cup" when we can't verify the actual measurement?
