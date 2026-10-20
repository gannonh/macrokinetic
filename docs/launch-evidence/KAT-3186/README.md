# KAT-3186 dose-history UI verification

Test-only slice stacked on KAT-3581 (PR #373). History and GLP-1 analytics UI tests now reach the screen through More > GLP-1 Programs > Analytics and assert the observed labels and exact dose content (0.25 mg, 0.50 mg, injection site, date headers, "3 of 3 doses shown") instead of inherited child identifiers. No helper or caller taps the removed Shots tab. No production identifier changed.

## Results (Debug, iOS 27 simulator, source = this branch; bundle `/tmp/jab-coord/medical/hist3.xcresult`, not committed)

33 passed, 0 failed, 0 skipped across DoseHistoryBasic (3), DoseHistoryStates (6), DoseHistorySwipeActions (4), DoseHistoryFiltering (10), AdherenceCharts (4), AdherenceMetricsDisplay (5) and ConcentrationTimelineChart (1).

- Adherence classes were rewritten debug-first. A raw hierarchy dump on the live simulator showed the parent `adherence-section` identifier replacing the child identifiers the old tests queried, so the tests now find elements by exact label and value (`Adherence rate: 100%, Excellent adherence` = 100%, `Current streak: 1 day`, `Best streak: 1 day`, goal 100% against 80% target, `Current trend: Stable`, `Total missed doses: 0`) using three deterministic 100%-adherence seeded doses. No production identifier changed.
- `testAdherenceMetricsUpdate` exposed a helper defect: the More tab keeps its navigation stack, so after returning from Dashboard the GLP-1 screen is already open. `navigateToGLP1Analytics` now checks for the open picker before looking for the More row.
- ConcentrationTimelineChartUITests: `testConcentrationSegmentIsAbsentUnderLaunchPolicy` (class `ConcentrationLaunchPolicyUITests`) runs and asserts the picker offers exactly Adherence and History. The former chart tests stay in the file and run instead when `ReleasePolicy.isEnabled(.concentrationEstimates)` is true: `ReleasePolicy.swift` is compiled into the UI test target and each class overrides `defaultTestSuite`, so exactly one of the two contributes tests (no skips).

## Live scenarios (integrated simulator, `live/`)

1. Empty history on main (Concentration, Adherence, History) and branch (Adherence, History): `s1-main-empty-history.png`, `s1-branch-empty-history.png`.
2. Empty state label and CTA: "No doses logged yet" with "Log Your First Dose" in `s1-branch-empty-history.png`.
3. First prescribed dose: `s2-branch-first-dose-in-history.png` (0.25 mg, Ozempic, "0.25 milligrams, Ozempic, at 7:40 PM, injection site Thigh").
4. Multiple dates group: `s4-multiple-dates-grouped.png` (Oct 1, Sep 24, Sep 17, "3 of 3 doses shown").
5. Search: `s3-branch-search-mounjaro-no-match.png` (0 of 1), `s3-branch-search-ozempic-match.png` (1 of 1).
6. Edit prepopulates exact values: `s6-edit-prepopulated-exact.png` (Ozempic 0.25 mg, Abdomen, Oct 1, 7:12 AM).
7. Cancel delete preserves: `s4-branch-delete-confirmation.png`, `s4-branch-after-cancel-delete.png`.
8. Swipe delete removes only the intended record: `s8-delete-confirmation.png`, `s8-after-delete-two-remain.png` (Sep 24 removed; Oct 1 and Sep 17 remain).
9. Analytics navigation: `s9-analytics-opens-adherence-history-no-concentration.png`, `s9-adherence-content.png` (Adherence and History only; Adherence content renders).
10. Relaunch without reset keeps exact history: `s10-relaunch-keeps-exact-history.png` (2 of 2 doses), plus `s4-branch-history-after-relaunch.png`.

Videos: `kat-3186-history-review-2.5x.mp4` (54 s) and `kat-3186-multi-record-review.mp4` (41 s), both sped-up sessions.
