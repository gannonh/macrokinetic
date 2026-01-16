---
created: 2026-01-16T00:00
title: Robust E2E tests with deterministic data validation
area: testing
files:
  - JabTrackerUITests/
  - JabTracker/Services/TDEECalculator.swift
  - JabTracker/Services/PharmacokineticEngine.swift
  - JabTracker/Views/Dashboard/
---

## Problem

Algorithmic regressions occur frequently during development, breaking core calculations without being caught until manual testing or user reports. Current E2E tests focus on UI interactions but don't validate computational correctness.

Key areas needing deterministic validation:
- **TDEE calculations**: Calorie expenditure algorithms, BMR formulas, activity factors
- **Pharmacokinetics**: Concentration curves, steady state progress, dose timing
- **Dashboard aggregations**: Multi-day averages, progress metrics, trend calculations
- **Nutrition math**: Macro totals, serving conversions, energy balance

Without deterministic test data, each test run uses different seeded data making it impossible to assert specific numeric outcomes.

## Solution

Create E2E test infrastructure with:

1. **Deterministic test fixtures** - Known input data with pre-calculated expected outputs
2. **Snapshot validation** - Compare algorithm outputs against golden values
3. **Calculation-specific test cases** covering:
   - TDEE with various biometric profiles
   - PK curves at specific time points
   - Dashboard aggregations over fixed date ranges
   - Nutrition totals for known food combinations

Consider:
- Test data seeding mechanism that bypasses CloudKit
- Golden file approach for complex calculation results
- Tolerance thresholds for floating-point comparisons
- CI integration to catch regressions before merge
