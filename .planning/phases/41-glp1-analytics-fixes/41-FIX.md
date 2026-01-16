---
phase: 41-glp1-analytics-fixes
plan: 41-FIX
type: fix
wave: 1
depends_on: []
files_modified:
  - JabTracker/AuthenticationManager.swift
  - JabTracker/Models/ChartData.swift
  - JabTracker/Services/ChartDatasetService.swift
autonomous: true
---

<objective>
Fix 3 UAT issues from phase 41.

Source: 41-UAT.md
Diagnosed: yes - all root causes identified via debug sessions
Priority: 0 blocker, 3 major, 0 minor, 0 cosmetic
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/execute-plan.md
@~/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/ROADMAP.md

**Issues being fixed:**
@.planning/phases/41-glp1-analytics-fixes/41-UAT.md

**Original plans for reference:**
@.planning/phases/41-glp1-analytics-fixes/41-01-PLAN.md
@.planning/phases/41-glp1-analytics-fixes/41-02-PLAN.md
</context>

<tasks>
<task type="auto">
  <name>Fix UAT-001: Steady state progress shows 0% instead of ~36%</name>
  <files>JabTracker/AuthenticationManager.swift</files>
  <action>
**Root Cause:** MedicationProfile created without explicit medicationType parameter in AuthenticationManager.swift:1297. The fallback logic leaves medicationType as empty string, causing medicationProfile.medication to return nil, which makes calculateSteadyStateProgress return 0.0.

**Issue:** Shows 0% instead of expected ~36% (9 days on medication / 25 days to steady state)

**Expected:** ConcentrationCard shows steady state progress as a percentage between 0-100%

**Fix:** Add `medicationType: config.medication.rawValue` parameter to the MedicationProfile initialization at line ~1297 in AuthenticationManager.swift. Find where MedicationProfile is created during authentication/setup and ensure the medicationType is passed through from the config.
  </action>
  <verify>
- Build succeeds
- Steady state progress displays correct percentage (not 0% for users on medication)
  </verify>
  <done>UAT-001 resolved - MedicationProfile now receives medicationType parameter</done>
</task>

<task type="auto">
  <name>Fix UAT-002: Concentration chart shows single bar instead of histogram</name>
  <files>JabTracker/Models/ChartData.swift, JabTracker/Services/ChartDatasetService.swift</files>
  <action>
**Root Cause:** Insufficient data point density. Chart uses BarMark correctly but concentration data is sampled at 2-hour intervals instead of 30-minute intervals, resulting in too few data points to form a proper histogram.

**Issue:** Shows single vertical bar at one time point instead of multiple bars across time axis. Not a histogram - should show concentration values at regular intervals (hourly) over the time period.

**Expected:** Concentration chart displays as vertical bars (histogram) with bars at regular intervals across the time axis.

**Fix:**
1. In ChartData.swift lines 160-165: Change InterpolationSettings.pharmacokinetic default from `intervalHours: 2.0` to `intervalHours: 0.5`
2. In ChartDatasetService.swift line ~746: Update any hardcoded `intervalHours: 2.0` to `intervalHours: 0.5`

This will generate 4x more data points, creating a proper histogram appearance.
  </action>
  <verify>
- Build succeeds
- Concentration chart shows multiple bars across time axis (not single bar)
  </verify>
  <done>UAT-002 resolved - Histogram shows proper bar density with 30-minute sampling</done>
</task>

<task type="auto">
  <name>Fix UAT-003: Therapeutic range band not visible on chart</name>
  <files>JabTracker/Services/ChartDatasetService.swift, JabTracker/Models/ChartData.swift</files>
  <action>
**Root Cause:** Default chart configuration uses ConcentrationRange.automatic instead of .therapeuticWindow. The RectangleMark rendering is guarded by pattern match on .therapeuticWindow which never succeeds.

**Issue:** No therapeutic range band visible on the chart

**Expected:** Blue therapeutic range band is visible behind/through the concentration bars (bars have 0.8 opacity)

**Fix:**
1. In ChartDatasetService.swift generateChartDataset() method (lines ~54-58, 89-93): Extract the medication's therapeutic window values from the medication profile
2. Pass `.therapeuticWindow(min:max:optimal:)` to the chart configuration instead of using `.default` which defaults to `.automatic`
3. The medication's therapeutic range can be obtained from `medication.therapeuticRange` (min/max/optimal values)

The chart view already has code to render RectangleMark when configuration is .therapeuticWindow - it just needs the correct configuration passed in.
  </action>
  <verify>
- Build succeeds
- Concentration chart shows blue therapeutic range band behind bars
  </verify>
  <done>UAT-003 resolved - Chart configuration uses therapeuticWindow instead of automatic</done>
</task>
</tasks>

<verification>
Before declaring plan complete:
- [ ] All 3 major issues fixed
- [ ] Build succeeds without errors
- [ ] Each fix verified against original reported issue
</verification>

<success_criteria>
- All UAT issues from 41-UAT.md addressed
- Build passes
- Ready for re-verification with /gsd:verify-work 41
</success_criteria>

<output>
After completion, create `.planning/phases/41-glp1-analytics-fixes/41-FIX-SUMMARY.md`
</output>
