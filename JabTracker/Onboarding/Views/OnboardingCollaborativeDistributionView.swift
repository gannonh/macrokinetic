//
//  OnboardingCollaborativeDistributionView.swift
//  JabTracker
//
//  Collaborative distribution editor for onboarding flow.
//  Allows per-day calorie customization with lock and auto-adjust.
//

import SwiftUI

/// Collaborative distribution step view for onboarding
/// Allows users to customize per-day calories with lock and auto-adjust
struct OnboardingCollaborativeDistributionView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isCaloriesInputFocused: Bool

    /// Body weight in pounds for protein calculation
    private var bodyWeightLb: Double {
        viewModel.goalViewModel.currentWeightKg * 2.205
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Compact header
            VStack(alignment: .leading, spacing: 4) {
                Text(OnboardingStep.collaborativeDistribution.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(OnboardingStep.collaborativeDistribution.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            ScrollView {
                VStack(spacing: 12) {
                    weeklyGridSection
                    daySelectorSection
                    selectedDayHeaderSection
                    caloriesInputSection
                    proteinSliderSection
                    carbFatRatioSection
                }
                .padding(.horizontal, 16)
            }
        }
        .focused($isCaloriesInputFocused)
        .onAppear {
            viewModel.initializeCollaborativeDays()
        }
        .accessibilityIdentifier("onboarding-collaborative-distribution-step")
    }

    // MARK: - Weekly Grid Section

    private var weeklyGridSection: some View {
        VStack(spacing: 0) {
            // Day headers
            HStack(spacing: 2) {
                Text("")
                    .frame(width: 28)

                ForEach(Weekday.mondayFirst, id: \.rawValue) { weekday in
                    Text(weekday.shortLetter)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(
                            viewModel.collaborativeSelectedDay == weekday.rawValue
                                ? DesignTokens.Colors.accent : .secondary
                        )
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            // Calorie row
            weeklyMacroRow(
                label: "Cals",
                values: Weekday.mondayFirst.map { weekday in
                    Int(viewModel.collaborativeDays[weekday.rawValue]?.calories ?? 0)
                },
                unit: "",
                color: DesignTokens.Colors.calories,
                isPill: true
            )

            // Protein row
            weeklyMacroRow(
                label: "P",
                values: Weekday.mondayFirst.map { weekday in
                    let config = viewModel.collaborativeDays[weekday.rawValue]
                    let proteinGrams = (config?.proteinGramsPerLb ?? 0) * bodyWeightLb
                    return Int(proteinGrams)
                },
                unit: "g",
                color: DesignTokens.Colors.protein,
                isPill: false
            )

            // Fat row
            weeklyMacroRow(
                label: "F",
                values: Weekday.mondayFirst.map { weekday in
                    guard let config = viewModel.collaborativeDays[weekday.rawValue] else { return 0 }
                    let proteinGrams = config.proteinGramsPerLb * bodyWeightLb
                    let proteinCalories = MacroCalorieConstants.proteinCalories(proteinGrams)
                    let remainingCalories = config.calories - proteinCalories
                    let fatCalories = remainingCalories * (1 - config.carbFatRatio)
                    return Int(fatCalories / MacroCalorieConstants.fatCaloriesPerGram)
                },
                unit: "g",
                color: DesignTokens.Colors.fat,
                isPill: false
            )

            // Carbs row
            weeklyMacroRow(
                label: "C",
                values: Weekday.mondayFirst.map { weekday in
                    guard let config = viewModel.collaborativeDays[weekday.rawValue] else { return 0 }
                    let proteinGrams = config.proteinGramsPerLb * bodyWeightLb
                    let proteinCalories = MacroCalorieConstants.proteinCalories(proteinGrams)
                    let remainingCalories = config.calories - proteinCalories
                    let carbCalories = remainingCalories * config.carbFatRatio
                    return Int(carbCalories / MacroCalorieConstants.carbsCaloriesPerGram)
                },
                unit: "g",
                color: DesignTokens.Colors.carbs,
                isPill: false
            )

            // Weekly total
            let weeklyTotal = WeeklyConstants.validWeekdayRange.reduce(0.0) { sum, day in
                sum + (viewModel.collaborativeDays[day]?.calories ?? 0)
            }
            HStack {
                Spacer()
                Text("Weekly: \(Int(weeklyTotal)) cal")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .compactCardBackground()
    }

    private func weeklyMacroRow(
        label: String,
        values: [Int],
        unit: String,
        color: Color,
        isPill: Bool
    ) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 28, alignment: .leading)

            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                let valueText = "\(value)\(unit)"

                ZStack {
                    if isPill {
                        Capsule()
                            .fill(color.opacity(0.15))
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.15))
                    }

                    Text(valueText)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(color)
                }
                .frame(maxWidth: .infinity)
                .frame(height: isPill ? 22 : 24)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Day Selector Section

    private var daySelectorSection: some View {
        HStack(spacing: 6) {
            ForEach(Weekday.mondayFirst, id: \.rawValue) { weekday in
                let isSelected = viewModel.collaborativeSelectedDay == weekday.rawValue
                let isLocked = viewModel.collaborativeDays[weekday.rawValue]?.isLocked ?? false

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.collaborativeSelectedDay = weekday.rawValue
                    }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Text(weekday.shortLetter)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(
                                        isSelected ? DesignTokens.Colors.accent : DesignTokens.Colors.tertiaryBackground
                                    )
                            )
                            .foregroundColor(isSelected ? .white : .primary)

                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.orange)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .compactCardBackground()
    }

    // MARK: - Selected Day Header Section

    private var selectedDayHeaderSection: some View {
        HStack {
            Text(selectedDayName)
                .font(.headline)

            Spacer()

            // Reset button
            Button {
                viewModel.resetCollaborativeDaysToEven()
            } label: {
                Label("Reset All", systemImage: "arrow.counterclockwise")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            // Lock toggle
            Button {
                toggleLock()
            } label: {
                Image(systemName: isSelectedDayLocked ? "lock.fill" : "lock.open")
                    .foregroundColor(isSelectedDayLocked ? .orange : .secondary)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .compactCardBackground()
    }

    private var selectedDayName: String {
        Weekday(rawValue: viewModel.collaborativeSelectedDay)?.fullName ?? "Day"
    }

    private var isSelectedDayLocked: Bool {
        viewModel.collaborativeDays[viewModel.collaborativeSelectedDay]?.isLocked ?? false
    }

    private func toggleLock() {
        guard var config = viewModel.collaborativeDays[viewModel.collaborativeSelectedDay] else { return }
        config.isLocked.toggle()
        viewModel.collaborativeDays[viewModel.collaborativeSelectedDay] = config
    }

    // MARK: - Calories Input Section

    private var caloriesInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calories")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                TextField("Calories", value: caloriesBinding, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 100)

                Text("kcal")
                    .foregroundColor(.secondary)

                Spacer()

                // Quick adjust buttons
                Button("-100") {
                    adjustCalories(by: -100)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("+100") {
                    adjustCalories(by: 100)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .compactCardBackground()
    }

    private var caloriesBinding: Binding<Double> {
        Binding(
            get: { viewModel.collaborativeDays[viewModel.collaborativeSelectedDay]?.calories ?? 0 },
            set: { newValue in
                viewModel.adjustCollaborativeCalories(forDay: viewModel.collaborativeSelectedDay, newCalories: newValue)
            }
        )
    }

    private func adjustCalories(by amount: Double) {
        let current = viewModel.collaborativeDays[viewModel.collaborativeSelectedDay]?.calories ?? 0
        viewModel.adjustCollaborativeCalories(forDay: viewModel.collaborativeSelectedDay, newCalories: current + amount)
    }

    // MARK: - Protein Slider Section

    private var proteinSliderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Protein")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(String(format: "%.1f g/lb (\(Int(currentProteinGrams))g)", currentProteinGramsPerLb))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Slider(value: proteinBinding, in: 0.5...1.5, step: 0.1)
                .tint(DesignTokens.Colors.protein)
        }
        .compactCardBackground()
    }

    private var currentProteinGramsPerLb: Double {
        viewModel.collaborativeDays[viewModel.collaborativeSelectedDay]?.proteinGramsPerLb ?? 0.8
    }

    private var currentProteinGrams: Double {
        currentProteinGramsPerLb * bodyWeightLb
    }

    private var proteinBinding: Binding<Double> {
        Binding(
            get: { currentProteinGramsPerLb },
            set: { newValue in
                guard var config = viewModel.collaborativeDays[viewModel.collaborativeSelectedDay] else { return }
                config.proteinGramsPerLb = newValue
                viewModel.collaborativeDays[viewModel.collaborativeSelectedDay] = config
            }
        )
    }

    // MARK: - Carb/Fat Ratio Section

    private var carbFatRatioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Carb / Fat Ratio")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(currentCarbFatRatio * 100))% carbs / \(Int((1 - currentCarbFatRatio) * 100))% fat")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Slider(value: carbFatRatioBinding, in: 0...1, step: 0.1)
                .tint(DesignTokens.Colors.carbs)

            HStack {
                Text("More Fat")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("More Carbs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .compactCardBackground()
    }

    private var currentCarbFatRatio: Double {
        viewModel.collaborativeDays[viewModel.collaborativeSelectedDay]?.carbFatRatio ?? 0.5
    }

    private var carbFatRatioBinding: Binding<Double> {
        Binding(
            get: { currentCarbFatRatio },
            set: { newValue in
                guard var config = viewModel.collaborativeDays[viewModel.collaborativeSelectedDay] else { return }
                config.carbFatRatio = newValue
                viewModel.collaborativeDays[viewModel.collaborativeSelectedDay] = config
            }
        )
    }
}

// MARK: - Preview

#Preview("Onboarding Collaborative Distribution") {
    OnboardingCollaborativeDistributionView(
        viewModel: OnboardingViewModel(
            dataController: DataController.preview,
            authManager: AuthenticationManager()
        )
    )
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}
