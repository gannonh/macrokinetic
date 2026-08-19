# TestFlight releases

The supported release path is GitHub Actions. A maintainer uses **Actions →
TestFlight Release → Run workflow**, selects exactly one internal group
(`internal`), and optionally supplies a marketing version and build number.
The `internal` group must be configured as an internal explicit-access group;
the App Store Connect `dev` group intentionally has automatic access to all
builds and is not a release target.
The workflow only accepts the `main` branch and never edits
`project.yml`.

## One-time setup

Create a protected GitHub environment named `testflight-release`. Its
deployment branch rule must allow only `main`. Add these environment secrets:

| Secret | Contents |
| --- | --- |
| `ASC_KEY_ID` | App Store Connect team API key ID |
| `ASC_ISSUER_ID` | App Store Connect issuer ID |
| `ASC_PRIVATE_KEY_BASE64` | Base64-encoded `.p8` private key |
| `APPLE_DISTRIBUTION_CERTIFICATE_BASE64` | Base64-encoded Apple Distribution `.p12` |
| `APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD` | Password for the `.p12` |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Base64-encoded App Store provisioning profile |
| `APPLE_KEYCHAIN_PASSWORD` | One-run ephemeral keychain password |

The API key must be able to read builds, read beta groups, upload builds, and
manage internal beta-group build relationships for App Store Connect app
`6757370520`. The signing assets must identify team `ZBZKKWF95G`, bundle
`com.gannonhall.JabTracker`, and the `app-store-connect` distribution method.

Add the repository variable `OFF_FULL_EXPORT_METADATA_URL`. It must point to a
JSON document issued with the configured Open Food Facts full export and shaped
as follows:

```json
{
  "full_export_url": "https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz",
  "covered_through_delta_end": 1762873792,
  "source_sha256": "<64 hexadecimal characters>"
}
```

The cursor is the authoritative full-export coverage boundary. The workflow
rejects metadata for another URL, missing boundaries, and checksum mismatch;
it never substitutes download time or the current delta-index endpoint.

## What a run does

1. Rejects non-`main` refs and invalid inputs before release secrets, database
   work, Xcode, or external writes are reached.
2. Resolves a blank version from the non-commented `MARKETING_VERSION` in
   `project.yml`. A blank build number is the next App Store Connect build for
   that version, or `1` when no build exists.
3. Serializes release runs and repeats the version/build uniqueness check
   immediately before upload.
4. Selects the newest valid immutable `food-db-<epoch>-<sha12>` release,
   applies every contiguous delta, and falls back to a full USDA + Open Food
   Facts rebuild for a missing/stale/invalid snapshot or a gap/overlap.
5. Validates SQLite integrity, schema, source thresholds, FTS parity,
   representative searches, identity uniqueness, provenance, and checksums.
6. Runs the full unit-test suite, archives and exports the exact validated
   database with manual signing, and checks the archive and IPA versions and
   database SHA-256.
7. Generates release notes from the commits since the previous app release,
   submits them to TestFlight as the build’s **What to Test** text, uploads
   once through pinned Fastlane/Transporter, waits up to 60 minutes for the
   exact build, and assigns it to the selected explicit-access group.
8. Publishes the exact tested database as a new immutable GitHub Release only
   after TestFlight assertions pass.

## Retry recovery

If processing or assignment fails after Transporter accepts the IPA, use
**Re-run failed jobs** for the same GitHub Actions run. The delivery and
binding receipts are immutable, run-scoped artifacts. A same-run retry polls
and binds the existing build without uploading again. A different run that
finds the same version/build without matching receipt evidence fails as an
ownership collision.

## Local wrapper

The repository-owned wrapper only dispatches the GitHub workflow; it does not
build, sign, or upload locally:

```bash
scripts/upload-testflight.sh --group internal --version 0.10.2 --build 17 --watch
```

It requires `gh` authentication with Actions access. It rejects invalid group,
version, build, and non-`main` ref values before dispatch.

## Common failures

- **Non-main ref:** dispatch the workflow from `main`.
- **Invalid version/build:** use `X.Y`, `X.Y.Z`, and a positive decimal build.
- **No valid snapshot:** configure `OFF_FULL_EXPORT_METADATA_URL`; the run will
  perform a bounded full rebuild.
- **Snapshot gap or overlap:** expected behavior; the run performs a full
  rebuild rather than applying an unsafe chain.
- **Signing preflight:** rotate the certificate/profile together and confirm
  the team, bundle ID, entitlements, and expiry.
- **Group preflight:** `internal` must exist exactly once, be an internal group,
  and have `hasAccessToAllBuilds=false`. The `dev` group is intentionally not
  validated or assigned because it has automatic access to all builds.
- **Missing Test Details:** the workflow generates notes with the local
  [`testflight-release-notes`](../../.agents/skills/testflight-release-notes/SKILL.md)
  skill and sends them through Fastlane’s `--changelog` option. A missing or
  empty generated file stops the upload before Transporter runs.
- **Ownership collision:** do not reuse a version/build from another run;
  choose the next automatic build or an unused explicit build.
- **Missing authoritative metadata:** publish the metadata document with the
  full export before retrying a full rebuild.

No credential values belong in workflow inputs, logs, artifacts, or this
document.
