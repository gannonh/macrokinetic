# Onboarding launch verification

[KAT-3588](https://linear.app/kata-sh/issue/KAT-3588/prove-first-run-onboarding-and-denied-permissions-leave-a-usable-app) adds two unit contracts and five UI journeys. Existing onboarding suites and helpers remain unchanged. It also fixes two defects the journeys found: Notification settings now reads the real authorization status (a denied user previously saw "Not Configured" and no Settings button), and the onboarding skip button is inserted only on skippable steps (it was intermittently not hittable). Release policy and authentication behavior are unchanged; Manual onboarding is hidden by the KAT-3580 launch flags on `main`.

## Authentication and isolation

The UI suite uses existing `--ui-testing --reset-app-data --force-onboarding --disable-cloudkit` only for initial fictional authentication. `AuthenticationManager.setupUITestingUser()` leaves onboarding incomplete when forced; it receives no medication, goal or history preset. The first launch is a test-authenticated onboarding fixture, not a clean production Apple-authenticated first launch.

Relaunch supplies only `--disable-cloudkit`, with `UI_TESTING=false` and `TEST_DATA_SEED=false`. It supplies no auth bypass, onboarding override, reset or seed argument. The original user has no Apple credential, so `validateAndHandleAppleCredential()` currently restores it without Apple validation. That known identity-policy boundary belongs to KAT-3582. These journeys can prove onboarding state and nutrition persistence; they cannot prove correct production account identity, Apple sign-in or cancel/revocation handling. Account acceptance remains **NOT RUN**.

Run on an explicitly owned ephemeral simulator with a fresh app container. These tests reset that fictional container on initial launch. Never run against a shared simulator or real-user container. Keep tests serial, retain result bundles, raw logs, screenshots and video outside the simulator, then destroy only that run's owned simulator. Copy the full local food database into `JabTracker/Resources/usda_foods.sqlite` before project generation; Quick Add still initializes the actual food service.

## Test contracts

`OnboardingLaunchContractTests` uses explicit in-memory dependency injection. Completion creates one maintenance goal and one Coached program, saves the literal profile and creates zero medication/dose records. Recreating managers and repeating completion preserves UUIDs, completion time and record counts. Skip preserves one user and its skipped state, with zero goal/program/medication/dose records. The suite restores its four UserDefaults keys. Run it alone because other existing suites also mutate those global keys. Manager recreation in one memory container is not disk persistence evidence.

`OnboardingLaunchUITests` uses real disk configuration and the existing UI:

- Complete Maintenance/Coached setup with HealthKit, notifications and biometrics left off; inspect the literal completion summary; retain profile, goal, program and one 100-calorie manual entry across relaunch.
- Explicitly confirm skip; reach Strategy's `No Active Goal` and Create Goal action; retain that state and one manual entry across relaunch.
- Cancel the skip confirmation; remain on goal setup with legacy medication/paywall screens absent.
- Complete with permissions skipped; reach Health and notification settings, then return to manual food logging. Reaching settings is not evidence of actual permission recovery or authorization.
- Turn on the Health and Notifications toggles, answer the real system prompts with Don't Allow, finish setup and log manually; Notification settings must show Disabled with a Settings button that opens iOS Settings; relaunch. This test needs an erased simulator.

Each failed assertion captures `TestUtilities.debugScreenshot`, prints the element hierarchy and attaches the screenshot before reporting failure. Named checkpoints also preserve welcome, skip, permission, completion, profile, goal and relaunch screenshots. Selectors follow source declarations; live trees must confirm them before any selector repair.

## Acceptance matrix

| Issue scenario | Coverage | Status |
| --- | --- | --- |
| 1. Main/branch first run | Denial journey against `main` app code vs branch | Pass |
| 2. Nutrition-only completion | Completion UI journey and record contracts | Pass |
| 3. Explicit skip | Skip and cancel journeys | Pass |
| 4. Deny HealthKit | Real Health Access sheet denied, then manual logging | Pass |
| 5. Deny notifications | Real system alert denied, then core logging | Pass |
| 6. Skip biometrics | Off/unavailable on simulator, no lock on relaunch | Pass |
| 7. Later recovery | Denied status, explanation and Settings button opening iOS Settings | Simulator part pass; re-grant on device moved to KAT-3595 |
| 8. Relaunch retains profile/goals | No-reset/no-reseed UI journeys; in-memory count contracts | Pass |
| 9. Hidden features | Manual onboarding, legacy medication/paywall, More placeholders and capture choices absent | Pass |
| 10. Signed-device Apple auth/cancel | No simulated substitute | Skipped, moved to KAT-3595 |

The older `NewOnboardingUITests` contains empty Face ID, notification and completion methods. Their green results are not acceptance evidence. Its full-flow test and `OnboardingPermissionsUITests` remain separate existing coverage. `TestUtilities+Onboarding.completeOnboardingFlow` still describes the legacy medication/subscription flow and is not used here. The existing `--manual-ui-testing` mock is not reached by `AuthenticationView`'s native Apple button; it is not used here.

## Parent execution

Generate from `project.yml` to include the two new files. The recursive source rules place the contract file in `JabTrackerUnitTests` and the UI file in `JabTrackerUITests`; no project specification edit is required. Set `DESTINATION` to the owned simulator's recorded UDID and use fresh DerivedData/result paths.

```sh
xcodebuild test -project JabTracker.xcodeproj -scheme JabTrackerUnitTests \
  -configuration Debug -destination "$DESTINATION" \
  -only-testing:JabTrackerUnitTests/OnboardingLaunchContractTests \
  -derivedDataPath "$UNIT_DERIVED_DATA" -resultBundlePath "$UNIT_RESULT"

xcodebuild test -project JabTracker.xcodeproj -scheme JabTracker \
  -configuration Debug -destination "$DESTINATION" \
  -only-testing:JabTrackerUITests/OnboardingLaunchUITests \
  -parallel-testing-enabled NO \
  -derivedDataPath "$UI_DERIVED_DATA" -resultBundlePath "$UI_RESULT"
```

This PR records Debug runs only. The class was not run under the KAT-3597 `JabTrackerReleaseTestHarness` scheme.

## Recorded results

Evidence and screenshots are in `docs/launch-evidence/KAT-3588/`. Debug unit contracts: 2 of 2 passed. Debug UI class: 5 of 5 passed on an erased simulator after the rebase onto `main` `49c78848`, including real Health and notification system-prompt denial. The same denial journey against `main`'s app code fails at the notification status check.
