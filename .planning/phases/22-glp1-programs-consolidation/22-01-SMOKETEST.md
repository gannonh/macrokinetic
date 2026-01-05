# Smoke Test: Section Extraction

## Feature

Extracted ConcentrationSection, AdherenceSection, and HistorySection components from ShotsView. This is a pure refactor - behavior should be identical.

## How to Test

1. Build and run the app on simulator or device
2. Navigate to the Shots tab
3. Test all three section modes:
   - **Concentration**: Tap "Concentration" in the section picker
   - **Adherence**: Tap "Adherence" in the section picker
   - **History**: Tap "History" in the section picker

## Expected Behavior

### Concentration Section
- [ ] Concentration chart displays correctly (if data exists)
- [ ] Loading spinner shows while chart is generating
- [ ] "No Data Yet" message shows when no medication profiles exist
- [ ] Time period selector (7 days, 30 days, etc.) works

### Adherence Section
- [ ] All adherence cards display: Adherence Rate, Dose Streaks, Progress Indicator
- [ ] Adherence trend chart shows weekly data
- [ ] Missed dose pattern view displays
- [ ] "No Data Yet" shows when no user/profiles exist

### History Section
- [ ] List/Calendar toggle works correctly
- [ ] Dose history list displays in list mode
- [ ] Dose calendar displays in calendar mode
- [ ] Toggle preserves selection when switching back

### General
- [ ] No visual glitches or layout issues
- [ ] No crashes during navigation
- [ ] Performance identical to before refactor

## Issues Found

(To be filled by tester)

## Status

- [ ] Verified
