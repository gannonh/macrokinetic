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

    @State private var viewModel: NutritionSummaryViewModel

    /// Get macro targets for the target date, considering per-day distribution
    private var baseMacroTargets: DailyMacros {
        user.macroTargetsForDate(targetDate)
    }

    // MARK: - Initialization

    init(user: User, mealLogService: MealLogService?, targetDate: Date = Date()) {
        self.user = user
        self.mealLogService = mealLogService
        self.targetDate = targetDate
        self._viewModel = State(
            initialValue: NutritionSummaryViewModel(
                mealLogService: mealLogService,
                calorieAdjustmentService: AppServices.shared.calorieAdjustmentService
            ))
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

                if viewModel.isLoading {
                    loadingSection
                } else if viewModel.loadError != nil {
                    errorSection
                } else {
                    macroRingsSection
                }
            }
        }
        .accessibilityIdentifier("nutrition-rings-card")
        .task(id: "\(mealLogService?.dataVersion.uuidString ?? "none")-\(targetDate.timeIntervalSince1970)") {
            await viewModel.loadData(for: targetDate)
            await viewModel.updateCalorieTarget(user: user, date: targetDate)
            viewModel.startEnergyObservation(user: user, date: targetDate)
        }
        .onChange(of: user.addBurnedCaloriesEnabled) { _, _ in
            viewModel.startEnergyObservation(user: user, date: targetDate)
        }
        .onChange(of: user.healthSyncEnabled) { _, _ in
            viewModel.startEnergyObservation(user: user, date: targetDate)
        }
        .onDisappear {
            viewModel.stopEnergyObservation()
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
        let targets = baseMacroTargets

        return HStack(spacing: 0) {
            macroRing(
                label: "Calories",
                consumed: viewModel.totals.calories,
                goal: viewModel.adjustedCalorieTarget,  // Use adjusted target from ViewModel
                color: DesignTokens.Colors.calories,
                unit: "kcal",
                isCalories: true
            )
            Spacer(minLength: 0)
            macroRing(
                label: "Protein",
                consumed: viewModel.totals.protein,
                goal: targets.proteinGrams,
                color: DesignTokens.Colors.protein,
                unit: "g"
            )
            Spacer(minLength: 0)
            macroRing(
                label: "Carbs",
                consumed: viewModel.totals.carbs,
                goal: targets.carbsGrams,
                color: DesignTokens.Colors.carbs,
                unit: "g"
            )
            Spacer(minLength: 0)
            macroRing(
                label: "Fat",
                consumed: viewModel.totals.fat,
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
        unit: String,
        isCalories: Bool = false
    ) -> some View {
        let progress = progressPercentage(consumed: consumed, goal: goal)
        let ringColor = progressColor(for: progress, baseColor: color)
        let isOver = consumed > goal && goal > 0

        VStack(spacing: 4) {
            // Macro name above ring
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            CircularProgressRing(
                progress: progress,
                label: label,
                valueText: "\(Int(consumed.rounded()))",
                color: ringColor,
                lineWidth: Constants.ringLineWidth,
                size: Constants.ringSize,
                showLabel: false
            )
            .padding(.vertical, 6)

            // Goal text below ring
            HStack(spacing: 2) {
                Text("\(Int(goal.rounded())) \(unit)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                // Visual Indicator for Burned Calories
                if isCalories && viewModel.activeEnergyBurned > 0 {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .accessibilityIdentifier("burned-calories-indicator")
                }
            }

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
