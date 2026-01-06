# Smoke Test: Simplified Goal & Program Setup

## Feature
Goal and program setup integrated into onboarding flow using existing GoalWizard and ProgramWizard components. HealthKit permission is requested before goal setup so weight data is available.

## How to Test
1. Build and run the app in Xcode
2. Use `--force-onboarding` launch argument OR delete app data to trigger onboarding
3. Complete Sign in with Apple (or skip if using `--ui-testing`)
4. Progress through USP showcase screens
5. On HealthKit step, tap Continue (placeholder for now)
6. GoalWizard sheet auto-presents:
   - Complete goal type selection (Weight Loss, Maintain, Build Muscle)
   - Set target weight and weekly rate
   - Review summary and tap "Continue to Program"
7. ProgramWizard sheet auto-presents:
   - Select program style (Coached, Flexible, Manual)
   - Complete remaining program configuration
   - Review and confirm
8. Complete remaining onboarding steps (Face ID, Notifications)
9. Navigate to Strategy tab to verify goal and program were created

## Expected Behavior
- GoalWizard presents as sheet after HealthKit step
- Full 3-step goal configuration (type, targets, summary)
- ProgramWizard chains after GoalWizard completes
- Full program configuration flow
- After onboarding, Strategy tab shows:
  - Created goal with user-configured targets
  - Created program with user-configured style

## Verification
- [ ] HealthKit step displays (placeholder)
- [ ] GoalWizard sheet appears automatically
- [ ] Goal type selection works
- [ ] Target weight configuration works
- [ ] Goal summary displays correctly
- [ ] ProgramWizard chains after goal completion
- [ ] Program configuration works
- [ ] Onboarding continues to Face ID step
- [ ] Onboarding completes successfully
- [ ] Goal appears in Strategy tab
- [ ] Program appears in Strategy tab
- [ ] No visual glitches or layout issues
- [ ] No crashes

## Issues Found
(To be filled by tester)

## Status
- [ ] Verified
