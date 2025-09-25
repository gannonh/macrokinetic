//
//  ChartDataModelTests.swift
//  JabTrackerTests
//

import Foundation
import SwiftUI
import Testing

@testable import JabTracker

/// Comprehensive tests for ChartData model types and enums
/// Covers chart configuration, themes, ranges, and interpolation types
@Suite("ChartData Model Tests")
struct ChartDataModelTests {

    // MARK: - TimeRange Tests

    @Test("TimeRange displays correct names for all cases")
    func testTimeRangeDisplayNames() {
        #expect(TimeRange.automatic.displayName == "Automatic")
        #expect(TimeRange.custom(startDate: Date(), endDate: Date()).displayName == "Custom Range")
        #expect(TimeRange.last24Hours.displayName == "Last 24 Hours")
        #expect(TimeRange.lastWeek.displayName == "Last Week")
        #expect(TimeRange.lastMonth.displayName == "Last Month")
        #expect(TimeRange.lastQuarter.displayName == "Last Quarter")
        #expect(TimeRange.lastYear.displayName == "Last Year")
    }

    @Test("TimeRange dateRange calculations work correctly")
    func testTimeRangeDateRangeCalculations() {
        let referenceDate = Date()
        let calendar = Calendar.current

        // Test automatic range (7 days)
        let automaticRange = TimeRange.automatic.dateRange(relativeTo: referenceDate)
        let expectedStart = calendar.date(byAdding: .day, value: -7, to: referenceDate) ?? referenceDate
        #expect(abs(automaticRange.start.timeIntervalSince(expectedStart)) < 1.0)
        #expect(abs(automaticRange.end.timeIntervalSince(referenceDate)) < 1.0)

        // Test last 24 hours
        let last24Range = TimeRange.last24Hours.dateRange(relativeTo: referenceDate)
        let expected24Start = calendar.date(byAdding: .hour, value: -24, to: referenceDate) ?? referenceDate
        #expect(abs(last24Range.start.timeIntervalSince(expected24Start)) < 1.0)

        // Test last week
        let lastWeekRange = TimeRange.lastWeek.dateRange(relativeTo: referenceDate)
        let expectedWeekStart = calendar.date(byAdding: .day, value: -7, to: referenceDate) ?? referenceDate
        #expect(abs(lastWeekRange.start.timeIntervalSince(expectedWeekStart)) < 1.0)

        // Test last month
        let lastMonthRange = TimeRange.lastMonth.dateRange(relativeTo: referenceDate)
        let expectedMonthStart = calendar.date(byAdding: .month, value: -1, to: referenceDate) ?? referenceDate
        #expect(abs(lastMonthRange.start.timeIntervalSince(expectedMonthStart)) < 1.0)

        // Test last quarter
        let lastQuarterRange = TimeRange.lastQuarter.dateRange(relativeTo: referenceDate)
        let expectedQuarterStart = calendar.date(byAdding: .month, value: -3, to: referenceDate) ?? referenceDate
        #expect(abs(lastQuarterRange.start.timeIntervalSince(expectedQuarterStart)) < 1.0)

        // Test last year
        let lastYearRange = TimeRange.lastYear.dateRange(relativeTo: referenceDate)
        let expectedYearStart = calendar.date(byAdding: .year, value: -1, to: referenceDate) ?? referenceDate
        #expect(abs(lastYearRange.start.timeIntervalSince(expectedYearStart)) < 1.0)

        // Test custom range
        let customStart = Date().addingTimeInterval(-1000)
        let customEnd = Date()
        let customRange = TimeRange.custom(startDate: customStart, endDate: customEnd).dateRange()
        #expect(customRange.start == customStart)
        #expect(customRange.end == customEnd)
    }

    // MARK: - ConcentrationRange Tests

    @Test("ConcentrationRange calculates automatic range correctly")
    func testConcentrationRangeAutomatic() {
        let concentrations = [2.5, 5.0, 7.5, 3.0, 6.0]
        let automaticRange = ConcentrationRange.automatic

        let result = automaticRange.range(for: concentrations)

        // Min should be 2.5, max should be 7.5
        // With 10% padding: (7.5 - 2.5) * 0.1 = 0.5
        // Expected range: max(0, 2.5 - 0.5) to 7.5 + 0.5 = 2.0 to 8.0
        #expect(result.min == 2.0)
        #expect(result.max == 8.0)
    }

    @Test("ConcentrationRange handles custom range")
    func testConcentrationRangeCustom() {
        let concentrations = [1.0, 2.0, 3.0]
        let customRange = ConcentrationRange.custom(min: 0.5, max: 10.0)

        let result = customRange.range(for: concentrations)

        #expect(result.min == 0.5)
        #expect(result.max == 10.0)
    }

    @Test("ConcentrationRange handles therapeutic window")
    func testConcentrationRangeTherapeuticWindow() {
        let concentrations = [1.0, 2.0, 3.0]
        let therapeuticRange = ConcentrationRange.therapeuticWindow(min: 2.0, max: 8.0, optimal: 5.0)

        let result = therapeuticRange.range(for: concentrations)

        // Should be min * 0.9 and max * 1.1 for 10% padding
        #expect(result.min == 1.8)  // 2.0 * 0.9
        #expect(result.max == 8.8)  // 8.0 * 1.1
    }

    @Test("ConcentrationRange handles fixed scale")
    func testConcentrationRangeFixedScale() {
        let concentrations = [1.0, 2.0, 3.0]
        let fixedRange = ConcentrationRange.fixedScale(max: 15.0)

        let result = fixedRange.range(for: concentrations)

        #expect(result.min == 0.0)
        #expect(result.max == 15.0)
    }

    @Test("ConcentrationRange handles empty concentration array")
    func testConcentrationRangeEmptyArray() {
        let emptyConcentrations: [Double] = []
        let automaticRange = ConcentrationRange.automatic

        let result = automaticRange.range(for: emptyConcentrations)

        // When empty, min() returns nil -> uses 0, max() returns nil -> uses 10
        // padding = (10-0)*0.1 = 1.0
        // min = max(0, 0-1) = 0, max = 10+1 = 11
        #expect(result.min == 0.0)  // max(0, 0-1) = 0
        #expect(result.max == 11.0)  // 10 + 1 = 11
    }

    // MARK: - ChartTheme Tests

    @Test("ChartTheme provides correct primary colors")
    func testChartThemePrimaryColors() {
        #expect(ChartTheme.medical.primaryColor == .blue)
        #expect(ChartTheme.consumer.primaryColor == .green)
        #expect(ChartTheme.professional.primaryColor == .gray)
        #expect(ChartTheme.accessible.primaryColor == .primary)
    }

    @Test("ChartTheme provides correct background colors")
    func testChartThemeBackgroundColors() {
        #expect(ChartTheme.medical.backgroundColor == Color(.systemBackground))
        #expect(ChartTheme.consumer.backgroundColor == Color(.systemGroupedBackground))
        #expect(ChartTheme.professional.backgroundColor == .white)
        #expect(ChartTheme.accessible.backgroundColor == Color(.systemBackground))
    }

    @Test("ChartTheme provides correct grid colors")
    func testChartThemeGridColors() {
        #expect(ChartTheme.medical.gridColor == Color(.systemGray5))
        #expect(ChartTheme.consumer.gridColor == Color(.systemGray6))
        #expect(ChartTheme.professional.gridColor == Color(.systemGray4))
        #expect(ChartTheme.accessible.gridColor == Color(.systemGray3))
    }

    // MARK: - CurveStyle Tests

    @Test("CurveStyle provides correct stroke styles")
    func testCurveStyleStrokeStyles() {
        let smoothStyle = CurveStyle.smooth.strokeStyle
        #expect(smoothStyle.lineWidth == 2)

        let angularStyle = CurveStyle.angular.strokeStyle
        #expect(angularStyle.lineWidth == 2)
        #expect(angularStyle.lineCap == .square)
        #expect(angularStyle.lineJoin == .miter)

        let dashedStyle = CurveStyle.dashed.strokeStyle
        #expect(dashedStyle.lineWidth == 2)
        #expect(dashedStyle.dash == [5, 3])

        let dottedStyle = CurveStyle.dotted.strokeStyle
        #expect(dottedStyle.lineWidth == 2)
        #expect(dottedStyle.dash == [1, 3])

        let gradientStyle = CurveStyle.gradient.strokeStyle
        #expect(gradientStyle.lineWidth == 3)
    }

    // MARK: - InterpolationType Tests

    @Test("InterpolationType provides correct display names")
    func testInterpolationTypeDisplayNames() {
        #expect(InterpolationType.linear.displayName == "Linear")
        #expect(InterpolationType.pharmacokinetic.displayName == "Pharmacokinetic")
        #expect(InterpolationType.spline.displayName == "Cubic Spline")
        #expect(InterpolationType.bezier.displayName == "Bezier Curve")
    }

    @Test("InterpolationType provides correct descriptions")
    func testInterpolationTypeDescriptions() {
        #expect(InterpolationType.linear.description == "Simple linear interpolation between points")
        #expect(InterpolationType.pharmacokinetic.description == "Exponential decay modeling based on drug half-life")
        #expect(InterpolationType.spline.description == "Smooth cubic spline interpolation")
        #expect(InterpolationType.bezier.description == "Bezier curve interpolation for smooth transitions")
    }

    // MARK: - ConfidenceInterval Tests

    @Test("ConfidenceInterval initializes correctly")
    func testConfidenceIntervalInitialization() {
        let interval = ConfidenceInterval(lowerBound: 2.0, upperBound: 8.0, confidenceLevel: 0.95)

        #expect(interval.lowerBound == 2.0)
        #expect(interval.upperBound == 8.0)
        #expect(interval.confidenceLevel == 0.95)
    }

    @Test("ConfidenceInterval uses default confidence level")
    func testConfidenceIntervalDefaultLevel() {
        let interval = ConfidenceInterval(lowerBound: 1.0, upperBound: 5.0)

        #expect(interval.confidenceLevel == 0.95)
    }

    // MARK: - ConcentrationChartConfiguration Tests

    @Test("ConcentrationChartConfiguration default configuration is valid")
    func testConcentrationChartConfigurationDefault() {
        let config = ConcentrationChartConfiguration.default

        #expect(config.timeRange == .automatic)
        #expect(config.concentrationRange == .automatic)
        #expect(config.theme == .medical)
    }

    @Test("ConcentrationChartConfiguration custom initialization works")
    func testConcentrationChartConfigurationCustom() {
        let config = ConcentrationChartConfiguration(
            timeRange: .lastWeek,
            concentrationRange: .fixedScale(max: 10.0),
            interpolationSettings: .linear,
            theme: .professional,
            gridSettings: .minimal,
            axisSettings: .default,
            interactionSettings: .readOnly,
            animationSettings: .fast
        )

        #expect(config.timeRange == .lastWeek)
        #expect(config.theme == .professional)
        #expect(config.interpolationSettings.type == .linear)
    }

    // MARK: - ConcentrationChartDataset Tests

    @Test("ConcentrationChartDataset initializes correctly")
    func testConcentrationChartDataset() {
        let points = [AdvancedConcentrationPoint(date: Date(), concentration: 5.0)]
        let curve = ConcentrationCurve(points: points, medication: "Test Med")
        let markers = [AdvancedDoseMarker(date: Date(), amount: 1.0)]

        let dataset = ConcentrationChartDataset(
            concentrationCurves: [curve],
            doseMarkers: markers,
            configuration: .default
        )

        #expect(dataset.concentrationCurves.count == 1)
        #expect(dataset.doseMarkers.count == 1)
        #expect(dataset.concentrationCurves.first?.medication == "Test Med")
    }

    // MARK: - ConcentrationCurve Tests

    @Test("ConcentrationCurve initializes with default values")
    func testConcentrationCurveDefaults() {
        let points = [AdvancedConcentrationPoint(date: Date(), concentration: 3.0)]
        let curve = ConcentrationCurve(points: points, medication: "Semaglutide")

        #expect(curve.points.count == 1)
        #expect(curve.medication == "Semaglutide")
        #expect(curve.curveStyle == .smooth)
        #expect(curve.isVisible == true)
        #expect(!curve.id.uuidString.isEmpty)
    }

    // MARK: - ChartMetadata Tests

    @Test("ChartMetadata initializes with default values")
    func testChartMetadataDefaults() {
        let metadata = ChartMetadata()

        #expect(metadata.title == "Concentration Timeline")
        #expect(metadata.subtitle == nil)
        #expect(metadata.dataSource == "JabTracker")
        #expect(metadata.version == "1.0")
        #expect(abs(metadata.generatedAt.timeIntervalSinceNow) < 2.0)  // Within 2 seconds of now
    }

    @Test("ChartMetadata initializes with custom values")
    func testChartMetadataCustom() {
        let customDate = Date().addingTimeInterval(-3600)  // 1 hour ago
        let metadata = ChartMetadata(
            title: "Custom Chart",
            subtitle: "Test Subtitle",
            generatedAt: customDate,
            dataSource: "Test Source",
            version: "2.0"
        )

        #expect(metadata.title == "Custom Chart")
        #expect(metadata.subtitle == "Test Subtitle")
        #expect(metadata.dataSource == "Test Source")
        #expect(metadata.version == "2.0")
        #expect(metadata.generatedAt == customDate)
    }
}
