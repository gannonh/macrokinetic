//
//  WeightTrendWidget.swift
//  JabTracker
//
//  Standard widget showing 7-day weight trend with sparkline chart.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import Charts
import SwiftData
import SwiftUI

/// Mock data for weight trend widget - used for previews
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
    @Environment(\.modelContext) private var modelContext

    /// ViewModel for live data - initialized lazily on first access
    @State private var viewModel: WeightTrendWidgetViewModel?

    /// Whether to use mock data (for previews)
    private let useMockData: Bool

    var onTap: (() -> Void)?

    // MARK: - Initialization

    /// Initialize with live data (default for production)
    init(onTap: (() -> Void)? = nil) {
        self.useMockData = false
        self.onTap = onTap
    }

    /// Initialize with mock data flag (for previews)
    init(useMockData: Bool, onTap: (() -> Void)? = nil) {
        self.useMockData = useMockData
        self.onTap = onTap
    }

    /// Whether data is currently loading
    private var isLoading: Bool {
        viewModel?.isLoading ?? (!useMockData && viewModel == nil)
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
        .redacted(reason: isLoading ? .placeholder : [])
        .accessibilityIdentifier("weight-trend-widget")
        .task {
            await loadDataIfNeeded()
        }
    }

    // MARK: - Data Loading

    private func loadDataIfNeeded() async {
        guard !useMockData else { return }

        if viewModel == nil {
            let metricsService = AppServices.shared.metricsService ?? MetricsService(context: modelContext)
            viewModel = WeightTrendWidgetViewModel(metricsService: metricsService, context: modelContext)
        }
        await viewModel?.loadData()
    }

    // MARK: - Data Accessors

    private var dataPoints: [WeightTrendWidgetData.DataPoint] {
        if useMockData {
            return WeightTrendWidgetData.mock.dataPoints
        }
        return viewModel?.dataPoints.map { dataPoint in
            WeightTrendWidgetData.DataPoint(day: dataPoint.day, weight: dataPoint.weight)
        } ?? []
    }

    private var latestWeight: Double {
        useMockData ? WeightTrendWidgetData.mock.latestWeight : (viewModel?.latestWeight ?? 0)
    }

    private var unit: String {
        useMockData ? WeightTrendWidgetData.mock.unit : (viewModel?.unit ?? "lbs")
    }

    private var hasData: Bool {
        useMockData ? true : (viewModel?.hasData ?? false)
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

    @ViewBuilder
    private var chartSection: some View {
        if hasData {
            Chart(dataPoints) { point in
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
            .frame(maxWidth: .infinity)
            .frame(height: 30)
        } else {
            // Empty state placeholder
            Rectangle()
                .fill(DesignTokens.Colors.inactive.opacity(0.3))
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .overlay {
                    Text("No weight data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
        }
    }

    private var valueSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if hasData {
                Text(String(format: "%.1f", latestWeight))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("--")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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

#Preview("With Mock Data") {
    VStack(spacing: 16) {
        WeightTrendWidget(useMockData: true)
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}

#Preview("Empty State") {
    VStack(spacing: 16) {
        // Empty state would show when no weight entries exist
        WeightTrendWidget(useMockData: false)
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}
