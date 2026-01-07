# Onboarding, Goal, Program & Check-in Flows

This document defines all conditional flows for onboarding, goal/program wizards, and weekly check-ins.

---

## 1. Onboarding Flow (New Users)

**File:** `JabTracker/Onboarding/OnboardingViewModel.swift`

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ONBOARDING FLOW                                   │
└─────────────────────────────────────────────────────────────────────────────┘

START
  │
  ▼
┌─────────────┐
│   welcome   │
└─────────────┘
  │
  ▼
┌─────────────┐
│ uspShowcase │
└─────────────┘
  │
  ▼
┌─────────────┐
│  healthKit  │  ─── Enable HealthKit? ──► Populates profile from HealthKit
└─────────────┘                            (height, sex, birthday, weight)
  │
  ▼
┌─────────────┐
│  goalType   │  Weight Loss / Maintain / Muscle Gain
└─────────────┘
  │
  ▼
┌──────────────┐
│ targetWeight │  Current weight, target weight, weekly rate
└──────────────┘
  │
  ▼
┌────────────────────────────────────────┐
│ hasProfileDataFromHealthKit == true ?  │
└────────────────────────────────────────┘
  │                    │
  │ YES                │ NO
  │                    ▼
  │            ┌───────────────────┐
  │            │ profileCompletion │  Height, Sex, Birthday
  │            └───────────────────┘
  │                    │
  ◄────────────────────┘
  │
  ▼
┌──────────────┐
│ programStyle │  Coached / Collaborative / Manual
└──────────────┘
  │
  ├──────────────────────────────────────────────────────────────┐
  │                                                              │
  │ COACHED or COLLABORATIVE                                     │ MANUAL
  │                                                              │
  ▼                                                              ▼
┌────────────────┐                                        (not implemented
│ dietPreference │  Balanced / Low-Carb / High-Protein     in onboarding)
└────────────────┘
  │
  ▼
┌──────────────┐
│ calorieFloor │  Standard / Aggressive / Very Aggressive
└──────────────┘
  │
  ▼
┌───────────────┐
│ activityLevel │  Sedentary / Light / Moderate / Active / Very Active
└───────────────┘
  │
  ├─────────────────────────────────────────────────┐
  │                                                 │
  │ COACHED only                                    │ COLLABORATIVE
  │                                                 │ (skips distribution)
  ▼                                                 │
┌────────────────────┐                              │
│ weeklyDistribution │  Even / Front / Back /       │
└────────────────────┘  Shifted                     │
  │                                                 │
  │                                                 │
  ├───────────────────────────────┐                 │
  │                               │                 │
  │ weeklyDistribution            │ Other           │
  │ == .shifted                   │                 │
  ▼                               │                 │
┌──────────────────────┐          │                 │
│ shiftedDaySelection  │          │                 │
│ (select high cal     │          │                 │
│  days)               │          │                 │
└──────────────────────┘          │                 │
  │                               │                 │
  ◄───────────────────────────────┘                 │
  │                                                 │
  ◄─────────────────────────────────────────────────┘
  │
  ▼
┌──────────────┐
│ proteinLevel │  Moderate / High / Very High
└──────────────┘
  │
  ▼
  │
  │  *** CALCULATING ANIMATION (5 seconds) ***
  │  → calculateTargets() runs
  │
  ▼
┌───────────────────┐
│ setupConfirmation │  Shows weekly macro grid
└───────────────────┘  + "How was your program designed?"
  │                    + Collaborative info card (if Collaborative)
  │
  ▼
┌────────┐
│ faceID │  Enable / Skip
└────────┘
  │
  ▼
┌───────────────┐
│ notifications │  Enable / Skip
└───────────────┘
  │
  ▼
┌────────────┐
│ completion │  "You're All Set!"
└────────────┘
  │
  ▼
END (dismiss onboarding, show main app)
```

### Onboarding Conditionals Summary

| Condition                             | Steps Affected                                   |
| ------------------------------------- | ------------------------------------------------ |
| `hasProfileDataFromHealthKit == true` | Skip `profileCompletion`                         |
| `programStyle == .collaborative`      | Skip `weeklyDistribution`, `shiftedDaySelection` |
| `weeklyDistributionMode == .shifted`  | Show `shiftedDaySelection` (Coached only)        |

---

## 2. New Goal Flow (Strategy)

**File:** `JabTracker/Views/Nutrition/GoalWizard.swift`

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NEW GOAL FLOW                                     │
└─────────────────────────────────────────────────────────────────────────────┘

START (isEditMode = false)
  │
  ▼
┌──────────┐
│ goalType │  Weight Loss / Maintain / Muscle Gain
└──────────┘
  │
  ▼
┌──────────────┐
│ targetWeight │  Current weight, target weight, weekly rate
└──────────────┘  (Maintenance: no target/rate needed)
  │
  ▼
┌─────────┐
│ summary │  Review goal details
└─────────┘
  │
  ▼
[Save Goal] → Creates NutritionGoal entity
  │
  ▼
END (dismiss wizard, launch ProgramWizard)
```

---

## 3. Edit Goal Flow (Strategy)

**File:** `JabTracker/Views/Nutrition/GoalWizard.swift`

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           EDIT GOAL FLOW                                    │
└─────────────────────────────────────────────────────────────────────────────┘

START (isEditMode = true, existingGoal loaded)
  │
  │  ** goalType step is SKIPPED in edit mode **
  │
  ▼
┌──────────────┐
│ targetWeight │  Edit current weight, target weight, weekly rate
└──────────────┘
  │
  ▼
┌─────────┐
│ summary │  Review goal details
└─────────┘
  │
  ▼
[Save Goal] → Updates existing NutritionGoal
  │
  ▼
END (dismiss wizard)
```

### Goal Flow Conditionals Summary

| Condition                  | Steps Affected                                 |
| -------------------------- | ---------------------------------------------- |
| `isEditMode == true`       | Skip `goalType`, start at `targetWeight`       |
| `goalType == .maintenance` | Target weight = current weight, no rate needed |

---

## 4. New Program Flow (Strategy)

**File:** `JabTracker/Views/Nutrition/ProgramWizard.swift`

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NEW PROGRAM FLOW                                  │
└─────────────────────────────────────────────────────────────────────────────┘

START (isEditMode = false)
  │
  ▼
┌──────────────┐
│ programStyle │  Coached / Collaborative / Manual
└──────────────┘
  │
  ├─────────────────────────────────────────────────────────────────────────────┐
  │                                                                             │
  │ COACHED                        COLLABORATIVE                    MANUAL      │
  │                                                                             │
  ▼                                ▼                                ▼           │
┌────────────────────┐       ┌────────────────────┐        ┌────────────┐       │
│ needsProfile?      │       │ needsProfile?      │        │ targetMode │       │
│ → profileCompletion│       │ → profileCompletion│        └────────────┘       │
└────────────────────┘       └────────────────────┘              │              │
  │                                │                              │              │
  ▼                                ▼                              │              │
┌────────────────┐           ┌────────────────┐                   │              │
│ dietPreference │           │ dietPreference │                   │              │
└────────────────┘           └────────────────┘                   │              │
  │                                │                              │              │
  ▼                                ▼                              │              │
┌──────────────┐             ┌──────────────┐                     │              │
│ calorieFloor │             │ calorieFloor │                     │              │
└──────────────┘             └──────────────┘                     │              │
  │                                │                              │              │
  ▼                                ▼                              │              │
┌──────────┐                 ┌──────────┐                         │              │
│ training │                 │ training │                         │              │
└──────────┘                 └──────────┘                         │              │
  │                                │                              │              │
  ▼                                │                              │              │
┌────────────────────┐             │                              │              │
│ weeklyDistribution │             │                              │              │
└────────────────────┘             │                              │              │
  │                                │                              │              │
  │                                │                   ┌──────────┴──────────┐   │
  │                                │                   │                     │   │
  │ Shifted?                       │                   │ useSameTargets      │   │
  │                                │                   │ AllWeek?            │   │
  ▼                                │                   │                     │   │
┌──────────────────────┐           │                   ▼                     ▼   │
│ shiftedDaySelection  │           │           ┌────────────────┐  ┌────────────┐│
│ (if shifted)         │           │           │singleWeekMacros│  │perDayMacros││
└──────────────────────┘           │           └────────────────┘  └────────────┘│
  │                                │                   │                     │   │
  ▼                                │                   └──────────┬──────────┘   │
┌──────────────┐                   │                              │              │
│ proteinLevel │                   │                              │              │
└──────────────┘                   │                              │              │
  │                                │                              │              │
  ▼                                ▼                              ▼              │
┌──────────────┐             ┌──────────────┐              ┌──────────────┐      │
│ proteinLevel │             │ confirmation │              │ confirmation │      │
└──────────────┘             └──────────────┘              └──────────────┘      │
  │                                │                              │              │
  ▼                                │                              │              │
┌──────────────┐                   │                              │              │
│ confirmation │                   │                              │              │
└──────────────┘                   │                              │              │
  │                                │                              │              │
  ◄────────────────────────────────┴──────────────────────────────┘              │
  │                                                                              │
  ▼                                                                              │
[Save Program] → Creates NutritionProgram + calculates TDEE                      │
  │                                                                              │
  ▼                                                                              │
END                                                                              │
```

### Program Style Step Comparison

| Step                | Coached    | Collaborative | Manual               |
| ------------------- | ---------- | ------------- | -------------------- |
| programStyle        | ✓          | ✓             | ✓                    |
| profileCompletion   | if needed  | if needed     | ✗                    |
| dietPreference      | ✓          | ✓             | ✗                    |
| calorieFloor        | ✓          | ✓             | ✗                    |
| training            | ✓          | ✓             | ✗                    |
| weeklyDistribution  | ✓          | ✗             | ✗                    |
| shiftedDaySelection | if shifted | ✗             | ✗                    |
| proteinLevel        | ✓          | ✓             | ✗                    |
| targetMode          | ✗          | ✗             | ✓                    |
| singleWeekMacros    | ✗          | ✗             | if same all week     |
| perDayMacros        | ✗          | ✗             | if different per day |
| confirmation        | ✓          | ✓             | ✓                    |

---

## 5. Edit Program Flow (Strategy)

**File:** `JabTracker/Views/Nutrition/ProgramWizard.swift`

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           EDIT PROGRAM FLOW                                 │
└─────────────────────────────────────────────────────────────────────────────┘

START (isEditMode = true, existingProgram loaded)
  │
  │  ** programStyle step is SKIPPED in edit mode **
  │  (Style is already set, cannot change)
  │
  ▼
  │
  │  Same steps as New Program for the given style,
  │  but starting AFTER programStyle
  │
  ▼
[Save Program] → Updates existing NutritionProgram + recalculates TDEE
  │
  ▼
END
```

### Edit Mode Conditionals

| Condition              | Effect                                                  |
| ---------------------- | ------------------------------------------------------- |
| `isEditMode == true`   | Skip `programStyle`, start at first style-specific step |
| Existing program style | Determines which subsequent steps are shown             |

---

## 6. Weekly Check-in Flow

**File:** `JabTracker/Services/WeeklyCheckInService.swift`

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           WEEKLY CHECK-IN FLOW                              │
└─────────────────────────────────────────────────────────────────────────────┘

TRIGGER: isCheckInDue(for: goal) == true
  │
  │  Conditions:
  │  - Program style != Manual (Manual skips check-ins)
  │  - Current day == goal.checkInDayOfWeek
  │  - Days since last check-in >= 7
  │
  ▼
┌─────────────────────────────────┐
│ generateOptimizationResult()    │
│                                 │
│ Analyzes:                       │
│ - Weight change vs goal pace    │
│ - Calorie intake vs target      │
│ - Data quality (logging days)   │
│ - Adaptive TDEE calculation     │
└─────────────────────────────────┘
  │
  ▼
┌─────────────────────────────────┐
│ ProgramOptimizationSheet        │
│                                 │
│ Shows:                          │
│ - Progress summary              │
│ - TDEE comparison               │
│ - Proposed changes (if any)     │
└─────────────────────────────────┘
  │
  ├─────────────────────────────────────────────────────────┐
  │                                                         │
  │ COACHED                                                 │ COLLABORATIVE
  │                                                         │
  ▼                                                         ▼
┌─────────────────┐                               ┌─────────────────────────┐
│                 │                               │                         │
│  [Accept]       │                               │  [Accept]  [Modify]     │
│  [Decline]      │                               │  [Decline]              │
│                 │                               │                         │
└─────────────────┘                               └─────────────────────────┘
  │        │                                        │     │        │
  │        │                                        │     │        │
  ▼        ▼                                        ▼     ▼        ▼
Accept   Decline                                 Accept  Modify   Decline
  │        │                                        │     │        │
  │        │                                        │     ▼        │
  │        │                                        │  ┌──────────┐│
  │        │                                        │  │Edit in   ││
  │        │                                        │  │Strategy  ││
  │        │                                        │  └──────────┘│
  │        │                                        │              │
  ▼        ▼                                        ▼              ▼
┌──────────────────┐                            ┌──────────────────┐
│ Apply changes    │                            │ No changes       │
│ to program       │                            │ applied          │
└──────────────────┘                            └──────────────────┘
  │                                                │
  ▼                                                ▼
┌──────────────────┐                            ┌──────────────────┐
│ Update           │                            │ Record check-in  │
│ goal.lastCheckIn │                            │ date only        │
└──────────────────┘                            └──────────────────┘
  │                                                │
  ◄────────────────────────────────────────────────┘
  │
  ▼
END
```

### Check-in Conditionals Summary

| Condition                              | Effect                                     |
| -------------------------------------- | ------------------------------------------ |
| `program.style == .manual`             | No check-ins (completely skipped)          |
| `program.style == .coached`            | Accept / Decline buttons only              |
| `program.style == .collaborative`      | Accept / Modify / Decline buttons          |
| `dataQuality.quality == .insufficient` | Lower confidence, different messaging      |
| `!result.hasChanges`                   | No proposed changes, just progress summary |

---

## E2E Test Scenarios

Based on the above flows, the following test scenarios should be covered:

### Onboarding Tests

1. **Full Coached flow with all steps**
   - Skip HealthKit → manual profile → Coached → all preferences → Even distribution

2. **Coached with Shifted distribution**
   - Coached → Shifted → shiftedDaySelection screen → verify day selection

3. **Collaborative flow (shorter)**
   - Collaborative → verify weeklyDistribution skipped → verify info card on confirmation

4. **HealthKit provides profile data**
   - Enable HealthKit (mock) → verify profileCompletion skipped

### Goal Wizard Tests

5. **New Goal - Weight Loss**
   - goalType → targetWeight (target < current) → summary → save

6. **New Goal - Maintenance**
   - goalType (maintain) → targetWeight (no target field) → summary → save

7. **Edit Goal**
   - Open existing goal → verify starts at targetWeight → save changes

### Program Wizard Tests

8. **New Program - Coached with Even**
   - Coached → all steps → Even distribution → no shiftedDaySelection

9. **New Program - Coached with Shifted**
   - Coached → Shifted → shiftedDaySelection → select days → confirm

10. **New Program - Collaborative**
    - Collaborative → verify skips weeklyDistribution → confirm

11. **New Program - Manual (same all week)**
    - Manual → targetMode (same) → singleWeekMacros → confirm

12. **New Program - Manual (different per day)**
    - Manual → targetMode (different) → perDayMacros → confirm

13. **Edit Program**
    - Open existing → verify skips programStyle → edit values → save

### Weekly Check-in Tests

14. **Check-in due - Coached Accept**
    - Trigger check-in → view optimization → Accept → verify changes applied

15. **Check-in due - Coached Decline**
    - Trigger check-in → view optimization → Decline → verify no changes

16. **Check-in due - Collaborative Modify**
    - Trigger check-in → Modify → opens edit sheet

17. **Check-in not due**
    - < 7 days since last → verify no check-in triggered

18. **Manual program - no check-in**
    - Manual program → verify check-in never triggers

---

## File References

| Flow            | Primary Files                                                               |
| --------------- | --------------------------------------------------------------------------- |
| Onboarding      | `OnboardingViewModel.swift`, `OnboardingView.swift`, `OnboardingStep.swift` |
| Goal Wizard     | `GoalWizard.swift`, `GoalWizardStepViews.swift`                             |
| Program Wizard  | `ProgramWizard.swift`, `ProgramWizardStepViews.swift`                       |
| Weekly Check-in | `WeeklyCheckInService.swift`, `ProgramOptimizationSheet.swift`              |

---

*Last updated: 2026-01-07T01:28:13Z*
