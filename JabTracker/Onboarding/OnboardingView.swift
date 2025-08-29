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
                    currentStep: viewModel.currentStepIndex + 1,
                    totalSteps: viewModel.totalSteps
                )
                .padding(.top, 16)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(viewModel.currentStepIndex + 1) of \(viewModel.totalSteps)")
                
                // Content area
                Group {
                    switch viewModel.currentStep {
                    case .welcome:
                        WelcomeScreensView(viewModel: viewModel)
                    case .medicationSelection:
                        MedicationSelectionView(viewModel: viewModel)
                    case .doseSetup:
                        InitialDoseSetupView(viewModel: viewModel)
                    case .notifications:
                        PermissionsRequestView(viewModel: viewModel, type: .notifications)
                    case .healthKit:
                        PermissionsRequestView(viewModel: viewModel, type: .healthKit)
                    case .subscription:
                        SubscriptionPlaceholderView(viewModel: viewModel)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
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
                        PrimaryButton(title: viewModel.isLoading ? "Setting Up..." : "Get Started") {
                            Task {
                                await completeOnboarding()
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
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-view")
    }
    
    private func completeOnboarding() async {
        do {
            try await viewModel.completeOnboarding()
            withAnimation(.spring()) {
                isPresented = false
            }
        } catch {
            viewModel.errorMessage = "Failed to complete onboarding: \(error.localizedDescription)"
        }
    }
}