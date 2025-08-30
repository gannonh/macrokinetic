import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>, authManager: AuthenticationManager) {
        self._isPresented = isPresented
        self._viewModel = StateObject(wrappedValue: OnboardingViewModel(authManager: authManager))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                OnboardingProgressIndicator(
                    currentStep: self.viewModel.currentStepIndex + 1,
                    totalSteps: self.viewModel.totalSteps)
                    .padding(.top, 16)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Step \(self.viewModel.currentStepIndex + 1) of \(self.viewModel.totalSteps)")

                // Content area
                Group {
                    switch self.viewModel.currentStep {
                    case .welcome:
                        WelcomeScreensView(viewModel: self.viewModel)
                    case .medicationSelection:
                        MedicationSelectionView(viewModel: self.viewModel)
                    case .doseSetup:
                        InitialDoseSetupView(viewModel: self.viewModel)
                    case .notifications:
                        PermissionsRequestView(viewModel: self.viewModel, type: .notifications)
                    case .healthKit:
                        PermissionsRequestView(viewModel: self.viewModel, type: .healthKit)
                    case .subscription:
                        SubscriptionPlaceholderView(viewModel: self.viewModel)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)))

                // Navigation buttons
                HStack {
                    if self.viewModel.currentStepIndex > 0 {
                        SecondaryButton(title: "Back") {
                            withAnimation(.spring()) {
                                self.viewModel.moveToPreviousStep()
                            }
                        }
                        .accessibilityIdentifier("onboarding-back-button")
                    }

                    Spacer()

                    if self.viewModel.isLastStep {
                        PrimaryButton(title: self.viewModel.isLoading ? "Setting Up..." : "Get Started") {
                            Task {
                                await self.completeOnboarding()
                            }
                        }
                        .disabled(self.viewModel.isLoading || !self.viewModel.canProceedToNext)
                        .accessibilityIdentifier("onboarding-complete-button")
                    } else {
                        PrimaryButton(title: "Continue") {
                            withAnimation(.spring()) {
                                self.viewModel.moveToNextStep()
                            }
                        }
                        .disabled(!self.viewModel.canProceedToNext)
                        .accessibilityIdentifier("onboarding-continue-button")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(DesignTokens.Colors.background)
            .navigationBarHidden(true)
            .alert("Error", isPresented: .constant(self.viewModel.errorMessage != nil)) {
                Button("OK") {
                    self.viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-view")
    }

    private func completeOnboarding() async {
        do {
            try await self.viewModel.completeOnboarding()
            withAnimation(.spring()) {
                self.isPresented = false
            }
        } catch {
            self.viewModel.errorMessage = "Failed to complete onboarding: \(error.localizedDescription)"
        }
    }
}
