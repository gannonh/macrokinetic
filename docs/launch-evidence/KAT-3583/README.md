# KAT-3583 recovery evidence

All ten ReleaseTestHarness `StorageRecoveryUITests` methods pass on the final code, on two simulators, with zero failures or skips. Eleven Debug `DataControllerInitializationTests` pass and inspect the real disk records and identity before and after retry.

| Scenario | Evidence |
| --- | --- |
| 1 Normal launch, main vs branch | `main-normal-*.png`, `branch-normal-*.png` (same flow, same screens); `live-iphone-18-pro/01-storage-normal-branch.png` |
| 2 Successful disk start | `live-iphone-18-pro/02-storage-disk-relaunch.png` |
| 3 Forced failure shows recovery | `03-storage-startup-blocked.png` (launched with reset and seed inputs) |
| 4 Food logging unavailable | `04-storage-no-food-logging.png` |
| 5 Dose logging unavailable | `05-storage-no-dose-logging.png` (dose deep link and foreground return) |
| 6 Copy describes unsaved state | `06-storage-recovery-copy.png` |
| 7 Retry failure stays blocked | `07-storage-repeat-failure.png` (3 attempts) |
| 8 Retry restores original data | `08-storage-before-retry.png`, `08-storage-original-data-recovered.png` |
| 9 Relaunch keeps original store | `09-storage-original-data-after-relaunch.png` |
| 10 Large text and support | `10-storage-safe-support-large-text.png` (copy reachable at AX XXXL) |

- `live-iphone-18-pro-recovery-review.mp4`: 52 s excerpt of the live run on iPhone 18 Pro (failure screen, blocked tabs, support, repeated retry, then retry restoring the food and 0.75 mg dose).
- `harness-ui-10-live-iphone-18-pro-summary.json`: the live run (iPhone 18 Pro, 10 passed). `harness-ui-10-clone-iphone-summary.json`: the same ten on an isolated iPhone 18 Pro Max clone (10 passed). `debug-unit-summary.json`: the 11 Debug units.
- The first live run on iPhone 18 Pro failed scenario 10: after one scroll Copy was still below the accessibility-size support text. Copy and Share now precede the text, and the rerun passed. All screenshots here come from the rerun.
- Scenarios 2, 8 and 9 prime a food entry through the real food-detail screen. They pass only with the KAT-3598 fix (PR #370), so these runs used a temporary integration of this branch plus `4bf867e0`. Without it, those three methods cannot add the food. `persistence-summary.json` records the earlier three-method run on the same combination.
- Fictional fixture data only. No report was sent from the share sheet.

Not covered: real system URL delivery while failed, VoiceOver, a physical device and CloudKit behavior. See `../../operations/storage-recovery-verification.md`.
