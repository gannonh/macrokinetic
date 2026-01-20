# Requirements: v0.10.1 Food Log Polish

Minor polish release addressing UI refinements in the Food Log.

---

## FLOG: Food Log Refinements

### FLOG-01: Clear Day Context Menu
**Priority:** P1
**Type:** Feature

Add a "Clear Day" option to the Food Log context menu that allows users to delete all food entries for the selected day in a single action.

**Acceptance Criteria:**
- [ ] Long-press on Food Log shows "Clear Day" option in context menu
- [ ] Selecting "Clear Day" shows confirmation dialog before deletion
- [ ] Confirmation dialog shows count of entries to be deleted
- [ ] All food entries for that day are deleted upon confirmation
- [ ] Operation is cancellable via dialog dismiss

---

### FLOG-02: Delete Button Color
**Priority:** P1
**Type:** Bug Fix

Fix the swipe-to-delete action button color from teal to red to match iOS destructive action conventions.

**Acceptance Criteria:**
- [ ] Swipe-to-delete button uses red background color
- [ ] Matches iOS system destructive action styling

---

### FLOG-03: Calendar Week Start
**Priority:** P1
**Type:** Feature

Change the Food Log weekly calendar to start on Monday instead of Sunday, aligning with the Weekly Nutrition Hero and other weekly views in the app.

**Acceptance Criteria:**
- [ ] Food Log calendar shows Monday as first day of week
- [ ] Week boundaries match Weekly Nutrition Hero (Mon-Sun)
- [ ] Navigation between weeks works correctly with new start day

---

## Requirements Coverage

| REQ-ID | Description | Phase |
|--------|-------------|-------|
| FLOG-01 | Clear Day Context Menu | 48 |
| FLOG-02 | Delete Button Color | 48 |
| FLOG-03 | Calendar Week Start | 48 |

**Total:** 3 requirements
**Coverage:** 100% mapped to phases
