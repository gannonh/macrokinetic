# Food data attribution and release evidence

KAT-3593 adds More > General > Food data. The source notices and license URIs are bundled in `JabTracker/Resources/food-data-notices.json`. They remain readable without a network connection; opening external links requires a connection. No product images are added.

## Source licenses

USDA FoodData Central publishes its data in the public domain under CC0 1.0 and requests source credit. See the [USDA licensing statement](https://fdc.nal.usda.gov/api-guide/) and [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

Open Food Facts identifies ODbL 1.0 for its database and DbCL 1.0 for individual contents. Its product images have separate licenses and other possible rights. See the [Open Food Facts licensing guide](https://github.com/openfoodfacts/openfoodfacts-server/blob/main/docs/api/tutorials/license-be-on-the-legal-side.md), [ODbL](https://opendatacommons.org/licenses/odbl/1-0/), and [DbCL](https://opendatacommons.org/licenses/dbcl/1-0/).

ODbL sections 4.2–4.3 require license/source notices and preservation of existing rights notices when distributing the database or publicly using its output. Sections 4.4 and 4.6 require applicable derivative databases to remain under permitted share-alike terms and require an offer of the machine-readable derivative database or alterations. Section 4.7 addresses restrictive distribution and parallel unrestricted copies. The bundled notices carry the license URIs. The snapshot release workflow also attaches the notices alongside the database and manifest.

This implementation does not establish that the combined database satisfies every redistribution obligation. Before distribution, the owner must review its derivative/collective classification, retained upstream notices, applicable terms, and the unrestricted machine-readable offer. App terms must preserve recipients' database-license rights.

## Exact bundled provenance

The release workflow copies the candidate's manifest beside its database before XcodeGen runs. Archive and IPA inspection reject missing notices, missing manifests, mismatched version/build, invalid source metadata, wrong size, or wrong SHA-256. The prior candidate validator checks database schema and actual source row counts. Matching hashes connect those validated bytes to the archived resource; the bundle check does not repeat the full database query validation.

```sh
python3 scripts/release/verify-food-data-bundle.py \
  --app /absolute/path/to/JabTracker.app \
  --expected-version 1.0.0 --expected-build 18 \
  --expected-database-sha THE_EXACT_CANDIDATE_SHA256
```

The app streams the bundled database checksum in a background task when Food data opens. It displays source dates, source URLs, commit, run, and checksum only when the manifest matches the database and app version/build. A missing or mismatched local manifest displays unverified provenance and the actual checksum. The development manifest is ignored by Git and remains optional for local project generation; it is mandatory for release archive validation.

The launch audit found local SHA-256 `b2c637b3cd700350cca0399c7be9456185ce23b4d2fcb55ef0e4b7f2dcc5c5c4`. Published snapshot `food-db-1787353695-41e46303fe82` instead records `58dc3ca8ae9682d298777db62843d40a4317e74f511c018a0ca6eba26b020d26`. Its manifest must not be attached to the local database as matching provenance. No matching public download is asserted for the local database.

Before submission, verify the exact candidate's unrestricted public database or complete alteration offer, source notices, and matching manifest. The workflow's snapshot publication occurs after TestFlight upload and is not proof that an offer is already available when the archive is made. A failed or private snapshot publication remains an acceptance blocker.

## App Review disclosure draft

Food-source credits and offline license notices are available at More > General > Food data. This screen identifies USDA FoodData Central and Open Food Facts, with license links and the bundled database checksum. The candidate's manifest and database must match before this statement is accepted. Add the verified unrestricted download/alteration offer only after its exact bytes and public accessibility have been checked.

## Live acceptance

Scenarios 1 to 10 were exercised on September 30, 2026 on the iOS 27 simulator. Screenshots, the review video and per-scenario notes are in [launch-evidence/KAT-3593](launch-evidence/KAT-3593/README.md). Not performed: a blocked-network run, a spoken VoiceOver pass, and any check against a signed candidate. Unit fixtures and Python checks prove the matching and rejection logic, not license compliance.

Remaining before submission: the exact candidate's manifest, archive and IPA verification; a verified unrestricted public database or alteration offer; and owner-approved distribution terms.
