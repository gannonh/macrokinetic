---
issue: 180
title: Fix Split-Dose Medical Accuracy & Add Medication-Specific Patterns
analyzed: 2025-10-20T17:32:36Z
estimated_hours: 5
parallelization_factor: 2.5
---

# Parallel Work Analysis: Issue #180

## Overview
Fix critical medical accuracy bug where split-dose pattern uses 12-hour interval (twice daily) instead of 3.5-day interval (twice weekly) for weekly medications. Add medication-specific pattern filtering to prevent daily medications from showing split-dose option. Remove non-functional custom pattern option from UI.

**Critical Safety Issue**: Current implementation could lead to medication overdosing by suggesting daily dosing for weekly medications.

## Scope Reassessment

✅ **Scope is valid and critical**
- Medical accuracy bug poses patient safety risk
- Issue is well-defined with clear fix identified
- Not redundant with any prior work
- All required files exist and are accessible
- Dependencies (Issue #175 - ScheduleService) are complete

✅ **Ready to proceed with implementation**

## Parallel Streams

### Stream A: Service Layer Medical Fix
**Scope**: Fix split-dose interval calculation and add medication-aware configuration
**Implementation Files**:
- `JabTracker/Services/ScheduleService.swift` (add `splitDoseConfiguration()` method)
- `JabTracker/Onboarding/OnboardingViewModel.swift` (update hardcoded 720 → 5040 minutes)
**Unit/Integration Testing Files**:
- `JabTrackerTests/ScheduleServiceTests.swift` (add split-dose configuration tests)
- `JabTrackerTests/ScheduleServiceProjectionTests.swift` (verify 3.5-day interval projection)
**E2E Testing Files**:
- N/A (backend logic only)
**Product Area**: backend
**Can Start**: immediately
**Estimated Hours**: 2
**Dependencies**: none

**Outside-In TDD Workflow**:
1. **E2E Acceptance Criteria**: No E2E tests for this stream (backend service layer only)
2. **Unit Tests (RED)**: Write failing tests for `splitDoseConfiguration()` method
   - Test: Split-dose config for weekly medication returns 5040 minutes interval
   - Test: Split-dose config throws error for daily medication
   - Test: Projected doses use 3.5-day spacing
3. **Implementation**: Add `splitDoseConfiguration()` to ScheduleService
4. **Unit Tests (GREEN)**: Verify tests pass
5. **Integration Tests**: Not needed (service method only)

### Stream B: UI Pattern Filtering & Description Updates
**Scope**: Add medication-specific filtering, update UI descriptions, remove custom pattern option
**Implementation Files**:
- `JabTracker/Onboarding/Components/SchedulePatternPicker.swift` (add medication filtering)
- `JabTracker/Onboarding/Components/SchedulePatternCard.swift` (update descriptions, remove custom)
- `JabTracker/Views/Settings/DoseScheduleEditView.swift` (add filtering, update descriptions, remove custom)
**Unit/Integration Testing Files**:
- `JabTrackerTests/OnboardingViewModelTests.swift` (verify pattern filtering logic)
**E2E Testing Files**:
- `JabTrackerUITests/OnboardingScheduleSetupUITests.swift` (medication filtering tests)
- `JabTrackerUITests/DoseScheduleEditUITests.swift` (settings filtering tests)
**Product Area**: frontend
**Can Start**: immediately (UI changes independent of service layer)
**Estimated Hours**: 2
**Dependencies**: none

**Outside-In TDD Workflow**:
1. **E2E Acceptance Criteria (Stub)**: Create stub E2E tests for pattern filtering
   - STUB AC4: Semaglutide shows split-dose option
   - STUB AC5: Liraglutide does NOT show split-dose option
   - STUB AC6: Custom pattern NOT visible in onboarding
   - STUB AC7: Custom pattern NOT visible in schedule edit
2. **Unit Tests (RED)**: Write failing tests for pattern filtering
   - Test: Weekly medication returns [.weekly, .splitDose]
   - Test: Daily medication returns [.weekly] only
3. **Implementation**: Add medication parameter and filtering logic
4. **Unit Tests (GREEN)**: Verify tests pass
5. **Integration Tests**: Not needed (view logic only)
6. **E2E Tests (Implement & GREEN)**: Implement full E2E tests one at a time
   - Test 1: Semaglutide shows split-dose (debug, implement, run, verify)
   - Test 2: Liraglutide hides split-dose (debug, implement, run, verify)
   - Test 3: Custom pattern hidden in onboarding (debug, implement, run, verify)
   - Test 4: Custom pattern hidden in settings (debug, implement, run, verify)

### Stream C: Integration & E2E Validation
**Scope**: Integration testing and comprehensive E2E validation of medical accuracy
**Implementation Files**:
- None (testing stream only)
**Unit/Integration Testing Files**:
- `JabTrackerTests/ScheduleServiceIntegrationTests.swift` (create schedule with split-dose)
**E2E Testing Files**:
- `JabTrackerUITests/OnboardingScheduleSetupUITests.swift` (split-dose flow end-to-end)
- `JabTrackerUITests/DoseScheduleEditUITests.swift` (edit split-dose schedule)
- `JabTrackerUITests/AccessibilityUITests.swift` (VoiceOver "twice weekly" validation)
**Product Area**: fullstack (testing)
**Can Start**: after Streams A & B complete
**Estimated Hours**: 1
**Dependencies**: Stream A (service logic), Stream B (UI changes)

**Outside-In TDD Workflow**:
1. **E2E Acceptance Criteria (Stub)**: Already created in Stream B
2. **Integration Tests (RED)**: Write failing integration tests
   - Test: Create schedule with split-dose pattern creates correct interval
   - Test: Onboarding → split-dose → creates 2 doses per week, 3.5 days apart
3. **Implementation**: Already complete from Streams A & B
4. **Integration Tests (GREEN)**: Verify integration tests pass
5. **E2E Tests (GREEN)**: Run and verify E2E tests from Stream B
   - Verify all 4 E2E tests pass
   - Verify accessibility test passes

## Coordination Points

### Shared Files
**None** - Clean separation between streams:
- Stream A: Service layer files only
- Stream B: UI component files only
- Stream C: Test files only

### Sequential Requirements
1. **Streams A & B run in parallel** (no dependencies)
2. **Stream C starts after A & B complete** (validates integration)

## Conflict Risk Assessment
- **Low Risk**: Zero file overlap between parallel streams
- **Stream A**: Service layer only
- **Stream B**: UI components only
- **Stream C**: Testing only
- **No coordination needed** during parallel execution

## Parallelization Strategy

**Recommended Approach**: Hybrid (A + B parallel, then C)

**Phase 1 - Parallel Execution**:
- Launch Stream A and Stream B simultaneously
- Both streams are fully independent
- No file conflicts possible

**Phase 2 - Integration Validation**:
- Stream C starts after A & B complete
- Validates medical accuracy end-to-end
- Ensures UI changes work correctly with service logic

## Expected Timeline

**With parallel execution**:
- Phase 1 (A + B parallel): 2 hours (max of 2h and 2h)
- Phase 2 (C sequential): 1 hour
- **Total wall time**: 3 hours

**Without parallel execution**:
- Stream A: 2 hours
- Stream B: 2 hours
- Stream C: 1 hour
- **Total wall time**: 5 hours

**Efficiency gain**: 40% reduction (5h → 3h)

## Notes

### Medical Accuracy Priority
This is a **critical patient safety issue**. Split-dose interval of 720 minutes (12 hours) suggests taking weekly medications twice daily, which could lead to overdosing.

**Correct behavior**:
- Weekly medication (Semaglutide 0.25mg): Split into 0.125mg × 2, taken 3.5 days apart (5040 minutes)
- Example: Wednesday 8pm + Sunday 8am = ~84 hours between doses

### Testing Strategy
- **Unit tests**: Validate service logic and UI filtering
- **Integration tests**: Verify schedule creation with split-dose pattern
- **E2E tests**: Confirm medication filtering and medical accuracy in actual UI
- **Accessibility tests**: Ensure VoiceOver announces "twice weekly" correctly

### Backward Compatibility
- Keep `SchedulePatternType.custom` enum case for data compatibility
- Remove from UI only (existing data continues to work)
- No migration required

### Definition of Done
- [ ] Split-dose interval fixed to 5040 minutes (3.5 days)
- [ ] UI descriptions updated to clarify "twice weekly"
- [ ] Medication-specific filtering implemented and tested
- [ ] Custom pattern removed from all UIs
- [ ] All 9 tests passing (Test1-Test9 from acceptance criteria)
- [ ] Medical accuracy validated via E2E tests
- [ ] VoiceOver accessibility verified
