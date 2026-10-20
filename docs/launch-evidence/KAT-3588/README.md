# KAT-3588 verification evidence

Rebased onto `main` at `49c78848` (KAT-3580 release flags, KAT-3583 store fail-closed and KAT-3597 test controls already merged). Debug build, Xcode 27.0, an owned iOS 27.0 iPhone 17 Pro simulator erased before the run, full local food database. Authentication is the test-mode fictional user (`--ui-testing`); it does not prove Apple sign-in.

## Tests

- `OnboardingLaunchContractTests`: 2 of 2 passed.
- `OnboardingLaunchUITests`: 5 of 5 passed in one run on the erased simulator, with no coordinate-tap fallback (every tap asserts `isHittable`).
- Main comparison: the same denial journey run against `main`'s app code fails at "Notification status should report the real denial". The status card reads "Not Configured / Tap toggle above to enable" with no Settings button (`main/main-notifications-denied-not-configured.png`). The branch shows "Disabled / Enable notifications in Settings" and a Settings button that opens iOS Settings.

## Fixes found by these journeys

1. Notification status dead end. Onboarding asks `UNUserNotificationCenter` directly, and `NotificationSettingsView` showed `NotificationService.authorizationStatus` without reading it, so a denied user saw "Not Configured" and no route to Settings. The view now reads the real status on appear and again when the app becomes active (return from iOS Settings).
2. Skip button `isHittable` flake. On Choose Your Goal, `onboarding-skip-button` was intermittently not hittable while enabled, idle and unobstructed (1 of 8 launches in a probe; 3 of about 9 runs earlier; `skip-hittable/`). The button stayed in the tree on every step and flipped from `accessibilityHidden` and opacity 0 to visible inside the animated step change. It is now inserted only on steps that allow skipping. The same probe then ran 16 of 16 hittable, and the coordinate-tap fallback is removed.

## Scenarios

| # | Scenario | Result | Evidence |
| --- | --- | --- | --- |
| 1 | Main vs branch first run | Pass | `main/main-notifications-denied-not-configured.png` vs `live/onboarding-notifications-denied-settings.png`; `main/main-welcome.png`, `live/onboarding-test-auth-welcome.png` |
| 2 | Welcome to nutrition-only setup | Pass | `live/onboarding-nutrition-setup-confirmation.png`, `live/onboarding-nutrition-completion.png` |
| 3 | Skip reaches a useful app | Pass | `live/onboarding-skip-confirmation.png`, `live/onboarding-explicit-skip.png`, `live/onboarding-skip-relaunched.png` |
| 4 | Deny Health keeps manual entry | Pass (real Health Access sheet) | `live/onboarding-healthkit-system-prompt*.png`, `live/onboarding-healthkit-denial-acknowledged.png`, `live/onboarding-manual-nutrition-logged.png` |
| 5 | Deny notifications keeps logging | Pass (real system alert) | `live/onboarding-notifications-system-prompt*.png` |
| 6 | Skip biometrics permits launch | Pass (simulator: off or unavailable) | `live/onboarding-biometrics-skipped.png` |
| 7 | Later permission recovery | Simulator part pass; device part skipped, moved to KAT-3595 | `live/onboarding-notifications-denied-settings.png`, `live/onboarding-notifications-ios-settings.png`, `live/onboarding-permissions-settings.png` |
| 8 | Relaunch keeps profile and goal | Pass | `live/onboarding-retained-nutrition-goal.png`, `live/onboarding-retained-profile.png`, `live/onboarding-completion-relaunched.png` |
| 9 | Hidden features never appear | Pass | Asserted at every step in all five journeys |
| 10 | Signed-device Apple sign-in and cancel | Skipped, moved to KAT-3595 | None. Simulated authentication is not a substitute. |

Scenario 7 on a simulator proves the recovery route: after a real denial the app reports Disabled, explains the fix, and its Settings button opens iOS Settings (the simulator lands on the Settings root). Turning the permission back on inside iOS Settings and seeing the app pick it up is not automatable: `simctl privacy` cannot grant or revoke notifications or Health, and none of the onboarding permissions is one it can toggle. That part runs on a signed device under KAT-3595.

`onboarding-timelapse-55s.mp4` is a 55 s timelapse of four journeys from the pre-rebase run (screenshots at 15 frames per second). The onboarding screens are unchanged by the rebase apart from the skip button now being absent, rather than invisible, on steps that cannot skip.
