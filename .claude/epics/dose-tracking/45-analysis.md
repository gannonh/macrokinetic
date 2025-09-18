---
issue: 45
title: PK Engine Integration
analyzed: 2025-09-18T18:58:56Z
estimated_hours: 20
parallelization_factor: 2.5
---

# Parallel Work Analysis: Issue #45

## Overview
Connect dose logging to pharmacokinetics calculations by integrating the PharmacokineticsEngine with dose entry and dashboard display. This involves core calculation engine development, UI integration, and comprehensive testing.

## Parallel Streams

### Stream A: Core Pharmacokinetics Engine
**Scope**: Implement PharmacokineticsEngine with all calculation methods
**Files**:
- `JabTracker/Engine/PharmacokineticsEngine.swift`
- `JabTracker/Models/ConcentrationPoint.swift`
- `JabTracker/Extensions/Medication+Pharmacokinetics.swift`
**Agent Type**: backend-specialist
**Can Start**: immediately
**Estimated Hours**: 8
**Dependencies**: none (uses existing Medication enum)

### Stream B: Dashboard UI Components
**Scope**: ConcentrationCard and dashboard display integration
**Files**:
- `JabTracker/Views/Dashboard/ConcentrationCard.swift`
- `JabTracker/Views/Dashboard/DashboardView.swift` (modifications)
- `JabTracker/Views/Components/ConcentrationDisplay.swift`
**Agent Type**: frontend-specialist
**Can Start**: immediately (can use mock data initially)
**Estimated Hours**: 6
**Dependencies**: none (can mock PK data during development)

### Stream C: Dose Entry Integration
**Scope**: Connect dose logging to PK calculation updates
**Files**:
- `JabTracker/Views/AddDose/QuickDoseEntry.swift` (modifications)
- `JabTracker/Views/AddDose/DoseEntrySheet.swift` (modifications)
- `JabTracker/Services/DoseService.swift` (create or modify)
**Agent Type**: fullstack-specialist
**Can Start**: after Stream A completes core calculations
**Estimated Hours**: 4
**Dependencies**: Stream A (needs PharmacokineticsEngine)

### Stream D: Comprehensive Testing
**Scope**: Unit tests, integration tests, and UI tests for PK functionality
**Files**:
- `JabTrackerTests/Engine/PharmacokineticsEngineTests.swift`
- `JabTrackerTests/Views/ConcentrationCardTests.swift`
- `JabTrackerTests/Integration/PKDashboardIntegrationTests.swift`
- `JabTrackerUITests/PKEngineUITests.swift`
**Agent Type**: backend-specialist (testing focus)
**Can Start**: immediately (TDD approach)
**Estimated Hours**: 6
**Dependencies**: none (write tests first, then implement)

## Coordination Points

### Shared Files
These files require coordination between streams:
- `JabTracker/Models/MedicationProfile.swift` - Streams A & C (medication data access)
- `JabTracker/Views/Dashboard/DashboardView.swift` - Stream B (UI integration)

### Sequential Requirements
Key dependencies that must happen in order:
1. Core PK calculations (Stream A) before dose integration (Stream C)
2. PK engine interfaces before comprehensive integration testing
3. Mock data contracts agreed upon between A & B for parallel development

## Conflict Risk Assessment
- **Low Risk**: Streams work on different directories and new files
- **Medium Risk**: DashboardView modifications and model access patterns
- **Low Risk**: Well-defined interfaces reduce integration conflicts

## Parallelization Strategy

**Recommended Approach**: hybrid

Launch Streams A, B, and D simultaneously with mock data contracts. Stream C starts when Stream A completes core calculation methods. Stream D provides continuous validation throughout development.

**Mock Data Contract**: Stream B uses predefined ConcentrationPoint data structure and mock calculation results to build UI independently of Stream A.

## Expected Timeline

With parallel execution:
- Wall time: 8 hours (longest stream)
- Total work: 24 hours
- Efficiency gain: 67%

Without parallel execution:
- Wall time: 24 hours

## Notes

### Development Strategy
- **TDD Approach**: Stream D starts immediately with test cases driving implementation
- **Mock Contracts**: Define ConcentrationPoint and calculation interfaces upfront
- **Performance Focus**: Stream A must implement caching for <50ms calculation requirement
- **Medical Accuracy**: Validate pharmacokinetic formulas against literature during development

### Risk Mitigation
- Regular integration checkpoints between streams
- Shared interface definitions agreed upon before parallel work begins
- Performance testing integrated into Stream D to catch issues early
- Medical accuracy validation as part of Stream A acceptance criteria

### Integration Points
- Dashboard refresh triggers when dose entry completes
- Calculation caching strategy shared between engine and UI
- Background calculation updates for improved UX