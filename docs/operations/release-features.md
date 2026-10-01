# Release feature policy

KAT-3580 excludes unfinished features from the launch build. `ReleasePolicy` is a static, typed, exhaustive decision in `JabTracker/App/ReleasePolicy.swift`. Every feature below is disabled. Changing availability requires a reviewed source change. Preferences, environment variables, launch arguments, authentication, and debug mode cannot override this policy.

| Feature | Disabled surface or request | Supported behavior retained |
| --- | --- | --- |
| `subscriptions` | More subscription row; directly constructed mock subscription screen and its manage action | Account, security and notification settings |
| `aiFoodCapture` | AI shortcut and food-search tab; an explicit AI method request selects Search | Search, barcode scan, Quick Add and Library |
| `recipes` | Recipes shortcut and library tab | Custom foods and schedules |
| `foodFavorites` | Favorites library tab and inert Favorite detail action | To Custom, Schedule and food logging |
| `shortcutCustomization` | Customize, Edit Days and Shortcuts & Tabs placeholders | Supported shortcut destinations |
| `dashboardCustomization` | Inert Dashboard settings row | Dashboard and its existing content |
| `foodLogCustomization` | Inert Food Log settings row | Log, edit, copy and delete flows |
| `extendedBodyMetrics` | Unsupported shoulders, bust, arm, leg and ratio settings | Weight, body fat, neck, chest, waist and hips |
| `progressPhotos` | Capture-only photo shortcut, photo settings and directly constructed capture view/save action | Existing photo records and preferences |
| `manualOnboarding` | Manual option in onboarding; validation rejects direct target calculation or completion requests before writes | Coached/Collaborative onboarding; Manual in the separate Strategy wizard |
| `barcodeScannerExtras` | Barcode scanner's Label scan type and inert Select from gallery button | Barcode scanning and the torch toggle |
| `helpCenter` | Inert FAQ and Help & Support rows | General settings and legal navigation |
| `historicalTDEERecalculation` | Historical backfill branch that copied an estimate into an adaptive snapshot | Holding snapshots; current-day TDEE calculation; burned, predictive and rollover calorie functionality/settings |

## Boundaries and storage

Search and library catalogs keep their existing raw values and cases. Visible menus filter these catalogs. Food-search selection normalizes unsupported requests. Shortcut actions validate before dismissal, again after the delayed presentation, and at the receiving sheet binding. Capture and subscription views guard their actual request boundaries. This policy introduces no model fields, preference migrations, remote configuration or CloudKit schema changes.

Hidden photo and metric preferences remain stored. No food, schedule, goal, program, medication, metric, snapshot or photo records are deleted. Manual custom-food creation from an empty library has no active launch entrypoint; the implemented To Custom flow remains available. Preview-only export stubs and dormant legacy subscription services receive no new abstraction.

## Calorie evidence and scope

`TDEEService.ensureDailySnapshots` previously used `lastTDEE` unchanged while reporting `.adaptive` when enough historical food and weight days existed. The disabled historical flag selects the existing `.holding` branch, carrying the estimate forward with its established confidence decay. It does not claim that historical recalculation occurred. The regression test supplies four food days and a weight day, verifies sufficient data, and expects a holding value of 2200 and confidence of 0.784 after a previous 0.8 confidence snapshot. A second invocation must add no duplicate snapshot.

Current-day TDEE calculation and implemented calorie adjustment providers stay active. Skipped tests and TODOs alone do not establish that those providers are unfinished. Split-dose and clinical-calorie questions require separate review under KAT-3581; this ticket makes no split-dose behavior change.

## Verification

Unit coverage asserts the thirteen disabled features, literal supported catalogs, AI request normalization, preserved preferences, and Manual onboarding rejection before persistent writes. UI coverage checks hidden shortcut/search/library/detail/More/metric controls and supported neighbors. Existing onboarding coverage asserts Manual absent while completing Coached onboarding; the Strategy wizard still receives all three styles explicitly.

Recorded on the branch: full Debug unit suite 3,076 tests, 3,073 passed, 1 skipped, 2 failed (`NotificationServiceActionTests` reschedule and remind-later titration cases, which fail on `UNAuthorizationStatus=Denied` and do not touch this diff). `ReleaseSurfaceUITests` runs 8 cases in Debug and in an optimized Release build (`Release-iphonesimulator`, no `debug.dylib`); 7 pass in each. The failing case opens food detail from search and hits the blank-sheet defect that also fails on `main` (`edd81bd7`); it is tracked separately and keeps scenario 8's search-to-detail path open. Quick Add logging, weight logging, the Dashboard to Food Log to More comparison, hostile launch arguments and environment variables, and the hidden Strategy and calorie-settings controls pass.

Hostile-input check: the Release build ignores `--enable-*` arguments, `RELEASE_FEATURES`/`ENABLE_*` environment variables and `-subscriptions YES`-style defaults; `ReleasePolicy` contains no `#if`, `ProcessInfo`, `UserDefaults` or launch-argument reads.

These tests do not establish Sign in with Apple, CloudKit synchronization, account deletion, privacy resources, or submission readiness; those have separate launch tickets.
