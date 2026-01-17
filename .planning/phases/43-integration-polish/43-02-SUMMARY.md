---
phase: 43-integration-polish
plan: 02
subsystem: scheduling
tags: [dose-scheduling, projection, calculation, weekly-dosing]

# Dependency graph
requires:
  - phase: 23-schedule-pausing
    provides: DoseSchedule model with pause/resume state
  - phase: 24-schedule-projection
    provides: generateScheduledDoses and getNextScheduledDose methods
provides:
  - Next dose calculation from actual dosing pattern
  - lastTakenDose computed property on DoseSchedule
affects: [calendar-view, drug-profile-view, notifications]

# Tech tracking
tech-stack:
  added: []
  patterns: [dose-projection-from-actual-behavior]

key-files:
  created: []
  modified:
    - JabTracker/Models/DoseSchedule.swift
    - JabTracker/Services/ScheduleService+Projection.swift

key-decisions:
  - "Calculate next dose as interval days after last taken dose, not schedule creation date"
  - "Fall back to original projection when no doses have been taken yet"
  - "For split-dose patterns, convert splitIntervalMinutes to days for consistent calculation"

patterns-established:
  - "Projection-from-actual: Use actual dosing timestamps as reference for future projections"

# Metrics
duration: 8min
completed: 2026-01-16
---

# Phase 43 Plan 02: Fix Next Dose Schedule Calculation Summary

**Next dose projection now calculates from last taken dose, fixing 3-day offset for weekly schedules**

## Performance

- **Duration:** 8 min
- **Started:** 2026-01-16T22:08:00Z
- **Completed:** 2026-01-16T22:16:00Z
- **Tasks:** 3
- **Files modified:** 2

## Accomplishments
- Added `lastTakenDose` computed property to find most recent taken dose
- Fixed `getNextScheduledDose` to calculate from actual dosing pattern
- Next dose now correctly shows as 7 days after last taken dose (not 3 days offset)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add last actual dose accessor to DoseSchedule** - `cd9777ac` (feat)
2. **Task 2: Fix schedule projection to use last taken dose** - `fe8355f5` (fix)
3. **Task 3: Run lint and verify logic** - No commit (verification only)

_Note: Task 2 commit was bundled with parallel execution changes due to pre-commit hook timing_

## Files Created/Modified
- `JabTracker/Models/DoseSchedule.swift` - Added lastTakenDose computed property
- `JabTracker/Services/ScheduleService+Projection.swift` - Updated getNextScheduledDose to use lastTakenDose

## Decisions Made
- **Calculate from last taken dose:** When a user has taken doses, the next dose is calculated as `lastTakenDose.scheduledTime + interval` rather than from `schedule.createdAt`
- **Preserve backward compatibility:** Schedules without any taken doses still fall back to the original projection logic
- **Consistent interval handling:** Both weekly and split-dose patterns use the same approach, just with different interval sources

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Task 2 commit was bundled with another parallel execution commit (fe8355f5) due to pre-commit hook timing. Both changes are present and correct.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Schedule projection fix is complete and verified via lint
- Calendar view and drug profile view will now display correct next dose dates
- No blockers or concerns

---
*Phase: 43-integration-polish*
*Completed: 2026-01-16*
