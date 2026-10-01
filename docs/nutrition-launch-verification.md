# Verify nutrition-only launch behavior

[KAT-3587](https://linear.app/kata-sh/issue/KAT-3587) owns this verification slice under [KAT-3185](https://linear.app/kata-sh/issue/KAT-3185). The implementation starts from food-details commit `4bf867e03a62ca37683ee203cac17d258a711b71`. The three UI tests run and pass on the CI fixture database; see [launch evidence](launch-evidence/KAT-3587/README.md) for results, the disk-identity check, and the open production-database/offline gate. No production-database or offline result is claimed.

## Run the three exact UI selectors

Generate and execute through the parent-controlled launch checkout. Use Debug for initial selector grounding, then the isolated ReleaseTestHarness after the flags, test-controls, food-details, and storage changes are combined. Ordinary Release excludes these test launch controls and requires its own real authentication/device check.

```text
JabTrackerUITests/NutritionLaunchUITests/testNutritionOnlyTotalsAndRelaunch
JabTrackerUITests/NutritionLaunchUITests/testEditAndDeleteRetainOtherDay
JabTrackerUITests/NutritionLaunchUITests/testClearDayRetainsOtherDay
```

The [tests](../JabTrackerUITests/Nutrition/NutritionLaunchUITests.swift) use the existing `launchAppWithConfiguration` helper. Each fresh scenario resets fictional data once. Fresh launch and relaunch have no seed arguments and set `TEST_DATA_SEED=false`. Relaunch explicitly sets `resetData=false`; no in-memory flag is used. Debug disables CloudKit through the existing control; the Release harness uses its compiled disk-only configuration. English UI is selected so literal labels are reproducible.

Authentication creates/reuses the existing fictional UI-testing user. [AuthenticationManager](../JabTracker/AuthenticationManager.swift) returns from requested seeding when no seed is requested. The default user has calorie/protein/fat/carbohydrate goals of 2000/150/65/200. The tests check the existing medication-profile empty state, but that UI filters profiles by the current user. It does not prove that unowned profiles or dose rows are absent. The disk gate below must show zero total MedicationProfile and Dose records.

The 22-food [CI fixture](../scripts/create-ci-food-database.py) has this exact salmon row. The same name in an arbitrary production snapshot is not permission to assume its nutrients or serving metadata match; validate the chosen production row separately.

| Serving | Calories | Protein | Fat | Carbohydrate |
| --- | --- | --- | --- | --- |
| Salmon, Atlantic, raw, 100g | 208 | 20g | 13g | 0g |
| Salmon, Atlantic, raw, 200g | 416 | 40g | 26g | 0g |
| Same-day 100g + 200g | 624 | 60g | 39g | 0g |

The first selector chooses grams and Breakfast on today's Food Log date. It checks the original and scaled detail values, exact row label/count, meal totals, selected-date entry count, Food Log totals, and all four dashboard ring values. It terminates/relaunches without reset or reseeding and repeats the literal checks.

The second selector records yesterday's 100g Breakfast and today's 200g Breakfast. Editing today's serving to 100g must leave exactly one 208/20/13/0 row. A canceled edit to 200g and canceled deletion must leave it unchanged. Confirmed deletion leaves today's totals at zero and yesterday's exact row intact, including after relaunch. Dashboard checks apply to today, independently of the Food Log date selection.

The third selector retains yesterday's 100g Breakfast while adding today's 100g Breakfast and 200g Lunch. Both the Clear Day menu and confirmation must name exactly two entries. Cancel retains both literal rows and 624/60/39/0 totals. Confirmation clears only today; yesterday's row survives and remains after relaunch.

Selectors note: at runtime the Food Log day cells and week navigation buttons expose the container identifier `week-calendar-strip`, so the tests find days by their accessibility label (`Wednesday, September 30, 2026, today, no entries`) and the buttons by label (`Previous week`, `Next week`), not by `food-day-N` or `week-calendar-previous/next`. Every explicit new assertion goes through a helper that captures `TestUtilities.debugScreenshot`, an xcresult screenshot attachment, and `app.debugDescription` before reporting failure. Success checkpoints also retain screenshots/hierarchy. On failure, read both artifacts before changing a selector, timeout, or app identifier. Source parsing and lint do not establish that the menu/header/ring queries match the runtime hierarchy.

## Prove exact record identity on disk

Use an isolated fictional-data container and the parent operator's read-only store inspection. Do not add UUIDs to VoiceOver, add an export/bypass to production, or change user data to make the evidence pass. Inspect the real SwiftData SQLite schema before choosing columns; do not assume every artifact has the same generated schema.

Record the simulator/device identity, bundle/configuration, candidate SHA/version/build, food-database checksum and fixture/production classification, local time zone, store location, and operator time. A live SQLite read must include current WAL state. Copying only a `.sqlite` file can omit committed rows still in its WAL.

1. After the fresh no-seed launch, prove exactly one fictional User and zero FoodEntry, MedicationProfile, and Dose rows. Keep the user's UUID for later comparison.
2. Drive the first selector's equivalent flow and a previous-day record manually. Save a before snapshot with the two distinct FoodEntry UUIDs and storage row identities, food reference, name/brand, selected local date/time, meal, grams, per-100g nutrients, serving metadata, notes, and any schedule reference. Check literal 208/20/13/0 per 100g, today's 200g Breakfast, and yesterday's 100g Breakfast.
3. Terminate/relaunch without reset or any seed argument/environment. Save the after snapshot. Require the same User UUID, same two FoodEntry UUIDs/storage row identities, and identical persisted field values. Require zero MedicationProfile and Dose rows in both snapshots. Screen labels or equal counts cannot substitute for UUID equality.
4. For edit/cancel/delete, snapshot each boundary. Editing changes the original today's UUID to exactly 100g; it does not replace it with a new UUID. Canceled edits and canceled deletion leave its fields unchanged. Confirmed deletion removes only that UUID and preserves yesterday's UUID and fields.
5. For clear-day, record the exact two UUIDs on today and the one on yesterday. Cancel preserves all three records. Confirmation removes only today's two UUIDs. Relaunch preserves yesterday's original UUID and all fields. Totals must match the UI literals at each boundary.

Keep these snapshots and a comparison result with the issue evidence. The UI selectors assert visible literal values and counts, not disk UUIDs. The same-ID comparison ran against snapshots of the live store taken every 0.4 s during the three tests; the result is in the launch evidence. The remaining boundaries not snapshotted (for example a canceled edit) rely on the UI literals. Unknown schema, missing snapshot, mismatched identity, or inaccessible store remains an explicit incomplete check.

## Complete the ten live scenarios

Keep a main/branch comparison, all ten results, screenshots, and a 30–60 second Human Review video before leaving draft. Preserve xcresult/logs and discovered/executed selectors with zero failures or unapproved skips. Results are recorded in the launch evidence README; scenario 10 stays NOT RUN.

| Scenario | Required evidence |
| --- | --- |
| 1. Compare known-food logging on main and branch | Same selected food/serving/meal/date and literal result. Keep main failure evidence if the baseline cannot complete the flow. |
| 2. Nutrition-only profile works | Fictional user, empty medication UI, and actual zero MedicationProfile/Dose rows. Real first-run onboarding is separately owned by KAT-3588. |
| 3. Known serving gives exact macros | Detail 100g and 200g literals, exact persisted serving/nutrient snapshot, and row values. |
| 4. Selected meal/date | Breakfast/Lunch headers, selected calendar date, record local date/time and meal fields. Include previous-week/month boundary behavior when applicable. |
| 5. Dashboard totals match | Four named ring values for today; Food Log daily totals agree and yesterday's entries do not enter today's totals. |
| 6. Edit updates exact macros | Original UUID remains; serving 200g becomes 100g and totals become 208/20/13/0. Cancel keeps the saved value. |
| 7. Cancel deletion preserves the record | Same UUID, fields, row/count, and totals before/after Cancel. |
| 8. Delete/clear-day preserves other dates | Only the selected UUID/date set is removed; yesterday's original UUID/fields and totals remain. |
| 9. Relaunch preserves the original record | No reset/reseed inputs; exact before/after UUID/field snapshots plus repeated literal UI checks. |
| 10. Production database works offline | Exact full database artifact and selected production row, verified unavailable network, local search/save/edit/delete and relaunch durability on the required candidate/device. |

The offline production-database scenario is a named gate, not a consequence of passing the fixture tests. Use an isolated test device with Wi-Fi and cellular unavailable, or a separately verified app-specific network isolation method. Keep evidence of that isolation. Do not interrupt the host's network or agent services. Record the production row's actual literals, search results, saved UUID, and no-reset relaunch values; if its data differs from the CI fixture, use separately stated expectations. UI-testing mode, a local SQLite file, or absence of observed network traffic alone does not prove an unavailable network.

Fixture UI automation does not establish real Apple sign-in, HealthKit/notification permission behavior, approved health-sync policy, production account ownership, signed upgrade retention, or final submission readiness. Those owner/device gates remain explicit under KAT-3582, KAT-3584, KAT-3588, KAT-3590, and KAT-3595.
