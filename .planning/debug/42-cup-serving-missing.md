---
status: diagnosed
trigger: "Cup serving unit missing for valid rice products - user searched for '365 everyday value, indian basmati rice', expected cup option but only sees serving/g/oz"
created: 2026-01-16T00:00:00Z
updated: 2026-01-16T00:00:00Z
---

## Current Focus

hypothesis: CONFIRMED - Validation ignores fractional cup quantities
test: Traced validation logic with actual database values
expecting: N/A - root cause confirmed
next_action: Report diagnosis

## Symptoms

expected: "cup" should appear as serving unit option for rice (49g serving = ~0.25 cups, rice density ~180-200g/cup)
actual: Only "serving", "g", "oz" appear as options
errors: none
reproduction: Search "365 everyday value, indian basmati rice" in food search, tap to view serving options
started: After phase 42 serving label validation implementation

## Eliminated

- hypothesis: OFF database missing cup data for this product
  evidence: Database query shows `serving_options: ["100g", "0.25 cup (49 g) (49g)"]` - cup data IS present
  timestamp: 2026-01-16

## Evidence

- timestamp: 2026-01-16
  checked: SQLite database for "365 everyday value, indian basmati rice" (fdc_id 2941749)
  found: serving_options = `["100g", "0.25 cup (49 g) (49g)"]`, serving_size = 49.0g
  implication: OFF data correctly has "0.25 cup" with 49g weight

- timestamp: 2026-01-16
  checked: formatLabel() output in ServingPillPicker.swift
  found: "0.25 cup (49 g) (49g)" is formatted to "cup (49 g)" by regex pattern `^[\d.]+\s+(.+?)\s*\([^)]+\)$`
  implication: The "0.25" prefix is stripped, but "(49 g)" is kept as part of the label

- timestamp: 2026-01-16
  checked: isServingLabelSuspicious() in ServingPillPicker.swift
  found: Label "cup (49 g)" contains "cup", so validation checks if 49g is in range [80, 300]
  implication: 49g < 80g minimum, so label is marked SUSPICIOUS and replaced with "serving"

- timestamp: 2026-01-16
  checked: Both process-off-data.py and ServingPillPicker.swift validation
  found: Both use the SAME logic - checking if gram value is within [80, 300] for "cup"
  implication: Validation assumes 1 cup = 80-300g, but ignores fractional cups

## Resolution

root_cause: |
  The serving label validation in both `process-off-data.py` and `ServingPillPicker.swift`
  does NOT account for fractional cup servings.

  The validation checks:
  - If label contains "cup", grams must be in range [80, 300]

  The problem:
  - OFF data often has fractional cup servings like "0.25 cup (49g)"
  - 49g is CORRECT for 0.25 cups of rice (rice density ~180-200g/cup, so 0.25 * 180 = 45g)
  - But validation compares 49g against 1-cup range [80, 300]
  - 49g < 80g, so it's incorrectly marked as "suspicious"

  The fix should:
  1. Parse the fractional quantity from the serving label (e.g., "0.25" from "0.25 cup")
  2. Scale the acceptable gram range by the quantity (0.25 * [80, 300] = [20, 75])
  3. Then check if actual grams falls within the scaled range

fix:
verification:
files_changed:
  - JabTracker/Views/Nutrition/ServingPillPicker.swift (lines 56-71, isServingLabelSuspicious)
  - scripts/process-off-data.py (lines 75-96, is_serving_label_suspicious)
