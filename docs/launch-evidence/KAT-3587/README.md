# Nutrition-only logging, literal totals and relaunch persistence (KAT-3587)

Three UI journeys in `JabTrackerUITests/Nutrition/NutritionLaunchUITests.swift` log a known food, check literal values in the Food Log and Dashboard, edit, delete, clear a day and relaunch without reset or seed. Plan, selectors and disk-identity procedure: [`docs/nutrition-launch-verification.md`](../../nutrition-launch-verification.md).

**Database: the 22-food CI fixture for scenarios 1 to 9; the full production database for scenario 10 only** (sha256 `9934b5294e5b8e476f955c9c4e183a25fe299d9d2f17dda94340feba78422a18`; Salmon, Atlantic, raw = 208 kcal / 20P / 13F / 0C per 100 g). The production-database run is described under scenario 10. Base: PR #370 (KAT-3598) at 86bd51d5; this branch adds only UI tests, the regenerated project file and docs, so the app source equals #370.

## Results

| Run | Where | Result |
| --- | --- | --- |
| `NutritionLaunchUITests` class, Debug, fixture database | clone simulator, iOS 27 | 3 journeys passed, 0 failed; the production-database test is skipped there with its explicit message (no production variables) |
| Same 3 tests, with the SwiftData store sampled every 0.4 s | clone simulator | 3 passed; identity result below |
| Same 3 tests | integrated simulator (iPhone 18 Pro, iOS 27) | 3 passed, 0 failed, 0 skipped |
| `testProductionDatabaseJourneyWithDatabaseValues`, full production database | clone simulator, Debug | 1 passed, 0 failed, 0 skipped, with the network sampler running (final commit) |
| Full `JabTrackerUnitTests` | clone simulator, on the #370 source | 3065 passed, 2 failed, 1 skipped (see KAT-3598 evidence; the 2 failures are `NotificationServiceActionTests` titration cases, environmental) |

Selector and timing notes: the Dashboard and Food Log value checks use one predicate query instead of enumerating every element, and bounded waits are 15 s because single accessibility queries took more than 4 s each while the shared host load average was above 100. The earlier 5 s waits timed out in two runs while the hierarchy showed the correct value.

Debug-first note: the first run failed in setup with "Navigate to the selected date's week". The captured hierarchy showed that the Food Log day cells and week buttons carry the container identifier `week-calendar-strip`, so the `food-day-N` and `week-calendar-previous/next` selectors never matched. The tests now find days by accessibility label and the buttons by label, with no change to application code.

## Ten scenarios (live: integrated simulator, XCUITest-driven)

The integrated-simulator runs and the disk-identity run used the first version of the tests; the later commit changed only how values are queried (one predicate instead of enumerating elements), the wait length, and added the production-database test. The clone-simulator class run above is on the final commit.


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
| 10 | Production database, no network use | Pass by direct observation, not airplane mode: journey on the full production database with zero inet sockets for the app process (see below) | `production-database-values.txt`, `production-netsample.log`, `prod-checkpoint-*.png` |

Videos are screenshot timelapses of the live runs (about 4.5x to 7x real speed, 55 to 58 s) because the simulator's host recorder was busy: `live-nutrition-only-totals-relaunch-review-timelapse.mp4` (journey 1), `live-edit-delete-retain-other-day-timelapse.mp4` (journey 2), `live-clear-day-retain-other-day-timelapse.mp4` (journey 3).

## Record identity on disk (clone simulator, fixture)

`disk-identity-snapshots.txt` lists every distinct state of the SwiftData store (`default.store` plus WAL) seen while the tests ran; each line is the entries (UUID, food, grams, meal, logged-at UTC, kcal per 100 g), the user count and UUID, and MedicationProfile and Dose counts. Findings:

- Every snapshot has at most one User, zero MedicationProfile and zero Dose rows.
- Journey 1: one entry (`5B918A8D...`, 200 g Breakfast) and one User (`7E16FF33...`) are identical before and after the no-reset relaunch.
- Journey 2: yesterday's entry `4A04DD51...` (100 g) and today's `78A414D0...` (200 g). The edit changes the same UUID `78A414D0...` to 100 g; deletion removes only `78A414D0...`; `4A04DD51...` is unchanged through the delete and the relaunch.
- Journey 3: yesterday `0AE19337...`, today `F73F534F...` (100 g Breakfast) and `66E97B18...` (200 g Lunch). Clear Day removes exactly the two of today; `0AE19337...` stays through the relaunch.
- Canceled edit and canceled delete produce no store change, since no intermediate state appears in the list.

## Scenario 10: production database, observed zero network use

Method (not airplane mode, and the host network was not touched):

1. The app was built with the full production `usda_foods.sqlite` (1,779,711 foods, sha256 `b2c637b3...5c4`); the copy inside the built app has the same hash.
2. `testProductionDatabaseJourneyWithDatabaseValues` searches, selects, sets grams, picks the meal and logs two named foods, then checks the Food Log, Dashboard and a no-reset relaunch. The expected values come from `sqlite3` queries of the same database, passed to the test as environment variables; it is skipped with an explicit message when they are absent. Foods: Chicken, broilers or fryers, breast, meat only, cooked, roasted at 200 g (165 kcal, 31 P, 0 C, 3.57 F per 100 g, giving 330/62/0/7) and Oil, olive, salad or cooking at 100 g (884/0/0/100). Totals 1214/62/0/107. Values and arithmetic: `production-database-values.txt`.
3. Throughout the run `netsample.sh` sampled `lsof -nP -i -a -p <app pid>` for the JabTracker app process: 400 samples over 272 s, median gap 0.57 s, 95th percentile 0.91 s, longest 4.7 s (the host was heavily loaded), covering both app launches (pids 53133 and 64657). Every sample reported zero inet sockets. `nettop -P -L 1 -p <pid>` in a parallel loop returned no traffic rows in 48 samples. A control sample of a user-owned process with a listening socket shows the method detects sockets. Logs: `production-netsample.log`, `production-netsample-nettop.log`.

Limits: this is sampling, so a socket that opened and closed between samples (between samples, typically under 0.6 s but up to 4.7 s) would not appear; it is not a packet capture. CloudKit was disabled by the test launch argument, so sync traffic is out of scope, as are system daemons (they are separate processes). The run used the clone simulator, not the integrated one, and the test runner process is excluded from the sampling.

## Gaps against the written acceptance criteria

- **Network unavailable is not simulated (AC3, scenario 10):** the evidence is observed zero network use with production data, not a run with the network disabled. A device-level airplane-mode check remains possible on a physical or isolated device.
- **Production-database coverage is one journey** (search, log, totals, relaunch for two foods); edit, delete and clear-day ran on the fixture only.
- **Camera and barcode** are untestable in the simulator and are not part of this slice.
- **Date choice:** dates are chosen by selecting a day in the Food Log before adding; the search sheet's own time picker is not exercised.
- **Real onboarding** is not part of this slice (KAT-3588).
- **Disk UUID identity** ran on the clone simulator, not the integrated one, and by sampling rather than a before/after export.
