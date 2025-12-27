### 📋 Goals & Daily Tracking

Set personalized weight and macro goals, then track daily progress with visual indicators showing intake vs. targets.

#### Requirements

- [ ] Goal configuration wizard (weight goal, pace, calorie/macro targets)
- [ ] Strategy/program selection (e.g., keto, balanced)
- [ ] Weight goal with target date and weekly pace selection
- [ ] Dynamic TDEE algorithm for calorie target (calorie targets adjust with weight changes)
- [ ] Daily calorie, protein, carb, and fat goals
- [ ] Progress rings/bars for each macro
- [ ] Remaining vs consumed display
- [ ] Color coding for under/over targets
- [ ] Daily summary on dashboard
- [ ] Edit goals from settings
- [ ] Weekly Check-ins for goal/strategy adjustments

#### User Stories

##### Goal Setup
- **As a user**, I want a guided goal setup, so that I configure targets correctly.
- **As a user**, I want to set a weight goal, so that the app calculates my daily calorie target.
- **As a user**, I want to choose my weight loss pace, so that I balance speed with sustainability.
- **As a user**, I want to select a nutrition strategy, so that my macro targets align with my diet.
- **As a user**, I want my calorie target to adjust, based on actual weight changes, not just a generic forumula

##### Daily Tracking
- **As a user**, I want to see progress rings, so that I visualize my daily intake at a glance.
- **As a user**, I want color coding, so that I know when I'm over or under target.
- **As a user**, I want to see remaining macros, so that I plan my next meal.

##### Adjustments
- **As a user**, I want to adjust goals later, so that I can adapt as my needs change.

#### Key Design Decisions

1. **Goal-driven calculations** - Calorie/macro targets derived from weight goal and pace.
2. **Visual progress rings** - Circular progress for each macro on dashboard.
3. **Color semantics** - Green (on track), Yellow (approaching limit), Red (over).

#### Acceptance Criteria

- [ ] Goal wizard completes setup in under 2 minutes
- [ ] Calorie goal calculated from weight goal and pace
- [ ] Progress rings update in real-time as food is logged
- [ ] Color coding reflects target status
- [ ] Goals editable from settings

---

Program Components

Program Style:

Which program style would you like to use?
[ ] Coached - We'll design a Calorie and macro program based on your goal and preferences.
[ ] Collaborative - Set your own macro targets and we'll adjust your Calorie budget based on your goal and progress.
[ ] Manual - Set your own macro and Calorie targets using manual entry.

What is your preferred diet?
[ ] Balanced - Standard distribution of carbs and fat
[ ] Low-fat - Fat will be reduced to prioritize carb and protein intake
[ ] Low-carb - Carbs will be reduced to prioritize fat and protein intake
[ ] Keto - Carbs will be very restricted to allow for higher fat intake

What calorie floor do you prefer?
[ ] Standard Floor = Your recommendations will never go below 1538 Calories
[ ] Low Floor = Your recommendations will never go below 1025 Calories (proceed with caution)

How would you like to distribute Calories throughout the week?
[ ] Distribute Evenly - Distribute Calories evenly across all days of the week.
[ ] Shift Calories - Distribute Calories to increase Calorie targets on specific days.

What is your preferred protein intake?
[ ] Low - On the low side of the optimal range.
[ ] Moderate - In the middle of the optimal range.
[ ] High - On the high end of the optimal range.
[ ] Extra High - Highest recommended intake.


---


  Design Summary

  Strategy Screen (IMG_2012):
  - New tab with "New Goal", "Edit Goal", "New Program" buttons
  - Countdown ring showing days until check-in
  - Current program display with daily targets

  Correct Domain Separation:

  | Goal                                | Program                                      |
  |-------------------------------------|----------------------------------------------|
  | Goal Type (Lose/Maintain/Gain)      | Program Style (Coached/Collaborative/Manual) |
  | Target Weight (e.g., 180 lbs)       | Diet Preference                              |
  | Rate of Change (e.g., 1.5 lbs/week) | Calorie Floor                                |
  |                                     | Weekly Distribution                          |
  |                                     | Protein Level                                |

  Flow Logic:
  1. New Goal → Must chain to New Program (2-step wizard)
  2. Edit Goal → Only goal settings (standalone)
  3. New Program → Only program settings (standalone, uses existing goal)

  Current Implementation Issues

  Our current GoalConfigurationWizard conflates Goal and Program:
  - GoalType is in the wizard but should be Goal Step 1
  - Missing: Target Weight, Rate of Change input
  - Missing: Separate edit paths for Goal vs Program
  - Entry point is wrong (should be a "Strategy" tab, not More menu)

  Recommended Next Steps

  1. Update Data Models:
    - Add targetWeightKg, weeklyRateKg to NutritionGoal
    - Move goalType logic to Goal-only context
  2. Split Wizard into Two Flows:
    - GoalWizard: GoalType → Target Weight/Rate → Summary
    - ProgramWizard: Program Style → Diet Preference → ... → Confirmation
  3. Create Strategy Tab (or view) with proper entry points
