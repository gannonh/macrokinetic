---
issue: 177
title: Onboarding Integration
analyzed: 2025-10-08T22:41:54Z
estimated_hours: 18
parallelization_factor: 2.5
---

# Parallel Work Analysis: Issue #177

## Overview
Add schedule configuration step to onboarding flow with concentration curve preview, enabling new users to set up dose schedules during first-time setup. This integrates ScheduleService, NotificationService, and PharmacokineticsEngine into the existing onboarding flow.

## Scope Reassessment

**Dependencies Status**: ✅ ALL COMPLETE
- ✅ Issue #174: SwiftData Models (CLOSED)
- ✅ Issue #175: ScheduleService Core (CLOSED)
- ✅ Issue #176: NotificationService (CLOSED)

**Scope Validation**: Issue scope remains valid and well-defined. The onboarding flow exists with a clear structure (OnboardingViewModel + OnboardingView with step-based navigation). Adding a schedule setup step with concentration preview is a natural extension that provides significant user value.

**Strategic Assessment**: This is a critical user adoption feature. New users configuring schedules during onboarding significantly improves initial engagement and adherence. The scope is appropriate and not duplicative of any prior work.

**Recommendation**: ✅ Proceed with implementation as defined.

## Parallel Streams

### Stream A: UI Components & Concentration Preview
**Scope**: Build all SwiftUI view components for schedule setup step
**Implementation Files**:
- `JabTracker/Onboarding/Views/ScheduleSetupView.swift` (main view)
- `JabTracker/Onboarding/Components/SchedulePatternPicker.swift` (pattern selection cards)
- `JabTracker/Onboarding/Components/SchedulePatternCard.swift` (individual pattern card)
- `JabTracker/Onboarding/Components/ConcentrationCurvePreview.swift` (chart preview)
- `JabTracker/Onboarding/Components/ConcentrationLabel.swift` (peak/trough labels)
- `JabTracker/Onboarding/Components/ReminderPreferencesView.swift` (reminder config)

**Unit/Integration Testing Files**:
- `JabTrackerTests/Onboarding/ScheduleSetupViewTests.swift` (component state tests)
- `JabTrackerTests/Onboarding/ConcentrationCurvePreviewTests.swift` (preview calculation tests)

**E2E Testing Files**:
- `JabTrackerUITests/OnboardingScheduleSetupUITests.swift` (E2E acceptance criteria)

**Product Area**: frontend
**Can Start**: immediately
**Estimated Hours**: 8
**Dependencies**: none (can mock ViewModel integration initially)

**Key Implementation Notes**:
- ConcentrationCurvePreview integrates with existing PharmacokineticsEngine
- Pattern selection uses card-based UI with visual feedback
- Reminder preferences use standard SwiftUI pickers and toggles
- Performance requirement: Chart preview must render in <1 second

### Stream B: ViewModel Integration & Business Logic
**Scope**: Extend OnboardingViewModel with schedule configuration logic
**Implementation Files**:
- `JabTracker/Onboarding/OnboardingViewModel.swift` (extend with schedule properties/methods)
- `JabTracker/Onboarding/OnboardingStep.swift` (add .scheduleSetup case)
- `JabTracker/Onboarding/OnboardingView.swift` (add scheduleSetup case to switch)

**Unit/Integration Testing Files**:
- `JabTrackerTests/Onboarding/OnboardingViewModelScheduleTests.swift` (schedule config logic)
- `JabTrackerTests/Onboarding/OnboardingViewModelValidationTests.swift` (validation logic)
- `JabTrackerTests/Onboarding/OnboardingIntegrationTests.swift` (ScheduleService + NotificationService)

**E2E Testing Files**:
- N/A (covered by Stream A E2E tests)

**Product Area**: frontend
**Can Start**: immediately
**Estimated Hours**: 6
**Dependencies**: none (services already exist)

**Key Implementation Notes**:
- Add schedule configuration properties (pattern, reminderMinutes, enableMultipleReminders)
- Implement saveScheduleConfiguration() method
- Implement createInitialSchedule() method (calls ScheduleService + NotificationService)
- Add validation logic for schedule configuration
- Update canProceedToNext computed property
- Migrate from ObservableObject to @Observable pattern (per Issue #51 guidelines)

### Stream C: E2E Test Suite & Accessibility
**Scope**: Comprehensive E2E testing and accessibility validation
**Implementation Files**:
- N/A (testing only)

**Unit/Integration Testing Files**:
- N/A (unit tests handled by Streams A & B)

**E2E Testing Files**:
- `JabTrackerUITests/OnboardingScheduleSetupUITests.swift` (8 acceptance tests)
  - AC4: Complete onboarding with weekly schedule
  - AC5: Complete onboarding with split-dose schedule
  - AC6: Concentration preview updates on pattern change
  - AC7: Schedule creation after onboarding completion
  - AC8: VoiceOver navigation through schedule setup
  - Additional: Continue button disabled state
  - Additional: Reminder preferences configuration
  - Additional: Back navigation preserves schedule state

**Product Area**: frontend
**Can Start**: after Stream A completes (needs UI components)
**Estimated Hours**: 4
**Dependencies**: Stream A (UI components must exist)

**Key Implementation Notes**:
- Follow iterative E2E testing pattern (one test at a time)
- Use TestUtilities.debugElements() for element discovery
- Validate VoiceOver accessibility for all interactive elements
- Performance testing: Chart preview rendering time
- Test notification permission flow integration

## Coordination Points

### Shared Files
**OnboardingViewModel.swift** - Streams A & B:
- Stream A: Adds PharmacokineticsEngine property for preview calculations
- Stream B: Adds schedule configuration properties and methods
- **Coordination**: Stream A should add pkEngine property first, then Stream B adds schedule logic

**OnboardingView.swift** - Streams A & B:
- Stream A: Creates ScheduleSetupView integration point
- Stream B: Adds .scheduleSetup case to step switch statement
- **Coordination**: Stream B adds enum case, Stream A adds view integration

### Sequential Requirements
1. **UI Components before E2E Tests**: Stream A must complete ScheduleSetupView before Stream C can write E2E tests
2. **ViewModel Integration Independent**: Stream B can work in parallel with Stream A using mock data initially
3. **Final Integration**: Both A & B complete, then merge and run Stream C E2E tests

## Conflict Risk Assessment

**Low Risk**: Streams work on different files with minimal overlap
- Stream A: Primarily new view files in JabTracker/Onboarding/Components/
- Stream B: Extensions to existing OnboardingViewModel.swift and OnboardingView.swift
- Stream C: Pure testing, no implementation files

**Coordination Required**:
- OnboardingViewModel.swift: Stream A adds pkEngine, Stream B adds schedule logic
- OnboardingView.swift: Stream B adds enum case, Stream A adds view case

**Mitigation**:
- Stream A commits pkEngine property early
- Stream B coordinates enum addition before Stream A needs it
- Use git feature branches with clear communication

## Parallelization Strategy

**Recommended Approach**: hybrid

**Phase 1** (Parallel): Launch Streams A and B simultaneously
- Stream A: Build all UI components (8 hours)
- Stream B: Extend ViewModel with schedule logic (6 hours)
- **Coordination**: Stream A commits pkEngine property first, Stream B adds enum cases

**Phase 2** (Sequential): Stream C after A completes
- Stream C: E2E testing (4 hours)
- Requires Stream A UI components to exist
- Stream B integration can complete during Stream C

**Wall Time**: ~12 hours (8h Phase 1 parallel + 4h Phase 2)
**Total Work**: 18 hours
**Efficiency Gain**: 33% time savings vs sequential

## Expected Timeline

**With parallel execution**:
- Phase 1: 8 hours (A & B in parallel, max 8h)
- Phase 2: 4 hours (C sequential)
- **Wall time**: 12 hours

**Without parallel execution**:
- Stream A: 8 hours
- Stream B: 6 hours
- Stream C: 4 hours
- **Wall time**: 18 hours

**Efficiency**: 2.5x speedup through parallelization (8+6+4=18 sequential vs 12 parallel)

## Notes

### Technical Considerations
1. **ObservableObject → @Observable Migration**: Stream B should migrate OnboardingViewModel to @Observable pattern per Issue #51 guidelines (iOS 17+ pattern)
2. **PharmacokineticsEngine Integration**: Stream A reuses existing engine for concentration calculations - generate sample doses based on selected pattern
3. **Performance Requirements**:
   - Chart preview render: <1 second (NFR1)
   - Pattern selection update: <200ms (NFR2)
4. **Notification Permission**: Request permission during schedule setup step, handle denial gracefully
5. **Data Persistence**: Schedule configuration saved to ViewModel state, DoseSchedule entity created only after onboarding completion

### Edge Cases
- No medication selected: Prevent schedule setup access if user navigates back
- Custom pattern: Phase 1 shows "Coming Soon", defaults to weekly
- Notification permission denied: Show in-app reminder fallback message
- Onboarding exit mid-setup: Persist schedule configuration in ViewModel

### Testing Strategy
- **Unit Tests**: Component state, validation logic, service integration (Streams A & B)
- **Integration Tests**: ScheduleService + NotificationService coordination (Stream B)
- **E2E Tests**: Full onboarding flows, accessibility validation (Stream C)
- **Performance Tests**: Chart rendering benchmarks (Stream C)

### Accessibility Requirements
- Schedule pattern cards keyboard navigable
- Concentration preview has descriptive accessibility labels
- Reminder pickers announce selected values
- Continue button disabled state announces reason
- Full VoiceOver support validation in Stream C

### Conflict Prevention
- Stream A: Commits pkEngine property addition early (line 21 in OnboardingViewModel.swift)
- Stream B: Adds OnboardingStep.scheduleSetup enum case first (line 219)
- Both streams: Frequent commits with clear messages
- Integration: Final merge after both streams complete with full test suite validation
