//
//  StandardWidgetGroup.swift
//  JabTracker
//
//  2x2 grid container for standard dashboard widgets.
//  Displays Insights & Analytics widgets in a grid layout.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import SwiftUI

/// 2x2 grid container for standard dashboard widgets.
///
/// Features:
/// - Section header using DesignTokens typography
/// - Flexible grid layout with 12pt spacing
/// - Widgets provide their own card styling
///
/// Example usage:
/// ```swift
/// StandardWidgetGroup(title: "Insights & Analytics") {
///     ExpenditureWidget()
///     WeightTrendWidget()
///     EnergyBalanceWidget()
///     GoalProgressWidget()
/// }
/// ```
struct StandardWidgetGroup<Content: View>: View {
    let title: String
    let content: Content

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(DesignTokens.Typography.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: columns, spacing: 12) {
                content
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("standard-widget-group-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            StandardWidgetGroup(title: "Insights & Analytics") {
                previewWidget(title: "Expenditure", value: "2,450", unit: "kcal")
                previewWidget(title: "Weight Trend", value: "−2.5", unit: "lbs")
                previewWidget(title: "Energy Balance", value: "+150", unit: "kcal")
                previewWidget(title: "Goal Progress", value: "68", unit: "%")
            }

            StandardWidgetGroup(title: "Quick Stats") {
                previewWidget(title: "Steps", value: "8,432", unit: "")
                previewWidget(title: "Water", value: "6", unit: "cups")
            }
        }
        .padding()
    }
    .background(DesignTokens.Colors.groupedBackground)
}

@ViewBuilder
private func previewWidget(title: String, value: String, unit: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .font(.caption)
            .foregroundColor(.secondary)

        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            if !unit.isEmpty {
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .cardStyle()
}
