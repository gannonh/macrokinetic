//
//  OnboardingView.swift
//  JabTracker
//
//  Main view for the v0.6.0 onboarding flow.
//  Uses the new simplified step structure with placeholder views.
//

import SwiftUI

/// Main onboarding view that orchestrates the onboarding flow.
///
/// This view maintains the same init signature as the legacy version for
/// JabTrackerApp.swift compatibility. The internal implementation uses
/// the new @Observable OnboardingViewModel.
struct OnboardingView: View {
    @Binding var isPresented: Bool
    let authManager: AuthenticationManager

    @State private var viewModel: OnboardingViewModel?

    // MARK: - Init (API compatibility with JabTrackerApp.swift)

    init(isPresented: Binding<Bool>, authManager: AuthenticationManager) {
        self._isPresented = isPresented
        self.authManager = authManager
    }

    var body: some View {
        NavigationStack {
            if let viewModel {
                VStack(spacing: 0) {
                    // Progress indicator (reusing existing component)
                    OnboardingProgressIndicator(
                        currentStep: viewModel.currentStepIndex + 1,
                        totalSteps: viewModel.totalSteps
                    )
                    .padding(.top, 16)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "Step \(viewModel.currentStepIndex + 1) of \(viewModel.totalSteps)"
                    )

                    // Step content area
                    Group {
                        stepContent(for: viewModel.currentStep, viewModel: viewModel)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )

                    // Navigation buttons
                    HStack {
                        if viewModel.currentStepIndex > 0 {
                            SecondaryButton(title: "Back") {
                                withAnimation(.spring()) {
                                    viewModel.moveToPreviousStep()
                                }
                            }
                            .accessibilityIdentifier("onboarding-back-button")
                        }

                        Spacer()

                        if viewModel.isLastStep {
                            PrimaryButton(
                                title: viewModel.isLoading ? "Setting Up..." : "Get Started"
                            ) {
                                Task {
                                    await completeOnboarding(viewModel: viewModel)
                                }
                            }
                            .disabled(viewModel.isLoading || !viewModel.canProceedToNext)
                            .accessibilityIdentifier("onboarding-complete-button")
                        } else {
                            PrimaryButton(title: "Continue") {
                                withAnimation(.spring()) {
                                    viewModel.moveToNextStep()
                                }
                            }
                            .disabled(!viewModel.canProceedToNext)
                            .accessibilityIdentifier("onboarding-continue-button")
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .background(DesignTokens.Colors.background)
                .navigationBarHidden(true)
                .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                    Button("OK") {
                        viewModel.errorMessage = nil
                    }
                } message: {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                    }
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = OnboardingViewModel(
                    dataController: DataController.shared,
                    authManager: authManager
                )
            }
        }
        .interactiveDismissDisabled()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-view")
    }

    // MARK: - Step Content Routing

    @ViewBuilder
    private func stepContent(for step: OnboardingStep, viewModel: OnboardingViewModel) -> some View {
        switch step {
        case .welcome:
            PlaceholderStepView(step: .welcome)
        case .uspShowcase:
            PlaceholderStepView(step: .uspShowcase)
        case .goalSetup:
            PlaceholderStepView(step: .goalSetup)
        case .programSetup:
            PlaceholderStepView(step: .programSetup)
        case .healthKit:
            PlaceholderStepView(step: .healthKit)
        case .faceID:
            PlaceholderStepView(step: .faceID)
        case .notifications:
            PlaceholderStepView(step: .notifications)
        case .completion:
            PlaceholderStepView(step: .completion)
        }
    }

    // MARK: - Completion Handler

    private func completeOnboarding(viewModel: OnboardingViewModel) async {
        let result = await viewModel.completeOnboarding()

        switch result {
        case .success:
            withAnimation(.spring()) {
                isPresented = false
            }
        case .alreadyCompleted:
            // Error message already set by viewModel
            break
        case .failed:
            // Error message already set by viewModel
            break
        }
    }
}

// MARK: - Placeholder Step View

/// Placeholder view for onboarding steps.
/// Will be replaced with actual step views in Phases 26-29.
private struct PlaceholderStepView: View {
    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: iconName(for: step))
                .font(.system(size: 64))
                .foregroundColor(DesignTokens.Colors.primary)
                .accessibilityHidden(true)

            Text(step.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(step.subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("Coming in Phase \(phaseNumber(for: step))")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)

            Spacer()
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("placeholder-step-\(step.rawValue)")
    }

    private func iconName(for step: OnboardingStep) -> String {
        switch step {
        case .welcome:
            return "hand.wave"
        case .uspShowcase:
            return "star.fill"
        case .goalSetup:
            return "target"
        case .programSetup:
            return "list.bullet.clipboard"
        case .healthKit:
            return "heart.fill"
        case .faceID:
            return "faceid"
        case .notifications:
            return "bell.fill"
        case .completion:
            return "checkmark.circle.fill"
        }
    }

    private func phaseNumber(for step: OnboardingStep) -> Int {
        switch step {
        case .welcome, .uspShowcase:
            return 26
        case .goalSetup, .programSetup:
            return 27
        case .healthKit, .faceID, .notifications:
            return 28
        case .completion:
            return 29
        }
    }
}
