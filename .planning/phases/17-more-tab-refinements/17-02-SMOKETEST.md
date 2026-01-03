# Smoke Test: Notification Settings

## Feature
Comprehensive notification settings view with weigh-in (daily/weekly), food logging (5 meal reminders), and medication dose reminder toggles. All settings persist to UserDefaults and schedule/cancel notifications in real-time.

## How to Test
1. Run the app on iOS 17 Pro simulator
2. Navigate: More tab → Notifications
3. Enable "Daily" weigh-in reminder → verify time picker appears
4. Change time → verify setting persists
5. Enable "Weekly" weigh-in reminder → verify day picker + time picker appear
6. Enable breakfast reminder → verify time picker appears
7. Enable lunch, snack, dinner reminders → verify all time pickers
8. Enable "End of Day" reminder → verify footer changes to "Get one daily reminder and log all your meals at once."
9. Enable "Dose Reminders" → verify ReminderTimingPicker appears
10. Kill and restart app → verify all toggles and times persist
11. Check notification authorization status section at bottom

## Expected Behavior
- All toggles function properly with smooth animations
- Time pickers appear/disappear when toggles change
- Weekly weigh-in shows day picker (Sunday-Saturday)
- End of day reminder changes footer text
- Settings persist across app restart
- NotificationAuthorizationStatus shows current auth state
- No console errors or warnings

## Verification
- [ ] Feature accessible from More tab
- [ ] All toggles work (9 total: 2 weigh-in, 5 food logging, 1 dose, 1 end-of-day)
- [ ] Time pickers appear when enabled
- [ ] Weekly day picker works
- [ ] Settings persist after app restart
- [ ] No visual glitches
- [ ] No crashes
- [ ] Authorization status displays correctly

## Issues Found
None - all functionality working as expected

## Status
- [x] Verified
