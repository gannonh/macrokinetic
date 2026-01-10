# Smoke Test: Weight Trend Detail View

## Feature
Weight Trend Detail View with header, time period filters, Swift Charts line chart, insights cards, and data sources section.

## How to Test
1. Build and run the app in Xcode
2. Navigate to Dashboard tab
3. Tap on the Weight Trend widget in the Standard Widgets section
4. Verify the WeightTrendDetailView sheet presents

## Expected Behavior
- Header shows "Average" label with current weight (192.2 lbs)
- "Difference" shows -9.8 lbs in green (loss)
- Time period selector shows: 1W, 1M, 3M, 6M, 1Y, All buttons
- "D" toggle button for detailed dates
- Chart displays scale weight points (dots) and trend line
- Legend shows "Scale Weight" and "Trend Weight"
- 5 insight cards render:
  - Weight Changes (with 3-day, 7-day, 14-day rows)
  - Current Weight (with description)
  - Weekly Weight Change (with description)
  - Energy Deficit (with description)
  - 30-Day Projection (with description)
- Data Sources section shows Scale Weight source
- Historical weight log displays with dates

## Verification
- [ ] Detail view presents as sheet from widget
- [ ] Header displays current weight and difference
- [ ] Time period buttons are tappable
- [ ] Chart renders with points and trend line
- [ ] All 5 insight cards display with mock data
- [ ] Data sources section visible
- [ ] No visual glitches
- [ ] No crashes

## Issues Found
(To be filled by tester)

## Status
- [ ] Verified
