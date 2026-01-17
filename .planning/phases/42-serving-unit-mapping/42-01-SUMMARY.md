---
phase: 42-serving-unit-mapping
plan: 01
subsystem: nutrition, ui
tags: [serving-size, food-database, data-validation, swiftui]

# Dependency graph
requires:
  - phase: 37-unit-serving-strategy
    provides: ServingPillPicker component and ServingOption model
provides:
  - Serving label validation in data processor (new imports)
  - Runtime serving label sanitization in UI (existing data)
  - Correct unit conversion when editing food entries
affects: [nutrition-tracking, food-logging, data-quality]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Density-based validation for volume-to-weight unit mappings"
    - "Runtime sanitization of suspicious labels at display time"

key-files:
  created: []
  modified:
    - scripts/process-off-data.py
    - JabTracker/Views/Nutrition/ServingPillPicker.swift
    - JabTracker/Views/Nutrition/EditFoodEntrySheet.swift

key-decisions:
  - "Use density thresholds (cup: 80-300g, tbsp: 5-25g, tsp: 2-10g) to detect suspicious unit labels"
  - "Sanitize suspicious labels to generic 'serving' instead of removing them"
  - "Apply validation both at data import time AND at UI display time (defense in depth)"

patterns-established:
  - "SUSPICIOUS_UNIT_RATIOS: dictionary of min/max gram ranges for volume units"
  - "isServingLabelSuspicious(): validation function reused in Python and Swift"

# Metrics
duration: 5min
completed: 2026-01-16
---

# Phase 42 Plan 01: Serving Unit Mapping Summary

**Density-based validation for serving unit labels with runtime sanitization for existing bad data and correct unit conversion in edit sheet**

## Performance

- **Duration:** 5 min
- **Started:** 2026-01-16T21:09:35Z
- **Completed:** 2026-01-16T21:14:56Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added SUSPICIOUS_UNIT_RATIOS dictionary to data processor for validating serving labels
- Implemented isServingLabelSuspicious() function in both Python (data processor) and Swift (UI)
- Fixed unit conversion bug in EditFoodEntrySheet when switching serving units
- Moved 2 related todos to done: serving-unit-gram-mapping and food-entry-unit-conversion

## Task Commits

Each task was committed atomically:

1. **Task 1: Investigate database and add serving label validation to data processor** - `277a5b3a` (feat)
2. **Task 2: Add defensive serving label validation to UI** - `a68890f8` (feat)
3. **Task 3: Fix unit conversion when editing food entries** - `55f796ae` (fix)

## Files Created/Modified

- `scripts/process-off-data.py` - Added SUSPICIOUS_UNIT_RATIOS and is_serving_label_suspicious() for new imports
- `JabTracker/Views/Nutrition/ServingPillPicker.swift` - Added isServingLabelSuspicious() for runtime validation
- `JabTracker/Views/Nutrition/EditFoodEntrySheet.swift` - Added onChange handler and convertServingCount function

## Decisions Made

1. **Density thresholds chosen:** Cup 80-300g, tbsp 5-25g, tsp 2-10g based on typical food densities
2. **Sanitize rather than reject:** Suspicious labels become "serving" to preserve gram data
3. **Defense in depth:** Validate at both import time and display time for existing bad data

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Serving unit validation complete for both new and existing data
- Unit conversion in edit sheet now works correctly
- Ready for manual testing: search for rice, verify suspicious cups show as "serving"
- Ready for manual testing: edit entry, switch serving->grams, verify amount converts

---
*Phase: 42-serving-unit-mapping*
*Completed: 2026-01-16*
