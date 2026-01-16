# UAT: Nutrition Calculation Centralization

**Issue**: Maintenance goal bug - weeklyPace set to +0.5 instead of 0, causing 550 kcal surplus
**Fix**: Centralized all nutrition calculations in `NutritionCalculationService`

---

## Pre-Test Setup

1. **Reset app state** or use a fresh user account
2. Have access to the Strategy tab (requires completed onboarding)
3. Know your expected TDEE for comparison (calculator: https://tdeecalculator.net/)

---

## UAT Test Cases

### Flow 1: Onboarding (New User Creation)

#### Test 1.1: Maintenance Goal During Onboarding
- [ ] Start onboarding as new user
- [ ] Complete biometrics step (height, weight, age, sex, activity)
- [ ] On goal selection, choose **Maintenance**
- [ ] Complete remaining onboarding steps
- [ ] **VERIFY**: Daily calorie target shown = estimated TDEE (NOT TDEE + 550)
- [ ] **VERIFY**: In Strategy tab, goal shows "Maintenance" with no deficit/surplus

**Expected TDEE Range**: For 80kg male, 30yo, moderate activity → ~2700-2800 kcal
**Bug Behavior**: Would show ~3250-3350 kcal (TDEE + 550)

#### Test 1.2: Weight Loss Goal During Onboarding
- [ ] Start onboarding as new user
- [ ] Complete biometrics (same as above)
- [ ] On goal selection, choose **Weight Loss**
- [ ] Set rate to 0.5 kg/week
- [ ] Complete remaining steps
- [ ] **VERIFY**: Daily target = TDEE - 550 (approximately 2150-2250 kcal)

#### Test 1.3: Muscle Gain Goal During Onboarding
- [ ] Start onboarding as new user
- [ ] Complete biometrics (same as above)
- [ ] On goal selection, choose **Muscle Gain**
- [ ] Set rate to 0.5 kg/week
- [ ] Complete remaining steps
- [ ] **VERIFY**: Daily target = TDEE + 550 (approximately 3250-3350 kcal)

---

### Flow 2: Strategy Tab - New/Edit Goal (GoalWizard)

#### Test 2.1: Create New Maintenance Goal
- [ ] Go to Strategy tab
- [ ] Tap to create new goal/program
- [ ] Select **Maintenance** goal type
- [ ] Note: Rate selector should be hidden or irrelevant for maintenance
- [ ] Complete wizard
- [ ] **VERIFY**: Weekly pace shown as "Maintenance" (not "+0.5 kg/week")
- [ ] **VERIFY**: Daily target = TDEE

#### Test 2.2: Edit Existing Goal to Maintenance
- [ ] Have an existing weight loss or muscle gain goal
- [ ] Go to Strategy tab → Edit Goal
- [ ] Change goal type to **Maintenance**
- [ ] Save changes
- [ ] **VERIFY**: Weekly pace updated to 0
- [ ] **VERIFY**: Daily target recalculated to equal TDEE

#### Test 2.3: Create Weight Loss Goal via Wizard
- [ ] Go to Strategy tab
- [ ] Create new weight loss goal with 0.5 kg/week rate
- [ ] **VERIFY**: Weekly pace shows "-0.5 kg/week"
- [ ] **VERIFY**: Daily target = TDEE - 550

#### Test 2.4: Create Muscle Gain Goal via Wizard
- [ ] Go to Strategy tab
- [ ] Create new muscle gain goal with 0.5 kg/week rate
- [ ] **VERIFY**: Weekly pace shows "+0.5 kg/week"
- [ ] **VERIFY**: Daily target = TDEE + 550

---

### Flow 3: Weekly Check-In (Strategy Tab)

**Prerequisite**: Have a goal with check-in due (or wait 7 days)

#### Test 3.1: Check-In with Maintenance Goal
- [ ] Have active maintenance goal
- [ ] Trigger weekly check-in (after 7+ days)
- [ ] Review proposed targets
- [ ] **VERIFY**: Proposed daily calories = updated TDEE (no surplus/deficit)
- [ ] Accept changes
- [ ] **VERIFY**: New daily target = new TDEE

#### Test 3.2: Check-In with Weight Loss Goal
- [ ] Have active weight loss goal (-0.5 kg/week)
- [ ] Trigger weekly check-in
- [ ] Review proposed targets
- [ ] **VERIFY**: Proposed daily calories = updated TDEE - 550
- [ ] Accept changes
- [ ] **VERIFY**: Correct adjustment applied

---

## Database/Debug Verification

If you have access to app debugging:

#### Test D.1: Verify weeklyWeightChangePaceKg Value
- [ ] Create maintenance goal
- [ ] Query database or use debug view
- [ ] **VERIFY**: `weeklyWeightChangePaceKg == 0.0` (NOT `+0.5`)

#### Test D.2: Verify Goal Values Match Expected
| Goal Type | weeklyWeightChangePaceKg | Daily Target Formula |
|-----------|--------------------------|---------------------|
| Weight Loss | -0.5 | TDEE - 550 |
| Maintenance | **0.0** | **TDEE** |
| Muscle Gain | +0.5 | TDEE + 550 |

---

## Edge Cases

#### Test E.1: Extreme Rate Selection
- [ ] Create weight loss goal with maximum rate (1.0 kg/week)
- [ ] **VERIFY**: Daily target = TDEE - 1100
- [ ] Calorie floor should be enforced (minimum ~1200)

#### Test E.2: Rate Selection Doesn't Affect Maintenance
- [ ] If UI allows selecting rate for maintenance goal
- [ ] Select any rate (0.25, 0.5, 1.0 kg/week)
- [ ] **VERIFY**: Maintenance always results in weeklyPace = 0

#### Test E.3: Goal Type Switch
- [ ] Create weight loss goal
- [ ] Edit and switch to maintenance
- [ ] Edit and switch to muscle gain
- [ ] **VERIFY**: Each switch correctly recalculates pace

---

## Regression Tests (Run After All Fixes)

### Run Automated Tests
```bash
# NutritionCalculationService unit tests
./scripts/test.sh unit 1 NutritionCalculationServiceTests

# GoalWizard ViewModel tests
./scripts/test.sh unit 1 GoalWizardViewModelTests

# Onboarding maintenance tests
./scripts/test.sh unit 1 OnboardingMaintenanceGoalTests

# All unit tests
./scripts/test.sh unit 1
```

### Key Test Assertions
- [ ] `testMaintenancePace()` - Returns 0.0
- [ ] `testWeightLossPace()` - Returns negative value
- [ ] `testMuscleGainPace()` - Returns positive value
- [ ] `testSaveMaintenancePace()` - GoalWizard.save() sets 0.0
- [ ] `testMaintenanceGoalEstimateUsesZeroPace()` - Onboarding integration

---

## Sign-Off

| Tester | Date | All Tests Passed | Notes |
|--------|------|------------------|-------|
| | | [ ] Yes [ ] No | |

---

## Technical Details

### Files Modified
1. `JabTracker/Services/NutritionCalculationService.swift` - NEW (centralized service)
2. `JabTracker/Views/Nutrition/GoalWizard.swift` - Uses service for weeklyPace
3. `JabTracker/Onboarding/OnboardingViewModel.swift` - Uses service for weeklyPace + dailyCalorieTarget
4. `JabTracker/Services/TDEEService.swift` - Uses service for dailyCalorieAdjustment
5. `JabTracker/Services/WeeklyCheckInService.swift` - Uses service for calorie target + macros
6. `JabTracker/Onboarding/Views/SetupConfirmationStepView.swift` - Uses service for display
7. `JabTracker/ViewModels/WeightTrendDetailViewModel.swift` - Uses service for display

### Key Formula
```swift
// THE FIX - maintenance always returns 0
func weeklyPace(for goalType: GoalType, weeklyRateKg: Double) -> Double {
    switch goalType {
    case .weightLoss: return -abs(weeklyRateKg)
    case .maintenance: return 0.0  // ← Always zero!
    case .muscleGain: return abs(weeklyRateKg)
    }
}
```

### Constants (Single Source of Truth)
- `caloriesPerKgBodyFat = 7700`
- `dailyCaloriesPerKgWeeklyChange = 1100` (7700/7)
