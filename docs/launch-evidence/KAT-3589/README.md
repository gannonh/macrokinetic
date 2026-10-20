# KAT-3589 launch suite evidence

These are excerpts from real `macos-26` runner artifacts. The complete artifacts are `launch-harness-39456462407`, `launch-release-39456462407` and `full-validation-launch-harness-39456534598`, with 7-day retention. They contain the xcresult, raw logs, attachments, hierarchy text and all screenshots.

| Scenario | Run | Result | Files |
| --- | --- | --- | --- |
| 1. PR trigger runs the named suite | CI [39456462407](https://github.com/gannonh/macrokinetic/actions/runs/39456462407) (`pull_request`, merge ref `6a4e34b4`) | 11/11 passed, 0 skipped. Gate exit 0, with KAT-3588 reported as pending | `pr-ci-39456462407/` |
| 2. Release validation runs the exact candidate tests | Full Validation [39456534598](https://github.com/gannonh/macrokinetic/actions/runs/39456534598) (`d1b2bbe2`) | The same 11 tests passed. Gate exit 1 because onboarding (KAT-3588) is not selected yet | `full-validation-39456534598/` |
| 3. Zero, missing, skip or failure blocks the gate | Full Validation above, plus the verifier against the real PR xcresult | Pending journey: exit 1. Missing method: exit 1. Extra method: exit 1. Exact selection: exit 0. Zero, skip, failure and expected-failure cases are covered by `scripts/tests/test_test_runner.py` | `verifier-negatives/`, `full-validation-39456534598/launch-gate.txt` |
| 4. Artifacts identify SHA, version, device, configuration and flags | Both runs | `candidate-evidence.json`: SHA, `ReleaseTestHarness`, `com.gannonhall.JabTrackerTestHarness` 0.10.1 (16), iOS 26.2 iPhone 17 Pro, Xcode 26.5 (17F42), the 22-food fixture SHA, and all 15 `ReleasePolicy` values (all false) | `*/candidate-evidence.json`, `pr-ci-39456462407/context.json` |
| Ordinary Release compile | CI 39456462407 | Release `com.gannonhall.JabTracker` built. Evidence status Passed | `release-compile-39456462407/` |

The fixture is the deterministic 22-food CI database (`production_database_acceptance: false`). Production-database and signed-device checks stay separate.

The `FAILURE--` screenshots in the full artifact come from passing tests. The `hasSucceeded` tearDown guard used across many classes is still false during tearDown. That is tracked in [KAT-3788](https://linear.app/kata-sh/issue/KAT-3788). This PR fixes its own `FoodSearchV08UITests` guard.
