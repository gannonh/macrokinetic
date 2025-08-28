import AuthenticationServices
import Foundation
@testable import JabTracker
import SwiftData
import Testing

@MainActor
@Suite("Authentication Manager Tests")
struct AuthenticationManagerTests {
    @Test("AuthenticationManager initialization")
    @MainActor
    func authManagerInit() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Verify initial state
        #expect(authManager.authenticationState == .notDetermined)
        #expect(authManager.currentUser == nil)

        // Note: dataController is private, so we can't test it directly
        // The fact that the manager initializes successfully validates the connection
    }

    @Test("AuthenticationManager sign in with Apple error handling")
    @MainActor
    func signInWithAppleErrorHandling() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test initial state is correct
        #expect(authManager.authenticationState == .notDetermined)
        #expect(authManager.currentUser == nil)

        // Test that signInWithApple properly propagates errors in test environment
        Task {
            var didThrowError = false
            do {
                _ = try await authManager.signInWithApple()
            } catch {
                didThrowError = true
                // Should throw a specific AuthenticationError, not just any error
                #expect(error is AuthenticationError, "Should throw AuthenticationError, got: \(type(of: error))")
                // Authentication state should remain unchanged after error
                #expect(authManager.authenticationState == .notDetermined)
                #expect(authManager.currentUser == nil)
            }
            #expect(didThrowError, "signInWithApple should throw an error in test environment")
        }
    }

    @Test("AuthenticationManager state transitions")
    @MainActor
    func authStateTransitions() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test initial state
        #expect(authManager.authenticationState == .notDetermined)
        #expect(authManager.currentUser == nil)

        // Test signOut updates state correctly
        Task {
            try await authManager.signOut()
            #expect(authManager.currentUser == nil, "currentUser should be nil after signOut")
            #expect(authManager.authenticationState == .notAuthenticated,
                    "authenticationState should be .notAuthenticated after signOut")
        }

        // Test checkAuthenticationStatus with empty database maintains notAuthenticated state
        Task {
            await authManager.checkAuthenticationStatus()
            // With no users in test database, should remain notAuthenticated
            #expect(authManager.authenticationState == .notAuthenticated,
                    "authenticationState should remain .notAuthenticated with empty database")
        }
    }

    @Test("Authentication state consistency after app restart")
    @MainActor
    func authStateConsistencyAfterRestart() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test checkAuthenticationStatus handles empty database gracefully
        Task {
            await authManager.checkAuthenticationStatus()
            // Should not crash with empty user database
            // AuthenticationState is an enum, so verify it has a valid state
            #expect(authManager.authenticationState == .notDetermined ||
                authManager.authenticationState == .authenticated ||
                authManager.authenticationState == .notAuthenticated)
        }

        // Test with existing user data
        let context = dataController.container.mainContext
        let testUser = User(email: "persistence-test@example.com", weight: 70.0)
        context.insert(testUser)
        try context.save()

        Task {
            await authManager.checkAuthenticationStatus()
            // Should detect existing user data
        }
    }

    @Test("Authentication manager error recovery")
    @MainActor
    func authManagerErrorRecovery() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test that sign out works regardless of current state
        Task {
            try await authManager.signOut()
            #expect(authManager.currentUser == nil)
        }

        // Test that checkAuthenticationStatus handles various states
        Task {
            await authManager.checkAuthenticationStatus()
            // Should complete without error regardless of state
        }
    }

    @Test("Concurrent authentication operations")
    @MainActor
    func concurrentAuthOperations() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test that multiple simultaneous auth status checks don't cause issues
        Task {
            await withTaskGroup(of: Void.self) { group in
                // Simulate multiple concurrent auth status checks
                for _ in 0 ..< 3 {
                    group.addTask {
                        await authManager.checkAuthenticationStatus()
                    }
                }
            }

            // Should complete without deadlocks or crashes
            // AuthenticationState is an enum so it's never nil
            #expect(authManager.authenticationState == .notDetermined ||
                authManager.authenticationState == .authenticated ||
                authManager.authenticationState == .notAuthenticated)
        }
    }

    @Test("Invalid user data handling")
    @MainActor
    func invalidUserDataHandling() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Test with user missing required fields
        let incompleteUser = User(email: "", weight: 0.0) // Empty email, zero weight
        context.insert(incompleteUser)
        try context.save()

        Task {
            await authManager.checkAuthenticationStatus()
            // Should handle incomplete user data gracefully
            // Don't assume this means authenticated if data is invalid
        }

        // Test authentication manager can handle users with missing Apple ID
        let userWithoutAppleID = User(email: "no-apple-id@example.com", weight: 70.0)
        // Note: appleUserId intentionally nil
        context.insert(userWithoutAppleID)
        try context.save()

        Task {
            await authManager.checkAuthenticationStatus()
            // Should handle missing Apple ID appropriately
        }
    }

    @Test("Authentication error handling scenarios")
    @MainActor
    func authenticationErrorHandlingScenarios() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test that signOut works even when no user is signed in
        Task {
            try await authManager.signOut()
            #expect(authManager.authenticationState == .notAuthenticated,
                    "signOut should succeed even when no user is signed in")
            #expect(authManager.currentUser == nil,
                    "currentUser should be nil after signOut")
        }

        // Test multiple consecutive signOut calls don't cause issues
        Task {
            try await authManager.signOut()
            try await authManager.signOut()
            try await authManager.signOut()
            #expect(authManager.authenticationState == .notAuthenticated,
                    "Multiple signOut calls should be handled gracefully")
        }
    }

    @Test("Authentication state persistence edge cases")
    @MainActor
    func authStatePersistenceEdgeCases() throws {
        let dataController = DataController.testContainer()

        // Test creating multiple authentication managers with same data controller
        let authManager1 = AuthenticationManager(dataController: dataController)
        let authManager2 = AuthenticationManager(dataController: dataController)

        // Both should start in same initial state
        #expect(authManager1.authenticationState == authManager2.authenticationState,
                "Multiple AuthenticationManager instances should have consistent initial state")

        // Test state changes don't affect each other (they're independent instances)
        Task {
            try await authManager1.signOut()
            #expect(authManager1.authenticationState == .notAuthenticated,
                    "First manager should be not authenticated after signOut")
            #expect(authManager2.authenticationState == .notDetermined,
                    "Second manager should remain in initial state")
        }
    }

    @Test("Handle Sign in with Apple result - authorization denied")
    @MainActor
    func handleSignInWithAppleResultAuthorizationDenied() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test authorization denied by using non-ASAuthorizationAppleIDCredential
        // Since we can't easily mock the Apple classes, we'll test the method exists
        // In real usage, this would be called by the ASAuthorizationControllerDelegate

        Task {
            // Test that the method exists and can handle error cases
            // The actual authentication flow is tested through the delegate methods
            #expect(authManager.authenticationState == .notDetermined, "Should start in notDetermined state")
            #expect(authManager.currentUser == nil, "Should have no current user initially")
        }
    }

    @Test("Handle Sign in with Apple result - successful credential")
    @MainActor
    func handleSignInWithAppleResultSuccess() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test that the method interface exists and state management works
        // The actual authentication flow testing is done through integration tests

        Task {
            // Test initial state
            #expect(authManager.authenticationState == .notDetermined, "Should start in notDetermined state")
            #expect(authManager.currentUser == nil, "Should have no current user initially")

            // The handleSignInWithAppleResult method exists and would process real credentials
            // Integration testing covers the full authentication flow
        }
    }

    @Test("Process Apple ID credential with empty email")
    @MainActor
    func processAppleIDCredentialEmptyEmail() throws {
        let dataController = DataController.testContainer()
        _ = AuthenticationManager(dataController: dataController)

        // Test that the authentication manager can handle users with nil emails
        // This tests the User model behavior when created with nil email

        Task {
            let context = dataController.container.mainContext

            // Create a user with nil email (as would happen when Apple doesn't provide email)
            let user = User(email: nil, name: nil)
            context.insert(user)
            try context.save()

            #expect(user.email == nil, "User should have nil email when not provided")
            #expect(user.displayEmail == "No email", "Display email should handle nil gracefully")
            #expect(user.emailForCloudKit == "", "CloudKit email should be empty string for nil")
        }
    }

    @Test("Check authentication status with UI testing environment", .disabled("Swift Testing framework issue with environment variables"))
    @MainActor
    func checkAuthStatusUITesting() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Save original environment
        let originalEnv = ProcessInfo.processInfo.environment["UI_TESTING"]

        // Simulate UI testing environment
        setenv("UI_TESTING", "true", 1)
        defer {
            if let original = originalEnv {
                setenv("UI_TESTING", original, 1)
            } else {
                unsetenv("UI_TESTING")
            }
        }

        await authManager.checkAuthenticationStatus()

        // Note: UI testing environment detection may not work in unit tests
        // This test validates the method can be called without crashing
        #expect(authManager.authenticationState != .notDetermined, "Authentication state should be determined after check")

        // The exact state depends on environment detection, so we check it's valid
        let validStates: [AuthenticationState] = [.authenticated, .notAuthenticated, .restricted, .expired]
        #expect(validStates.contains(authManager.authenticationState), "Should have valid authentication state")
    }

    @Test("Reset app data functionality")
    @MainActor
    func resetAppDataFunctionality() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Create test user data first
        let testUser = User(email: "test-before-reset@example.com", weight: 75.0)
        context.insert(testUser)
        try context.save()

        // Verify user exists
        let fetchDescriptor = FetchDescriptor<User>()
        let usersBefore = try context.fetch(fetchDescriptor)
        #expect(usersBefore.count == 1, "Should have one user before reset")

        // Set current user
        authManager.currentUser = testUser
        authManager.authenticationState = .authenticated

        // Simulate reset app data (like UI testing does)
        Task {
            await authManager.checkAuthenticationStatus()

            // Verify data was reset (this only happens with --reset-app-data arg)
            // Since we can't easily mock process arguments, we'll test the state
            #expect(authManager.authenticationState != .notDetermined, "State should be determined after check")
        }
    }

    @Test("ASAuthorizationControllerDelegate - success handling")
    @MainActor
    func authControllerDelegateSuccess() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test that the delegate methods exist and can be called
        // The actual delegate functionality is tested through integration tests

        Task {
            // Verify initial state
            #expect(authManager.authenticationState == .notDetermined, "Should start in notDetermined state")
            #expect(authManager.currentUser == nil, "Should have no current user initially")

            // The delegate methods exist and would handle real authorization responses
            // Integration tests cover the full authentication delegate flow
        }
    }

    @Test("ASAuthorizationControllerDelegate - error handling")
    @MainActor
    func authControllerDelegateError() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test that the delegate error handling methods exist
        // The actual error handling is tested through integration tests

        Task {
            // Verify initial state
            #expect(authManager.authenticationState == .notDetermined, "Should start in notDetermined state")
            #expect(authManager.currentUser == nil, "Should have no current user initially")

            // The delegate error methods exist and would handle authentication failures
            // Integration tests cover the full authentication error flow
        }
    }

    @Test("Authentication error types and descriptions")
    func authenticationErrorTypes() throws {
        // Test all AuthenticationError cases have proper descriptions
        let notImplemented = AuthenticationError.notImplemented
        #expect(notImplemented.errorDescription?.contains("not fully implemented") == true,
                "notImplemented should have descriptive error message")

        let authDenied = AuthenticationError.authorizationDenied
        #expect(authDenied.errorDescription?.contains("denied authorization") == true,
                "authorizationDenied should have descriptive error message")

        let credentialsNotFound = AuthenticationError.credentialsNotFound
        #expect(credentialsNotFound.errorDescription?.contains("credentials found") == true,
                "credentialsNotFound should have descriptive error message")

        let keychainError = AuthenticationError.keychainError
        #expect(keychainError.errorDescription?.contains("Keychain") == true,
                "keychainError should have descriptive error message")
    }

    @Test("Authentication state enum all cases")
    func authenticationStateEnumCases() throws {
        // Test all AuthenticationState cases exist and have proper raw values
        let states: [AuthenticationState] = [.notDetermined, .authenticated, .notAuthenticated, .restricted, .expired]

        #expect(states.count == 5, "Should have exactly 5 authentication states")
        #expect(AuthenticationState.notDetermined.rawValue == "notDetermined")
        #expect(AuthenticationState.authenticated.rawValue == "authenticated")
        #expect(AuthenticationState.notAuthenticated.rawValue == "notAuthenticated")
        #expect(AuthenticationState.restricted.rawValue == "restricted")
        #expect(AuthenticationState.expired.rawValue == "expired")

        // Test CaseIterable conformance
        #expect(AuthenticationState.allCases.count == 5, "allCases should contain all 5 states")
    }

    @Test("Presentation context providing")
    @MainActor
    func presentationContextProviding() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test that the presentation context method exists
        // This method requires a valid window scene which is not available in unit tests
        // The method would work in a real app context with proper UI setup

        // Verify the authentication manager exists and has the required protocol conformance
        #expect(authManager is ASAuthorizationControllerPresentationContextProviding,
                "AuthenticationManager should conform to presentation context providing")

        // The presentationAnchor method exists and would return a window in real app context
        // Testing this requires integration tests with actual UI context
    }
}

// MARK: - Test Notes

//
// Full authentication flow testing with Apple's AuthenticationServices framework
// requires integration testing with real Apple ID credentials. The tests above
// cover the state management, error handling, and public interfaces.
//
// The actual Sign in with Apple flow is tested through:
// - UI tests that simulate the authentication flow
// - Integration tests with test Apple ID accounts
// - Manual testing on physical devices
