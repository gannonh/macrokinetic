# Privacy data-flow worksheet

**DRAFT. Owner decisions of 2026-10-19 set on-device storage only, no iCloud sync (KAT-3713), and no sign-in (KAT-3586). The App Store privacy answers need owner approval and verification on the candidate.** The table below still describes the audit baseline, before those changes. This inventory describes source behavior at audit baseline `35c7a1959a805331ccc09a2821b8d801f42efc3c`. Reconcile it against the final candidate and release flags.

| Data | Source and current handling | Candidate questions |
| --- | --- | --- |
| Name, email, Apple user ID | Apple sign-in and User model. AuthenticationManager persists User. | Is sign-in required? Which fields leave the device? Who can access or retain them? How does deletion revoke credentials? |
| Weight, height, sex, birthday, waist, body fat | Manual profile/metrics and HealthKit reads. MetricsService imports weight into SwiftData. | Which types remain enabled? Confirm consent, optional manual alternatives, storage policy, retention, and deletion scope. |
| Active energy | HealthKit read for calorie expenditure. | Is this capability enabled and accurately explained in the permission request? |
| Prescribed-dose and medication history | Dose and MedicationProfile models in SwiftData. | Prove retention on logout/upgrade. Resolve permitted sync and backups. Avoid dosing instructions. |
| Food entries, totals, goals, and nutrition programs | Local food search and app SwiftData records. | Separate public dataset distribution from personal food logs. Confirm cloud handling and deletion of unscoped FoodEntry records. |
| Progress photos and notes | ProgressPhoto model and CameraPicker/PhotosPicker. | Intended release-off. Preserve existing records without exposing incomplete capture. Do old records still sync? |
| Purchases | StoreKit transaction and subscription code, plus local fixtures. | Intended release-off. Local StoreKit fixtures do not prove production products or data collection. |
| Settings | UserDefaults for onboarding and notifications. | Required-reason manifest under KAT-3585. Document actual reasons and bundle inclusion. |
| Diagnostic logs | AuthenticationManager uses public email/UUID log interpolation. | Remove unnecessary personal logging or restrict privacy. Confirm actual log capture and retention. |

At the audit baseline DataController put health and medication models into one CloudKit private database. The owner resolved KAT-3584 as option A: on-device storage only, no iCloud sync, so the developer has no access to user data and deleting the app removes the data. KAT-3713 implements that and updates the repository sync invariant. Do not publish the on-device promise until the candidate proves CloudKit is off. iPhone backups the user makes under their own Apple settings can still contain app data. [Apple review guidelines](https://developer.apple.com/app-store/review/guidelines/).

Apple's privacy label definition of collection depends on off-device transmission and access/retention. On-device processing alone does not mean collection. Conversely, functionality-only collection still needs disclosure. Inventory developer access and third-party access before choosing answers. [Apple privacy details](https://developer.apple.com/app-store/app-privacy-details/).

Record each final data type, whether collected, linked to a person, used for tracking, purpose, recipients, retention, consent withdrawal, and deletion path. Check actual SDKs and network behavior from the signed candidate. A source scan found no declared third-party package dependencies, but it is not a compiled privacy report.

HealthKit samples in Apple's Health app and app-owned copies are separate records. Deletion copy must state which are removed and which remain. Do not imply app deletion cancels any future Apple subscription.

## Privacy label draft (pending owner approval)

**Draft answer: Data Not Collected.** Status: **PENDING OWNER APPROVAL.** Nothing leaves the device under the 2026-10-19 decisions, and a source scan found no declared third-party packages.

| Condition to verify on the candidate | Owner / ticket |
| --- | --- |
| CloudKit and iCloud sync are off and no health model reaches a cloud store. | KAT-3713 |
| No sign-in, so no name, email, or Apple user ID is stored or sent. | KAT-3586 |
| No network call carries user data, and no third-party SDK collects data. | Candidate network and SDK inspection |
| Diagnostic logs do not leave the device. | Candidate inspection |

The owner approves or changes this answer after those checks pass. Until then the label stays a draft and nothing is entered in App Store Connect.
