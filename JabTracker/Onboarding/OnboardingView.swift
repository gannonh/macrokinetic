//
//  OnboardingView.swift
//  JabTracker
//
//  Main view for the v0.6.0 onboarding flow.
//  Integrates existing GoalWizard and ProgramWizard for goal/program setup.
//

import SwiftUI

/// Delay between chained sheet presentations (matches StrategyView pattern)
private enum OnboardingSheetConstants {
    static let chainedSheetDelay: TimeInterval = 0.35
}

/// Main onboarding view that orchestrates the onboarding flow.
///
/// This view maintains the same init signature as the legacy version for
/// JabTrackerApp.swift compatibility. The internal implementation uses
/// the new @Observable OnboardingViewModel.
struct OnboardingView: View {
    @Binding var isPresented: Bool
    let authManager: AuthenticationManager

    @State private var viewModel: OnboardingViewModel?

    // MARK: - Wizard Sheet State

    /// Whether the GoalWizard sheet is presented
    @State private var showingGoalWizard = false

    /// Whether the ProgramWizard sheet is presented
    @State private var showingProgramWizard = false

    /// Goal created by GoalWizard, used to chain to ProgramWizard
    @State private var createdGoal: NutritionGoal?

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

                    // Navigation buttons (hidden during goalProgram step - wizards have their own)
                    if viewModel.currentStep != .goalProgram {
                        navigationButtons(viewModel: viewModel)
                    }
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
                .sheet(isPresented: $showingGoalWizard) {
                    goalWizardSheet(viewModel: viewModel)
                }
                .sheet(isPresented: $showingProgramWizard) {
                    programWizardSheet(viewModel: viewModel)
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

    // MARK: - Navigation Buttons

    @ViewBuilder
    private func navigationButtons(viewModel: OnboardingViewModel) -> some View {
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

    // MARK: - Step Content Routing

    @ViewBuilder
    private func stepContent(for step: OnboardingStep, viewModel: OnboardingViewModel) -> some View {
        switch step {
        case .welcome:
            WelcomeStepView()
        case .uspShowcase:
            USPShowcaseStepView()
        case .healthKit:
            PlaceholderStepView(step: step)
        case .goalProgram:
            goalProgramStepContent(viewModel: viewModel)
        default:
            PlaceholderStepView(step: step)
        }
    }

    // MARK: - Goal/Program Step

    /// Content for the goalProgram step - auto-presents GoalWizard
    @ViewBuilder
    private func goalProgramStepContent(viewModel: OnboardingViewModel) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Show a loading/transition state while wizard sheets are presented
            Image(systemName: "target")
                .font(.system(size: 80))
                .foregroundStyle(DesignTokens.Colors.accent.gradient)
                .accessibilityHidden(true)

            Text("Setting Up Your Goals")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Let's configure your nutrition goal and program.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .onAppear {
            // Auto-present GoalWizard when this step is reached
            if !showingGoalWizard && !showingProgramWizard && createdGoal == nil {
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + OnboardingSheetConstants.chainedSheetDelay
                ) {
                    showingGoalWizard = true
                }
            }
        }
    }

    // MARK: - Wizard Sheets

    @ViewBuilder
    private func goalWizardSheet(viewModel: OnboardingViewModel) -> some View {
        if let user = authManager.currentUser {
            GoalWizard(user: user, existingGoal: nil, showIntro: false) { goal in
                createdGoal = goal
                showingGoalWizard = false
                // Chain to ProgramWizard after delay
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + OnboardingSheetConstants.chainedSheetDelay
                ) {
                    showingProgramWizard = true
                }
            }
            .interactiveDismissDisabled()  // Prevent dismissing during onboarding
        }
    }

    @ViewBuilder
    private func programWizardSheet(viewModel: OnboardingViewModel) -> some View {
        if let goal = createdGoal {
            ProgramWizard(goal: goal, existingProgram: nil) {
                showingProgramWizard = false
                // Mark goal/program setup complete and advance
                viewModel.markGoalProgramComplete()
                withAnimation(.spring()) {
                    viewModel.moveToNextStep()
                }
            }
            .interactiveDismissDisabled()  // Prevent dismissing during onboarding
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
