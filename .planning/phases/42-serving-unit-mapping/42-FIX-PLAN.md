---
phase: 42-serving-unit-mapping
plan: FIX
type: execute
wave: 1
depends_on: []
files_modified:
  - JabTracker/Views/Nutrition/ServingPillPicker.swift
  - scripts/process-off-data.py
autonomous: true
gap_closure: true

must_haves:
  truths:
    - "Rice with 0.25 cup (49g) serving shows 'cup' as unit option, not 'serving'"
    - "Fractional cup servings (0.25, 0.5, 0.33) are validated with scaled gram ranges"
    - "Full cup servings still validated against [80, 300] gram range"
  artifacts:
    - path: "JabTracker/Views/Nutrition/ServingPillPicker.swift"
      provides: "Fractional quantity parsing in isServingLabelSuspicious"
      contains: "parseQuantityPrefix"
    - path: "scripts/process-off-data.py"
      provides: "Fractional quantity parsing in is_serving_label_suspicious"
      contains: "parse_quantity_prefix"
  key_links:
    - from: "isServingLabelSuspicious"
      to: "gram range validation"
      via: "quantity multiplier"
      pattern: "min.*\\*.*quantity|quantity.*\\*.*min"
---

<objective>
Fix fractional cup validation to preserve valid serving labels like "0.25 cup (49g)"

Purpose: The current validation assumes all cup labels represent 1 full cup. For fractional cups (e.g., "0.25 cup"), the gram range must be scaled by the fraction. Without this fix, valid rice servings show "serving" instead of "cup".

Output: Updated validation logic in both Python (data import) and Swift (runtime display) that correctly validates fractional cup servings.
</objective>

<execution_context>
@~/.claude/get-shit-done/workflows/execute-plan.md
@~/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/42-serving-unit-mapping/42-UAT.md
@.planning/debug/42-cup-serving-missing.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Fix Swift fractional cup validation</name>
  <files>JabTracker/Views/Nutrition/ServingPillPicker.swift</files>
  <action>
Update `isServingLabelSuspicious` in ServingPillPicker.swift (lines 56-71) to:

1. Add a new private static function `parseQuantityPrefix(_ label: String) -> Double?` that:
   - Uses regex to extract leading numeric quantity from the ORIGINAL label (before formatLabel strips it)
   - Handles decimal formats like "0.25", "0.5", "1.5"
   - Handles fraction formats like "1/4", "1/2", "1/3" (convert to decimal)
   - Returns nil if no quantity prefix found (default to 1.0)

2. Modify `isServingLabelSuspicious` to accept the ORIGINAL label (not the formatted one) as a second parameter:
   - Change signature to: `isServingLabelSuspicious(_ formattedLabel: String, originalLabel: String, grams: Double) -> Bool`
   - Parse quantity from originalLabel using parseQuantityPrefix
   - Default to 1.0 if no quantity found
   - Scale the min/max gram ranges by the quantity before comparison
   - Example: For "0.25 cup", check if grams is in [80*0.25, 300*0.25] = [20, 75]

3. Update the call site in `init(from option: ServingOption)` to pass both the formatted label AND the original label:
   - `ServingPillOption.isServingLabelSuspicious(formattedLabel, originalLabel: option.label, grams: option.grams)`

Example test cases the fix should handle:
- "0.25 cup (49g)" with 49g -> quantity=0.25, range=[20,75], 49 is in range -> NOT suspicious
- "1 cup (250g)" with 250g -> quantity=1.0, range=[80,300], 250 is in range -> NOT suspicious
- "1 cup (5g)" with 5g -> quantity=1.0, range=[80,300], 5 NOT in range -> SUSPICIOUS
- "1/2 cup (120g)" with 120g -> quantity=0.5, range=[40,150], 120 is in range -> NOT suspicious
  </action>
  <verify>
Build succeeds: `./scripts/build.sh`

Manual verification:
1. Search for "365 everyday value, indian basmati rice" in food search
2. Tap the rice product
3. Confirm "cup" appears as a serving unit option (not just "serving", "g", "oz")
  </verify>
  <done>
Rice product with "0.25 cup (49g)" serving displays "cup" as unit option instead of "serving"
  </done>
</task>

<task type="auto">
  <name>Task 2: Fix Python fractional cup validation</name>
  <files>scripts/process-off-data.py</files>
  <action>
Update `is_serving_label_suspicious` in process-off-data.py (lines 75-96) to match the Swift logic:

1. Add a new function `parse_quantity_prefix(serving_size_str: str) -> float` that:
   - Uses regex to extract leading numeric quantity
   - Handles decimal formats: "0.25 cup", "0.5 cup", "1.5 cups"
   - Handles fraction formats: "1/4 cup", "1/2 cup" (convert to float)
   - Returns 1.0 if no quantity prefix found

2. Modify `is_serving_label_suspicious` to:
   - Call parse_quantity_prefix to get the quantity multiplier
   - Scale min_grams and max_grams by the quantity before comparison
   - Example: For "0.25 cup (49g)", quantity=0.25, range becomes [20, 75]

3. Update the comment at the top of is_serving_label_suspicious to explain the fractional scaling logic

Note: This Python fix is for future data imports. Existing database data is handled by the Swift runtime fix in Task 1.
  </action>
  <verify>
Python syntax check: `python3 -m py_compile scripts/process-off-data.py`

Unit test the function manually in Python REPL:
```python
exec(open('scripts/process-off-data.py').read())
# Should return False (valid)
print(is_serving_label_suspicious("0.25 cup (49g)", 49))  # False
print(is_serving_label_suspicious("1/2 cup (120g)", 120))  # False
# Should return True (suspicious)
print(is_serving_label_suspicious("1 cup (5g)", 5))  # True
```
  </verify>
  <done>
Python validation logic matches Swift, correctly handling fractional cup quantities in serving labels
  </done>
</task>

</tasks>

<verification>
1. Build succeeds with no errors
2. SwiftLint passes: `swiftlint`
3. Python syntax valid: `python3 -m py_compile scripts/process-off-data.py`
4. UAT Test 1 passes: Search for rice, confirm "cup" appears as serving option
</verification>

<success_criteria>
- Rice product "365 everyday value, indian basmati rice" shows "cup" serving option
- Fractional cups (0.25, 0.5, 1/4, 1/2, 1/3) correctly validated
- Full cups still validated against [80, 300] range
- Both Swift and Python implementations are consistent
</success_criteria>

<output>
After completion, create `.planning/phases/42-serving-unit-mapping/42-FIX-SUMMARY.md`
</output>
