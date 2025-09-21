---
issue: 53
title: Extend SwiftData Models for Analytics
analyzed: 2025-09-21T22:03:09Z
estimated_hours: 14
parallelization_factor: 2.5
---

# Parallel Work Analysis: Issue #53

## Overview
Extend existing SwiftData models (Dose, Medication, User) to support analytics calculations and metadata storage. Add computed properties and relationships needed for concentration timelines, adherence tracking, and report generation without breaking existing functionality.

## Parallel Streams

### Stream A: Dose Model Analytics Extensions
**Scope**: Extend Dose model with analytics metadata and computed properties
**Files**:
- JabTracker/Models/Dose.swift
- JabTrackerTests/DoseAnalyticsTests.swift (new)
**Agent Type**: backend-specialist
**Can Start**: immediately
**Estimated Hours**: 4
**Dependencies**: none

**Technical Details**:
- Add analytics metadata fields (adherence tracking, streak data)
- Add computed properties for dose timing analysis
- Maintain CloudKit compatibility with default values
- Ensure backward compatibility with existing dose tracking

### Stream B: User Model Analytics Extensions
**Scope**: Extend User model with analytics preferences and adherence calculations
**Files**:
- JabTracker/Models/User.swift
- JabTrackerTests/UserAnalyticsTests.swift (new)
**Agent Type**: backend-specialist
**Can Start**: immediately
**Estimated Hours**: 3
**Dependencies**: none

**Technical Details**:
- Add analytics preferences and settings fields
- Add user-level computed properties for adherence statistics
- Maintain CloudKit compatibility
- Add analytics reporting preferences

### Stream C: Medication Analytics Extensions
**Scope**: Enhance Medication enum and MedicationProfile with pharmacokinetic properties
**Files**:
- JabTracker/Models/Medication.swift
- JabTracker/Models/MedicationProfile.swift
- JabTrackerTests/MedicationAnalyticsTests.swift (new)
**Agent Type**: backend-specialist
**Can Start**: immediately
**Estimated Hours**: 4
**Dependencies**: none

**Technical Details**:
- Add pharmacokinetic properties to Medication enum for concentration calculations
- Extend MedicationProfile with analytics-specific fields
- Add computed properties for medication effectiveness tracking
- Ensure all fields are CloudKit compatible

### Stream D: Cross-Model Analytics Integration
**Scope**: Implement cross-model computed properties and analytics methods
**Files**:
- JabTracker/Models/Dose.swift (additions)
- JabTracker/Models/User.swift (additions)
- JabTracker/Models/MedicationProfile.swift (additions)
- JabTrackerTests/CrossModelAnalyticsTests.swift (new)
**Agent Type**: backend-specialist
**Can Start**: after Streams A, B, C complete
**Estimated Hours**: 3
**Dependencies**: Streams A, B, C

**Technical Details**:
- Implement adherence calculation methods that span models
- Add concentration timeline calculation methods
- Implement streak and consistency analytics
- Validate all cross-model relationships work correctly

## Coordination Points

### Shared Files
- `JabTracker/Models/Dose.swift` - Streams A & D (coordinate timing analysis additions)
- `JabTracker/Models/User.swift` - Streams B & D (coordinate adherence calculations)
- `JabTracker/Models/MedicationProfile.swift` - Streams C & D (coordinate analytics integration)

### Sequential Requirements
1. Core model extensions (Streams A, B, C) before cross-model analytics (Stream D)
2. All model extensions before comprehensive testing
3. CloudKit compatibility validation throughout all streams

## Conflict Risk Assessment
- **Medium Risk**: Multiple streams modifying same core model files for Stream D
- **Mitigation**: Clear separation between basic field additions (A, B, C) and cross-model logic (D)
- **CloudKit Risk**: All new fields must maintain CloudKit sync compatibility

## Parallelization Strategy

**Recommended Approach**: hybrid

Launch Streams A, B, C simultaneously for basic model extensions. Start Stream D when A, B, C complete. Testing can happen incrementally with each stream completion.

**Rationale**:
- Basic field additions to each model are independent
- Cross-model computed properties require all base fields to exist
- CloudKit compatibility must be validated incrementally
- Foundation for other analytics features requires this work to be solid

## Expected Timeline

With parallel execution:
- Wall time: 7 hours (Streams A,B,C parallel: 4h + Stream D: 3h)
- Total work: 14 hours
- Efficiency gain: 50%

Without parallel execution:
- Wall time: 14 hours

## Notes

**Critical Considerations**:
- CloudKit sync compatibility is essential - all new fields need proper defaults
- Existing test suite must continue to pass with model extensions
- Computed properties should be performant as they'll be called frequently
- Medical accuracy is critical for pharmacokinetic calculations
- This is foundational work for subsequent analytics features

**Testing Strategy**:
- Unit tests for each new computed property
- CloudKit sync validation for all new fields
- Performance testing for analytics calculations
- Integration tests for cross-model relationships
- Backward compatibility validation with existing data

**Risk Mitigation**:
- Incremental testing after each stream completion
- CloudKit field validation before moving to next stream
- Existing test suite regression testing throughout