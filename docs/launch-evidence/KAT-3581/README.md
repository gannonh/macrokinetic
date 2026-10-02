# Prescribed-dose release verification

KAT-3581 disables calculators, titration actions/reminders and concentration estimates while preserving clinician-entered medication/dose records and manual schedules. The registry has fifteen fixed-off flags. Ordinary reminder and stored titration/schedule records remain intact; only pending titration requests are canceled at unconditional startup.

The full Debug unit suite after notification guards passed 3086 tests, zero failures, with one pre-existing disabled authentication test. Result: `/tmp/jabtracker-launch-20260930/medical-full-units-after-notifications.xcresult`. This predates the subsequent raw-text and precision fix and is not verification of that newer code.

The two committed PNGs show actual failed UI readback before that fix: an attempted 2.125 edit reopened as 2.1251, and an attempted 0.375 dose reopened as 0.3751 while History rounded it to 0.38. Screenshots and hierarchy were captured before the failing assertions. They are diagnostic artifacts from fictional data, not accepted launch behavior or App Store screenshots.

The follow-up retains raw text and parses the complete finite positive amount for Save eligibility and at the save boundary. Empty/malformed text cannot save a previous valid value; zero is permitted only for an explicitly skipped dose. Readback retains precision, preserving existing two-decimal labels when exact. Actual Foundation source passed 87 literal parser/formatter checks. Eight new app-unit methods and the corrected UI replacement/relaunch journeys await execution on this source. Compound switches target the observed inner native switch, and History navigation handles the observed retained profile stack.

## Final verification (commit d77775a5 and later documentation commit)

- Full Debug unit target plus MedicalReleaseUITests on one run: 3096 passed, 0 failed, 1 skipped (the pre-existing disabled authentication test). Result bundle: `/tmp/jab-coord/medical/final.xcresult`. The three earlier UI failures are resolved: the compound switch is targeted through its inner native switch, History navigation handles the retained profile stack, and numeric replacement reads back exactly (2.125, 0.375, 0.625; never 2.1251).
- An empty numeric field reports its placeholder as its value, so the UI helper asserts `value == placeholderValue` ("Amount") and a disabled Save before typing the replacement.
- Live checks on the integrated simulator caught two rounding defects the unit tests did not: the medication list row showed 1.375 mg as 1.38 mg and the calendar day detail showed 0.375 mg as 0.4 mg (`live/before-fix-*.png`). Both and the dose action sheet now use `RecordedAmountInput.displayText`.
- Ten scenarios, main vs branch for scenario 1, are in `live/`. Scenario 7 has no live route: the legacy onboarding dose setup view is not referenced from any presented flow, and the add-medication sheet is the only creation path.
- `kat-3581-branch-review-3x.mp4` is a 58 s review video (3.1x speed of the 179 s session).

Not covered: older UI classes that start from a stale "Settings" button in More (MedicationProfileCRUD, Settings, Schedule, DailyMedicationProfileSchedule, Advanced and Calculator UI tests) fail at that navigation step before reaching medical code; they are not changed by this PR. Real notification delivery and signed-device acceptance remain outside this PR.
