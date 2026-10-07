# Candidate evidence inventory

No acceptance evidence is recorded here yet. Do not reuse mocks, fixture successes, or the baseline audit as candidate acceptance.

For each result, record candidate SHA, version/build, device and OS, release flags, production food-database checksum, scenario steps, literal expected/actual values, outcome, and artifact paths. State NOT RUN, FAILED, or UNVERIFIED when appropriate.

`metadata.json` links advertised claims to result files. `assets.json` links the release scope, compiled icon, and each screenshot to evidence. Image checksums identify files; they do not prove the scenario worked.

The validator expects each linked result to be a JSON object with `candidate_sha`, `result` equal to `PASS`, `method`, `reviewed_by`, and a timezone-qualified `recorded_at`. Claim evidence also lists covered IDs in `claims`. Release-scope evidence covers `release_scope`; icon evidence covers `compiled_icon`. Add scenario details and artifact references to the same result. Record failed or unrun checks separately; do not point a readiness claim at them.

The script validates recorded facts, not their truth. The reviewer must inspect the referenced result and artifacts. A JSON file containing `PASS` without an exercised scenario is not acceptance evidence.

Keep secrets, App Review passwords, raw health records, private contact details, certificates, and API keys out of this public repository. Reference an approved external credential location where needed without copying credentials.
