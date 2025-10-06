---
issue: 175
title: ScheduleService Core - Schedule Management and Calculation Algorithms
analyzed: 2025-10-06T18:35:11Z
estimated_hours: 24
parallelization_factor: 3.2
---

# Parallel Work Analysis: Issue #175

## Overview

Implement the centralized `ScheduleService` for dose scheduling business logic, including CRUD operations, schedule projection algorithms, dose modification handling, adherence metrics calculation, and titration integration. This is a pure business logic service with 90%+ test coverage requirement (Tier 1).

**Scope Validation**: ✅ Issue remains highly relevant. Dependency #174 (models) is complete. This service is foundational for Tasks #176-183.

**Key Insight**: This is primarily backend business logic with algorithmic complexity. The 68+ test requirement suggests 3 distinct algorithmic domains that can be parallelized.

## Parallel Streams

### Stream A: CRUD Operations & Schedule Projection
**Scope**: Core schedule management and dose generation algorithms
**Focus Areas**:
- Schedule CRUD (create, update, delete, pause, resume)
- Schedule projection algorithm (weekly/split-dose/custom patterns)
- Performance optimization for 365-day projections (<100ms requirement)
- Base schedule configuration encoding/decoding

**Implementation Files**:
- `JabTracker/Services/ScheduleService.swift` (core class + CRUD methods)
- `JabTracker/Services/ScheduleService+Projection.swift` (schedule projection algorithms)

**Test Files**:
- `JabTrackerTests/ScheduleServiceTests.swift` (CRUD tests - 15 tests)
- `JabTrackerTests/ScheduleServiceProjectionTests.swift` (Projection tests - 20 tests)

**Agent Type**: backend-specialist
**Can Start**: immediately
**Estimated Hours**: 10
**Dependencies**: none (models from #174 already complete)

**Acceptance Criteria Coverage**:
- ✅ Service Architecture (6 criteria)
- ✅ Schedule CRUD Operations (8 criteria)
- ✅ Schedule Projection and Generation (9 criteria including performance)

---

### Stream B: Dose Modifications & Adherence Metrics
**Scope**: Dose action handling and adherence calculation algorithms
**Focus Areas**:
- Reschedule, skip, mark taken operations
- Adherence metrics calculation (percentage, streaks, on-time)
- Recent adherence pattern generation (DoseEvent timeline)
- Adherence issue detection

**Implementation Files**:
- `JabTracker/Services/ScheduleService+Modifications.swift` (dose modification methods)
- `JabTracker/Services/ScheduleService+Adherence.swift` (adherence calculation algorithms)

**Test Files**:
- `JabTrackerTests/ScheduleServiceModificationTests.swift` (Dose modification tests - 15 tests)
- `JabTrackerTests/ScheduleServiceAdherenceTests.swift` (Adherence metrics tests - 10 tests)

**Agent Type**: backend-specialist
**Can Start**: immediately (after Stream A creates base class structure)
**Estimated Hours**: 8
**Dependencies**: Stream A (needs base ScheduleService class and init)

**Acceptance Criteria Coverage**:
- ✅ Dose Modification Operations (9 criteria)
- ✅ Adherence Metrics and Analytics (9 criteria)

---

### Stream C: Titration Integration & Error Handling
**Scope**: Titration coordination and error management
**Focus Areas**:
- Detect active titrations affecting schedules
- Handle completed titrations (update schedule doseAmount)
- Generate titration warnings for users
- Comprehensive error handling with ScheduleServiceError enum
- OSLog integration for debugging

**Implementation Files**:
- `JabTracker/Services/ScheduleService+Titration.swift` (titration integration methods)
- `JabTracker/Services/ScheduleServiceError.swift` (error enum with localized descriptions)

**Test Files**:
- `JabTrackerTests/ScheduleServiceTitrationTests.swift` (Titration integration tests - 8 tests)

**Agent Type**: backend-specialist
**Can Start**: after Stream A completes (needs core service structure)
**Estimated Hours**: 6
**Dependencies**: Stream A (needs base service + schedule access methods)

**Acceptance Criteria Coverage**:
- ✅ Titration Integration (4 criteria + logging)
- ✅ Error Handling (5 criteria)

---

## Coordination Points

### Shared Files
**Primary coordination needed**:
- `JabTracker/Services/ScheduleService.swift` - Stream A creates base class, Streams B & C extend via Swift extensions
  - **Strategy**: Stream A creates core class with private helper methods
  - **Streams B & C**: Add functionality via extensions (ScheduleService+Modifications.swift, etc.)
  - **Risk**: Low - extension pattern prevents merge conflicts

**No other shared files** - each stream works on dedicated extension files and test files.

### Sequential Requirements
**Critical path**:
1. **Stream A FIRST**: Must create base `ScheduleService` class with:
   - ModelContext dependency injection
   - Observable properties (activeSchedules, upcomingDoses, isProcessing)
   - Private helper methods (loadActiveSchedules)
   - Init method

2. **Streams B & C**: Can start after Stream A commits base class (typically 2-3 hours into Stream A)

**Parallel execution window**: Streams B & C can run simultaneously once A completes base structure.

### Integration Testing
**After all streams complete**:
- Integration test: CRUD → Projection → Adherence calculation full workflow
- Integration test: Titration completion → Schedule update → Regenerate doses
- Performance test: 365-day projection across all pattern types

---

## Conflict Risk Assessment

**Overall Risk: LOW**

**Low Risk Factors**:
- ✅ Extension-based architecture prevents file conflicts
- ✅ Dedicated test files per stream (no shared test files)
- ✅ Clear algorithmic separation (CRUD, Adherence, Titration)
- ✅ No UI components involved (pure business logic)

**Medium Risk Factor**:
- ⚠️ Stream A must complete base class before B & C can proceed
- **Mitigation**: Stream A focuses on base structure first (2-3h), then B & C can start

---

## Parallelization Strategy

**Recommended Approach**: Hybrid (Sequential start → Parallel execution)

**Phase 1 (Sequential - 2-3 hours)**:
- Stream A: Create base ScheduleService class structure
- Stream A commits: Core class with ModelContext, @Observable properties, init

**Phase 2 (Parallel - remaining time)**:
- Stream A: Continue with CRUD methods and projection algorithms
- Stream B: Add modifications and adherence via extensions
- Stream C: Add titration integration and error handling via extensions

**Why Hybrid**:
- Base class must exist before extensions can compile
- Once base exists, streams work on independent extension files
- Maximizes parallel execution while respecting Swift compilation requirements

---

## Expected Timeline

**With parallel execution (hybrid approach)**:
- **Phase 1 (Sequential)**: 3 hours (Stream A base structure)
- **Phase 2 (Parallel)**: 7 hours (max of remaining Stream A, B, C)
- **Total wall time**: ~10 hours
- **Total work**: 24 hours
- **Efficiency gain**: 58% time savings

**Without parallel execution (sequential)**:
- Stream A: 10 hours
- Stream B: 8 hours
- Stream C: 6 hours
- **Total wall time**: 24 hours

**Parallelization factor**: 2.4x speedup (24h work / 10h wall time)

---

## Testing Strategy Per Stream

**Stream A Testing (35 tests)**:
- Unit tests for each CRUD method (create, update, delete, pause, resume)
- Schedule projection algorithm tests (weekly, split-dose, custom patterns)
- Performance benchmark test (365-day projection < 100ms)
- Edge cases: past start dates, no future doses, pause periods

**Stream B Testing (25 tests)**:
- Dose modification tests (reschedule validation, skip recording, mark taken)
- Adherence calculation accuracy tests (percentage, streaks, on-time)
- DoseEvent timeline generation tests
- Edge cases: all taken, all missed, mixed patterns

**Stream C Testing (8 tests)**:
- Titration detection tests (within 30 days, beyond window, no titration)
- Titration completion handling tests (doseAmount update, regeneration)
- Warning message generation tests
- Error handling tests for all ScheduleServiceError cases

**Integration Testing (Final)**:
- Full workflow: Create schedule → Generate doses → Calculate adherence
- Titration workflow: Complete titration → Update schedule → Verify doses
- Performance validation: All pattern types meet <100ms requirement

---

## Notes

**Medical Accuracy Critical**:
- Adherence algorithms directly impact patient care decisions
- All calculation methods require comprehensive edge case testing
- Titration integration must preserve schedule integrity

**Performance Requirements**:
- 365-day projection < 100ms is HARD REQUIREMENT
- Stream A must validate this early with performance benchmarks
- Consider lazy generation strategies if performance issues arise

**Extension Architecture Benefits**:
- Clean separation of concerns (CRUD, Modifications, Adherence, Titration)
- Prevents merge conflicts in parallel development
- Easier code review and testing per domain
- Follows established patterns in codebase (ChartDataProcessor+Filtering.swift, etc.)

**Coverage Requirements**:
- 90%+ required (Tier 1: Pure Business Logic)
- 68 test methods should achieve this easily
- Each stream responsible for coverage of their methods

**Dependency Note**:
- Issue #174 (models) ✅ COMPLETE
- No other blockers
- This service is prerequisite for Tasks #176-183 (UI integration, notifications)
