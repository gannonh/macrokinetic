---
stream: A
title: Service Layer Medical Fix
issue: 180
started: 2025-10-20T18:00:00Z
status: in_progress
---

# Stream A: Service Layer Medical Fix

## Scope
Fix split-dose interval calculation (720 → 5040 minutes) and add medication-aware configuration method.

## Files Owned
**Implementation**:
- `JabTracker/Services/ScheduleService.swift`
- `JabTracker/Onboarding/OnboardingViewModel.swift`

**Tests**:
- `JabTrackerTests/ScheduleServiceTests.swift`
- `JabTrackerTests/ScheduleServiceProjectionTests.swift`

## Progress

### Session 1: 2025-10-20T18:00:00Z - 18:30:00Z
**Status**: RED phase complete, moving to GREEN phase

**TDD Progress**:
- ✅ Step 1 (RED): Written 5 failing tests
  - testSplitDoseConfigurationWeeklyMedication
  - testSplitDoseConfigurationDailyMedicationThrows
  - testSplitDoseConfigurationTirzepatide
  - testGenerateSplitDoseScheduleCorrectInterval
  - testSplitDoseTwiceWeeklyPattern

**Test Compilation Fixes**:
- Fixed test file structure issues (closing braces)
- Fixed property name: `dose.amount` → `dose.doseAmount`
- All tests now compile and fail correctly (method doesn't exist)

**Next Steps**:
1. Add `splitDoseNotSupported` error case to `ScheduleServiceError` enum
2. Implement `ScheduleConfiguration.splitDoseConfiguration()` static method
3. Update `OnboardingViewModel.swift` hardcoded 720 → 5040 minutes
4. Run tests to verify GREEN phase
5. Commit working implementation

## Test Results
- Total Tests Added: 5
- Compilation Status: ✅ Passing
- Test Execution: ❌ Failing (expected - method not implemented)
- Error: "type 'ScheduleConfiguration' has no member 'splitDoseConfiguration'"

## Blockers
None

## Notes
- Medical accuracy critical: 5040 minutes = 3.5 days = 84 hours
- Split-dose pattern: Wednesday 8pm + Sunday 8am example
- ScheduledDose uses `doseAmount` property (not `amount`)
- TimeConstants.defaultWindowMinutes = 120 (2 hours)
