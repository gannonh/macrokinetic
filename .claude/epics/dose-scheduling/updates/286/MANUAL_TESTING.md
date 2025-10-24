# Manual Testing Guide for Issue #286: Titration Completion Workflow

## Overview

This guide explains how to manually test the titration completion workflow implemented in Issue #286. The workflow includes warning banners, confirmation dialogs, manual completion buttons, and notifications.

## Setup

### 1. Generate Xcode Project with Test Data Flag

The `--test-titration-data` launch argument is already configured in `project.yml` (line 95).

```bash
xcodegen generate
```

### 2. Build and Run in Xcode

1. Open `JabTracker.xcodeproj` in Xcode
2. Select a simulator (iPhone 15 recommended)
3. Build and run (Cmd+R)
4. The app will automatically seed test data on launch

### 3. Verify Test Data Seeded

Check the Xcode console for confirmation:

```
🌱 Seeding titration test data...
✅ Titration test data seeded successfully!
   - User: test-titration@example.com
   - Medication: Ozempic 1.0mg
   - Completed dose: Yesterday
   - Titration TODAY: 1.0mg → 2.0mg (will trigger dialog)
   - Titration TOMORROW: 2.0mg → 3.0mg (warning banner)
   - Titration +7 days: 3.0mg → 4.0mg (warning banner)
```

## Test Scenarios

### Stream A: Warning Banner Integration (AC1-AC4)

**Test 1: Warning Banner Displays for Upcoming Titration**
1. Navigate to Settings tab
2. Tap on medication profile (Ozempic)
3. Scroll to "Schedule" section
4. **Expected**: Warning banner visible with message: "Your dose will increase to 2.0mg on [tomorrow's date] per your titration plan"

**Test 2: Tapping Warning Banner Navigates to Titration Plan**
1. From Settings > Medication Profile
2. Tap the warning banner
3. **Expected**: Navigates to "Dose Escalation Plan" screen showing:
   - Current Dose: 1.00 mg
   - Escalation Timeline with scheduled titrations
   - "Complete" button for tomorrow's titration

### Stream B: Dose Entry Confirmation Dialog (AC5-AC10)

**Test 3: Dialog Appears When Logging Dose on Titration Date**
1. Navigate to Dashboard (home tab)
2. Tap "+" button to add dose
3. **Expected**: TitrationConfirmationDialog appears automatically showing:
   - Title: "Dose Increase Scheduled"
   - Current dose: 1.0mg
   - New dose: 2.0mg
   - Scheduled date: Today
   - Three buttons: "Complete Now", "Reschedule", "Remind Me Later"

**Test 4: "Complete Now" Action**
1. In the dialog, tap "Complete Now"
2. **Expected**:
   - Dialog dismisses
   - QuickDoseSheet shows with amount pre-filled to 2.0mg (new dose)
   - Complete the dose entry
   - Navigate to Settings > Medication Profile
   - Verify titration marked as completed
   - Verify currentDose updated to 2.0mg

**Test 5: "Reschedule" Action**
1. Tap "+" button again (if needed, tap "Remind Me Later" first to re-trigger)
2. In dialog, tap "Reschedule"
3. **Expected**:
   - Date picker appears
   - Select a new date (e.g., 3 days from now)
   - Tap "Save"
   - Navigate to Settings > Dose Escalation Plan
   - Verify titration date updated

**Test 6: "Remind Me Later" Action**
1. Tap "+" button to trigger dialog
2. Tap "Remind Me Later"
3. **Expected**:
   - Dialog dismisses immediately
   - QuickDoseSheet shows with current dose (1.0mg)
   - Complete dose entry
   - Tap "+" button again
   - Dialog should appear again (remind later flag reset after dose)

### Stream C: Manual Completion Button Updates (AC11-AC13)

**Test 7: Complete Button Works Before Scheduled Date**
1. Navigate to Settings > Medication Profile > Dose Escalation Plan
2. View the titration scheduled for tomorrow (2.0mg → 3.0mg)
3. **Expected**:
   - "Complete" button is visible and enabled
   - Tap button
   - Titration marked as completed early
   - CurrentDose updated to 3.0mg

**Test 8: Complete Button Hidden After Scheduled Date**
1. For titrations scheduled in the past (test by setting system date forward if needed)
2. Navigate to Dose Escalation Plan
3. **Expected**:
   - "Complete" button is hidden/disabled for past titrations
   - Message shown: "Use dose entry to complete this titration"

### Stream D: Notification Integration (AC14-AC15)

**Test 9: Titration Notification Sent**
1. Ensure notifications are enabled (Settings > Notifications)
2. Wait for or simulate titration date arrival
3. **Expected**:
   - Notification appears with title indicating dose increase
   - Body shows: "Time to increase your dose from 1.0mg to 2.0mg"
   - Three notification actions visible

**Test 10: Notification Actions**
1. From notification, tap "Complete" action
2. **Expected**: App opens, titration marked complete, dose updated
3. From notification, tap "Reschedule" action
4. **Expected**: App opens to date picker for rescheduling
5. From notification, tap "Remind Later" action
6. **Expected**: Notification dismissed, reminder scheduled for 1 hour later

## Acceptance Criteria Checklist

### Stream A (AC1-AC4)
- [ ] AC1: Warning banner displays when titration within 30 days
- [ ] AC2: Banner shows correct message format with dose and date
- [ ] AC3: Tapping banner navigates to Dose Titration Plan
- [ ] AC4: Warning uses getTitrationWarning() method (verified via code)

### Stream B (AC5-AC10)
- [ ] AC5: Dialog appears when logging dose on/after titration date
- [ ] AC6: Dialog shows correct title and dose amounts
- [ ] AC7: "Complete Now" marks titration completed and updates currentDose
- [ ] AC8: "Complete Now" uses new dose amount for current entry
- [ ] AC9: "Reschedule" opens date picker and updates date
- [ ] AC10: "Remind Me Later" dismisses and prompts again next time

### Stream C (AC11-AC13)
- [ ] AC11: "Complete" button works for early completion
- [ ] AC12: Button disables/hides after scheduled date
- [ ] AC13: Screen shows "Use dose entry" message after date

### Stream D (AC14-AC15)
- [ ] AC14: Notification sent on titration date
- [ ] AC15: Notification actions work correctly

## Troubleshooting

### Test Data Not Appearing
- Verify `--test-titration-data` flag is enabled in project.yml
- Run `xcodegen generate` to regenerate project
- Check console for seed confirmation message
- If data exists, delete app and reinstall

### Dialog Not Appearing
- Verify you have a dose from yesterday (test data includes this)
- Check that titration is scheduled for today
- Ensure titration is not already completed

### Warning Banner Not Showing
- Navigate to Settings > Medication Profile (not just Settings)
- Verify titrations scheduled within 30 days exist
- Check console for getTitrationWarning() calls

### Notifications Not Appearing
- Enable notifications in iOS Settings > JabTracker
- Grant notification permission when prompted
- Check notification queue in code (developers only)

## Clean Up

To reset test data:
1. Delete app from simulator
2. Reinstall with `xcodegen generate` and run again
3. New test data will be seeded on next launch

## Notes

- Test data is seeded only once per app installation
- Titration dates are relative to current date (today, tomorrow, +7 days)
- If you need to test past titrations, temporarily modify seeding dates in `DataController.swift`
- All manual testing should be documented in the acceptance criteria checklist above
