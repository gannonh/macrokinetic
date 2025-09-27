//
//  AdherenceTrendDataTests.swift
//  JabTrackerTests
//
//  Comprehensive tests for AdherenceTrendData models including
//  AdherenceTrendPoint, ChartTimePeriod, TrendDirection, and MissedDosePattern
//

import Foundation
import Testing

@testable import JabTracker

struct AdherenceTrendDataTests {

    // MARK: - AdherenceTrendPoint Tests

    @Test("AdherenceTrendPoint creation with valid data")
    func testAdherenceTrendPointCreation() {
        // Given
        let date = Date()
        let adherenceRate = 0.85
        let period = "Week 1"

        // When
        let trendPoint = AdherenceTrendPoint(
            date: date,
            adherenceRate: adherenceRate,
            period: period
        )

        // Then
        #expect(trendPoint.date == date)
        #expect(trendPoint.adherenceRate == adherenceRate)
        #expect(trendPoint.period == period)
    }

    @Test("AdherenceTrendPoint edge case values")
    func testAdherenceTrendPointEdgeCases() {
        // Given
        let date = Date()

        // When & Then - Test with 0.0 adherence rate
        let zeroPoint = AdherenceTrendPoint(date: date, adherenceRate: 0.0, period: "Test")
        #expect(zeroPoint.adherenceRate == 0.0)

        // When & Then - Test with 1.0 adherence rate
        let perfectPoint = AdherenceTrendPoint(date: date, adherenceRate: 1.0, period: "Perfect")
        #expect(perfectPoint.adherenceRate == 1.0)

        // When & Then - Test with empty period string
        let emptyPeriodPoint = AdherenceTrendPoint(date: date, adherenceRate: 0.5, period: "")
        #expect(emptyPeriodPoint.period == "")
    }

    @Test("AdherenceTrendPoint Equatable conformance")
    func testAdherenceTrendPointEquality() {
        // Given
        let date = Date()
        let adherenceRate = 0.75
        let period = "Month 1"

        let point1 = AdherenceTrendPoint(date: date, adherenceRate: adherenceRate, period: period)
        let point2 = AdherenceTrendPoint(date: date, adherenceRate: adherenceRate, period: period)
        let point3 = AdherenceTrendPoint(date: date.addingTimeInterval(1), adherenceRate: adherenceRate, period: period)

        // Then
        #expect(point1 == point2)
        #expect(point1 != point3)
    }

    @Test("AdherenceTrendPoint Identifiable conformance")
    func testAdherenceTrendPointIdentifiable() {
        // Given
        let date = Date()
        let trendPoint = AdherenceTrendPoint(date: date, adherenceRate: 0.8, period: "Test")

        // Then
        #expect(trendPoint.id == date)
    }

    // MARK: - ChartTimePeriod Tests

    @Test("ChartTimePeriod display names")
    func testChartTimePeriodDisplayNames() {
        // Then
        #expect(ChartTimePeriod.weekly.displayName == "Weekly")
        #expect(ChartTimePeriod.monthly.displayName == "Monthly")
        #expect(ChartTimePeriod.quarterly.displayName == "Quarterly")
    }

    @Test("ChartTimePeriod CaseIterable conformance")
    func testChartTimePeriodCaseIterable() {
        // Given
        let allCases = ChartTimePeriod.allCases

        // Then
        #expect(allCases.count == 3)
        #expect(allCases.contains(.weekly))
        #expect(allCases.contains(.monthly))
        #expect(allCases.contains(.quarterly))
    }

    // MARK: - TrendDirection Tests

    @Test("TrendDirection display names")
    func testTrendDirectionDisplayNames() {
        // Then
        #expect(TrendDirection.improving.displayName == "Improving")
        #expect(TrendDirection.declining.displayName == "Declining")
        #expect(TrendDirection.stable.displayName == "Stable")
    }

    @Test("TrendDirection system image names")
    func testTrendDirectionSystemImageNames() {
        // Then
        #expect(TrendDirection.improving.systemImageName == "arrow.up.circle.fill")
        #expect(TrendDirection.declining.systemImageName == "arrow.down.circle.fill")
        #expect(TrendDirection.stable.systemImageName == "minus.circle.fill")
    }

    @Test("TrendDirection CaseIterable conformance")
    func testTrendDirectionCaseIterable() {
        // Given
        let allCases = TrendDirection.allCases

        // Then
        #expect(allCases.count == 3)
        #expect(allCases.contains(.improving))
        #expect(allCases.contains(.declining))
        #expect(allCases.contains(.stable))
    }

    // MARK: - MissedDosePattern Tests

    @Test("MissedDosePattern creation with valid data")
    func testMissedDosePatternCreation() {
        // Given
        let date = Date()
        let dayOfWeek = "Monday"
        let missedCount = 3

        // When
        let pattern = MissedDosePattern(
            date: date,
            dayOfWeek: dayOfWeek,
            missedCount: missedCount
        )

        // Then
        #expect(pattern.date == date)
        #expect(pattern.dayOfWeek == dayOfWeek)
        #expect(pattern.missedCount == missedCount)
    }

    @Test("MissedDosePattern edge case values")
    func testMissedDosePatternEdgeCases() {
        // Given
        let date = Date()

        // When & Then - Test with zero missed count
        let zeroPattern = MissedDosePattern(date: date, dayOfWeek: "Sunday", missedCount: 0)
        #expect(zeroPattern.missedCount == 0)

        // When & Then - Test with high missed count
        let highPattern = MissedDosePattern(date: date, dayOfWeek: "Friday", missedCount: 100)
        #expect(highPattern.missedCount == 100)

        // When & Then - Test with empty day of week
        let emptyDayPattern = MissedDosePattern(date: date, dayOfWeek: "", missedCount: 1)
        #expect(emptyDayPattern.dayOfWeek == "")
    }

    @Test("MissedDosePattern Equatable conformance")
    func testMissedDosePatternEquality() {
        // Given
        let date = Date()
        let dayOfWeek = "Tuesday"
        let missedCount = 2

        let pattern1 = MissedDosePattern(date: date, dayOfWeek: dayOfWeek, missedCount: missedCount)
        let pattern2 = MissedDosePattern(date: date, dayOfWeek: dayOfWeek, missedCount: missedCount)
        let pattern3 = MissedDosePattern(date: date, dayOfWeek: "Wednesday", missedCount: missedCount)

        // Then
        #expect(pattern1 == pattern2)
        #expect(pattern1 != pattern3)
    }

    @Test("MissedDosePattern Identifiable conformance")
    func testMissedDosePatternIdentifiable() {
        // Given
        let date = Date()
        let pattern = MissedDosePattern(date: date, dayOfWeek: "Thursday", missedCount: 1)

        // Then
        #expect(pattern.id == date)
    }

    // MARK: - MissedDoseVisualizationStyle Tests

    @Test("MissedDoseVisualizationStyle display names")
    func testMissedDoseVisualizationStyleDisplayNames() {
        // Then
        #expect(MissedDoseVisualizationStyle.heatmap.displayName == "Heat Map")
        #expect(MissedDoseVisualizationStyle.barChart.displayName == "Bar Chart")
        #expect(MissedDoseVisualizationStyle.calendar.displayName == "Calendar View")
    }

    @Test("MissedDoseVisualizationStyle CaseIterable conformance")
    func testMissedDoseVisualizationStyleCaseIterable() {
        // Given
        let allCases = MissedDoseVisualizationStyle.allCases

        // Then
        #expect(allCases.count == 3)
        #expect(allCases.contains(.heatmap))
        #expect(allCases.contains(.barChart))
        #expect(allCases.contains(.calendar))
    }

    // MARK: - Integration Tests

    @Test("AdherenceTrendPoint and MissedDosePattern work together")
    func testIntegrationBetweenModels() {
        // Given
        let baseDate = Date()
        let trendPoint = AdherenceTrendPoint(
            date: baseDate,
            adherenceRate: 0.6,
            period: "Week 1"
        )
        let missedPattern = MissedDosePattern(
            date: baseDate,
            dayOfWeek: "Saturday",
            missedCount: 2
        )

        // Then - Both should have same date for correlation
        #expect(trendPoint.id == missedPattern.id)
        #expect(trendPoint.date == missedPattern.date)

        // Then - Trend point should reflect missed doses
        #expect(trendPoint.adherenceRate < 1.0)  // Some adherence issues
        #expect(missedPattern.missedCount > 0)  // Has missed doses
    }

    @Test("Multiple trend points with different time periods")
    func testMultipleTrendPointsWithDifferentPeriods() {
        // Given
        let baseDate = Date()
        let points = [
            AdherenceTrendPoint(date: baseDate, adherenceRate: 0.9, period: "Week 1"),
            AdherenceTrendPoint(
                date: baseDate.addingTimeInterval(7 * 24 * 60 * 60), adherenceRate: 0.8, period: "Week 2"),
            AdherenceTrendPoint(
                date: baseDate.addingTimeInterval(14 * 24 * 60 * 60), adherenceRate: 0.7, period: "Week 3"),
        ]

        // Then
        #expect(points.count == 3)
        #expect(points[0].adherenceRate > points[1].adherenceRate)
        #expect(points[1].adherenceRate > points[2].adherenceRate)

        // All points should be unique by date
        let uniqueDates = Set(points.map { $0.date })
        #expect(uniqueDates.count == 3)
    }

    @Test("Missed dose patterns for different days of week")
    func testMissedDosePatternsForDifferentDays() {
        // Given
        let baseDate = Date()
        let patterns = [
            MissedDosePattern(date: baseDate, dayOfWeek: "Saturday", missedCount: 3),
            MissedDosePattern(date: baseDate.addingTimeInterval(24 * 60 * 60), dayOfWeek: "Sunday", missedCount: 2),
            MissedDosePattern(date: baseDate.addingTimeInterval(2 * 24 * 60 * 60), dayOfWeek: "Monday", missedCount: 0),
        ]

        // Then
        #expect(patterns.count == 3)

        // Weekend should have more missed doses than weekday
        let saturdayPattern = patterns.first { $0.dayOfWeek == "Saturday" }
        let mondayPattern = patterns.first { $0.dayOfWeek == "Monday" }

        #expect(saturdayPattern?.missedCount ?? 0 > mondayPattern?.missedCount ?? 0)
    }
}
