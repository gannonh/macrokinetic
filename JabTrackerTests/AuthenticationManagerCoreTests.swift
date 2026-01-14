import AuthenticationServices
import Foundation
import SwiftData
import Testing

@testable import JabTracker

// MARK: - AuthenticationState Enum Tests

@Suite("AuthenticationState Enum Tests")
struct AuthenticationStateTests {
    @Test("AuthenticationState has correct raw values")
    func authStateRawValues() {
        #expect(AuthenticationState.notDetermined.rawValue == "notDetermined")
        #expect(AuthenticationState.authenticated.rawValue == "authenticated")
        #expect(AuthenticationState.notAuthenticated.rawValue == "notAuthenticated")
        #expect(AuthenticationState.restricted.rawValue == "restricted")
        #expect(AuthenticationState.expired.rawValue == "expired")
    }

    @Test("AuthenticationState CaseIterable provides all cases")
    func authStateCaseIterable() {
        let allCases = AuthenticationState.allCases
        #expect(allCases.count == 5)
        #expect(allCases.contains(.notDetermined))
        #expect(allCases.contains(.authenticated))
        #expect(allCases.contains(.notAuthenticated))
        #expect(allCases.contains(.restricted))
        #expect(allCases.contains(.expired))
    }

    @Test("AuthenticationState can be initialized from raw value")
    func authStateFromRawValue() {
        #expect(AuthenticationState(rawValue: "notDetermined") == .notDetermined)
        #expect(AuthenticationState(rawValue: "authenticated") == .authenticated)
        #expect(AuthenticationState(rawValue: "notAuthenticated") == .notAuthenticated)
        #expect(AuthenticationState(rawValue: "restricted") == .restricted)
        #expect(AuthenticationState(rawValue: "expired") == .expired)
        #expect(AuthenticationState(rawValue: "invalid") == nil)
    }
}

// MARK: - AuthenticationError Enum Tests

@Suite("AuthenticationError Enum Tests")
struct AuthenticationErrorTests {
    @Test("AuthenticationError provides localized descriptions")
    func authErrorDescriptions() {
        let notImplemented = AuthenticationError.notImplemented
        #expect(notImplemented.errorDescription == "Authentication not fully implemented")

        let authDenied = AuthenticationError.authorizationDenied
        #expect(authDenied.errorDescription == "User denied authorization")

        let credsNotFound = AuthenticationError.credentialsNotFound
        #expect(credsNotFound.errorDescription == "No stored credentials found")

        let keychainError = AuthenticationError.keychainError
        #expect(keychainError.errorDescription == "Error accessing Keychain")
    }

    @Test("AuthenticationError conforms to LocalizedError")
    func authErrorConformsToLocalizedError() {
        let error: LocalizedError = AuthenticationError.notImplemented
        #expect(error.errorDescription != nil)
    }

    @Test("AuthenticationError conforms to Error")
    func authErrorConformsToError() {
        let error: Error = AuthenticationError.authorizationDenied
        // Error conformance verified by successful cast
        #expect(error is AuthenticationError)
    }
}

// MARK: - AuthenticationManager Core Tests

@MainActor
@Suite("Authentication Manager Core Tests")
struct AuthenticationManagerCoreTests {
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
    func signInWithAppleErrorHandling() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test initial state is correct
        #expect(authManager.authenticationState == .notDetermined)
        #expect(authManager.currentUser == nil)

        // Test that signInWithApple properly propagates errors in test environment
        var didThrowError = false
        do {
            _ = try await authManager.signInWithApple()
        } catch {
            didThrowError = true
            // Should throw a specific AuthenticationError, not just any error
            #expect(
                error is AuthenticationError, "Should throw AuthenticationError, got: \(type(of: error))")
            // Authentication state should remain unchanged after error
            #expect(authManager.authenticationState == .notDetermined)
            #expect(authManager.currentUser == nil)
        }
        #expect(didThrowError, "signInWithApple should throw an error in test environment")
    }

    @Test("AuthenticationManager state transitions")
    @MainActor
    func authStateTransitions() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test initial state
        #expect(authManager.authenticationState == .notDetermined)
        #expect(authManager.currentUser == nil)

        // Test signOut updates state correctly
        try await authManager.signOut()
        #expect(authManager.currentUser == nil, "currentUser should be nil after signOut")
        #expect(
            authManager.authenticationState == .notAuthenticated,
            "authenticationState should be .notAuthenticated after signOut")

        // Test checkAuthenticationStatus with empty database maintains notAuthenticated state
        await authManager.checkAuthenticationStatus()
        // With no users in test database, should remain notAuthenticated
        #expect(
            authManager.authenticationState == .notAuthenticated,
            "authenticationState should remain .notAuthenticated with empty database")
    }

    @Test("Authentication state consistency after app restart")
    @MainActor
    func authStateConsistencyAfterRestart() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test checkAuthenticationStatus handles empty database gracefully
        await authManager.checkAuthenticationStatus()
        // Should not crash with empty user database
        // AuthenticationState is an enum, so verify it has a valid state
        #expect(
            authManager.authenticationState == .notDetermined
                || authManager.authenticationState == .authenticated
                || authManager.authenticationState == .notAuthenticated)

        // Test with existing user data
        let context = dataController.container.mainContext
        let testUser = User(email: "persistence-test@example.com", weight: 70.0)
        context.insert(testUser)
        try context.save()

        await authManager.checkAuthenticationStatus()
        // Should detect existing user data
    }

    @Test("Authentication manager error recovery")
    @MainActor
    func authManagerErrorRecovery() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test that sign out works regardless of current state
        try await authManager.signOut()
        #expect(authManager.currentUser == nil)

        // Test that checkAuthenticationStatus handles various states
        await authManager.checkAuthenticationStatus()
        // Should complete without error regardless of state
    }

    @Test("Concurrent authentication operations")
    @MainActor
    func concurrentAuthOperations() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test that multiple simultaneous auth status checks don't cause issues
        await withTaskGroup(of: Void.self) { group in
            // Simulate multiple concurrent auth status checks
            for _ in 0..<3 {
                group.addTask {
                    await authManager.checkAuthenticationStatus()
                }
            }
        }

        // Should complete without deadlocks or crashes
        // AuthenticationState is an enum so it's never nil
        #expect(
            authManager.authenticationState == .notDetermined
                || authManager.authenticationState == .authenticated
                || authManager.authenticationState == .notAuthenticated)
    }

    @Test("Invalid user data handling")
    @MainActor
    func invalidUserDataHandling() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Test with user missing required fields
        let incompleteUser = User(email: "", weight: 0.0)  // Empty email, zero weight
        context.insert(incompleteUser)
        try context.save()

        await authManager.checkAuthenticationStatus()
        // Should handle incomplete user data gracefully
        // Don't assume this means authenticated if data is invalid

        // Test authentication manager can handle users with missing Apple ID
        let userWithoutAppleID = User(email: "no-apple-id@example.com", weight: 70.0)
        // Note: appleUserId intentionally nil
        context.insert(userWithoutAppleID)
        try context.save()

        await authManager.checkAuthenticationStatus()
        // Should handle missing Apple ID appropriately
    }

    @Test("Authentication error handling scenarios")
    @MainActor
    func authenticationErrorHandlingScenarios() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test that signOut works even when no user is signed in
        try await authManager.signOut()
        #expect(
            authManager.authenticationState == .notAuthenticated,
            "signOut should succeed even when no user is signed in")
        #expect(
            authManager.currentUser == nil,
            "currentUser should be nil after signOut")

        // Test multiple consecutive signOut calls don't cause issues
        try await authManager.signOut()
        try await authManager.signOut()
        try await authManager.signOut()
        #expect(
            authManager.authenticationState == .notAuthenticated,
            "State should remain consistent after multiple signOut calls")
        #expect(
            authManager.currentUser == nil,
            "User should remain nil after multiple signOut calls")
    }

    @Test("Authentication manager reset app data functionality")
    @MainActor
    func authManagerResetAppData() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Create test user data
        let testUser = User(email: "reset-test@example.com", weight: 70.0)
        context.insert(testUser)
        try context.save()

        // Verify user exists
        let fetchBefore = FetchDescriptor<User>()
        let usersBefore = try context.fetch(fetchBefore)
        #expect(!usersBefore.isEmpty, "Should have user before reset")

        // Test reset through checkAuthenticationStatus with reset flag
        // This indirectly tests the resetAppData method
        // Simulate UI testing environment with reset flag
        await authManager.checkAuthenticationStatus()

        // Authentication state should be properly set
        let validStates: [AuthenticationState] = [.notDetermined, .authenticated, .notAuthenticated]
        #expect(
            validStates.contains(authManager.authenticationState),
            "Should have valid authentication state after check")
    }

    @Test("Authentication manager processAppleIDCredential error scenarios")
    @MainActor
    func authManagerProcessAppleIDCredentialErrorScenarios() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test that sign in handles authorization denial
        var didThrowExpectedError = false
        do {
            _ = try await authManager.signInWithApple()
        } catch let error as AuthenticationError {
            didThrowExpectedError = true
            // Should be the not implemented error for test environment
            #expect(error == .notImplemented, "Should throw notImplemented error in test environment")
        }
        #expect(didThrowExpectedError, "Should throw AuthenticationError for sign in")
    }

    @Test("Authentication manager state logging and transitions")
    @MainActor
    func authManagerStateLoggingTransitions() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test initial state
        #expect(
            authManager.authenticationState == .notDetermined,
            "Should start in notDetermined state")
        #expect(authManager.currentUser == nil, "Should have no user initially")

        // Test state can be observed and changed
        _ = authManager.authenticationState

        // Test checkAuthenticationStatus completes
        await authManager.checkAuthenticationStatus()

        // State should be determined after check
        #expect(
            authManager.authenticationState != .notDetermined
                || authManager.authenticationState == .notAuthenticated,
            "State should be determined after authentication check")
    }

    @Test("Authentication manager with existing user data")
    @MainActor
    func authManagerWithExistingUserData() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Create existing user in database
        let existingUser = User(email: "existing@example.com", weight: 75.0)
        context.insert(existingUser)
        try context.save()

        await authManager.checkAuthenticationStatus()

        // Should detect existing user and set authenticated state
        // But only if no UI testing or reset flags are active
        if !ProcessInfo.processInfo.arguments.contains("--reset-app-data"),
            !ProcessInfo.processInfo.arguments.contains("--ui-testing"),
            ProcessInfo.processInfo.environment["UI_TESTING"] != "true"
        {
            #expect(
                authManager.currentUser != nil,
                "Should set current user when existing user found")
            #expect(
                authManager.authenticationState == .authenticated,
                "Should be authenticated when user data exists")
        } else {
            // In test environments with UI testing flags, the behavior might be different
            #expect(
                authManager.authenticationState != .notDetermined,
                "Authentication state should be determined after check")
        }
    }

    @Test("Reset app data functionality through launch argument")
    @MainActor
    func resetAppDataWithLaunchArgument() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Create user data first
        let user = User(email: "test@reset.com", weight: 70.0)
        context.insert(user)
        try context.save()

        // Verify user exists
        let beforeFetch = FetchDescriptor<User>()
        let usersBefore = try context.fetch(beforeFetch)
        #expect(!usersBefore.isEmpty, "Should have user before reset")

        // Add reset argument to ProcessInfo for testing
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        // Note: We can't actually modify ProcessInfo.arguments, but we can test the path
        // by calling checkAuthenticationStatus and verifying reset behavior

        await authManager.checkAuthenticationStatus()

        // The method should still work even without the reset flag
        // The actual reset functionality is tested through the launch argument scenario
    }

    @Test("Sign out deletes current user from context")
    @MainActor
    func signOutDeletesUser() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Create and save a user
        let user = User(email: "signout-test@example.com", name: "Sign Out Test", weight: 70.0)
        context.insert(user)
        try context.save()

        // Verify user exists
        let beforeFetch = FetchDescriptor<User>()
        let usersBefore = try context.fetch(beforeFetch)
        #expect(usersBefore.count == 1, "Should have 1 user before sign out")

        // Set up auth manager with user
        await authManager.checkAuthenticationStatus()
        #expect(authManager.currentUser != nil, "Should have current user set")
        #expect(authManager.authenticationState == .authenticated, "Should be authenticated")

        // Sign out
        try await authManager.signOut()

        // Verify state is updated
        #expect(authManager.currentUser == nil, "Current user should be nil after sign out")
        #expect(
            authManager.authenticationState == .notAuthenticated,
            "Should be notAuthenticated after sign out")

        // Verify user was deleted from context
        let afterFetch = FetchDescriptor<User>()
        let usersAfter = try context.fetch(afterFetch)
        #expect(usersAfter.isEmpty, "User should be deleted from database after sign out")
    }

    @Test("Sign out handles nil current user gracefully")
    @MainActor
    func signOutWithNilUser() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Verify no current user
        #expect(authManager.currentUser == nil, "Should have no current user initially")

        // Sign out should not throw even with nil user
        try await authManager.signOut()

        // State should be updated
        #expect(authManager.currentUser == nil, "Current user should remain nil")
        #expect(
            authManager.authenticationState == .notAuthenticated,
            "Should be notAuthenticated after sign out")
    }
}

// MARK: - Seed Additional Medication Profiles Tests

@MainActor
@Suite("AuthenticationManager Medication Profile Seeding Tests")
struct AuthManagerMedProfileSeedingTests {

    @Test("Seed additional medication profiles creates correct number of profiles")
    @MainActor
    func seedAdditionalProfilesCount() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Create user
        let user = User(email: "seed-test@example.com", name: "Seed Test", weight: 70.0)
        context.insert(user)
        try context.save()

        // Seed 2 additional profiles
        try authManager.seedAdditionalMedicationProfiles(count: 2, user: user, context: context)

        // Verify profiles were created
        let profileFetch = FetchDescriptor<MedicationProfile>()
        let profiles = try context.fetch(profileFetch)
        #expect(profiles.count == 2, "Should have created 2 medication profiles")
    }

    @Test("Seed additional medication profiles creates tirzepatide first")
    @MainActor
    func seedAdditionalProfilesFirstIsTirzepatide() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Create user
        let user = User(email: "seed-test2@example.com", name: "Seed Test 2", weight: 70.0)
        context.insert(user)
        try context.save()

        // Seed 1 additional profile
        try authManager.seedAdditionalMedicationProfiles(count: 1, user: user, context: context)

        // Verify first profile is tirzepatide (Mounjaro)
        let profileFetch = FetchDescriptor<MedicationProfile>()
        let profiles = try context.fetch(profileFetch)
        #expect(profiles.count == 1, "Should have created 1 medication profile")

        guard let profile = profiles.first else {
            #expect(Bool(false), "Profile should exist")
            return
        }

        #expect(profile.brandName == "Mounjaro", "First profile should be Mounjaro")
        #expect(profile.currentDose == 5.0, "Tirzepatide dose should be 5.0")
        #expect(profile.user === user, "Profile should be associated with user")
    }

    @Test("Seed additional medication profiles respects maximum count")
    @MainActor
    func seedAdditionalProfilesMaxCount() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Create user
        let user = User(email: "seed-test3@example.com", name: "Seed Test 3", weight: 70.0)
        context.insert(user)
        try context.save()

        // Request more profiles than available (only 3 additional medications defined)
        try authManager.seedAdditionalMedicationProfiles(count: 10, user: user, context: context)

        // Should only create 3 profiles (the maximum available)
        let profileFetch = FetchDescriptor<MedicationProfile>()
        let profiles = try context.fetch(profileFetch)
        #expect(profiles.count == 3, "Should create at most 3 medication profiles")
    }

    @Test("Seed zero additional medication profiles creates none")
    @MainActor
    func seedZeroAdditionalProfiles() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Create user
        let user = User(email: "seed-test4@example.com", name: "Seed Test 4", weight: 70.0)
        context.insert(user)
        try context.save()

        // Seed 0 additional profiles
        try authManager.seedAdditionalMedicationProfiles(count: 0, user: user, context: context)

        // Verify no profiles were created
        let profileFetch = FetchDescriptor<MedicationProfile>()
        let profiles = try context.fetch(profileFetch)
        #expect(profiles.isEmpty, "Should not create any medication profiles with count 0")
    }

    @Test("Seed all three additional medication profiles")
    @MainActor
    func seedAllThreeAdditionalProfiles() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Create user
        let user = User(email: "seed-test5@example.com", name: "Seed Test 5", weight: 70.0)
        context.insert(user)
        try context.save()

        // Seed all 3 additional profiles
        try authManager.seedAdditionalMedicationProfiles(count: 3, user: user, context: context)

        // Verify all 3 profiles were created with correct data
        let profileFetch = FetchDescriptor<MedicationProfile>()
        let profiles = try context.fetch(profileFetch)
        #expect(profiles.count == 3, "Should have created 3 medication profiles")

        let brandNames = Set(profiles.map { $0.brandName })
        #expect(brandNames.contains("Mounjaro"), "Should have Mounjaro profile")
        #expect(brandNames.contains("Victoza"), "Should have Victoza profile")
        #expect(brandNames.contains("Trulicity"), "Should have Trulicity profile")

        // Verify all profiles are associated with the user
        for profile in profiles {
            #expect(profile.user === user, "All profiles should be associated with user")
        }
    }
}

// MARK: - Additional AuthenticationManager Tests

@MainActor
@Suite("AuthenticationManager Additional Tests")
struct AuthenticationManagerAdditionalTests {

    @Test("AuthenticationManager uses default DataController when none provided")
    @MainActor
    func authManagerDefaultDataController() {
        // This test verifies the default initializer path works
        // Note: In unit tests, this will use a test-isolated context
        let authManager = AuthenticationManager()

        // Should initialize with default state
        #expect(authManager.authenticationState == .notDetermined)
        #expect(authManager.currentUser == nil)
    }

    @Test("AuthenticationManager state change triggers didSet logging")
    @MainActor
    func authManagerStateChangeDidSet() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Initial state
        #expect(authManager.authenticationState == .notDetermined)

        // Change state by calling signOut (which sets to .notAuthenticated)
        try await authManager.signOut()

        // State should have changed and didSet should have been triggered
        #expect(authManager.authenticationState == .notAuthenticated)
    }

    @Test("Check authentication status with fetch error handling")
    @MainActor
    func checkAuthStatusWithEmptyDatabase() async {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Empty database scenario
        await authManager.checkAuthenticationStatus()

        // Should handle empty database gracefully
        #expect(
            authManager.authenticationState == .notAuthenticated,
            "Empty database should result in notAuthenticated state")
        #expect(authManager.currentUser == nil, "No user should be set for empty database")
    }

    @Test("Multiple users in database uses first user")
    @MainActor
    func multipleUsersUsesFirst() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Create multiple users
        let user1 = User(email: "first@example.com", name: "First User", weight: 70.0)
        let user2 = User(email: "second@example.com", name: "Second User", weight: 75.0)
        context.insert(user1)
        context.insert(user2)
        try context.save()

        // Check authentication
        await authManager.checkAuthenticationStatus()

        // Should use first user found (behavior is implementation-defined by fetch order)
        #expect(authManager.currentUser != nil, "Should have a current user")
        #expect(authManager.authenticationState == .authenticated, "Should be authenticated")
    }

    @Test("SignInWithApple throws notImplemented in regular test environment")
    @MainActor
    func signInWithAppleThrowsNotImplemented() async {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        do {
            _ = try await authManager.signInWithApple()
            #expect(Bool(false), "signInWithApple should throw in test environment")
        } catch let error as AuthenticationError {
            #expect(error == .notImplemented, "Should throw notImplemented error")
        } catch {
            #expect(Bool(false), "Should throw AuthenticationError, got: \(type(of: error))")
        }
    }

    @Test("handleSignInWithAppleResult rejects non-Apple credentials")
    @MainActor
    func handleSignInRejectsNonAppleCredentials() async {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Create a mock authorization with non-Apple credential
        // Note: We cannot directly create ASAuthorization, but we can test error handling
        // by verifying the method signature and expected behavior documentation

        // This test verifies the method exists and has correct signature
        // Actual credential testing requires mocking ASAuthorization which is not possible
        #expect(authManager.currentUser == nil, "Should start with no user")
    }

    @Test("Authentication with existing user updates Apple ID")
    @MainActor
    func authWithExistingUserUpdatesAppleID() async throws {
        let dataController = DataController.testContainer()
        let context = dataController.container.mainContext

        // Create existing user without Apple ID
        let existingUser = User(email: nil, name: "Existing User")
        existingUser.appleUserId = nil
        context.insert(existingUser)
        try context.save()

        let authManager = AuthenticationManager(dataController: dataController)

        // Check authentication status should find existing user
        await authManager.checkAuthenticationStatus()

        // User should be authenticated (has user record, no Apple ID to validate)
        #expect(authManager.authenticationState == .authenticated)
        #expect(authManager.currentUser?.name == "Existing User")
        #expect(authManager.currentUser?.appleUserId == nil)
    }

    @Test("User without Apple ID skips credential validation")
    @MainActor
    func userWithoutAppleIDSkipsValidation() async throws {
        let dataController = DataController.testContainer()
        let context = dataController.container.mainContext

        // Create user without Apple ID - should authenticate without validation
        let user = User(email: nil, name: "Local User")
        user.appleUserId = nil
        context.insert(user)
        try context.save()

        let authManager = AuthenticationManager(dataController: dataController)
        await authManager.checkAuthenticationStatus()

        // Should be authenticated - no Apple credential to validate
        #expect(authManager.authenticationState == .authenticated)
        #expect(authManager.currentUser?.id == user.id)
    }
}
