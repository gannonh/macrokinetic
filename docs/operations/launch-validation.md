# Launch validation

KAT-3589 adds two jobs to CI and Full Validation. `ReleaseHarnessUI` runs selected UI methods serially in the optimized `ReleaseTestHarness` configuration. `Ordinary Release compile` builds the production bundle identifier with the ordinary `Release` compiler inputs. Existing unit, integration, StoreKit, performance, lint and tooling jobs remain enabled.

The launch suite is currently incomplete. `scripts/ci/launch-suite.json` selects only `FoodSearchV08UITests/testSearchShowsRetryableError`, whose prior local result is recorded in the manifest. Four missing critical journey groups keep the readiness gate failed even when that control test passes. The manifest must not be treated as launch acceptance until those groups have verified selections.

## Selected methods and quarantine

The suite schema is version 1. Each entry names an exact `JabTrackerUITests/Class/testMethod` selector, its Swift source, Linear issue, purpose, exercised journeys and prior verification evidence. Validation rejects empty or duplicate selections, class-only filters, methods absent from their declared class, paths outside the UI test source tree and an incompatible scheme or configuration.

After the affected slices are integrated, run their critical journeys against the same candidate and the deterministic 22-food fixture in `ReleaseTestHarness`. Add only methods supported by that run, retain the xcresult reference, map their actual behavior to the required journey groups, and remove a missing-journey entry only when its behavior has passed. Source inspection, Debug passes, and runs against the full production database do not establish acceptance for this fixture and configuration.

`scripts/ci/launch-quarantine.json` explicitly records dormant clinical capabilities, old selectors, stub or conditional suites, and the separate production database benchmark. Each entry has a reason and linked Linear context. It does not add broad skip filters or suppress a selected failure. A selected method that overlaps a quarantined class or method fails the launch gate.

## Runner

The existing CLI remains available. Launch selection uses explicit controls:

```bash
./scripts/test.sh ui \
  --scheme JabTrackerReleaseTestHarness \
  --configuration ReleaseTestHarness \
  --suite-file scripts/ci/launch-suite.json \
  --device-id <owned-simulator-udid> \
  --derived-data <fresh-derived-data-directory> \
  --log-dir <fresh-evidence-directory> \
  --log-only
```

`scripts/verify-test-results.py` reads the actual xcresult summary and test inventory, then exports attachments. Every selected method must appear exactly once with `Passed`. Zero tests, a missing method, a skip, expected failure, extra case, duplicate case, count mismatch, unreadable result or failed attachment export fails the runner. The original xcodebuild failure status remains visible when later diagnostics also fail.

Failed selected search tests retain a screenshot and the application hierarchy through XCTest attachments. The complete xcresult also remains available for crash and launch diagnostics.

## Workflow evidence

`scripts/ci/run-launch-validation.sh harness` owns a fresh simulator, waits for its boot and deletes only that simulator at exit. It records the actual resolved device, runtime and Xcode version. The workflow requests the installed iOS 26.2 iPhone 17 Pro runtime. Prior local evidence from another runtime remains distinct. Test parallelism is disabled; relaunch within a journey keeps that journey's installed data.

`scripts/ci/run-launch-validation.sh release` compiles for a generic iOS Simulator without signing. Both modes require fresh evidence and derived data directories. CI prepares its existing deterministic 22-food database before either mode. Full Validation checks out `CHECKOUT_REF`, resolved from its requested `git-ref` or the calling SHA, in both added jobs. Candidate evidence records the actual checkout SHA and rejects uncommitted source changes.

Each job always uploads its complete evidence directory and fails if no artifact exists. Evidence contains:

- Actual candidate SHA, requested and resolved configuration, Xcode and simulator context.
- Built Info.plist version, build and bundle identifier, executable checksum, build manifest and actual app Swift compiler commands.
- Built database checksum and row count, checked against the prepared 22-food fixture.
- The candidate's complete static `ReleasePolicy.swift` and its exhaustively parsed boolean values, without a fixed feature count.
- Raw logs and statuses; the harness also retains the selected manifest, quarantine inventory, xcresult summary, exact cases, attachment export and xcresult bundle.

Flag evidence is based on policy source associated with the built candidate. Compiled boolean values are not independently sampled from the executable. A missing policy or a policy that no longer has static exhaustive literal decisions fails evidence collection. The harness gate also checks that its retained runner manifest matches the readiness selection.

Ordinary Release evidence uses the existing build-control inspector to reject harness identity or compiler definitions. The simulator compile and 22-food fixture do not establish production database packaging, signed device behavior, CloudKit synchronization or App Store acceptance. Those gates require their own evidence. TestFlight's final build-number resolution and signed archive still follow the release workflow; this earlier compile does not claim to validate that final artifact.

The two new job names can be required by repository protection once their missing launch journeys are populated and verified. This source change does not configure remote branch protection.

## Local plumbing checks

The Python tests use synthetic compiler and xcresult fixtures, without Xcode or simulator execution:

```bash
python3 -W error::ResourceWarning -m unittest \
  scripts.tests.test_test_runner scripts.tests.test_launch_ci \
  scripts.tests.test_ci_lanes scripts.tests.test_build_controls \
  scripts.tests.test_release_tools -q
shellcheck scripts/test.sh scripts/ci/run-launch-validation.sh
actionlint .github/workflows/ci.yml .github/workflows/full-validation.yml
```
