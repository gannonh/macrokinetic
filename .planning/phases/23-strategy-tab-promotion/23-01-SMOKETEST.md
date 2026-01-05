# Smoke Test: Strategy Tab Promotion

## Feature
Promoted Strategy to top-level tab in the main tab bar, replacing the Shots tab (now consolidated under More).

## How to Test
1. Launch the app in simulator or device
2. Look at the tab bar at the bottom of the screen
3. Verify "Strategy" tab appears (4th position) with target icon
4. Tap the Strategy tab
5. Navigate to More tab
6. Verify "Goals & Strategy" row is NOT present
7. Verify "GLP-1 Programs" row IS present in More

## Expected Behavior
- Tab bar shows: Dashboard | Food Log | + | Strategy | More
- Strategy tab has "target" SF Symbol icon
- Strategy tab uses large PageHeader title (matching Dashboard/Food Log)
- Tapping Strategy tab shows StrategyView content (check-in countdown, program cards)
- More tab does NOT show "Goals & Strategy" row
- GLP-1 Programs and Food Library remain accessible from More tab
- Badge ("!") appears on Strategy tab when weekly check-in is due (non-Manual programs only)

## Verification
- [x] Strategy tab visible in tab bar with target icon
- [x] Strategy tab shows large "Strategy" PageHeader title
- [x] Strategy tab shows StrategyView content when tapped
- [x] More tab does NOT show "Goals & Strategy" row
- [x] GLP-1 Programs still accessible from More tab
- [x] Navigation within Strategy tab works (edit goal sheets)
- [x] Badge appears on Strategy tab when check-in is due
- [x] No visual glitches or layout issues

## Issues Found
None

## Status
- [x] Verified
