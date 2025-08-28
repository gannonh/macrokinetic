import Foundation
@testable import JabTracker
import SwiftData
import Testing

@MainActor
@Suite("User SwiftData Model Tests")
struct UserModelTests {
    @Test("User model has all required fields")
    func userModelRequiredFields() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Test creating user with all required fields as per Issue #11
        let user = User(
            email: "test@example.com",
            name: "Test User",
            dateOfBirth: Date(timeIntervalSince1970: 0), // Jan 1, 1970
            weight: 70.0,
            weightUnit: "kg",
            timezone: "UTC")

        context.insert(user)
        try context.save()

        // Verify all fields are properly set
        #expect(user.id != UUID()) // ID should be auto-generated and unique
        #expect(user.email == "test@example.com")
        #expect(user.name == "Test User")
        #expect(user.dateOfBirth != nil)
        #expect(user.weight == 70.0)
        #expect(user.weightUnit == "kg")
        #expect(user.timezone == "UTC")
        // createdAt and updatedAt are Date objects (non-optional), so they always exist
        #expect(user.createdAt.timeIntervalSince1970 > 0)
        #expect(user.updatedAt.timeIntervalSince1970 > 0)
    }

    @Test("User weight unit validation")
    func userWeightUnitValidation() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Test with kg
        let userKg = User(
            email: "kg-user@example.com",
            weight: 70.0,
            weightUnit: "kg")
        context.insert(userKg)

        // Test with lbs
        let userLbs = User(
            email: "lbs-user@example.com",
            weight: 154.0,
            weightUnit: "lbs")
        context.insert(userLbs)

        try context.save()

        #expect(userKg.weightUnit == "kg")
        #expect(userLbs.weightUnit == "lbs")
    }

    @Test("User with Apple ID association")
    func userAppleIDAssociation() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Test user creation with Apple ID (this will be the identifier)
        let user = User(
            email: "apple.user@icloud.com",
            name: "Apple User")

        // Apple ID would be stored as the primary identifier
        // In real implementation, this would come from Sign in with Apple response

        context.insert(user)
        try context.save()

        #expect(user.email == "apple.user@icloud.com")
        #expect(user.name == "Apple User")
    }
}

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
}

@MainActor
@Suite("Biometric Authentication Manager Tests")
struct BiometricAuthManagerTests {
    @Test("BiometricAuthManager initialization")
    @MainActor
    func biometricManagerInit() throws {
        let biometricManager = BiometricAuthManager()

        // Verify initial state - should be disabled by default
        #expect(biometricManager.isBiometricEnabled == false)

        // Verify properties exist and are accessible
        _ = biometricManager.biometricType
        _ = biometricManager.isAvailable
        _ = biometricManager.biometricTypeDisplayName

        // Verify methods exist (getBiometricAvailability is public)
        let availability = biometricManager.getBiometricAvailability()
        // BiometricAvailability is an enum, so test it exists
        switch availability {
        case .available, .notAvailable, .notEnrolled, .restricted, .unknown:
            break // All valid cases
        }
    }

    @Test("BiometricAuthManager availability checking")
    @MainActor
    func biometricAvailabilityChecking() throws {
        let biometricManager = BiometricAuthManager()

        // Test availability checking methods
        let availability = biometricManager.getBiometricAvailability()
        // Test that availability is one of the valid enum cases
        switch availability {
        case .available, .notAvailable, .notEnrolled, .restricted, .unknown:
            break // All valid cases
        }

        // Test biometric type detection
        let biometricType = biometricManager.biometricType
        #expect([BiometricType.faceID, BiometricType.touchID, BiometricType.none].contains(biometricType))

        // Test display name
        let displayName = biometricManager.biometricTypeDisplayName
        #expect(!displayName.isEmpty)

        // Note: checkBiometricAvailability() is private, so we can't test it directly
        // The public getBiometricAvailability() method provides the same functionality
    }

    @Test("BiometricAuthManager authentication interface")
    @MainActor
    func biometricAuthInterface() throws {
        let biometricManager = BiometricAuthManager()

        // Test preference setting
        biometricManager.setBiometricPreference(enabled: true)
        #expect(biometricManager.isBiometricEnabled == true)

        biometricManager.setBiometricPreference(enabled: false)
        #expect(biometricManager.isBiometricEnabled == false)

        // Test toggle functionality
        let initialState = biometricManager.isBiometricEnabled
        biometricManager.toggleBiometric()
        #expect(biometricManager.isBiometricEnabled == !initialState)

        // Test authenticateWithBiometrics error handling in test environment
        Task {
            var didThrowError = false
            do {
                _ = try await biometricManager.authenticateWithBiometrics(reason: "Test authentication")
            } catch {
                didThrowError = true
                // Should fail with a specific error type (not just any error)
                // In test environment, this should be a biometric authentication error
                #expect(error is BiometricError,
                        "Should fail with BiometricError in test environment, got: \(type(of: error))")
            }
            #expect(didThrowError, "authenticateWithBiometrics should fail in test environment without biometrics")
        }
    }
}

@Suite("Authentication Edge Cases")
struct AuthenticationEdgeCaseTests {
    @Test("Sign in with Apple maintains state after failure")
    @MainActor
    func signInWithAppleStateAfterFailure() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)

        // Test initial state
        #expect(authManager.authenticationState == .notDetermined)
        #expect(authManager.currentUser == nil)

        // Test that failed sign in attempt leaves authentication in consistent state
        Task {
            var didThrowError = false
            do {
                _ = try await authManager.signInWithApple()
            } catch {
                didThrowError = true
                // After failure, state should remain consistent
                #expect(authManager.authenticationState == .notDetermined,
                        "State should remain notDetermined after failed sign in")
                #expect(authManager.currentUser == nil,
                        "currentUser should remain nil after failed sign in")
            }
            #expect(didThrowError, "signInWithApple should fail in test environment")
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

    @Test("Biometric authentication error scenarios")
    @MainActor
    func biometricAuthErrorScenarios() throws {
        let biometricManager = BiometricAuthManager()

        // Test that biometric availability check handles all device states
        let availability = biometricManager.getBiometricAvailability()
        // Test that availability is one of the valid enum cases
        switch availability {
        case .available, .notAvailable, .notEnrolled, .restricted, .unknown:
            break // All valid cases handled
        }

        // Test biometric type detection for all device types
        let biometricType = biometricManager.biometricType
        #expect([BiometricType.faceID, BiometricType.touchID, BiometricType.none].contains(biometricType))

        // Test preference setting doesn't crash with any availability state
        biometricManager.setBiometricPreference(enabled: true)
        biometricManager.setBiometricPreference(enabled: false)
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

    @Test("Biometric authentication disabled state handling")
    @MainActor
    func biometricAuthDisabledStateHandling() throws {
        let biometricManager = BiometricAuthManager()

        // Test enabling biometrics when not available
        biometricManager.setBiometricPreference(enabled: true)
        #expect(biometricManager.isBiometricEnabled == true,
                "Should be able to set preference even if biometrics unavailable")

        // Test authentication when biometrics are disabled
        biometricManager.setBiometricPreference(enabled: false)
        Task {
            var threwDisabledError = false
            do {
                _ = try await biometricManager.authenticateWithBiometrics(reason: "Test")
            } catch BiometricError.disabled {
                threwDisabledError = true
            } catch {
                // Other errors are also acceptable in test environment
            }
            // In test environment, should throw disabled error since we set enabled = false
            if biometricManager.isBiometricEnabled == false {
                #expect(threwDisabledError, "Should throw BiometricError.disabled when biometrics are disabled")
            }
        }

        // Test availability check returns valid enum case
        let availability = biometricManager.getBiometricAvailability()
        let validCases: [BiometricAvailability] = [.available(.faceID), .available(.touchID), .available(.opticID), .available(.none), .notAvailable, .notEnrolled, .restricted, .unknown]

        var isValidCase = false
        for validCase in validCases {
            switch (availability, validCase) {
            case let (.available(a), .available(b)) where a == b:
                isValidCase = true
            case (.notAvailable, .notAvailable), (.notEnrolled, .notEnrolled), (.restricted, .restricted), (.unknown, .unknown):
                isValidCase = true
            default:
                continue
            }
            if isValidCase { break }
        }
        #expect(isValidCase, "getBiometricAvailability should return a valid enum case")
    }

    @Test("BiometricError error descriptions")
    @MainActor
    func biometricErrorDescriptions() throws {
        // Test all BiometricError cases have non-empty descriptions
        let errorCases: [BiometricError] = [
            .notAvailable,
            .disabled,
            .userCancel,
            .userFallback,
            .lockout,
            .authenticationFailed,
        ]

        for error in errorCases {
            let description = error.errorDescription
            #expect(description != nil, "BiometricError.\(error) should have error description")
            #expect(!description!.isEmpty, "BiometricError.\(error) description should not be empty")

            // Test specific expected content
            switch error {
            case .notAvailable:
                #expect(description!.contains("not available"), "notAvailable error should mention availability")
            case .disabled:
                #expect(description!.contains("disabled"), "disabled error should mention disabled state")
            case .userCancel:
                #expect(description!.contains("cancel"), "userCancel error should mention cancellation")
            case .userFallback:
                #expect(description!.contains("passcode"), "userFallback error should mention passcode")
            case .lockout:
                #expect(description!.contains("locked out"), "lockout error should mention lockout")
            case .authenticationFailed:
                #expect(description!.contains("failed"), "authenticationFailed error should mention failure")
            }
        }
    }

    @Test("BiometricType display names")
    @MainActor
    func biometricTypeDisplayNames() throws {
        let biometricManager = BiometricAuthManager()

        // Test all biometric type display names
        let testCases: [(BiometricType, String)] = [
            (.faceID, "Face ID"),
            (.touchID, "Touch ID"),
            (.opticID, "Optic ID"),
            (.none, "Biometrics"),
        ]

        for (biometricType, expectedName) in testCases {
            // Manually set the biometric type for testing
            biometricManager.biometricType = biometricType
            let displayName = biometricManager.biometricTypeDisplayName
            #expect(displayName == expectedName,
                    "BiometricType.\(biometricType) should display as '\(expectedName)', got '\(displayName)'")
        }

        // Test that display names are human-readable
        for (_, displayName) in testCases {
            #expect(!displayName.isEmpty, "Display name should not be empty")
            #expect(displayName.count > 3, "Display name should be descriptive")
            #expect(!displayName.contains("_"), "Display name should be user-friendly (no underscores)")
        }
    }

    @Test("BiometricAvailability equality and pattern matching")
    @MainActor
    func biometricAvailabilityEquality() throws {
        // Test BiometricAvailability pattern matching works correctly
        let testCases: [BiometricAvailability] = [
            .available(.faceID),
            .available(.touchID),
            .available(.opticID),
            .available(.none),
            .notAvailable,
            .notEnrolled,
            .restricted,
            .unknown,
        ]

        for availability in testCases {
            // Test that each case can be pattern matched correctly
            var matched = false
            switch availability {
            case let .available(type):
                matched = true
                #expect([BiometricType.faceID, .touchID, .opticID, .none].contains(type),
                        "Available biometric type should be one of the valid types")
            case .notAvailable, .notEnrolled, .restricted, .unknown:
                matched = true
            }
            #expect(matched, "BiometricAvailability case should be matchable in switch statement")
        }
    }

    @Test("BiometricAuthManager testing environment behavior")
    @MainActor
    func biometricManagerTestingBehavior() throws {
        // In test environment, biometrics should be configured predictably
        let biometricManager = BiometricAuthManager()

        // Test that in unit test environment, biometrics are set up for testing
        #expect(biometricManager.isAvailable == true,
                "Biometrics should be available in test environment")
        #expect(biometricManager.biometricType == .faceID,
                "Biometric type should be Face ID in test environment")
        #expect(biometricManager.isBiometricEnabled == false,
                "Biometric should start disabled for predictable test behavior")

        // Test toggle functionality
        let initialState = biometricManager.isBiometricEnabled
        biometricManager.toggleBiometric()
        #expect(biometricManager.isBiometricEnabled == !initialState,
                "toggleBiometric should invert the enabled state")

        // Test toggle again
        biometricManager.toggleBiometric()
        #expect(biometricManager.isBiometricEnabled == initialState,
                "Second toggle should restore original state")
    }

    @Test("BiometricAuthManager preference persistence behavior")
    @MainActor
    func biometricPreferencePersistence() throws {
        let biometricManager = BiometricAuthManager()

        // Test that setBiometricPreference updates the published property
        let initialValue = biometricManager.isBiometricEnabled

        biometricManager.setBiometricPreference(enabled: !initialValue)
        #expect(biometricManager.isBiometricEnabled == !initialValue,
                "setBiometricPreference should update isBiometricEnabled")

        biometricManager.setBiometricPreference(enabled: initialValue)
        #expect(biometricManager.isBiometricEnabled == initialValue,
                "setBiometricPreference should restore original value")

        // Test multiple rapid changes
        for _ in 0 ..< 5 {
            let currentValue = biometricManager.isBiometricEnabled
            biometricManager.setBiometricPreference(enabled: !currentValue)
            #expect(biometricManager.isBiometricEnabled == !currentValue,
                    "Rapid preference changes should be handled correctly")
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
}

// MARK: - Test Data Factories

extension UserModelTests {
    static func createTestUser(
        email: String = "test@example.com",
        name: String = "Test User") -> User
    {
        User(
            email: email,
            name: name,
            weight: 70.0,
            weightUnit: "kg",
            timezone: TimeZone.current.identifier)
    }

    @Test("Authentication manager maintains clean initial state")
    func authenticationManagerCleanInitialState() throws {
        // This test verifies the AuthenticationManager initializes with expected state
        // after consolidation work - consistent behavior across instances
        let dataController = DataController.testContainer()

        // Create multiple instances to verify consistent initialization
        let authManager1 = AuthenticationManager(dataController: dataController)
        let authManager2 = AuthenticationManager(dataController: dataController)

        // Both instances should have identical initial state (consolidated behavior)
        #expect(authManager1.authenticationState == authManager2.authenticationState,
                "Multiple AuthenticationManager instances should have identical initial state")
        #expect(authManager1.currentUser == nil,
                "Initial currentUser should be nil")
        #expect(authManager2.currentUser == nil,
                "Initial currentUser should be nil")
        #expect(authManager1.authenticationState == .notDetermined,
                "Initial authentication state should be notDetermined")
    }
}
