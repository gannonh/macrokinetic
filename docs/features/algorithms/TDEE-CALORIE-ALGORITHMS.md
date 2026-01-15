# TDEE & Calorie Algorithms

**Last Updated:** 2026-01-15T00:00:00Z (Day Status rules for fasting days)
**Source Files:**
- `JabTracker/Models/BiologicalSex.swift`
- `JabTracker/Models/DayStatus.swift`
- `JabTracker/Services/DayStatusService.swift`
- `JabTracker/Services/TDEECalculationEngine.swift`
- `JabTracker/Services/TDEECalculationEngine+Adaptive.swift`
- `JabTracker/Services/TDEECalculationEngine+EWMA.swift`
- `JabTracker/Services/TDEECalculationEngine+Validation.swift`
- `JabTracker/Services/TDEEService.swift`
- `JabTracker/Services/WeeklyCheckInService.swift`
- `JabTracker/Services/CalorieAdjustmentService.swift`
- `JabTracker/Services/CalorieAdjustmentService+Adjustments.swift`
- `JabTracker/Services/MealLogService.swift`

---

## Table of Contents

1. [Overview](#overview)
2. [Day Status Rules](#day-status-rules)
3. [Initial TDEE Estimation](#initial-tdee-estimation)
4. [Adaptive TDEE Calculation](#adaptive-tdee-calculation)
5. [Weight Smoothing (EWMA)](#weight-smoothing-ewma)
6. [Confidence Scoring](#confidence-scoring)
7. [Calorie Target Derivation](#calorie-target-derivation)
8. [Calorie Expenditure Adjustments](#calorie-expenditure-adjustments)
9. [Macro Calculations](#macro-calculations)
10. [Thresholds & Configuration](#thresholds--configuration)
11. [Weekly Check-In Logic](#weekly-check-in-logic)
12. [Data Requirements Summary](#data-requirements-summary)

---

## Overview

The app uses a two-phase TDEE (Total Daily Energy Expenditure) calculation:

1. **Initial Estimate**: Formula-based estimate using Mifflin-St Jeor + activity multiplier
2. **Adaptive Refinement**: Data-driven refinement using actual weight changes and food intake

This allows the app to provide immediate targets during onboarding, then progressively improve accuracy as user data accumulates.

---

## Day Status Rules

The app uses day status tracking to differentiate between intentional fasting and missing data. This ensures accurate calculations across all multi-day aggregations.

### Day Classification

| Day Condition | Classification | Treatment in Calculations |
| --- | --- | --- |
| Has food entries | **Data Day** | Included with logged calories |
| No entries + Fasting flag ON | **Fasting Day** | Included as 0-calorie day |
| No entries + Fasting flag OFF | **Unknown Day** | Skipped entirely |
| Today (any status) | **Partial Day** | Excluded from aggregations |

### Why This Matters

Without day status rules, the algorithm cannot distinguish between:
- "I intentionally ate nothing" (should count as 0)
- "I forgot to log" (should be skipped)

**Example without day status:**
- 7-day window: 6 days with 2000 kcal, 1 day with 0 kcal (fasting)
- Total: 12,000 kcal / 7 days = 1,714 kcal/day average

**Example with day status (fasting marked):**
- Same data, but user marked day 7 as fasting
- Total: 12,000 kcal / 6 non-fasting days = 2,000 kcal/day average
- The fasting day is counted as intentional 0 but excluded from calorie averaging

### Affected Calculations

Day status rules apply to:

1. **TDEE Calculation** (`TDEEService.calculateAdaptiveTDEE`)
   - Fasting days excluded from average intake calculation
   - Food consistency adjusted for fasting days

2. **Energy Balance Charts** (`EnergyBalanceHeroViewModel`, `EnergyBalanceWidgetViewModel`)
   - Only shows days with meaningful data
   - Today excluded (partial data)

3. **Weekly Nutrition Tracking** (`WeeklyNutritionHeroViewModel`)
   - Fasting days show 0 calories (intentional)
   - Unknown days show 0 but don't affect averages

### User Interface

Users can mark a day as fasting in the Food Log:

1. Navigate to the day with no food entries
2. A "Fasting Day" toggle appears
3. Toggle ON to mark as intentional fasting

The toggle only appears when there are no food entries for that day.

### Data Model

```swift
// DayStatus.swift
@Model
final class DayStatus {
    var id: UUID
    var date: Date        // Normalized to start of day
    var isFasting: Bool   // true = intentional fast
    var createdAt: Date
    var updatedAt: Date
}
```

### Service Methods

```swift
// DayStatusService.swift
func setFasting(for date: Date, isFasting: Bool)
func isFasting(for date: Date) -> Bool
func getFastingDates(from: Date, to: Date) -> Set<Date>

// MealLogService.swift
func getDatesWithMeaningfulData(from: Date, to: Date, dayStatusService: DayStatusService?) -> Set<Date>
```

---

## Initial TDEE Estimation

### Mifflin-St Jeor Formula (BMR)

The Basal Metabolic Rate (BMR) is calculated using the Mifflin-St Jeor equation, which is considered the most accurate formula for healthy adults.

**Formula:**

```
BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + adjustment
```

**BiologicalSex Adjustments:**

The `BiologicalSex` enum (matching HealthKit's `HKBiologicalSex`) provides type-safe sex handling:

| BiologicalSex | Raw Value | Adjustment | Calculation Allowed |
| ------------- | --------- | ---------- | ------------------- |
| `.female`     | "female"  | -161       | Yes                 |
| `.male`       | "male"    | +5         | Yes                 |
| `.other`      | "other"   | -78 (avg)  | Yes                 |
| `.notSet`     | ""        | N/A        | **No** (blocked)    |

**Type-Safe API:** New overloads accepting `BiologicalSex` throw `ValidationError.sexNotSet` when sex is `.notSet`, enforcing profile completion before TDEE calculations.

**Legacy API:** String-based methods still accept any value and use the average adjustment (-78) for unrecognized values, maintaining backward compatibility.

**Example:**
```
Male, 85kg, 175cm, 30 years old:
BMR = (10 × 85) + (6.25 × 175) - (5 × 30) + 5
BMR = 850 + 1093.75 - 150 + 5
BMR = 1798.75 kcal/day
```

### Activity Multipliers

BMR is multiplied by an activity factor to get TDEE:

```
TDEE = BMR × Activity_Multiplier
```

| Training Level   | Multiplier | Description                             |
| ---------------- | ---------- | --------------------------------------- |
| None             | 1.2        | Sedentary - desk job, no exercise       |
| Lifting          | 1.55       | Moderately active - resistance training |
| Cardio           | 1.55       | Moderately active - aerobic exercise    |
| Cardio & Lifting | 1.725      | Very active - combined training         |

**Valid multiplier range:** 1.0 - 2.5 (values outside this are clamped)

**Example:**
```
BMR = 1798.75 kcal
Training = Lifting (1.55)
TDEE = 1798.75 × 1.55 = 2788 kcal/day
```

### Input Validation Ranges

| Parameter | Valid Range | Unit  | Error if Invalid |
| --------- | ----------- | ----- | ---------------- |
| Weight    | 20 - 500    | kg    | `invalidWeight`  |
| Height    | 100 - 250   | cm    | `invalidHeight`  |
| Age       | 10 - 120    | years | `invalidAge`     |
| Sex       | Not `.notSet` | enum | `sexNotSet`     |

**Note:** The `sexNotSet` validation only applies to type-safe `BiologicalSex` overloads. Legacy string-based methods accept any value.

---

## Adaptive TDEE Calculation

Once sufficient data exists, the app calculates a more accurate TDEE based on the energy balance equation.

### Energy Balance Equation

The fundamental principle: weight change reflects the difference between calories consumed and calories burned.

**Formula:**

```
TDEE = Average_Daily_Intake - (Weight_Change_kg × 7700 / Days)
```

Where:
- **7700 kcal/kg** = Energy density of body weight change (fat + water + lean mass)
- Negative weight change (loss) → TDEE > intake
- Positive weight change (gain) → TDEE < intake
- Zero weight change → TDEE = intake

**Example (Weight Loss):**
```
Average daily intake: 2000 kcal
Weight change over 28 days: -2 kg
Daily calorie change = (-2 × 7700) / 28 = -550 kcal/day

TDEE = 2000 - (-550) = 2550 kcal/day
```
This means the user was in a 550 kcal/day deficit, burning 2550 but eating 2000.

**Example (Weight Gain):**
```
Average daily intake: 2800 kcal
Weight change over 28 days: +1 kg
Daily calorie change = (1 × 7700) / 28 = +275 kcal/day

TDEE = 2800 - 275 = 2525 kcal/day
```
This means the user was in a 275 kcal/day surplus.

### Reasonable TDEE Bounds

Calculated TDEE is checked against reasonable bounds: **800 - 6000 kcal/day**

Values outside this range trigger a warning log but are still returned (not clamped).

---

## Weight Smoothing (EWMA)

Daily weight fluctuates due to water retention, sodium, and other factors. Exponentially Weighted Moving Average (EWMA) smooths these fluctuations to reveal the true trend.

### EWMA Formula

```
EWMA_t = α × weight_t + (1 - α) × EWMA_{t-1}
```

Where:
- **α (alpha)** = Smoothing factor (0.01 - 1.0)
- Higher α = more responsive to recent changes
- Lower α = smoother, less volatile

**Default α = 0.2** (balance between responsiveness and smoothness)

### Weight Change Rate

Calculated from smoothed weights:

```
Rate (kg/week) = (Last_Smoothed - First_Smoothed) / Days × 7
```

**Minimum data requirements:**
- At least 2 weight entries
- At least 7 days span

### Plateau Detection

A weight plateau is detected when:
```
|change_rate| < 0.1 kg/week
```

---

## Confidence Scoring

The adaptive TDEE calculation includes a confidence score (0-1) to indicate reliability.

### Confidence Formula

```
Confidence = (Duration_Factor × 0.3) + (Consistency_Factor × 0.5) + (Trend_Clarity_Factor × 0.2)
```

**Components:**

| Factor        | Weight | Calculation                 | Max at      |
| ------------- | ------ | --------------------------- | ----------- |
| Duration      | 30%    | days / 28                   | 28 days     |
| Consistency   | 50%    | days_with_food / total_days | 100%        |
| Trend Clarity | 20%    | \|rate\| / 0.5              | 0.5 kg/week |

**Examples:**

```
14 days, 70% consistency, 0.3 kg/week loss:
Duration = 14/28 = 0.5
Consistency = 0.7
Trend = 0.3/0.5 = 0.6

Confidence = (0.5 × 0.3) + (0.7 × 0.5) + (0.6 × 0.2) = 0.15 + 0.35 + 0.12 = 0.62
```

```
28 days, 85% consistency, 0.5 kg/week loss:
Duration = 28/28 = 1.0
Consistency = 0.85
Trend = 0.5/0.5 = 1.0

Confidence = (1.0 × 0.3) + (0.85 × 0.5) + (1.0 × 0.2) = 0.30 + 0.425 + 0.20 = 0.925
```

### High Confidence Threshold

**≥ 0.7** = High confidence (changes can be recommended)

---

## Calorie Target Derivation

Once TDEE is known, daily calorie target is derived based on the user's weight change pace.

### Calorie Adjustment Formula

```
Daily_Calorie_Target = TDEE + (Weekly_Pace_kg × 1100)
```

Where:
- **1100** = 7700 kcal/kg ÷ 7 days
- Weekly pace is negative for weight loss, positive for gain

**Example (Weight Loss):**
```
TDEE = 2500 kcal
Goal = -0.5 kg/week

Target = 2500 + (-0.5 × 1100) = 2500 - 550 = 1950 kcal/day
```

**Example (Muscle Gain):**
```
TDEE = 2500 kcal
Goal = +0.25 kg/week

Target = 2500 + (0.25 × 1100) = 2500 + 275 = 2775 kcal/day
```

### Calorie Floor (Safety Minimum)

Calorie target is never set below the safety floor:

| Floor Type | Minimum   | Use Case                 |
| ---------- | --------- | ------------------------ |
| Standard   | 1538 kcal | Recommended default      |
| Low        | 1025 kcal | With medical supervision |

```
Final_Target = max(Calculated_Target, Calorie_Floor)
```

---

## Calorie Expenditure Adjustments

The app provides three optional adjustments that modify the daily calorie target based on activity and eating patterns. These are configured in **More > Calorie Expenditure**.

### Adjustment Types

| Adjustment | Source | Description |
|------------|--------|-------------|
| **Burned Calories** | HealthKit (today) | Adds today's active energy burned to target |
| **Predictive Activity** | HealthKit (7-day avg) | Adds historical activity average to target |
| **Rollover Calories** | Food Log (yesterday) | Adds unused calories from yesterday (max 200) |

### Adjusted Target Formula

```
Adjusted_Target = Base_Target + Burned + Predictive + Rollover
```

Where each adjustment is 0 if disabled.

---

### Burned Calories (Add Burned Calories)

Adds today's cumulative active energy from HealthKit to the daily calorie target.

**Requirements:**
- Health Sync enabled
- HealthKit active energy permission granted

**Formula:**
```
Burned_Adjustment = Today_Active_Energy_kcal
```

**Example:**
```
Base target: 2000 kcal
Today's active energy: 350 kcal
Adjusted target: 2000 + 350 = 2350 kcal
```

**Source:** `MetricsService.getTodayActiveEnergy()` via HealthKit

---

### Predictive Activity Adjustment

Adds a goal-adjusted 7-day average of activity to the daily calorie target. Uses historical data (not including today) to predict expected activity.

**Requirements:**
- Health Sync enabled
- HealthKit active energy permission granted
- At least 1 day of activity history in the past 7 days
- **Burned Calories must be OFF** (mutually exclusive)

**Formula:**
```
Seven_Day_Average = Sum(Past_7_Days_Active_Energy) / Days_With_Data
Predictive_Adjustment = Seven_Day_Average × Goal_Multiplier
```

**Goal-Type Multipliers:**

| Goal Type | Multiplier | Rationale |
|-----------|------------|-----------|
| Weight Loss | 0.8 (80%) | Conservative - maintain deficit |
| Maintenance | 1.0 (100%) | Neutral - replace what you burn |
| Muscle Gain | 1.2 (120%) | Aggressive - support muscle growth |

**Example (Weight Loss Goal):**
```
7-day average activity: 400 kcal
Goal type: Weight Loss (0.8 multiplier)
Predictive adjustment: 400 × 0.8 = 320 kcal

Base target: 2000 kcal
Adjusted target: 2000 + 320 = 2320 kcal
```

**Example (Muscle Gain Goal):**
```
7-day average activity: 400 kcal
Goal type: Muscle Gain (1.2 multiplier)
Predictive adjustment: 400 × 1.2 = 480 kcal

Base target: 2800 kcal
Adjusted target: 2800 + 480 = 3280 kcal
```

**Source:** `PredictiveActivityProvider` in `CalorieAdjustmentService+Adjustments.swift`

---

### Rollover Calories

Adds unused calories from yesterday to today's target, up to a maximum of 200 kcal.

**Requirements:**
- Food entries logged for yesterday

**Formula:**
```
Yesterday_Unused = Yesterday_Base_Target - Yesterday_Consumed
Rollover_Adjustment = min(max(Yesterday_Unused, 0), 200)
```

**Notes:**
- Only positive unused calories roll over (no penalty for overeating)
- Capped at 200 kcal to prevent large swings
- Uses base target (not adjusted) to prevent compounding

**Example:**
```
Yesterday's base target: 2000 kcal
Yesterday's consumed: 1850 kcal
Yesterday's unused: 2000 - 1850 = 150 kcal

Rollover adjustment: min(max(150, 0), 200) = 150 kcal
Today's adjusted target: 2000 + 150 = 2150 kcal
```

**Example (Overeating - No Rollover):**
```
Yesterday's base target: 2000 kcal
Yesterday's consumed: 2200 kcal
Yesterday's unused: 2000 - 2200 = -200 kcal

Rollover adjustment: min(max(-200, 0), 200) = 0 kcal
```

**Source:** `RolloverCalorieProvider` in `CalorieAdjustmentService+Adjustments.swift`

---

### Mutual Exclusivity: Burned vs Predictive

**Burned Calories and Predictive Activity cannot be enabled simultaneously.**

| If You Enable... | Then... | Reason |
|------------------|---------|--------|
| Burned Calories | Predictive turns OFF | Avoids double-counting today's activity |
| Predictive Activity | Burned turns OFF | Avoids double-counting today's activity |

**Why?**
- Burned adds today's actual active energy
- Predictive uses a 7-day average which may include today's data
- Enabling both would over-credit activity calories

**UI Behavior:**
- Toggling one ON automatically toggles the other OFF
- Footer text explains: "Cannot be used with [other option]"

**Source:** `CalorieExpenditureView.swift` custom bindings

---

### Adjustment Display (CalorieAdjustmentBreakdownView)

When adjustments are active, a breakdown card appears in the Food Log showing:

| Component | Color | Description |
|-----------|-------|-------------|
| Burned | Orange | Today's HealthKit active energy |
| Rollover | Blue | Yesterday's unused calories |
| Predictive | Purple | 7-day activity average (goal-adjusted) |
| Total | Green | Sum of all adjustments |

**Display Conditions:**
- Only shown for today's date
- Only shown when total adjustments > 0
- Hidden when all adjustments are 0 or disabled

**Source:** `CalorieAdjustmentBreakdownView.swift`

---

### Test Seeding for Calorie Expenditure

| Flag | Description |
|------|-------------|
| `--seed-calorie-user` | Creates user with Health Sync enabled, 2000 kcal goal |
| `--mock-active-energy=350` | Mocks HealthKit to return 350 kcal burned |

**Example project.yml configuration:**
```yaml
run:
  commandLineArguments:
    "--reset-app-data": true
    "--ui-testing": true
    "--seed-calorie-user": true
    "--mock-active-energy=350": true
```

---

## Macro Calculations

Macros are calculated based on the calorie target, protein level, and diet preference.

### Protein Calculation

Protein is calculated based on body weight:

```
Protein (g) = Weight_kg × Grams_per_kg
```

| Protein Level | g/kg | Description        |
| ------------- | ---- | ------------------ |
| Low           | 1.2  | Minimal activity   |
| Moderate      | 1.6  | Regular activity   |
| High          | 2.0  | Strength training  |
| Extra High    | 2.4  | Intensive training |

### Fat & Carb Distribution

After protein calories are set, remaining calories are split according to diet preference:

```
Protein_Calories = Protein_g × 4
Remaining_Calories = Total_Calories - Protein_Calories

Fat_Calories = Remaining × (Fat% / (Fat% + Carb%))
Carb_Calories = Remaining × (Carb% / (Fat% + Carb%))

Fat_g = Fat_Calories / 9
Carb_g = Carb_Calories / 4
```

### Diet Preference Percentages

| Diet     | Protein | Carbs | Fat |
| -------- | ------- | ----- | --- |
| Balanced | 30%     | 40%   | 30% |
| Low Fat  | 30%     | 50%   | 20% |
| Low Carb | 30%     | 20%   | 50% |
| Keto     | 25%     | 5%    | 70% |

**Note:** Protein percentage in diet preference is used only for ratio calculation. Actual protein is determined by ProteinLevel × body weight.

### Example Calculation

```
Target: 2000 kcal
Weight: 80 kg
Protein Level: Moderate (1.6 g/kg)
Diet: Balanced

Step 1: Protein
Protein = 80 × 1.6 = 128g (512 kcal)

Step 2: Remaining calories
Remaining = 2000 - 512 = 1488 kcal

Step 3: Fat & Carbs (Balanced = 30% fat, 40% carbs → ratio 30:40 = 3:4)
Fat ratio = 30 / (30 + 40) = 0.429
Carb ratio = 40 / (30 + 40) = 0.571

Fat calories = 1488 × 0.429 = 638 kcal → 638/9 = 71g
Carb calories = 1488 × 0.571 = 850 kcal → 850/4 = 212g

Final Macros:
- Protein: 128g
- Fat: 71g
- Carbs: 212g
- Total: 2000 kcal
```

---

## Thresholds & Configuration

### TDEEService Configuration

| Parameter                        | Default   | Description                         |
| -------------------------------- | --------- | ----------------------------------- |
| `ewmaAlpha`                      | 0.2       | EWMA smoothing factor               |
| `absoluteMinimumWeightEntries`   | 3         | Hard minimum to attempt calculation |
| `absoluteMinimumFoodConsistency` | 0.5 (50%) | Hard minimum food logging           |
| `optimalWeightEntries`           | 14        | Optimal for high confidence         |
| `optimalFoodConsistency`         | 0.7 (70%) | Optimal food logging                |
| `lookbackDays`                   | 28        | Analysis window                     |

### WeeklyCheckInService Configuration

| Parameter                   | Value | Description                            |
| --------------------------- | ----- | -------------------------------------- |
| `checkInIntervalDays`       | 7     | Days between check-ins                 |
| `onTrackToleranceKgPerWeek` | 0.1   | Tolerance for "on track" determination |

### On-Track Detection

User is considered "on track" when:
```
|Actual_Weekly_Rate - Goal_Weekly_Rate| ≤ 0.1 kg/week
```

---

## Data Quality Tiers (Progressive Accuracy)

The system uses tiered data quality levels instead of hard pass/fail thresholds. This allows check-ins to work with limited data while communicating accuracy to users.

### Data Quality Levels

| Level            | Weight Entries | Food Consistency | Time Span | Confidence Range |
| ---------------- | -------------- | ---------------- | --------- | ---------------- |
| **Insufficient** | < 3            | < 50%            | < 7 days  | N/A (blocked)    |
| **Minimum**      | 3-6            | 50-59%           | 7+ days   | 0.3 - 0.5        |
| **Good**         | 7-13           | 60-74%           | 7+ days   | 0.5 - 0.7        |
| **Excellent**    | 14+            | 75%+             | 14+ days  | 0.7 - 1.0        |

### Tier Behavior

| Level            | Check-In Available | Recommendations                 | UI Indicator                              |
| ---------------- | ------------------ | ------------------------------- | ----------------------------------------- |
| **Insufficient** | No                 | None                            | "Keep tracking" message with requirements |
| **Minimum**      | Yes                | With strong caveats             | Yellow/caution indicator                  |
| **Good**         | Yes                | Standard recommendations        | Blue/normal indicator                     |
| **Excellent**    | Yes                | High confidence recommendations | Green/confident indicator                 |

### How Food Consistency Is Calculated

**Important:** Food consistency is calculated as percentage of the *actual data span*, NOT the full lookback window:

```
foodConsistency = uniqueDaysWithFood / daySpan
```

Where:
- `uniqueDaysWithFood`: Number of distinct days with at least one food entry
- `daySpan`: Number of days between first and last weight entry

**Example:**
- User has 10 weight entries spanning 10 days (daySpan = 10)
- User logged food on 7 of those 10 days
- Food consistency = 7/10 = 70% → GOOD tier

This ensures users with shorter tracking periods are fairly assessed based on their actual behavior, not penalized for having a shorter history.

### Improvement Tips by Tier

Each tier shows specific guidance on how to improve accuracy:

**Insufficient → Minimum:**
- "Log your weight at least 3 times this week"
- "Track your meals on at least 4 of the next 7 days"

**Minimum → Good:**
- "You're on track! Log weight daily for better accuracy"
- "Tracking meals 5+ days/week will improve your results"

**Good → Excellent:**
- "Almost there! 2 more weeks of data will maximize accuracy"
- "Great consistency! Keep it up for best results"

---

## Weekly Check-In Logic

### Check-In Due Conditions

A check-in is due when ALL conditions are met:

1. Program style is NOT Manual
2. Current day matches configured `checkInDayOfWeek`
3. At least 7 days since last check-in (or goal creation)

### Check-In Availability (NEW)

Check-in button state depends on data quality:

| Data Quality | Button State | Card Appearance                                   |
| ------------ | ------------ | ------------------------------------------------- |
| Insufficient | Disabled     | Shows "X days until check-in" OR "Need more data" |
| Minimum+     | Enabled      | Shows green checkmark, tappable                   |

### Optimization Flow (Updated)

1. **Gather Data** (uses available data, up to 28 days)
   - Get weight entries → Apply EWMA smoothing → Calculate change rate
   - Get food entries → Calculate average daily intake and consistency

2. **Assess Data Quality**
   - Calculate `dataQuality` tier based on weight count, food consistency, time span
   - If `Insufficient` → Return early with specific improvement guidance

3. **Calculate Adaptive TDEE**
   - Apply energy balance equation
   - Calculate confidence score (now reflects data quality tier)

4. **Generate Recommendation**
   - Always show current analysis (weight trend, average intake)
   - Show proposed changes with confidence indicator
   - Include tier-specific improvement tips

5. **Apply or Decline**
   - Accept: Update goal with new TDEE, calories, macros
   - Decline: Only update lastCheckInDate (keep current targets)

---

## Data Requirements Summary

### Absolute Minimums (Check-In Blocked Below These)

| Requirement    | Minimum       | Rationale                         |
| -------------- | ------------- | --------------------------------- |
| Weight entries | ≥ 3           | Need start, middle, end for trend |
| Time span      | ≥ 7 days      | One full week for weekly rate     |
| Food logging   | ≥ 50% of days | Basic intake estimation           |

### Progressive Thresholds

| Data Quality | Weight | Food | Span | Confidence |
| ------------ | ------ | ---- | ---- | ---------- |
| Minimum      | 3+     | 50%+ | 7d+  | ~40%       |
| Good         | 7+     | 60%+ | 7d+  | ~60%       |
| Excellent    | 14+    | 75%+ | 14d+ | ~85%       |

### Confidence Calculation (Updated)

The confidence formula now uses the data quality tier as a ceiling:

```
Raw_Confidence = (Duration_Factor × 0.3) + (Consistency_Factor × 0.5) + (Trend_Clarity × 0.2)

Tier_Ceiling:
- Minimum tier: max 0.5
- Good tier: max 0.7
- Excellent tier: max 1.0

Final_Confidence = min(Raw_Confidence, Tier_Ceiling)
```

This ensures users understand that limited data = limited confidence, regardless of how "perfect" the limited data looks

---

## Metabolic Adaptation Detection

The system can detect if actual TDEE is significantly lower than expected:

```
Adaptation_Detected = (Expected_TDEE - Actual_TDEE) / Expected_TDEE > 0.15
```

A >15% reduction from expected TDEE suggests metabolic adaptation (body slowing metabolism in response to caloric deficit).

---

## Test Seeding Scenarios

The following launch arguments seed different data conditions for testing the progressive accuracy system.

### Available Flags

| Flag                           | Data Quality | Weight     | Food | Days | Purpose                |
| ------------------------------ | ------------ | ---------- | ---- | ---- | ---------------------- |
| `--seed-check-in-insufficient` | Insufficient | 2 entries  | 40%  | 5    | Test blocked state     |
| `--seed-check-in-minimum`      | Minimum      | 4 entries  | 55%  | 7    | Test low confidence    |
| `--seed-check-in-good`         | Good         | 10 entries | 65%  | 10   | Test medium confidence |
| `--seed-check-in-ready`        | Excellent    | 21 entries | 75%  | 28   | Test high confidence   |

### Scenario Details

#### 1. Insufficient Data (`--seed-check-in-insufficient`)
- **Weight:** 2 entries over 5 days
- **Food:** 2 of 5 days logged (40%)
- **Expected:** Check-in card disabled, shows "Need more data" message
- **UI:** Displays specific requirements to unlock check-in

#### 2. Minimum Data (`--seed-check-in-minimum`)
- **Weight:** 4 entries over 7 days
- **Food:** 4 of 7 days logged (~57%)
- **Expected:** Check-in enabled with yellow/caution indicator
- **UI:** Shows "Limited data - results may vary" caveat
- **Confidence:** ~40%

#### 3. Good Data (`--seed-check-in-good`)
- **Weight:** 10 entries over 10 days
- **Food:** 7 of 10 days logged (70%)
- **Expected:** Check-in enabled with blue/normal indicator
- **UI:** Standard recommendation view
- **Confidence:** ~60%

#### 4. Excellent Data (`--seed-check-in-ready`)
- **Weight:** 21 entries over 28 days
- **Food:** 21 of 28 days logged (75%)
- **Expected:** Check-in enabled with green/confident indicator
- **UI:** High confidence recommendations
- **Confidence:** ~85%

### Combining with Other Flags

All check-in flags require:
- `--reset-app-data: true` (clears existing data)
- `--ui-testing: true` (bypasses auth)

Example project.yml configuration:
```yaml
run:
  commandLineArguments:
    "--reset-app-data": true
    "--ui-testing": true
    "--seed-check-in-minimum": true  # Choose one
```

### Test Matrix

| Scenario     | Card State | Tap Result  | Confidence | Recommendations |
| ------------ | ---------- | ----------- | ---------- | --------------- |
| Insufficient | Disabled   | N/A         | N/A        | None            |
| Minimum      | Enabled    | Opens sheet | ~40%       | With caveats    |
| Good         | Enabled    | Opens sheet | ~60%       | Standard        |
| Excellent    | Enabled    | Opens sheet | ~85%       | High confidence |

---

## References

- Mifflin MD, St Jeor ST, et al. "A new predictive equation for resting energy expenditure in healthy individuals." Am J Clin Nutr. 1990;51(2):241-247.
- Standard activity multipliers from Harris-Benedict revisions
- 7700 kcal/kg commonly used in nutrition literature (approximation for mixed tissue)
