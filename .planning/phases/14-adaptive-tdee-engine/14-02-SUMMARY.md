# Phase 14 Plan 02: Adaptive TDEE Calculations Summary

**EWMA weight smoothing, adaptive TDEE from intake/weight history, confidence scoring, metabolic adaptation detection, and input validation with typed errors**

## Performance

- **Duration:** 9 min
- **Started:** 2025-12-28T16:27:00Z
- **Completed:** 2025-12-28T16:36:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Created EWMA weight smoothing extension with trend analysis and plateau detection
- Implemented adaptive TDEE calculation from calorie intake and weight change (7700 kcal/kg formula)
- Added confidence scoring based on data duration, logging consistency, and trend clarity
- Built metabolic adaptation detection (>15% TDEE drop triggers alert)
- Created comprehensive validation with typed LocalizedError messages
- Added 36 new tests (suite total now 54 tests)

## Files Created/Modified

- `JabTracker/Services/TDEECalculationEngine+EWMA.swift` - EWMA smoothing, weight change rate, plateau detection
- `JabTracker/Services/TDEECalculationEngine+Adaptive.swift` - Adaptive TDEE, confidence scoring, metabolic adaptation
- `JabTracker/Services/TDEECalculationEngine+Validation.swift` - ValidationError enum with user-friendly messages
- `JabTrackerTests/Services/TDEECalculationEngineTests.swift` - 36 new tests for all new functionality

## Decisions Made

- Formula clarification: Used `TDEE = intake - (weightChange × 7700 / days)` (negative change = weight loss = higher TDEE)
- Confidence score weighting: 50% consistency, 30% duration, 20% trend clarity (consistency most important for accuracy)
- Minimum 7 days required for weight change rate calculation
- Alpha clamped to 0.01-1.0 range for EWMA (prevents division issues)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected TDEE formula direction**
- **Found during:** Task 2 (Adaptive TDEE implementation)
- **Issue:** Plan formula `TDEE = intake + (weightChange × 7700 / days)` was inverted for weight loss
- **Fix:** Changed to subtraction: `TDEE = intake - (weightChange × 7700 / days)` so weight loss (negative) increases TDEE
- **Files modified:** JabTracker/Services/TDEECalculationEngine+Adaptive.swift
- **Verification:** Tests confirm 2kg loss with 1800 intake → TDEE ≈ 2900 (correct)

**2. [Rule 3 - Blocking] Removed private logger access**
- **Found during:** Task 2 (Adaptive TDEE logging)
- **Issue:** `logger` property is private in base class, not accessible in extension
- **Fix:** Removed debug logging from adaptive extension (can add computed property later if needed)
- **Files modified:** JabTracker/Services/TDEECalculationEngine+Adaptive.swift
- **Verification:** Build succeeds

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both fixes necessary for correctness. No scope creep.

## Issues Encountered

None - plan executed as written after formula correction.

## Next Phase Readiness

- TDEECalculationEngine fully equipped for adaptive TDEE calculations
- EWMA smoothing ready for weight trend analysis
- Confidence scoring enables UI indicators for data quality
- Metabolic adaptation detection ready for user alerts
- All validations in place for robust input handling
- Ready for 14-03: TDEE service integration and user-facing features

---
*Phase: 14-adaptive-tdee-engine*
*Completed: 2025-12-28*
