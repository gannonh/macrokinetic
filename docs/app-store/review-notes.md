# App Review notes draft

**DRAFT. Do not submit.** The App Review contact is UNRESOLVED (owner input `app_review_access`). The signed candidate SHA, version 1.0.0, and build come from KAT-3594.

Public name: MacroKinetic. Seller: Gannon Hall (individual). Price: free, no in-app purchases. Bundle identifier: `com.gannonhall.JabTracker`.

## Review introduction

MacroKinetic records food, body measurements, and prescribed medication doses. Nutrition tracking works without medication tracking. The app does not prescribe doses or calculate medication mixing.

The release build turns off subscriptions, AI food tools, recipes, favorites, progress photos, manual onboarding, help center, medical calculators, and concentration estimates (`JabTracker/App/ReleasePolicy.swift`; evidence in `docs/launch-evidence/KAT-3580` and `KAT-3581`). Launch arguments and environment variables cannot turn them on.

The app has no accounts. Reviewers need no sign-in, credentials, or demo account. All data stays on the iPhone, with no iCloud sync. Deleting the app removes the data.

## Reviewer route

Each step lists the evidence on `main` at `49c78848`. The signed archive (KAT-3594) and independent device checks (KAT-3595) still have to confirm the same behavior.

| Step | Evidence |
| --- | --- |
| Contact name and phone | UNRESOLVED. Support email: support@macrokinetic.app |
| Open the app. It needs no sign-in. | KAT-3586 merged (`docs/launch-evidence/KAT-3586/live-checks.sh`) |
| Complete first-run onboarding | UNVERIFIED: KAT-3588 is open |
| Food Log → Add → search a food → Add. Confirm the row and the day's totals. | KAT-3587 merged; `evidence/capture-run.json` |
| Add (+) → Metrics → enter a waist value → Save | `evidence/capture-run.json` (store row 81.28 cm for 32 in) |
| Optional: More → GLP-1 Programs → Analytics → History | KAT-3186 merged; `evidence/capture-run.json` |
| More → General → Food data: USDA and Open Food Facts notices | KAT-3593 merged |
| Privacy, terms, and support at https://macrokinetic.app/privacy, /terms, /support | UNVERIFIED: KAT-3783 publishes the pages and KAT-3592 links them in the app |
| Data deletion: delete the app. No account and no iCloud copy exist. Apple Health samples stay in Health. | KAT-3713 and KAT-3586 merged |

Offline behavior is not advertised. KAT-3590 verifies it on a device.
