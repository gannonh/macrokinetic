# KAT-3186 dose-history UI verification

Test-only slice stacked on KAT-3581 (PR #373). History and GLP-1 analytics UI tests now reach the screen through More > GLP-1 Programs > Analytics and assert the observed labels and exact dose content (0.25 mg, 0.50 mg, injection site, date headers, "3 of 3 doses shown") instead of inherited child identifiers. No helper or caller taps the removed Shots tab. No production identifier changed.

## Results on 7ee83685 plus this diff (Debug, iOS 27 simulator, `/tmp/jab-coord/medical/hist.xcresult`)

- DoseHistoryBasicUITests 3/3, DoseHistoryStatesUITests 6/6, DoseHistorySwipeActionsUITests 4/4: pass. DoseHistoryFilteringUITests 10/10: pass. 23 passed in these four classes, 0 skipped.
- AdherenceChartsUITests (4) and AdherenceMetricsDisplayUITests (5) navigate to Adherence correctly but fail on content assertions. Live reproduction with the same 30-day seed (`live/s-adherence-navigation-reaches-content.png`, raw hierarchy) shows the content renders, and that the parent `adherence-section` identifier replaces the child identifiers these tests query (`adherence-metrics-card`, `streak-counters-card`, `adherence-progress-indicator`), the same propagation seen in History. They failed before this change at the Shots tab; rewriting their assertions to labels is a separate slice.
- ConcentrationTimelineChartUITests now route through the current Analytics path but cannot pass on this stack: `concentrationEstimates` is fixed off by KAT-3581, so the Concentration segment is absent. Not run.

## Live scenarios (integrated simulator, `live/`)

1. Empty history on main (Concentration/Adherence/History segments) and on the branch (Adherence/History): `s1-*`.
2. First prescribed dose logged: 0.25 mg, Ozempic, Sep 30, 7:40 PM, accessibility label "0.25 milligrams, Ozempic, at 7:40 PM, injection site Thigh".
3. Search: "Mounjaro" shows 0 of 1 doses, "Ozempic" shows 1 of 1.
4. Cancel on the delete confirmation keeps the record; it is still present after relaunch without reset.

`kat-3186-history-review-2.5x.mp4` is 54 s (2.5x speed of the 127 s session).
