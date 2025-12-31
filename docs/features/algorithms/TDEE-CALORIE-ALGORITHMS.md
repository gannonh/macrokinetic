# TDEE & Calorie Algorithms

**Last Updated:** 2025-12-31 (Progressive Accuracy Update)
**Source Files:**
- `JabTracker/Services/TDEECalculationEngine.swift`
- `JabTracker/Services/TDEECalculationEngine+Adaptive.swift`
- `JabTracker/Services/TDEECalculationEngine+EWMA.swift`
- `JabTracker/Services/TDEECalculationEngine+Validation.swift`
- `JabTracker/Services/TDEEService.swift`
- `JabTracker/Services/WeeklyCheckInService.swift`

---

## Table of Contents

1. [Overview](#overview)
2. [Initial TDEE Estimation](#initial-tdee-estimation)
3. [Adaptive TDEE Calculation](#adaptive-tdee-calculation)
4. [Weight Smoothing (EWMA)](#weight-smoothing-ewma)
5. [Confidence Scoring](#confidence-scoring)
6. [Calorie Target Derivation](#calorie-target-derivation)
7. [Macro Calculations](#macro-calculations)
8. [Thresholds & Configuration](#thresholds--configuration)
9. [Weekly Check-In Logic](#weekly-check-in-logic)
10. [Data Requirements Summary](#data-requirements-summary)

---

## Overview

The app uses a two-phase TDEE (Total Daily Energy Expenditure) calculation:

1. **Initial Estimate**: Formula-based estimate using Mifflin-St Jeor + activity multiplier
2. **Adaptive Refinement**: Data-driven refinement using actual weight changes and food intake

This allows the app to provide immediate targets during onboarding, then progressively improve accuracy as user data accumulates.

---

## Initial TDEE Estimation

### Mifflin-St Jeor Formula (BMR)

The Basal Metabolic Rate (BMR) is calculated using the Mifflin-St Jeor equation, which is considered the most accurate formula for healthy adults.

**Formula:**

```
BMR = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + adjustment
```

**Gender Adjustments:**
| Gender | Adjustment |
|--------|------------|
| Male | +5 |
| Female | -161 |
| Unknown | -78 (average) |

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

| Training Level | Multiplier | Description |
|----------------|------------|-------------|
| None | 1.2 | Sedentary - desk job, no exercise |
| Lifting | 1.55 | Moderately active - resistance training |
| Cardio | 1.55 | Moderately active - aerobic exercise |
| Cardio & Lifting | 1.725 | Very active - combined training |

**Valid multiplier range:** 1.0 - 2.5 (values outside this are clamped)

**Example:**
```
BMR = 1798.75 kcal
Training = Lifting (1.55)
TDEE = 1798.75 × 1.55 = 2788 kcal/day
```

### Input Validation Ranges

| Parameter | Valid Range | Unit |
|-----------|-------------|------|
| Weight | 20 - 500 | kg |
| Height | 100 - 250 | cm |
| Age | 10 - 120 | years |

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

| Factor | Weight | Calculation | Max at |
|--------|--------|-------------|--------|
| Duration | 30% | days / 28 | 28 days |
| Consistency | 50% | days_with_food / total_days | 100% |
| Trend Clarity | 20% | \|rate\| / 0.5 | 0.5 kg/week |

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

| Floor Type | Minimum | Use Case |
|------------|---------|----------|
| Standard | 1538 kcal | Recommended default |
| Low | 1025 kcal | With medical supervision |

```
Final_Target = max(Calculated_Target, Calorie_Floor)
```

---

## Macro Calculations

Macros are calculated based on the calorie target, protein level, and diet preference.

### Protein Calculation

Protein is calculated based on body weight:

```
Protein (g) = Weight_kg × Grams_per_kg
```

| Protein Level | g/kg | Description |
|---------------|------|-------------|
| Low | 1.2 | Minimal activity |
| Moderate | 1.6 | Regular activity |
| High | 2.0 | Strength training |
| Extra High | 2.4 | Intensive training |

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

| Diet | Protein | Carbs | Fat |
|------|---------|-------|-----|
| Balanced | 30% | 40% | 30% |
| Low Fat | 30% | 50% | 20% |
| Low Carb | 30% | 20% | 50% |
| Keto | 25% | 5% | 70% |

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

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ewmaAlpha` | 0.2 | EWMA smoothing factor |
| `absoluteMinimumWeightEntries` | 3 | Hard minimum to attempt calculation |
| `absoluteMinimumFoodConsistency` | 0.5 (50%) | Hard minimum food logging |
| `optimalWeightEntries` | 14 | Optimal for high confidence |
| `optimalFoodConsistency` | 0.7 (70%) | Optimal food logging |
| `lookbackDays` | 28 | Analysis window |

### WeeklyCheckInService Configuration

| Parameter | Value | Description |
|-----------|-------|-------------|
| `checkInIntervalDays` | 7 | Days between check-ins |
| `onTrackToleranceKgPerWeek` | 0.1 | Tolerance for "on track" determination |

### On-Track Detection

User is considered "on track" when:
```
|Actual_Weekly_Rate - Goal_Weekly_Rate| ≤ 0.1 kg/week
```

---

## Data Quality Tiers (Progressive Accuracy)

The system uses tiered data quality levels instead of hard pass/fail thresholds. This allows check-ins to work with limited data while communicating accuracy to users.

### Data Quality Levels

| Level | Weight Entries | Food Consistency | Time Span | Confidence Range |
|-------|----------------|------------------|-----------|------------------|
| **Insufficient** | < 3 | < 50% | < 7 days | N/A (blocked) |
| **Minimum** | 3-6 | 50-59% | 7+ days | 0.3 - 0.5 |
| **Good** | 7-13 | 60-74% | 7+ days | 0.5 - 0.7 |
| **Excellent** | 14+ | 75%+ | 14+ days | 0.7 - 1.0 |

### Tier Behavior

| Level | Check-In Available | Recommendations | UI Indicator |
|-------|-------------------|-----------------|--------------|
| **Insufficient** | No | None | "Keep tracking" message with requirements |
| **Minimum** | Yes | With strong caveats | Yellow/caution indicator |
| **Good** | Yes | Standard recommendations | Blue/normal indicator |
| **Excellent** | Yes | High confidence recommendations | Green/confident indicator |

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

| Data Quality | Button State | Card Appearance |
|--------------|--------------|-----------------|
| Insufficient | Disabled | Shows "X days until check-in" OR "Need more data" |
| Minimum+ | Enabled | Shows green checkmark, tappable |

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

| Requirement | Minimum | Rationale |
|-------------|---------|-----------|
| Weight entries | ≥ 3 | Need start, middle, end for trend |
| Time span | ≥ 7 days | One full week for weekly rate |
| Food logging | ≥ 50% of days | Basic intake estimation |

### Progressive Thresholds

| Data Quality | Weight | Food | Span | Confidence |
|--------------|--------|------|------|------------|
| Minimum | 3+ | 50%+ | 7d+ | ~40% |
| Good | 7+ | 60%+ | 7d+ | ~60% |
| Excellent | 14+ | 75%+ | 14d+ | ~85% |

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

## References

- Mifflin MD, St Jeor ST, et al. "A new predictive equation for resting energy expenditure in healthy individuals." Am J Clin Nutr. 1990;51(2):241-247.
- Standard activity multipliers from Harris-Benedict revisions
- 7700 kcal/kg commonly used in nutrition literature (approximation for mixed tissue)
