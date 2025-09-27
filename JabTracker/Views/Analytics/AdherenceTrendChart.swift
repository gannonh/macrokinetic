//
//  AdherenceTrendChart.swift
//  JabTracker
//
//  Interactive adherence trend chart displaying medication adherence patterns over time.
//

import Charts
import SwiftUI

/// Interactive adherence trend chart showing adherence rates over time periods
struct AdherenceTrendChart: View {

    // MARK: - Properties

    /// Array of trend data points to display
    let trendData: [AdherenceTrendPoint]

    /// Time period configuration for the chart
    let timePeriod: ChartTimePeriod

    /// Accessibility identifier for testing
    let accessibilityIdentifier: String

    // MARK: - Computed Properties

    /// Calculated trend direction based on data points
    var trendDirection: TrendDirection {
        calculateTrendDirection()
    }

    /// Chart data sorted by date for proper display
    var sortedTrendData: [AdherenceTrendPoint] {
        trendData.sorted { $0.date < $1.date }
    }

    // MARK: - Initialization

    init(
        trendData: [AdherenceTrendPoint],
        timePeriod: ChartTimePeriod = .weekly,
        accessibilityIdentifier: String = "adherence-trend-chart"
    ) {
        self.trendData = trendData
        self.timePeriod = timePeriod
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chart Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Adherence Trend")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(.primary)

                    if !trendData.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: trendDirection.systemImageName)
                                .foregroundColor(trendDirectionColor)
                                .font(.caption)

                            Text(trendDirection.displayName)
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(trendDirectionColor)
                        }
                    }
                }

                Spacer()

                Text(timePeriod.displayName)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
            }

            // Chart Content
            if trendData.isEmpty {
                EmptyTrendChartView()
            } else {
                Chart {
                    ForEach(sortedTrendData) { point in
                        LineMark(
                            x: .value("Period", point.date),
                            y: .value("Adherence Rate", point.adherenceRate)
                        )
                        .foregroundStyle(DesignTokens.Colors.primary)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                        PointMark(
                            x: .value("Period", point.date),
                            y: .value("Adherence Rate", point.adherenceRate)
                        )
                        .foregroundStyle(DesignTokens.Colors.primary)
                        .symbolSize(60)
                    }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let rate = value.as(Double.self) {
                                Text("\(Int(rate * 100))%")
                                    .font(DesignTokens.Typography.caption)
                            }
                        }
                        AxisGridLine()
                        AxisTick()
                    }
                }
                .frame(height: 120)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.secondaryBackground)
        )
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityLabel(
            trendData.isEmpty
                ? "Adherence trend chart - No trend data available"
                : "Adherence trend chart showing \(trendDirection.displayName.lowercased()) pattern"
        )
        .accessibilityValue(
            trendData.isEmpty ? "Current trend: no data" : "Current trend: \(trendDirection.displayName)")
    }

    // MARK: - Private Properties

    private var trendDirectionColor: Color {
        switch trendDirection {
        case .improving:
            return DesignTokens.Colors.success
        case .declining:
            return DesignTokens.Colors.danger
        case .stable:
            return DesignTokens.Colors.warning
        }
    }

    // MARK: - Private Methods

    private func calculateTrendDirection() -> TrendDirection {
        guard trendData.count >= 2 else { return .stable }

        let sortedData = sortedTrendData
        let firstRate = sortedData.first?.adherenceRate ?? 0
        let lastRate = sortedData.last?.adherenceRate ?? 0

        let difference = lastRate - firstRate
        let threshold = 0.05  // 5% threshold for stable vs improving/declining

        if difference > threshold {
            return .improving
        } else if difference < -threshold {
            return .declining
        } else {
            return .stable
        }
    }
}

// MARK: - Empty State View

private struct EmptyTrendChartView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No trend data available")
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)

            Text("Start tracking doses to see your adherence trends")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Chart with trending data
        AdherenceTrendChart(
            trendData: [
                AdherenceTrendPoint(
                    date: Date().addingTimeInterval(-14 * 24 * 3600), adherenceRate: 0.75, period: "Week 1"),
                AdherenceTrendPoint(
                    date: Date().addingTimeInterval(-7 * 24 * 3600), adherenceRate: 0.85, period: "Week 2"),
                AdherenceTrendPoint(date: Date(), adherenceRate: 0.92, period: "Week 3"),
            ]
        )

        // Empty chart
        AdherenceTrendChart(trendData: [])
    }
    .padding()
}
