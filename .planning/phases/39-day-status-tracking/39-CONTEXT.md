# Phase 39: Day Status Tracking - Context

**Gathered:** 2026-01-14
**Status:** Ready for planning

<vision>
## How This Should Work

Mirroring MacroFactor's proven approach to data quality:

1. **Fasting Days**: When a user does a full-day fast, they should be able to mark it as a fasting day. This tells the algorithm "I intentionally consumed zero calories" so it counts as a 0-calorie day in calculations rather than being skipped as unknown data.

2. **Today Exclusion**: Today should never appear in energy balance calculations. Since the day isn't complete, including partial data skews the averages. Only completed days (yesterday and earlier) should feed into TDEE and energy balance calculations.

3. **Zero-Entry Days**: Days with no food logged (and not marked as fasting) should be skipped entirely in calculations — treated as "we don't know what happened that day."

4. **Partial Days**: Days with some entries are included as-is. If this pollutes the data, the user can either complete the day with estimates or delete all entries to make it a blank day (which then gets skipped).

</vision>

<essential>
## What Must Be Nailed

- **Today excluded from energy balance** — Partial day data should never skew the algorithm
- **Fasting toggle** — Simple way to mark a day as intentionally 0-calorie
- **Keep 28-day lookback** — No change from our current window (MacroFactor uses 21)

</essential>

<specifics>
## Specific Ideas

- MacroFactor's fasting toggle: Navigate to food log, select the day, toggle "Are you fasting?"
- MacroFactor has a "fasting coaching module" in weekly check-ins that prompts about unlogged days
- Consider prompting during weekly check-in about days with no food logged: mark as fasting or leave as skipped

</specifics>

<notes>
## Additional Context

**Research findings from MacroFactor:**
- A single partially logged day can negatively impact expenditure calculation for ~3 weeks (their 21-day window)
- For partial days, MacroFactor suggests either estimating missing entries (±30% is ok) or deleting all entries
- Blank days (no entries) are skipped in calculations
- Fasting days (marked) count as 0-calorie days in calculations

**Current MacroKinetic implementation:**
- Uses 28-day lookback (keeping this)
- Days with 0 calories are already implicitly excluded
- Today IS included if any food is logged (needs fix)
- No fasting toggle exists

</notes>

---

*Phase: 39-day-status-tracking*
*Context gathered: 2026-01-14*
