# Design Token Violations - Migration Task

**Generated:** 2026-01-12  
**Total Violations:** 142  
**Priority:** Medium  
**Assignee:** TBD

## Overview

This document tracks SwiftLint violations related to the `DesignTokens.Colors` design system. These views are using raw system colors (`Color(.systemGray6)`, `Color.white`, etc.) instead of the centralized `DesignTokens.Colors` tokens defined in `JabTracker/Design/DesignTokens.swift`.

## Why This Matters

1. **Consistency**: Using design tokens ensures consistent colors across the app
2. **Theming**: Enables easier theme changes in the future
3. **Maintainability**: Single source of truth for color definitions
4. **Accessibility**: Design tokens can be tuned for accessibility requirements

## How to Fix

Replace raw colors with equivalent `DesignTokens.Colors` tokens:

| Raw Color | Design Token Replacement |
|-----------|-------------------------|
| `Color(.systemGray6)` | `DesignTokens.Colors.cardBackground` |
| `Color(.tertiarySystemFill)` | `DesignTokens.Colors.inputBackground` |
| `Color(.systemBackground)` | `DesignTokens.Colors.background` |
| `Color(.systemGroupedBackground)` | `DesignTokens.Colors.groupedBackground` |
| `Color.white` | `DesignTokens.Colors.background` or `.primary` |
| `Color.gray` | `DesignTokens.Colors.secondary` |
| `Color.blue.opacity(0.1)` | `DesignTokens.Colors.primary.opacity(0.1)` |

For `.fill()` and `.background()` modifiers, ensure the color argument uses `DesignTokens.Colors.*`.

---

## Violations by Directory

### Models (9 violations)

| File | Line | Rule | Current Code |
|------|------|------|--------------|
| `ChartData.swift` | 211 | prefer_design_tokens_colors | `Color(.systemBackground)` |
| `ChartData.swift` | 212 | prefer_design_tokens_colors | `Color(.systemGroupedBackground)` |
| `ChartData.swift` | 214 | prefer_design_tokens_colors | `Color(.systemBackground)` |
| `ChartData.swift` | 220 | prefer_design_tokens_colors | `Color(.systemGray5)` |
| `ChartData.swift` | 221 | prefer_design_tokens_colors | `Color(.systemGray6)` |
| `ChartData.swift` | 222 | prefer_design_tokens_colors | `Color(.systemGray4)` |
| `ChartData.swift` | 223 | prefer_design_tokens_colors | `Color(.systemGray3)` |
| `ChartData.swift` | 240 | prefer_design_tokens_colors | `Color(.systemGray5)` |
| `ChartData.swift` | 248 | prefer_design_tokens_colors | `Color(.systemGray6)` |

### Views/Analytics (8 violations)

| File | Line | Rule |
|------|------|------|
| `AnalyticsView.swift` | 268 | prefer_design_tokens_colors, prefer_design_tokens_fill |
| `AnalyticsView.swift` | 288 | prefer_design_tokens_colors, prefer_design_tokens_fill |
| `ChartConfiguration.swift` | 71 | prefer_design_tokens_colors |
| `ChartConfiguration.swift` | 72 | prefer_design_tokens_colors |
| `ChartConfiguration.swift` | 129 | prefer_design_tokens_colors |
| `TimePeriodSelector.swift` | 42 | prefer_design_tokens_colors, prefer_design_tokens_fill |

### Views/Dashboard (4 violations)

| File | Line | Rule |
|------|------|------|
| `QuickDoseButton.swift` | 112 | prefer_design_tokens_backgrounds_static |

### Views/DoseEntry (2 violations)

| File | Line | Rule |
|------|------|------|
| `QuickDoseEntry.swift` | 82 | prefer_design_tokens_backgrounds_static |
| `QuickDoseEntry.swift` | 253 | prefer_design_tokens_static_colors |

### Views/History (4 violations)

| File | Line | Rule |
|------|------|------|
| `DoseCalendarView.swift` | 129 | prefer_design_tokens_fill_static |
| `MonthlyStatsView.swift` | 169 | prefer_design_tokens_colors, prefer_design_tokens_fill |
| `MonthlyStatsView+DetailedSections.swift` | 35 | prefer_design_tokens_colors |

### Views/LockScreenView.swift (1 violation)

| File | Line | Rule |
|------|------|------|
| `LockScreenView.swift` | 79 | prefer_design_tokens_backgrounds_static |

### Views/Nutrition (27 violations)

| File | Line | Rule |
|------|------|------|
| `BarcodeScannerContentView.swift` | 230 | prefer_design_tokens_fill_static |
| `CreateFoodSheet.swift` | 192 | prefer_design_tokens_colors, prefer_design_tokens_backgrounds |
| `CreateFoodSheet.swift` | 345 | prefer_design_tokens_static_colors |
| `CreateFoodSheet.swift` | 357 | prefer_design_tokens_colors, prefer_design_tokens_backgrounds |
| `EditFoodEntrySheet.swift` | 250 | prefer_design_tokens_colors, prefer_design_tokens_backgrounds |
| `EditFoodEntrySheet.swift` | 281 | prefer_design_tokens_colors |
| `EditFoodEntrySheet.swift` | 300 | prefer_design_tokens_colors |
| `FoodDetailSheet.swift` | 373 | prefer_design_tokens_colors, prefer_design_tokens_backgrounds |
| `FoodDetailSheet.swift` | 396 | prefer_design_tokens_colors, prefer_design_tokens_backgrounds |
| `FoodSearchSheet.swift` | 139 | prefer_design_tokens_backgrounds_static, prefer_design_tokens_static_colors |
| `FoodSearchSheet.swift` | 280 | prefer_design_tokens_colors, prefer_design_tokens_backgrounds |
| `FoodSearchSheet.swift` | 350 | prefer_design_tokens_colors, prefer_design_tokens_backgrounds |
| `QuickAddContentView.swift` | 71 | prefer_design_tokens_colors, prefer_design_tokens_backgrounds |
| `QuickAddContentView.swift` | 85 | prefer_design_tokens_colors, prefer_design_tokens_backgrounds |
| `QuickAddContentView.swift` | 128 | prefer_design_tokens_colors, prefer_design_tokens_backgrounds |

### Views/Onboarding/Legacy/Components (3 violations - already partially fixed)

| File | Line | Rule |
|------|------|------|
| `SchedulePatternCard.swift` | 44 | prefer_design_tokens_static_colors (Color.blue still present) |
| `ConcentrationCurvePreview.swift` | - | *(already migrated)* |
| `ReminderPreferencesView.swift` | - | *(already migrated)* |

### Views/Settings (7 violations)

| File | Line | Rule |
|------|------|------|
| `AccountView.swift` | 243 | prefer_design_tokens_fill_static |
| `AccountView.swift` | 363 | prefer_design_tokens_colors |
| `Components/NotificationAuthorizationStatus.swift` | 99 | prefer_design_tokens_colors |
| `Components/ScheduleSummaryView.swift` | 61 | prefer_design_tokens_colors, prefer_design_tokens_backgrounds |
| `Components/ScheduleSummaryView.swift` | 182 | prefer_design_tokens_backgrounds_static |
| `MedicationProfileSettingsView.swift` | 215 | prefer_design_tokens_backgrounds_static, prefer_design_tokens_static_colors |

### Views/Shortcuts (2 violations)

| File | Line | Rule |
|------|------|------|
| `ShortcutButton.swift` | 37 | prefer_design_tokens_colors |
| `ShortcutRowButton.swift` | 46 | prefer_design_tokens_colors |

### Views/Shots (2 violations)

| File | Line | Rule |
|------|------|------|
| `ShotsView.swift` | 81 | prefer_design_tokens_colors, prefer_design_tokens_backgrounds |

### Views/Strategy (11 violations)

| File | Line | Rule |
|------|------|------|
| `ProgramOptimizationSheet.swift` | 124 | prefer_design_tokens_fill_static |
| `ProgramOptimizationSheet.swift` | 267 | prefer_design_tokens_fill |
| `ProgramOptimizationSheet.swift` | 317 | prefer_design_tokens_fill |
| `ProgramOptimizationSheet.swift` | 337 | prefer_design_tokens_fill |
| `ProgramReadySheet.swift` | 139 | prefer_design_tokens_fill |
| `ProgramReadySheet.swift` | 229 | prefer_design_tokens_fill |
| `ProgramReadySheet.swift` | 247 | prefer_design_tokens_fill_static |
| `ProgramSummarySheet.swift` | 136 | prefer_design_tokens_fill |
| `StrategyView.swift` | 283 | prefer_design_tokens_static_colors |

### JabTrackerTests (9 violations)

| File | Line | Rule |
|------|------|------|
| `DesignSystemTests.swift` | 151 | prefer_design_tokens_fill_static |
| `Models/ChartDataModelTests.swift` | 150 | prefer_design_tokens_colors |
| `Models/ChartDataModelTests.swift` | 151 | prefer_design_tokens_colors |
| `Models/ChartDataModelTests.swift` | 153 | prefer_design_tokens_colors |
| `Models/ChartDataModelTests.swift` | 158 | prefer_design_tokens_colors |
| `Models/ChartDataModelTests.swift` | 159 | prefer_design_tokens_colors |
| `Models/ChartDataModelTests.swift` | 160 | prefer_design_tokens_colors |
| `Models/ChartDataModelTests.swift` | 161 | prefer_design_tokens_colors |

---

## Suggested Approach

1. **Start with Models/ChartData.swift** - This is foundational and used throughout the app
2. **Fix Views/Nutrition** - Largest number of violations (27)
3. **Fix Views/Strategy** - Visible user-facing views (11)
4. **Fix remaining views** - Incrementally address other directories
5. **Update tests last** - Tests can reference expected system colors

## Verification

After making fixes, run:
```bash
swiftlint | grep prefer_design_tokens
```

Target: **0 violations**

---

## Notes

- Some violations may require adding new tokens to `DesignTokens.Colors` if no equivalent exists
- The `prefer_design_tokens_*` rules are custom SwiftLint rules defined in `.swiftlint.yml`
- Test files (ChartDataModelTests) are testing the ChartData model which uses system colors - these tests may need to be updated to expect design tokens instead
