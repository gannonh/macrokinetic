# Smoketest: Phase 32-01 Standard Widgets

## Quick Verification (2 minutes)

### Prerequisites
- Run the app on simulator or device
- Navigate to Dashboard tab

### Visual Checks

1. **Insights & Analytics Section Visible**
   - [ ] Section appears below Hero carousel
   - [ ] Section header shows "Insights & Analytics"
   - [ ] 2x2 grid layout displays 4 widgets

2. **Expenditure Widget (top-left)**
   - [ ] Title: "Expenditure"
   - [ ] Subtitle: "Last 7 Days"
   - [ ] Orange bar visualization (7 bars, varying heights)
   - [ ] Value: "1893 kcal"
   - [ ] Chevron indicator on right

3. **Weight Trend Widget (top-right)**
   - [ ] Title: "Weight Trend"
   - [ ] Subtitle: "Last 7 Days"
   - [ ] Purple sparkline chart (line with dots)
   - [ ] Value: "183.7 lbs"
   - [ ] Chevron indicator on right

4. **Energy Balance Widget (bottom-left)**
   - [ ] Title: "Energy Balance"
   - [ ] Subtitle: "Last 7 Days"
   - [ ] Orange dots (7 dots)
   - [ ] Blue bar below dots
   - [ ] Value: "1793 kcal deficit"
   - [ ] Chevron indicator on right

5. **Goal Progress Widget (bottom-right)**
   - [ ] Title: "Goal Progress"
   - [ ] Subtitle: "Last 1 Days"
   - [ ] Progress bar (green fill on gray track)
   - [ ] White target marker on bar
   - [ ] Value: "20%"
   - [ ] Chevron indicator on right

### Interaction Checks

6. **Widget Cards**
   - [ ] All 4 widgets have consistent card styling
   - [ ] Cards have proper padding and spacing
   - [ ] Widgets are tappable (visual feedback on tap)

### Scrolling Behavior

7. **Dashboard Scroll**
   - [ ] Insights section scrolls with dashboard
   - [ ] No visual glitches during scroll

## Notes
- All widgets display mock data (will be connected in Phase 34)
- Widget tap actions are no-ops (navigation will be added in Phase 33)
