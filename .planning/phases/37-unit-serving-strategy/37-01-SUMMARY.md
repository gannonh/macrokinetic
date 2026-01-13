# Phase 37-01 Summary: Unit/Serving Strategy - Horizontal Pill Picker

**Status:** Complete
**Completed:** 2026-01-12

## What Was Built

Implemented a horizontal scrollable pill picker for serving unit selection in FoodDetailSheet, matching the MacroFactor UX pattern.

### Components Created

1. **ServingPillPicker.swift** - Reusable horizontal pill picker component
   - `ServingPillOption` struct with label, grams, and isUnitOnly flag
   - Auto-parses multi-word descriptions from database (e.g., "whole without shell")
   - Always includes "g" and "oz" as universal fallback options
   - Auto-selects first item-based option on appear

2. **FoodDetailSheet Integration**
   - Replaced unit buttons with ServingPillPicker
   - Smart serving count conversion when switching pills
   - Proper initialization based on food's serving options

### Key Behaviors

- **Item-based options** (e.g., "large apple", "cup slices"): Selecting resets to 1
- **Unit-only options** (g/oz): Selecting converts to preserve gram amount
- **Foods without item options**: Default to food's serving size (e.g., 100g) not 1g

## Commits

1. `ef20d22` - feat(37-01): create ServingPillPicker component
2. `545230e` - feat(37-01): integrate ServingPillPicker into FoodDetailSheet
3. `cc959f6` - fix(37-01): parse multi-word serving descriptions
4. `9e8d76d` - fix(37-01): preserve gram amount when switching serving pills
5. `fdb546e` - fix(37-01): reset to 1 when selecting item-based serving options
6. `8c9400b` - fix(37-01): use food serving size for gram-only foods

## Files Changed

- `JabTracker/Views/Nutrition/ServingPillPicker.swift` (new)
- `JabTracker/Views/Nutrition/FoodDetailSheet.swift`
- `JabTracker/Views/Nutrition/FoodDetailSheet+InputSection.swift`
- `JabTracker/Services/FoodService.swift` (regex fix)
- `coverage-config.json`

## Testing Notes

Verified with:
- Eggs (multi-word description: "whole without shell")
- Apples, raw, without skin (multiple size options)
- Apples, fuji, with skin (gram-only, no item options)

## Next Steps

Phase 37 complete. Consider:
- Unit tests for ServingPillPicker
- E2E tests for serving selection flow
