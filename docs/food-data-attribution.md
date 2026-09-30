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

## Pending live acceptance

The issue remains In Progress until the parent verifies these ten scenarios and records main/branch comparison, screenshots, and a 30–60 second video:

1. Compare About on main and the branch.
2. Reach Food data from More > General.
3. Read USDA credit offline.
4. Read OFF and its license notices offline.
5. Open source and license links with a connection.
6. Confirm the screen claims no product-image or trademark license.
7. Read the full notices and checksum at accessibility text sizes.
8. Confirm VoiceOver labels and link names are clear.
9. Verify the exact candidate manifest, archive, IPA, and resource checksum; confirm a missing/mismatched development manifest displays unverified provenance.
10. Make the App Review notes point to these same disclosures and the verified offer.

Python fixture checks prove the validator's rejection behavior. Four Swift provenance tests and the actual Debug app build passed on September 30, 2026. Browser route and local unverified-manifest behavior are recorded in launch-evidence/KAT-3593. These checks do not establish the complete live matrix, signed-candidate or legal acceptance.
