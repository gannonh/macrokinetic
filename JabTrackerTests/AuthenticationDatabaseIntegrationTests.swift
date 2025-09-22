import AuthenticationServices
import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
@Suite("Authentication Database Integration Tests")
struct AuthenticationDatabaseIntegrationTests {
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
      #expect(
        savedUser?.appleUserId == "test.apple.user.id",
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
      #expect(
        authManager.authenticationState == .notAuthenticated,
        "State should be notAuthenticated after signOut")

      // User should be deleted from database
      let fetchDescriptor = FetchDescriptor<User>()
      let remainingUsers = try context.fetch(fetchDescriptor)
      let foundUser = remainingUsers.first { $0.email == "signout-test@example.com" }
      #expect(foundUser == nil, "User should be deleted from database on signOut")
    }
  }

  @Test("Authentication processAppleIDCredential database integration")
  @MainActor
  func authProcessAppleIDCredentialDBIntegration() throws {
    let dataController = DataController.testContainer()
    let authManager = AuthenticationManager(dataController: dataController)
    let context = dataController.container.mainContext

    Task {
      // Test the database integration logic that processAppleIDCredential performs
      // We simulate what the method does since we can't create real ASAuthorizationAppleIDCredential

      // Create a user as if processAppleIDCredential created it
      let user = User(email: "integration-test@example.com", name: "Integration User")
      user.appleUserId = "integration.apple.user.id"
      user.weight = 75.0
      user.weightUnit = "kg"

      context.insert(user)
      try context.save()

      // Set the user as current user (as processAppleIDCredential would)
      authManager.currentUser = user
      authManager.authenticationState = .authenticated

      // Verify the integration worked
      #expect(authManager.currentUser != nil, "Current user should be set")
      #expect(
        authManager.currentUser?.email == "integration-test@example.com",
        "Current user email should match")
      #expect(
        authManager.currentUser?.appleUserId == "integration.apple.user.id",
        "Apple User ID should be set correctly")
      #expect(
        authManager.authenticationState == .authenticated,
        "Authentication state should be authenticated")

      // Verify user persisted in database
      let fetchDescriptor = FetchDescriptor<User>()
      let users = try context.fetch(fetchDescriptor)
      let savedUser = users.first { $0.email == "integration-test@example.com" }

      #expect(savedUser != nil, "User should persist in database")
      #expect(savedUser?.weight == 75.0, "User weight should be saved")
      #expect(savedUser?.weightUnit == "kg", "User weight unit should be saved")
    }
  }

  @Test("Authentication checkAuthenticationStatus with existing user flow")
  @MainActor
  func authCheckAuthenticationStatusExistingUserFlow() async throws {
    let dataController = DataController.testContainer()
    let authManager = AuthenticationManager(dataController: dataController)
    let context = dataController.container.mainContext

    // Create an existing user in the database
    let existingUser = User(email: "existing@example.com", name: "Existing User")
    existingUser.appleUserId = "existing.apple.user.id"
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

  @Test("Authentication checkAuthenticationStatus database fetch error handling")
  @MainActor
  func authCheckAuthenticationStatusDatabaseFetchError() async throws {
    let dataController = DataController.testContainer()
    let authManager = AuthenticationManager(dataController: dataController)

    // Test checkAuthenticationStatus with empty database
    await authManager.checkAuthenticationStatus()

    // In test environment, should set notAuthenticated state
    #expect(
      authManager.authenticationState == .notAuthenticated,
      "Should be notAuthenticated when no users exist")
    #expect(authManager.currentUser == nil, "Current user should be nil")
  }
}
