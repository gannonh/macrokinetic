//
//  NutritionSummaryCard.swift
//  JabTracker
//
//  Dashboard card showing daily nutrition progress with circular progress rings.
//

import SwiftUI
import os

/// Dashboard card displaying daily macro progress vs goals using circular progress rings
struct NutritionSummaryCard: View {
    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "NutritionSummaryCard"
    )
    let user: User
    let mealLogService: MealLogService?

    @State private var totals: DailyNutritionTotals = .zero
    @State private var isLoading = true

    var body: some View {
        DesignCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("Today's Nutrition")
                        .font(DesignTokens.Typography.headline)
                    Spacer()
                    Image(systemName: "fork.knife")
                        .foregroundColor(DesignTokens.Colors.primary)
                }
                .accessibilityIdentifier("nutrition-card-header")

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    // Macro progress rings
                    HStack(spacing: 16) {
                        macroRing(
                            label: "Calories",
                            consumed: totals.calories,
                            goal: user.dailyCalorieGoal,
                            defaultColor: .orange,
                            unit: "kcal"
                        )
                        macroRing(
                            label: "Protein",
                            consumed: totals.protein,
                            goal: user.dailyProteinGoal,
                            defaultColor: .red,
                            unit: "g"
                        )
                        macroRing(
                            label: "Carbs",
                            consumed: totals.carbs,
                            goal: user.dailyCarbGoal,
                            defaultColor: .blue,
                            unit: "g"
                        )
                        macroRing(
                            label: "Fat",
                            consumed: totals.fat,
                            goal: user.dailyFatGoal,
                            defaultColor: .yellow,
                            unit: "g"
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityIdentifier("nutrition-rings-card")
        .task {
            await loadTotals()
        }
    }

    // MARK: - Macro Ring View Builder

    @ViewBuilder
    private func macroRing(
        label: String,
        consumed: Double,
        goal: Double,
        defaultColor: Color,
        unit: String
    ) -> some View {
        let progress = progressPercentage(consumed: consumed, goal: goal)
        let color = progressColor(for: progress, defaultColor: defaultColor)

        VStack(spacing: 4) {
            CircularProgressRing(
                progress: progress,
                label: label,
                valueText: "\(Int(consumed))",
                color: color,
                lineWidth: 6,
                size: 70
            )

            // Goal text below ring
            Text("\(Int(goal)) \(unit)")
                .font(.caption2)
                .foregroundColor(.secondary)

            // Remaining/over text
            Text(remainingText(consumed: consumed, goal: goal))
                .font(.caption2)
                .foregroundColor(progress > 1.0 ? .red : .secondary)
        }
    }

    // MARK: - Helper Functions

    private func progressPercentage(consumed: Double, goal: Double) -> Double {
        guard goal > 0 else { return 0 }
        return consumed / goal
    }

    private func progressColor(for progress: Double, defaultColor: Color) -> Color {
        if progress > 1.0 {
            return .red
        } else if progress >= 0.85 {
            return defaultColor
        } else {
            return defaultColor.opacity(0.7)
        }
    }

    private func remainingText(consumed: Double, goal: Double) -> String {
        let remaining = goal - consumed
        if remaining >= 0 {
            return "\(Int(remaining)) left"
        } else {
            return "+\(Int(abs(remaining))) over"
        }
    }

    private func loadTotals() async {
        guard let service = mealLogService else {
            isLoading = false
            return
        }

        do {
            totals = try await service.getDailyTotals(for: Date())
        } catch {
            Self.logger.error("Failed to load daily nutrition totals: \(error.localizedDescription)")
        }
        isLoading = false
    }
}
