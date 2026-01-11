# Smoke Test: Hero Widgets Live Data

## Feature
Hero carousel widgets (Daily Nutrition, Weekly Nutrition, Energy Balance) now display live data from MealLogService and TDEEService instead of mock data.

## How to Test
1. Launch the app and navigate to the Dashboard tab
2. Observe the Hero Widget carousel (swipe between the 3 widgets)
3. Verify each widget displays your actual nutrition data

## Expected Behavior
- **Daily Nutrition Widget**: Shows today's consumed calories/macros vs your targets
- **Weekly Nutrition Widget**: Shows 7-day nutrition history with fill percentages
- **Energy Balance Widget**: Shows 30-day calorie intake vs expenditure/targets

## Verification
- [ ] Daily Nutrition shows actual today's data (or zeros if no food logged)
- [ ] Weekly Nutrition shows past days filled, today partial, future 0%
- [ ] Energy Balance chart shows actual balance data
- [ ] Mode toggle (Consumed/Remaining or Expenditure/Targets) works correctly
- [ ] No visual glitches or layout issues
- [ ] No crashes when swiping between widgets

## Issues Found
(To be filled by tester)

## Status
- [ ] Verified
