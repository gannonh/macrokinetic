---
issue: 174
title: SwiftData Models - DoseSchedule, ScheduledDose, DoseEvent
analyzed: 2025-10-05T16:25:15Z
estimated_hours: 11
parallelization_factor: 2.2
---

# Parallel Work Analysis: Issue #174

## Overview
Create three foundational SwiftData models for the dose scheduling system (DoseSchedule, ScheduledDose, DoseEvent) and integrate them with existing models (MedicationProfile, Dose). This task follows established SwiftData + CloudKit patterns with comprehensive testing (50+ test methods) and 90% coverage requirement.

## Scope Validation

✅ **Scope remains valid** - No overlapping work found in codebase:
- Verified models don't exist: DoseSchedule.swift, ScheduledDose.swift, DoseEvent.swift not present
- Integration points identified: MedicationProfile and Dose models ready for relationship additions
- Pattern alignment: Follows established one-side relationship rule from existing models
- CloudKit compatibility: All planned fields use supported types (UUID, Date, Double, String, Data, Bool)

## Parallel Streams

### Stream A: ScheduledDose Model & Tests
**Scope**: Foundation model representing individual scheduled dose instances with adherence windows

**Implementation Files**:
- `JabTracker/Models/ScheduledDose.swift` (new file)
  - @Model class with SwiftData schema
  - Required fields: id, schedule, scheduledTime, doseAmount, windowStart, windowEnd, timestamps
  - Optional fields: actualDose, skippedAt, skipReason, rescheduledFrom
  - Computed properties: isInWindow, status
  - Supporting enums: ScheduledDoseStatus

**Test Files**:
- `JabTrackerTests/ScheduledDoseTests.swift` (new file)
  - 20+ test methods covering:
    - Model creation with valid data
    - Window calculation (isInWindow computed property)
    - Status transitions (pending → taken/skipped/missed)
    - Relationship setup (scheduledDose → schedule, scheduledDose → actualDose)
    - Reschedule scenarios
    - Skip reason tracking
  - Use DataController.testContainer() for SwiftData setup
  - Target: 90%+ coverage (Tier 1 - Pure Business Logic)

**Agent Type**: backend-specialist (SwiftData model expert)

**Can Start**: Immediately (no dependencies)

**Estimated Hours**: 3

**Dependencies**: None

**TDD Approach**:
1. Unit Tests (RED): Write failing tests for ScheduledDose model behavior
2. Implementation: Create ScheduledDose.swift with minimal code to pass tests
3. Unit Tests (GREEN): Verify all tests pass
4. Refactor: Clean up implementation while keeping tests green

---

### Stream B: DoseSchedule Model & Tests
**Scope**: Parent model managing medication schedule patterns and generating scheduled doses

**Implementation Files**:
- `JabTracker/Models/DoseSchedule.swift` (new file)
  - @Model class with SwiftData schema
  - Required fields: id, medicationProfile, patternType, baseSchedule, isActive, timestamps
  - Optional fields: pausedAt, pausedUntil, customScheduleData
  - @Relationship to ScheduledDose: `@Relationship(deleteRule: .cascade, inverse: \ScheduledDose.schedule) var scheduledDoses: [ScheduledDose] = []`
  - Computed property: nextScheduledDose
  - Supporting enums: SchedulePatternType

**Test Files**:
- `JabTrackerTests/DoseScheduleTests.swift` (new file)
  - 15+ test methods covering:
    - Model creation with valid data
    - Default value initialization
    - Relationship setup (schedule → scheduledDoses)
    - Computed property nextScheduledDose accuracy
    - Pattern type enum values and encoding
    - Pause/resume scenarios
  - Use DataController.testContainer() for SwiftData setup
  - Target: 90%+ coverage (Tier 1 - Pure Business Logic)

**Agent Type**: backend-specialist (SwiftData relationship expert)

**Can Start**: Immediately (Swift allows circular optional type references)

**Estimated Hours**: 3

**Dependencies**: None (can develop in parallel with Stream A)

**TDD Approach**:
1. Unit Tests (RED): Write failing tests for DoseSchedule model behavior
2. Implementation: Create DoseSchedule.swift with minimal code to pass tests
3. Unit Tests (GREEN): Verify all tests pass
4. Refactor: Clean up implementation while keeping tests green

---

### Stream C: DoseEvent Struct & Tests
**Scope**: Calculated entity combining scheduled and actual doses for unified timeline presentation

**Implementation Files**:
- `JabTracker/Models/DoseEvent.swift` (new file)
  - Struct (not @Model) for calculated timeline data
  - Fields: id, timestamp, type, scheduledDose, actualDose, doseAmount, adherenceStatus
  - Protocols: Identifiable, Comparable
  - Computed property: isAdherent
  - Factory methods: from(scheduledDose:), from(actualDose:), combined(scheduled:actual:)
  - Supporting enums: DoseEventType, AdherenceStatus

**Test Files**:
- `JabTrackerTests/DoseEventTests.swift` (new file)
  - 15+ test methods covering:
    - Factory method creation from ScheduledDose
    - Factory method creation from Dose
    - Combined event creation
    - Adherence status calculation
    - Sorting by timestamp
    - Equality and comparison logic
  - Use DataController.testContainer() for SwiftData setup
  - Target: 90%+ coverage (Tier 1 - Pure Business Logic)

**Agent Type**: backend-specialist (Swift struct and protocol expert)

**Can Start**: Immediately (references types created in Streams A & B but Swift allows forward references)

**Estimated Hours**: 3

**Dependencies**: None (can develop in parallel, factory methods will compile once A & B models exist)

**TDD Approach**:
1. Unit Tests (RED): Write failing tests for DoseEvent struct behavior
2. Implementation: Create DoseEvent.swift with minimal code to pass tests
3. Unit Tests (GREEN): Verify all tests pass
4. Refactor: Clean up implementation while keeping tests green

---

### Stream D: Model Integration & Validation
**Scope**: Wire new models into existing codebase and validate complete system integration

**Implementation Files**:
- `JabTracker/Models/MedicationProfile.swift` (modify existing)
  - Add: `@Relationship(deleteRule: .cascade, inverse: \DoseSchedule.medicationProfile) var schedules: [DoseSchedule] = []`
  - Follows existing pattern (already has doses and doseTitrations relationships)

- `JabTracker/Models/Dose.swift` (modify existing)
  - Add: `var scheduledDose: ScheduledDose?` (child-side plain property)
  - Follows existing pattern (already has user and medication child references)

**Integration Test Files**:
- Add integration test methods to existing test files:
  - `JabTrackerTests/MedicationProfileTests.swift` - verify schedules relationship cascade delete
  - `JabTrackerTests/DoseTests.swift` - verify scheduledDose reference works correctly

**Agent Type**: backend-specialist (integration and validation)

**Can Start**: After Streams A, B, and C complete (needs all models to exist)

**Estimated Hours**: 2

**Dependencies**: Streams A, B, C (all models must exist before integration)

**Integration Testing Approach**:
1. Integration Tests (RED): Write failing tests for model relationships
2. Implementation: Update MedicationProfile.swift and Dose.swift
3. Integration Tests (GREEN): Verify relationship tests pass
4. System Validation: Run full test suite to ensure no regressions

---

## Coordination Points

### Shared Files
**None** - Streams A, B, C create entirely new files with no conflicts

Stream D modifies existing files but runs sequentially after others complete:
- `MedicationProfile.swift` - Stream D only (after A, B, C)
- `Dose.swift` - Stream D only (after A, B, C)

### Sequential Requirements
1. **Parallel Phase**: Streams A, B, C run simultaneously (no blocking dependencies)
2. **Integration Phase**: Stream D runs after A, B, C complete
3. **Validation**: Full test suite execution after Stream D completes

### Type Reference Strategy
- Swift allows circular optional type references, enabling parallel development
- DoseSchedule references `[ScheduledDose]` - compiles with forward declaration
- ScheduledDose references `DoseSchedule?` - compiles with forward declaration
- DoseEvent references both types - compiles once A & B files exist

## Conflict Risk Assessment

**Low Risk** - Excellent parallelization opportunity:
- ✅ **No file conflicts**: Streams A, B, C create separate new files
- ✅ **No shared types**: Each stream owns its model completely
- ✅ **Clean separation**: Test files completely independent
- ✅ **Integration isolated**: Stream D sequential, no parallel conflicts

**Coordination needed**:
- Agents should communicate when models are ready for reference (A & B completion)
- Stream D should verify all tests pass before integration modifications

## Parallelization Strategy

**Recommended Approach**: Hybrid (parallel + sequential)

**Phase 1 - Parallel Execution**:
- Launch Streams A, B, C simultaneously
- Each agent owns complete model + test implementation
- No coordination needed during development
- All agents follow outside-in TDD (unit tests → implementation)

**Phase 2 - Integration**:
- Start Stream D after Streams A, B, C complete
- Single agent updates existing models
- Integration testing validates complete system
- Final validation: full test suite passes

**Communication Protocol**:
- Stream A agent: Notify when ScheduledDose.swift complete
- Stream B agent: Notify when DoseSchedule.swift complete
- Stream C agent: Notify when DoseEvent.swift complete
- Stream D agent: Start when all three notifications received

## Expected Timeline

### With Parallel Execution
- **Wall time**: 5 hours
  - Parallel phase (A, B, C): max(3, 3, 3) = 3 hours
  - Integration phase (D): 2 hours
- **Total work**: 11 hours
- **Efficiency gain**: 45% time savings

### Without Parallel Execution
- **Wall time**: 11 hours
  - Stream A: 3 hours
  - Stream B: 3 hours
  - Stream C: 3 hours
  - Stream D: 2 hours

### Parallelization Factor
**2.2x speedup** (11 hours / 5 hours = 2.2)

## Testing Strategy

### Coverage Requirements
- **Target**: 90%+ for all model files (Tier 1 - Pure Business Logic)
- **Total Test Methods**: 50+ across three test files
  - DoseScheduleTests: 15+ methods
  - ScheduledDoseTests: 20+ methods
  - DoseEventTests: 15+ methods

### TDD Workflow (Per Stream)
Each stream follows outside-in TDD independently:

1. **Unit Tests (RED Phase)**:
   - Write comprehensive failing unit tests
   - Cover all model behavior and edge cases
   - Use DataController.testContainer() for SwiftData setup

2. **Implementation (GREEN Phase)**:
   - Write minimal code to make tests pass
   - Follow established SwiftData patterns
   - Ensure CloudKit compatibility

3. **Refactor**:
   - Clean up implementation
   - Add doc comments
   - Verify tests still pass

4. **Validation**:
   - Run: `./scripts/test.sh unit 1 {ModelName}Tests`
   - Verify 90%+ coverage
   - SwiftLint passes

### Integration Testing (Stream D)
1. **Integration Tests (RED Phase)**:
   - Write tests for MedicationProfile.schedules relationship
   - Write tests for Dose.scheduledDose reference
   - Test cascade delete behavior

2. **Implementation (GREEN Phase)**:
   - Update MedicationProfile.swift
   - Update Dose.swift
   - Verify relationship wiring

3. **System Validation**:
   - Run full test suite
   - Verify no regressions
   - Check 90%+ coverage maintained

## Quality Gates

### Per-Stream Quality Gates
- All unit tests pass
- SwiftLint violations: 0
- Test coverage: 90%+
- Doc comments: Complete

### Integration Quality Gates (Stream D)
- All integration tests pass
- Existing tests still pass (no regressions)
- Relationship cascade deletes work correctly
- CloudKit sync validated (no migration issues)

### Final Validation
```bash
# Stream A validation
./scripts/test.sh unit 1 ScheduledDoseTests

# Stream B validation
./scripts/test.sh unit 1 DoseScheduleTests

# Stream C validation
./scripts/test.sh unit 1 DoseEventTests

# Stream D validation (integration)
./scripts/test.sh unit 1 MedicationProfileTests
./scripts/test.sh unit 1 DoseTests

# Full suite validation
./scripts/check-all.sh --skip-ui
```

## Risk Mitigation

### SwiftData Relationship Complexity
**Risk**: Circular references or relationship errors
**Mitigation**:
- Follow one-side rule (parent has @Relationship, child has plain property)
- Use established patterns from MedicationProfile/Dose models
- Test cascade deletes explicitly in Stream D

### CloudKit Sync Compatibility
**Risk**: New fields incompatible with CloudKit
**Mitigation**:
- Use only supported types: UUID, Date, Double, String, Data, Bool
- Encode complex structures as Data (JSON)
- Test sync scenarios in integration phase

### Parallel Development Conflicts
**Risk**: Type reference issues during parallel development
**Mitigation**:
- Swift compiler handles forward type references
- No shared files between A, B, C streams
- Clear communication when models ready for use

### Test Coverage Gaps
**Risk**: Missing edge cases or insufficient coverage
**Mitigation**:
- 50+ test methods specified in acceptance criteria
- Each stream owns comprehensive testing
- Coverage validation in quality gates

## Notes

### Medical Accuracy Considerations
- **Scheduling Windows**: windowStart/windowEnd define adherence (typically ±2 hours for weekly)
- **Pause/Resume**: pausedAt/pausedUntil support treatment interruptions
- **Reschedule Tracking**: rescheduledFrom preserves original time for adherence analysis
- **Skip Reasons**: skipReason enables intentional vs missed dose differentiation

### Architecture Decisions
- **DoseEvent as Struct**: Not @Model - calculated entity for timeline presentation, not persisted
- **JSON Encoding**: baseSchedule and customScheduleData use Data type for CloudKit compatibility
- **Audit Trail**: createdAt/updatedAt on all persistent models for debugging and sync tracking
- **Relationship Pattern**: Follows established one-side rule from existing codebase

### Performance Considerations
- Relationship queries must scale with 365+ ScheduledDose records
- nextScheduledDose computed property should be optimized for frequent access
- DoseEvent factory methods should handle large timeline queries efficiently

### Future Integration Points
- ScheduleService (Task 002) will handle schedule generation and window detection
- NotificationManager will use ScheduledDose for reminder scheduling
- Timeline views will use DoseEvent for unified scheduled/actual dose display
- Analytics will track adherence using ScheduledDose.status transitions
