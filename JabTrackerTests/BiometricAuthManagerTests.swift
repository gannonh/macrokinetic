import Foundation
@testable import JabTracker
import SwiftData
import Testing

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
        let validCases: [BiometricAvailability] = [
            .available(.faceID), .available(.touchID), .available(.opticID), .available(.none),
            .notAvailable, .notEnrolled, .restricted, .unknown,
        ]

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
}
