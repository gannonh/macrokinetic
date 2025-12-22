import AuthenticationServices
import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App Logo and Branding
            VStack(spacing: 16) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                Text("MacroKinetic")
                    .font(DesignTokens.Typography.largeTitle)
                    .bold()

                Text("Precision nutrition tracking for your weight management journey")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Authentication Section
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Welcome to MacroKinetic")
                        .font(DesignTokens.Typography.headline)

                    Text("Sign in to sync your data across devices")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        Task {
                            await self.handleSignInResult(result)
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .accessibilityIdentifier("sign-in-with-apple-button")

                VStack(spacing: 4) {
                    Text("Your medical data stays private and secure")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)

                    Text("Synced with iCloud and protected by encryption")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .alert("Sign In Error", isPresented: self.$showingError) {
            Button("OK") {}
        } message: {
            Text(self.errorMessage)
        }
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case let .success(authorization):
            do {
                _ = try await self.authManager.handleSignInWithAppleResult(authorization)
                await MainActor.run {
                    // Authentication successful, AuthenticationManager will update state
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Sign in failed: \(error.localizedDescription)"
                    self.showingError = true
                }
            }

        case let .failure(error):
            await MainActor.run {
                self.errorMessage = "Sign in failed: \(error.localizedDescription)"
                self.showingError = true
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
        .environmentObject(BiometricAuthManager())
}
