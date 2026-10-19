# KAT-3586 evidence: launch 1.0 without sign-in

Simulator "KAT3586" (iPhone 18 Pro, iOS 27.0), Debug builds, `--disable-cloudkit` so no iCloud is touched.
`main` = 59abf387, branch = b0511776 (app sources identical to 589f49e9). Reproduce with
`docs/launch-evidence/KAT-3586/live-checks.sh` on the branch.

How the upgrade states were made: `main` was installed and launched with
`--ui-testing --seed-1-month-active` (1 User, 4 doses, 1 medication profile, 1 goal, 30 weights, 97 food entries,
onboarded). The branch build was then installed over it (same bundle id, same data container) and launched the
way a phone launches it (no `--ui-testing`). Each state was set with sqlite3 on `default.store` before upgrade:

| State | Store edit before upgrade |
| --- | --- |
| signed in | `ZUSER.ZAPPLEUSERID = '001234.live-check'` |
| Apple ID erased | `ZAPPLEUSERID = NULL` |
| signed out | delete ZUSER and what logout cascaded (doses, medication profiles, goals); weights and food entries stay (no User relationship) |

See `results-upgrade-scenarios.md` and `results-lock-scenarios.md` for the raw output.
