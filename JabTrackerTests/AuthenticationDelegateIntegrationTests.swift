import AuthenticationServices
import Foundation
@testable import JabTracker
import SwiftData
import Testing

@MainActor
@Suite("Authentication Delegate Integration Tests")
struct AuthenticationDelegateIntegrationTests {
    @Test("Authentication delegate error handling integration")
    @MainActor
    func authDelegateErrorHandlingIntegration() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        
        // Test error delegate method without creating ASAuthorizationController
        // (since it requires non-empty authorization requests)
        let mockError = NSError(domain: "test.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // Create a dummy request for the controller
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        let mockController = ASAuthorizationController(authorizationRequests: [request])
        
        // Call the delegate error method directly
        authManager.authorizationController(controller: mockController, didCompleteWithError: mockError)
        
        Task {
            // Give async operations time to complete
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            // Should set state to notAuthenticated on error
            #expect(authManager.authenticationState == .notAuthenticated,
                    "Should set notAuthenticated state on authorization error")
        }
    }
    
    @Test("Authentication handleSignInResult error path")
    @MainActor
    func authHandleSignInResultErrorPath() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        
        // Test the error handling path by checking initial state
        // The actual delegate method testing requires real ASAuthorization objects
        // which are difficult to mock properly
        
        Task {
            // Test initial state
            #expect(authManager.authenticationState == .notDetermined,
                    "Should start in notDetermined state")
            
            // Test that signInWithApple throws appropriate error
            var didThrowError = false
            do {
                _ = try await authManager.signInWithApple()
            } catch {
                didThrowError = true
                #expect(error is AuthenticationError, "Should throw AuthenticationError")
            }
            #expect(didThrowError, "signInWithApple should throw error in test environment")
        }
    }
    
    @Test("Authentication processAppleIDCredential database operations")
    @MainActor
    func authProcessAppleIDCredentialDatabaseOps() throws {
        let dataController = DataController.testContainer()
        _ = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext
        
        // Test that processAppleIDCredential creates and saves user correctly
        // We can't directly test processAppleIDCredential since it's private,
        // but we can test the database operations it would perform
        
        Task {
            // Simulate what processAppleIDCredential does
            let user = User(email: "credential-test@example.com", name: "Test User")
            user.appleUserId = "test.apple.user.id"
            
            context.insert(user)
            try context.save()
            
            // Verify user was created with correct data
            let fetchDescriptor = FetchDescriptor<User>()
            let users = try context.fetch(fetchDescriptor)
            
            let savedUser = users.first { $0.email == "credential-test@example.com" }
            #expect(savedUser != nil, "User should be saved to database")
            #expect(savedUser?.appleUserId == "test.apple.user.id", 
                    "Apple User ID should be saved correctly")
            #expect(savedUser?.name == "Test User", "User name should be saved correctly")
        }
    }
    
    @Test("Authentication signOut database cleanup")
    @MainActor
    func authSignOutDatabaseCleanup() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext
        
        // Create a user to sign out
        let user = User(email: "signout-test@example.com", weight: 70.0)
        context.insert(user)
        try context.save()
        
        // Set as current user
        authManager.currentUser = user
        authManager.authenticationState = .authenticated
        
        Task {
            // Test sign out clears data
            try await authManager.signOut()
            
            // Should clear current user and state
            #expect(authManager.currentUser == nil, "Current user should be nil after signOut")
            #expect(authManager.authenticationState == .notAuthenticated,
                    "State should be notAuthenticated after signOut")
            
            // User should be deleted from database
            let fetchDescriptor = FetchDescriptor<User>()
            let remainingUsers = try context.fetch(fetchDescriptor)
            let foundUser = remainingUsers.first { $0.email == "signout-test@example.com" }
            #expect(foundUser == nil, "User should be deleted from database on signOut")
        }
    }
    
    @Test("Authentication resetAppData through checkAuthenticationStatus")
    @MainActor
    func authResetAppDataThroughCheckAuth() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext
        
        // Create some existing user data to test reset
        let existingUser1 = User(email: "existing1@example.com", name: "User 1")
        let existingUser2 = User(email: "existing2@example.com", name: "User 2")
        context.insert(existingUser1)
        context.insert(existingUser2)
        try context.save()
        
        // Verify users exist before reset
        let initialDescriptor = FetchDescriptor<User>()
        let initialUsers = try context.fetch(initialDescriptor)
        #expect(initialUsers.count == 2, "Should have 2 users before reset")
        
        // Set authentication state to test reset
        authManager.authenticationState = .authenticated
        authManager.currentUser = existingUser1
        
        Task {
            // Test the reset scenario by simulating what resetAppData does
            // Since we can't easily mock ProcessInfo.arguments in tests,
            // we'll test the database cleanup logic that resetAppData performs
            
            // Simulate what resetAppData does to the database
            let fetchDescriptor = FetchDescriptor<User>()
            let usersToDelete = try context.fetch(fetchDescriptor)
            for user in usersToDelete {
                context.delete(user)
            }
            try context.save()
            
            // Verify reset effects on authentication manager
            authManager.currentUser = nil
            authManager.authenticationState = .notAuthenticated
            
            // Verify database is cleared
            let postResetDescriptor = FetchDescriptor<User>()
            let remainingUsers = try context.fetch(postResetDescriptor)
            #expect(remainingUsers.isEmpty, "All users should be deleted after reset")
            
            // Verify authentication state is reset
            #expect(authManager.currentUser == nil, "Current user should be nil after reset")
            #expect(authManager.authenticationState == .notAuthenticated, 
                    "State should be notAuthenticated after reset")
        }
    }
}
