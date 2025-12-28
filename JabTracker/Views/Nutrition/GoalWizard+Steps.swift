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
            GoalStepHeader(
                title: GoalWizardStep.goalType.title,
                subtitle: GoalWizardStep.goalType.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(GoalType.allCases, id: \.self) { goalType in
                        GoalSelectionCard(
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GoalStepHeader(
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
    }

    private var currentWeightSection: some View {
        HStack {
            Text("Current Weight")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 4) {
                TextField(
                    "",
                    value: $viewModel.currentWeightDisplay,
                    format: .number.precision(.fractionLength(1))
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .font(.headline)
                .accessibilityIdentifier("goal-wizard-current-weight-input")

                Text(viewModel.weightUnitLabel)
                    .font(.headline)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
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
            let safeMax = max(minWeight, maxWeight)
            return minWeight...safeMax
        case .muscleGain:
            let minWeight = roundMin((viewModel.currentWeightKg + 0.5) * multiplier)
            let maxWeight = roundMax(viewModel.currentWeightKg * 1.3 * multiplier)
            let safeMax = max(minWeight, maxWeight)
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
            GoalStepHeader(
                title: GoalWizardStep.summary.title,
                subtitle: GoalWizardStep.summary.subtitle
            )

            ScrollView {
                VStack(spacing: 16) {
                    GoalSummaryRow(label: "Goal Type", value: viewModel.goalType?.displayName ?? "—")
                    GoalSummaryRow(
                        label: "Current Weight",
                        value: String(format: weightFormat, viewModel.currentWeightDisplay, viewModel.weightUnitLabel)
                    )

                    if viewModel.goalType != .maintenance {
                        GoalSummaryRow(
                            label: "Target Weight",
                            value: String(
                                format: weightFormat, viewModel.targetWeightDisplay, viewModel.weightUnitLabel)
                        )
                        GoalSummaryRow(
                            label: "Weekly Rate",
                            value: String(
                                format: "%.1f %@/week",
                                viewModel.weeklyRateDisplay,
                                viewModel.weightUnitLabel
                            )
                        )
                        GoalSummaryRow(
                            label: "Total Change",
                            value: String(
                                format: changeFormat,
                                viewModel.totalWeightChangeDisplay > 0 ? "+" : "",
                                viewModel.totalWeightChangeDisplay,
                                viewModel.weightUnitLabel
                            )
                        )
                        GoalSummaryRow(label: "Duration", value: viewModel.durationDisplay)

                        if let endDate = viewModel.projectedEndDate {
                            GoalSummaryRow(
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

// MARK: - Reusable Step Header

struct GoalStepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
}

// MARK: - Selection Card

/// Selection card for wizard options
struct GoalSelectionCard: View {
    let title: String
    let description: String
    var icon: String?
    var detail: String?
    let isSelected: Bool
    var showWarning: Bool = false
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                if let icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .blue : .secondary)
                        .frame(width: 32)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if showWarning {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let detail {
                        Text(detail)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(description)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Summary Row

struct GoalSummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
    }
}
