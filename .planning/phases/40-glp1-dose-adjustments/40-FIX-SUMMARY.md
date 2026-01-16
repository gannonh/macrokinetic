# Fix Summary: Phase 40 UAT Issues

**Phase:** 40-glp1-dose-adjustments
**Plan:** FIX - UAT Issue Resolution
**Executed:** 2026-01-15

## Status: COMPLETE

All UAT issues resolved. Ready for re-verification with `/gsd:verify-work 40`.

## Commits

| Issue | Description | Commit | Files |
|-------|-------------|--------|-------|
| UAT-001 | Stepper controls not visible | 5cbad0f6 | QuickDoseButton.swift, QuickDoseEntry.swift (deleted) |
| UAT-002 | Dose display rounding | 9d7e761e | DoseHistoryRow.swift |

## Issues Fixed

### UAT-001: Stepper Controls Not Visible (Fixed 2026-01-15)

- **Root Cause:** Was editing wrong file (QuickDoseEntry.swift) instead of QuickDoseButton.swift. Additionally, HStack layout pattern in Forms can hide Stepper controls in iOS 26.
- **Solution:** Added `Stepper` with `.labelsHidden()` modifier to the dose amount HStack in `QuickDoseButton.swift`
- **Code Cleanup:** Deleted unused `QuickDoseEntry.swift` (396 lines of dead code)

### UAT-002: Dose Display Rounds Incorrectly (Fixed 2026-01-15)

- **Root Cause:** `DoseHistoryRow.swift` used `"%.1f mg"` format (1 decimal place) instead of the existing `dose.formattedAmount` property which uses `"%.2f"` (2 decimal places)
- **Issue:** User reported "This dose was .75 but shows as 0.8 mg"
- **Solution:**
  1. Line 73: Replaced `String(format: "%.1f mg", self.dose.amount)` with `self.dose.formattedAmount`
  2. Line 149: Updated accessibility label from `"%.1f milligrams"` to `"%.2f milligrams"` for consistency

```swift
// Before
private var doseAmountText: some View {
    Text(String(format: "%.1f mg", self.dose.amount))
        ...
}

// After
private var doseAmountText: some View {
    Text(self.dose.formattedAmount)
        ...
}
```

## Files Changed

### UAT-001
- `JabTracker/Views/Dashboard/QuickDoseButton.swift` - Added Stepper to dose amount row
- `JabTracker/Views/DoseEntry/QuickDoseEntry.swift` - Deleted (unused)
- `coverage-config.json` - Removed deleted file reference

### UAT-002
- `JabTracker/Views/History/DoseHistoryRow.swift` - Use formattedAmount for 2 decimal places

## Verification

- [x] Build succeeds
- [x] SwiftLint passes
- [x] UAT-001: Stepper +/- controls visible in Quick Add Dose sheet
- [x] UAT-002: Dose amounts display with 2 decimal places (0.75 mg)

## Next Steps

Ready for re-verification with `/gsd:verify-work 40`
