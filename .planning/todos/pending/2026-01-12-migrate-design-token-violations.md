---
created: 2026-01-12T11:03
title: Migrate 142 design token violations
area: ui
files:
  - JabTracker/Models/ChartData.swift:211-248
  - JabTracker/Views/Nutrition/*.swift
  - JabTracker/Views/Strategy/*.swift
  - JabTracker/Views/Settings/*.swift
  - .planning/tech-debt/DESIGN_TOKEN_VIOLATIONS.md
---

## Problem

142 SwiftLint violations exist for using raw system colors instead of `DesignTokens.Colors` tokens. These violations indicate inconsistent color usage across the app, making theming difficult and creating a maintenance burden.

Key areas affected:
- Views/Nutrition (27 violations) - food search, detail sheets
- Views/Strategy (11 violations) - program sheets
- Models/ChartData.swift (9 violations) - chart colors
- Views/Settings (7 violations) - account, schedule views
- Multiple other view directories

## Solution

Follow the migration guide in `.planning/tech-debt/DESIGN_TOKEN_VIOLATIONS.md`:

1. Start with Models/ChartData.swift (foundational)
2. Migrate Views/Nutrition (largest count)
3. Migrate Views/Strategy (user-facing)
4. Address remaining directories incrementally
5. Update tests last

Use the mapping table:
- `Color(.systemGray6)` → `DesignTokens.Colors.cardBackground`
- `Color(.systemBackground)` → `DesignTokens.Colors.background`
- `Color.white` → `DesignTokens.Colors.background`

Verify with: `swiftlint | grep prefer_design_tokens` (target: 0 violations)
