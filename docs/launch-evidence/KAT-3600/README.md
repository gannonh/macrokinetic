# KAT-3600: weekly dose totals stay literal around split dosing

Contract found in the code: a profile's `currentDose` is the weekly total (the split factory divides `totalWeeklyDose` by 2, and Quick Dose shows half the profile dose for a split schedule). A split schedule stores the amount of ONE administration. `DoseScheduleEditView` saved the full profile dose as that amount, so a 5 mg weekly schedule edited to split projected two 5 mg administrations (10 mg per week).

Chosen path: fix (the contract is unambiguous and the change touches two production files plus a test seed switch). The launch build already cannot switch a weekly schedule to split (KAT-3581 closes the picker and save path while `medicalCalculators` is off); the fix makes the split branch correct for when it is reopened and makes recorded split schedules state their amounts and return to weekly at the weekly total.

Tests (Debug, iOS 27.0 simulator): `SplitDoseWeeklyTotalTests` 6 of 6 pass (literal 2.5 per administration, 5.0 per week, 84-hour spacing, revert to 5.0); `SplitDoseTotalsUITests` 2 of 2 pass.

## Live scenarios (integrated "iPhone 18 Pro", fictional seeded data: Ozempic 5 mg weekly)

Driver: `SplitDoseLive.swift.txt` (an XCUITest, not part of the target). Raw notes: `live/main-results.txt`, `live/branch-results.txt`. Video: `live/kat-3600-main-vs-branch-review.mp4` (55 s, 3.6x speed of a 198 s run of scenario 1 on main plus scenarios 2 and 3 on the branch). The integrated simulator's host recorder was already in use ("Host recording is already in progress"), so the video was recorded on a cloned iPhone 18 Pro simulator running the same build and driver. The screenshots are from the integrated simulator.

| # | Scenario | Result |
| --- | --- | --- |
| 1 | Weekly 5 mg profile, edit schedule, on main and on the branch | Main offers Split Dose; after saving, the calendar shows 5.00 mg on each of two administrations per week (days 5, 8, 12, 15, 19, 22, 26, 29), 10 mg per week. Branch: Split Dose is not offered; the weekly schedule keeps 5.00 mg (days 8, 15, 22, 29). `s01-*` |
| 2 | Branch weekly editor | Daily and Weekly only, no Split Dose, no Recorded Split Schedule, no split amounts; Current Dose 5.00 mg. `s02-*` |
| 3 | Branch, existing recorded split schedule (2.5 per administration) | Editor shows Per administration 2.50 mg, Administrations per week 2, Weekly total 5.00 mg. `s03-*` |
| 4 | Branch, revert the recorded split to Weekly and save | Split amounts disappear; calendar shows one 5.00 mg administration per week. `s04-*` |
| 5 | Branch, recorded split schedule in the calendar | Eight 2.50 mg administrations in October (days 5, 8, 12, 15, 19, 22, 26, 29), 5 mg per week. `s05-*` |
| 6 | Branch, pause and resume the split schedule | Amounts afterwards: 2.50 mg per administration, 5.00 mg weekly total. `s06-*` |
| 7 | Branch, past recorded dose when the schedule is switched to weekly | The recorded dose history reads 5.00 mg before and after. `s07-*` |
| 8 | Branch, Quick Dose for a split profile | An explicit amount is required; recording 2.5 reads back as 2.50 mg in History next to the earlier 5.00 mg. `s08-*` |
| 9 | Branch, relaunch without reset | Split schedule persists: 2.50 mg per administration, 5.00 mg weekly total. `s09-*` |
| 10 | Branch, daily then weekly | Daily saves and projects 5.00 mg each day; no split section. See the observation below. `s10-*` |

## Observation outside this ticket

Switching a saved Daily schedule to Weekly keeps the 1-day interval in the Interval stepper, so the "Weekly" schedule still projects every day until the stepper is set to 7 (scenario 10, `s10-branch-weekly-again-calendar.png`). This is existing behavior of the weekly branch (`interval` state is read from the saved config). It is not part of this change.

Split projections step by 3.5 days in absolute time, so the local reminder time moves by one hour across a daylight saving change. The count and amounts do not change. Not changed here.

Not covered: real notification delivery; a signed-device run. The unit test asserts projected scheduled amounts, which feed reminders.
