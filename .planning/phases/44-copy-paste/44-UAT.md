---
status: complete
phase: 44-copy-paste
source: 44-01-SUMMARY.md, 44-02-SUMMARY.md
started: 2026-01-17T21:30:00Z
updated: 2026-01-17T21:40:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Copy Day via Context Menu
expected: Long-press macro summary card shows context menu with "Copy Day" option. Tapping copies all foods from that day.
result: pass

### 2. Copy Meal via Context Menu
expected: Long-press a meal section header (e.g., "Breakfast") shows context menu with "Copy Meal" option. Tapping copies all foods from that meal.
result: pass

### 3. Copy via Segmented Control
expected: Segmented control appears in header toolbar (next to + button) when there's content to copy. Tapping shows copy options (day/meal).
result: pass

### 4. Paste to Empty Day with Add Mode
expected: Navigate to a day with no food entries. Use paste option. Food entries appear immediately without confirmation dialog.
result: pass

### 5. Paste with Replace Existing
expected: Navigate to a day that has food entries. Use paste option. Confirmation dialog shows "Add to Existing" and "Replace Existing". Tap "Replace Existing". Old entries removed, clipboard entries appear.
result: pass

### 6. Paste with Add to Existing
expected: Navigate to a day that has food entries. Use paste option. Confirmation dialog appears. Tap "Add to Existing". Clipboard entries added without removing existing entries.
result: issue
reported: "fail due to minor ux issue (that i still want to fix): When using the paste button the confirmation dialog is near the bottom of the view, no where near the button. Should be higher up in the ui when pasting from the button. Context menu pasting dialog is fine"
severity: minor

### 7. Clipboard Persists Across Navigation
expected: Copy a day or meal, navigate to a different date, paste is still available. Navigate to Food Library and back, paste still available.
result: pass

### 8. New Copy Replaces Clipboard
expected: Copy a meal with 2 items. Copy a different day with 5 items. Paste - should paste 5 items (from the day), not 2 (the earlier meal copy is replaced).
result: pass

## Summary

total: 8
passed: 7
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "Paste confirmation dialog appears near the paste button in header toolbar"
  status: failed
  reason: "User reported: When using the paste button the confirmation dialog is near the bottom of the view, no where near the button. Should be higher up in the ui when pasting from the button. Context menu pasting dialog is fine"
  severity: minor
  test: 6
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
