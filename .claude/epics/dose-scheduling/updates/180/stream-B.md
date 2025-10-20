---
stream: B
issue: 180
title: UI Pattern Filtering & Description Updates
status: blocked
started: 2025-10-20T18:00:00Z
updated: 2025-10-20T18:40:00Z
blocker: Stream A syntax errors in ScheduleServiceTests.swift and ScheduleServiceProjectionTests.swift
---

# Stream B: UI Pattern Filtering & Description Updates

## Scope
- Add medication-specific pattern filtering to UI components
- Update split-dose UI descriptions (remove "morning and evening")
- Remove custom pattern option from all UIs

## Files Assigned
**Implementation**:
- `JabTracker/Onboarding/Components/SchedulePatternPicker.swift`
- `JabTracker/Onboarding/Components/SchedulePatternCard.swift`
- `JabTracker/Views/Settings/DoseScheduleEditView.swift`

**Tests**:
- `JabTrackerTests/SchedulePatternFilteringTests.swift` (NEW)
- `JabTrackerUITests/OnboardingScheduleSetupUITests.swift`
- `JabTrackerUITests/MedicationProfileScheduleUITests.swift`

## TDD Progress

### Step 1: Stub E2E Acceptance Tests ✅
- [x] Stub AC4: Semaglutide shows split-dose option
- [x] Stub AC5: Liraglutide does NOT show split-dose option
- [x] Stub AC6: Custom pattern NOT visible in onboarding
- [x] Stub AC7: Custom pattern NOT visible in settings edit view

**Commit**: 1e074e8 - "Test stubs: Add E2E and unit test stubs for medication-specific pattern filtering (Issue #180, Stream B)"

### Step 2: Unit Tests (RED) ⏸️ BLOCKED
- [x] Created `SchedulePatternFilteringTests.swift` with 5 comprehensive tests
- [ ] ~~Run tests to verify RED state~~ - BLOCKED by Stream A syntax errors

**Blocker Details**:
Stream A added tests OUTSIDE the struct closing brace in:
- `JabTrackerTests/ScheduleServiceTests.swift` (line 474 closes struct, tests added after line 474)
- `JabTrackerTests/ScheduleServiceProjectionTests.swift` (line 621 closes struct, tests added after line 621)

This prevents compilation of ALL tests in the project.

**Error**:
```
❌ /Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/ScheduleServiceTests.swift:537:1: extraneous '}' at top level
❌ /Users/gannonhall/dev/jab-tracker-ios/JabTrackerTests/ScheduleServiceProjectionTests.swift:734:1: extraneous '}' at top level
```

### Step 3: Implementation (GREEN) 🟢
- [ ] SchedulePatternPicker: Add medication filtering
- [ ] SchedulePatternCard: Update split-dose description
- [ ] DoseScheduleEditView: Add filtering, update description

### Step 4: Unit Tests Pass ✅
- [ ] Run: `./scripts/test.sh unit 2 SchedulePatternFilteringTests`

### Step 5: E2E Tests One-at-a-Time ✅
- [ ] Test 1: Semaglutide shows split-dose (debug → implement → run → verify → commit)
- [ ] Test 2: Liraglutide hides split-dose (debug → implement → run → verify → commit)
- [ ] Test 3: Custom hidden in onboarding (debug → implement → run → verify → commit)
- [ ] Test 4: Custom hidden in settings (debug → implement → run → verify → commit)

## Session Notes

### Session 1: 2025-10-20T18:00:00Z - 18:40:00Z
**Goal**: Complete Steps 1 & 2 (Stub E2E tests + Unit tests RED)

✅ **Step 1 Complete** (18:15:00Z):
- Added 3 stub E2E tests to `OnboardingScheduleSetupUITests.swift`
- Added 1 stub E2E test to `MedicationProfileScheduleUITests.swift`
- All stubs follow GIVEN/WHEN/THEN structure

✅ **Step 2 Tests Created** (18:30:00Z):
- Created `SchedulePatternFilteringTests.swift` with 5 unit tests:
  1. `testSemaglutidePatterns()` - Weekly medication returns [.weekly, .splitDose]
  2. `testTirzepatidePatterns()` - Weekly medication returns [.weekly, .splitDose]
  3. `testDulaglutidePatterns()` - Weekly medication returns [.weekly, .splitDose]
  4. `testLiraglutidePatterns()` - Daily medication returns [.weekly] only
  5. `testNoCustomPattern()` - No medication returns .custom pattern
- Includes helper function `availablePatterns(for:)` that will be implemented in SchedulePatternPicker

⏸️ **BLOCKED** (18:40:00Z):
- Cannot verify RED state due to Stream A compilation errors
- Stream A added test methods outside their struct closing braces
- Needs coordination with Stream A to fix syntax errors

**Next Steps**:
1. **Coordinate with Stream A** to fix syntax errors in their test files
2. Once fixed, verify unit tests fail (RED)
3. Proceed to Step 3 (Implementation)

## Coordination Notes

**To Stream A**: Your test files have syntax errors:
- `ScheduleServiceTests.swift`: Line 474 closes the struct, but tests were added after it
- `ScheduleServiceProjectionTests.swift`: Line 621 closes the struct, but tests were added after it

Please move the test methods INSIDE the struct (before the closing brace).

## Acceptance Criteria Tracking
- [ ] AC2: Split-dose UI descriptions updated
- [ ] AC3: Split-dose option only visible for weekly medications
- [ ] AC4: Split-dose option NOT visible for daily medications
- [ ] AC5: Custom pattern option removed from all UIs
- [ ] AC6: Interval display shows "3.5 days" or "Twice weekly"
- [x] Test2: Unit test for medication frequency filtering (CREATED, awaiting RED verification)
- [x] Test4: E2E test: Semaglutide shows split-dose option (STUB)
- [x] Test5: E2E test: Liraglutide does NOT show split-dose option (STUB)
- [x] Test6: E2E test: Custom pattern NOT visible in onboarding (STUB)
- [x] Test7: E2E test: Custom pattern NOT visible in schedule edit view (STUB)

## Files Modified
- `JabTrackerUITests/OnboardingScheduleSetupUITests.swift` - Added 3 stub E2E tests
- `JabTrackerUITests/MedicationProfileScheduleUITests.swift` - Added 1 stub E2E test
- `JabTrackerTests/SchedulePatternFilteringTests.swift` - NEW: 5 unit tests for pattern filtering

## Commits
1. **1e074e8**: "Test stubs: Add E2E and unit test stubs for medication-specific pattern filtering (Issue #180, Stream B)"
