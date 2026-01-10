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
struct StandardWidgetGroup<W1: View, W2: View, W3: View, W4: View>: View {
    let title: String
    let widget1: W1
    let widget2: W2
    let widget3: W3
    let widget4: W4

    init(
        title: String,
        @ViewBuilder content: () -> TupleView<(W1, W2, W3, W4)>
    ) {
        self.title = title
        let views = content().value
        self.widget1 = views.0
        self.widget2 = views.1
        self.widget3 = views.2
        self.widget4 = views.3
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(DesignTokens.Typography.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    widget1.frame(minWidth: 0, maxWidth: .infinity)
                    widget2.frame(minWidth: 0, maxWidth: .infinity)
                }
                HStack(spacing: 12) {
                    widget3.frame(minWidth: 0, maxWidth: .infinity)
                    widget4.frame(minWidth: 0, maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity)
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
