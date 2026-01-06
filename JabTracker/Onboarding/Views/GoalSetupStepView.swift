//
//  GoalSetupStepView.swift
//  JabTracker
//
//  Goal type selection step for onboarding.
//  Uses simplified selection from GoalType enum.
//

import SwiftUI

/// Goal type selection step for onboarding.
///
/// Presents SelectionCard options for weight loss, maintenance, and muscle gain.
/// Selection is bound to the OnboardingViewModel's selectedGoalType.
struct GoalSetupStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: OnboardingStep.goalSetup.title,
                subtitle: OnboardingStep.goalSetup.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(GoalType.allCases, id: \.self) { goalType in
                        SelectionCard(
                            title: goalType.displayName,
                            description: goalType.description,
                            icon: goalType.icon,
                            isSelected: viewModel.selectedGoalType == goalType
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedGoalType = goalType
                            }
                        }
                        .accessibilityIdentifier("onboarding-goal-\(goalType.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
        .accessibilityIdentifier("onboarding-goal-setup-step")
    }
}

// Preview requires a real AuthenticationManager instance which isn't available in previews
// Use the actual app flow for testing
