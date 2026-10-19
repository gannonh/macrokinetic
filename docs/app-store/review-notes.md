# App Review notes draft

**DRAFT. Do not submit.** Candidate SHA, version, build, signed-device checks, and the App Review contact are unresolved. The owner decided on 2026-10-19 that 1.0 has no sign-in and keeps data on the device (KAT-3586, KAT-3713); verify both on the candidate.

Public name: MacroKinetic. Seller: Gannon Hall (individual). Price: free, no in-app purchases. Bundle identifier: `com.gannonhall.JabTracker`.

## Proposed review introduction

MacroKinetic records food, body measurements, and prescribed medication doses. Nutrition tracking can be used without medication tracking. The app does not prescribe doses or provide mixing instructions in the intended launch scope.

The intended launch excludes subscriptions, AI food tools, recipes, unfinished manual food creation, progress photos, manual onboarding, and drug-dose or reconstitution calculators. KAT-3580 and KAT-3581 must prove these exclusions on the exact candidate before this text becomes a submitted statement. No unreviewed feature should become remotely available after approval.

## Record the reviewer route

Replace this section with the confirmed final route after the candidate is verified. The app has no accounts, so provide no credentials and no demo account. Do not assume a test-only bypass works in the submitted app.

- Owner review contact and telephone: UNRESOLVED. Support email is support@macrokinetic.app; the owner has not given an App Review name or phone.
- Sign-in requirement and reviewer access: none. The app opens straight to onboarding and reviewers need no account (KAT-3586). UNVERIFIED on the candidate.
- First-run permission and onboarding steps: UNVERIFIED, KAT-3588.
- Open Food Log, search the bundled library, add a food, and confirm the recorded meal and totals: UNVERIFIED, KAT-3587.
- Open Add (+), choose Metrics, and record a body measurement in Log Metrics: UNVERIFIED, KAT-3595. Confirm exact saved values and relaunch retention; no measurement-history screen is advertised.
- Optional medication route through More, GLP-1 Programs, and dose history: UNVERIFIED, KAT-3186.
- Open privacy, terms, and support at https://macrokinetic.app/privacy, /terms, and /support: UNVERIFIED until KAT-3783 publishes them and KAT-3592 links them in the app. Open food dataset credits at More → General → Food data (USDA FoodData Central and Open Food Facts notices, license links, bundled database checksum; draft PR #372): UNVERIFIED until KAT-3593 merges and the candidate's manifest matches its database. Add the verified database download or alteration offer only after the owner confirms it.
- Data deletion: the app has no account. All data is on the iPhone and deleting the app removes it; no iCloud sync (KAT-3713). UNVERIFIED on the candidate, KAT-3586 and KAT-3713. HealthKit samples stay in Apple Health.
- Offline behavior, upgrade retention, and permission-denial evidence: UNVERIFIED, KAT-3590 and KAT-3588.

## Attach the candidate record

Record the exact SHA, version, build, production food-database manifest/checksum, release-scope evidence, archive report, tested device and OS, and supporting results in `evidence/`. Link sources for any retained medication estimate. Source inspection and fixture tests do not establish on-device acceptance.
