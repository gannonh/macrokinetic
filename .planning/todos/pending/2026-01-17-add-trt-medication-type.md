---
created: 2026-01-17T08:58
title: Add TRT as new medication type
area: ui
files: []
---

## Problem

The app currently focuses on GLP-1 medications, but our target audience (bodybuilders, fitness enthusiasts) often also uses Testosterone Replacement Therapy (TRT). These users want to track all their injectable medications in one place rather than using multiple apps.

TRT has different:
- Dosing schedules (typically weekly or bi-weekly)
- Pharmacokinetics (different half-life than GLP-1s)
- Tracking needs (testosterone levels, injection sites)

## Solution

TBD - Consider:
- Extend medication model to support TRT medication profiles
- TRT-specific pharmacokinetic calculations
- Injection site rotation tracking (already have for GLP-1, may reuse)
- Lab value tracking integration (testosterone levels, estradiol, etc.)
- Different visualization for TRT concentration curves
