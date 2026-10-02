# KAT-3597 evidence

Ordinary Release ignores every inventoried test control; the separate `ReleaseTestHarness` keeps them; the archive preflight accepts only ordinary Release. Fictional data only. Details and commands: `../../operations/test-controls.md`.

| # | Scenario | Result | Evidence |
| --- | --- | --- | --- |
| 1 | Inventory controls, preserve Debug behavior | Pass. Debug seeds the fictional user and dose from `--ui-testing --bypass-onboarding --seed-test-7d`; the Debug binary contains every control string and the ordinary Release binary none. | `release-binary-control-strings.txt`, `strings-check.sh`, `release-hostile-matrix-results.txt` (row `retained\|BEFORE`), `controls-debug-retained-food.png` |
| 2 | Ordinary Release ignores each control | Pass. 24 inputs, each alone plus combined: a fresh install always shows Sign in with Apple with an empty store (identical screenshot hash); over a seeded store the user/dose/profile rows and their hash never change, including with `--reset-app-data`. | `release-hostile-matrix-results.txt`, `release-hostile-matrix.sh`, `matrix-fresh-release-combined-hostile.png`, `matrix-retained-release-combined-hostile.png` |
| 3 | Exact archive preflight rejects the harness | Pass. Ordinary archive + IPA accepted; harness/harness, Release/harness, harness/Release, a missing manifest and a manifest claiming `DEBUG` rejected. Unsigned archives of the candidate sources, not the signed submission artifact. | `archive-preflight-results.txt`, `controls-compiled-bundle-rejection.json`, `controls-actual-build-evidence.json` |
| 4 | Real production authentication and data retention | Partial. A fresh Release shows the real Sign in with Apple screen with every hostile input, and seeded data survives. Completing Apple sign-in, real biometric/notification permission, CloudKit and signed-device upgrade retention were not run; they need a signed ordinary build on a device with an Apple ID. | `live-iphone-18-pro-*.png`, `live-iphone-18-pro-results.txt`, `live-iphone-18-pro-hostile-release.mp4` (53 s), `controls-release-hostile-retained-food.png`, `controls-release-fresh-hostile-auth.png` |

Test results on `9f5e7224` code: 20 Python CLI/inspector tests pass; `JabTrackerUnitTests` 3065 passed, 1 skipped, 2 failed (`final-unit-tests-summary.json`). The two failures are the known `NotificationServiceActionTests` titration cases (`UNAuthorizationStatus=Denied` on a cloned simulator). The harness retry UI test (`FoodSearchV08UITests/testSearchShowsRetryableError`) passed once, 0 skipped.

Screenshot hashes in the retained matrix vary only by the dashboard's "Updated" clock minute. The matrix script runs on a simulator clone; the live session used iPhone 18 Pro with the same Release build.
