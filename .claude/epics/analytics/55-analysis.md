---
issue: 55
title: Build ChartDataProcessor
analyzed: 2025-09-23T00:04:12Z
estimated_hours: 14
parallelization_factor: 2.5
---

# Parallel Work Analysis: Issue #55

## Overview
Build ChartDataProcessor utility to transform dose tracking data into Swift Charts-compatible data structures with efficient processing for large datasets and concentration timeline visualizations.

## Reassessment of Scope
The scope is well-defined and valid. Issue #53 (dependencies) has been completed, providing the extended SwiftData models with analytics capabilities. The ChartDataProcessor is a new service that doesn't exist yet, making this greenfield development with minimal conflict risk. This is critical infrastructure for the analytics visualization phase of the epic.

## Parallel Streams

### Stream A: Core Data Transformation Service
**Scope**: Build the ChartDataProcessor class structure and core transformation methods
**Files**:
- `JabTracker/Services/ChartDataProcessor.swift` (new)
- `JabTrackerTests/Services/ChartDataProcessorTests.swift` (new)
**Agent Type**: backend-specialist
**Can Start**: immediately
**Estimated Hours**: 4
**Dependencies**: none
**Testing**: Unit tests for basic data transformation

### Stream B: Chart Data Formatting & Interpolation
**Scope**: Implement Swift Charts-specific data structures and concentration interpolation
**Files**:
- `JabTracker/Services/ChartDataProcessor.swift` (extend)
- `JabTracker/Models/ChartData.swift` (new - data structures)
- `JabTrackerTests/Services/ChartDataProcessorInterpolationTests.swift` (new)
**Agent Type**: fullstack-specialist
**Can Start**: immediately
**Estimated Hours**: 5
**Dependencies**: none (can define interfaces first)
**Testing**: Unit tests for interpolation accuracy and edge cases

### Stream C: Time Period Filtering & Aggregation
**Scope**: Implement filtering, aggregation, and dose marker overlay logic
**Files**:
- `JabTracker/Services/ChartDataProcessor+Filtering.swift` (new extension)
- `JabTrackerTests/Services/ChartDataProcessorFilteringTests.swift` (new)
**Agent Type**: backend-specialist
**Can Start**: after Stream A completes (needs core structure)
**Estimated Hours**: 3
**Dependencies**: Stream A
**Testing**: Unit tests for various time periods and filter combinations

### Stream D: Performance Optimization & Integration
**Scope**: Memory optimization, integration with PharmacokineticsEngine and AnalyticsService
**Files**:
- `JabTracker/Services/ChartDataProcessor.swift` (optimize)
- `JabTrackerTests/Services/ChartDataProcessorPerformanceTests.swift` (new)
- `JabTrackerTests/Services/ChartDataProcessorIntegrationTests.swift` (new)
**Agent Type**: backend-specialist
**Can Start**: after Streams B and C complete
**Estimated Hours**: 2
**Dependencies**: Streams B, C
**Testing**: Performance tests with 1+ year datasets, integration tests with existing services

## Coordination Points

### Shared Files
- `JabTracker/Services/ChartDataProcessor.swift` - All streams (coordinate through clear method separation)
- Stream A creates the base class structure
- Stream B extends with chart-specific methods
- Stream C adds filtering extension file
- Stream D optimizes the combined implementation

### Sequential Requirements
1. Core service structure (Stream A) before filtering extensions (Stream C)
2. Data structures and interpolation (Stream B) can proceed independently
3. Performance optimization (Stream D) must wait for functional implementation

## Conflict Risk Assessment
- **Low Risk**: Streams work on mostly different files or different methods
- Different test files for each stream minimize test conflicts
- Extension pattern for filtering keeps code separated
- Main coordination needed when Stream D optimizes combined work

## Parallelization Strategy

**Recommended Approach**: Hybrid

Start Streams A & B simultaneously (independent foundation work)
Stream C begins when A completes (3-4 hours later)
Stream D begins when B & C complete (final optimization pass)

## Expected Timeline

With parallel execution:
- Wall time: ~7 hours
- Total work: 14 hours
- Efficiency gain: 50%

Without parallel execution:
- Wall time: 14 hours

## Implementation Notes

### Key Technical Considerations
1. **Swift Charts Data Structures**: Use standard Chart Point/Mark types for compatibility
2. **Memory Management**: Process data in chunks for large datasets (>1000 doses)
3. **Interpolation Strategy**: Use existing PharmacokineticsEngine's exponential decay model
4. **Performance Target**: Process 1 year of data (365 doses) in <100ms
5. **Empty State Handling**: Graceful handling when no dose data exists

### Testing Strategy
- Each stream includes its own test development following TDD principles
- Unit tests for data transformation accuracy
- Performance benchmarks with varying dataset sizes
- Integration tests with real SwiftData models
- No separate testing stream needed - embedded in each development stream

### Risk Mitigation
- Define clear interfaces early to prevent integration issues
- Use protocol-oriented design for testability
- Consider using Combine for reactive data updates
- Profile memory usage early to catch performance issues

## Next Steps
After completion of ChartDataProcessor (Issue #55), the next logical tasks would be:
- Issue #54: Create AnalyticsTabView and ConcentrationTimelineChart UI components
- Issue #56: Implement AdherenceInsightsView
- Both can leverage the completed ChartDataProcessor for data