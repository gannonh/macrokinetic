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
    // MARK: - Properties

    let user: User
    let mealLogService: MealLogService?

    /// Date to display targets for (default: today)
    var targetDate: Date = Date()

    @State private var totals: DailyNutritionTotals = .zero
    @State private var isLoading = true
    @State private var loadError: Error?

    /// Get macro targets for the target date, considering per-day distribution
    private var macroTargets: DailyMacros {
        user.macroTargetsForDate(targetDate)
    }

    // MARK: - Constants

    private enum Constants {
        static let ringSize: CGFloat = 70
        static let ringLineWidth: CGFloat = 6
        /// Progress threshold for showing full-intensity color (85%)
        static let nearGoalThreshold: Double = 0.85
        /// Opacity for progress rings below nearGoalThreshold
        static let lowProgressOpacity: Double = 0.7
    }

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "NutritionSummaryCard"
    )

    // MARK: - Body

    var body: some View {
        DesignCard {
            VStack(alignment: .leading, spacing: 12) {
                headerSection

                if isLoading {
                    loadingSection
                } else if loadError != nil {
                    errorSection
                } else {
                    macroRingsSection
                }
            }
        }
        .accessibilityIdentifier("nutrition-rings-card")
        .task(id: "\(mealLogService?.dataVersion.uuidString ?? "none")-\(targetDate.timeIntervalSince1970)") {
            await loadTotals()
        }
    }

    // MARK: - View Sections

    private var headerSection: some View {
        HStack {
            Text("Today's Nutrition")
                .font(DesignTokens.Typography.headline)
            Spacer()
            Image(systemName: "fork.knife")
                .foregroundColor(DesignTokens.Colors.primary)
        }
        .accessibilityIdentifier("nutrition-card-header")
    }

    private var loadingSection: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
    }

    private var errorSection: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
            Text("Unable to load nutrition data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("nutrition-error-state")
    }

    private var macroRingsSection: some View {
        let targets = macroTargets

        return HStack(spacing: 16) {
            macroRing(
                label: "Calories",
                consumed: totals.calories,
                goal: targets.calories,
                color: DesignTokens.Colors.calories,
                unit: "kcal"
            )
            macroRing(
                label: "Protein",
                consumed: totals.protein,
                goal: targets.proteinGrams,
                color: DesignTokens.Colors.protein,
                unit: "g"
            )
            macroRing(
                label: "Carbs",
                consumed: totals.carbs,
                goal: targets.carbsGrams,
                color: DesignTokens.Colors.carbs,
                unit: "g"
            )
            macroRing(
                label: "Fat",
                consumed: totals.fat,
                goal: targets.fatGrams,
                color: DesignTokens.Colors.fat,
                unit: "g"
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Macro Ring View Builder

    @ViewBuilder
    private func macroRing(
        label: String,
        consumed: Double,
        goal: Double,
        color: Color,
        unit: String
    ) -> some View {
        let progress = progressPercentage(consumed: consumed, goal: goal)
        let ringColor = progressColor(for: progress, baseColor: color)
        let isOver = consumed > goal && goal > 0

        VStack(spacing: 4) {
            CircularProgressRing(
                progress: progress,
                label: label,
                valueText: "\(Int(consumed.rounded()))",
                color: ringColor,
                lineWidth: Constants.ringLineWidth,
                size: Constants.ringSize
            )

            // Goal text below ring
            Text("\(Int(goal.rounded())) \(unit)")
                .font(.caption2)
                .foregroundColor(.secondary)

            // Remaining/over text
            Text(remainingText(consumed: consumed, goal: goal))
                .font(.caption2)
                .foregroundColor(isOver ? color : .secondary)
                .accessibilityIdentifier("macro-remaining-\(label.lowercased())")
        }
    }

    // MARK: - Helper Functions

    private func progressPercentage(consumed: Double, goal: Double) -> Double {
        guard goal > 0 else { return 0 }
        return consumed / goal
    }

    private func progressColor(for progress: Double, baseColor: Color) -> Color {
        if progress >= Constants.nearGoalThreshold {
            return baseColor
        } else {
            return baseColor.opacity(Constants.lowProgressOpacity)
        }
    }

    private func remainingText(consumed: Double, goal: Double) -> String {
        guard goal > 0 else {
            return consumed > 0 ? "\(Int(consumed.rounded())) eaten" : "No goal"
        }
        let remaining = goal - consumed
        if remaining >= 0 {
            return "\(Int(remaining.rounded())) left"
        } else {
            return "+\(Int(abs(remaining).rounded())) over"
        }
    }

    @MainActor
    private func loadTotals() async {
        guard let service = mealLogService else {
            isLoading = false
            return
        }

        do {
            totals = try await service.getDailyTotals(for: targetDate)
            loadError = nil
        } catch {
            loadError = error
            Self.logger.error("Failed to load daily nutrition totals: \(error.localizedDescription)")
        }
        isLoading = false
    }
}

// MARK: - Preview

#Preview("With Data") {
    let user = User(
        dailyCalorieGoal: 2000,
        dailyProteinGoal: 150,
        dailyCarbGoal: 200,
        dailyFatGoal: 65
    )
    return NutritionSummaryCard(user: user, mealLogService: nil)
        .padding()
}

#Preview("Loading") {
    let user = User()
    return NutritionSummaryCard(user: user, mealLogService: nil)
        .padding()
}
