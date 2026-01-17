---
created: 2026-01-17T08:59
title: Add custom medication support
area: ui
files: []
---

## Problem

Users take a variety of injectable and oral medications beyond the pre-defined types (GLP-1, TRT). Rather than adding each medication type individually, users need the ability to define their own medications with custom parameters:

- Medication name
- Dosing schedule (daily, weekly, bi-weekly, custom intervals)
- Dose units (mg, ml, IU, etc.)
- Half-life (for pharmacokinetic modeling, if applicable)
- Injection vs oral
- Notes/instructions

This gives power users full flexibility to track any medication regimen.

## Solution

TBD - Consider:
- "Add Custom Medication" flow in settings/medications
- User-defined fields for name, schedule, units, half-life
- Optional PK modeling toggle (requires half-life input)
- Template system: start from scratch or modify existing templates
- Import/export medication profiles for sharing
