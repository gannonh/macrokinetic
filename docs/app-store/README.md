# App Store packet

Submission packet for [KAT-3591](https://linear.app/kata-sh/issue/KAT-3591), under [KAT-3185](https://linear.app/kata-sh/issue/KAT-3185). Nothing here is published or submitted.

| Part | File | State |
| --- | --- | --- |
| Copy, URLs, seller, claims | [`metadata.json`](metadata.json) | Ready. Each claim links evidence. |
| Screenshots and release scope | [`assets.json`](assets.json), [`screenshots/`](screenshots/README.md) | Ready. Five 1320 x 2868 captures of `main` at `49c78848`. |
| Icon packaging | [`evidence/icon-check.json`](evidence/icon-check.json) | PASS from the source catalog. KAT-3594 checks the signed archive. |
| Reviewer notes | [`review-notes.md`](review-notes.md) | Draft. App Review contact is unresolved. |
| Owner facts | [`owner-inputs.json`](owner-inputs.json) | 5 of 10 unresolved (see below) |
| Privacy, age, public pages | [`privacy-data-flow.md`](privacy-data-flow.md), [`age-and-medical-status.md`](age-and-medical-status.md), [`public/`](public/README.md) | Drafts pending owner facts |
| Verification scenarios | [`evidence/verification.md`](evidence/verification.md) | 4 of 4 run |

The app displays **MacroKinetic**. The repository and bundle identifier keep JabTracker. `metadata.json` proposes 1.0.0. The capture build is 0.10.1 (16). KAT-3594 sets the submission version and build.

## Validate

Run from the repository root:

```sh
python3 scripts/app-store.py validate            # format checks; lists readiness blockers; exit 0
python3 scripts/app-store.py validate --ready    # exit 2 while any blocker remains
python3 scripts/app-store.py check-icon          # compiles JabTracker/AppIcon.icon with actool, rewrites evidence/icon-check.json
python3 -m unittest scripts.tests.test_app_store
```

`validate` checks copy lengths (name and subtitle 30, promotional text 170, description 4,000, keywords 100 UTF-8 bytes), URLs, screenshot size, opaque 8-bit RGB, checksums, capture provenance, claim evidence, and the icon report. It rejects an icon report whose source checksum no longer matches `JabTracker/AppIcon.icon`.

The icon check compiles the Icon Composer source for iPhone and reads the compiled catalog with `assetutil`. It requires opaque 1024 x 1024 renditions for the any, dark, and tinted appearances. For an Icon Composer source, App Store Connect takes the marketing icon from the archive's asset catalog, so no separate 1024 PNG is uploaded.

## Open blockers

`validate --ready` reports these. All are owner facts or belong to another ticket.

| Blocker | Owner |
| --- | --- |
| `privacy_label` approval (draft answer: Data Not Collected) | Owner |
| `regions_age_medical_status`: regions, age rating, medical-device status | Owner |
| `pricing_and_agreements`: EU trader status | Owner |
| `app_review_access`: App Review contact name and phone | Owner |
| `export_and_signing`: export compliance | Owner; signed archive is KAT-3594 |
| Version 1.0.0 and build | KAT-3594 |
| Draft markers in `review-notes.md` and `public/` | Clear after the owner facts above, KAT-3588 onboarding, and KAT-3783/KAT-3592 public pages |

## Limits

- Copy advertises only behavior with merged evidence. The offline claim was removed because KAT-3590 has not verified it on a device.
- Screenshots come from a simulator `ReleaseTestHarness` build, not from the signed archive. Recapture if the archive's screens differ.
- iPad assets are not required while `TARGETED_DEVICE_FAMILY` is `1`.
- Apple references: [platform version fields](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information), [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), [Icon Composer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer).
