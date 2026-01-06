//
//  ProgramSetupStepView.swift
//  JabTracker
//
//  Program style selection step for onboarding.
//  Uses simplified selection from ProgramStyle enum.
//

import SwiftUI

/// Program style selection step for onboarding.
///
/// Presents SelectionCard options for coached, collaborative, and manual program styles.
/// Selection is bound to the OnboardingViewModel's selectedProgramStyle.
struct ProgramSetupStepView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: OnboardingStep.programSetup.title,
                subtitle: OnboardingStep.programSetup.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ProgramStyle.allCases, id: \.self) { style in
                        SelectionCard(
                            title: style.displayName,
                            description: style.description,
                            icon: style.icon,
                            isSelected: viewModel.selectedProgramStyle == style
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedProgramStyle = style
                            }
                        }
                        .accessibilityIdentifier("onboarding-program-\(style.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
        .accessibilityIdentifier("onboarding-program-setup-step")
    }
}

// Preview requires a real AuthenticationManager instance which isn't available in previews
// Use the actual app flow for testing
