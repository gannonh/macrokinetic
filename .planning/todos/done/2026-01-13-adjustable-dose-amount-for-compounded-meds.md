---
created: 2026-01-13T10:55
title: Allow adjustable dose amount when logging shots
area: ui
files:
  - JabTracker/Views/DoseEntry/QuickDoseSheet.swift
  - JabTracker/Models/MedicationProfile.swift
  - JabTracker/Models/Dose.swift
---

## Problem

Currently, the "Quick Add Dose" sheet shows the dose amount (e.g., "2.50 mg") as a static display based on the medication profile. Users cannot adjust this amount when logging a dose.

For compounded GLP-1 medications, users frequently make subtle dose adjustments:
- Titrating up slowly (e.g., 2.5 → 2.75 → 3.0 mg)
- Testing tolerance with small increases
- Adjusting based on side effects or response
- Splitting doses differently than prescribed

The current UI forces users to either:
1. Edit their medication profile every time they adjust (tedious)
2. Log inaccurate doses (defeats tracking purpose)

Screenshot shows: Tirzepatide (Generic) marked as "Compounded", 2.50 mg Weekly. The dose amount row shows "2.50 mg" but is not interactive.

## Solution

TBD - Possible approaches:

1. **Stepper/Dial control**: Replace static text with a stepper or dial wheel
   - Bounds based on medication type (e.g., Tirzepatide: 0.5-15mg in 0.25mg increments)
   - Default to profile amount, allow adjustment per-log
   - Dose model already stores actual amount, profile is just default

2. **Inline text field**: Tap to edit with numeric keyboard
   - Simpler UI but less discoverable
   - Need validation for reasonable bounds

3. **Preset options**: Quick buttons for common adjustments (+0.5, +1.0, etc.)
   - Combined with custom entry option

4. **Profile vs. logged distinction**: Make it clear that profile = "usual dose" and logged = "what I actually took"

Consider: Should adjusting dose also offer to update the profile? Or keep them separate?
