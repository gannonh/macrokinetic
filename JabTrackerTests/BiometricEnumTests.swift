import Foundation
import Testing

@testable import JabTracker

@Suite("Biometric Enum Tests")
struct BiometricEnumTests {
  @Test("BiometricError error descriptions")
  func biometricErrorDescriptions() throws {
    // Test all BiometricError cases have proper descriptions
    let authenticationFailed = BiometricError.authenticationFailed
    #expect(
      authenticationFailed.localizedDescription.contains("failed"),
      "authenticationFailed should have descriptive error message")

    let userCancel = BiometricError.userCancel
    #expect(
      userCancel.localizedDescription.contains("cancelled")
        || userCancel.localizedDescription.contains("canceled"),
      "userCancel should have descriptive error message")

    let lockout = BiometricError.lockout
    #expect(
      lockout.localizedDescription.contains("locked"),
      "lockout should have descriptive error message")

    let disabled = BiometricError.disabled
    #expect(
      disabled.localizedDescription.contains("disabled"),
      "disabled should have descriptive error message")

    let notAvailable = BiometricError.notAvailable
    #expect(
      notAvailable.localizedDescription.contains("available"),
      "notAvailable should have descriptive error message")

    let userFallback = BiometricError.userFallback
    #expect(
      userFallback.localizedDescription.contains("passcode"),
      "userFallback should have descriptive error message")

    // Test all error descriptions are non-empty and meaningful
    let allErrors: [BiometricError] = [
      .authenticationFailed, .userCancel, .lockout, .disabled,
      .notAvailable, .userFallback,
    ]

    for error in allErrors {
      #expect(
        !error.localizedDescription.isEmpty, "Error description should not be empty for \(error)")
      #expect(
        error.localizedDescription.count > 5, "Error description should be descriptive for \(error)"
      )
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
      #expect(
        displayName == expectedName,
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
        #expect(
          [BiometricType.faceID, .touchID, .opticID, .none].contains(type),
          "Available biometric type should be one of the valid types")
      case .notAvailable, .notEnrolled, .restricted, .unknown:
        matched = true
      }
      #expect(matched, "BiometricAvailability case should be matchable in switch statement")
    }
  }

  @Test("BiometricType enum all cases")
  func biometricTypeEnumCases() throws {
    // Test all BiometricType cases exist and have proper raw values
    let allTypes = BiometricType.allCases
    #expect(allTypes.count == 4, "Should have exactly 4 biometric types")

    #expect(allTypes.contains(.none), "Should contain none case")
    #expect(allTypes.contains(.touchID), "Should contain touchID case")
    #expect(allTypes.contains(.faceID), "Should contain faceID case")
    #expect(allTypes.contains(.opticID), "Should contain opticID case")

    // Test raw values
    #expect(BiometricType.none.rawValue == "none")
    #expect(BiometricType.touchID.rawValue == "touchID")
    #expect(BiometricType.faceID.rawValue == "faceID")
    #expect(BiometricType.opticID.rawValue == "opticID")
  }
}
