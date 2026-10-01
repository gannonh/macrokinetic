# Test controls and release artifacts

[KAT-3597](https://linear.app/kata-sh/issue/KAT-3597/exclude-test-authentication-reset-and-seed-controls-from-production) separates test launch controls from ordinary Release. The source inventory started at `edd81bd73ee84bf7cddf1e6fa62a3736f88a70fe` on 2026-09-30. `project.yml` owns the configurations and schemes.

## Configuration contract

| Configuration | Identity | Launch controls | Default app storage |
| --- | --- | --- | --- |
| Debug | `com.gannonhall.JabTracker` | Existing Debug controls and predicates | Existing Debug selection, including named CloudKit checks |
| Release | `com.gannonhall.JabTracker` | Test readers, reset/seed helpers and mock branches excluded | Existing persistent production storage and CloudKit selection |
| ReleaseTestHarness | `com.gannonhall.JabTrackerTestHarness` | Explicit `JABTRACKER_TEST_HARNESS` condition; no `DEBUG` | Persistent disk store; compiled CloudKit `.none` |

Local owners retain their existing test-detection predicates inside `#if DEBUG || JABTRACKER_TEST_HARNESS`. The harness ignores `-inMemory` and cannot enable CloudKit with `--cloudkit-testing`. Its entitlements retain HealthKit and Sign in with Apple, with all iCloud/CloudKit/ubiquity entries removed. Installing it on a device requires provisioning for its separate identifier.

`JabTrackerReleaseTestHarness` includes UI tests, without Debug-only unit/integration targets. `JabTrackerFoodSearchBenchmark` and `scripts/benchmark-food-search.sh` use the harness configuration. The main scheme's archive action remains ordinary Release. The harness is never eligible for shipment.

## Control inventory

The following readers and their test-only implementations are excluded from ordinary Release. Each row identifies its owner and the state it can affect in Debug or the harness.

| Controls | Owner | Effect |
| --- | --- | --- |
| `--reset-app-data` | `AuthenticationManager.swift` | Deletes SwiftData records, test-reset defaults, chart cache and notifications; clears authentication state |
| `--ui-testing`, `UI_TESTING=true`, `--manual-ui-testing` | `AuthenticationManager.swift` | Creates/reuses a fictional user, bypasses authentication, or simulates the manual sign-in result |
| `--bypass-onboarding`, `--force-onboarding`, UI-test detection | `AuthenticationManager.swift`, `Onboarding/OnboardingCoordinator.swift` | Changes fixture completion fields/defaults and onboarding routing |
| `--seed-test-7d`, `--seed-test-30d`, `--seed-test-90d`, `--seed-test-1y`; quality/new-user, check-in and active-user controls listed below | `AuthenticationManager.swift`, `Utils/TestDataSeeding*.swift` | Creates fictional medication, dose, schedule, food, weight, goal, program and metric history |
| `TEST_DATA_*` variables listed below | `AuthenticationManager.swift`, `Utils/TestDataSeeding.swift` | Selects fictional seed content, counts and timing |
| `--test-titration-data`, `--seed-calorie-user` | `JabTrackerApp.swift`, `DataController.swift` | Inserts titration history or modifies a fictional user's calorie/HealthKit settings |
| `--deeplink-url=<url>` | `JabTrackerApp.swift` | Invokes a test-requested route; ordinary system `.onOpenURL` handling remains available |
| `-inMemory`, `--disable-cloudkit`, `--cloudkit-testing`, UI/XCTest detection | `DataController.swift` | Debug storage/sync overrides; harness always disables CloudKit and ignores runtime in-memory selection |
| `UI_TESTING=true`, `--ui-testing`, loaded `XCTestCase` | `BiometricAuthManager.swift` | Forces available/Face ID state; does not simulate `LAContext.evaluatePolicy` |
| `--ui-testing` with the owner's XCTest exclusion | `Services/NotificationService.swift` | Returns fixture authorization without OS permission |
| `--ui-testing` | `Views/Settings/SettingsView.swift` | Skips notification toggle asynchronous operations |
| `--mock-active-energy=<double>` | `Services/MetricsService+HealthKit.swift` | Supplies active-energy data through a process argument |
| `--ui-testing` plus `--food-search-fail-once` | `Services/LocalFoodDatabase.swift` | Throws once for a pizza search |
| `--ui-testing` | `Views/Nutrition/FoodSearchSheet.swift` | Exposes the benchmark timestamp accessibility marker |
| `XCTestConfigurationFilePath`, `SWIFT_TESTING=1`, UI detection and the test initializer parameter | `Services/SubscriptionManager.swift`, legacy `SubscriptionView.swift` | Controls fixture restore, purchase, transaction-listener and entitlement behavior |
| XCTest detection and injected availability/result booleans | `Onboarding/Legacy/LegacyOnboardingViewModel.swift` | Skips or supplies fixture HealthKit authorization |

Seeding arguments:

- `--seed-test-1y-high`, `--seed-test-1y-medium`, `--seed-test-1y-low`, `--seed-test-new-user`.
- `--seed-check-in-ready`, `--seed-check-in-good`, `--seed-check-in-minimum`, `--seed-check-in-insufficient`, `--seed-collaborative`.
- `--seed-3-day-active`, `--seed-5-day-active`, `--seed-2-week-active`, `--seed-1-month-active`, `--seed-90-day-active`.

Seed environment variables: `TEST_DATA_SEED`, `TEST_DATA_DAYS`, `TEST_DATA_MEDICATION`, `TEST_DATA_BRAND`, `TEST_DATA_DOSE`, `TEST_DATA_ADHERENCE`, `TEST_DATA_VARIABILITY`, `TEST_DATA_SKIPPED`, `TEST_DATA_PROFILES`, `TEST_DATA_DOSE_COUNT`. Owners that exclude unit tests retain their existing `XCTestConfigurationFilePath` / `XCTestSessionIdentifier` checks. Biometrics retains its loaded-class predicate; SubscriptionManager retains `SWIFT_TESTING` detection.

Existing Debug-only dose, HealthKit and StoreKit test seams remain Debug-only. Genuine biometric, reminder and completed/skipped onboarding preferences remain production state. Explicit programmatic injection (`DataController(inMemory:)`, custom database paths and `ActiveEnergyDataSource`) and previews remain available without a runtime test-input route. This issue does not change credential/account policy, logout deletion, model schema, sync behavior, persistent-store fallback or launch feature flags.

## Build provenance and preflight

The application post-build phase runs `scripts/release/build-controls.py generate`. It reads the built Info.plist and writes `JabTrackerBuildManifest.json` atomically into the application resources. The manifest contains only a schema version and raw resolved inputs:

- `CONFIGURATION`, `PRODUCT_BUNDLE_IDENTIFIER`, `PLATFORM_NAME`.
- `SWIFT_ACTIVE_COMPILATION_CONDITIONS`, `OTHER_SWIFT_FLAGS`, `TOOLCHAIN_DIR`.
- Effective `SWIFT_EXEC`, `SWIFT_FRONTEND_EXEC`, `SWIFT_DRIVER_SWIFT_FRONTEND_EXEC` values, including empty values.

The phase declares the Python script and built Info.plist as inputs, and the final manifest plus its fixed `.tmp` sibling as outputs. It runs on each build to replace previous configuration metadata. Generation failure removes stale outputs.

The same CLI verifies both app bundles through the existing five-argument `scripts/release/inspect-release-bundle.sh` entry point. It recomputes Swift definitions from raw conditions, both `-D` forms and `-Xfrontend` forwarding. Shipment preflight requires ordinary `Release`, exact production identifiers in both Info.plists and manifests, identical archive/IPA inputs, and an empty Swift-definition set. Unknown fields, invalid types, duplicate JSON keys, missing metadata, opaque response files and unresolved/ambiguous inputs fail.

Xcode's standard compiler environment is supported: a nonempty compiler value must match the corresponding `swiftc` or `swift-frontend` path inside the selected `TOOLCHAIN_DIR`, whose name is `XcodeDefault.xctoolchain`. Custom compiler/toolchain overrides fail. Retained compiler commands must still establish what Xcode actually invoked.

The original version, build and food-database checks remain required. No stored boolean, binary-string scan or signature verdict substitutes for verification. The manifest records resolved build settings; it does not attest arbitrary binaries, per-file compiler flags or post-build tampering. KAT-3594 owns signing/profile/entitlement acceptance on the exact candidate archive and IPA.

## Verification evidence

### Parent checks on 2026-09-30

Debug, ordinary Release and ReleaseTestHarness compiled successfully on the isolated iPhone 18 Pro Max simulator with Xcode 27. The sandbox-enabled provenance phase wrote the actual bundle manifest in every configuration. Retained compiler commands show no Swift definitions for Release, DEBUG for Debug, and JABTRACKER_TEST_HARNESS for the harness. Release and the harness both resolve to -O. A second XcodeGen generation produced identical project and scheme hashes; no per-file COMPILER_FLAGS were present.

The real CLI tests pass (20 tests). The compiled simulator Release bundle passes provenance validation; compiled Debug and harness bundles are rejected. These same-bundle checks do not establish archive/export acceptance. The Release harness runs FoodSearchV08UITests/testSearchShowsRetryableError successfully (one passed, no failed or skipped tests), including the checked lock-backed failure gate.

Ordinary Release was installed over an isolated fictional Debug store and launched with combined authentication, reset, seeding, in-memory, mock-energy and route inputs. The existing food record kept id 46, its Salmon name and record counts; the visible Food Log retained 100g, 208 calories, 20P, 13F and 0C. A subsequent fresh install with hostile authentication/seed inputs displayed Sign in with Apple. No Apple sign-in was performed. These checks cover combined inputs; the full independent-input matrix, real platform permissions, signed Apple authentication and retained signed-device upgrade data remain pending.

Evidence is retained in the launch run directory under controls-actual-build-evidence.json, controls-fictional-before.json, controls-fictional-after.json, controls-harness-retry.xcresult and the three controls screenshots. The candidate archive, exported IPA and signed-device gates remain incomplete; this branch stays draft.

### Independent Release verification at 9f5e7224, 2026-09-30

All files are under `docs/launch-evidence/KAT-3597/`. Simulators: an isolated iOS 27 clone for the full matrix, and `iPhone 18 Pro` for the live session. Data is fictional (Debug `--seed-test-7d`: one user, one dose, one profile, one schedule).

- **Inventory and Debug behavior.** The Debug app on the same sources still honors the controls: a Debug build seeds the fictional user and dose from `--ui-testing --bypass-onboarding --seed-test-7d` (matrix row `retained|BEFORE`). The Debug binary contains each control string; the ordinary Release binary contains none (`release-binary-control-strings.txt`, `strings-check.sh`). Short Swift string literals such as `--ui-testing` are stored inline and cannot be proven absent by `strings`; the runtime matrix covers them.
- **Ordinary Release, each control alone.** `release-hostile-matrix-results.txt` runs 24 inputs (every inventoried argument and the `UI_TESTING` / `TEST_DATA_*` variables, plus storage-fixture and combined) twice on a Release build:
  - Fresh install: all 24 launches produce a byte-identical screenshot (Sign in with Apple) and an empty store. No authentication bypass, no fake user, no seeded data.
  - Over the Debug-seeded store: record counts and a hash of the user, dose and profile rows are identical before, after every input, and after the last one, including `--reset-app-data`. Screenshot hashes vary only by the dashboard's "Updated" clock minute.
- **Exact archive preflight.** `xcodebuild archive` with signing disabled for the `JabTracker` and `JabTrackerReleaseTestHarness` schemes, with the app zipped into IPA form. `archive-preflight-results.txt`: the ordinary pair passes `inspect-release-bundle.sh`; harness/harness, Release/harness and harness/Release pairs, an IPA without the manifest, and an IPA whose manifest claims `DEBUG` are all rejected with exit 1. The iphoneos Release binary has no control strings; the harness binary has them. These archives are unsigned `CODE_SIGNING_ALLOWED=NO` builds of the candidate sources, not the signed submission artifact.
- **Live session on `iPhone 18 Pro`.** `live-iphone-18-pro-results.txt`, `live-iphone-18-pro-*.png`: Release over the seeded store with combined hostile inputs kept the same rows and hash and showed the app; a fresh Release with hostile inputs and with `--reset-app-data --seed-test-new-user` showed Sign in with Apple and an empty store.

Scenario 4 (real Apple authentication, real biometric/notification permission, CloudKit and signed-device upgrade retention) needs a signed ordinary build on a device with an Apple ID. It was not run. The simulator launches above use a development-style install, not distribution signing.

| Check | Evidence available from implementation | Acceptance still required |
| --- | --- | --- |
| CLI/inspector behavior | 12 Python tests drive real CLI calls, fixture `.app` directories and IPA zip files; eight existing release-tool tests pass | Actual ordinary/harness archive and exported IPA inspection |
| Swift compilation | Actual Debug, Release and harness builds pass; syntax and lint checks also pass | Signed candidate compilation and device execution |
| Configuration/entitlements | XcodeGen twice is stable; resolved Release/harness settings share -O and differ in identity, conditions and entitlement file; no per-file flags | Signed-device harness provisioning |
| Provenance phase | Sandbox-enabled phase writes manifests in actual bundles; retained compiler commands and atomic/error-path CLI tests agree | Ordering before candidate signing and manifest retention in the final archive/exported IPA |
| Runtime controls and retention | Source inventory and local guards reviewed | Four issue scenarios below; no runtime or signed-device result is implied by fixtures |

Run the inexpensive tooling checks from the repository root:

```sh
python3 -m unittest scripts.tests.test_build_controls scripts.tests.test_release_tools -v
bash -n scripts/release/inspect-release-bundle.sh scripts/benchmark-food-search.sh scripts/test-archive.sh
plutil -lint JabTracker/JabTrackerTestHarness.entitlements
git diff --check
```

Before acceptance, retain four named scenario results:

1. Exercise existing Debug controls on isolated fictional data. Compile ordinary Release and harness, and inspect resolved settings plus generated per-file flags. Only identifier, conditions, entitlements and any optional display name may differ between Release and harness settings.
2. Launch ordinary Release with each inventoried hostile input independently and combined. Verify authentication/onboarding/platform permissions use production paths. Capture fictional record IDs, counts, values and genuine preferences before/after launch and termination/relaunch; keep disk persistence throughout.
3. Run the actual archive/IPA inspector on ordinary Release and a harness artifact. Ordinary Release must pass; harness, missing/altered metadata and test definitions must fail. Retain settings, compiler commands and phase-order evidence alongside the artifact identity.
4. Verify real Apple authentication and retained data on a signed ordinary artifact with an isolated identity/device. Real biometric/notification permission, CloudKit sync and upgrade retention require their own live evidence; seeded routes do not establish them.

Distribution-signed apps cannot receive ordinary simulator launch arguments. A development-signed Release or simulator run can exercise hostile inputs, while the exact shipping artifact's compiler and signing evidence establishes its provenance. Capture screenshots and element hierarchy before changing selectors after a UI failure.
