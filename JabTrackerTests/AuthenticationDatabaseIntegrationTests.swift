import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
@Suite("Authentication Database Integration Tests")
struct AuthenticationDatabaseIntegrationTests {
    @Test("Authentication checkAuthenticationStatus with existing user flow")
    @MainActor
    func authCheckAuthenticationStatusExistingUserFlow() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Create an existing user in the database.
        let existingUser = User(email: "existing@example.com", name: "Existing User")
        context.insert(existingUser)
        try context.save()

        // Verify user was created successfully before calling checkAuthenticationStatus
        let beforeFetchDescriptor = FetchDescriptor<User>()
        let usersBefore = try context.fetch(beforeFetchDescriptor)
        #expect(!usersBefore.isEmpty, "Should have user before checkAuthenticationStatus")

        // Test checkAuthenticationStatus with existing user
        await authManager.checkAuthenticationStatus()

        // The test should verify the authentication manager's state, not just database state
        // Because checkAuthenticationStatus might reset data in test environments
        #expect(
            authManager.authenticationState != .notDetermined,
            "Authentication state should be determined after check")

        // If no UI testing flags are set, the user should remain and be set as current user
        if !ProcessInfo.processInfo.arguments.contains("--reset-app-data"),
            !ProcessInfo.processInfo.arguments.contains("--ui-testing"),
            ProcessInfo.processInfo.environment["UI_TESTING"] != "true"
        {
            #expect(authManager.currentUser != nil, "Should set current user when existing user found")
            #expect(
                authManager.authenticationState == .authenticated,
                "Should be authenticated when user exists")
        }
    }

    @Test("Authentication checkAuthenticationStatus creates blank user when database is empty")
    @MainActor
    func authCheckAuthenticationStatusEmptyDatabase() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test checkAuthenticationStatus with empty database
        await authManager.checkAuthenticationStatus()

        // With no sign-in, an empty database gets a blank local User
        #expect(
            authManager.authenticationState == .authenticated,
            "Should be authenticated when no users exist")
        #expect(authManager.currentUser != nil, "Current user should be created")
    }
}
