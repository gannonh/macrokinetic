# App Review notes draft

**DRAFT. Do not submit.** Candidate SHA, version, build, signed-device checks, owner contact, access instructions, and health-sync decision are unresolved.

Proposed public name: MacroKinetic. Bundle identifier: `com.gannonhall.JabTracker`.

## Proposed review introduction

MacroKinetic records food, body measurements, and prescribed medication doses. Nutrition tracking can be used without medication tracking. The app does not prescribe doses or provide mixing instructions in the intended launch scope.

The intended launch excludes subscriptions, AI food tools, recipes, unfinished manual food creation, progress photos, manual onboarding, and drug-dose or reconstitution calculators. KAT-3580 and KAT-3581 must prove these exclusions on the exact candidate before this text becomes a submitted statement. No unreviewed feature should become remotely available after approval.

## Record the reviewer route

Replace this section with the confirmed final route. Do not provide fictitious credentials or assume a test-only bypass works in the submitted app.

- Owner review contact and telephone: UNRESOLVED.
- Sign-in requirement and reviewer access: UNRESOLVED. Verify the shipping Apple sign-in flow and any guest route.
- First-run permission and onboarding steps: UNVERIFIED, KAT-3588.
- Open Food Log, search the bundled library, add a food, and confirm the recorded meal and totals: UNVERIFIED, KAT-3587.
- Open Metrics, record a measurement, and review persisted history: UNVERIFIED, KAT-3595.
- Optional medication route through More, GLP-1 Programs, and dose history: UNVERIFIED, KAT-3186.
- Open privacy, terms, support, and food dataset credits: UNVERIFIED, KAT-3592 and KAT-3593.
- Account deletion route and its HealthKit, local-storage, and sync effects: UNRESOLVED, KAT-3586 and KAT-3584.
- Offline behavior, upgrade retention, and permission-denial evidence: UNVERIFIED, KAT-3590 and KAT-3588.

## Attach the candidate record

Record the exact SHA, version, build, production food-database manifest/checksum, release-scope evidence, archive report, tested device and OS, and supporting results in `evidence/`. Link sources for any retained medication estimate. Source inspection and fixture tests do not establish on-device acceptance.
