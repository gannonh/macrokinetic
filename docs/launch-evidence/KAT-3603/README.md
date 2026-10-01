# KAT-3603 evidence: dose streaks and weight trends across month boundaries

Run on Thu Oct 1 2026 (the 1st of a month; yesterday = Sep 30). Integrated simulator "iPhone 18 Pro" (iOS 27), Debug builds.
`main` = c6824713, branch = ce9d3540. Flow for streak shots: More > GLP-1 Programs > Adherence ("Dose Streaks" card).
Doses were seeded with the existing `TEST_DATA_*` launch environment (daily liraglutide, one dose per day ending now, no timing variability), so yesterday and today straddle Sep 30 / Oct 1.
Weight shots: `--seed-test-1y-high` (seed 789, one weigh-in per day for 365 days), Dashboard > Weight Trend.

## Findings

- The month-bound streak was in `DoseCalendarViewModel` (monthly statistics), which no screen uses today. The on-screen "Dose Streaks" card reads `User.currentStreak`, which was already correct across months. Scenario 1 therefore shows 2 days on both main and branch.
- The weight window bug is visible on screen: on main, the 1M window drops the entry that is exactly one month old (Sep 1), because the window began at "now minus one month" to the second.
- Not fixed (out of AC): `AdherenceStatisticsCalculator.calculateInternal` filters `<= periodEnd`, so a dose at exactly 00:00 on the 1st counts in the previous period if a caller passes the raw month end. `DoseCalendarViewModel` already filters `< end`, so nothing is affected today.

## Window contract

`DetailTimePeriod.startDate(now:calendar:)`: calendar units back from `now` (1M on Mar 1 starts Feb 1, not 30 days back), anchored to the start of that day, so an entry exactly one period old is always inside the window. Applies to 1M to 1Y; 1W is today plus the previous 6 days (7 dates).

## Live scenarios (10)

| # | Build | Setup | Result | Screenshot |
|---|---|---|---|---|
| 1 | main and branch | 2 daily doses (Sep 30, Oct 1) | Current 2 days, best 2 days on both | screenshots/s01-main-streak-2-days-oct1.png, s01-branch-streak-2-days-oct1.png |
| 2 | branch | 5 daily doses (Sep 27 to Oct 1) | 5 days | s02-branch-5-day-streak.png |
| 3 | branch | 31 daily doses (Sep 1 to Oct 1) | 31 days | s03-branch-31-day-streak-across-month.png |
| 4 | branch | 1 dose today | 1 day | s04-branch-1-day-streak.png |
| 5 | branch | weekly semaglutide, 3 doses | 1 day (day-streak semantics unchanged) | s05-branch-weekly-3-doses.png |
| 6 | branch | weight 1M | Sep 1 - Oct 1, difference -0.8 lbs (Sep 1 entry included) | s06-branch-weight-1M.png |
| 7 | main | weight 1M, same seed | Sep 2 - Oct 1, difference -2.2 lbs (Sep 1 entry dropped) | s07-main-weight-1M.png |
| 8 | main and branch | weight 1W | main Sep 25 - Oct 1; branch Sep 24 - Oct 1 (captured at 0f41b13d, before the 1W fix below; 1W now starts Sep 25 on both) | s08-*-weight-1W.png |
| 9 | main and branch | weight 3M | main Jul 2 - Oct 1; branch Jul 1 - Oct 1 | s09-*-weight-3M.png |
| 10 | branch | weight 6M | Apr 1 - Oct 1, difference -5.8 lbs | s10-branch-weight-6M.png |

## Video

`KAT-3603-branch-live-session.mp4` (59 s): branch build, 2-dose and 31-dose streaks, then weight 1M/1W/3M. The integrated simulator reported "Host recording is already in progress" for `simctl io recordVideo` and `agent-device record`, so the video is encoded from `simctl io screenshot` frames captured during the live session (about 2.5 fps).

## Unit tests

- Before the fix, on main at c6824713 on Oct 1 (local): `currentStreakDisplayFormatting` ("1 day (active)") and `testCalculatesCurrentWeightAndDifference` (`difference` nil) fail. See logs/main-before-fix-failures.txt.
- After the fix, targeted classes (DoseCalendarViewModelTests, WeightTrendDetailViewModelTests, DoseDefaultsTests, AdherenceStatisticsTests): 96 passed, 0 failed.
- Full JabTrackerUnitTests on the final sources: 3077 tests, 3074 passed, 1 skipped, 2 failed. The 2 failures are `NotificationServiceActionTests` titration cases (`UNAuthorizationStatus` denied on cloned simulators), known environmental noise. See logs/unit-results.txt.
- The affected tests use `FixedClock` (UTC calendar) with literal expectations: Sep 30 + Oct 1 = "2 days (active)"; Dec 30 to Jan 1 = "3 days (active)"; Feb 28 + Mar 1 = 2 with February or January displayed; Mar 1 1M window = Feb 1 included, Jan 31 excluded (difference -2.0); Jan 1 1M window starts Dec 1 (difference -3.0); Mar 31 1M start = Feb 28 00:00; doses at 23:59 and 00:01 UTC land in different days and months; a dose at exactly 00:00 counts for the new day only.
