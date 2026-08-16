---
name: testflight-release-notes
description: Generate concise, user-facing TestFlight release notes and the App Store Connect “What to Test” text from the commits in a JabTracker release. Use when preparing a TestFlight build, reviewing release metadata, or updating the TestFlight release workflow.
---

# TestFlight release notes

Use this skill when a JabTracker build is being prepared for TestFlight. The
output is the text shown in App Store Connect under Test Details → What to
Test, so keep it short, concrete, and directed at testers.

## Generate notes

Run the repository-owned generator from the repository root. Prefer the latest
app release tag as the exclusive starting revision and the exact commit being
released as the ending revision:

```bash
python3 .agents/skills/testflight-release-notes/scripts/generate_release_notes.py \
  --version 0.10.1 \
  --build 5 \
  --from-ref v0.10.0 \
  --to-ref HEAD \
  --focus "Verify Food Library search returns results without a premature No Results state" \
  --output /tmp/testflight-what-to-test.txt
```

The generated file is bounded to 4,000 characters and is suitable for
Fastlane’s `pilot upload --changelog` option. Review it before a manual
release when the commit subjects are too technical or when a specific UAT
scenario should be called out. Add a `--focus` item for that scenario rather
than editing the workflow.

## Release workflow integration

The TestFlight workflow regenerates this file from the immutable release
commit, passes it to `scripts/release/upload-ipa.sh`, and records its SHA-256
in the delivery receipt and GitHub Actions summary. Fastlane submits it as the
build’s “What to Test” text while the binary is uploaded. A same-run retry
regenerates the same content from the same commit and does not upload a second
binary.

Do not place credentials, API keys, or private tester information in release
notes. Mention observable behavior and the areas that need testing, not
implementation details or internal paths.
