---
phase: 40-glp1-dose-adjustments
plan: 40-FIX
type: fix
wave: 1
depends_on: []
files_modified:
  - JabTracker/Views/DoseEntry/QuickDoseEntry.swift
autonomous: true
---

<objective>
Fix 1 UAT issue from phase 40.

Source: 40-UAT.md
Diagnosed: yes - root cause identified
Priority: 0 blocker, 1 major, 0 minor, 0 cosmetic

Purpose: The Stepper +/- controls are hidden due to HStack/Spacer layout inside the label. Need to restructure for iOS 26 Form compatibility.
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/execute-plan.md
@~/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/ROADMAP.md

**Issues being fixed:**
@.planning/phases/40-glp1-dose-adjustments/40-UAT.md

**Original plan for reference:**
@.planning/phases/40-glp1-dose-adjustments/40-01-PLAN.md

**Source file:**
@JabTracker/Views/DoseEntry/QuickDoseEntry.swift
</context>

<tasks>

<task type="auto">
  <name>Task 1: Fix UAT-001 - Stepper controls not visible</name>
  <files>JabTracker/Views/DoseEntry/QuickDoseEntry.swift</files>
  <action>
**Root Cause:** HStack label with Spacer() inside Stepper causes +/- controls to be hidden in iOS 26 Form layout.

**Issue:** "doesnt work - Dose Amount shows static text (2.50 mg), no stepper +/- controls visible"

**Expected:** Open Quick Add Dose sheet. Dose Amount row shows stepper +/- controls instead of static text.

**Fix:** Replace the complex HStack label pattern with a standard Stepper format that works in iOS 26 Forms.

Current broken pattern (around line 155-167):
```swift
Stepper(
    value: $viewModel.doseAmount,
    in: self.viewModel.doseAmountRange,
    step: self.viewModel.doseAmountStep
) {
    HStack {
        Text("Dose Amount")
        Spacer()
        Text("\(self.viewModel.doseAmount, specifier: "%.2f") mg")
            .foregroundColor(.secondary)
    }
}
```

Replace with LabeledContent pattern that separates label from stepper:
```swift
LabeledContent {
    Stepper(
        value: $viewModel.doseAmount,
        in: self.viewModel.doseAmountRange,
        step: self.viewModel.doseAmountStep
    ) {
        Text("\(self.viewModel.doseAmount, specifier: "%.2f") mg")
            .foregroundColor(.secondary)
    }
    .accessibilityIdentifier("quick-dose-entry-amount-stepper")
} label: {
    Text("Dose Amount")
}
```

This pattern:
1. Uses LabeledContent for the row label/value structure
2. Stepper label contains only the value (no HStack/Spacer)
3. +/- controls render correctly in iOS 26 Form sections

Keep the accessibilityIdentifier on the Stepper element.
  </action>
  <verify>
Build succeeds: `./scripts/build.sh`
SwiftLint passes: `swiftlint lint --path JabTracker/Views/DoseEntry/QuickDoseEntry.swift`
  </verify>
  <done>
- Stepper +/- controls visible in Quick Add Dose sheet
- UAT-001 resolved - root cause fixed
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>Fixed Stepper layout using LabeledContent pattern for iOS 26 compatibility</what-built>
  <how-to-verify>
    1. Run: Open JabTracker in Xcode, run on simulator
    2. Navigate to Dashboard tab, tap "+" → "Log Dose"
    3. Verify: Dose Amount row now shows stepper (+/-) controls
    4. Test: Tap + to increase dose, verify it increments
    5. Test: Tap - to decrease dose, verify it decrements
    6. Test bounds: Try to go below minimum, verify it stops
    7. Test bounds: Try to go above maximum, verify it stops
    8. Save a dose with adjusted amount, verify it saves correctly
  </how-to-verify>
  <resume-signal>Type "approved" if stepper works correctly, or describe any issues</resume-signal>
</task>

</tasks>

<verification>
Before declaring plan complete:
- [ ] `./scripts/build.sh` succeeds without errors
- [ ] SwiftLint has no errors in modified files
- [ ] Stepper +/- controls visible in Quick Add Dose sheet
- [ ] User has approved visual/functional verification
</verification>

<success_criteria>
- UAT-001 resolved - Stepper controls visible
- All blocked tests (UAT tests 2-7) can now be executed
- Ready for re-verification with /gsd:verify-work 40
</success_criteria>

<output>
After completion, create `.planning/phases/40-glp1-dose-adjustments/40-FIX-SUMMARY.md`
</output>
