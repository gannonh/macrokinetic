# Quickstart: Medication Profile Management

**Date**: 2025-09-05  
**Purpose**: End-to-end validation of medication profile management functionality

## Test Scenarios (User Stories)

### Scenario 1: New User Medication Setup

**Given**: New user during onboarding  
**When**: User selects Semaglutide (Ozempic) as their medication  
**Then**: System creates profile with correct medical properties

**Test Steps**:
1. Launch app in UI testing mode (`--ui-testing`)
2. Complete authentication bypass
3. Navigate to medication selection in onboarding
4. Select "Semaglutide" from medication list
5. Choose "Ozempic" as brand name
6. Set initial dose to 0.25mg
7. Complete onboarding flow

**Expected Results**:
- MedicationProfile created with `medicationType = .semaglutide`
- Current dose set to 0.25mg (within valid range)
- Half-life property available as 7.0 days
- Available doses: [0.25, 0.5, 1.0, 1.7, 2.0, 2.4]
- Weekly dosing frequency set

### Scenario 2: Compounded Medication Reconstitution

**Given**: User with compounded Semaglutide  
**When**: User enters 10mg vial strength and 1mg target dose  
**Then**: System calculates correct reconstitution instructions

**Test Steps**:
1. Access medication profile settings
2. Enable "Compounded Medication" option
3. Enter vial strength: 10mg
4. Enter target dose: 1mg
5. Request reconstitution calculation

**Expected Results**:
- Water volume calculation: 10ml
- Units per dose: 10 units (1mg per 10 units)
- Display text: "Add 10.0 ml water. Your dose is 10.0 units"
- Validation passes (target ≤ vial strength)

### Scenario 3: Branded Pen Click Calculation

**Given**: User with Ozempic pen  
**When**: User wants to adjust from 0.5mg to 0.25mg  
**Then**: System shows correct pen click instructions

**Test Steps**:
1. Access medication profile with Ozempic pen
2. Navigate to dose adjustment tool
3. Set current dose: 0.5mg
4. Set target dose: 0.25mg
5. Request pen click calculation

**Expected Results**:
- Click calculation based on Ozempic pen specifications
- Clear instruction format: "Dial to X clicks for your 0.25 mg dose"
- Validation ensures target dose is achievable with pen

### Scenario 4: Dose Escalation Tracking

**Given**: User starting dose escalation  
**When**: User schedules increase from 0.25mg to 0.5mg in 4 weeks  
**Then**: System creates escalation record with validation

**Test Steps**:
1. Access current medication profile (0.25mg Semaglutide)
2. Create dose escalation plan
3. Set target dose: 0.5mg
4. Set escalation date: 4 weeks from now
5. Save escalation schedule

**Expected Results**:
- DoseEscalation record created
- Target dose validated against medication limits
- Scheduled date in future
- Escalation appears in profile timeline

### Scenario 5: Profile Update with Data Preservation

**Given**: User with existing medication profile  
**When**: User switches from branded to compounded version  
**Then**: Profile updates while preserving dose history

**Test Steps**:
1. Start with branded Semaglutide profile (with existing doses)
2. Edit medication profile
3. Enable compounded medication option
4. Set vial strength and reconstitution settings
5. Save profile changes

**Expected Results**:
- Profile `isCompounded` flag updated to true
- Vial strength and reconstitution settings saved
- Existing dose records preserved and linked
- CloudKit sync updates profile without data loss

## Performance Validation

### Calculation Speed Tests

**Test**: Measure calculation response times
- Reconstitution calculation: < 10ms
- Pen click calculation: < 10ms
- Profile validation: < 5ms

**Implementation**:
```swift
func testCalculationPerformance() {
    measure {
        _ = calculator.calculateReconstitution(
            vialStrength: 10.0,
            targetDose: 1.0
        )
    }
    // XCTAssertLessThan(averageTime, 0.01) // 10ms
}
```

### Data Integrity Tests

**Test**: Verify medical data accuracy
- All medication half-lives match medical literature
- Available doses match FDA-approved ranges
- Calculations maintain precision for medical safety

**Implementation**:
```swift
func testMedicalDataAccuracy() {
    XCTAssertEqual(Medication.semaglutide.halfLifeDays, 7.0)
    XCTAssertTrue(Medication.semaglutide.availableDoses.contains(0.25))
    // Additional assertions for each medication
}
```

## Integration Validation

### SwiftData + CloudKit Integration

**Test**: Verify model changes sync correctly
1. Create medication profile on device A
2. Verify sync to CloudKit
3. Retrieve on device B
4. Validate all fields present and accurate

### Offline Functionality

**Test**: Verify offline calculations work
1. Disable network connectivity
2. Perform all calculation operations
3. Verify results match online calculations
4. Re-enable network and verify sync

## Error Handling Validation

### Input Validation Tests

**Test**: Verify proper error handling
- Invalid dose ranges → Clear error message
- Target dose > vial strength → Specific guidance
- Unsupported pen types → Helpful alternatives

### User Experience Tests

**Test**: Verify error messages are user-friendly
- Medical terminology avoided in error messages
- Clear guidance provided for resolution
- No technical jargon in user-facing text

## Accessibility Validation

### VoiceOver Support

**Test**: Complete workflow using only VoiceOver
1. Navigate medication selection with VoiceOver
2. Perform calculations using voice commands
3. Verify all results are announced clearly

### Dynamic Type Support

**Test**: Verify layout adapts to text size changes
- Test with smallest and largest system text sizes
- Ensure all text remains readable
- Verify layout doesn't break with accessibility sizes

## Security Validation

### Data Privacy

**Test**: Verify sensitive medical data handling
- No medical data logged to console in production
- CloudKit private database usage verified
- Local data encrypted properly

### Input Sanitization

**Test**: Verify calculation inputs are sanitized
- Prevent injection attacks through numeric inputs
- Validate all user input before processing
- Ensure calculation results are bounded properly

## Completion Criteria

**All scenarios pass**: ✅ / ❌  
**Performance targets met**: ✅ / ❌  
**Integration tests pass**: ✅ / ❌  
**Error handling verified**: ✅ / ❌  
**Accessibility validated**: ✅ / ❌  
**Security requirements met**: ✅ / ❌  

**Ready for production deployment**: ✅ / ❌

---

**Usage Instructions**:
1. Run `./scripts/test.sh ui 1 --coverage` for full UI test suite
2. Run `./scripts/test.sh unit 1` for unit and integration tests  
3. Execute manual accessibility testing using iOS Accessibility Inspector
4. Verify CloudKit sync using multiple test devices
5. Validate performance using Instruments profiling

**Documentation**: Update CLAUDE.md with new medication management capabilities and testing patterns upon successful completion.