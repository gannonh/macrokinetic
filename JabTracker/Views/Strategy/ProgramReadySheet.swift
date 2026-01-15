//
//  ProgramReadySheet.swift
//  JabTracker
//
//  Sheet shown after Coached program creation with calculated targets.
//  Displays weekly macro grid and explains how targets were derived.
//

import SwiftUI

// MARK: - Program Ready Sheet

/// Sheet shown after program creation with calculated targets
struct ProgramReadySheet: View {
    // MARK: - Properties

    let goal: NutritionGoal
    let program: NutritionProgram
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    weeklyMacroGrid
                    calculationExplanation
                    doneButton
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Program Ready")
            .navigationBarTitleDisplayMode(.inline)
        }
        .accessibilityIdentifier("program-ready-sheet")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(DesignTokens.Colors.success.gradient)

            Text("Your macro program is ready")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Personalized targets based on your goals and profile")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityIdentifier("program-ready-header")
    }

    // MARK: - Weekly Macro Grid

    private static let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    /// Map day labels to weekday numbers: M=2, T=3, W=4, T=5, F=6, S=7, S=1
    private static let weekdayNumbers = [2, 3, 4, 5, 6, 7, 1]

    /// Get macros for a specific weekday (1=Sun, 2=Mon, ..., 7=Sat)
    private func macrosForWeekday(_ weekday: Int) -> DailyMacros {
        // Create a date with the specified weekday for lookup
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = weekday
        let date = calendar.date(from: components) ?? Date()
        return goal.macroTargetsForDate(date)
    }

    private var weeklyMacroGrid: some View {
        // Get macros for each day of the week
        let dayMacros = Self.weekdayNumbers.map { macrosForWeekday($0) }

        return VStack(spacing: 0) {
            // Day headers
            HStack(spacing: 4) {
                Text("")
                    .frame(width: 30)

                ForEach(Array(Self.dayLabels.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)

            // Calorie row (pill style) with per-day values
            macroRow(
                label: "Cals",
                values: dayMacros.map { Int($0.calories) },
                unit: "",
                color: DesignTokens.Colors.calories,
                isPill: true
            )

            // Protein row
            macroRow(
                label: "P",
                values: dayMacros.map { Int($0.proteinGrams) },
                unit: "g",
                color: DesignTokens.Colors.protein,
                isPill: false
            )

            // Fat row
            macroRow(
                label: "F",
                values: dayMacros.map { Int($0.fatGrams) },
                unit: "g",
                color: DesignTokens.Colors.fat,
                isPill: false
            )

            // Carbs row
            macroRow(
                label: "C",
                values: dayMacros.map { Int($0.carbsGrams) },
                unit: "g",
                color: DesignTokens.Colors.carbs,
                isPill: false
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.Colors.cardBackground)
        )
        .accessibilityIdentifier("weekly-macro-grid")
    }

    private func macroRow(
        label: String,
        values: [Int],
        unit: String,
        color: Color,
        isPill: Bool
    ) -> some View {
        let macroName = macroDisplayName(for: label)

        return HStack(spacing: 4) {
            // Label column
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)

            // 7 days with individual values
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                let dayName = Self.dayLabels[index]
                let valueText = "\(value)\(unit)"

                ZStack {
                    if isPill {
                        Capsule()
                            .fill(color.opacity(0.15))
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color.opacity(0.15))
                    }

                    Text(valueText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(color)
                }
                .frame(maxWidth: .infinity)
                .frame(height: isPill ? 28 : 32)
                .accessibilityLabel("\(dayName): \(value) \(macroName)")
            }
        }
        .padding(.vertical, 4)
    }

    private func macroDisplayName(for label: String) -> String {
        switch label {
        case "Cals": return "calories"
        case "P": return "grams protein"
        case "F": return "grams fat"
        case "C": return "grams carbs"
        default: return label
        }
    }

    // MARK: - Calculation Explanation

    private var calculationExplanation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How was your program designed?")
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 10) {
                explanationStep(
                    number: 1,
                    title: "Estimated Expenditure (TDEE)",
                    value: formatCalories(goal.initialEstimatedTDEE ?? 0)
                )

                explanationStep(
                    number: 2,
                    title: "Daily Target",
                    value: formatCalories(goal.dailyCalorieTarget),
                    detail: weeklyPaceDetail
                )

                explanationStep(
                    number: 3,
                    title: "Macro Split",
                    value: program.diet.displayName,
                    detail: macroSplitDetail
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.Colors.cardBackground)
        )
        .accessibilityIdentifier("calculation-explanation")
    }

    private func explanationStep(
        number: Int,
        title: String,
        value: String,
        detail: String? = nil
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Number badge
            Text("\(number)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(DesignTokens.Colors.accent))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let detail = detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }

    private var weeklyPaceDetail: String {
        let pace = goal.weeklyWeightChangePaceKg
        if pace < 0 {
            return String(format: "%.1f kg/week deficit", abs(pace))
        } else if pace > 0 {
            return String(format: "%.1f kg/week surplus", pace)
        } else {
            return "Maintenance mode"
        }
    }

    private var macroSplitDetail: String {
        let protein = Int(goal.dailyProteinTargetGrams)
        let fat = Int(goal.dailyFatTargetGrams)
        let carbs = Int(goal.dailyCarbTargetGrams)
        return "P: \(protein)g / F: \(fat)g / C: \(carbs)g"
    }

    private func formatCalories(_ value: Double) -> String {
        if value <= 0 {
            return "Calculating..."
        }
        return String(format: "%.0f kcal", value)
    }

    // MARK: - Done Button

    private var doneButton: some View {
        PrimaryButton(title: "Done") {
            onDone()
            dismiss()
        }
        .accessibilityIdentifier("done-button")
    }
}

// MARK: - Preview

#Preview("Program Ready Sheet") {
    let goal = NutritionGoal(
        goalType: .weightLoss,
        targetWeightKg: 80.0,
        weeklyWeightChangePaceKg: -0.5,
        dailyCalorieTarget: 1850,
        dailyProteinTargetGrams: 150,
        dailyCarbTargetGrams: 185,
        dailyFatTargetGrams: 62
    )
    goal.initialEstimatedTDEE = 2200

    let program = NutritionProgram(style: .coached, diet: .balanced)

    return ProgramReadySheet(goal: goal, program: program) {}
}
