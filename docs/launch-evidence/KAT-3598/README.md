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

## Pending acceptance

The positive barcode/camera scenario needs a deterministic available barcode and camera/device execution. The full ten-scenario browser matrix and integrated Release harness must be verified before leaving draft. This branch is not the combined launch candidate; flags, medical controls, privacy and signed-device gates have separate work. No production-database, signed-device or submission acceptance is inferred from the CI fixture.
