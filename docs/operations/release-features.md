# Release feature policy

KAT-3580 excludes unfinished features from the launch build. KAT-3581 also excludes medical calculators and unsupported concentration displays. `ReleasePolicy` is a static, typed, exhaustive decision in `JabTracker/App/ReleasePolicy.swift`. Every feature below is disabled. Changing availability requires a reviewed source change. Preferences, environment variables, launch arguments, authentication, and debug mode cannot override this policy.

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
| `medicalCalculators` | Reconstitution/dilution/unit calculations; drug dose menus/ranges/steps; titration plans/actions/notifications; inferred drug schedules and new split-dose suggestions | Record a finite positive clinician-prescribed amount, date and manually confirmed schedule; read/edit existing recorded schedules and doses |
| `concentrationEstimates` | Dashboard concentration cards, Concentration analytics tab/chart requests, dose PK preview and clinical half-life/frequency detail rows | History and Adherence analytics; internal PK engine and stored data |

## Boundaries and storage

Search and library catalogs keep their existing raw values and cases. Visible menus filter these catalogs. Food-search selection normalizes unsupported requests. Shortcut actions validate before dismissal, again after the delayed presentation, and at the receiving sheet binding. Capture and subscription views guard their actual request boundaries. This policy introduces no model fields, preference migrations, remote configuration or CloudKit schema changes.

Hidden photo and metric preferences remain stored. No food, schedule, goal, program, medication, metric, snapshot or photo records are deleted. Manual custom-food creation from an empty library has no active launch entrypoint; the implemented To Custom flow remains available. Preview-only export stubs and dormant legacy subscription services receive no new abstraction.

## Calorie evidence and scope

`TDEEService.ensureDailySnapshots` previously used `lastTDEE` unchanged while reporting `.adaptive` when enough historical food and weight days existed. The disabled historical flag selects the existing `.holding` branch, carrying the estimate forward with its established confidence decay. It does not claim that historical recalculation occurred. The regression test supplies four food days and a weight day, verifies sufficient data, and expects a holding value of 2200 and confidence of 0.784 after a previous 0.8 confidence snapshot. A second invocation must add no duplicate snapshot.

Current-day TDEE calculation and implemented calorie adjustment providers stay active. Skipped tests and TODOs alone do not establish that those providers are unfinished. KAT-3580 makes no split-dose behavior change. KAT-3581 separately gates medical advice as described below.

## Medication recording boundary

Medication add/edit forms and Quick Dose accept a finite positive prescribed amount rather than recommending drug-specific values. Save does not clamp to a therapeutic range. New profiles do not create a schedule inferred from a drug's default frequency. The existing manual Create Schedule path still accepts Daily or Weekly and the user's timing. Existing split/custom schedule edits preserve their recorded amount, recurrence and split fields. Quick Dose requires explicit input for an existing split profile; a scheduled dose or dose edit uses the exact recorded amount instead of deriving half the profile dose.

Reconstitution and titration views guard receiving presentation and their calculation/save actions. Concentration selections normalize to History and the visible analytics catalog contains Adherence and History. Concentration cards and PK previews also guard directly constructed views. The two flags do not delete hidden compounding fields, profiles, titration records, dose records or schedules. The PK engine and CloudKit schema remain unchanged.

JabTrackerApp schedules pending notification cleanup independently of authentication. The static cleanup helper needs no ScheduleService or ModelContext and cancels only pending requests marked by the TITRATION category, a titrationId payload or the titration- identifier prefix. Ordinary dose, missed-dose, weigh-in and food-log requests remain pending. Titration categories are omitted, foreground presentation is suppressed, and received requests and direct titration actions reject before record writes or notification additions. Delivered notifications and stored titration/schedule records remain unchanged. The existing dormant titration response router is not enabled.

No concentration estimate is enabled in this release. Before enabling these features, review the current [App Store Review Guidelines, sections 1.4.1 and 1.4.2](https://developer.apple.com/app-store/review/guidelines/), establish calculator provider eligibility and support any retained estimate methodology with primary manufacturer references and clear limits in the UI. Disclaimers alone do not establish eligibility or submission approval.

## Verification

Unit coverage asserts the fifteen disabled features, literal supported catalogs, AI request normalization, preserved preferences, and Manual onboarding rejection before persistent writes. UI coverage checks hidden shortcut/search/library/detail/More/metric controls and supported neighbors. Existing onboarding coverage asserts Manual absent while completing Coached onboarding; the Strategy wizard still receives all three styles explicitly.

Recorded on the branch (details and screenshots in `docs/launch-evidence/KAT-3580/`): full Debug unit suite 3,076 tests, 3,071 passed, 1 skipped, 4 failed (two titration notification cases that fail on `UNAuthorizationStatus=Denied`, two date-sensitive view-model tests; none touch this diff). `ReleaseSurfaceUITests` runs 9 cases in Debug and in an optimized Release build (`Release-iphonesimulator`, no `debug.dylib`); 8 pass in each. The failing case opens food detail from search and hits the blank-sheet defect that also fails on `main` (`edd81bd7`); it is tracked separately and keeps scenario 8's search-to-detail path open. Quick Add logging, weight logging, the scanner without its Label and gallery controls, the Dashboard to Food Log to More comparison, hostile launch input, and the hidden Strategy and calorie-settings controls pass.

Hostile-input check: the Release build ignores `--enable-*` arguments, `RELEASE_FEATURES`/`ENABLE_*` environment variables and `-subscriptions YES`-style defaults; `ReleasePolicy` contains no `#if`, `ProcessInfo`, `UserDefaults` or launch-argument reads.

These tests do not establish Sign in with Apple, CloudKit synchronization, account deletion, privacy resources, or submission readiness; those have separate launch tickets.

KAT-3581 has its own ten live scenarios and Human Review evidence. Earlier tests expecting an enabled dose stepper, therapeutic range, automatic split amount or titration mutation must be reconciled to the launch recording contract. `quick-dose-prescribed-amount-input` replaces `quick-dose-amount-stepper` and `quick-dose-amount` while the medical flag is off. Pure calculator/PK engine tests can continue to verify internal math without exposing those features.
