# Tasks: Medication Profile Management

**Input**: Design documents from `/specs/001-medication-profile-management/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → ✅ Tech stack: Swift 5.9+, SwiftUI, SwiftData, CloudKit
   → ✅ Libraries: MedicationManager, ReconstitutionCalculator, PenClickCalculator
2. Load optional design documents:
   → ✅ data-model.md: Medication enum, enhanced MedicationProfile
   → ✅ contracts/: medication-manager-contract.swift, calculator-contracts.swift
   → ✅ research.md: Medical accuracy decisions
3. Generate tasks by category:
   → Setup: Model enhancements, test structure
   → Tests: Contract tests, integration tests, UI tests
   → Core: Models, services, calculators
   → Integration: SwiftData, CloudKit sync, UI
   → Polish: Medical accuracy validation, performance
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Models**: `JabTracker/Models/`
- **Services**: `JabTracker/Services/`
- **Views**: `JabTracker/Views/`
- **Tests**: `JabTrackerTests/`, `JabTrackerUITests/`

## Phase 3.1: Setup & Model Foundation
- [ ] T001 Create Medication.swift enum with medical properties in JabTracker/Models/
- [ ] T002 Create DoseFrequency.swift enum in JabTracker/Models/
- [ ] T003 [P] Create test structure folders: JabTrackerTests/MedicationTests/, JabTrackerTests/CalculatorTests/
- [ ] T004 [P] Run xcodegen generate to update project file with new Swift files

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

### Contract Tests
- [ ] T005 [P] Create MedicationManagerTests.swift in JabTrackerTests/ServiceTests/ implementing MedicationManagerTestContract
- [ ] T006 [P] Create ReconstitutionCalculatorTests.swift in JabTrackerTests/CalculatorTests/ implementing ReconstitutionCalculatorTestContract
- [ ] T007 [P] Create PenClickCalculatorTests.swift in JabTrackerTests/CalculatorTests/ implementing PenClickCalculatorTestContract

### Model Tests
- [ ] T008 [P] Create MedicationTests.swift in JabTrackerTests/MedicationTests/ - test enum properties, medical accuracy
- [ ] T009 [P] Create MedicationProfileEnhancementTests.swift in JabTrackerTests/ModelTests/ - test new fields, validation

### Integration Tests
- [ ] T010 [P] Create MedicationProfileUITests.swift in JabTrackerUITests/ - Scenario 1: New user medication setup
- [ ] T011 [P] Create ReconstitutionUITests.swift in JabTrackerUITests/ - Scenario 2: Compounded medication calculation
- [ ] T012 [P] Create PenClickUITests.swift in JabTrackerUITests/ - Scenario 3: Branded pen adjustment
- [ ] T013 [P] Create DoseEscalationUITests.swift in JabTrackerUITests/ - Scenario 4: Dose escalation tracking

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### Model Implementation
- [ ] T014 [P] Implement Medication enum with halfLifeDays, availableDoses, frequency, brandNames, penClickRatio computed properties
- [ ] T015 Enhance MedicationProfile.swift in JabTracker/Models/ - add medicationType, isCompounded, vialStrength, reconstitutionVolume, penType fields
- [ ] T016 [P] Create ReconstitutionResult.swift struct in JabTracker/Models/
- [ ] T017 [P] Create PenClickResult.swift struct in JabTracker/Models/
- [ ] T018 Update DoseEscalation.swift in JabTracker/Models/ - add relationship to MedicationProfile

### Service Implementation
- [ ] T019 [P] Implement MedicationManager.swift in JabTracker/Services/ - CRUD operations, validation
- [ ] T020 [P] Implement ReconstitutionCalculator.swift in JabTracker/Services/ - calculation logic, validation
- [ ] T021 [P] Implement PenClickCalculator.swift in JabTracker/Services/ - pen ratios, click calculations

### Medical Data Configuration
- [ ] T022 Configure medication-specific dose arrays in Medication enum (Semaglutide: 0.25-2.4mg, etc.)
- [ ] T023 Configure pen click ratios for each branded medication type
- [ ] T024 Add validation logic for dose ranges and compounding constraints

## Phase 3.4: UI Integration

### Settings Views
- [ ] T025 Create MedicationProfileSettingsView.swift in JabTracker/Views/Settings/ - profile CRUD UI
- [ ] T026 Create ReconstitutionCalculatorView.swift in JabTracker/Views/MedicationProfile/
- [ ] T027 Create PenClickCalculatorView.swift in JabTracker/Views/MedicationProfile/
- [ ] T028 Create DoseEscalationView.swift in JabTracker/Views/MedicationProfile/

### Onboarding Enhancement
- [ ] T029 Enhance MedicationSelectionView.swift in JabTracker/Views/Onboarding/ - integrate with Medication enum
- [ ] T030 Add compounded vs branded selection flow to onboarding

### View Model Integration
- [ ] T031 Update SettingsViewModel to integrate MedicationManager service
- [ ] T032 Create MedicationProfileViewModel for reactive UI updates

## Phase 3.5: Data Migration & Sync
- [ ] T033 Create SwiftData migration for MedicationProfile model changes
- [ ] T034 Test CloudKit sync with new MedicationProfile fields
- [ ] T035 Verify data preservation during profile updates

## Phase 3.6: Polish & Validation

### Medical Accuracy Validation
- [ ] T036 [P] Create MedicalAccuracyTests.swift - verify all medication properties match medical literature
- [ ] T037 [P] Create CalculationPrecisionTests.swift - verify <50ms performance, precision validation

### Performance & Error Handling
- [ ] T038 Add comprehensive error handling to all calculators with user-friendly messages
- [ ] T039 Add input sanitization and validation to prevent invalid medical calculations
- [ ] T040 Performance profiling with Instruments - verify <50ms calculation updates

### Documentation
- [ ] T041 [P] Update CLAUDE.md with medication management patterns and new components
- [ ] T042 [P] Create inline documentation for all medical calculation methods
- [ ] T043 Run quickstart.md validation scenarios end-to-end

## Dependencies
- Model foundation (T001-T002) before all tests
- Tests (T005-T013) before implementation (T014-T032)
- T014 (Medication enum) blocks T015, T019, T020, T021
- T015 (MedicationProfile) blocks T033, T034
- Services (T019-T021) before UI (T025-T032)
- Implementation before polish (T036-T043)

## Parallel Execution Examples

### Test Creation (can run simultaneously):
```bash
# Launch T005-T007 together (contract tests):
Task: "Create MedicationManagerTests.swift implementing test contract"
Task: "Create ReconstitutionCalculatorTests.swift implementing test contract"  
Task: "Create PenClickCalculatorTests.swift implementing test contract"

# Launch T010-T013 together (UI tests):
Task: "Create MedicationProfileUITests.swift for new user setup"
Task: "Create ReconstitutionUITests.swift for compounded calculation"
Task: "Create PenClickUITests.swift for pen adjustment"
Task: "Create DoseEscalationUITests.swift for dose tracking"
```

### Model Implementation (can run simultaneously):
```bash
# Launch T014, T016-T017 together (independent models):
Task: "Implement Medication enum with medical properties"
Task: "Create ReconstitutionResult.swift struct"
Task: "Create PenClickResult.swift struct"
```

### Service Implementation (can run simultaneously):
```bash
# Launch T019-T021 together (independent services):
Task: "Implement MedicationManager.swift service"
Task: "Implement ReconstitutionCalculator.swift service"
Task: "Implement PenClickCalculator.swift service"
```

## Notes
- [P] tasks = different files, no dependencies
- Run `xcodegen generate` after creating new Swift files
- Verify tests fail (RED phase) before implementing
- Run `./scripts/test.sh unit 1` after each implementation task
- Commit after each task with descriptive message
- Medical accuracy is critical - double-check all calculations

## Validation Checklist
*GATE: Verify before starting implementation*

- ✅ All contracts have corresponding test tasks (T005-T007)
- ✅ All entities have model tasks (T014-T018)
- ✅ All tests come before implementation (T005-T013 before T014-T032)
- ✅ Parallel tasks truly independent (different files)
- ✅ Each task specifies exact file path
- ✅ No task modifies same file as another [P] task
- ✅ Medical validation tasks included (T036-T037)
- ✅ Performance requirements specified (<50ms)

**Total Tasks**: 43
**Parallel Groups**: 6 (Tests, Models, Services, Polish)
**Critical Path**: Setup → Tests → Medication enum → MedicationProfile → Services → UI → Validation

**Ready for execution**: ✅