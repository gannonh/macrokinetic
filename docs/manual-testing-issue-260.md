# Manual Testing Instructions - Issue #260
# Notification UI & Configuration

## Prerequisites

### Device Requirements
- Physical iOS device (iPhone or iPad) running iOS 17.0+
- Device must support notifications (all modern devices do)
- Device signed into iCloud (optional, but recommended for full testing)

### Build Installation
```bash
# 1. Connect your device via USB
# 2. Select your device in Xcode (top toolbar)
# 3. Build and run on device
xcodebuild -scheme JabTracker -destination 'platform=iOS,id=<YOUR_DEVICE_UDID>' build

# Or use Xcode UI:
# Product → Destination → [Your Device Name]
# Product → Run (⌘R)
```

### Initial Setup
1. **Fresh Install**: Delete app from device if previously installed
2. **Reset Notifications**: Settings → Notifications → JabTracker → Delete (if exists)
3. **Reset App Data**: Long press app icon → Remove App → Delete App
4. **Reinstall**: Install from Xcode

---

## Test Scenario 1: Onboarding Notification Flow

### Test 1.1: Grant Notifications During Onboarding
**Purpose**: Verify notifications can be enabled during onboarding

**Steps**:
1. Launch app (should show onboarding)
2. Complete welcome screens → tap Continue
3. Select medication: Semaglutide
4. Configure dose: 0.25 mg, abdomen injection site
5. On "Set Up Your Schedule" screen:
   - Verify reminder timing picker exists
   - Select "30 min before"
   - Tap Continue
6. On "Never miss a dose" screen:
   - Tap "Enable Notifications"
   - **iOS permission dialog should appear**
   - Tap "Allow"
7. Complete HealthKit screen (skip or grant)
8. Complete subscription screen
9. Verify app loads to Home tab

**Expected Results**:
- ✅ iOS permission dialog appears when enabling notifications
- ✅ Notification permission granted (check Settings → Notifications → JabTracker)
- ✅ App completes onboarding successfully
- ✅ No crashes or errors

**Verification**:
```
Go to: Settings tab → Notifications section
- Dose Reminders toggle: ON
- Reminder Timing: "30 min before"
- Authorization Status: "Enabled - You'll receive dose reminders"
```

---

### Test 1.2: Deny Notifications During Onboarding
**Purpose**: Verify app handles notification denial gracefully

**Steps**:
1. Reset app (delete and reinstall)
2. Complete onboarding through schedule setup
3. On "Never miss a dose" screen:
   - Tap "Not Now" (deny notifications)
4. Complete remaining onboarding
5. Navigate to Settings tab

**Expected Results**:
- ✅ Onboarding completes successfully without notifications
- ✅ No crashes when denying permission
- ✅ Settings shows notifications disabled

**Verification**:
```
Settings tab → Notifications section:
- Dose Reminders toggle: OFF
- Authorization Status: "Disabled - Enable notifications in Settings"
```

---

## Test Scenario 2: Settings Screen Notification Configuration

### Test 2.1: Enable Notifications via Settings
**Purpose**: Verify notifications can be enabled from Settings after onboarding

**Prerequisite**: App installed with notifications disabled

**Steps**:
1. Open app → Settings tab
2. Scroll down to Notifications section
3. Tap "Dose Reminders" toggle to enable
4. **iOS permission dialog should appear**
5. Tap "Allow"
6. Wait for toggle animation to complete

**Expected Results**:
- ✅ iOS permission dialog appears
- ✅ Toggle turns ON after granting permission
- ✅ Authorization status updates to "Enabled"
- ✅ Reminder timing picker becomes visible

**Verification**:
```
Settings → Notifications:
- Toggle state: ON
- Status: "Enabled - You'll receive dose reminders"
- Reminder Timing picker: Visible
```

---

### Test 2.2: Change Reminder Timing
**Purpose**: Verify reminder timing can be configured

**Prerequisite**: Notifications enabled

**Steps**:
1. Settings tab → Notifications section
2. Tap "Reminder Timing" picker
3. Select "2 hours before"
4. Dismiss picker
5. Navigate away and back to Settings

**Expected Results**:
- ✅ Picker shows all options: 15 min, 30 min, 1 hour, 2 hours
- ✅ Selection persists after navigation
- ✅ No crashes or UI glitches

**Verification**:
```
Settings → Notifications → Reminder Timing:
- Shows: "2 hours before"
- Persists across app restarts
```

---

### Test 2.3: Disable Notifications via Settings
**Purpose**: Verify notifications can be disabled from Settings

**Prerequisite**: Notifications enabled

**Steps**:
1. Settings tab → Notifications section
2. Tap "Dose Reminders" toggle to disable
3. Wait for toggle animation

**Expected Results**:
- ✅ Toggle turns OFF
- ✅ Reminder timing picker disappears
- ✅ Authorization status remains showing system permission state

**Verification**:
```
Settings → Notifications:
- Toggle: OFF
- Reminder picker: Hidden
- Status still shows: "Enabled" (system permission not revoked)
```

---

## Test Scenario 3: Notification Delivery

### Test 3.1: Schedule and Receive Notification
**Purpose**: Verify actual notification delivery on device

**Prerequisite**: Notifications enabled, active medication schedule

**Steps**:
1. **Create a dose schedule**:
   - Go to Settings → Medication Profile
   - Set up weekly schedule with dose time in ~2 minutes
   - Example: If current time is 2:00 PM, set dose time to 2:02 PM
2. **Configure reminder**:
   - Settings → Notifications
   - Set reminder to "15 min before"
   - This means notification at 1:47 PM for 2:02 PM dose
3. **Wait for notification**:
   - Lock device or put app in background
   - Wait until notification time
4. **Check notification delivery**

**Expected Results**:
- ✅ Notification appears at correct time (dose time - reminder offset)
- ✅ Notification content:
   - Title: "Time for your dose"
   - Body: "Semaglutide 0.25 mg"
- ✅ Notification actions visible:
   - "Take Dose"
   - "Skip"
   - "Snooze"

**Verification**:
```
iOS Notification Center:
- Notification appears at expected time
- All action buttons present
- Tapping notification opens app
```

---

### Test 3.2: Notification Actions - Take Dose
**Purpose**: Verify "Take Dose" action logs dose correctly

**Steps**:
1. Wait for notification to arrive
2. Pull down notification (or 3D touch)
3. Tap "Take Dose" action
4. **Do NOT open app yet**
5. Wait 5-10 seconds for background processing
6. Open app → History tab

**Expected Results**:
- ✅ Dose logged in History with correct timestamp
- ✅ Notification dismissed from notification center
- ✅ Badge count updated (if applicable)

**Verification**:
```
History tab:
- New dose entry exists
- Timestamp matches scheduled dose time
- Amount matches medication profile
```

---

### Test 3.3: Notification Actions - Skip
**Purpose**: Verify "Skip" action marks dose as skipped

**Steps**:
1. Wait for notification
2. Pull down notification
3. Tap "Skip" action
4. Open app → History tab

**Expected Results**:
- ✅ Dose marked as skipped in history
- ✅ Notification dismissed
- ✅ No dose entry created

**Verification**:
```
History tab:
- Scheduled dose shows "Skipped" status
- No actual dose logged
```

---

### Test 3.4: Notification Actions - Snooze
**Purpose**: Verify "Snooze" action reschedules notification

**Steps**:
1. Wait for notification
2. Pull down notification
3. Tap "Snooze" action
4. Wait 15 minutes (snooze duration)
5. Check for second notification

**Expected Results**:
- ✅ First notification dismissed
- ✅ Second notification arrives 15 minutes later
- ✅ Second notification has same actions

**Verification**:
```
Notification Center:
- Original notification dismissed
- New notification appears after snooze duration
```

---

## Test Scenario 4: Deeplink Handling

### Test 4.1: Deeplink from Background
**Purpose**: Verify deeplinks work when app is backgrounded

**Steps**:
1. Ensure app is running in background (home screen)
2. Wait for notification
3. Tap notification body (not action buttons)
4. App should open

**Expected Results**:
- ✅ App opens to Home tab
- ✅ No crashes
- ✅ Deeplink logged in console (if viewing Xcode console)

**Verification**:
```
Xcode Console (if attached):
- Look for: "Handling dose deeplink: <UUID>"
- No error messages
```

---

### Test 4.2: Deeplink from Terminated
**Purpose**: Verify deeplinks work when app is fully closed

**Steps**:
1. Force quit app (swipe up in app switcher)
2. Wait for scheduled notification
3. Tap notification
4. App should launch

**Expected Results**:
- ✅ App launches successfully
- ✅ Opens to Home tab
- ✅ No crashes or errors

**Note**: QuickDoseSheet navigation is not yet implemented, so app opens to Home tab only.

---

## Test Scenario 5: Permission Edge Cases

### Test 5.1: Authorization Denied in iOS Settings
**Purpose**: Verify app handles denied permissions gracefully

**Steps**:
1. Enable notifications in app
2. Go to iOS Settings → Notifications → JabTracker
3. Turn OFF "Allow Notifications"
4. Return to app → Settings tab
5. Check notification section

**Expected Results**:
- ✅ Toggle remains ON (app state)
- ✅ Status shows "Disabled - Enable notifications in Settings"
- ✅ "Settings" button appears
- ✅ Tapping "Settings" opens iOS Settings

**Verification**:
```
Settings → Notifications:
- Toggle: ON (app wants notifications)
- Status: "Disabled" (system permission denied)
- Settings button visible and functional
```

---

### Test 5.2: Re-Enable After Denial
**Purpose**: Verify app detects permission changes

**Steps**:
1. With notifications denied in iOS Settings
2. Go to iOS Settings → Notifications → JabTracker
3. Turn ON "Allow Notifications"
4. Return to app (may need to force quit and reopen)
5. Check Settings → Notifications

**Expected Results**:
- ✅ Status updates to "Enabled"
- ✅ Notifications start being delivered
- ✅ App reflects permission change

---

## Test Scenario 6: Persistence and App Restart

### Test 6.1: Settings Persist Across Restart
**Purpose**: Verify notification preferences survive app restart

**Steps**:
1. Configure notifications:
   - Enable toggle
   - Set reminder to "2 hours before"
2. Force quit app
3. Relaunch app
4. Go to Settings → Notifications

**Expected Results**:
- ✅ Toggle state: ON (persisted)
- ✅ Reminder timing: "2 hours before" (persisted)
- ✅ Authorization status correct

**Verification**:
```
After restart:
- All settings match pre-restart state
- No reset to defaults
```

---

### Test 6.2: Notifications Survive Device Restart
**Purpose**: Verify scheduled notifications persist across device reboot

**Steps**:
1. Enable notifications with schedule
2. Restart device (power off and on)
3. Wait for next scheduled notification time

**Expected Results**:
- ✅ Notification still delivers after device restart
- ✅ Notification queue rebuilt correctly
- ✅ No duplicate notifications

---

## Test Scenario 7: Accessibility

### Test 7.1: VoiceOver Support
**Purpose**: Verify full accessibility support

**Steps**:
1. Enable VoiceOver: Settings → Accessibility → VoiceOver → ON
2. Navigate to Settings tab → Notifications
3. Test each element with VoiceOver

**Expected Results**:
- ✅ "Dose Reminders" toggle announces state ("enabled" or "disabled")
- ✅ Reminder timing picker readable
- ✅ Authorization status card has descriptive label
- ✅ "Settings" button has label: "Open iOS Settings to enable notifications"

---

## Troubleshooting

### Notifications Not Appearing

**Check**:
1. iOS Settings → Notifications → JabTracker → Allow Notifications: ON
2. iOS Settings → Notifications → JabTracker → Sounds: ON
3. Device not in Do Not Disturb mode
4. Scheduled dose time is in future
5. Reminder offset doesn't push notification into past
6. App Settings → Notifications toggle: ON

**Debug**:
```
Xcode Console Output:
- Look for: "Scheduled notification for dose at <time>"
- Check for: "Notification authorization status: authorized"
- Errors: "Failed to schedule notification: <error>"
```

---

### Deeplinks Not Working

**Check**:
1. URL scheme registered: `jab-tracker://`
2. Info.plist has CFBundleURLTypes
3. Notification contains deeplink in userInfo

**Debug**:
```
Xcode Console:
- Look for: "Handling deeplink: <URL>"
- Check for parsing errors
- Verify scheduledDoseId in URL
```

---

### Toggle Not Responding

**Check**:
1. NotificationService initialized
2. AppServices.shared.initialize() called
3. ModelContext available

**Debug**:
```
Xcode Console:
- Look for: "NotificationService.enable() called"
- Check for authorization errors
- Verify state persistence
```

---

## Success Criteria

All tests passing means:
- ✅ Notifications can be enabled/disabled from Settings
- ✅ Reminder timing configurable (15/30/60/120 minutes)
- ✅ Actual notifications delivered to device
- ✅ Notification actions work (Take/Skip/Snooze)
- ✅ Deeplinks open app correctly
- ✅ Settings persist across app/device restarts
- ✅ Permission edge cases handled gracefully
- ✅ Full VoiceOver accessibility support

---

## Recording Test Results

Create a checklist:
```
Test Scenario 1: Onboarding
- [ ] 1.1: Grant during onboarding
- [ ] 1.2: Deny during onboarding

Test Scenario 2: Settings Configuration
- [ ] 2.1: Enable via Settings
- [ ] 2.2: Change reminder timing
- [ ] 2.3: Disable via Settings

Test Scenario 3: Notification Delivery
- [ ] 3.1: Receive notification
- [ ] 3.2: Take Dose action
- [ ] 3.3: Skip action
- [ ] 3.4: Snooze action

Test Scenario 4: Deeplinks
- [ ] 4.1: From background
- [ ] 4.2: From terminated

Test Scenario 5: Permission Edge Cases
- [ ] 5.1: Denied in iOS Settings
- [ ] 5.2: Re-enable after denial

Test Scenario 6: Persistence
- [ ] 6.1: Settings persist across restart
- [ ] 6.2: Notifications survive device restart

Test Scenario 7: Accessibility
- [ ] 7.1: VoiceOver support
```

Report any failures with:
- Device model and iOS version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/screen recordings if applicable
- Xcode console logs
