---
issue: 178
title: Calendar Integration
analyzed: 2025-10-13T17:10:40Z
estimated_hours: 14
parallelization_factor: 2.5
---

# Parallel Work Analysis: Issue #178

## Scope Reassessment

### Current State
- Dependencies **COMPLETED**: Issue #174 (Models), Issue #175 (ScheduleService) ✅
- Existing calendar infrastructure: `DoseCalendarView`, `CalendarDayView`, `HistoryView`
- DoseEvent model exists with full status tracking (scheduled, taken, skipped, missed)
- ScheduleService has required methods for fetching and managing schedules

### Relevance
✅ **CONFIRMED**: This issue is highly relevant and ready to implement:
- Critical user feature for visualizing scheduled vs actual doses
- Natural interface for dose management actions (log, reschedule, skip)
- Completes Phase 4 of dose-scheduling epic
- Dependencies are met - can proceed immediately

### Scope Adjustments
**IMPORTANT**: The task specification references files that don't exist yet:
- Task mentions `CalendarView.swift` and `CalendarViewModel.swift` (don't exist)
- Actual files are `DoseCalendarView.swift` (view-only, no separate ViewModel)
- Current architecture is simpler than spec - need to adapt implementation strategy

**Implementation Strategy**:
1. Extend existing `DoseCalendarView` directly (it's already well-structured)
2. Add scheduled dose display to existing `CalendarDayView`
3. Create new UI components for action sheets
4. Integrate with existing ScheduleService (no additional service layer needed)

## Parallel Streams

### Stream A: Calendar UI Extensions & Dose Indicators
**Scope**: Extend existing calendar views to display scheduled doses with visual indicators
**Implementation Files**:
- `JabTracker/Views/History/DoseCalendarView.swift` (extend - add scheduled dose loading)
- `JabTracker/Views/History/CalendarDayView.swift` (extend - add scheduled dose indicators)
- `JabTracker/Views/History/Components/ScheduledDoseIndicator.swift` (new - visual indicators)
- `JabTracker/Views/History/Components/DoseIndicatorsView.swift` (new - combined display)

**Unit/Integration Testing Files**:
- `JabTrackerTests/Views/DoseCalendarViewTests.swift` (unit tests for dose loading logic)
- `JabTrackerTests/Views/CalendarDayViewTests.swift` (unit tests for indicator display)
- `JabTrackerTests/Views/ScheduledDoseIndicatorTests.swift` (unit tests for visual indicators)

**E2E Testing Files**:
- `JabTrackerUITests/CalendarScheduledDosesUITests.swift` (E2E: viewing scheduled doses on calendar)
- `JabTrackerUITests/CalendarAccessibilityUITests.swift` (E2E: VoiceOver for dose indicators)

**Product Area**: frontend
**Can Start**: immediately
**Estimated Hours**: 5
**Dependencies**: none

**TDD Approach**:
1. Stub E2E acceptance tests for scheduled dose display
2. Write unit tests for dose filtering and indicator logic
3. Implement calendar extensions to pass unit tests
4. Write E2E tests for visual display
5. Refactor for performance

### Stream B: Action Sheet UI & Dose Management
**Scope**: Create action sheets for dose management (log, reschedule, skip) with QuickDoseSheet integration
**Implementation Files**:
- `JabTracker/Views/History/Components/DoseActionSheet.swift` (new - action sheet for dose management)
- `JabTracker/Views/History/Components/RescheduleDoseSheet.swift` (new - reschedule UI with date picker)
- `JabTracker/Views/History/DoseCalendarView.swift` (extend - add long-press gesture handling)

**Unit/Integration Testing Files**:
- `JabTrackerTests/Views/DoseActionSheetTests.swift` (unit tests for action handling)
- `JabTrackerTests/Views/RescheduleDoseSheetTests.swift` (unit tests for reschedule validation)

**E2E Testing Files**:
- `JabTrackerUITests/CalendarDoseActionsUITests.swift` (E2E: long-press, log, reschedule, skip)
- `JabTrackerUITests/CalendarQuickDoseIntegrationUITests.swift` (E2E: QuickDoseSheet pre-population)

**Product Area**: frontend
**Can Start**: immediately
**Estimated Hours**: 5
**Dependencies**: none (shares DoseCalendarView.swift with Stream A but different sections)

**TDD Approach**:
1. Stub E2E acceptance tests for action sheet interactions
2. Write unit tests for action validation and state management
3. Implement action sheets to pass unit tests
4. Write E2E tests for user interaction flows
5. Refactor for UX polish

### Stream C: Statistics Integration & Performance
**Scope**: Add schedule adherence statistics to calendar and optimize performance
**Implementation Files**:
- `JabTracker/Views/History/MonthlyStatsView.swift` (extend - add schedule adherence stats)
- `JabTracker/Services/ScheduleService+Adherence.swift` (extend - adherence calculation for calendar)
- `JabTracker/Views/History/DoseCalendarView.swift` (extend - performance optimization for lazy loading)

**Unit/Integration Testing Files**:
- `JabTrackerTests/Services/ScheduleServiceAdherenceTests.swift` (extend - calendar adherence tests)
- `JabTrackerTests/Views/MonthlyStatsViewTests.swift` (unit tests for stats display)
- `JabTrackerTests/Integration/CalendarPerformanceTests.swift` (integration tests for performance)

**E2E Testing Files**:
- `JabTrackerUITests/CalendarPerformanceUITests.swift` (E2E: <500ms rendering requirement)
- `JabTrackerUITests/CalendarStatsUITests.swift` (E2E: schedule adherence display)

**Product Area**: fullstack (backend service + frontend display)
**Can Start**: immediately
**Estimated Hours**: 4
**Dependencies**: none

**TDD Approach**:
1. Stub E2E acceptance tests for performance and stats
2. Write unit tests for adherence calculations
3. Implement statistics extensions to pass unit tests
4. Write integration tests for performance benchmarks
5. Write E2E tests for stats display
6. Optimize for <500ms target

## Coordination Points

### Shared Files
- `JabTracker/Views/History/DoseCalendarView.swift` - All 3 streams modify this file
  - **Stream A**: Adds scheduled dose loading and filtering
  - **Stream B**: Adds long-press gesture handling and action sheet presentation
  - **Stream C**: Adds performance optimization for lazy loading
  - **Coordination**: Use clear section markers (MARK:) for each stream's additions
  - **Risk**: MEDIUM - All streams touch this file but different sections

### Integration Points
1. **DoseEvent Model** (existing): All streams rely on DoseEvent for dose status
2. **ScheduleService** (existing): Streams A & C use for loading scheduled doses
3. **QuickDoseSheet** (existing): Stream B integrates for dose logging
4. **CalendarDayView** (existing): Stream A extends for indicators

### Sequential Requirements
None - all streams can work in parallel with coordinated shared file edits

## Conflict Risk Assessment
- **Medium Risk**: DoseCalendarView.swift shared by all 3 streams
  - Mitigation: Each stream owns distinct sections (loading, gestures, stats)
  - Use MARK: comments to delineate ownership
  - Commit frequently to minimize merge complexity
- **Low Risk**: Other files are stream-exclusive
- **No Conflicts**: Test files are completely independent per stream

## Parallelization Strategy

**Recommended Approach**: parallel

All 3 streams can launch simultaneously:
- Stream A: UI indicators and dose display
- Stream B: Action sheets and user interactions
- Stream C: Statistics and performance

Coordination strategy for DoseCalendarView.swift:
1. Each stream adds properties/state in clearly marked sections
2. Each stream adds methods in extension-like sections with MARK: comments
3. Body changes should be minimal and non-overlapping
4. First stream to commit sets structure, others adapt

**Merge Order**: No specific order required - all can merge independently

## Expected Timeline

With parallel execution:
- Wall time: **5 hours** (longest stream)
- Total work: 14 hours
- Efficiency gain: **64%** (2.8x speedup)

Without parallel execution:
- Wall time: 14 hours (sequential)

## Simulator Assignments
- Stream A: Simulator 1 (iPhone 15) - UUID: 336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB
- Stream B: Simulator 2 (iPhone 15 Pro Max) - UUID: BFE552DA-1CB4-4736-821D-270EC6307512
- Stream C: Simulator 3 (iPhone SE 3rd gen) - UUID: FF190E2B-E6A1-461F-BEAF-E9A827038FA1

## Notes

### Architecture Insights
The task specification assumed a separate ViewModel pattern, but the existing codebase uses a simpler direct SwiftUI + @Query pattern in DoseCalendarView. This is actually **better** for this use case:
- Less indirection for simple calendar logic
- @Query handles real-time updates automatically
- No need for separate ViewModel layer

### Performance Considerations
- Scheduled dose loading must be lazy (per month, not all future dates)
- Use existing dose filtering patterns from DoseCalendarView.dosesForDate()
- Calendar rendering target: <500ms for 90-day view with scheduled doses

### Gesture Handling
- Long-press on calendar day cell needs careful implementation to not conflict with tap
- Use `.gesture()` modifier with `.simultaneously(with:)` for both gestures
- Long-press should only trigger on days with scheduled doses

### Testing Strategy
- Each stream owns its E2E tests completely (no conflicts)
- Unit tests follow TDD red-green-refactor cycle
- Integration tests validate cross-component coordination
- E2E tests validate full user flows with realistic data

### Accessibility
- All dose indicators need descriptive labels
- Action sheets must announce actions clearly
- VoiceOver must distinguish between scheduled/logged/missed doses
- Calendar navigation must work with assistive technologies
