Context:
Currently smoke testing @.planning/phases/15.2-program-style-implementation/15.2-04-PLAN.md


Scenario 1: First time use (basic health data not set)

Entry point: More > Strategy > Create Goal  
- Weight Loss
- Set Your Target: 
  - Current Weight: 180 lbs
  - Target Weight: 170 lbs
  - Weekly Rate: 1.0 lbs/week
  - Continue 
    - ❌ ISSUE: 
      - Should ask to sync health data if not set (like profile or quick weight entry)
- Goal Summary > continue to Program

- Program Style: Coached
- Complete Your Profile
  - Height: 5'7"
  - Age: 30
  - Sex: Male
  - Continue 
    - ❌ ISSUE
      - UI Freezes

- Program Style: Collaborative
- Weekly Distribution 
    - ❌ ISSUE: 
      - Showing generic results instead of actual TDEE/macro calculation to modify
      - Should ask to complete profile if data missing (like Coached)
      - Should show calculated cals/macros evenly distributed for modification.
      - Should look like mock: @mocks/goal-program/Collaborative/02.PNG
        - Color coded macros/cals bars

---

Scenario 2: User data exists (health data already set)

New Goal 
> Weight Loss 
> Set Target (with health data already set) 
  - Current Weight: 180 lbs
  - Target Weight: 170 lbs
  - Weekly Rate: 1.0 lbs/week
> Goal Summary > 

Program Style: Coached (1428)
> Preferred Diet - Balanced
> Calorie Floor - Standard
> Training - Cardio
> Distribution - Even
> Protein - Moderate
> Review & Confirm - Create Program

RESULTS: 
TDEE: 2689kcal; 
Program: 2190/kcal, P 130g, F 29g, C: 238g

---

Program Style: Collaborative
> Weekly Distribution


---

Test:
- Coached / Shifted
- How Protein setting effects calculated macros/cals

