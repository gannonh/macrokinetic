# Food detail presentation verification

Selecting the first search result previously presented a blank sheet. `sheet(item:)` now uses the selected food as the presentation state across search, library, recent and barcode callbacks. The existing calorie and nutrient stacks have containing accessibility groups so tests verify each value against its nutrient label.

## Recorded results on 2026-09-30

The same first-egg-result test failed on audited main and passed after the fix using the same full local database. See `main-first-result-blank.png` and `branch-first-result-full-database.png`. Their xcresults are `main-food-detail-debug.xcresult` and `food-detail-first-after.xcresult` in the launch run directory.

Three strengthened Debug UI regressions then passed against the explicit 22-food CI fixture, with no failures or skips:

- FoodSearchV08UITests/testServingPillPickerShowsUniversalUnits.
- FoodSearchV08UITests/testCompleteAddFoodFlow: Salmon at 100g has 208 calories, 20P, 13F and 0C; choosing 200g displays 416/40/26/0, creates exactly one matching row, and retains it after relaunch without reset or reseeding.
- FoodSearchV08UITests/testCancelThenSelectDifferentFoodShowsFreshDetails: cancel Salmon, select Chicken, observe 165/31/3/0, cancel again and retain zero entries and consumed calories.

The actual accessibility tree contains the four scoped nutrient groups. `verification.json` records the fixture checksum and configuration. Runtime result: `/tmp/jabtracker-launch-20260930/food-detail-regressions.xcresult`; raw log: `test_sim_2026-09-30T21-13-35-394Z_pid19961_aa391c60.log` in XcodeBuildMCP's run directory. Screenshots are copied here for review.

Browser-driven checks reopened the persisted 200g entry, selected Recent Salmon into a populated 100g detail, saved a fictional library copy through To Custom, and selected that library copy into populated details. Both source displays showed 208 calories, 20P, 13F and 0C. `browser-recent-review.mp4` is a continuous 52.1-second excerpt of the real browser-driven recent-food recording; it is a Human Review video, not an App Store preview or final candidate asset.

## Final-commit verification (45f2654a, 2026-09-30 to 2026-10-01)

Fixture: the 22-food CI database (`scripts/create-ci-food-database.py`, sha256 `9934b529...8422a18`). Nothing here is production-database acceptance.

Automated, Debug, clone simulator (iOS 27), commit 45f2654a:

- `FoodSearchV08UITests` (full class, 20 tests): 19 passed, 1 failed, 0 skipped. The failure is `testSearchShowsPendingThenFinalState`, which expects a visible loading state; with the 22-row fixture the search returns before the state is observable. It fails the same way on the pre-fix base (51c9a1a0). The new `testRecentAndLibrarySelectionsOpenPopulatedDetails` passes.
- `JabTrackerUnitTests` (full suite): 3065 passed, 2 failed, 1 skipped. Both failures are `NotificationServiceActionTests` titration cases (`UNErrorDomain 2003`, notification authorization on a cloned simulator), outside this diff. The skip is the existing "Check authentication status with UI testing environment".
- Base 51c9a1a0 for comparison: `testServingPillPickerShowsUniversalUnits` and `testCompleteAddFoodFlow` fail with "Food detail sheet should appear" (blank sheet); `BarcodeScanningUITests` fails 7 of 8 in the simulator on both base and branch (camera-dependent; a different single test passes each run), so no barcode result is claimed.

## Ten live scenarios on the integrated simulator (iPhone 18 Pro, iOS 27)

All are XCUITest-driven from the Debug build with the CI fixture; videos are screenshots stitched at the real run speed because the simulator's host recorder was busy.

| # | Scenario | Result | Evidence |
| --- | --- | --- | --- |
| 1 | First result, main vs branch | main: blank sheet, test fails; branch: populated | `live-main-first-result-blank.png`, `live-main-add-flow-failure.mp4`; `live-s1-first-result-detail.png` |
| 2 | Fresh search result opens populated detail | pass (Salmon 208/20/13/0) | `live-s2-fresh-search-detail.png` |
| 3 | Different result after dismiss | pass (Chicken 165/31/3/0, no Salmon values) | `live-s3-different-result-chicken.png`, `live-branch-cancel-then-different-food.mp4` |
| 4 | Library result | pass (fictional "Library Salmon" 208/20/13/0) | `live-s4-library-detail.png`, `live-branch-recent-and-library.mp4` |
| 5 | Recent-food result | pass | `live-s5-recent-detail.png` |
| 6 | Barcode result | NOT RUN: the scanner needs a camera; the simulator offers no deterministic barcode input and adding a test-only hook to production is out of scope. Source-only: the barcode callbacks now set `selectedFood`, the same `sheet(item:)` contract. | none |
| 7 | Gram amount changes visible values | pass (100g 208 to 200g 416/40/26/0) | `live-s7-200g-values.png` |
| 8 | Save yields one matching log row | pass (one row, 416/2000 cal) | `live-s8-saved-one-row.png` |
| 9 | Cancel adds no row | pass (0 rows, 0/2000) | `live-s9-cancel-no-row.png` |
| 10 | Relaunch retains record and totals | pass (no reset, same row and totals) | `live-s10-relaunch-retained.png`, `live-branch-add-flow-review.mp4` |

`live-branch-add-flow-review.mp4` is a 51-second review video of scenarios 2, 7, 8 and 10. Scenario 6 stays open; it is the only unmet verification item.
