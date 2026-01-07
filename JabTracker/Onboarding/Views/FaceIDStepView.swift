//
//  FaceIDStepView.swift
//  JabTracker
//
//  Permission screen for Face ID/Touch ID during onboarding.
//  Dynamically detects biometric type and adapts UI accordingly.
//

import SwiftUI

/// Face ID/Touch ID permission screen for onboarding.
///
/// Displays appropriate biometric type (Face ID, Touch ID, or Optic ID) and
/// allows users to toggle biometric protection on/off.
/// Uses standard navigation (Back/Continue) from parent OnboardingView.
struct FaceIDStepView: View {
    // Note: BiometricAuthManager uses legacy ObservableObject pattern.
    // Broader refactor needed to migrate to @Observable (iOS 17+).
    @ObservedObject private var biometricManager = BiometricAuthManager.shared

    private let step = OnboardingStep.faceID

    private let benefits = [
        "Protect your sensitive health data",
        "Unlock the app quickly and securely",
        "Your data stays private on your device",
    ]

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(title: step.title, subtitle: step.subtitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Check if biometrics are available
            if biometricManager.isAvailable {
                availableContent
            } else {
                unavailableContent
            }

            Spacer()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-faceid-step")
    }

    // MARK: - Available Content

    private var availableContent: some View {
        VStack(spacing: 32) {
            // Dynamic icon based on biometric type
            Image(systemName: biometricIconName)
                .font(.system(size: 64))
                .foregroundStyle(
                    biometricManager.isBiometricEnabled
                        ? DesignTokens.Colors.accent
                        : DesignTokens.Colors.inactive
                )
                .accessibilityHidden(true)
                .animation(.easeInOut(duration: 0.2), value: biometricManager.isBiometricEnabled)

            // Benefits list
            BenefitsCard(benefits: benefits)
                .padding(.horizontal, 24)

            // Toggle row
            toggleRow
                .padding(.horizontal, 24)
        }
    }

    // MARK: - Toggle Row

    private var toggleRow: some View {
        VStack(spacing: 0) {
            HStack {
                Label {
                    Text(biometricManager.biometricTypeDisplayName)
                        .font(.body)
                } icon: {
                    Image(systemName: biometricIconName)
                        .foregroundStyle(DesignTokens.Colors.accent)
                }

                Spacer()

                Toggle("", isOn: $biometricManager.isBiometricEnabled)
                    .labelsHidden()
                    .accessibilityIdentifier("faceid-toggle")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(DesignTokens.Colors.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Unavailable Content

    private var unavailableContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .font(.system(size: 64))
                .foregroundStyle(DesignTokens.Colors.inactive)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Biometrics Not Available")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Your device doesn't support biometric authentication, or it hasn't been set up.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Text("You can continue without biometric protection.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Computed Properties

    private var biometricIconName: String {
        switch biometricManager.biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.shield"
        }
    }
}

#Preview("Face ID Available") {
    FaceIDStepView()
}
