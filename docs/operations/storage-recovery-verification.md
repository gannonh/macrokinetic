# Storage recovery verification

[KAT-3583](https://linear.app/kata-sh/issue/KAT-3583/show-persistent-store-failure-and-prevent-silent-temporary-logging) replaces the emergency memory fallback with `ready(ModelContainer)` or `failed(StorageFailure)`. The normal root and its startup, authentication, seeding, onboarding, foreground and restart callbacks exist only when storage is ready. System URLs received while failed are discarded before parsing or dispatch.

Production opens retain the unnamed application-default configuration. A requested CloudKit open can fall back to the same default local disk identity. Local-only opens make one attempt. Failure creates no replacement container. Synchronous Retry reuses the retained configurations and factory; ready is terminal. Retry performs no deletion, reset, seeding or sign-out. Explicit programmatic memory injection remains available for tests/previews.

The recovery screen offers Retry and copy/share support metadata. Its report includes fixed app/event/stage fields, validated version/build values, numeric OS components, attempt count and error codes only from allowlisted system domains. Error descriptions, raw domains, userInfo, paths, identities and health values are not included. Sharing does not claim support delivery. KAT-3592 owns the public contact destination.

## Isolated fault fixtures

The fixture implementation and bootstrap reader compile only under `DEBUG || JABTRACKER_TEST_HARNESS`. Launch with `--storage-fixture=<UUID>` to select `Application Support/JabTrackerStorageFixtures/<UUID>/default.store`. Arbitrary paths and duplicate fixture identifiers are rejected. This disk store uses CloudKit `.none`, including when `--cloudkit-testing` or `-inMemory` is supplied.

- `--storage-fail-first-open` fails the initial opening operation, then allows Retry.
- `--storage-always-fail-open` fails each operation, including Retry.
- Omitting failure arguments reopens the same fixture successfully.

Prime fictional records during a successful fixture launch. Keep the UUID unchanged across failure/retry/relaunch. Remove reset and seed inputs from subsequent successful recovery launches. Do not remove the fixture files until persistence evidence is collected. These controls do not authorize touching the ordinary store or real-user data.

Run these tests only on an explicitly owned ephemeral simulator created for the run. Record its UDID and use `platform=iOS Simulator,id=<owned-UDID>` for every destination. UUID fixture directories intentionally remain after test teardown so relaunch evidence can inspect the original disk state. Save result bundles, raw logs, screenshots and video outside the simulator before cleanup. The run owner then shuts down and deletes that exact owned simulator, including on test failure. Future launch CI must create its own simulator and install an exit trap for that same UDID. Never delete or erase an existing shared simulator, the ordinary app store, or a directory inferred from app input. The app exposes no fixture deletion control.

KAT-3597 supplies the integrated separate harness configuration. Its production input guards and compiled harness CloudKit exclusion remain in `DataController` and `StoreOpening`.

## Test code and execution evidence

`DataControllerInitializationTests` now contains eleven behavioral cases: real disk startup/reopen; no emergency memory after failure; preexisting user and `0.75` dose retained across retry; repeated failure; configured/local ordering; unchanged production identities across attempts; real invalid-store bytes retained; strict support fields; intentional memory injection; fixture UUID/disk isolation; fixture fault-mode recovery. Simulated factory ordering does not establish real CloudKit service behavior.

`StorageRecoveryUITests` has ten scenario methods. Successful priming uses the existing guarded dose fixture and the actual food logging UI. Recovery and relaunch use neither reset nor seed inputs. Food display values and the single preexisting `0.75 mg` dose are checked afterward. Unit tests additionally assert unchanged record UUIDs and counts directly from disk.

| # | UI scenario | Remaining live evidence |
| --- | --- | --- |
| 1 | Normal branch launch has no recovery screen | Compare the same benign normal route on main and branch |
| 2 | Successful disk launch; food/dose survive relaunch | Execute on the candidate and retain results |
| 3 | Forced failure blocks startup, including reset/seed arguments | Capture recovery PNG and hierarchy |
| 4 | Food logging controls absent during failure | Drive the failure screen and verify no alternate route |
| 5 | Launch dose link and foreground cannot reveal normal logging | Deliver a real system URL while blocked |
| 6 | Literal recovery copy explains unavailable logging and preserved data | Review copy and screenshot |
| 7 | Repeat failure increments attempt feedback and remains blocked | Execute sequential repeated taps |
| 8 | Retry recovers preexisting food and dose without reseeding | Retain original/recovered values and fixture identity |
| 9 | Terminating while blocked and reopening preserves original store | Keep files unchanged throughout the check |
| 10 | Accessibility-sized text, support fields, copy and dismiss | Confirm actual text scaling; drive system share/cancel and VoiceOver |

Every new UI assertion captures a screenshot and element hierarchy before reporting a failure. The suite retains screenshots as XCTest attachments. If a selector fails, inspect that evidence before changing selectors, identifiers or timeouts.

Implementation checks cover Swift parsing in Debug, Release and harness modes, plus SwiftLint and `git diff --check`. They do not compile or execute SwiftData/XCTest. Runtime tests, generated-project inclusion, normal main/branch comparison, screenshots and a 30–60 second video remain required before draft promotion. Signed-device persistence, real device failure/recovery and CloudKit acceptance are separate live gates. KAT-3584's health-data/CloudKit policy remains unchanged.

After the parent generates the project and creates the owned ephemeral simulator described above, these targeted commands exercise the code. Set `DESTINATION` to its recorded UDID. Use fresh result/DerivedData paths and retain the bundle and raw log:

```sh
xcodebuild test -project JabTracker.xcodeproj -scheme JabTrackerIntegrationTests \
  -configuration Debug -destination "$DESTINATION" \
  -only-testing:JabTrackerIntegrationTests/DataControllerInitializationTests \
  -derivedDataPath "$UNIT_DERIVED_DATA" -resultBundlePath "$UNIT_RESULT"

xcodebuild test -project JabTracker.xcodeproj -scheme JabTracker \
  -configuration Debug -destination "$DESTINATION" \
  -only-testing:JabTrackerUITests/StorageRecoveryUITests \
  -parallel-testing-enabled NO \
  -derivedDataPath "$UI_DERIVED_DATA" -resultBundlePath "$UI_RESULT"
```

Repeat the UI class using `JabTrackerReleaseTestHarness` / `ReleaseTestHarness`. Fixture screenshots and seeded authentication establish route and recovery behavior; they do not establish real Apple authentication or production sync.

## Recorded runtime checks, 2026-09-30

On the owned iPhone 18 Pro Max simulator `13D2AEC6-F13F-4318-BC06-BCBF69040A47`, iOS 27 / Xcode 27:

- Debug `JabTrackerIntegrationTests/DataControllerInitializationTests`: 11 passed, zero failed/skipped. `/tmp/jabtracker-launch-20260930/storage-units.xcresult`; log `test_sim_2026-09-30T21-50-07-729Z_pid19961_09a35dad.log`.
- ReleaseTestHarness `StorageRecoveryUITests` methods 01,03,04,05,06,07,10: 7 passed, zero failed/skipped. `/tmp/jabtracker-launch-20260930/storage-ui-blocking-harness.xcresult`; log `test_sim_2026-09-30T21-52-15-676Z_pid19961_4e6330d2.log`. The actual harness application and UI tests compiled in this run.

The first attempted UI command selected a target name as a scheme and failed before execution. The corrected command uses the actual `JabTrackerReleaseTestHarness` scheme; its passing xcresult is the evidence above. No UI selector was changed to handle that tooling error.

At 22:48 UTC, methods 02,08,09 passed on temporary integration `00613e38479b31a7ef6f0d7d80c377b89215e63e`: storage `264472a74e53e87e70d90a5ebe49a64beca34cad` (controls included) plus food presentation `4bf867e03a62ca37683ee203cac17d258a711b71`. `/tmp/jabtracker-launch-20260930/storage-food-persistence-harness.xcresult` reports 3 passed, zero failed/skipped. Exact methods are successful disk startup/relaunch, retry of preexisting food/dose without reseeding, and failure/termination/reopen retaining the original store. The bundled full database is 439869440 bytes, SHA-256 `b2c637b3cd700350cca0399c7be9456185ce23b4d2fcb55ef0e4b7f2dcc5c5c4`; this is not the 22-food CI fixture. The tool response timed out, but direct xcresult inspection shows a completed passing run and no running Xcode test process. No rerun or selector change was used to handle that reporting timeout.

All ten optimized harness methods have now passed across the two batches. This does not establish the eventual combined launch SHA, main comparison, all ten browser scenarios, physical-device recovery, real authentication, VoiceOver or real CloudKit behavior. The integration adds no food dependency changes to this PR's diff.
