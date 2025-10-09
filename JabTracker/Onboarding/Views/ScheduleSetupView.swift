//
//  ScheduleSetupView.swift
//  JabTracker
//
//  Schedule configuration step in onboarding flow
//

import SwiftUI

/// Onboarding step for configuring medication dosing schedule
///
/// Allows users to select a schedule pattern (weekly, split-dose, custom),
/// preview concentration curves, and configure reminder preferences.
/// Integrates with OnboardingViewModel for state management.
struct ScheduleSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    @State private var showConcentrationPreview: Bool = true

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set Up Your Schedule")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Choose when you'll take your medication")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Pattern Selection
                SchedulePatternPicker(
                    selectedPattern: $viewModel.schedulePattern,
                    onPatternChange: { _ in
                        // Pattern change triggers concentration preview update
                    }
                )

                // Concentration Curve Preview
                if showConcentrationPreview, let medication = viewModel.selectedMedication {
                    ConcentrationCurvePreview(
                        pattern: viewModel.schedulePattern,
                        medication: medication,
                        pkEngine: viewModel.pkEngine,
                        doseAmount: viewModel.selectedDose
                    )
                }

                // Reminder Configuration
                ReminderPreferencesView(
                    reminderMinutes: $viewModel.reminderMinutes,
                    enableMultiple: $viewModel.enableMultipleReminders
                )

                Spacer(minLength: 32)

                // Continue Button
                Button {
                    viewModel.moveToNextStep()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.canProceedToNext ? Color.blue : Color.gray)
                        )
                }
                .disabled(!viewModel.canProceedToNext)
                .accessibilityLabel("Continue to next step")
                .accessibilityHint(continueButtonHint)
            }
            .padding()
        }
        .accessibilityIdentifier("schedule-setup-view")
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Schedule setup")
    }

    /// Accessibility hint for continue button
    private var continueButtonHint: String {
        if !viewModel.canProceedToNext {
            if viewModel.schedulePattern == .custom && !viewModel.customScheduleValid {
                return "Custom pattern configuration required"
            }
            return "Select a schedule pattern to continue"
        }
        return "Proceeds to notification permissions"
    }
}

// MARK: - Preview

#Preview {
    let dataController = DataController.testContainer()
    let authManager = AuthenticationManager(dataController: dataController)
    let viewModel = OnboardingViewModel(
        dataController: dataController,
        authManager: authManager
    )

    // Setup medication selection
    viewModel.selectedMedication = .semaglutide
    viewModel.selectedDose = 0.5
    viewModel.currentStep = .scheduleSetup

    return ScheduleSetupView(viewModel: viewModel)
}
