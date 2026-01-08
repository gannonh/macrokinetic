//
//  SetupConfirmationStepView.swift
//  JabTracker
//
//  Combined goal and program confirmation step showing calculated targets.
//  Matches the "Program Ready" sheet design with weekly macro grid.
//

import SwiftUI

// MARK: - Setup Confirmation Step View

/// Combined goal and program confirmation step showing calculated targets
/// Matches the "Program Ready" sheet design (Image 12) with weekly macro grid
struct SetupConfirmationStepView: View {
    let viewModel: OnboardingViewModel

    private static let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    /// Maps display index (0=Mon, 6=Sun) to Calendar weekday (2=Mon, 1=Sun)
    private static let displayIndexToWeekday = [2, 3, 4, 5, 6, 7, 1]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                weeklyMacroGrid

                // Show Collaborative info card if that mode is selected
                if viewModel.programStyle == .collaborative {
                    collaborativeInfoCard
                }

                calculationExplanation
            }
            .padding()
        }
        .background(DesignTokens.Colors.groupedBackground)
    }

    // MARK: - Collaborative Info Card

    private var collaborativeInfoCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "slider.horizontal.3")
                .font(.body)
                .foregroundColor(DesignTokens.Colors.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Collaborative Mode")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("You can customize calories and macros for each day in Strategy settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DesignTokens.Colors.accent.opacity(0.1))
        )
        .accessibilityIdentifier("collaborative-info-card")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green.gradient)

            Text("Your macro program is ready")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Personalized targets based on your goals and profile")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
        .accessibilityIdentifier("setup-confirmation-header")
    }

    // MARK: - Weekly Macro Grid

    private var weeklyMacroGrid: some View {
        VStack(spacing: 0) {
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

            // Calorie row (pill style) - uses per-day values for shifted distribution
            calorieRow

            // Protein row
            macroRow(
                label: "P",
                value: Int(viewModel.calculatedProtein),
                unit: "g",
                color: DesignTokens.Colors.protein,
                isPill: false
            )

            // Fat row
            macroRow(
                label: "F",
                value: Int(viewModel.calculatedFat),
                unit: "g",
                color: DesignTokens.Colors.fat,
                isPill: false
            )

            // Carbs row
            macroRow(
                label: "C",
                value: Int(viewModel.calculatedCarbs),
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
        value: Int,
        unit: String,
        color: Color,
        isPill: Bool
    ) -> some View {
        let macroName = macroDisplayName(for: label)
        let valueText = "\(value)\(unit)"

        return HStack(spacing: 4) {
            // Label column
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)

            // 7 days with same value (for now - can be per-day later)
            ForEach(0..<7, id: \.self) { index in
                let dayName = Self.dayLabels[index]

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

    /// Calorie row with per-day values for shifted distribution
    private var calorieRow: some View {
        let color = DesignTokens.Colors.calories

        return HStack(spacing: 4) {
            Text("Cals")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)

            ForEach(0..<7, id: \.self) { index in
                let weekday = Self.displayIndexToWeekday[index]
                let dayCalories = viewModel.calculatedDailyCalories[weekday] ?? viewModel.calculatedCalories
                let valueText = "\(Int(dayCalories))"
                let dayName = Self.dayLabels[index]

                ZStack {
                    Capsule()
                        .fill(color.opacity(0.15))

                    Text(valueText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(color)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .accessibilityLabel("\(dayName): \(Int(dayCalories)) calories")
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Calculation Explanation

    private var calculationExplanation: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How was your program designed?")
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                explanationStep(
                    number: 1,
                    title: "Estimated Expenditure (TDEE)",
                    value: formatCalories(viewModel.calculatedCalories + weeklyDeficit)
                )

                explanationStep(
                    number: 2,
                    title: "Daily Target",
                    value: formatCalories(viewModel.calculatedCalories),
                    detail: weeklyPaceDetail
                )

                explanationStep(
                    number: 3,
                    title: "Macro Split",
                    value: viewModel.dietPreference?.displayName ?? "Balanced",
                    detail: macroSplitDetail
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
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

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.footnote)
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

    private var weeklyDeficit: Double {
        // Estimate TDEE from daily target + weekly pace
        let pace = viewModel.goalViewModel.weeklyRateKg
        // 7700 kcal per kg of body weight
        return abs(pace) * 7700 / 7
    }

    private var weeklyPaceDetail: String {
        let pace = viewModel.goalViewModel.weeklyRateKg
        let unit = viewModel.goalViewModel.weightUnitLabel
        let displayPace = viewModel.goalViewModel.usesMetricWeight ? pace : pace * 2.205

        if viewModel.goalViewModel.goalType == .weightLoss {
            return String(format: "%.1f %@/week deficit", abs(displayPace), unit)
        } else if viewModel.goalViewModel.goalType == .muscleGain {
            return String(format: "%.1f %@/week surplus", displayPace, unit)
        } else {
            return "Maintenance mode"
        }
    }

    private var macroSplitDetail: String {
        let protein = Int(viewModel.calculatedProtein)
        let fat = Int(viewModel.calculatedFat)
        let carbs = Int(viewModel.calculatedCarbs)
        return "P: \(protein)g / F: \(fat)g / C: \(carbs)g"
    }

    private func formatCalories(_ value: Double) -> String {
        if value <= 0 {
            return "Calculating..."
        }
        return String(format: "%.0f kcal", value)
    }
}
