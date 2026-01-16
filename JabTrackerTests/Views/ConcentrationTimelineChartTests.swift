//
//  ConcentrationTimelineChartTests.swift
//  JabTrackerTests
//

import SwiftData
import SwiftUI
import Testing

@testable import JabTracker

/// Unit tests for ConcentrationTimelineChart view and chart data integration
/// Validates chart data processing, configuration handling, and accessibility features
@MainActor
struct ConcentrationTimelineChartTests {

    // MARK: - Test Setup Helpers

    /// Creates a test chart dataset for unit testing
    private func createTestChartDataset() -> ConcentrationChartDataset {
        let concentrationPoints = [
            AdvancedConcentrationPoint(date: Date().addingTimeInterval(-24 * 3600), concentration: 0.0),
            AdvancedConcentrationPoint(date: Date().addingTimeInterval(-12 * 3600), concentration: 5.2),
            AdvancedConcentrationPoint(date: Date().addingTimeInterval(-6 * 3600), concentration: 3.8),
            AdvancedConcentrationPoint(date: Date(), concentration: 2.1),
        ]

        let doseMarkers = [
            AdvancedDoseMarker(
                date: Date().addingTimeInterval(-24 * 3600),
                amount: 1.0,
                markerStyle: .firstDose
            ),
            AdvancedDoseMarker(
                date: Date().addingTimeInterval(-12 * 3600),
                amount: 1.0,
                markerStyle: .standard
            ),
        ]

        let concentrationCurve = ConcentrationCurve(
            points: concentrationPoints,
            medication: "semaglutide"
        )

        return ConcentrationChartDataset(
            concentrationCurves: [concentrationCurve],
            doseMarkers: doseMarkers,
            configuration: .default
        )
    }

    // MARK: - Chart Data Integration Tests

    @Test("ConcentrationTimelineChart initializes with valid dataset")
    func testChartInitializationWithDataset() async {
        // GIVEN: Valid concentration chart dataset
        let dataset = createTestChartDataset()

        // WHEN: Creating ConcentrationTimelineChart with dataset
        let chart = ConcentrationTimelineChart(dataset: dataset)

        // THEN: Chart should initialize successfully
        #expect(chart.dataset.concentrationCurves.count == 1, "Should have one concentration curve")
        #expect(chart.dataset.doseMarkers.count == 2, "Should have two dose markers")
        #expect(
            chart.configuration.timeRange == .automatic, "Should use automatic time range by default")
    }

    @Test("ConcentrationTimelineChart handles empty dataset gracefully")
    func testChartWithEmptyDataset() async {
        // GIVEN: Empty concentration chart dataset
        let emptyDataset = ConcentrationChartDataset(
            concentrationCurves: [],
            doseMarkers: [],
            configuration: .default
        )

        // WHEN: Creating ConcentrationTimelineChart with empty dataset
        let chart = ConcentrationTimelineChart(dataset: emptyDataset)

        // THEN: Chart should handle empty data gracefully
        #expect(chart.dataset.concentrationCurves.isEmpty, "Should handle empty concentration curves")
        #expect(chart.dataset.doseMarkers.isEmpty, "Should handle empty dose markers")
        #expect(chart.showsEmptyState == true, "Should show empty state for no data")
    }

    // MARK: - Chart Configuration Tests

    @Test("ConcentrationTimelineChart applies custom configuration correctly")
    func testChartCustomConfiguration() async {
        // GIVEN: Custom chart configuration
        let customConfig = ConcentrationChartConfiguration(
            timeRange: .lastWeek,
            concentrationRange: .custom(min: 0, max: 10),
            interpolationSettings: .pharmacokinetic,
            theme: .medical,
            gridSettings: .minimal,
            axisSettings: .default,
            interactionSettings: .default,
            animationSettings: .fast
        )

        let dataset = ConcentrationChartDataset(
            concentrationCurves: [],
            doseMarkers: [],
            configuration: customConfig
        )

        // WHEN: Creating chart with custom configuration
        let chart = ConcentrationTimelineChart(dataset: dataset)

        // THEN: Chart should apply custom configuration
        #expect(chart.configuration.timeRange == .lastWeek, "Should use custom time range")
        #expect(chart.configuration.theme == .medical, "Should use medical theme")
        #expect(
            chart.configuration.animationSettings.duration == 0.3, "Should use fast animation duration")
    }

    // MARK: - Time Period Selection Tests

    @Test("ConcentrationTimelineChart processes different time ranges correctly")
    func testTimePeriodSelection() async {
        // GIVEN: Chart dataset with different time range configurations
        let baseDataset = createTestChartDataset()

        // WHEN: Creating chart with last month configuration
        let lastMonthConfig = baseDataset.configuration.withTimeRange(.lastMonth)
        let lastMonthDataset = ConcentrationChartDataset(
            concentrationCurves: baseDataset.concentrationCurves,
            doseMarkers: baseDataset.doseMarkers,
            configuration: lastMonthConfig
        )
        let lastMonthChart = ConcentrationTimelineChart(dataset: lastMonthDataset)

        // THEN: Chart should use last month time range
        #expect(
            lastMonthChart.configuration.timeRange == .lastMonth, "Should use last month time range")

        // WHEN: Creating chart with custom time range
        let startDate = Date().addingTimeInterval(-30 * 24 * 3600)
        let endDate = Date()
        let customConfig = baseDataset.configuration.withTimeRange(
            .custom(startDate: startDate, endDate: endDate))
        let customDataset = ConcentrationChartDataset(
            concentrationCurves: baseDataset.concentrationCurves,
            doseMarkers: baseDataset.doseMarkers,
            configuration: customConfig
        )
        let customChart = ConcentrationTimelineChart(dataset: customDataset)

        // THEN: Chart should use custom time range
        #expect(
            customChart.configuration.timeRange == .custom(startDate: startDate, endDate: endDate),
            "Should use custom date range")

        // THEN: Different time ranges should filter data differently
        let automaticPoints = baseDataset.configuration.timeRange.dateRange()
        let lastMonthPoints = lastMonthChart.configuration.timeRange.dateRange()
        #expect(
            automaticPoints.start != lastMonthPoints.start,
            "Different time ranges should have different start dates")
    }

    // MARK: - Accessibility Tests

    @Test("ConcentrationTimelineChart provides accessibility information")
    func testChartAccessibility() async {
        // GIVEN: Chart with concentration data
        let dataset = createTestChartDataset()
        let chart = ConcentrationTimelineChart(dataset: dataset)

        // WHEN: Accessing chart accessibility properties
        let accessibilityLabel = chart.accessibilityLabel
        let accessibilityValue = chart.accessibilityValue

        // THEN: Chart should provide meaningful accessibility information
        #expect(
            accessibilityLabel?.contains("Concentration Area Chart") == true,
            "Should include chart type in accessibility label")
        #expect(
            accessibilityValue?.contains("concentration") == true,
            "Should describe concentration data in accessibility value")
    }

    // MARK: - Chart Data Processing Tests

    @Test("ConcentrationTimelineChart processes concentration points correctly")
    func testConcentrationPointProcessing() async {
        // GIVEN: Dataset with concentration points
        let dataset = createTestChartDataset()
        let chart = ConcentrationTimelineChart(dataset: dataset)

        // WHEN: Processing concentration data for display
        let processedPoints = chart.processedConcentrationPoints

        // THEN: Points should be processed correctly
        #expect(processedPoints.count >= 4, "Should have at least original concentration points")
        #expect(
            processedPoints.first?.concentration == 0.0, "First point should have zero concentration")
        #expect(
            processedPoints.allSatisfy { $0.concentration >= 0 },
            "All concentrations should be non-negative")
    }

    @Test("ConcentrationTimelineChart processes dose markers correctly")
    func testDoseMarkerProcessing() async {
        // GIVEN: Dataset with dose markers
        let dataset = createTestChartDataset()
        let chart = ConcentrationTimelineChart(dataset: dataset)

        // WHEN: Processing dose marker data for display
        let processedMarkers = chart.processedDoseMarkers

        // THEN: Markers should be processed correctly
        #expect(processedMarkers.count == 2, "Should have two dose markers")
        #expect(
            processedMarkers.first?.markerStyle == .firstDose, "First marker should be first dose style")
        #expect(
            processedMarkers.last?.markerStyle == .standard, "Second marker should be standard style")
    }

    // MARK: - Performance Tests

    @Test("ConcentrationTimelineChart handles large datasets efficiently")
    func testChartPerformanceWithLargeDataset() async {
        // GIVEN: Large dataset with 1000+ concentration points
        let largePoints = (0..<1000).map { index in
            AdvancedConcentrationPoint(
                date: Date().addingTimeInterval(Double(index) * -3600),
                concentration: Double.random(in: 0...10)
            )
        }

        let largeCurve = ConcentrationCurve(
            points: largePoints,
            medication: "semaglutide"
        )

        // Use a configuration with longer time range to capture all test data
        let largeTimeRangeConfig = ConcentrationChartConfiguration(
            timeRange: .lastYear,  // Extended time range to capture all 1000 hours of test data
            concentrationRange: .automatic,
            interpolationSettings: .pharmacokinetic,
            theme: .medical,
            gridSettings: .default,
            axisSettings: .default,
            interactionSettings: .default,
            animationSettings: .fast
        )

        let largeDataset = ConcentrationChartDataset(
            concentrationCurves: [largeCurve],
            doseMarkers: [],
            configuration: largeTimeRangeConfig
        )

        // WHEN: Processing large dataset
        let startTime = Date()
        let chart = ConcentrationTimelineChart(dataset: largeDataset)
        _ = chart.processedConcentrationPoints
        let processingTime = Date().timeIntervalSince(startTime)

        // THEN: Processing should complete within performance target
        #expect(processingTime < 0.5, "Large dataset processing should complete within 500ms")
        #expect(
            chart.processedConcentrationPoints.count >= 1000, "Should process all concentration points")
    }
}
