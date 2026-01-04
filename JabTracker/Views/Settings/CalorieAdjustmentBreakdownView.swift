//
//  CalorieAdjustmentBreakdownView.swift
//  JabTracker
//
//  Displays breakdown of calorie adjustments (burned, rollover, predictive).
//

import SwiftUI

struct CalorieAdjustmentBreakdownView: View {
    let breakdown: CalorieAdjustmentBreakdown
    let baseTarget: Double

    var body: some View {
        // Show breakdown only when there are adjustments
        if breakdown.totalAdjustment > 0 {
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Calorie Adjustments")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                // Base target row
                HStack {
                    Text("Base Target")
                    Spacer()
                    Text("\(Int(baseTarget)) kcal")
                }
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)

                // Burned calories row (if > 0)
                if breakdown.burnedCalories > 0 {
                    HStack {
                        Label("Burned", systemImage: "flame.fill")
                            .foregroundColor(.orange)
                        Spacer()
                        Text("+\(Int(breakdown.burnedCalories)) kcal")
                            .foregroundColor(.green)
                    }
                    .font(DesignTokens.Typography.body)
                }

                // Rollover row (if > 0)
                if breakdown.rolloverCalories > 0 {
                    HStack {
                        Label("Rollover", systemImage: "arrow.forward.circle.fill")
                            .foregroundColor(.blue)
                        Spacer()
                        Text("+\(Int(breakdown.rolloverCalories)) kcal")
                            .foregroundColor(.green)
                    }
                    .font(DesignTokens.Typography.body)
                }

                // Predictive row (if > 0)
                if breakdown.predictiveCalories > 0 {
                    HStack {
                        Label("Predictive", systemImage: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.purple)
                        Spacer()
                        Text("+\(Int(breakdown.predictiveCalories)) kcal")
                            .foregroundColor(.green)
                    }
                    .font(DesignTokens.Typography.body)
                }

                Divider()

                // Total row
                HStack {
                    Text("Today's Target")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(Int(baseTarget + breakdown.totalAdjustment)) kcal")
                        .fontWeight(.semibold)
                }
                .font(DesignTokens.Typography.body)
            }
            .padding()
            .background(DesignTokens.Colors.cardBackground)
            .cornerRadius(DesignTokens.CornerRadius.card)
            .accessibilityIdentifier("calorie-adjustment-breakdown")
        }
    }
}

#Preview("With All Adjustments") {
    CalorieAdjustmentBreakdownView(
        breakdown: CalorieAdjustmentBreakdown(
            burnedCalories: 250,
            rolloverCalories: 150,
            predictiveCalories: 100
        ),
        baseTarget: 2000
    )
    .padding()
}

#Preview("Burned Only") {
    CalorieAdjustmentBreakdownView(
        breakdown: CalorieAdjustmentBreakdown(
            burnedCalories: 350,
            rolloverCalories: 0,
            predictiveCalories: 0
        ),
        baseTarget: 2000
    )
    .padding()
}

#Preview("No Adjustments") {
    CalorieAdjustmentBreakdownView(
        breakdown: CalorieAdjustmentBreakdown(
            burnedCalories: 0,
            rolloverCalories: 0,
            predictiveCalories: 0
        ),
        baseTarget: 2000
    )
    .padding()
}
