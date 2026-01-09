//
//  ExpenditureWidget.swift
//  JabTracker
//
//  Standard widget showing 7-day expenditure with bar visualization.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import SwiftUI

/// Mock data for expenditure widget - will be replaced with live data in Phase 34
struct ExpenditureWidgetData {
    let dailyValues: [Double]  // 7 days of expenditure values
    let averageKcal: Int

    static let mock = ExpenditureWidgetData(
        dailyValues: [1850, 2100, 1920, 1780, 2050, 1900, 1650],
        averageKcal: 1893
    )
}

/// Standard widget displaying 7-day calorie expenditure with mini bar chart.
struct ExpenditureWidget: View {
    let data: ExpenditureWidgetData
    var onTap: (() -> Void)?

    init(data: ExpenditureWidgetData = .mock, onTap: (() -> Void)? = nil) {
        self.data = data
        self.onTap = onTap
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
        .accessibilityIdentifier("expenditure-widget")
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
            Text("Last 7 Days")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var visualizationSection: some View {
        let maxValue = data.dailyValues.max() ?? 1
        let minValue = data.dailyValues.min() ?? 0
        let range = maxValue - minValue

        return HStack(spacing: 4) {
            ForEach(0..<data.dailyValues.count, id: \.self) { index in
                let value = data.dailyValues[index]
                let normalizedHeight = range > 0 ? (value - minValue) / range : 0.5
                let height = 6 + (normalizedHeight * 14)  // 6-20pt range

                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignTokens.Colors.expenditure)
                    .frame(width: 20, height: height)
            }
            Spacer()
        }
        .frame(height: 24)
    }

    private var valueSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(data.averageKcal)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text("kcal")
                .font(.caption)
                .foregroundColor(.secondary)
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

#Preview {
    VStack(spacing: 16) {
        ExpenditureWidget()
        ExpenditureWidget(
            data: ExpenditureWidgetData(
                dailyValues: [2200, 2100, 2300, 2150, 2000, 2250, 2100],
                averageKcal: 2157
            ))
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}
