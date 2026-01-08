//
//  ScheduleSetupView.swift
//  JabTracker
//
//  Schedule configuration step in onboarding flow
//

import SwiftUI

/// Legacy onboarding step for configuring medication dosing schedule (v0.5.x and earlier).
/// Retained for reference only.
/// New implementation: JabTracker/Onboarding/Views/ScheduleSetupView.swift
struct ScheduleSetupView: View {
    @ObservedObject var viewModel: LegacyOnboardingViewModel

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
                    medication: viewModel.selectedMedication ?? .semaglutide,
                    selectedPattern: $viewModel.schedulePattern,
                    onPatternChange: { _ in
                        // Pattern change triggers concentration preview update
                    }
                )

                // Start Date Selection
                DesignCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Start Date")
                            .font(DesignTokens.Typography.headline)

                        DatePicker(
                            "Start Date",
                            selection: $viewModel.selectedStartDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .accessibilityIdentifier("start-date-picker")
                    }
                }

                // Time of Day Selection
                if viewModel.schedulePattern == .splitDose {
                    // Split-dose: Two time pickers
                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Dose Times")
                                .font(DesignTokens.Typography.headline)

                            VStack(alignment: .leading, spacing: 12) {
                                // First dose time
                                HStack {
                                    Text("1st Dose")
                                        .font(DesignTokens.Typography.body)
                                    Spacer()
                                    DatePicker(
                                        "1st Dose Time",
                                        selection: $viewModel.selectedFirstDoseTime,
                                        displayedComponents: .hourAndMinute
                                    )
                                    .labelsHidden()
                                    .accessibilityIdentifier("first-dose-time-picker")
                                }

                                Divider()

                                // Second dose time
                                HStack {
                                    Text("2nd Dose")
                                        .font(DesignTokens.Typography.body)
                                    Spacer()
                                    DatePicker(
                                        "2nd Dose Time",
                                        selection: $viewModel.selectedSecondDoseTime,
                                        displayedComponents: .hourAndMinute
                                    )
                                    .labelsHidden()
                                    .accessibilityIdentifier("second-dose-time-picker")
                                }
                            }

                            // Validation message for split-dose times
                            if !viewModel.areSplitDoseTimesValid {
                                Text("Dose times must be 6-18 hours apart")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .accessibilityIdentifier("split-dose-validation-error")
                            }
                        }
                    }
                } else {
                    // Weekly/Daily: Single time picker (compact pill style)
                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Time of Day")
                                .font(DesignTokens.Typography.headline)

                            HStack {
                                Text("Dose Time")
                                    .font(DesignTokens.Typography.body)
                                Spacer()
                                DatePicker(
                                    "Dose Time",
                                    selection: $viewModel.selectedDoseTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                .accessibilityIdentifier("dose-time-picker")
                            }
                        }
                    }
                }

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
                    enableMultiple: $viewModel.enableMultipleReminders,
                    schedulePattern: viewModel.schedulePattern,
                    doseTime: viewModel.selectedDoseTime,
                    firstDoseTime: viewModel.selectedFirstDoseTime,
                    secondDoseTime: viewModel.selectedSecondDoseTime
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
    let viewModel = LegacyOnboardingViewModel(
        dataController: dataController,
        authManager: authManager
    )

    // Setup medication selection using closure to avoid view builder issues
    return ScheduleSetupView(viewModel: viewModel)
        .onAppear {
            viewModel.selectedMedication = .semaglutide
            viewModel.selectedDose = 0.5
            viewModel.currentStep = .scheduleSetup
        }
}
