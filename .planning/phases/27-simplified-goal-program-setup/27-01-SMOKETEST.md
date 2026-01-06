# Smoke Test: Simplified Goal & Program Setup

## Feature
Goal and program setup integrated into onboarding flow as native steps (not separate wizard sheets). Reuses existing step view components from GoalWizard and ProgramWizard. HealthKit permission is requested before goal setup so weight data is available.

## How to Test
1. Build and run the app in Xcode
2. Use `--force-onboarding` launch argument OR delete app data to trigger onboarding
3. Complete Sign in with Apple (or skip if using `--ui-testing`)
4. Progress through Welcome and USP showcase screens
5. On HealthKit step, tap Continue (placeholder for now)
6. **Goal Type step**: Select your goal (Weight Loss, Maintain, Build Muscle)
7. **Target Weight step**:
   - Verify current weight is displayed
   - Set target weight using slider
   - Set weekly rate using slider
   - Review projected results
8. **Profile Completion step**:
   - Set height using feet/inches pickers
   - Select sex (Male/Female)
   - Set birthday using date picker
9. **Activity Level step**: Select your activity level
10. **Your Personalized Plan step**:
    - Verify calculated calorie target is displayed (NOT 2000 generic)
    - Verify macro breakdown (Protein/Fat/Carbs) is shown
    - Review goal summary
    - Review program info (Coached, Balanced, your activity level)
11. Continue to Face ID step
12. Continue to Notifications step
13. Tap "Get Started" on completion step
14. Navigate to Strategy tab to verify goal and program were created

## Expected Behavior
- Seamless integrated flow (no jarring sheet presentations)
- 11 total steps with single progress indicator
- Goal configuration steps reuse existing components
- Profile data collection before TDEE calculation
- **Personalized calorie targets** based on:
  - Your height, age, sex
  - Your activity level
  - Your goal type and pace
- Strategy tab shows created goal and program

## Verification
- [ ] Welcome step displays
- [ ] USP showcase step displays
- [ ] HealthKit step displays (placeholder)
- [ ] Goal type selection works
- [ ] Target weight slider works
- [ ] Weekly rate slider works
- [ ] Profile completion (height/sex/birthday) works
- [ ] Activity level selection works
- [ ] **Calculated calories are personalized (NOT 2000 generic)**
- [ ] Macro breakdown displays
- [ ] Onboarding completes successfully
- [ ] Goal appears in Strategy tab
- [ ] Program appears in Strategy tab
- [ ] No visual glitches or layout issues
- [ ] No crashes
- [ ] Back button works on each step

## Issues Found
(To be filled by tester)

## Status
- [ ] Verified
