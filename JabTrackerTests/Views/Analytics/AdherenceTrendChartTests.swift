import Charts
import Foundation
import SwiftUI
import Testing

@testable import JabTracker

@MainActor
struct AdherenceTrendChartTests {

    // MARK: - Test Cases

    @Test("AdherenceTrendChart initializes with trend data")
    func testAdherenceTrendChartInitialization() throws {
        let trendData = [
            AdherenceTrendPoint(date: Date(), adherenceRate: 0.85, period: "Week 1"),
            AdherenceTrendPoint(date: Date().addingTimeInterval(-7 * 24 * 3600), adherenceRate: 0.92, period: "Week 2"),
        ]
        let chart = AdherenceTrendChart(trendData: trendData)

        // Expected: AdherenceTrendChart should store trend data
        #expect(chart.trendData.count == 2)
        #expect(chart.trendData[0].adherenceRate == 0.85)
        #expect(chart.trendData[1].adherenceRate == 0.92)
    }

    @Test("AdherenceTrendChart handles empty data gracefully")
    func testAdherenceTrendChartEmptyData() throws {
        let emptyData: [AdherenceTrendPoint] = []
        let chart = AdherenceTrendChart(trendData: emptyData)

        // Expected: AdherenceTrendChart should handle empty data without crashing
        #expect(chart.trendData.isEmpty)
    }

    @Test("AdherenceTrendChart supports time period configuration")
    func testTimePeriodConfiguration() throws {
        let trendData = [
            AdherenceTrendPoint(date: Date(), adherenceRate: 0.85, period: "Week 1")
        ]
        let chart = AdherenceTrendChart(trendData: trendData, timePeriod: .weekly)

        // Expected: AdherenceTrendChart should support time period settings
        #expect(chart.timePeriod == .weekly)
    }

    @Test("AdherenceTrendChart provides accessibility support")
    func testAccessibilitySupport() throws {
        let trendData = [
            AdherenceTrendPoint(date: Date(), adherenceRate: 0.85, period: "Week 1")
        ]
        let chart = AdherenceTrendChart(trendData: trendData)

        // Expected: AdherenceTrendChart should have accessibility identifier
        #expect(chart.accessibilityIdentifier == "adherence-trend-chart")
    }

    @Test("AdherenceTrendChart calculates trend direction")
    func testTrendDirectionCalculation() throws {
        let improvingTrendData = [
            AdherenceTrendPoint(date: Date().addingTimeInterval(-7 * 24 * 3600), adherenceRate: 0.70, period: "Week 1"),
            AdherenceTrendPoint(date: Date(), adherenceRate: 0.85, period: "Week 2"),
        ]
        let chart = AdherenceTrendChart(trendData: improvingTrendData)

        // Expected: AdherenceTrendChart should calculate improving trend
        #expect(chart.trendDirection == .improving)
    }

    @Test("AdherenceTrendChart calculates declining trend")
    func testDecliningTrendCalculation() throws {
        let decliningTrendData = [
            AdherenceTrendPoint(date: Date().addingTimeInterval(-7 * 24 * 3600), adherenceRate: 0.90, period: "Week 1"),
            AdherenceTrendPoint(date: Date(), adherenceRate: 0.75, period: "Week 2"),
        ]
        let chart = AdherenceTrendChart(trendData: decliningTrendData)

        // Expected: AdherenceTrendChart should calculate declining trend
        #expect(chart.trendDirection == .declining)
    }

    @Test("AdherenceTrendChart calculates stable trend")
    func testStableTrendCalculation() throws {
        let stableTrendData = [
            AdherenceTrendPoint(date: Date().addingTimeInterval(-7 * 24 * 3600), adherenceRate: 0.85, period: "Week 1"),
            AdherenceTrendPoint(date: Date(), adherenceRate: 0.86, period: "Week 2"),
        ]
        let chart = AdherenceTrendChart(trendData: stableTrendData)

        // Expected: AdherenceTrendChart should calculate stable trend (within 5% difference)
        #expect(chart.trendDirection == .stable)
    }

    @Test("AdherenceTrendChart handles single data point")
    func testSingleDataPointTrend() throws {
        let singlePointData = [
            AdherenceTrendPoint(date: Date(), adherenceRate: 0.85, period: "Week 1")
        ]
        let chart = AdherenceTrendChart(trendData: singlePointData)

        // Expected: AdherenceTrendChart should handle single data point as stable
        #expect(chart.trendDirection == .stable)
    }
}
