---
created: 2026-01-16T06:15
title: Fix next dose schedule calculation off by 10 days
area: analytics
files:
  - JabTracker/Views/Medication/MedicationDetailView.swift
  - JabTracker/Services/DoseScheduleService.swift
---

## Problem

The next scheduled dose calculation is incorrect. With weekly dosing:

- Doses taken: Jan 7 and Jan 14, 2026
- Expected next doses: Jan 21 and Jan 28 (7 days after last dose)
- Actual displayed: Jan 24 and Jan 31 (10 days after last dose)

This appears in both:
1. Drug Profile view showing "Next Dose: 7 days - January 24, 2026"
2. Calendar view showing hollow dots on 24th and 31st instead of 21st and 28st

The offset is exactly 3 days, which suggests:
- Possible date calculation using wrong reference point (start date vs last dose date)
- May be counting from medication start date (Jan 7) + some multiplier instead of last actual dose

## Solution

TBD - Need to investigate:

1. How `nextScheduledDose` is calculated in DoseScheduleService
2. Whether it uses last actual dose date or start date as reference
3. Calendar view's dose projection logic
4. Verify the issue is in calculation, not just display
