//
//  GoalWizard+Steps.swift
//  JabTracker
//
//  Step views for GoalWizard - extracted to reduce file length.
//

import SwiftUI

// MARK: - Goal Type Selection Step

/// Goal type selection step
struct GoalTypeSelectionView: View {
    @Binding var selection: GoalType?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: GoalWizardStep.goalType.title,
                subtitle: GoalWizardStep.goalType.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(GoalType.allCases, id: \.self) { goalType in
                        SelectionCard(
                            title: goalType.displayName,
                            description: goalType.description,
                            icon: goalType.icon,
                            isSelected: selection == goalType
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = goalType
                            }
                        }
                        .accessibilityIdentifier("goal-wizard-goalType-\(goalType.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Target Weight Step

/// Target weight and rate configuration step
struct TargetWeightStepView: View {
    @Bindable var viewModel: GoalWizardViewModel

    // State for weight picker sheet
    @State private var showingWeightPicker = false
    @State private var weightWhole: Int = 150
    @State private var weightDecimal: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: GoalWizardStep.targetWeight.title,
                subtitle: GoalWizardStep.targetWeight.subtitle
            )

            ScrollView {
                VStack(spacing: 24) {
                    currentWeightSection
                    if viewModel.goalType != .maintenance {
                        targetWeightSection
                        weeklyRateSection
                        projectedResultsCard
                    } else {
                        maintenanceCard
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .sheet(isPresented: $showingWeightPicker) {
            weightPickerSheet
        }
    }

    private var currentWeightSection: some View {
        Button {
            // Initialize picker values before showing sheet
            let (whole, decimal) = WeightPickerView.pickerValues(
                from: viewModel.currentWeightDisplay.rounded(toPlaces: 1)
            )
            weightWhole = whole
            weightDecimal = decimal
            showingWeightPicker = true
        } label: {
            HStack {
                Text("Current Weight")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Text(formattedCurrentWeight)
                    .font(.headline)
                    .foregroundColor(.blue)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("goal-wizard-current-weight-row")
    }

    private var formattedCurrentWeight: String {
        let format = viewModel.usesMetricWeight ? "%.1f %@" : "%.0f %@"
        return String(format: format, viewModel.currentWeightDisplay.rounded(toPlaces: 1), viewModel.weightUnitLabel)
    }

    private var weightPickerSheet: some View {
        NavigationStack {
            Form {
                WeightPickerView(
                    weightWhole: $weightWhole,
                    weightDecimal: $weightDecimal,
                    unit: viewModel.weightUnitLabel
                )
            }
            .navigationTitle("Current Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingWeightPicker = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let pickerWeight = Double(weightWhole) + Double(weightDecimal) / 10.0
                        viewModel.currentWeightDisplay = pickerWeight
                        showingWeightPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var weightFormat: String {
        viewModel.usesMetricWeight ? "%.1f %@" : "%.0f %@"
    }

    private var targetWeightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Target Weight")
                    .font(.headline)
                Spacer()
                Text(String(format: weightFormat, viewModel.targetWeightDisplay, viewModel.weightUnitLabel))
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            Slider(
                value: $viewModel.targetWeightDisplay,
                in: targetWeightRangeDisplay,
                step: viewModel.usesMetricWeight ? 0.5 : 1.0
            )
            .tint(.blue)
            .accessibilityIdentifier("goal-wizard-target-weight-slider")

            HStack {
                Text(String(format: "%.0f %@", targetWeightRangeDisplay.lowerBound, viewModel.weightUnitLabel))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.0f %@", targetWeightRangeDisplay.upperBound, viewModel.weightUnitLabel))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }

    private var targetWeightRangeDisplay: ClosedRange<Double> {
        let kgToLbs = 2.20462
        let multiplier = viewModel.usesMetricWeight ? 1.0 : kgToLbs
        // Minimum step size for the slider
        let minStep = viewModel.usesMetricWeight ? 0.5 : 1.0

        func roundMin(_ value: Double) -> Double {
            viewModel.usesMetricWeight ? (value * 2).rounded(.up) / 2 : value.rounded(.up)
        }
        func roundMax(_ value: Double) -> Double {
            viewModel.usesMetricWeight ? (value * 2).rounded(.down) / 2 : value.rounded(.down)
        }

        switch viewModel.goalType {
        case .weightLoss:
            let minWeight = roundMin(max(40, viewModel.currentWeightKg * 0.7) * multiplier)
            let maxWeight = roundMax((viewModel.currentWeightKg - 0.5) * multiplier)
            // Ensure range has at least one step of width to prevent Slider crash
            let safeMax = max(minWeight + minStep, maxWeight)
            return minWeight...safeMax
        case .muscleGain:
            let minWeight = roundMin((viewModel.currentWeightKg + 0.5) * multiplier)
            let maxWeight = roundMax(viewModel.currentWeightKg * 1.3 * multiplier)
            // Ensure range has at least one step of width to prevent Slider crash
            let safeMax = max(minWeight + minStep, maxWeight)
            return minWeight...safeMax
        case .maintenance, .none:
            let weight = viewModel.currentWeightKg * multiplier
            return weight...weight
        }
    }

    private var weeklyRateSection: some View {
        let minRate = viewModel.usesMetricWeight ? 0.25 : 0.5
        let maxRate = viewModel.usesMetricWeight ? 1.0 : 2.0
        let stepRate = viewModel.usesMetricWeight ? 0.25 : 0.5

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Rate")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f %@/week", viewModel.weeklyRateDisplay, viewModel.weightUnitLabel))
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            Slider(
                value: $viewModel.weeklyRateDisplay,
                in: minRate...maxRate,
                step: stepRate
            )
            .tint(.blue)
            .accessibilityIdentifier("goal-wizard-rate-slider")

            HStack {
                VStack(alignment: .leading) {
                    Text(String(format: "%.1f %@", minRate, viewModel.weightUnitLabel))
                        .font(.caption)
                    Text("Gradual")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(String(format: "%.1f %@", maxRate, viewModel.weightUnitLabel))
                        .font(.caption)
                    Text("Aggressive")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }

    private var projectedResultsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Projected Results")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 24) {
                resultItem(
                    title: "Change",
                    value: String(
                        format: viewModel.usesMetricWeight ? "%@%.1f %@" : "%@%.0f %@",
                        viewModel.totalWeightChangeDisplay > 0 ? "+" : "",
                        viewModel.totalWeightChangeDisplay,
                        viewModel.weightUnitLabel
                    )
                )
                resultItem(
                    title: "Duration",
                    value: viewModel.durationDisplay
                )
                if let endDate = viewModel.projectedEndDate {
                    resultItem(
                        title: "Target Date",
                        value: endDate.formatted(.dateTime.month(.abbreviated).day())
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }

    private var maintenanceCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "equal.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("Maintain Your Weight")
                .font(.headline)

            Text("Your goal is to maintain your current weight. We'll help you find the right calorie balance.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }

    private func resultItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(.blue)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Goal Summary Step

/// Goal summary step
struct GoalSummaryStepView: View {
    let viewModel: GoalWizardViewModel

    private var weightFormat: String {
        viewModel.usesMetricWeight ? "%.1f %@" : "%.0f %@"
    }

    private var changeFormat: String {
        viewModel.usesMetricWeight ? "%@%.1f %@" : "%@%.0f %@"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: GoalWizardStep.summary.title,
                subtitle: GoalWizardStep.summary.subtitle
            )

            ScrollView {
                VStack(spacing: 16) {
                    SummaryRow(label: "Goal Type", value: viewModel.goalType?.displayName ?? "—")
                    SummaryRow(
                        label: "Current Weight",
                        value: String(format: weightFormat, viewModel.currentWeightDisplay, viewModel.weightUnitLabel)
                    )

                    if viewModel.goalType != .maintenance {
                        SummaryRow(
                            label: "Target Weight",
                            value: String(
                                format: weightFormat, viewModel.targetWeightDisplay, viewModel.weightUnitLabel)
                        )
                        SummaryRow(
                            label: "Weekly Rate",
                            value: String(
                                format: "%.1f %@/week",
                                viewModel.weeklyRateDisplay,
                                viewModel.weightUnitLabel
                            )
                        )
                        SummaryRow(
                            label: "Total Change",
                            value: String(
                                format: changeFormat,
                                viewModel.totalWeightChangeDisplay > 0 ? "+" : "",
                                viewModel.totalWeightChangeDisplay,
                                viewModel.weightUnitLabel
                            )
                        )
                        SummaryRow(label: "Duration", value: viewModel.durationDisplay)

                        if let endDate = viewModel.projectedEndDate {
                            SummaryRow(
                                label: "Target Date",
                                value: endDate.formatted(.dateTime.month().day().year())
                            )
                        }
                    }

                    nextStepPreview
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var nextStepPreview: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.vertical, 8)

            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.blue)
                Text("Next: Build Your Program")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }

            Text("Choose your program style, diet preference, and more.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Note: StepHeader, SelectionCard, and SummaryRow are now shared components
// located in JabTracker/Design/ for reuse across wizards and onboarding
