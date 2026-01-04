//
//  MacroSummarySwipeCard.swift
//  JabTracker
//
//  Compact card showing macro progress with optional adjustments info button.
//

import SwiftUI

/// Compact macro summary card with info button for adjustments
struct MacroSummarySwipeCard: View {
    // MARK: - Properties

    /// Daily consumed totals
    let consumedCalories: Double
    let consumedProtein: Double
    let consumedCarbs: Double
    let consumedFat: Double

    /// Macro targets
    let targetCalories: Double
    let targetProtein: Double
    let targetCarbs: Double
    let targetFat: Double

    /// Adjusted calorie target (includes burned/rollover/predictive)
    let adjustedCalorieTarget: Double

    /// Optional breakdown for adjustments page (nil = hide adjustments button)
    let adjustmentBreakdown: CalorieAdjustmentBreakdown?

    // MARK: - State

    @State private var showingAdjustmentsSheet = false

    // MARK: - Computed Properties

    /// Whether there are active adjustments to show
    private var hasAdjustments: Bool {
        guard let breakdown = adjustmentBreakdown else { return false }
        return breakdown.totalAdjustment > 0
    }

    /// Base calorie target (before adjustments)
    private var baseCalorieTarget: Double {
        guard let breakdown = adjustmentBreakdown else { return targetCalories }
        return adjustedCalorieTarget - breakdown.totalAdjustment
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Macro summary
            MacroSummaryConsumedPage(
                consumedCalories: consumedCalories,
                consumedProtein: consumedProtein,
                consumedFat: consumedFat,
                consumedCarbs: consumedCarbs,
                targetCalories: adjustedCalorieTarget,
                targetProtein: targetProtein,
                targetFat: targetFat,
                targetCarbs: targetCarbs
            )

            // Info button (only show when adjustments exist)
            if hasAdjustments {
                Button {
                    showingAdjustmentsSheet = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View calorie adjustments")
                .accessibilityIdentifier("adjustments-info-button")
            }
        }
        .padding()
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("macro-summary-card")
        .sheet(isPresented: $showingAdjustmentsSheet) {
            if let breakdown = adjustmentBreakdown {
                AdjustmentsSheet(
                    baseTarget: baseCalorieTarget,
                    breakdown: breakdown
                )
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Adjustments Sheet

/// Compact sheet showing calorie adjustment breakdown
private struct AdjustmentsSheet: View {
    let baseTarget: Double
    let breakdown: CalorieAdjustmentBreakdown

    @Environment(\.dismiss) private var dismiss

    private var adjustedTarget: Double {
        baseTarget + breakdown.totalAdjustment
    }

    var body: some View {
        VStack(spacing: 16) {
            // Close button
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Breakdown
            VStack(spacing: 8) {
                adjustmentRow(label: "Base Target", value: baseTarget, color: .secondary)

                if breakdown.burnedCalories > 0 {
                    adjustmentRow(
                        label: "Burned",
                        value: breakdown.burnedCalories,
                        color: .orange,
                        icon: "flame.fill",
                        isAddition: true
                    )
                }

                if breakdown.rolloverCalories > 0 {
                    adjustmentRow(
                        label: "Rollover",
                        value: breakdown.rolloverCalories,
                        color: .blue,
                        icon: "arrow.forward.circle.fill",
                        isAddition: true
                    )
                }

                if breakdown.predictiveCalories > 0 {
                    adjustmentRow(
                        label: "Predictive",
                        value: breakdown.predictiveCalories,
                        color: .purple,
                        icon: "chart.line.uptrend.xyaxis",
                        isAddition: true
                    )
                }

                Divider()

                HStack {
                    Text("Today's Target")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(Int(adjustedTarget)) kcal")
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.Colors.calories)
                }
                .font(.subheadline)
            }

            Spacer()
        }
        .padding()
    }

    private func adjustmentRow(
        label: String,
        value: Double,
        color: Color,
        icon: String? = nil,
        isAddition: Bool = false
    ) -> some View {
        HStack {
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            Text(label)
                .foregroundColor(color)
            Spacer()
            Text(isAddition ? "+\(Int(value)) kcal" : "\(Int(value)) kcal")
                .foregroundColor(isAddition ? .green : .primary)
        }
        .font(.subheadline)
    }
}

// MARK: - Preview

#Preview("With Adjustments") {
    MacroSummarySwipeCard(
        consumedCalories: 1450,
        consumedProtein: 89,
        consumedCarbs: 136,
        consumedFat: 51,
        targetCalories: 2000,
        targetProtein: 125,
        targetCarbs: 200,
        targetFat: 65,
        adjustedCalorieTarget: 2350,
        adjustmentBreakdown: CalorieAdjustmentBreakdown(
            burnedCalories: 250,
            rolloverCalories: 100,
            predictiveCalories: 0
        )
    )
    .padding()
}

#Preview("No Adjustments") {
    MacroSummarySwipeCard(
        consumedCalories: 1450,
        consumedProtein: 89,
        consumedCarbs: 136,
        consumedFat: 51,
        targetCalories: 2000,
        targetProtein: 125,
        targetCarbs: 200,
        targetFat: 65,
        adjustedCalorieTarget: 2000,
        adjustmentBreakdown: nil
    )
    .padding()
}

#Preview("Over Target") {
    MacroSummarySwipeCard(
        consumedCalories: 2200,
        consumedProtein: 140,
        consumedCarbs: 220,
        consumedFat: 80,
        targetCalories: 2000,
        targetProtein: 125,
        targetCarbs: 200,
        targetFat: 65,
        adjustedCalorieTarget: 2000,
        adjustmentBreakdown: nil
    )
    .padding()
}
