# Privacy API and permission audit

KAT-3585. Source audit on 2026-09-30 at `edd81bd73ee84bf7cddf1e6fa62a3736f88a70fe`.

`JabTracker/Resources/PrivacyInfo.xcprivacy` declares the required-reason API use found in app source. This audit does not approve the App Store privacy labels. Collected-data declarations remain incomplete until the CloudKit and developer-access questions below have answers.

## Required-reason API inventory

The audit searched all Swift, Objective-C, and C app source under `JabTracker/` for the API names in [Apple's current category list](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype). It also checked file operations, preferences wrappers, entitlements, and dependencies in `project.yml`. Test targets and build scripts are outside the shipped app inventory.

| Category | Source evidence | Declaration |
| --- | --- | --- |
| User defaults | `UserDefaults.standard` reads, writes, and removes the app's own keys in the files below. No suite, App Group, managed-preference, or cross-app reads were found. | `NSPrivacyAccessedAPICategoryUserDefaults`, `CA92.1` |
| File timestamps | No listed timestamp API calls found. `ChartDatasetCache`, `AuthenticationManager`, `LocalFoodDatabase`, and `ChartExportView` use container paths, file existence checks, reads, writes, or removal. These calls do not read file timestamps. Model `Date` fields describe user records rather than filesystem metadata. | None |
| Disk space | No listed disk-capacity API calls found. | None |
| System boot time | No `systemUptime` or `mach_absolute_time` calls found. Date arithmetic and app timers do not query boot time. | None |
| Active keyboards | No `activeInputModes` calls found. | None |

App-private defaults have these purposes:

| Purpose | Source references |
| --- | --- |
| Onboarding completion and skip state | `Onboarding/OnboardingViewModel.swift:743`, `Onboarding/OnboardingCoordinator.swift:78`, `Onboarding/Legacy/LegacyOnboardingViewModel.swift:359` |
| Notification preferences and reminder times | `Services/NotificationService+Persistence.swift:53`, `Onboarding/Views/NotificationsStepView.swift:68` |
| Biometric lock preference | `BiometricAuthManager.swift:54` |
| Food auto-population and TDEE backfill checkpoints | `Services/FoodAutoPopulationService.swift:129`, `ContentView.swift:55` |
| Reset and account deletion cleanup | `AuthenticationManager.swift:210`, `Views/Settings/AccountView.swift:684` |

Apple's `CA92.1` reason covers preferences accessible only to this app. It does not authorize other apps' or system preferences. App Group and SDK-wrapper reasons do not apply to this inventory. The reason code and dictionary structure were checked against [Apple's required-reason API documentation](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype) and [TN3183](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest).

The project has no third-party SDK dependencies. SQLite, SwiftData, CloudKit, HealthKit, AVFoundation, StoreKit, and other imported system frameworks do not justify adding unused API categories to the app manifest. Re-audit direct API calls and SDK manifests when dependencies change.

## Permissions for the launch configuration

`Services/MetricsService+HealthKit.swift:56` requests reads for weight, height, body fat percentage, waist circumference, active energy burned, biological sex, and date of birth. Its write set at line 61 requests weight, height, body fat percentage, and waist circumference. The updated HealthKit strings name all of these types and their purposes. Active energy is read-only.

Enabled paths include body metrics and profile reads, weight and body-fat writes in `Services/MetricsService.swift:139`, height writes in `Views/Nutrition/ProgramWizard.swift:804`, waist writes in `Views/Metrics/QuickMetricsSheet.swift:381`, and activity calorie calculations in `Services/CalorieAdjustmentService.swift:139`. The service requests the full authorization set together. This change adjusts descriptions without changing authorization, storage, or synchronization behavior. Apple requires separate explanations for [reading and writing HealthKit data](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data).

The launch camera purpose is food barcode scanning. `Services/CameraService.swift:95` requests video access, and its metadata delegate at line 340 extracts a barcode for food lookup. The camera string describes that use, as required by [Apple's camera purpose-string documentation](https://developer.apple.com/documentation/bundleresources/information-property-list/nscamerausagedescription).

**Candidate acceptance depends on KAT-3580.** At this audited commit, `Views/Photos/QuickPhotoSheet.swift:432` can still open the camera for progress photos. The barcode-only purpose text is accurate for the intended launch configuration only after KAT-3580 disables all photo-capture entry points. Do not accept or submit this standalone branch before that dependency is integrated. If photo capture ships, update the camera text and repeat the collection audit first.

## Tracking and unresolved collection decisions

`NSPrivacyTracking` is `false`. No advertising identifier, App Tracking Transparency, ad SDK, tracking-domain, or developer telemetry implementation was found. The app's `AnalyticsService` calculates medication and health summaries from SwiftData. It does not send analytics to a service. No tracking domains are declared.

`NSPrivacyCollectedDataTypes` is intentionally absent while the following decisions remain unresolved. This is an incomplete collection declaration and must not be copied into App Store Connect as an approved "Data Not Collected" answer. Apple defines collection by off-device transmission and subsequent developer or partner access, and separately describes data processed only on device in [App privacy details](https://developer.apple.com/app-store/app-privacy-details/). Follow [Apple's manifest collection guidance](https://developer.apple.com/documentation/technotes/tn3184-adding-data-collection-details-to-your-privacy-manifest) after the answers are verified.

- Normal production startup enables the private CloudKit store in `DataController.swift:28` and `DataController.swift:185`. Test launch arguments commonly disable it. Verify the production container's developer access, data retention, and collection treatment before deciding the App Store labels or manifest entries.
- The CloudKit schema includes account fields, medication and dose history, nutrition logs, weight, body measurements, and HealthKit-derived profile information. Determine the exact data types, purposes, and linkage for retained enabled flows. Do not infer an answer from the word "private" in the database configuration.
- Existing photo data remains part of the registered `ProgressPhoto` model even when KAT-3580 hides capture. Disabling new capture does not establish that previously saved images or notes stop syncing.
- Review HealthKit-derived data in the CloudKit schema and the relevant App Store health-data rules before submission. This ticket makes no health-model or sync changes.
- Compare the final archive and App Store Connect settings for Sign in with Apple, diagnostics, purchases, and retained account identifiers. Disabled purchase UI alone does not settle these collection questions.

## Verification record and remaining checks

The manifest and `Info.plist` pass `plutil -lint`. Their parsed values match the single audited API category, reason, tracking flag, and permission strings. `project.yml` lists the manifest as an explicit source with `buildPhase: resources` and excludes it from broad source discovery. XcodeGen generated one file reference and one Copy Bundle Resources entry; repeated generation is stable. A target-level `resources` entry alone did not include the manifest in the generated project, so bundle inspection is still required.

Parent verification built an unsigned Release app for the isolated iOS 27 Simulator on 2026-09-30. The build passed. Bundle inspection found exactly one `PrivacyInfo.xcprivacy` at the app root, with the expected API reason and tracking flag, and all three updated camera/HealthKit purpose strings in the built `Info.plist`. The record is [privacy-bundle-inspection.json](evidence/privacy-bundle-inspection.json).

The final signed archive's SDK manifests and Xcode privacy report still need inspection. Simulator packaging does not establish App Store acceptance or settle collected-data declarations. [Apple documents the required bundle placement](https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk).

Before submission, integrate KAT-3580, settle the collected-data decisions, update both the manifest and App Store Connect answers, and compare the enabled launch paths against this inventory. Re-audit after any dependency or data-flow change.
