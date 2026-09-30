# Prescribed-dose release verification

KAT-3581 disables calculators, titration actions/reminders and concentration estimates while preserving clinician-entered medication/dose records and manual schedules. The registry has fourteen fixed-off flags. Ordinary reminder and stored titration/schedule records remain intact; only pending titration requests are canceled at unconditional startup.

The full Debug unit suite after notification guards passed 3086 tests, zero failures, with one pre-existing disabled authentication test. Result: `/tmp/jabtracker-launch-20260930/medical-full-units-after-notifications.xcresult`. This predates the subsequent raw-text and precision fix and is not verification of that newer code.

The two committed PNGs show actual failed UI readback before that fix: an attempted 2.125 edit reopened as 2.1251, and an attempted 0.375 dose reopened as 0.3751 while History rounded it to 0.38. Screenshots and hierarchy were captured before the failing assertions. They are diagnostic artifacts from fictional data, not accepted launch behavior or App Store screenshots.

The follow-up retains raw text and parses the complete finite positive amount for Save eligibility and at the save boundary. Empty/malformed text cannot save a previous valid value; zero is permitted only for an explicitly skipped dose. Readback retains precision, preserving existing two-decimal labels when exact. Actual Foundation source passed 87 literal parser/formatter checks. Eight new app-unit methods and the corrected UI replacement/relaunch journeys await execution on this source. Compound switches target the observed inner native switch, and History navigation handles the observed retained profile stack.

Pending: app compilation and units after the text fix, the integrated optimized harness, exact profile/dose/schedule disk readback, all ten browser scenarios/main comparison, 30–60 second review video, real notification delivery and signed-device acceptance. Keep the PR draft until its build gates are met.
