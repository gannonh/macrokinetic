//
//  NutritionSummaryCard.swift
//  JabTracker
//
//  Dashboard card showing daily nutrition progress.
//

import SwiftUI
import os

/// Dashboard card displaying daily macro progress vs goals
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
                    // Macro progress bars
                    VStack(spacing: 10) {
                        macroProgressRow(
                            label: "Calories",
                            current: totals.calories,
                            goal: user.dailyCalorieGoal,
                            color: .orange,
                            unit: "kcal"
                        )

                        macroProgressRow(
                            label: "Protein",
                            current: totals.protein,
                            goal: user.dailyProteinGoal,
                            color: .red,
                            unit: "g"
                        )

                        macroProgressRow(
                            label: "Carbs",
                            current: totals.carbs,
                            goal: user.dailyCarbGoal,
                            color: .blue,
                            unit: "g"
                        )

                        macroProgressRow(
                            label: "Fat",
                            current: totals.fat,
                            goal: user.dailyFatGoal,
                            color: .yellow,
                            unit: "g"
                        )
                    }
                }
            }
        }
        .accessibilityIdentifier("nutrition-summary-card")
        .task {
            await loadTotals()
        }
    }

    private func macroProgressRow(
        label: String,
        current: Double,
        goal: Double,
        color: Color,
        unit: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(current))/\(Int(goal)) \(unit)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(
                            width: progressWidth(current: current, goal: goal, maxWidth: geometry.size.width), height: 8
                        )
                }
            }
            .frame(height: 8)
        }
        .accessibilityIdentifier("macro-progress-\(label.lowercased())")
    }

    private func progressWidth(current: Double, goal: Double, maxWidth: CGFloat) -> CGFloat {
        guard goal > 0 else { return 0 }
        let progress = min(current / goal, 1.0)
        return maxWidth * progress
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
