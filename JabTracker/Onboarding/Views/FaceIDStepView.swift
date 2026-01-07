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
/// allows users to enable or skip biometric protection.
/// Navigation is handled via the onContinue callback.
struct FaceIDStepView: View {
    /// Callback when user completes this step (enable or skip)
    let onContinue: () -> Void

    // Note: BiometricAuthManager uses legacy ObservableObject pattern.
    // Broader refactor needed to migrate to @Observable (iOS 17+).
    @ObservedObject private var biometricManager = BiometricAuthManager.shared

    /// Task for auto-skip when biometrics unavailable (cancellable on disappear)
    @State private var autoSkipTask: Task<Void, Never>?

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

            // Action buttons (only show if biometrics available)
            if biometricManager.isAvailable {
                PermissionActionButtons(
                    primaryTitle: "Enable \(biometricManager.biometricTypeDisplayName)",
                    enableIdentifier: "faceid-enable-button",
                    skipIdentifier: "faceid-skip-button",
                    onEnable: enableBiometrics,
                    onSkip: skipBiometrics
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-faceid-step")
        .onAppear {
            // Auto-skip if biometrics not available (using cancellable Task)
            if !biometricManager.isAvailable {
                autoSkipTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    if !Task.isCancelled {
                        onContinue()
                    }
                }
            }
        }
        .onDisappear {
            // Cancel auto-skip if view disappears before timer fires
            autoSkipTask?.cancel()
        }
    }

    // MARK: - Available Content

    private var availableContent: some View {
        VStack(spacing: 32) {
            // Dynamic icon based on biometric type
            Image(systemName: biometricIconName)
                .font(.system(size: 64))
                .foregroundStyle(DesignTokens.Colors.accent)
                .accessibilityHidden(true)

            // Benefits list
            BenefitsCard(benefits: benefits)
                .padding(.horizontal, 24)
        }
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

            Text("Skipping automatically...")
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

    // MARK: - Actions

    private func enableBiometrics() {
        // LocalAuthentication doesn't require a system dialog for enabling preference
        // Just set the preference and proceed
        biometricManager.setBiometricPreference(enabled: true)
        onContinue()
    }

    private func skipBiometrics() {
        biometricManager.setBiometricPreference(enabled: false)
        onContinue()
    }
}

#Preview("Face ID Available") {
    FaceIDStepView {}
}
