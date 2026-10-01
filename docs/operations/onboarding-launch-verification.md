# Onboarding launch verification

[KAT-3588](https://linear.app/kata-sh/issue/KAT-3588/prove-first-run-onboarding-and-denied-permissions-leave-a-usable-app) adds two unit contracts and four UI journeys. Existing onboarding suites and helpers remain unchanged. No production code, permission implementation, release policy or authentication behavior changes. The branch is stacked on the KAT-3580 release-flag branch, so Manual onboarding is hidden here.

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

Each failed assertion captures `TestUtilities.debugScreenshot`, prints the element hierarchy and attaches the screenshot before reporting failure. Named checkpoints also preserve welcome, skip, permission, completion, profile, goal and relaunch screenshots. Selectors follow source declarations; live trees must confirm them before any selector repair.

## Acceptance matrix

| Issue scenario | Current coverage | Required live evidence |
| --- | --- | --- |
| 1. Main/branch first run | Named welcome checkpoint | Same production first-run route on main and branch |
| 2. Nutrition-only completion | Completion UI journey and record contracts | Executed in Debug (passes); Release run pending KAT-3597 |
| 3. Explicit skip | Skip and cancel journeys | Execute; demonstrate manual entry and later Create Goal |
| 4. Deny HealthKit | Skipping/unavailable state only | Actual OS denial plus manual logging; **NOT RUN** |
| 5. Deny notifications | Toggle left off only | Actual OS denial plus core logging; **NOT RUN** |
| 6. Skip biometrics | Off/unavailable state and no lock on relaunch | Execute on available and unavailable devices |
| 7. Later recovery | Settings routes reachable | Actual enable/reauthorize in supported OS settings; **NOT RUN** |
| 8. Relaunch retains profile/goals | No-reset/no-reseed UI journeys; separate in-memory count contracts | Execute and inspect disk-backed results; no claim of UI access to all inactive model records |
| 9. Hidden features | Manual onboarding, legacy medication/paywall, More placeholders and capture choices absent | Execute against fixed launch policy; inspect every step |
| 10. Signed-device Apple auth/cancel | No simulated substitute | Named signed-device production run; **NOT RUN** |

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

This branch has no `ReleaseTestHarness` configuration (KAT-3597 owns it), so the UI class runs in Debug only. A Release-configuration run of this fixture needs KAT-3597 to land first.

## Recorded results

Run on Xcode 27.0 with iOS 27.0 simulators with the full local food database. Debug unit contracts: 2 of 2 passed. Debug UI class: 4 of 4 passed on the final commit. The same UI flow on `main` (`edd81bd7`) stops at the Program Style step because Manual is offered there; the screenshot is the main/branch comparison for scenario 1. Skipped permissions do not satisfy the OS-denial or signed-device gates; scenarios 4, 5, 7 and 10 stay open.
