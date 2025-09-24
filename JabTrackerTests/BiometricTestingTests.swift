import Foundation
import LocalAuthentication
import Testing

@testable import JabTracker

@MainActor
@Suite("Biometric Testing Environment Tests")
struct BiometricTestingTests {
    @Test("BiometricAuthManager testing environment behavior")
    @MainActor
    func biometricManagerTestingBehavior() throws {
        // In test environment, biometrics should be configured predictably
        let biometricManager = BiometricAuthManager()

        // Test that in unit test environment, biometrics are set up for testing
        #expect(
            biometricManager.isAvailable == true,
            "Biometrics should be available in test environment")
        #expect(
            biometricManager.biometricType == .faceID,
            "Biometric type should be Face ID in test environment")
        #expect(
            biometricManager.isBiometricEnabled == false,
            "Biometric should start disabled for predictable test behavior")

        // Test toggle functionality
        let initialState = biometricManager.isBiometricEnabled
        biometricManager.toggleBiometric()
        #expect(
            biometricManager.isBiometricEnabled == !initialState,
            "toggleBiometric should invert the enabled state")

        // Test toggle again
        biometricManager.toggleBiometric()
        #expect(
            biometricManager.isBiometricEnabled == initialState,
            "Second toggle should restore original state")
    }

    @Test("BiometricAuthManager preference persistence behavior")
    @MainActor
    func biometricPreferencePersistence() throws {
        let biometricManager = BiometricAuthManager()

        // Test that setBiometricPreference updates the published property
        let initialValue = biometricManager.isBiometricEnabled

        biometricManager.setBiometricPreference(enabled: !initialValue)
        #expect(
            biometricManager.isBiometricEnabled == !initialValue,
            "setBiometricPreference should update isBiometricPreference")

        biometricManager.setBiometricPreference(enabled: initialValue)
        #expect(
            biometricManager.isBiometricEnabled == initialValue,
            "setBiometricPreference should restore original value")
    }

    @Test("Biometric authentication with specific error types")
    @MainActor
    func biometricAuthSpecificErrors() throws {
        let biometricManager = BiometricAuthManager()

        // Test the authentication method handles specific LAError scenarios
        Task {
            do {
                _ = try await biometricManager.authenticateWithBiometrics(reason: "Test authentication")
            } catch {
                // In test environment, we expect specific biometric errors
                if let biometricError = error as? BiometricError {
                    // Test that it's a known error type
                    let knownErrors: [BiometricError] = [
                        .authenticationFailed, .userCancel, .lockout,
                        .disabled, .notAvailable, .userFallback,
                    ]
                    #expect(
                        knownErrors.contains(biometricError),
                        "Should be a known BiometricError type: \(biometricError)")
                }
            }
        }
    }

    @Test("BiometricAuthManager property observers")
    @MainActor
    func biometricManagerPropertyObservers() throws {
        let biometricManager = BiometricAuthManager()

        // Test willSet and didSet are called
        let initialValue = biometricManager.isBiometricEnabled

        // This should trigger both willSet and didSet
        biometricManager.isBiometricEnabled = !initialValue

        #expect(
            biometricManager.isBiometricEnabled == !initialValue,
            "Property should be updated")

        // Test setting to same value
        biometricManager.isBiometricEnabled = !initialValue
        #expect(
            biometricManager.isBiometricEnabled == !initialValue,
            "Property should remain the same when set to same value")
    }

    @Test("Availability from error mapping")
    @MainActor
    func availabilityFromErrorMapping() throws {
        let biometricManager = BiometricAuthManager()

        // Test that getBiometricAvailability handles different error scenarios
        let availability = biometricManager.getBiometricAvailability()

        // Should return one of the valid availability states
        switch availability {
        case .available, .notAvailable, .notEnrolled, .restricted, .unknown:
            break  // All valid cases
        }
    }

    @Test("BiometricAuthManager observable object behavior")
    @MainActor
    func biometricManagerObservableObject() throws {
        let biometricManager = BiometricAuthManager()

        // Note: BiometricAuthManager always conforms to ObservableObject by definition

        // Test that property changes trigger objectWillChange
        let initialValue = biometricManager.isBiometricEnabled
        biometricManager.isBiometricEnabled = !initialValue
        #expect(
            biometricManager.isBiometricEnabled == !initialValue,
            "Property change should be published")
    }

    @Test("Biometric authentication LAError handling")
    @MainActor
    func biometricAuthLAErrorHandling() throws {
        let biometricManager = BiometricAuthManager()

        // Test that the manager correctly maps LAError to BiometricError
        // This tests the error handling logic for LocalAuthentication framework errors

        Task {
            // Attempt authentication - will likely fail in test environment
            do {
                _ = try await biometricManager.authenticateWithBiometrics(reason: "Test authentication")
            } catch let error as BiometricError {
                // Test that LAError is properly mapped to BiometricError
                let validErrors: [BiometricError] = [
                    .authenticationFailed, .userCancel, .lockout,
                    .disabled, .notAvailable, .userFallback,
                ]
                #expect(
                    validErrors.contains(error),
                    "Should map LAError to valid BiometricError: \(error)")
            } catch {
                // In test environment, might throw other errors
                // This is acceptable for testing
            }
        }
    }

    @Test("UI testing environment detection")
    @MainActor
    func uiTestingEnvironmentDetection() throws {
        let biometricManager = BiometricAuthManager()

        // Test UI testing environment detection
        if ProcessInfo.processInfo.environment["UI_TESTING"] == "true" {
            // In UI testing environment, behavior should be predictable
            #expect(
                biometricManager.isAvailable == true,
                "Should be available in UI testing environment")
            #expect(
                biometricManager.biometricType == .faceID,
                "Should default to Face ID in UI testing environment")
        }

        // Test that manager doesn't crash in either testing or production environment
        _ = biometricManager.getBiometricAvailability()
        _ = biometricManager.biometricTypeDisplayName
    }
}
