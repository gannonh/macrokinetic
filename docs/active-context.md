## Implementation Plan: Add Time-of-Day Selection to Dose Scheduling

### Design Decisions (Confirmed)
- **Split-Dose**: Two separate time pickers (1st Dose @ 8 AM, 2nd Dose @ 8 PM defaults)
- **Validation**: Enforce 6-18 hours apart for split-dose times
- **Default Time**: 8:00 AM for all patterns
- **Start Date Move**: Move start date selection from "Set Up Your First Dose" to Schedule Setup view
- **Phased Approach**: Onboarding → Manual Test → Settings → All Tests

---

## Phase 1: Onboarding Implementation (This Phase)

### 1.1 Data Layer Enhancement
**File**: `JabTracker/Services/ScheduleService.swift`
- Add `secondTimeOfDay: TimeComponents?` field to `ScheduleConfiguration` struct
- Add validation function: `validateSplitDoseTimes(first:second:) -> Bool` (6-18 hour check)

### 1.2 Move Start Date to Schedule Setup
**File**: `JabTracker/Onboarding/OnboardingViewModel.swift`
- Move `selectedStartDate` from dose entry step to schedule step
- Add `@Published var selectedDayOfWeek: Int = 1` (for weekly pattern)
- Remove start date from dose configuration logic

**File**: Onboarding flow views
- Remove start date picker from "Set Up Your First Dose" view
- Add to Schedule Setup view (integrated with pattern selection)

### 1.3 Add Time Pickers to Schedule Setup
**File**: `JabTracker/Onboarding/Views/ScheduleSetupView.swift`
- Add `@Published var selectedTimeOfDay: Date = Date()` (defaults to 8 AM in ViewModel)
- Add `@Published var selectedSecondTimeOfDay: Date = Date()` (defaults to 8 PM in ViewModel)
- Add single time picker for weekly/daily patterns
- Add TWO time pickers for split-dose pattern ("1st Dose Time", "2nd Dose Time")
- Show validation error if split-dose times violate 6-18 hour rule
- Update concentration preview to use selected time(s)
- Add accessibility identifiers: `"dose-time-picker"`, `"first-dose-time-picker"`, `"second-dose-time-picker"`

### 1.4 Update Schedule Configuration Creation
**File**: `JabTracker/Onboarding/OnboardingViewModel.swift`
- Extract hour/minute from `selectedTimeOfDay` Date
- Create `TimeComponents(hour:minute:)` from selected time
- For split-dose: Create both timeOfDay and secondTimeOfDay
- Pass to ScheduleConfiguration when calling `createInitialSchedule()`

### 1.5 Update Reminder Preferences Display
**File**: `JabTracker/Onboarding/Components/ReminderPreferencesView.swift`
- Add parameter: `timeOfDay: Date`
- Calculate and display actual notification time
- Example: "You'll be reminded at 7:00 AM (1 hour before your 8:00 AM dose)"

---

## Phase 2: Manual Testing (Your Task)
- Test onboarding flow with time selection
- Verify weekly pattern with custom time
- Verify split-dose with two different times
- Verify validation (6-18 hour rule)
- Verify concentration preview uses correct times
- Verify reminders calculate correctly

---

## Phase 3: Settings Implementation (After Manual Test)

### 3.1 Add Time Pickers to Schedule Edit
**File**: `JabTracker/Views/Settings/DoseScheduleEditView.swift`
- Add time picker section (similar to onboarding)
- Load existing timeOfDay from schedule configuration
- Single picker for weekly/daily, two pickers for split-dose
- Save timeOfDay when creating/updating schedules
- Add validation for split-dose time spacing

### 3.2 Update Schedule Service Projection
**File**: `JabTracker/Services/ScheduleService+Projection.swift`
- Update `generateSplitDoses()` to use secondTimeOfDay if present
- Maintain current behavior if secondTimeOfDay is nil (backward compat not needed per user, but good practice)

---

## Phase 4: Test Updates (After Settings)

### 4.1 Unit Tests
- `ScheduleServiceTests.swift`: Test secondTimeOfDay field
- `ScheduleServiceProjectionTests.swift`: Test dose generation at correct times
- `OnboardingViewModelScheduleTests.swift`: Test time selection state
- Add split-dose validation tests

### 4.2 E2E Tests
- `OnboardingScheduleSetupUITests.swift`: Add time picker interaction tests
- `MedicationProfileScheduleUITests.swift`: Add time picker to schedule editing tests

---

## Files Modified in Phase 1 (Onboarding Only)

**Production Code (5-6 files)**:
1. `ScheduleService.swift` - Add secondTimeOfDay field + validation
2. `ScheduleSetupView.swift` - Add time pickers, move start date here
3. `OnboardingViewModel.swift` - Add time state, move start date handling
4. `ReminderPreferencesView.swift` - Show calculated notification time
5. First dose entry view (name TBD) - Remove start date picker
6. `ConcentrationCurvePreview.swift` - Use selected times (if needed)

**Estimated**: 200-300 lines of new code

---

## Acceptance Criteria (Phase 1)

✅ User can select day of week and time together in Schedule Setup view
✅ Weekly pattern shows single time picker (defaults 8 AM)
✅ Split-dose pattern shows TWO time pickers (defaults 8 AM, 8 PM)
✅ Split-dose validation enforces 6-18 hour spacing
✅ Concentration preview reflects selected time(s)
✅ Reminder preference shows calculated notification time
✅ Onboarding creates schedule with correct timeOfDay
✅ Split-dose creates schedule with both times in configuration

---

## Risk Mitigation

**Risk**: Moving start date might break existing onboarding flow
**Mitigation**: Keep date selection in ViewModel, just move UI presentation

**Risk**: Time picker defaults might confuse users
**Mitigation**: Clear labels, helper text, show 12-hour format

**Risk**: Split-dose time validation might be too strict
**Mitigation**: User confirmed 6-18 hours is correct medical range

---

Ready to implement Phase 1 (Onboarding only)?

---

⏺ Perfect! The bug is fixed. Here's what was wrong and what we fixed:

  The Bug

  Root Cause: Instance Isolation
  - OnboardingViewModel was creating a NEW ScheduleService instance
  - NotificationService was using a DIFFERENT ScheduleService instance from AppServices.shared
  - When the schedule was created, it went into the LOCAL instance's activeSchedules array
  - When NotificationService queried for doses, it used the SHARED instance which had ZERO schedules!

  The Fix

  Changed OnboardingViewModel line 411 from:
  // WRONG - creates new instance
  let scheduleService = ScheduleService(context: context)

  To:
  // CORRECT - uses shared instance
  guard let scheduleService = AppServices.shared.scheduleService else {
      print("❌ ERROR: AppServices.scheduleService not initialized!")
      return
  }

  What to Expect in Logs

  When you test again, you should now see:
  1. ✅ Using AppServices.shared.scheduleService
  2. 🔍 [ScheduleService.createSchedule] activeSchedules.count after load: 1 (not 0!)
  3. 🔍 [ScheduleService] activeSchedules.count = 1 when refreshUpcomingDoses() is called
  4. 🔍 [ScheduleService] Generated X doses for this schedule (not 0!)
  5. Scheduled X dose reminders (not 0!)
  6. NOTIFICATION DELIVERED at the correct time! 🎉

  Ready for testing! Please run the onboarding flow again and let me know what you see in the logs.