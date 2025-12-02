# Manual Testing Instructions - Issue #260
# Notification Delivery & Device-Only Features

**⚠️ IMPORTANT**: This document covers ONLY features that cannot be tested on simulator. All UI flows, Settings configuration, and onboarding are covered by E2E tests and should NOT be manually tested.

## What Simulators Cannot Test

1. **Actual notification delivery** - Simulators don't deliver real notifications
2. **Notification action buttons** - Take Dose, Skip, Snooze actions
3. **Deeplink handling from real notifications** - Opening app from notification tap
4. **Device restart persistence** - iOS notification queue survival across reboot
5. **Real iOS Settings integration** - Permission changes in system Settings app

---

## Prerequisites

### Device Setup
```bash
# 1. Connect device via USB
# 2. In Xcode: Product → Destination → [Your Device]
# 3. Build and run: Product → Run (⌘R)
```

### Pre-Test Setup
1. **Complete onboarding** - Grant notifications when prompted (or enable in Settings after)
2. **Create a medication schedule**:
   - Settings → Medication Profile
   - Set weekly dose time ~5 minutes in future
3. **Configure reminder timing**:
   - Settings → Notifications
   - Set "15 min before" (notification will arrive 15 min before dose time)
4. **Verify notification permission**:
   - iOS Settings → Notifications → JabTracker → Allow Notifications: ON

---

## Test 1: Basic Notification Delivery (5 min)

**Purpose**: Verify actual notifications appear on device

**Steps**:
1. Lock device or background app
2. Wait for notification (dose time - 15 min)
3. Check notification appears

**Expected**:
- ✅ Notification appears at correct time
- ✅ Title: "Time for your dose"
- ✅ Body: "Semaglutide 0.25 mg" (or your medication)
- ✅ Three action buttons: "Take Dose", "Skip", "Snooze"

**If fails**: Check Troubleshooting section below

---

## Test 2: "Take Dose" Action (2 min)

**Purpose**: Verify "Take Dose" button logs dose in background

**Steps**:
1. When notification appears, pull down to show actions
2. Tap "Take Dose" button
3. **Do NOT open app** - wait 5 seconds
4. Open app → History tab

**Expected**:
- ✅ Dose logged in History with scheduled timestamp
- ✅ Amount matches medication profile
- ✅ Notification dismissed from notification center

---

## Test 3: "Skip" Action (2 min)

**Purpose**: Verify "Skip" button marks dose as skipped

**Steps**:
1. Wait for next notification
2. Pull down notification
3. Tap "Skip" button
4. Open app → History tab

**Expected**:
- ✅ Scheduled dose shows "Skipped" status
- ✅ No dose entry created
- ✅ Notification dismissed

---

## Test 4: "Snooze" Action (15 min)

**Purpose**: Verify "Snooze" reschedules notification

**Steps**:
1. Wait for next notification
2. Pull down notification
3. Tap "Snooze" button
4. Wait 15 minutes
5. Check for second notification

**Expected**:
- ✅ First notification dismissed immediately
- ✅ Second notification appears 15 minutes later
- ✅ Second notification has same content and actions

---

## Test 5: Deeplink from Background (1 min)

**Purpose**: Verify tapping notification opens app

**Steps**:
1. Ensure app is backgrounded (home screen)
2. Wait for notification
3. Tap notification body (not action buttons)

**Expected**:
- ✅ App opens to Home tab
- ✅ No crashes

---

## Test 6: Deeplink from Terminated (1 min)

**Purpose**: Verify tapping notification launches closed app

**Steps**:
1. Force quit app (swipe up in app switcher)
2. Wait for notification
3. Tap notification body

**Expected**:
- ✅ App launches successfully
- ✅ Opens to Home tab
- ✅ No crashes

**Note**: QuickDoseSheet navigation from deeplink not yet implemented (future enhancement)

---

## Test 7: Device Restart Persistence (5 min)

**Purpose**: Verify notification queue survives device restart

**Steps**:
1. Ensure notifications enabled with future scheduled dose
2. Power off device completely
3. Power on device
4. Wait for next scheduled notification time

**Expected**:
- ✅ Notification still delivers after device restart
- ✅ No duplicate notifications
- ✅ Notification queue rebuilt correctly

---

## Test 8: iOS Settings Permission Changes (3 min)

**Purpose**: Verify app responds to system permission changes

**Steps**:
1. Enable notifications in app (Settings tab)
2. Go to iOS Settings → Notifications → JabTracker
3. Turn OFF "Allow Notifications"
4. Return to app → Settings tab → Notifications section

**Expected**:
- ✅ Toggle remains ON (app state preserved)
- ✅ Status shows "Disabled - Enable notifications in Settings"
- ✅ "Settings" button appears
- ✅ Tapping "Settings" opens iOS Settings app

**Re-enable Test**:
1. Go to iOS Settings → Notifications → JabTracker
2. Turn ON "Allow Notifications"
3. Return to app (may need to force quit and reopen)

**Expected**:
- ✅ Status updates to "Enabled"
- ✅ Notifications resume working

---

## Troubleshooting

### Notifications Not Appearing

**Check**:
1. iOS Settings → Notifications → JabTracker → Allow Notifications: **ON**
2. iOS Settings → Notifications → JabTracker → Sounds: **ON**
3. Device **NOT** in Do Not Disturb mode (check Control Center)
4. Focus modes disabled (Settings → Focus)
5. App Settings → Notifications toggle: **ON**
6. Scheduled dose time is in **future** (check Settings → Medication Profile)
7. Reminder offset doesn't push notification into **past**

**Debug with Xcode Console**:
```bash
# Connect device, run app from Xcode, check Console output:
✅ "Scheduled notification for dose at <time>"
✅ "Notification authorization status: authorized"
❌ "Failed to schedule notification: <error>"
```

### Notification Actions Not Working

**Check**:
1. Pull down notification to reveal actions (don't just tap notification)
2. Wait 5-10 seconds after action tap for background processing
3. Check Xcode Console for error messages

### Deeplinks Not Working

**Check**:
1. URL scheme registered: `jab-tracker://` (check Info.plist)
2. Notification contains deeplink in userInfo (check Xcode Console)

**Debug**:
```bash
# Xcode Console should show:
✅ "Handling dose deeplink: <UUID>"
❌ "Failed to parse deeplink: <error>"
```

---

## Success Criteria

**Total Manual Testing Time: ~35 minutes**

All tests passing means:
- ✅ Actual notifications delivered to device at correct time
- ✅ Notification actions work (Take Dose, Skip, Snooze)
- ✅ Deeplinks open app from background and terminated states
- ✅ Notification queue survives device restart
- ✅ App responds correctly to iOS Settings permission changes

---

## Recording Results

**Quick Checklist** (copy to PR comment):
```
Manual Testing - Issue #260 (Device: iPhone XX, iOS XX.X)

Notification Delivery:
- [ ] Test 1: Basic notification delivery (5 min)
- [ ] Test 2: "Take Dose" action (2 min)
- [ ] Test 3: "Skip" action (2 min)
- [ ] Test 4: "Snooze" action (15 min)

Deeplinks:
- [ ] Test 5: From background (1 min)
- [ ] Test 6: From terminated (1 min)

Device-Specific:
- [ ] Test 7: Device restart persistence (5 min)
- [ ] Test 8: iOS Settings permission changes (3 min)

Total Time: ~35 minutes

Issues Found:
- [List any failures with device model, iOS version, steps to reproduce]

All tests passed ✅
```

---

## Notes

- **E2E tests already cover**: Onboarding flow, Settings UI, toggle states, reminder picker
- **This document covers ONLY**: What simulators cannot test
- **Run E2E tests first**: `./scripts/test.sh ui 1 OnboardingNotificationFlowUITests NotificationSettingsUITests`
- **Manual testing is last step**: Only after all E2E tests pass
