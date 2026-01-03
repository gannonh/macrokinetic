# Smoke Test: More Tab Refinements

## Feature
CalorieExpenditureView mock screen with daily budget, activity level selector, and TDEE breakdown sections, plus verified inactive placeholders in MoreView.

## How to Test
1. Launch the app and navigate to the More tab
2. Verify all sections are properly organized and labeled
3. Test CalorieExpenditureView navigation:
   - Tap "Calorie Expenditure" under Feature Settings
   - Verify the view loads with "Coming Soon" banner
   - Check daily budget shows "2,400 calories"
   - Verify activity level selector shows 5 options with "Moderately Active" selected
   - Check TDEE breakdown shows BMR (1,800), Activity (400), TEF (200), Total (2,400)
   - Verify footer text "This feature is coming soon"
4. Test inactive placeholders:
   - Verify "Food Log" appears gray and is not tappable
   - Verify "Shortcuts & Tabs" appears gray and is not tappable
   - Verify "FAQ" appears gray and is not tappable
   - Verify "Help & Support" appears gray and is not tappable
5. Test other navigation items still work:
   - Goals & Strategy
   - Food Library
   - GLP-1 Medications
   - Metrics
   - Units of Measurement
   - Profile
   - Subscription
   - Security & Privacy
   - Notifications
   - General

## Expected Behavior
- CalorieExpenditureView displays all mock content correctly with proper styling
- All inactive items appear grayed out and cannot be tapped
- All active navigation items navigate to their respective screens
- No layout issues or visual glitches
- Consistent styling throughout the More tab

## Verification
- [ ] CalorieExpenditureView accessible from More tab
- [ ] All mock content displays correctly
- [ ] Inactive placeholders styled correctly (gray)
- [ ] Active navigation works properly
- [ ] No visual glitches or crashes

## Issues Found
(To be filled by tester)

## Status
- [ ] Verified
