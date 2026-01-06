//
//  OnboardingStepViews.swift
//  JabTracker
//
//  Step views for onboarding flow - extracted to reduce file length.
//

import SwiftUI

// MARK: - Onboarding Profile Completion View

/// Profile completion step adapted for onboarding (always shows all fields)
struct OnboardingProfileCompletionView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: OnboardingStep.profileCompletion.title,
                subtitle: OnboardingStep.profileCompletion.subtitle
            )

            ScrollView {
                VStack(spacing: 20) {
                    // Info card
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(DesignTokens.Colors.accent)
                            .font(.title2)

                        Text("We need these details to calculate your personalized calorie and macro targets.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DesignTokens.Colors.accent.opacity(0.1))
                    )

                    // Height field
                    profileField(title: "Height", icon: "ruler") {
                        HStack(spacing: 0) {
                            Picker("Feet", selection: $viewModel.editHeightFeet) {
                                ForEach(3...7, id: \.self) { feet in
                                    Text("\(feet) ft").tag(feet)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100, height: 120)

                            Picker("Inches", selection: $viewModel.editHeightInches) {
                                ForEach(0...11, id: \.self) { inches in
                                    Text("\(inches) in").tag(inches)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100, height: 120)
                        }
                    }
                    .accessibilityIdentifier("onboarding-profile-height")

                    // Sex field
                    profileField(title: "Sex", icon: "person.fill") {
                        HStack {
                            sexButton(title: "Male", value: "male")
                            sexButton(title: "Female", value: "female")
                        }
                    }
                    .accessibilityIdentifier("onboarding-profile-sex")

                    // Birthday field
                    profileField(title: "Birthday", icon: "calendar") {
                        DatePicker(
                            "Birthday",
                            selection: $viewModel.editBirthday,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 140)
                        .padding(.vertical, 8)
                        .clipped()
                    }
                    .accessibilityIdentifier("onboarding-profile-birthday")
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func profileField<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(DesignTokens.Colors.accent)
                Text(title)
                    .font(.headline)
            }

            content()
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignTokens.Colors.inactive.opacity(0.3), lineWidth: 1)
        )
    }

    private func sexButton(title: String, value: String) -> some View {
        Button {
            viewModel.editSex = value
        } label: {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            viewModel.editSex == value
                                ? DesignTokens.Colors.accent
                                : DesignTokens.Colors.inactive.opacity(0.2))
                )
                .foregroundColor(viewModel.editSex == value ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("onboarding-sex-\(value)")
    }
}

// MARK: - Setup Confirmation Step View

/// Combined goal and program confirmation step showing calculated targets
struct SetupConfirmationStepView: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: OnboardingStep.setupConfirmation.title,
                subtitle: OnboardingStep.setupConfirmation.subtitle
            )

            ScrollView {
                VStack(spacing: 20) {
                    // Daily Targets Card
                    dailyTargetsCard

                    // Goal Summary
                    goalSummaryCard

                    // Program Info
                    programInfoCard
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var dailyTargetsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("Your Daily Targets")
                    .font(.headline)
                Spacer()
            }

            // Calorie target (prominent)
            VStack(spacing: 4) {
                Text("\(Int(viewModel.calculatedCalories))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.accent)
                Text("calories per day")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)

            // Macro breakdown
            HStack(spacing: 16) {
                macroItem(
                    name: "Protein",
                    value: "\(Int(viewModel.calculatedProtein))g",
                    color: DesignTokens.Colors.accent
                )
                macroItem(
                    name: "Fat",
                    value: "\(Int(viewModel.calculatedFat))g",
                    color: .orange
                )
                macroItem(
                    name: "Carbs",
                    value: "\(Int(viewModel.calculatedCarbs))g",
                    color: DesignTokens.Colors.success
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.Colors.accent.opacity(0.1))
        )
    }

    private func macroItem(name: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var goalSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(DesignTokens.Colors.accent)
                Text("Your Goal")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                SummaryRow(
                    label: "Goal Type",
                    value: viewModel.goalViewModel.goalType?.displayName ?? "—"
                )

                if viewModel.goalViewModel.goalType != .maintenance {
                    SummaryRow(
                        label: "Target Weight",
                        value: formatWeight(viewModel.goalViewModel.targetWeightDisplay)
                    )
                    SummaryRow(
                        label: "Weekly Rate",
                        value: formatRate(viewModel.goalViewModel.weeklyRateDisplay)
                    )
                    SummaryRow(
                        label: "Duration",
                        value: viewModel.goalViewModel.durationDisplay
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.cardBackground)
        )
    }

    private var programInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(DesignTokens.Colors.accent)
                Text("Your Program")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 8) {
                SummaryRow(label: "Style", value: "Coached")
                SummaryRow(label: "Diet", value: "Balanced")
                SummaryRow(
                    label: "Activity",
                    value: viewModel.trainingLevel?.displayName ?? "—"
                )
            }

            Text("You can customize your program anytime in Strategy settings.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.cardBackground)
        )
    }

    private func formatWeight(_ weight: Double) -> String {
        let unit = viewModel.goalViewModel.weightUnitLabel
        let format = viewModel.goalViewModel.usesMetricWeight ? "%.1f %@" : "%.0f %@"
        return String(format: format, weight, unit)
    }

    private func formatRate(_ rate: Double) -> String {
        let unit = viewModel.goalViewModel.weightUnitLabel
        return String(format: "%.1f %@/week", rate, unit)
    }
}
