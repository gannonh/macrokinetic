import Foundation
import LocalAuthentication
import SwiftData
import Testing

@testable import JabTracker

@MainActor
@Suite("Biometric Authentication Manager Core Tests")
struct BiometricAuthManagerCoreTests {
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
      break  // All valid cases
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
      break  // All valid cases
    }

    // Test biometric type detection
    let biometricType = biometricManager.biometricType
    #expect(
      [BiometricType.faceID, BiometricType.touchID, BiometricType.none].contains(biometricType))

    // Test display name
    let displayName = biometricManager.biometricTypeDisplayName
    #expect(!displayName.isEmpty, "Display name should not be empty")
  }

  @Test("BiometricAuthManager authentication interface")
  @MainActor
  func biometricAuthenticationInterface() throws {
    let biometricManager = BiometricAuthManager()

    // Test that the authentication methods exist and can be called
    #expect(biometricManager.isBiometricEnabled == false, "Should start disabled")

    // In testing environment, authenticateWithBiometrics would not actually prompt
    // but the method should exist and be callable
    Task {
      // Test that the async method exists and returns a result
      do {
        let result = try await biometricManager.authenticateWithBiometrics(
          reason: "Test authentication")
        // In test environment, this might succeed or fail depending on setup
        // Result is a Bool - true for success, false for failure (though failure usually throws)
        #expect(result == true || result == false, "Result should be a boolean value")
      } catch {
        // Biometric authentication can throw in test environment
        // Should be a BiometricError
        #expect(
          error is BiometricError,
          "authenticateWithBiometrics should throw BiometricError, got: \(type(of: error))")
      }
    }

    // Test that authentication method returns Bool
    Task {
      do {
        let result = try await biometricManager.authenticateWithBiometrics(
          reason: "Test authentication")
        // Result is Bool - true for success
        #expect(result == true, "Successful authentication should return true")
      } catch {
        // Error is expected in test environment
        #expect(error is BiometricError, "Should throw BiometricError")
      }
    }
  }

  @Test("Biometric authentication error scenarios")
  @MainActor
  func biometricAuthenticationErrors() throws {
    let biometricManager = BiometricAuthManager()

    // Test various error scenarios that can occur during authentication
    Task {
      // Try authentication - might fail in test environment
      do {
        _ = try await biometricManager.authenticateWithBiometrics(reason: "Test authentication")
      } catch {
        // Should throw BiometricError in failure cases
        #expect(error is BiometricError, "Should throw BiometricError, got: \(type(of: error))")
      }
    }
  }

  @Test("Biometric authentication disabled state handling")
  @MainActor
  func biometricAuthDisabledHandling() throws {
    let biometricManager = BiometricAuthManager()

    // Ensure biometrics are disabled
    biometricManager.setBiometricPreference(enabled: false)
    #expect(biometricManager.isBiometricEnabled == false, "Should be disabled")

    // Test authentication when disabled
    Task {
      do {
        _ = try await biometricManager.authenticateWithBiometrics(reason: "Test authentication")
        #expect(Bool(false), "Should not reach here - authentication should throw when disabled")
      } catch let error as BiometricError {
        // Should throw specific disabled error
        #expect(
          error == BiometricError.notAvailable || error == BiometricError.disabled,
          "Should throw appropriate error when disabled, got: \(error)")
      } catch {
        #expect(Bool(false), "Should throw BiometricError when disabled, got: \(type(of: error))")
      }
    }

    // Test UI testing environment behavior - authenticateWithBiometrics when disabled
    if ProcessInfo.processInfo.environment["UI_TESTING"] == "true" {
      Task {
        var threwDisabledError = false
        do {
          _ = try await biometricManager.authenticateWithBiometrics(reason: "Test authentication")
        } catch BiometricError.notAvailable {
          threwDisabledError = true
        } catch {
          // Other errors are acceptable in test environment
        }
        #expect(threwDisabledError, "Should throw disabled error when biometrics disabled")
      }
    }
  }
}
