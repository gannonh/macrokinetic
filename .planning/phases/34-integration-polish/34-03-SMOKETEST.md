# Phase 34-03 Smoketest: Detail Views Live Data

**Tester:** _____________
**Date:** _____________
**Build:** `feat/v0.7.0-dashboard-widget-ux`

## Test Setup

1. Run app with test data: `--seed-check-in-ready`
   - Seeds 28 days of weight entries (downward trend with noise)
   - Seeds 21 days of food entries (varied meals)
   - Creates NutritionGoal with TDEE data
2. Navigate to Dashboard tab

## Test Cases

### 1. Weight Trend Detail View 

- [ ] Tap Weight Trend widget on Dashboard
- [ ] WeightTrendDetailView opens
- [ ] Time period selector works (1W/1M/3M/6M/1Y/All)
- [ ] Weight chart displays with data points
- [ ] Trend line (EWMA smoothed) visible
- [ ] Insights section shows:
  - [ ] Weight Changes (3-day, 7-day, etc.)
  - [ ] Current Weight
  - [ ] Weekly Weight Change
  - [ ] Energy Deficit/Surplus
  - [ ] 30-Day Projection
- [ ] Back navigation works

**Result:** PASS / FAIL
**Notes:**

---

### 2. Expenditure Detail View

- [ ] Tap Expenditure widget on Dashboard
- [ ] ExpenditureDetailView opens
- [ ] Time period selector works
- [ ] TDEE chart displays with flux range
- [ ] Insights section shows:
  - [ ] Expenditure Changes
  - [ ] Current Expenditure (TDEE)
  - [ ] Current Strategy (Holding/Updating)
- [ ] Back navigation works

**Result:** PASS / FAIL
**Notes:**

---

### 3. Energy Balance Detail View

- [ ] Tap Energy Balance widget on Dashboard
- [ ] EnergyBalanceDetailView opens
- [ ] Mode toggle works (Expenditure / Calorie Targets)
- [ ] Time period selector works
- [ ] Balance chart displays correctly
- [ ] Insights section shows:
  - [ ] Balance Changes with correct labels per mode
  - [ ] Header value updates per mode
- [ ] Back navigation works

**Result:** PASS / FAIL
**Notes:**

---

## Overall Result

- [ ] **PASS** - All detail views work correctly with live data
- [ ] **FAIL** - Issues found (describe below)

**Issues Found:**

**Sign-off:**
