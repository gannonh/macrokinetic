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
                        // Back button (only after first step)
                        if viewModel.currentStepIndex > 0 {
                            SecondaryButton(title: "Back") {
                                withAnimation(.spring()) {
                                    viewModel.moveToPreviousStep()
                                }
                            }
                            .accessibilityIdentifier("onboarding-back-button")

                            Spacer()
                        }

                        // Continue or Get Started button (centered when alone)
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

                        // Spacer after Continue when Back is visible (for symmetry)
                        if viewModel.currentStepIndex > 0 {
                            Spacer()
                                .frame(width: 0)  // Invisible spacer for HStack balance
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
            WelcomeStepView()
        case .uspShowcase:
            USPShowcaseStepView()
        case .goalSetup:
            GoalSetupStepView(viewModel: viewModel)
        case .programSetup:
            ProgramSetupStepView(viewModel: viewModel)
        default:
            PlaceholderStepView(step: step)
        }
    }

    // MARK: - Completion Handler

    private func completeOnboarding(viewModel: OnboardingViewModel) async {
        let result = await viewModel.completeOnboarding()

        switch result {
        case .success, .alreadyCompleted:
            // Dismiss onboarding (already completed is also a success case)
            withAnimation(.spring()) {
                isPresented = false
            }
        case .failed:
            // Error message already set by viewModel
            break
        }
    }
}
