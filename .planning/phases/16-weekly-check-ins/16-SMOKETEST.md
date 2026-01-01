# Smoke Test: Phase 16 - Weekly Check-ins

## Feature
Multi-step ProgramOptimizationSheet for weekly check-ins with intro screen, calculation animation, and results summary showing updated macro targets.

## How to Test

### Prerequisites
1. In Xcode scheme, enable one of the seeding flags (Run → Arguments)
2. Run the app with `--ui-testing` enabled (bypasses auth)

### Data Quality Tier Seeding Flags

| Flag                           | Data Quality | Weight     | Food | Days | Check-in                  |
| ------------------------------ | ------------ | ---------- | ---- | ---- | ------------------------- |
| `--seed-check-in-ready`        | EXCELLENT    | 28 entries | 75%  | 28   | Allowed (high confidence) |
| `--seed-check-in-good`         | GOOD         | 10 entries | 65%  | 10   | Allowed (good confidence) |
| `--seed-check-in-minimum`      | MINIMUM      | 4 entries  | 55%  | 7    | Allowed (low confidence)  |
| `--seed-check-in-insufficient` | INSUFFICIENT | 2 entries  | 40%  | 5    | **Blocked** (shows tips)  |

### Program Style Modifier

| Flag                   | Description                                         |
| ---------------------- | --------------------------------------------------- |
| `--seed-collaborative` | Changes program style from Coached to Collaborative |

**Notes:**
- Only enable ONE check-in tier flag at a time
- All tier flags set check-in as due (10 days past)
- Combine `--seed-collaborative` with any tier flag to test Collaborative UI

### Test Steps

1. **Navigate to Strategy tab** in the app
2. **Locate the countdown card** - Shows "Weekly Check-in" with days remaining
   - If check-in is due: Card should show green checkmark and be tappable
   - If not due yet: Card shows countdown (e.g., "5 days until check-in")
3. **Tap the countdown card** when check-in is due
4. **Verify intro screen** appears with:
   - "Ready for Your Weekly Check-in" header
   - 3 bullet points explaining what will happen
   - "Start Check-in" button
5. **Tap "Start Check-in"** and verify:
   - Calculating animation with rotating status messages
   - Messages rotate through: "Analyzing weight trend...", "Calculating metabolic rate...", etc.
   - Animation runs for at least 2 seconds
6. **Verify results screen** shows:
   - Updated weekly macro grid (same format as Strategy view)
   - "What changed?" section with summary
   - "What's next?" section with explanation
   - Mode-specific buttons:
     - Coached: "Looks Good" + "Modify Program"
     - Collaborative: "Accept All" + "Modify" + "Keep Current"
7. **Test each button**:
   - "Looks Good"/"Accept All": Should dismiss sheet and apply changes
   - "Modify Program"/"Modify": Should open Program Wizard
   - "Keep Current"/"Decline": Should dismiss without changes

### Manual Program Behavior
- If user has a Manual program, the countdown card should NOT appear (Manual programs don't use automated check-ins)

## Expected Behavior
- Countdown card only visible for Coached/Collaborative programs
- Card becomes tappable (green) when check-in is due
- Multi-step flow is smooth with engaging calculation animation
- Results display matches existing Strategy view patterns
- Buttons perform correct actions based on program style

---

## Progressive Accuracy Testing

### ✅ Scenario 1: EXCELLENT Data (--seed-check-in-ready)
1. Enable `--seed-check-in-ready` flag
2. Navigate to Strategy tab, tap check-in card
3. **Expected:**
   - Check-in proceeds with full recommendations
   - High confidence in TDEE adjustments
   - No data quality warnings

### ✅ Scenario 2: GOOD Data (--seed-check-in-good)
1. Enable `--seed-check-in-good` flag
2. Navigate to Strategy tab, tap check-in card
3. **Expected:**
   - Check-in proceeds with recommendations
   - Confidence ceiling at 70%
   - May show subtle indicator of data quality

### ✅ Scenario 3: MINIMUM Data (--seed-check-in-minimum)
1. Enable `--seed-check-in-minimum` flag
2. Navigate to Strategy tab, tap check-in card
3. **Expected:**
   - Check-in proceeds but with lower confidence
   - Confidence ceiling at 50%
   - Shows encouragement to log more consistently

### ✅ SScenario 4: INSUFFICIENT Data (--seed-check-in-insufficient)
1. Enable `--seed-check-in-insufficient` flag
2. Navigate to Strategy tab, tap check-in card
3. **Expected:**
   - Check-in is **blocked**
   - Shows "Not enough data yet" message
   - Displays improvement tips:
     - "Log at least 1 more weight entry"
     - "Track meals on at least 1 more day"
     - "Wait 2 more days"
   - Shows progress toward next tier requirements

---

## Collaborative Program Testing

Test Collaborative-specific UI by combining `--seed-collaborative` with any tier flag.

### Scenario 5: Collaborative + GOOD Data
**Flags:** `--seed-check-in-good` + `--seed-collaborative`

1. Navigate to Strategy tab, tap check-in card
2. Complete intro and calculation screens
3. **Expected Results Screen:**
   - Shows three buttons (not two):
     - "Accept All" (primary) - Applies changes, dismisses
     - "Modify" (secondary) - Applies changes, opens Program Wizard
     - "Keep Current" (tertiary/destructive) - Declines, dismisses
4. **Test "Accept All":** Should apply new targets and dismiss
5. **Test "Modify":** Should apply new targets, then open Program Wizard with updated baseline
6. **Test "Keep Current":** Should dismiss without applying changes

### Scenario 6: Collaborative + EXCELLENT Data
**Flags:** `--seed-check-in-ready` + `--seed-collaborative`

- Same button layout as Scenario 5
- Higher confidence in recommendations
- Verify all three buttons work correctly

### Key Differences: Coached vs Collaborative

| Aspect          | Coached                         | Collaborative                            |
| --------------- | ------------------------------- | ---------------------------------------- |
| Buttons         | "Looks Good" + "Modify Program" | "Accept All" + "Modify" + "Keep Current" |
| Modify behavior | Opens wizard with current data  | Applies changes first, then opens wizard |
| Decline option  | "Decline and Silence"           | "Keep Current"                           |

---

## Verification

### Core Flow
- [ ] Countdown card shows correct state (countdown vs due)
- [ ] Card hidden for Manual programs
- [ ] Intro screen displays correctly
- [ ] Calculation animation runs smoothly with rotating messages
- [ ] Results screen shows updated targets
- [ ] Weekly macro grid displays correctly
- [ ] No visual glitches
- [ ] No crashes

### Coached Program
- [ ] Shows "Looks Good" + "Modify Program" buttons
- [ ] "Looks Good" applies changes and dismisses
- [ ] "Modify Program" applies changes then opens wizard

### Collaborative Program
- [ ] Shows "Accept All" + "Modify" + "Keep Current" buttons
- [ ] "Accept All" applies changes and dismisses
- [ ] "Modify" applies changes then opens wizard with new baseline
- [ ] "Keep Current" dismisses without changes

### Progressive Accuracy
- [ ] EXCELLENT tier: Full check-in with high confidence
- [ ] GOOD tier: Check-in with good confidence (ceiling 0.7)
- [ ] MINIMUM tier: Check-in with low confidence (ceiling 0.5)
- [ ] INSUFFICIENT tier: Check-in blocked with improvement tips

## Issues Found
(To be filled by tester)

## Status
- [ ] Verified
