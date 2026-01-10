# Smoke Test: Expenditure Detail View

## Feature
ExpenditureDetailView with header, bar chart, time period filtering, insights cards, and data sources section.

## How to Test
1. Open the app and navigate to the Dashboard tab
2. Find the "Expenditure" widget in the Insights & Analytics group
3. Tap the widget to open ExpenditureDetailView
4. Verify the following elements:

## Expected Behavior
- Header shows "Average: 1903 kcal" with "Difference: -135 kcal"
- Date range displays below header
- Time period selector shows 1W, 1M, 3M, 6M, 1Y, All buttons + D toggle
- Bar chart displays with colored bars (orange/blue/gray for Flux Range/Updating/Holding)
- Legend shows all three status types
- "Expenditure Changes" card shows 3-day through 90-day changes
- "Current Expenditure" card shows 1893 kcal with description
- "Current Strategy" card shows "Holding" with explanation
- Data sources section shows Nutrition Data Manager and Scale Weight
- Historical log shows recent expenditure entries

## Verification
- [ ] Feature accessible via widget tap
- [ ] Header displays correctly
- [ ] Time period selector works (buttons highlight on tap)
- [ ] Bar chart renders with colored bars
- [ ] Legend displays correctly
- [ ] Insights cards render with descriptions
- [ ] Data sources section displays
- [ ] Historical log shows entries
- [ ] No visual glitches
- [ ] No crashes

## Issues Found
(To be filled by tester)

## Status
- [ ] Verified
