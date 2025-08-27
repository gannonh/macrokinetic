import AuthenticationServices
import Foundation
import OSLog
import SwiftData
import SwiftUI

enum AuthenticationState: String, CaseIterable {
    case notDetermined
    case authenticated
    case notAuthenticated
    case restricted
    case expired
}

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "JabTracker",
        category: "AuthenticationManager"
    )

    @Published var authenticationState: AuthenticationState = .notDetermined {
        didSet {
            Self.logger.info("🔄 AuthenticationManager: State changed from \(oldValue.rawValue, privacy: .public) to \(self.authenticationState.rawValue, privacy: .public)")
        }
    }

    @Published var currentUser: User?

    private let dataController: DataController

    init(dataController: DataController? = nil) {
        self.dataController = dataController ?? DataController.shared
        super.init()
    }

    func checkAuthenticationStatus() async {
        Self.logger.info("🔍 AuthenticationManager: checkAuthenticationStatus() called")

        // Reset app data if requested (for UI testing)
        if ProcessInfo.processInfo.arguments.contains("--reset-app-data") {
            await resetAppData()
        }

        // Check if we're in UI testing mode - environment is available after app launch
        let isUITesting = ProcessInfo.processInfo.environment["UI_TESTING"] == "true" ||
            ProcessInfo.processInfo.arguments.contains("--ui-testing")

        if isUITesting {
            await MainActor.run {
                authenticationState = .authenticated
                // Create a simple test user
                currentUser = User(
                    email: "test@uitesting.com",
                    name: "UI Test User",
                    weight: 70.0,
                    weightUnit: "kg",
                    timezone: "UTC")
            }
            return
        }

        // Check if user is already authenticated by looking for existing user data
        let context = dataController.container.mainContext

        do {
            let fetchDescriptor = FetchDescriptor<User>()
            let users = try context.fetch(fetchDescriptor)

            Self.logger.info("🔍 AuthenticationManager: Found \(users.count, privacy: .public) users in database")
            if let user = users.first {
                Self.logger.info("🔍 AuthenticationManager: First user - ID: \(user.id, privacy: .public), Email: \(user.email, privacy: .public)")
            }

            await MainActor.run {
                if let user = users.first {
                    currentUser = user
                    authenticationState = .authenticated
                    Self.logger.info("✅ AuthenticationManager: Set state to authenticated")
                } else {
                    authenticationState = .notAuthenticated
                    Self.logger.info("❌ AuthenticationManager: Set state to notAuthenticated - no users found")
                }
            }
        } catch {
            Self.logger.error("❌ AuthenticationManager: Fetch error: \(error, privacy: .public)")
            await MainActor.run {
                authenticationState = .notAuthenticated
            }
        }
    }

    private func resetAppData() async {
        let context = dataController.container.mainContext

        // Clear all existing users
        do {
            let fetchDescriptor = FetchDescriptor<User>()
            let users = try context.fetch(fetchDescriptor)
            for user in users {
                context.delete(user)
            }
            try context.save()
        } catch {
            Self.logger.error("Failed to reset app data: \(error, privacy: .public)")
        }

        await MainActor.run {
            currentUser = nil
            authenticationState = .notAuthenticated
        }
    }

    // MARK: - Private Helper Methods

    private func processAppleIDCredential(_ appleIDCredential: ASAuthorizationAppleIDCredential) async throws -> User {
        // Consolidated credential processing logic
        let context = dataController.container.mainContext

        let user = User(
            email: appleIDCredential.email ?? "unknown@apple.com",
            name: appleIDCredential.fullName?.formatted())

        context.insert(user)
        Self.logger.info("📝 AuthenticationManager: User inserted into context - ID: \(user.id, privacy: .public)")

        try context.save()
        Self.logger.info("💾 AuthenticationManager: Context saved successfully")

        // Verify the user was actually saved
        let fetchDescriptor = FetchDescriptor<User>()
        let savedUsers = try context.fetch(fetchDescriptor)
        Self.logger.info("🔍 AuthenticationManager: After save, found \(savedUsers.count, privacy: .public) users in database")

        Self.logger.info("✅ AuthenticationManager: User created successfully - ID: \(user.id, privacy: .public), Email: \(user.email, privacy: .public)")

        return user
    }

    // MARK: - Public Methods

    func signInWithApple() async throws -> User {
        // This method will implement the Sign in with Apple flow
        // For now, return a placeholder to make tests pass

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        // This is a minimal implementation to make tests pass
        // Full implementation would handle the authorization flow
        throw AuthenticationError.notImplemented
    }

    func handleSignInWithAppleResult(_ authorization: ASAuthorization) async throws -> User {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthenticationError.authorizationDenied
        }

        let user = try await processAppleIDCredential(appleIDCredential)

        await MainActor.run {
            currentUser = user
            authenticationState = .authenticated
        }

        return user
    }

    func signOut() async throws {
        // Clear user data from SwiftData
        let context = dataController.container.mainContext

        if let user = currentUser {
            context.delete(user)
            try context.save()
        }

        await MainActor.run {
            authenticationState = .notAuthenticated
            currentUser = nil
        }
    }
}

enum AuthenticationError: Error, LocalizedError {
    case notImplemented
    case authorizationDenied
    case credentialsNotFound
    case keychainError

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Authentication not fully implemented"
        case .authorizationDenied:
            return "User denied authorization"
        case .credentialsNotFound:
            return "No stored credentials found"
        case .keychainError:
            return "Error accessing Keychain"
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            await handleSignInResult(authorization)
        }
    }

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError _: Error) {
        Task { @MainActor in
            authenticationState = .notAuthenticated
        }
    }

    private func handleSignInResult(_ authorization: ASAuthorization) async {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            await MainActor.run {
                authenticationState = .notAuthenticated
            }
            return
        }

        do {
            let user = try await processAppleIDCredential(appleIDCredential)

            await MainActor.run {
                currentUser = user
                authenticationState = .authenticated
            }
        } catch {
            Self.logger.error("❌ AuthenticationManager: Failed to process Apple ID credential: \(error.localizedDescription, privacy: .public)")
            await MainActor.run {
                authenticationState = .notAuthenticated
            }
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first
        else {
            fatalError("No window available for Sign in with Apple")
        }
        return window
    }
}
