# KAT-3588 verification evidence

Branch commit under test: the commit that adds this file on top of the "deny HealthKit and notification system prompts" test commit (tests ran at its pre-rebase form `8cfe1eb2`; the rebase onto the KAT-3580 branch changed no code). Debug build, Xcode 27.0, iOS 27.0 simulators with the full local food database. Authentication is the test-mode fictional user (`--ui-testing`); it does not prove Apple sign-in.

## Tests

- `OnboardingLaunchContractTests`: 2 of 2 passed (completion and explicit skip persistence with recreated managers).
- `OnboardingLaunchUITests`: 5 of 5 passed on the final commit, on a freshly erased owned simulator in one run. The same four non-prompt cases also passed on the integrated simulator (4 of 4).
- Real system-prompt denial (`testDeniedSystemPromptsForHealthKitAndNotificationsLeaveNutritionUsable`): the test turns on the Health and Notifications toggles, answers the actual Health Access sheet and notification alert with Don't Allow, finishes setup, logs 100 kcal by Quick Add, opens Notification settings, relaunches without reset or seed arguments and checks that the goal and the single entry persist. It needs an erased simulator, because iOS remembers a first answer.
- Main comparison: the same flow on `main` (`edd81bd7`) stops at Program Style because Manual is offered (`main/main-programstyle-manual-visible.png`); the branch hides it.

## Scenarios

1. Main vs branch first run: `main/main-welcome.png`, `main/main-programstyle-manual-visible.png`, `live/onboarding-test-auth-welcome.png`.
2. Welcome to nutrition-only setup: `live/onboarding-nutrition-setup-confirmation.png`, `live/onboarding-nutrition-completion.png`.
3. Skip reaches a useful app: `live/onboarding-explicit-skip.png`, `live/onboarding-skip-relaunched.png`.
4. Deny Health: `live/onboarding-healthkit-system-prompt.png`, `live/onboarding-healthkit-system-prompt-denial.png`, `live/onboarding-healthkit-denial-acknowledged.png`; manual logging follows in `live/onboarding-manual-nutrition-logged.png`. Passed against the real Health Access sheet.
5. Deny notifications: `live/onboarding-notifications-system-prompt.png`, `live/onboarding-notifications-system-prompt-denial.png`; core logging afterwards.
6. Skip biometrics: `live/onboarding-biometrics-skipped.png` (toggle off or unavailable on the simulator).
7. Later recovery: partly covered. Health and notification settings stay reachable (`live/onboarding-permissions-settings.png`, `live/onboarding-notifications-denied-settings.png`). After a real denial the notification status row reads "Not Configured" in this test-authenticated launch, so the system Settings button was not asserted. `simctl privacy` cannot revoke or grant notifications, camera or Health (it covers photos, location, contacts and similar), so re-granting through iOS Settings was not automated. Open gap.
8. Relaunch retains profile and goal: `live/onboarding-retained-nutrition-goal.png`, `live/onboarding-retained-profile.png`, `live/onboarding-completion-relaunched.png`.
9. Hidden features never appear: the tests assert Manual, subscription, AI and photo choices absent at every step.
10. Signed-device Apple sign-in and cancel: not run. Owner and device gap; simulated authentication is not a substitute.

`onboarding-timelapse-55s.mp4` is a 55 s timelapse of four cases on the integrated simulator (screenshots played at 15 frames per second), because `simctl recordVideo` reported "Host recording is already in progress".

## Skip button `isHittable` (intermittent)

On the Choose Your Goal step `onboarding-skip-button` sometimes reports `isHittable == false` while the screen is idle, the button is enabled, and nothing overlaps it (`skip-hittable/run-failure-goal-step.png`, `skip-hittable/earlier-failure-goal-step.png`; the captured element tree shows an enabled button inside the window). It failed in 3 of about 9 runs without the fallback, including one run of three consecutive runs with the fallback removed, and passed on rerun with no code change. A 3 s hittable wait did not help, so a keyboard or animation overlap is ruled out. The test taps the button's center when the flag is false. Root cause is unknown.
