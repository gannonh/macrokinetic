# Nutrition-only logging, literal totals and relaunch persistence (KAT-3587)

Three UI journeys in `JabTrackerUITests/Nutrition/NutritionLaunchUITests.swift` log a known food, check literal values in the Food Log and Dashboard, edit, delete, clear a day and relaunch without reset or seed. Plan, selectors and disk-identity procedure: [`docs/nutrition-launch-verification.md`](../../nutrition-launch-verification.md).

**Database: the 22-food CI fixture only** (sha256 `9934b5294e5b8e476f955c9c4e183a25fe299d9d2f17dda94340feba78422a18`; Salmon, Atlantic, raw = 208 kcal / 20P / 13F / 0C per 100 g). Nothing here is production-database or offline acceptance. Base: PR #370 (KAT-3598) at 86bd51d5; this branch adds only UI tests, the regenerated project file and docs, so the app source equals #370.

## Results

| Run | Where | Result |
| --- | --- | --- |
| `NutritionLaunchUITests` (3 tests), Debug | clone simulator, iOS 27 | 3 passed, 0 failed, 0 skipped |
| Same 3 tests, with the SwiftData store sampled every 0.4 s | clone simulator | 3 passed; identity result below |
| Same 3 tests | integrated simulator (iPhone 18 Pro, iOS 27) | 3 passed, 0 failed, 0 skipped |
| Full `JabTrackerUnitTests` | clone simulator, on the #370 source | 3065 passed, 2 failed, 1 skipped (see KAT-3598 evidence; the 2 failures are `NotificationServiceActionTests` titration cases, environmental) |

Debug-first note: the first run failed in setup with "Navigate to the selected date's week". The captured hierarchy showed that the Food Log day cells and week buttons carry the container identifier `week-calendar-strip`, so the `food-day-N` and `week-calendar-previous/next` selectors never matched. The tests now find days by accessibility label and the buttons by label, with no change to application code.

## Ten scenarios (live: integrated simulator, XCUITest-driven)

| # | Scenario | Result | Evidence |
| --- | --- | --- | --- |
| 1 | Known-food logging, main vs branch | Main opens a blank detail sheet and cannot log the food; the branch logs it. The new journeys were not run on main because main cannot open the sheet. | `live-s1-main-blank-sheet-known-food.png`, `live-s1-branch-known-food-detail.png` |
| 2 | Nutrition-only profile | Pass: fictional UI-testing user, "No medication profiles yet", and zero MedicationProfile and Dose rows in every store snapshot. This is not the real onboarding flow (KAT-3588). | `live-s2-no-medication-profiles.jpg`, `disk-identity-snapshots.txt` |
| 3 | Known serving gives exact macros | Pass: 200 g = 416/40/26/0, 100 g = 208/20/13/0 in detail, row and totals | `live-s3-s4-breakfast-416-selected-day.jpg` |
| 4 | Selected meal and date | Pass: Breakfast and Lunch rows on today, yesterday's row on yesterday; meal header, row label, day-cell entry count asserted | `live-s3-s4-breakfast-416-selected-day.jpg`, `live-s8-clear-day-two-entries.jpg` |
| 5 | Dashboard totals match | Pass: 416/40/26/0 and 624/60/39/0 on the four rings; yesterday not counted | `live-s5-dashboard-416-40-26-0.jpg`, `live-s5-dashboard-624-60-39-0.jpg`, `checkpoint-dashboard-*.png` |
| 6 | Edit updates exact macros | Pass: 200 g to 100 g leaves one 208/20/13/0 row; canceled edit to 200 g changes nothing | `live-s6-edit-saved-208-20-13-0.jpg` |
| 7 | Cancel deletion preserves the record | Pass by assertion (alert names the food; row, count and totals unchanged after Cancel); no separate screenshot | timelapse `live-edit-delete-retain-other-day-timelapse.mp4` |
| 8 | Delete and clear-day preserve other dates | Pass: delete leaves today at 0 and yesterday's 208 row; clear-day alert and menu name exactly 2 items, Cancel keeps both, Clear Day removes only today | `live-s8-*.jpg` |
| 9 | Relaunch preserves the record | Pass: no reset/seed arguments, same row and totals on Food Log and Dashboard | `live-s9-relaunch-log-416.jpg`, `checkpoint-dashboard-after-relaunch.png` |
| 10 | Production database works offline | **NOT RUN** (see gaps) | none |

Videos are screenshot timelapses of the live runs (about 4.5x to 7x real speed, 55 to 58 s) because the simulator's host recorder was busy: `live-nutrition-only-totals-relaunch-review-timelapse.mp4` (journey 1), `live-edit-delete-retain-other-day-timelapse.mp4` (journey 2), `live-clear-day-retain-other-day-timelapse.mp4` (journey 3).

## Record identity on disk (clone simulator, fixture)

`disk-identity-snapshots.txt` lists every distinct state of the SwiftData store (`default.store` plus WAL) seen while the tests ran; each line is the entries (UUID, food, grams, meal, logged-at UTC, kcal per 100 g), the user count and UUID, and MedicationProfile and Dose counts. Findings:

- Every snapshot has at most one User, zero MedicationProfile and zero Dose rows.
- Journey 1: one entry (`5B918A8D...`, 200 g Breakfast) and one User (`7E16FF33...`) are identical before and after the no-reset relaunch.
- Journey 2: yesterday's entry `4A04DD51...` (100 g) and today's `78A414D0...` (200 g). The edit changes the same UUID `78A414D0...` to 100 g; deletion removes only `78A414D0...`; `4A04DD51...` is unchanged through the delete and the relaunch.
- Journey 3: yesterday `0AE19337...`, today `F73F534F...` (100 g Breakfast) and `66E97B18...` (200 g Lunch). Clear Day removes exactly the two of today; `0AE19337...` stays through the relaunch.
- Canceled edit and canceled delete produce no store change, since no intermediate state appears in the list.

## Gaps against the written acceptance criteria

- **Offline production database (AC3, scenario 10): not done.** It needs the full database artifact and an isolated device or app-level network block; the host network cannot be interrupted from here. Source evidence only: the food search, log and service path has no network client (`grep` for URLSession, NWPathMonitor and "offline" finds nothing in the nutrition services).
- **Production-database evidence (AC4):** none; all values are fixture values and labelled so.
- **Date choice:** dates are chosen by selecting a day in the Food Log before adding; the search sheet's own time picker is not exercised.
- **Real onboarding** is not part of this slice (KAT-3588).
- **Disk UUID identity** ran on the clone simulator, not the integrated one, and by sampling rather than a before/after export.
