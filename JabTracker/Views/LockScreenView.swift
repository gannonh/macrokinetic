//
//  LockScreenView.swift
//  JabTracker
//
//  Lock screen shown when biometric authentication is required.
//

import SwiftUI

struct LockScreenView: View {
    @EnvironmentObject private var biometricManager: BiometricAuthManager
    @Binding var isLocked: Bool

    @State private var isAuthenticating = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.1, green: 0.12, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Lock icon in shield
                ZStack {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.white.opacity(0.15))

                    Image(systemName: "lock.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white.opacity(0.9))
                }

                // App name
                Text("MacroKinetic")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                // Unlock message
                Text("Unlock to access your health data")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Unlock button
                Button {
                    authenticate()
                } label: {
                    HStack(spacing: 12) {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: biometricIconName)
                                .font(.title2)
                        }
                        Text(
                            isAuthenticating
                                ? "Authenticating..." : "Unlock with \(biometricManager.biometricTypeDisplayName)"
                        )
                        .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(14)
                }
                .disabled(isAuthenticating)
                .padding(.horizontal, 24)
                .accessibilityIdentifier("unlock-button")

                // Version info
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
                {
                    Text("Version \(version) (\(build))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.bottom, 32)
                }
            }
        }
        .accessibilityIdentifier("lock-screen-view")
    }

    private var biometricIconName: String {
        switch biometricManager.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "lock.fill"
        }
    }

    private func authenticate() {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        errorMessage = nil

        Task {
            do {
                let success = try await biometricManager.authenticateWithBiometrics(
                    reason: "Unlock MacroKinetic")

                await MainActor.run {
                    isAuthenticating = false
                    if success {
                        withAnimation {
                            isLocked = false
                        }
                    } else {
                        errorMessage = "Authentication failed. Please try again."
                    }
                }
            } catch {
                await MainActor.run {
                    isAuthenticating = false
                    if let biometricError = error as? BiometricError {
                        switch biometricError {
                        case .userCancel, .userFallback:
                            // User cancelled - don't show error, let them tap button again
                            break
                        case .lockout:
                            errorMessage = "Too many failed attempts. Please try again later."
                        case .notAvailable:
                            errorMessage = "Biometric authentication not available."
                        case .disabled:
                            // Shouldn't happen since we check this before showing lock screen
                            isLocked = false
                        case .authenticationFailed:
                            errorMessage = "Authentication failed. Please try again."
                        }
                    } else {
                        errorMessage = "Authentication error. Please try again."
                    }
                }
            }
        }
    }
}

#Preview {
    LockScreenView(isLocked: .constant(true))
        .environmentObject(BiometricAuthManager())
}
