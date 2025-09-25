//
//  ConcentrationChartAccessibilityTests.swift
//  JabTrackerTests
//

import Foundation
import Testing

@testable import JabTracker

/// Comprehensive tests for ConcentrationChartAccessibility
/// Tests accessibility value generation, trend descriptions, and formatting functions
@Suite("ConcentrationChartAccessibility Tests")
struct ConcentrationChartAccessibilityTests {

    // MARK: - Test Helper Functions

    private func createTestConcentrationPoint(date: Date, concentration: Double) -> AdvancedConcentrationPoint {
        AdvancedConcentrationPoint(date: date, concentration: concentration)
    }

    private func createTestDoseMarker(date: Date, amount: Double) -> AdvancedDoseMarker {
        AdvancedDoseMarker(
            date: date,
            amount: amount,
            markerStyle: .standard
        )
    }

    // MARK: - Accessibility Value Tests

    @Test("accessibilityValue provides basic chart summary")
    func testAccessibilityValueBasic() {
        let points = [
            createTestConcentrationPoint(date: Date(), concentration: 2.5),
            createTestConcentrationPoint(date: Date().addingTimeInterval(3600), concentration: 2.2),
        ]
        let markers = [
            createTestDoseMarker(date: Date(), amount: 1.0)
        ]

        let result = ConcentrationChartAccessibility.accessibilityValue(
            for: points,
            markers: markers,
            timeRange: .lastWeek,
            zoomLevel: 1.0
        )

        #expect(result.contains("2 concentration points"))
        #expect(result.contains("1 dose markers"))
        #expect(result.contains("Last Week"))
        #expect(!result.contains("zoomed"))
    }

    @Test("accessibilityValue includes zoom information when zoomed")
    func testAccessibilityValueWithZoom() {
        let points: [AdvancedConcentrationPoint] = []
        let markers: [AdvancedDoseMarker] = []

        let result = ConcentrationChartAccessibility.accessibilityValue(
            for: points,
            markers: markers,
            timeRange: .lastMonth,
            zoomLevel: 2.5
        )

        #expect(result.contains("0 concentration points"))
        #expect(result.contains("0 dose markers"))
        #expect(result.contains("Last Month"))
        #expect(result.contains("zoomed to 250%"))
    }

    @Test("accessibilityValue works with different time ranges")
    func testAccessibilityValueDifferentTimeRanges() {
        let points = [createTestConcentrationPoint(date: Date(), concentration: 1.0)]
        let markers = [createTestDoseMarker(date: Date(), amount: 0.5)]

        let timeRanges: [TimeRange] = [
            .automatic,
            .last24Hours,
            .lastWeek,
            .lastMonth,
            .lastQuarter,
            .lastYear,
        ]

        for timeRange in timeRanges {
            let result = ConcentrationChartAccessibility.accessibilityValue(
                for: points,
                markers: markers,
                timeRange: timeRange,
                zoomLevel: 1.0
            )

            #expect(result.contains("1 concentration points"))
            #expect(result.contains("1 dose markers"))
            #expect(result.contains(timeRange.displayName))
        }
    }

    @Test("accessibilityValue works with custom time range")
    func testAccessibilityValueCustomTimeRange() {
        let points: [AdvancedConcentrationPoint] = []
        let markers: [AdvancedDoseMarker] = []
        let customRange = TimeRange.custom(startDate: Date().addingTimeInterval(-86400), endDate: Date())

        let result = ConcentrationChartAccessibility.accessibilityValue(
            for: points,
            markers: markers,
            timeRange: customRange,
            zoomLevel: 1.5
        )

        #expect(result.contains("Custom Range"))
        #expect(result.contains("zoomed to 150%"))
    }

    // MARK: - Accessibility Hint Tests

    @Test("accessibilityHint handles empty data")
    func testAccessibilityHintEmptyData() {
        let emptyPoints: [AdvancedConcentrationPoint] = []

        let result = ConcentrationChartAccessibility.accessibilityHint(for: emptyPoints)

        #expect(result.contains("No concentration data available"))
        #expect(result.contains("Start tracking doses"))
    }

    @Test("accessibilityHint provides current level and instructions")
    func testAccessibilityHintWithData() {
        let points = [
            createTestConcentrationPoint(date: Date().addingTimeInterval(-3600), concentration: 2.0),
            createTestConcentrationPoint(date: Date(), concentration: 3.5),
        ]

        let result = ConcentrationChartAccessibility.accessibilityHint(for: points)

        #expect(result.contains("Current concentration level:"))
        #expect(result.contains("3.5 units"))
        #expect(result.contains("high level"))
        #expect(result.contains("Use pinch to zoom"))
        #expect(result.contains("drag to pan"))
        #expect(result.contains("double tap to reset"))
    }

    @Test("accessibilityHint finds latest point correctly")
    func testAccessibilityHintLatestPoint() {
        let oldDate = Date().addingTimeInterval(-7200)  // 2 hours ago
        let recentDate = Date().addingTimeInterval(-1800)  // 30 minutes ago
        let currentDate = Date()

        let points = [
            createTestConcentrationPoint(date: oldDate, concentration: 1.0),
            createTestConcentrationPoint(date: currentDate, concentration: 4.0),
            createTestConcentrationPoint(date: recentDate, concentration: 2.5),
        ]

        let result = ConcentrationChartAccessibility.accessibilityHint(for: points)

        // Should use the latest point (currentDate with 4.0 concentration)
        #expect(result.contains("4.0 units"))
        #expect(result.contains("high level"))
    }

    // MARK: - Trend Description Tests

    @Test("trendDescription handles insufficient data")
    func testTrendDescriptionInsufficientData() {
        let singlePoint = [createTestConcentrationPoint(date: Date(), concentration: 2.0)]
        let emptyPoints: [AdvancedConcentrationPoint] = []

        let resultSingle = ConcentrationChartAccessibility.trendDescription(for: singlePoint)
        let resultEmpty = ConcentrationChartAccessibility.trendDescription(for: emptyPoints)

        #expect(resultSingle.contains("Insufficient data"))
        #expect(resultEmpty.contains("Insufficient data"))
    }

    @Test("trendDescription identifies stable levels")
    func testTrendDescriptionStable() {
        let points = [
            createTestConcentrationPoint(date: Date().addingTimeInterval(-3600), concentration: 2.0),
            createTestConcentrationPoint(date: Date().addingTimeInterval(-1800), concentration: 2.05),
            createTestConcentrationPoint(date: Date().addingTimeInterval(-900), concentration: 1.95),
            createTestConcentrationPoint(date: Date(), concentration: 2.0),
        ]

        let result = ConcentrationChartAccessibility.trendDescription(for: points)

        #expect(result.contains("stable"))
    }

    @Test("trendDescription identifies increasing trend")
    func testTrendDescriptionIncreasing() {
        let points = [
            createTestConcentrationPoint(date: Date().addingTimeInterval(-3600), concentration: 1.0),
            createTestConcentrationPoint(date: Date().addingTimeInterval(-1800), concentration: 1.2),
            createTestConcentrationPoint(date: Date().addingTimeInterval(-900), concentration: 2.5),
            createTestConcentrationPoint(date: Date(), concentration: 3.0),
        ]

        let result = ConcentrationChartAccessibility.trendDescription(for: points)

        #expect(result.contains("increasing"))
        #expect(result.contains("%"))
    }

    @Test("trendDescription identifies decreasing trend")
    func testTrendDescriptionDecreasing() {
        let points = [
            createTestConcentrationPoint(date: Date().addingTimeInterval(-3600), concentration: 4.0),
            createTestConcentrationPoint(date: Date().addingTimeInterval(-1800), concentration: 3.8),
            createTestConcentrationPoint(date: Date().addingTimeInterval(-900), concentration: 2.0),
            createTestConcentrationPoint(date: Date(), concentration: 1.5),
        ]

        let result = ConcentrationChartAccessibility.trendDescription(for: points)

        #expect(result.contains("decreasing"))
        #expect(result.contains("%"))
    }

    @Test("trendDescription handles unsorted points correctly")
    func testTrendDescriptionUnsortedPoints() {
        // Create points in random order - should still calculate trend correctly
        let points = [
            createTestConcentrationPoint(date: Date(), concentration: 3.0),
            createTestConcentrationPoint(date: Date().addingTimeInterval(-3600), concentration: 1.0),
            createTestConcentrationPoint(date: Date().addingTimeInterval(-900), concentration: 2.5),
            createTestConcentrationPoint(date: Date().addingTimeInterval(-1800), concentration: 1.5),
        ]

        let result = ConcentrationChartAccessibility.trendDescription(for: points)

        #expect(result.contains("increasing"))
    }

    @Test("trendDescription calculates percentage change correctly")
    func testTrendDescriptionPercentageCalculation() {
        // First half average: (1.0 + 1.0) / 2 = 1.0
        // Second half average: (2.0 + 2.0) / 2 = 2.0
        // Change: (2.0 - 1.0) / 1.0 * 100 = 100%
        let points = [
            createTestConcentrationPoint(date: Date().addingTimeInterval(-3600), concentration: 1.0),
            createTestConcentrationPoint(date: Date().addingTimeInterval(-1800), concentration: 1.0),
            createTestConcentrationPoint(date: Date().addingTimeInterval(-900), concentration: 2.0),
            createTestConcentrationPoint(date: Date(), concentration: 2.0),
        ]

        let result = ConcentrationChartAccessibility.trendDescription(for: points)

        #expect(result.contains("increasing by 100%"))
    }

    // MARK: - Format Concentration For Accessibility Tests

    @Test("formatConcentrationForAccessibility handles low levels")
    func testFormatConcentrationLowLevels() {
        let testCases = [0.0, 0.5, 1.0]

        for concentration in testCases {
            let result = ConcentrationChartAccessibility.formatConcentrationForAccessibility(concentration)
            #expect(result.contains("low level"))
            #expect(result.contains(String(format: "%.1f", concentration)))
            #expect(result.contains("units"))
        }
    }

    @Test("formatConcentrationForAccessibility handles moderate levels")
    func testFormatConcentrationModerateLevels() {
        let testCases = [1.5, 2.0, 2.5, 3.0]

        for concentration in testCases {
            let result = ConcentrationChartAccessibility.formatConcentrationForAccessibility(concentration)
            #expect(result.contains("moderate level"))
            #expect(result.contains(String(format: "%.1f", concentration)))
        }
    }

    @Test("formatConcentrationForAccessibility handles high levels")
    func testFormatConcentrationHighLevels() {
        let testCases = [3.5, 4.0, 4.5, 5.0]

        for concentration in testCases {
            let result = ConcentrationChartAccessibility.formatConcentrationForAccessibility(concentration)
            #expect(result.contains("high level"))
            #expect(result.contains(String(format: "%.1f", concentration)))
        }
    }

    @Test("formatConcentrationForAccessibility handles very high levels")
    func testFormatConcentrationVeryHighLevels() {
        let testCases = [5.1, 10.0, 15.5, 100.0]

        for concentration in testCases {
            let result = ConcentrationChartAccessibility.formatConcentrationForAccessibility(concentration)
            #expect(result.contains("very high level"))
            #expect(result.contains(String(format: "%.1f", concentration)))
        }
    }

    @Test("formatConcentrationForAccessibility formats numbers correctly")
    func testFormatConcentrationNumberFormatting() {
        let testCases: [(Double, String)] = [
            (0.0, "0.0"),
            (1.23, "1.2"),
            (2.56, "2.6"),
            (10.99, "11.0"),
            (15.04, "15.0"),
        ]

        for (input, expectedFormat) in testCases {
            let result = ConcentrationChartAccessibility.formatConcentrationForAccessibility(input)
            #expect(result.contains(expectedFormat))
        }
    }

    // MARK: - Format Dose Amount Tests

    @Test("formatDoseAmount formats correctly with mg units")
    func testFormatDoseAmount() {
        let testCases: [(Double, String)] = [
            (0.25, "0.2 mg"),  // Rounded to 1 decimal
            (0.5, "0.5 mg"),
            (1.0, "1.0 mg"),
            (1.25, "1.2 mg"),  // Rounded to 1 decimal
            (2.4, "2.4 mg"),
            (10.75, "10.8 mg"),  // Rounded to 1 decimal
        ]

        for (input, expected) in testCases {
            let result = ConcentrationChartAccessibility.formatDoseAmount(input)
            #expect(result == expected, "Expected '\(expected)' but got '\(result)' for input \(input)")
        }
    }

    @Test("formatDoseAmount handles edge cases")
    func testFormatDoseAmountEdgeCases() {
        let edgeCases = [0.0, 0.01, 999.99]

        for amount in edgeCases {
            let result = ConcentrationChartAccessibility.formatDoseAmount(amount)
            #expect(result.contains("mg"))
            #expect(result.contains(String(format: "%.1f", amount)))
        }
    }

    // MARK: - Integration Tests

    @Test("All methods work together in realistic scenario")
    func testIntegrationScenario() {
        let points = [
            createTestConcentrationPoint(date: Date().addingTimeInterval(-7200), concentration: 1.2),
            createTestConcentrationPoint(date: Date().addingTimeInterval(-3600), concentration: 2.8),
            createTestConcentrationPoint(date: Date().addingTimeInterval(-1800), concentration: 3.5),
            createTestConcentrationPoint(date: Date(), concentration: 4.2),
        ]

        let markers = [
            createTestDoseMarker(date: Date().addingTimeInterval(-7200), amount: 1.0),
            createTestDoseMarker(date: Date(), amount: 1.0),
        ]

        // Test accessibility value
        let accessibilityValue = ConcentrationChartAccessibility.accessibilityValue(
            for: points,
            markers: markers,
            timeRange: .lastWeek,
            zoomLevel: 1.5
        )
        #expect(accessibilityValue.contains("4 concentration points"))
        #expect(accessibilityValue.contains("2 dose markers"))
        #expect(accessibilityValue.contains("Last Week"))
        #expect(accessibilityValue.contains("150%"))

        // Test accessibility hint
        let hint = ConcentrationChartAccessibility.accessibilityHint(for: points)
        #expect(hint.contains("4.2 units"))
        #expect(hint.contains("high level"))

        // Test trend description
        let trend = ConcentrationChartAccessibility.trendDescription(for: points)
        #expect(trend.contains("increasing"))

        // Test formatting functions
        let concentrationFormat = ConcentrationChartAccessibility.formatConcentrationForAccessibility(4.2)
        #expect(concentrationFormat.contains("4.2 units, high level"))

        let doseFormat = ConcentrationChartAccessibility.formatDoseAmount(1.0)
        #expect(doseFormat == "1.0 mg")
    }
}
