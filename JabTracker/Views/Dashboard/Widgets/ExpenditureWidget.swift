//
//  ExpenditureWidget.swift
//  JabTracker
//
//  Standard widget showing TDEE expenditure with line chart visualization.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import Charts
import SwiftData
import SwiftUI

/// Mock data for expenditure widget - used for previews
struct ExpenditureWidgetData {
    struct DataPoint: Identifiable {
        let id = UUID()
        let day: Int
        let value: Double
    }

    let dataPoints: [DataPoint]
    let currentTdee: Int

    static let mock = ExpenditureWidgetData(
        dataPoints: [
            DataPoint(day: 0, value: 2340),
            DataPoint(day: 1, value: 2355),
            DataPoint(day: 2, value: 2360),
            DataPoint(day: 3, value: 2350),
            DataPoint(day: 4, value: 2345),
            DataPoint(day: 5, value: 2355),
            DataPoint(day: 6, value: 2350),
        ],
        currentTdee: 2350
    )
}

/// Standard widget displaying TDEE calorie expenditure.
struct ExpenditureWidget: View {
    @Environment(\.modelContext) private var modelContext

    /// ViewModel for live data - initialized lazily on first access
    @State private var viewModel: ExpenditureWidgetViewModel?

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
                visualizationSection
                valueSection
            }
        } onTap: {
            onTap?()
        }
        .redacted(reason: isLoading ? .placeholder : [])
        .accessibilityIdentifier("expenditure-widget")
        .task {
            await loadDataIfNeeded()
        }
    }

    // MARK: - Data Loading

    private func loadDataIfNeeded() async {
        guard !useMockData else { return }

        if viewModel == nil {
            viewModel = ExpenditureWidgetViewModel(context: modelContext)
        }
        await viewModel?.loadData()
    }

    // MARK: - Data Accessors

    private var dataPoints: [ExpenditureWidgetData.DataPoint] {
        if useMockData {
            return ExpenditureWidgetData.mock.dataPoints
        }
        return viewModel?.dailyValues.map { data in
            ExpenditureWidgetData.DataPoint(day: data.day, value: data.value)
        } ?? []
    }

    private var tdeeValue: Int {
        if useMockData {
            return ExpenditureWidgetData.mock.currentTdee
        }
        return Int(viewModel?.tdee ?? 0)
    }

    private var hasData: Bool {
        useMockData ? true : (viewModel?.hasData ?? false)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Expenditure")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            Text("Daily TDEE")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    /// Chart data points - ensures a flat line when values are stable (holding)
    /// When only 1 point or all values are the same, shows a flat line
    private var chartDataPoints: [ExpenditureWidgetData.DataPoint] {
        guard !dataPoints.isEmpty else { return [] }

        // Check if all values are effectively the same (within 1 kcal)
        let values = dataPoints.map { $0.value }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let isStable = (maxValue - minValue) < 2

        if dataPoints.count == 1 || isStable {
            // Show flat line at the current TDEE
            let flatValue = Double(tdeeValue)
            return [
                ExpenditureWidgetData.DataPoint(day: 0, value: flatValue),
                ExpenditureWidgetData.DataPoint(day: 6, value: flatValue),
            ]
        }
        return dataPoints
    }

    @ViewBuilder
    private var visualizationSection: some View {
        if hasData {
            Chart(chartDataPoints) { point in
                LineMark(
                    x: .value("Day", point.day),
                    y: .value("TDEE", point.value)
                )
                .foregroundStyle(DesignTokens.Colors.expenditure)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Day", point.day),
                    y: .value("TDEE", point.value)
                )
                .foregroundStyle(DesignTokens.Colors.expenditure)
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
                    Text("No TDEE data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
        }
    }

    private var valueSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if hasData {
                Text("\(tdeeValue)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("--")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                Text("kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - DashboardWidget Conformance

extension ExpenditureWidget: DashboardWidget {
    var id: String { "expenditure" }
    var title: String { "Expenditure" }
    var content: some View { body }
}

// MARK: - Preview

#Preview("With Mock Data") {
    VStack(spacing: 16) {
        ExpenditureWidget(useMockData: true)
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}

#Preview("Empty State") {
    VStack(spacing: 16) {
        ExpenditureWidget(useMockData: false)
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}
