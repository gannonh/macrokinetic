---
created: 2026-01-13T10:58
title: Fix steady state progress calculation showing 2416%
area: analytics
files:
  - JabTracker/Services/PharmacokineticsEngine.swift
  - JabTracker/Views/Dashboard/ConcentrationCard.swift
---

## Problem

The Drug Concentration card on the Dashboard is showing "Steady State Progress: 2,416%" which is mathematically impossible - progress should be capped at 100%.

Screenshot shows:
- Drug: Tirzepatide
- Current Level: 2.85 units
- Next Peak: 2.74 units (in 7h)
- Next Trough: 1.09 units (in 6d)
- Steady State Progress: **2,416%** (should be 0-100%)
- Status: "Steady state achieved" (with full green bar)

User context: 2 doses over 2 weeks (weekly dosing schedule)

The calculation is clearly wrong. Possible causes:
1. Division by wrong value (e.g., dividing by target trough instead of steady state concentration)
2. Not clamping the percentage to 0-100 range
3. Using wrong units in comparison
4. Mismatched time constants in the pharmacokinetic model

## Solution

TBD - Need to investigate:

1. **Find the calculation**: Search `PharmacokineticsEngine.swift` for steady state progress formula

2. **Understand the model**: Steady state for GLP-1s is typically reached after 4-5 half-lives
   - Tirzepatide half-life: ~5 days
   - Steady state: ~20-25 days (4-5 weeks of weekly dosing)
   - After 2 weeks: should be ~50-60% progress, not 2416%

3. **Check the formula**: Progress should likely be:
   ```
   progress = min(1.0, currentConcentration / expectedSteadyStateConcentration)
   ```
   or time-based:
   ```
   progress = min(1.0, weeksSincStart / weeksToSteadyState)
   ```

4. **Clamp output**: Ensure display value is always 0-100%
