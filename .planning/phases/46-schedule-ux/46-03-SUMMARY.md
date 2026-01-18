---
phase: 46
plan: 03
subsystem: nutrition-ui
tags: [swiftui, food-schedule, library, tabs]
dependency-graph:
  requires: [46-01]
  provides: [scheduled-tab, schedule-list-view, schedule-edit-flow]
  affects: []
tech-stack:
  added: []
  patterns: [tab-content-switching, wrapper-view-pattern]
key-files:
  created: []
  modified:
    - JabTracker/Models/LibraryTab.swift
    - JabTracker/Views/Nutrition/FoodLibraryContentView.swift
decisions:
  - id: scheduled-tab-position
    choice: "Add .scheduled after .foods in enum order"
    reason: "Logical grouping - foods then scheduled foods"
  - id: wrapper-view-pattern
    choice: "ScheduleEditSheetWrapper to load Food before presenting sheet"
    reason: "ScheduleConfigSheet requires Food model, schedule only has foodId reference"
  - id: placeholder-food-creation
    choice: "Create Food from FoodSchedule denormalized data if custom food not found"
    reason: "Handle case where original custom food was deleted but schedule remains"
metrics:
  duration: 6min
  completed: 2026-01-18
---

# Phase 46 Plan 03: Scheduled Tab Summary

Food Library "Scheduled" tab showing all active food schedules with edit/stop actions.

## What Was Built

### LibraryTab.swift
- Added `.scheduled` case to LibraryTab enum
- Added "Scheduled" display name
- Enabled `.scheduled` tab (alongside `.foods`)

### FoodLibraryContentView.swift
- Added `scheduledFoods` and `selectedScheduleForEdit` state
- Added tab content switching for `.scheduled` tab
- Added `scheduledTabContent` with header, list, and empty state
- Added `scheduledFoodRow` showing:
  - Calendar icon in purple
  - Food name and brand
  - Schedule summary (days and meals)
  - Serving info (grams and description)
  - Chevron disclosure indicator
- Added `scheduleSummary(for:)` helper with smart grouping:
  - "Every day" for 7 days
  - "Weekdays" for Mon-Fri
  - "Weekends" for Sat-Sun
  - Comma-separated day abbreviations otherwise
- Added "Stop" swipe action to delete schedules
- Added `ScheduleEditSheetWrapper` view to:
  - Load Food model from CustomFoodService
  - Create placeholder Food from schedule data if not found
  - Present ScheduleConfigSheet with existing schedule pre-populated

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Tab position | After .foods | Logical grouping of food-related tabs |
| Wrapper pattern | ScheduleEditSheetWrapper | ScheduleConfigSheet needs Food, schedule has foodId |
| Placeholder food | Create from schedule data | Handle deleted custom food edge case |
| Schedule summary | Smart day grouping | Better UX than always showing 7 abbreviations |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Food initializer mismatch**
- **Found during:** Task 2 implementation
- **Issue:** Plan specified `id:` parameter in Food init which doesn't exist
- **Fix:** Used standard init then set `placeholder.id = schedule.foodId`
- **Files modified:** FoodLibraryContentView.swift
- **Commit:** 39bb6898

## Verification Results

- [x] Build succeeds
- [x] Food Library shows "Scheduled" tab button that is tappable
- [x] Scheduled tab shows list of foods with active schedules
- [x] Each row shows food name, schedule summary, serving info
- [x] Tapping scheduled food opens ScheduleConfigSheet for editing
- [x] Swiping reveals "Stop" action to delete schedule
- [x] Empty state shows when no foods are scheduled

## Commits

| Hash | Description |
|------|-------------|
| c24496fe | feat(46-03): add scheduled case to LibraryTab |
| 39bb6898 | feat(46-03): implement Scheduled tab in Food Library |

## Next Phase Readiness

Phase 46 is complete. All three plans executed:
- 46-01: Schedule UI foundation (ScheduleDayMealGrid, ScheduleConfigSheet)
- 46-02: Food Library swipe actions (Schedule swipe action)
- 46-03: Scheduled tab (this plan)

Ready for Phase 47 or release testing.
