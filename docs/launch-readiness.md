# Launch readiness

**Submission readiness: BLOCKED.** This is the delivery and evidence index for the [1.0 launch epic](https://linear.app/kata-sh/issue/KAT-3185) and the [App Store packet](app-store/README.md). Linear owns issue scope, dependencies, acceptance criteria, and status. This document records a snapshot; refresh it when the candidate or work states change.

**Status snapshot:** September 30, 2026, 22:01 UTC. The project issue list, milestone descriptions, relevant issue relations, open GitHub PRs, local source identities, and saved test summaries were read for this update. None of the 21 launch children was Done. No launch merge or submission is recorded. Successful checks on separate branches do not establish one submission candidate.

## Scope and artifact identity

The app displays **MacroKinetic**; JabTracker is the internal project name. Keep that public name until the owner confirms branding and rights. The intended launch supports standalone nutrition logging, body-measurement recording, and optional recording of prescribed GLP-1 doses.

Release-default-off scope covers subscriptions/paywall, AI food tools, recipes, unfinished manual food creation, progress-photo capture, manual onboarding, and drug-dose/reconstitution calculators. Verify every entry point and dependent computation, preserve existing records, and keep complete logging flows usable. Turning off unfinished manual onboarding does not establish that every existing manual nutrition strategy is unfinished. [KAT-3580](https://linear.app/kata-sh/issue/KAT-3580) and [KAT-3581](https://linear.app/kata-sh/issue/KAT-3581) own the exact release behavior.

| Identity | Recorded value | Meaning |
| --- | --- | --- |
| Initial audit source | `35c7a1959a805331ccc09a2821b8d801f42efc3c` | Baseline findings, not current acceptance. See the [source audit](app-store/launch-audit.md). |
| Local `main` at snapshot | `edd81bd73ee84bf7cddf1e6fa62a3736f88a70fe` | Clean checkout, observed locally. It does not include the open launch PRs. |
| Packet branch before this documentation update | `63e492d76ac7e94bdbc546531477802ce9773521` | Draft resources in PR #367, not an app candidate. |
| Submission candidate | **Unassigned** | SHA, version, build, database checksum, release flags, signed archive, and export evidence must agree. |

The source configuration at audit was version 0.10.1/build 16. The packet proposes 1.0.0 without changing app configuration or assigning a build number. An unsigned simulator Release build and `ReleaseTestHarness` are useful verification artifacts; neither is a signed submission archive. The harness has its own identity and must never be distributed as the app.

## Gates and delivery order

These summarize the live Linear milestone conditions. Every in-scope child must be Done with its own acceptance evidence. Milestone progress percentages and automatic parent closure do not prove PASS.

| Milestone | PASS requires |
| --- | --- |
| Gate 0: Safe launch scope | Default-off unfinished/ineligible surfaces in Release; usable core logging; proved data-loss fixes; packaged privacy manifest; health-data persistence matching the explicit owner decision and Apple policy. Source review and unit tests alone do not pass the gate. |
| Gate 1: Critical journeys verified | Candidate-release onboarding, nutrition-only, medication, persistence, offline, permissions, notifications, accessibility, and upgrade journeys; reproducible artifacts; mandatory UI CI/release validation; required live device/cloud evidence; exact candidate SHA and explicit NOT RUN checks. |
| Gate 2: App Store submission packet | Evidenced copy, authentic candidate screenshots, production icon, functioning public resources, food attribution, accurate privacy/age answers, reviewer notes, eligible archive, external TestFlight evidence, and verified owner-controlled Connect facts. Prepared resources remain distinct from submission approval. |

Use this delivery order while allowing independent work in parallel. Each issue keeps its own branch, PR, and evidence; Linear's issue-specific dependencies remain authoritative.

| Order | Tickets and snapshot state | Demonstrable outcome / next dependency |
| --- | --- | --- |
| 1 | [KAT-3579](https://linear.app/kata-sh/issue/KAT-3579), [KAT-3596](https://linear.app/kata-sh/issue/KAT-3596): Human Review | Reliable failure/evidence handling and reproducible generation. Both are in human-owned stand-down. |
| 2 | [KAT-3580](https://linear.app/kata-sh/issue/KAT-3580), [KAT-3597](https://linear.app/kata-sh/issue/KAT-3597), [KAT-3581](https://linear.app/kata-sh/issue/KAT-3581): In Progress | Exercise core flows with unfinished surfaces and clinical calculators off; exclude test authentication/reset/seed controls from ordinary Release. |
| 3 | [KAT-3583](https://linear.app/kata-sh/issue/KAT-3583), [KAT-3585](https://linear.app/kata-sh/issue/KAT-3585): In Progress | Durable-store failure/recovery without temporary writes; actual bundled privacy manifest and accurate permissions. |
| 4 | [KAT-3584](https://linear.app/kata-sh/issue/KAT-3584), [KAT-3582](https://linear.app/kata-sh/issue/KAT-3582): Todo | Resolve health-sync policy and legacy account ownership, then prove logout retention and same/different-identity behavior. Policy implementation may need new scoped slices. |
| 5 | [KAT-3586](https://linear.app/kata-sh/issue/KAT-3586): Todo | Explicit account/data deletion after the account and persistence decisions. It is distinct from logout. |
| 6 | [KAT-3186](https://linear.app/kata-sh/issue/KAT-3186), [KAT-3598](https://linear.app/kata-sh/issue/KAT-3598): In Progress | Current dose-history navigation and populated food details with literal values and relaunch persistence. Reconcile History with the new prescribed-amount input. |
| 7 | [KAT-3587](https://linear.app/kata-sh/issue/KAT-3587), [KAT-3588](https://linear.app/kata-sh/issue/KAT-3588): Todo | Nutrition-only totals and persistence; usable first-run onboarding with denied permissions. Reuse verified food behavior rather than count its tests as the whole journey. |
| 8 | [KAT-3589](https://linear.app/kata-sh/issue/KAT-3589): Todo | Enforce the verified exact launch selectors in PR and Full Validation, rejecting missing, empty, failed, or skipped required tests. Its recorded blockers are KAT-3579, KAT-3581, KAT-3186, KAT-3587, and KAT-3588. |
| 9 | [KAT-3590](https://linear.app/kata-sh/issue/KAT-3590): Todo | Upgrade retention and offline recovery on the integrated release candidate after account/persistence decisions. |
| Parallel packet work | [KAT-3591](https://linear.app/kata-sh/issue/KAT-3591), [KAT-3593](https://linear.app/kata-sh/issue/KAT-3593): In Progress; [KAT-3592](https://linear.app/kata-sh/issue/KAT-3592): Todo | Draft copy, actual-screen capture plan, and food notices; finalize and wire public pages after owner facts and policy resolve. |
| Final candidate | [KAT-3594](https://linear.app/kata-sh/issue/KAT-3594), [KAT-3595](https://linear.app/kata-sh/issue/KAT-3595): Todo | Eligible signed archive/export, independent signed-device verification, external TestFlight and Connect evidence tied to the same candidate. |

Each screen slice requires its issue's ten live scenarios, including main/branch comparison, screenshots, and a 30–60 second Human Review video before leaving draft. Chores require their four stated scenarios. Unit checks and selected UI regressions do not replace those acceptance gates. Merge only from Merging; Human Review does not authorize further coding/review activity or merging.

## Existing ticket disposition

The launch epic replaces the imported GitHub launch checklist. GitHub issues remain inbound context; implementation is specified in Linear.

| Original ticket | Disposition and reason |
| --- | --- |
| [KAT-3185](https://linear.app/kata-sh/issue/KAT-3185) | Retained as the launch epic and gate owner. Live reads at 22:01 and 22:06 UTC returned Backlog; the grouping state does not establish child acceptance. |
| [KAT-3186](https://linear.app/kata-sh/issue/KAT-3186) | Retained in Gate 1 and narrowed to current dose-history verification. |
| [KAT-3187](https://linear.app/kata-sh/issue/KAT-3187) | Post-launch Backlog: calorie expenditure enhancements; do not expand algorithms during launch hardening. |
| [KAT-3188](https://linear.app/kata-sh/issue/KAT-3188) | Post-launch Backlog: remaining design-token adoption. |
| [KAT-3189](https://linear.app/kata-sh/issue/KAT-3189) | Post-launch Backlog: existing view-model Observation migration. |
| [KAT-3190](https://linear.app/kata-sh/issue/KAT-3190) | Post-launch Backlog: custom-food creation from the Food Library; unfinished entry points are release-off. |
| [KAT-3191](https://linear.app/kata-sh/issue/KAT-3191) | Post-launch Backlog: CloudKit test-warning isolation; persistent acceptance tests must not be weakened into in-memory tests. |
| [KAT-3192](https://linear.app/kata-sh/issue/KAT-3192) | Post-launch Backlog: subscription grace/retry/revocation; subscriptions are release-off. |
| [KAT-3193](https://linear.app/kata-sh/issue/KAT-3193) | Post-launch Backlog: broader performance, visual, and accessibility coverage. Critical launch accessibility checks still belong in Gate 1. |
| [KAT-3194](https://linear.app/kata-sh/issue/KAT-3194) | Post-launch Backlog: asset-symbol refactor. |

The runner's explicit artifact-directory concurrency race is separately tracked in [KAT-3599](https://linear.app/kata-sh/issue/KAT-3599), Backlog. It is not claimed fixed by KAT-3579. Deferred photo attachments remain inbound context; hiding unmanageable capture avoids adding that feature to launch.

## Open PR snapshot

| PR | Issue / Linear state | Draft | Observed head |
| --- | --- | --- | --- |
| [#364](https://github.com/gannonh/macrokinetic/pull/364) | KAT-3596 / Human Review | No | `51c9a1a` |
| [#365](https://github.com/gannonh/macrokinetic/pull/365) | KAT-3579 / Human Review | No | `eefb31e` |
| [#366](https://github.com/gannonh/macrokinetic/pull/366) | KAT-3585 / In Progress | Yes | `ac5589a` |
| [#367](https://github.com/gannonh/macrokinetic/pull/367) | KAT-3591 / In Progress | Yes | `63e492d` |
| [#368](https://github.com/gannonh/macrokinetic/pull/368) | KAT-3580 / In Progress | Yes | `f9c66f6` |
| [#369](https://github.com/gannonh/macrokinetic/pull/369) | KAT-3597 / In Progress | Yes | `9f5e722` |
| [#370](https://github.com/gannonh/macrokinetic/pull/370) | KAT-3598 / In Progress | Yes | `4bf867e` |

This snapshot does not certify merge readiness. Current review threads and required checks must be refreshed at the issue's authorized review phase. No PR was listed for the other active slices at this snapshot.

**Later checkpoint — September 30, 2026, 22:07 UTC:** [PR #371](https://github.com/gannonh/macrokinetic/pull/371), KAT-3583, was open and draft at `264472a74e53e87e70d90a5ebe49a64beca34cad`; the issue remained In Progress. The live KAT-3185 read still returned Backlog. This update does not change the earlier seven-PR snapshot or assert new review/CI acceptance.

## Verified evidence and remaining coverage

The following results are local, branch-specific proof. Operator artifacts currently live under `/tmp/jabtracker-launch-20260930/`; preserve reviewable copies with the owning PR before relying on them as durable candidate evidence. The local UI artifacts use iOS 27 Simulator; they do not prove the configured CI runtime or physical-device behavior.

| Slice | Observed result | Limit / next proof |
| --- | --- | --- |
| Runner | 19 CLI regressions; real failing run retained screenshots and exit status 65. Historical review checkpoint records six successful CI jobs for PR #365. | Human Review stand-down. Reuse its xcresult verifier; do not substitute historical CI for a current check refresh. |
| Flags | 78 unit tests passed with zero failures/skips; initial UI selection had 2 passes and 1 failure. | Blank food details reproduced on main and became KAT-3598. Rerun the combined release scope; ten live scenarios remain required. |
| Privacy | Unsigned Release simulator bundle contained one root privacy manifest and the intended purpose strings (`privacy-bundle-inspection.json`). | Collection/storage decisions and signed archive inspection remain open. |
| Dose History | `history-full-after.xcresult`: 13 passed, zero failed/skipped, main scheme Debug. | Three add/edit tests use controls changed by calculators-off work. Reconcile and rerun all selectors in the integrated Release harness. |
| Food details | `food-detail-regressions.xcresult`: 3 passed, zero failed/skipped, Debug; selected 200g salmon has literal 416 calories, 40g protein, 26g fat, 0g carbs; relaunch and cancel/reselection asserted. | These do not establish all nutrition-only, meal/date, dashboard, edit/delete/clear-day, or offline acceptance. |
| Test controls | Debug, ordinary Release, and ReleaseTestHarness compiled. Release had no test compilation conditions; harness had its explicit condition and separate bundle identity (`controls-actual-build-evidence.json`). A retry UI test passed in the harness. | Combined hostile-input simulator check retained the same fictional record. Signed archive/export and real Apple authentication remain unverified. |
| Storage recovery | `storage-units-summary.json`: 11 Debug tests passed, zero failed/skipped. `storage-ui-blocking-summary.json`: 7 Release-harness UI tests passed, zero failed/skipped. | Three food-dependent storage UI scenarios await the compound checkout; do not count them as passed. |
| Store packet | Nine targeted CLI regressions and 84 Python tests passed at packet creation. Draft validation passed and strict readiness validation rejected missing facts/assets. | Historical tooling evidence is not candidate evidence. All advertised claim evidence, screenshots, compiled icon, and owner approvals remain absent. |

**Additional evidence checked at 22:07 UTC:** `attribution-units.xcresult` contains four Passed FoodDatabaseProvenanceTests in the Debug unit bundle, with zero failed/skipped tests. They cover exact matching provenance, changed database/app build, missing manifest, and unsupported schema. `attribution-built-bundle.json` records the actual Debug bundle (`com.gannonhall.JabTracker`, 0.10.1/build 16) with USDA/OFF notices and the local database checksum below. The manifest is absent, so that bundle proves packaged source notices and truthful unverified development provenance, not release readiness. KAT-3593's ten live scenarios, matching candidate manifest, exact public offer, and signed archive/IPA checks remain pending.

KAT-3589 must select exact, already verified enabled test methods and preserve xcresult, logs, screenshots/hierarchy, discovery counts, SHA/version/build, configuration, runtime, flags, and fixture identity. Reuse the runner's result parser and fail on absent expected selectors, zero execution, failure, or required skips. A Release harness tests disk/relaunch behavior with the 22-food fixture; ordinary Release compile/authentication and signed production-database/device checks need their own evidence.

Legacy calendar/statistics, program/strategy, and rollover stub suites; disabled manual-auth coverage; clinical surfaces that are release-off; and assertions that merely return true must have an explicit quarantine inventory with linked tickets. They must not inflate launch coverage. The existing unit/integration lane inventory excludes UI; it is not a passing launch suite.

## Exact owner and candidate blockers

1. **Health-data storage policy — KAT-3584.** The repository requires cross-device CloudKit sync, while the audited schema stores personal health records and HealthKit imports. Apple guideline 5.1.3(ii) prohibits personal health information in iCloud. Record an explicit owner-approved resolution and any needed eligibility advice, then scope migration and durability work. Private CloudKit alone does not settle the conflict. [Apple App Review guidelines](https://developer.apple.com/app-store/review/guidelines/).
2. **Legacy account ownership — KAT-3582.** Existing Apple identity/record ownership and unscoped food, weight, and metrics records need a recovery/migration rule. Do not guess that a new Apple identity owns another identity's health history. Prove same-identity restoration, different-identity separation, signed-out persistence, and revoked/offline credential behavior.
3. **Publisher facts — KAT-3591/KAT-3592.** Confirm public name and asset rights; legal seller/entity; public and legal contact; owned domain and publication authority; real support/privacy/terms URLs. No identity, contact, domain, or rights have been invented. The [public drafts](app-store/public/README.md) visibly retain unresolved facts and storage policy.
4. **Privacy and account lifecycle — KAT-3584/KAT-3585/KAT-3586.** Confirm actual collection, processors, storage/sync/backup, retention, and deletion using the final candidate. Privacy labels and deletion promises must match implementation and the approved policy.
5. **Connect and distribution facts — KAT-3594/KAT-3595.** Verify launch regions, age answers/minimum age, substantiated medical-device declaration, pricing/agreements and applicable seller requirements, export answers, reviewer contact/access, production signing/entitlements, and external TestFlight. Credential availability and live Connect configuration have not been established by source inspection.
6. **Exact food snapshot — KAT-3593/KAT-3594.** The local database hash `b2c637b3cd700350cca0399c7be9456185ce23b4d2fcb55ef0e4b7f2dcc5c5c4` differs from the downloaded public snapshot manifest hash `58dc3ca8ae9682d298777db62843d40a4317e74f511c018a0ca6eba26b020d26` (tag `food-db-1787353695-41e46303fe82`). Do not label the local file as that published snapshot. Bundle matching provenance and prove exact checksums. Confirm the normalized database's license obligations, retained notices, and any required unrestricted machine-readable offer; do not invent an endpoint or assert uncertain compliance. [USDA guide](https://fdc.nal.usda.gov/api-guide/), [Open Food Facts license guide](https://github.com/openfoodfacts/openfoodfacts-server/blob/main/docs/api/tutorials/license-be-on-the-legal-side.md), [ODbL](https://opendatacommons.org/licenses/odbl/1-0/).
7. **One integrated signed candidate — KAT-3590/KAT-3594/KAT-3595.** Preserve exact records through upgrade, prove offline/permission/notification/authentication behavior on required devices, inspect the eligible signed export, and identify the same candidate in every final resource. No separate-branch result closes this requirement.

## Submission resource readiness

The [packet](app-store/README.md) is **IN PROGRESS**. [Metadata](app-store/metadata.json) is conditional draft copy; every claim lacks candidate evidence. [Assets](app-store/assets.json) has an unassigned candidate, no compiled icon, and five pending screenshot slots. [Owner inputs](app-store/owner-inputs.json) has ten unresolved entries. Review instructions, privacy data flow, age/medical worksheets, public-page drafts, capture storyboard, and the validator are prepared for completion.

Source-only work can refine copy, worksheets, source notices, and the evidence inventory. It cannot supply authentic final UI images, a compiled candidate icon, live URL checks, owner facts, or signed acceptance. Measurement copy is now limited to recording through Add (+) → Metrics → Log Metrics. The `metrics_recording` claim and recording-form screenshot remain pending candidate evidence. More → Metrics opens visibility settings. No measurement-history screen is advertised, and no feature was added to justify marketing copy.

After an integrated candidate is available, capture full-resolution supported iPhone PNGs with fictional data, preserve their exact bytes and candidate identity, review content, and export the icon from the same archive. Follow the [capture plan](app-store/screenshots/README.md) and [evidence requirements](app-store/evidence/README.md). Mock screenshots, generated app UI, and clinical artwork cannot substitute for those assets.

Run `python3 scripts/app-store.py validate` for draft consistency and `python3 scripts/app-store.py validate --ready` for the strict packet gate. The strict gate must remain nonzero while facts, claim evidence, or reviewed candidate images are absent. A passing packet validator still needs independent signed-candidate and owner verification under KAT-3595; it does not authorize publishing, upload, or submission.
