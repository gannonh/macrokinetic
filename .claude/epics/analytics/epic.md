---
name: analytics
status: in-progress
created: 2025-09-21T21:11:24Z
progress: 33%
updated: 2025-09-28T16:00:22Z
prd: .claude/prds/analytics.md
github: https://github.com/gannonh/jab-tracker-ios/issues/52
---

# Epic: Analytics

## Overview
Build comprehensive analytics dashboard using Swift Charts to visualize medication concentration timelines, dose adherence patterns, and generate healthcare provider reports. Leverages existing pharmacokinetics engine and dose tracking data with local processing for privacy.

## Architecture Decisions
- **Swift Charts Framework**: Native iOS 17+ charting for performance and integration
- **Existing Pharmacokinetics Engine**: Reuse concentration calculations rather than rebuilding
- **SwiftData Integration**: Extend existing dose and medication models for analytics data
- **Local Processing**: All analytics computed on-device for privacy compliance
- **MVVM Pattern**: AnalyticsViewModel managing chart data and business logic

## Technical Approach
### Frontend Components
- **AnalyticsTabView**: Main container with chart types switcher
- **ConcentrationTimelineChart**: Interactive line chart with dose markers
- **AdherenceInsightsView**: Consistency tracking and adherence metrics
- **ExportableReportView**: PDF-ready healthcare provider summary
- **Chart interaction utilities**: Zoom, pan, time period selection

### Backend Services
- **AnalyticsService**: Aggregate dose data and calculate metrics
- **ChartDataProcessor**: Transform dose records into chart-ready datasets
- **ReportGenerator**: Create exportable PDF reports using existing data
- **Extend existing PharmacokineticsEngine**: Add analytics-specific calculations

### Infrastructure
- **Performance optimization**: Background processing for complex calculations
- **Memory management**: Efficient data structures for large historical datasets
- **Export integration**: iOS Share Sheet for report distribution

## Implementation Strategy
- **Phase 1**: Core concentration timeline with existing dose data
- **Phase 2**: Adherence insights and pattern recognition
- **Phase 3**: Exportable reports and advanced analytics
- **Testing approach**: Leverage existing test patterns with chart-specific validation

## Task Breakdown Preview
High-level task categories that will be created:
- [ ] Extend SwiftData models for analytics metadata
- [ ] Create AnalyticsService leveraging existing dose data
- [ ] Build ConcentrationTimelineChart with Swift Charts
- [ ] Implement AdherenceInsightsView with metrics calculation
- [ ] Create ExportableReportView with PDF generation
- [ ] Add Analytics tab to main TabView navigation
- [ ] Integrate with existing PharmacokineticsEngine
- [ ] Performance optimization for large datasets
- [ ] Comprehensive testing suite for analytics accuracy

## Dependencies
- **Existing Pharmacokinetics Engine**: Concentration calculations and modeling
- **SwiftData Dose Models**: Historical dose data as analytics foundation
- **Design System**: Reuse existing UI components and styling patterns
- **Swift Charts Framework**: iOS 17+ requirement for advanced charting
- **Core Graphics**: PDF export functionality for healthcare reports

## Success Criteria (Technical)
- **Performance**: Chart rendering under 500ms for 1-year datasets
- **Memory efficiency**: Smooth interaction with large historical data
- **Analytics accuracy**: Validated concentration models and adherence calculations
- **Export functionality**: Professional PDF reports compatible with medical records
- **Accessibility**: Full VoiceOver support and Dynamic Type compatibility

## Estimated Effort
- **Overall timeline**: 3-4 development sprints
- **Resource requirements**: 1 iOS developer with Swift Charts experience
- **Critical path**: Analytics service foundation → Chart implementation → Export features

## Tasks Created
- [x] #53 - Extend SwiftData Models for Analytics (parallel: false)
- [x] #54 - Create AnalyticsService Core (parallel: false)
- [x] #55 - Build ChartDataProcessor (parallel: true)
- [ ] #56 - Implement ConcentrationTimelineChart (parallel: false)
- [ ] #57 - Create AdherenceInsightsView (parallel: true)
- [ ] #58 - Build ExportableReportView (parallel: true)
- [ ] #59 - Add AnalyticsTabView Navigation (parallel: false)
- [ ] #60 - Performance Optimization for Large Datasets (parallel: true)
- [ ] #61 - Comprehensive Testing Suite for Analytics (parallel: true)

Total tasks: 9
Parallel tasks: 5
Sequential tasks: 4
Estimated total effort: 126-158 hours