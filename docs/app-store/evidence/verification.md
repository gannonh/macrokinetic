# KAT-3591 verification scenarios

Run on 2026-10-20 against the KAT-3591 branch rebased on `main` `49c78848`. Commands run from the repository root.

## 1. Metadata field lengths: PASS

`python3 scripts/app-store.py validate` exits 0 with `Packet format checks passed.`

| Field | Length | Limit |
| --- | --- | --- |
| name | 12 chars | 30 |
| subtitle | 28 chars | 30 |
| promotional_text | 92 chars | 170 |
| description | 544 chars | 4000 |
| whats_new | 92 chars | 4000 |
| keywords | 85 bytes | 100 |

## 2. Screenshots and icon: PASS

Captured by `AppStoreScreenshotUITests` (1 test, 0 failures, [`capture-run.log`](capture-run.log)) on an iPhone 17 Pro Max simulator, iOS 27.0, `ReleaseTestHarness` build. Each image passed `import-screenshot` (PNG decode, size, color type, checksum). "Changed pixels" is `magick compare -metric AE` between the raw simulator PNG and the committed file after dropping the fully opaque alpha channel.

| Slot | Size | Format | sha256 | Captured (UTC) | Changed pixels |
| --- | --- | --- | --- | --- | --- |
| `dashboard` | 1320 x 2868 | opaque 8-bit RGB | `9f3a6f4e1610` | 2026-10-20T16:47:27Z | 0 |
| `food-search` | 1320 x 2868 | opaque 8-bit RGB | `27b83211c40f` | 2026-10-20T16:47:37Z | 0 |
| `food-log` | 1320 x 2868 | opaque 8-bit RGB | `c6a271a16959` | 2026-10-20T16:47:45Z | 0 |
| `metrics` | 1320 x 2868 | opaque 8-bit RGB | `a36c5a06f130` | 2026-10-20T16:47:56Z | 0 |
| `dose-history` | 1320 x 2868 | opaque 8-bit RGB | `405690414290` | 2026-10-20T16:48:12Z | 0 |

Content review: every image shows a real release-scope screen with fictional seeded records ("Test breakfast", seeded Ozempic doses). No subscription, AI, recipe, photo, or concentration surfaces appear.

Icon: `python3 scripts/app-store.py check-icon` returns `Icon packaging PASS: 3 iPhone renditions` ([`icon-check.json`](icon-check.json), actool 27.0).

| Appearance | Size | Opaque |
| --- | --- | --- |
| any | 1024 x 1024 | True |
| dark | 1024 x 1024 | True |
| tinted | 1024 x 1024 | True |

The signed archive's icon is checked under KAT-3594.

## 3. Claims against the release flag inventory: PASS

`ReleasePolicy.isEnabled` returns false for all 15 `ReleaseFeature` cases. The copy names none of them.

| Claim | Issue | Evidence |
| --- | --- | --- |
| `nutrition_logging` | KAT-3587 | `evidence/capture-run.json`; docs/launch-evidence/KAT-3587/README.md |
| `nutrition_without_medication` | KAT-3587 | `evidence/capture-run.json`; docs/launch-evidence/KAT-3587/README.md (scenario 2) |
| `metrics_recording` | KAT-3580 | `evidence/capture-run.json`; docs/launch-evidence/KAT-3580/README.md (scenario 7) |
| `prescribed_dose_history` | KAT-3186 | `evidence/capture-run.json`; docs/launch-evidence/KAT-3186/README.md |

Removed: `offline_logging` (KAT-3590 is Todo; no device check with the network off). "Works offline" is gone from the promotional text, description, keywords, and support draft.

Store rows behind the claim results: [`capture-store-query.txt`](capture-store-query.txt) (waist 81.28 cm = 32 in, 4 doses, logged salmon 417 g at 153 kcal/100 g = 638 kcal).

## 4. Reviewer steps and owner-only gaps: PASS (gate correctly BLOCKED)

[`review-notes.md`](../review-notes.md) lists each reviewer step with its evidence. `python3 scripts/app-store.py validate --ready`:

```text
Packet format checks passed.
Submission readiness BLOCKED:
- owner inputs: still draft
- candidate version 0.10.1 is not proposed 1.0.0 (KAT-3594 sets the submission version)
- owner input unresolved: privacy_label
- owner input unresolved: regions_age_medical_status
- owner input unresolved: pricing_and_agreements
- owner input unresolved: app_review_access
- owner input unresolved: export_and_signing
- review-notes.md: unresolved draft content
- public/privacy.md: unresolved draft content
- public/terms.md: unresolved draft content
- public/support.md: unresolved draft content
exit=2
```

Every blocker is an owner fact, KAT-3594 (version and signed archive), or a draft marker that clears with those facts and KAT-3588/KAT-3783/KAT-3592.
