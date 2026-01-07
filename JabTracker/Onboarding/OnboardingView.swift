//
//  OnboardingView.swift
//  JabTracker
//
//  Main view for the v0.6.0 onboarding flow.
//  Integrates goal and program configuration as native steps.
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
    @State private var isCalculatingTargets = false
    @State private var calculationError: String?

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

                    // Navigation buttons (hidden for steps with internal navigation)
                    if !stepHasInternalNavigation(viewModel.currentStep) {
                        navigationButtons(viewModel: viewModel)
                    }
                }
                .background(DesignTokens.Colors.groupedBackground)
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
                .alert("Calculation Error", isPresented: .constant(calculationError != nil)) {
                    Button("OK") {
                        calculationError = nil
                    }
                } message: {
                    if let error = calculationError {
                        Text(error)
                    }
                }
                .overlay {
                    if isCalculatingTargets {
                        CalculatingOverlayView()
                            .transition(.opacity)
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
                PrimaryButton(
                    title: isCalculatingTargets ? "Calculating..." : "Continue"
                ) {
                    Task {
                        await handleContinue(viewModel: viewModel)
                    }
                }
                .disabled(!viewModel.canProceedToNext || isCalculatingTargets)
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

    // MARK: - Continue Handler

    private func handleContinue(viewModel: OnboardingViewModel) async {
        // Determine if we're on the last step before setupConfirmation (need animation + calculation)
        let isLastConfigStep = isStepBeforeSetupConfirmation(viewModel.currentStep, viewModel: viewModel)

        if isLastConfigStep {
            // Show animation, calculate targets, then move to setupConfirmation
            await showCalculatingThenSetupConfirmation(viewModel: viewModel)
            return
        }

        withAnimation(.spring()) {
            viewModel.moveToNextStep()
        }
    }

    /// Determines if the current step is immediately before setupConfirmation
    private func isStepBeforeSetupConfirmation(_ step: OnboardingStep, viewModel: OnboardingViewModel) -> Bool {
        let steps = viewModel.availableSteps
        guard let currentIndex = steps.firstIndex(of: step),
            currentIndex + 1 < steps.count
        else {
            return false
        }
        return steps[currentIndex + 1] == .setupConfirmation
    }

    // MARK: - Step Navigation Helpers

    /// Returns true if the step has its own internal Enable/Skip buttons
    /// and should not show the standard Continue button.
    private func stepHasInternalNavigation(_ step: OnboardingStep) -> Bool {
        switch step {
        case .healthKit, .faceID, .notifications:
            return true
        default:
            return false
        }
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
            HealthKitStepView(
                onEnableHealthKit: {
                    await viewModel.enableHealthKitSync()
                },
                onContinue: {
                    Task {
                        // Configure goal ViewModel before entering goalType step
                        await viewModel.configureGoalViewModel()
                        withAnimation(.spring()) {
                            viewModel.moveToNextStep()
                        }
                    }
                }
            )
        case .goalType:
            GoalTypeSelectionView(selection: Bindable(viewModel.goalViewModel).goalType)
                .accessibilityIdentifier("onboarding-goalType-step")
        case .targetWeight:
            TargetWeightStepView(viewModel: viewModel.goalViewModel)
                .accessibilityIdentifier("onboarding-targetWeight-step")
        case .profileCompletion:
            OnboardingProfileCompletionView(viewModel: viewModel)
                .accessibilityIdentifier("onboarding-profileCompletion-step")
        case .programStyle:
            ProgramStyleStepView(selection: Bindable(viewModel).programStyle)
                .accessibilityIdentifier("onboarding-programStyle-step")
        case .dietPreference:
            DietPreferenceStepView(selection: Bindable(viewModel).dietPreference)
                .accessibilityIdentifier("onboarding-dietPreference-step")
        case .calorieFloor:
            CalorieFloorStepView(selection: Bindable(viewModel).calorieFloorType)
                .accessibilityIdentifier("onboarding-calorieFloor-step")
        case .activityLevel:
            TrainingLevelStepView(selection: Bindable(viewModel).trainingLevel)
                .accessibilityIdentifier("onboarding-activityLevel-step")
        case .weeklyDistribution:
            WeeklyDistributionStepView(selection: Bindable(viewModel).weeklyDistributionMode)
                .accessibilityIdentifier("onboarding-weeklyDistribution-step")
        case .proteinLevel:
            ProteinLevelStepView(selection: Bindable(viewModel).proteinLevel)
                .accessibilityIdentifier("onboarding-proteinLevel-step")
        case .shiftedDaySelection:
            ShiftedDaySelectionStepView(highCalorieDays: Bindable(viewModel).highCalorieDays)
                .accessibilityIdentifier("onboarding-shiftedDaySelection-step")
        case .setupConfirmation:
            SetupConfirmationStepView(viewModel: viewModel)
                .accessibilityIdentifier("onboarding-setupConfirmation-step")
        case .faceID:
            FaceIDStepView {
                withAnimation(.spring()) {
                    viewModel.moveToNextStep()
                }
            }
        case .notifications:
            NotificationsStepView {
                withAnimation(.spring()) {
                    viewModel.moveToNextStep()
                }
            }
        case .completion:
            PlaceholderStepView(step: step)
        }
    }

    // MARK: - Pre-SetupConfirmation Animation

    /// Shows the calculating overlay before transitioning to setupConfirmation.
    /// Duration allows all 4 messages to cycle through, showing the "magic" of personalization.
    private func showCalculatingThenSetupConfirmation(viewModel: OnboardingViewModel) async {
        withAnimation(.easeIn(duration: 0.2)) {
            isCalculatingTargets = true
        }

        // Calculate targets while showing animation
        do {
            try await viewModel.calculateTargets()
        } catch {
            calculationError = "Failed to calculate your targets: \(error.localizedDescription)"
            withAnimation(.spring()) {
                isCalculatingTargets = false
            }
            return
        }

        // Show overlay long enough to cycle through all messages (4 messages × 1.2s each)
        try? await Task.sleep(nanoseconds: 5_000_000_000)  // 5 seconds

        withAnimation(.spring()) {
            isCalculatingTargets = false
            viewModel.moveToNextStep()
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
