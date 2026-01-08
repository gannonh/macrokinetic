//
//  CompletionStepView.swift
//  JabTracker
//
//  Completion step view for onboarding - celebrates finish and shows summary.
//

import SwiftUI

// MARK: - Completion Step View

/// Final step of onboarding showing success animation, personalized summary, and next steps.
struct CompletionStepView: View {
    let viewModel: OnboardingViewModel

    @State private var checkmarkScale: CGFloat = 0.1
    @State private var checkmarkOpacity: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                summaryCard
                nextStepsCard
            }
            .padding()
        }
        .background(DesignTokens.Colors.groupedBackground)
        .onAppear {
            animateCheckmark()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-completion-step")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green.gradient)
                .scaleEffect(checkmarkScale)
                .opacity(checkmarkOpacity)

            Text(OnboardingStep.completion.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(OnboardingStep.completion.subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
        .accessibilityIdentifier("completion-header")
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Program")
                .font(.headline)

            VStack(spacing: 12) {
                CompletionSummaryRow(
                    icon: "target",
                    label: "Goal",
                    value: goalSummaryText
                )

                CompletionSummaryRow(
                    icon: "gearshape.2.fill",
                    label: "Program Style",
                    value: viewModel.programStyle?.displayName ?? "Coached"
                )

                CompletionSummaryRow(
                    icon: "flame.fill",
                    label: "Daily Calories",
                    value: caloriesSummaryText
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card))
        .accessibilityIdentifier("completion-summary-card")
    }

    // MARK: - Next Steps Card

    private var nextStepsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Here's how to get started")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                NextStepRow(number: 1, text: "Log your first meal to start tracking")
                NextStepRow(number: 2, text: "Check in weekly to adjust your targets")
                NextStepRow(number: 3, text: "Enable notifications for reminders")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card))
        .accessibilityIdentifier("completion-next-steps-card")
    }

    // MARK: - Computed Properties

    private var goalSummaryText: String {
        guard let goalType = viewModel.goalViewModel.goalType else {
            return "Not set"
        }

        switch goalType {
        case .weightLoss:
            return "Weight Loss"
        case .maintenance:
            return "Maintain Weight"
        case .muscleGain:
            return "Muscle Gain"
        }
    }

    private var caloriesSummaryText: String {
        let calories = Int(viewModel.calculatedCalories)
        if calories > 0 {
            return "\(calories) kcal"
        }
        return "Calculating..."
    }

    // MARK: - Animation

    private func animateCheckmark() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            checkmarkScale = 1.0
            checkmarkOpacity = 1.0
        }
    }
}

// MARK: - Completion Summary Row

/// A row showing an icon, label, and value for the completion summary card.
private struct CompletionSummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(DesignTokens.Colors.accent)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Next Step Row

/// A numbered row for the next steps guidance.
private struct NextStepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(DesignTokens.Colors.accent))
                .accessibilityHidden(true)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(text)")
    }
}
