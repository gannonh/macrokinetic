import Foundation
import AuthenticationServices
import SwiftData
import SwiftUI

enum AuthenticationState: String, CaseIterable {
    case notDetermined
    case authenticated
    case denied
    case restricted
    case expired
}

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    @Published var authenticationState: AuthenticationState = .notDetermined
    @Published var currentUser: User?
    
    private let dataController: DataController
    
    init(dataController: DataController = .shared) {
        self.dataController = dataController
        super.init()
        checkAuthenticationState()
    }
    
    private func checkAuthenticationState() {
        // Check stored authentication state on app launch
        // This will be implemented to check Keychain for stored credentials
        authenticationState = .notDetermined
    }
    
    func signInWithApple() async throws -> User {
        // This method will implement the Sign in with Apple flow
        // For now, return a placeholder to make tests pass
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // This is a minimal implementation to make tests pass
        // Full implementation would handle the authorization flow
        throw AuthenticationError.notImplemented
    }
    
    func signOut() async throws {
        // Clear authentication state and user
        authenticationState = .notDetermined
        currentUser = nil
        
        // Clear Keychain credentials (to be implemented)
        // Clear any cached user data
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
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task {
            await handleSignInResult(authorization)
        }
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            authenticationState = .denied
        }
    }
    
    private func handleSignInResult(_ authorization: ASAuthorization) async {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            await MainActor.run {
                authenticationState = .denied
            }
            return
        }
        
        // Create or update user in SwiftData
        let context = dataController.container.mainContext
        
        let user = User(
            email: appleIDCredential.email,
            name: appleIDCredential.fullName?.formatted(),
            createdAt: Date(),
            updatedAt: Date()
        )
        
        context.insert(user)
        try? context.save()
        
        await MainActor.run {
            currentUser = user
            authenticationState = .authenticated
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for Sign in with Apple")
        }
        return window
    }
}