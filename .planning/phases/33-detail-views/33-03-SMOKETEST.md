# Smoke Test: Energy Balance Detail View

## Feature
EnergyBalanceDetailView with dual-mode display (Expenditure vs Calorie Targets), bar chart, insights cards, historical log, and navigation wiring from dashboard widgets.

## How to Test

1. **Launch app and navigate to Dashboard tab**
2. **Tap Energy Balance widget** in Insights & Analytics section
3. **Verify mode toggle** - segmented control at top shows "Expenditure" and "Calorie Targets"
4. **Toggle between modes** - header value/label, chart, and insights should all update
5. **Verify chart** - bar chart shows positive (red) and negative (orange) bars with zero line
6. **Verify insights** - "Relative to Expenditure" or "Relative to Targets" card based on mode
7. **Verify historical log** - shows recent days with deficit/surplus indicators
8. **Tap Done button** - sheet should dismiss
9. **Test other widgets:**
   - Tap Weight Trend widget → WeightTrendDetailView
   - Tap Expenditure widget → ExpenditureDetailView
   - Each sheet dismisses with Done button

## Expected Behavior

- Mode toggle correctly switches all content (header, chart, insights)
- Expenditure mode shows "Deficit" label, Calorie Targets shows "Average"
- Bar chart shows deficit days (orange) and surplus days (red)
- Zero reference line visible on chart
- Time period selector works (1W, 1M, 3M, 6M, 1Y, All)
- Historical log shows most recent 7 days with trend indicators
- All 3 widgets navigate to their respective detail views
- Done button dismisses each sheet

## Verification

- [ ] EnergyBalanceDetailView opens from widget
- [ ] Mode toggle switches between Expenditure and Calorie Targets
- [ ] Header updates based on mode (Deficit/Average, date range)
- [ ] Chart shows positive/negative bars with zero line
- [ ] Insights section updates based on mode
- [ ] Historical log shows with trend indicators
- [ ] WeightTrendDetailView opens from widget
- [ ] ExpenditureDetailView opens from widget
- [ ] Done button dismisses sheets

## Issues Found
(To be filled by tester)

## Status
- [ ] Verified
