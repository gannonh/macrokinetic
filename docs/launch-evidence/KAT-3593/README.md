# KAT-3593 verification evidence

Branch commit under test: the commit that adds this file on top of `26925159`. All live checks ran on the iOS 27.0 "iPhone 18 Pro" simulator with the Debug build (0.10.1, build 16). Main comparison uses the baseline Debug app built from `35c7a195` (the later main commits change only the shared scheme).

## Tests

- `full-unit-summary.json`: full `JabTrackerUnitTests` suite, 3069 passed, 2 failed, 1 skipped. The 2 failures are `NotificationServiceActionTests` reschedule/remind-later cases that report `UNAuthorizationStatus=Denied` on the cloned simulator; they fail identically on the KAT-3585 branch, which shares no code with this change. The 4 `FoodDatabaseProvenanceTests` pass.
- `unit-summary.json`: earlier targeted run of the 4 provenance tests (4 passed, 0 failed, 0 skipped).
- 7 Python validator cases in `scripts/tests/test_food_data_bundle.py` pass.
- `built-bundle.json`: bundled notices plus the full local database; no manifest in the development bundle.

## Live scenarios (live/ and food-data-review-39s.mp4)

1. Main vs branch, More > General: `live/01-main-general.png` shows About (Version, Build) and Legal only. `live/02-branch-general.png` adds a Food data row.
2. Food data reachable from More > General > Food data: `live/03-food-data-top.png`.
3. USDA credit visible: `live/03-food-data-top.png`. The notices ship in `food-data-notices.json` inside the app bundle and the view makes no network call, so they do not depend on connectivity. A blocked-network run was not performed; the host network was left untouched because the simulator is shared.
4. Open Food Facts ODbL/DbCL notice and links visible: `live/04-food-data-bottom.png`. Same offline basis as 3.
5. Links open: the Open Database License 1.0 link opened Safari on opendatacommons.org (`live/05b-safari-license.png`). The other links come from the bundled JSON and were not each tapped.
6. No image rights claimed: the "Images and other rights" section in `live/04-food-data-bottom.png` states the bundle holds food records, not product images. The database schema has no image column, and the app source has no image loading from these sources.
7. Large text: launched with `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL` (device setting untouched). `live/07a-large-text-top.png` and `live/07d-large-text-end.png` show wrapped notices and the full 64-character checksum.
8. VoiceOver labels: the accessibility tree exposes each link by its visible name (for example "Open Database License 1.0"), notices as whole-text cells, and each provenance detail as one combined element ("SHA-256, b2c6..."). A spoken VoiceOver pass was not performed.
9. Manifest versus resource: with a synthetic manifest generated from the local database and edited into the installed app, the screen reports a match and lists commit, run and source links (`live/09-synthetic-matched.png`; commit `000...0` and run `0` mark it as a fixture). With the published snapshot manifest (hash `58dc3c...`, build 7) it reports unverified (`live/09b-published-manifest-mismatch.png`). The default bundle with no manifest is in `live/04-food-data-bottom.png`. This does not establish provenance for a signed candidate.
10. App Review notes: `docs/app-store/review-notes.md` on the KAT-3591 branch names More > General > Food data as the disclosure route. This document's "App Review disclosure draft" holds the proposed wording.

`food-data-review-39s.mp4` is a 39.6 second recording of More > General > Food data and a scroll to the checksum. `source-notices.png` and `unverified-local-provenance.png` are earlier captures of the same screens.

## Still open (owner or candidate dependent)

Exact signed-candidate manifest, archive and IPA checks; a verified unrestricted public database or alteration offer; owner-approved distribution terms. No legal compliance is asserted.
