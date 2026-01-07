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
