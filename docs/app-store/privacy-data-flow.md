# Privacy data-flow worksheet

**DRAFT. Storage policy, retention, deletion, processor access, and App Store privacy answers are unresolved.** This inventory describes source behavior at audit baseline `35c7a1959a805331ccc09a2821b8d801f42efc3c`. Reconcile it against the final candidate and release flags.

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

The current DataController puts health and medication models into one CloudKit private database. KAT-3584 must resolve the conflict with Apple's guideline 5.1.3(ii) and the repository sync invariant. Do not publish a promise that all data stays on-device, that iCloud is compliant, or that the developer cannot access data without confirming the final design. [Apple review guidelines](https://developer.apple.com/app-store/review/guidelines/).

Apple's privacy label definition of collection depends on off-device transmission and access/retention. On-device processing alone does not mean collection. Conversely, functionality-only collection still needs disclosure. Inventory developer access and third-party access before choosing answers. [Apple privacy details](https://developer.apple.com/app-store/app-privacy-details/).

Record each final data type, whether collected, linked to a person, used for tracking, purpose, recipients, retention, consent withdrawal, and deletion path. Check actual SDKs and network behavior from the signed candidate. A source scan found no declared third-party package dependencies, but it is not a compiled privacy report.

HealthKit samples in Apple's Health app and app-owned copies are separate records. Deletion copy must state which are removed and which remain. Do not imply app deletion cancels any future Apple subscription.
