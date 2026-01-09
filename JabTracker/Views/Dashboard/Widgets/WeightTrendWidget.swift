//
//  WeightTrendWidget.swift
//  JabTracker
//
//  Standard widget showing 7-day weight trend with sparkline chart.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import Charts
import SwiftUI

/// Mock data for weight trend widget - will be replaced with live data in Phase 34
struct WeightTrendWidgetData {
    struct DataPoint: Identifiable {
        let id = UUID()
        let day: Int  // 0-6 representing days
        let weight: Double
    }

    let dataPoints: [DataPoint]
    let latestWeight: Double
    let unit: String

    static let mock = WeightTrendWidgetData(
        dataPoints: [
            DataPoint(day: 0, weight: 185.2),
            DataPoint(day: 1, weight: 184.8),
            DataPoint(day: 2, weight: 184.5),
            DataPoint(day: 3, weight: 184.9),
            DataPoint(day: 4, weight: 184.2),
            DataPoint(day: 5, weight: 183.9),
            DataPoint(day: 6, weight: 183.7),
        ],
        latestWeight: 183.7,
        unit: "lbs"
    )
}

/// Standard widget displaying 7-day weight trend with sparkline chart.
struct WeightTrendWidget: View {
    let data: WeightTrendWidgetData
    var onTap: (() -> Void)?

    init(data: WeightTrendWidgetData = .mock, onTap: (() -> Void)? = nil) {
        self.data = data
        self.onTap = onTap
    }

    var body: some View {
        WidgetCard(title: nil) {
            VStack(alignment: .leading, spacing: 8) {
                headerSection
                chartSection
                valueSection
            }
        } onTap: {
            onTap?()
        }
        .accessibilityIdentifier("weight-trend-widget")
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Weight Trend")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            Text("Last 7 Days")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var chartSection: some View {
        Chart(data.dataPoints) { point in
            LineMark(
                x: .value("Day", point.day),
                y: .value("Weight", point.weight)
            )
            .foregroundStyle(DesignTokens.Colors.weight)
            .lineStyle(StrokeStyle(lineWidth: 2))

            PointMark(
                x: .value("Day", point.day),
                y: .value("Weight", point.weight)
            )
            .foregroundStyle(DesignTokens.Colors.weight)
            .symbolSize(20)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: .automatic(includesZero: false))
        .frame(height: 30)
    }

    private var valueSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(String(format: "%.1f", data.latestWeight))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(data.unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - DashboardWidget Conformance

extension WeightTrendWidget: DashboardWidget {
    var id: String { "weight-trend" }
    var title: String { "Weight Trend" }
    var content: some View { body }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        WeightTrendWidget()
        WeightTrendWidget(
            data: WeightTrendWidgetData(
                dataPoints: [
                    WeightTrendWidgetData.DataPoint(day: 0, weight: 180.0),
                    WeightTrendWidgetData.DataPoint(day: 1, weight: 180.5),
                    WeightTrendWidgetData.DataPoint(day: 2, weight: 181.0),
                    WeightTrendWidgetData.DataPoint(day: 3, weight: 180.8),
                    WeightTrendWidgetData.DataPoint(day: 4, weight: 181.2),
                    WeightTrendWidgetData.DataPoint(day: 5, weight: 181.5),
                    WeightTrendWidgetData.DataPoint(day: 6, weight: 182.0),
                ],
                latestWeight: 182.0,
                unit: "lbs"
            ))
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}
