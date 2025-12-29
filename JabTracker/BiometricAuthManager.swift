import Foundation
import LocalAuthentication
import OSLog
import SwiftUI

enum BiometricType: String, CaseIterable {
    case none
    case touchID
    case faceID
    case opticID
}

enum BiometricAvailability {
    case available(BiometricType)
    case notAvailable
    case notEnrolled
    case restricted
    case unknown
}

@MainActor
class BiometricAuthManager: ObservableObject {
    /// Shared singleton instance for app-wide biometric state
    static let shared = BiometricAuthManager()

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "JabTracker",
        category: "BiometricAuthManager")

    @Published var isBiometricEnabled: Bool {
        willSet {
            Self.logger.info(
                """
                🔐 BiometricAuthManager: isBiometricEnabled will change from \
                \(self.isBiometricEnabled, privacy: .public) to \(newValue, privacy: .public)
                """
            )
            objectWillChange.send()
        }
        didSet {
            Self.logger.info(
                "🔐 BiometricAuthManager: isBiometricEnabled did change to \(self.isBiometricEnabled, privacy: .public)"
            )
            UserDefaults.standard.set(self.isBiometricEnabled, forKey: "biometricAuthEnabled")
        }
    }

    @Published var biometricType: BiometricType = .none
    @Published var isAvailable: Bool = false

    init() {
        // Always load from UserDefaults - the --reset-app-data flag handles clearing if needed
        self.isBiometricEnabled = UserDefaults.standard.bool(forKey: "biometricAuthEnabled")
        self.checkBiometricAvailability()
    }

    private func checkBiometricAvailability() {
        // In testing mode, provide predictable behavior
        let isUITesting =
            ProcessInfo.processInfo.environment["UI_TESTING"] == "true"
            || ProcessInfo.processInfo.arguments.contains("--ui-testing")
        let isUnitTesting = NSClassFromString("XCTestCase") != nil

        if isUITesting || isUnitTesting {
            // Make biometrics available in testing for testing scenarios
            self.isAvailable = true
            self.biometricType = .faceID
            return
        }

        let context = LAContext()
        var error: NSError?

        let isAvailable = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: &error)

        Task { @MainActor in
            self.isAvailable = isAvailable

            if isAvailable {
                switch context.biometryType {
                case .faceID:
                    self.biometricType = .faceID
                case .touchID:
                    self.biometricType = .touchID
                case .opticID:
                    self.biometricType = .opticID
                case .none:
                    self.biometricType = .none
                @unknown default:
                    self.biometricType = .none
                }
            } else {
                self.biometricType = .none
            }
        }
    }

    func getBiometricAvailability() -> BiometricAvailability {
        let context = LAContext()
        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: &error)

        if canEvaluate {
            let type = self.biometricTypeFrom(context: context)
            return .available(type)
        } else {
            return self.availabilityFromError(error)
        }
    }

    private func biometricTypeFrom(context: LAContext) -> BiometricType {
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    private func availabilityFromError(_ error: NSError?) -> BiometricAvailability {
        guard let error else { return .unknown }

        switch LAError.Code(rawValue: error.code) {
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .restricted
        default:
            return .unknown
        }
    }

    func authenticateWithBiometrics(reason: String) async throws -> Bool {
        guard self.isAvailable else {
            throw BiometricError.notAvailable
        }

        guard self.isBiometricEnabled else {
            throw BiometricError.disabled
        }

        let context = LAContext()

        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason)
            return result
        } catch {
            if let laError = error as? LAError {
                switch laError.code {
                case .userCancel:
                    throw BiometricError.userCancel
                case .userFallback:
                    throw BiometricError.userFallback
                case .biometryLockout:
                    throw BiometricError.lockout
                default:
                    throw BiometricError.authenticationFailed
                }
            }
            throw BiometricError.authenticationFailed
        }
    }

    func setBiometricPreference(enabled: Bool) {
        self.isBiometricEnabled = enabled
    }

    /// Refresh the biometric enabled state from UserDefaults
    ///
    /// Call this when a view appears to ensure the state is in sync with UserDefaults,
    /// especially after another view may have modified the preference.
    func refreshFromUserDefaults() {
        let storedValue = UserDefaults.standard.bool(forKey: "biometricAuthEnabled")
        if storedValue != isBiometricEnabled {
            isBiometricEnabled = storedValue
        }
    }

    // Force objectWillChange for testing
    func toggleBiometric() {
        objectWillChange.send()
        self.isBiometricEnabled.toggle()
    }

    var biometricTypeDisplayName: String {
        switch self.biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Biometrics"
        }
    }
}

enum BiometricError: Error, LocalizedError {
    case notAvailable
    case disabled
    case userCancel
    case userFallback
    case lockout
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .disabled:
            return "Biometric authentication is disabled in settings"
        case .userCancel:
            return "User cancelled biometric authentication"
        case .userFallback:
            return "User chose to use device passcode instead"
        case .lockout:
            return "Biometric authentication is locked out"
        case .authenticationFailed:
            return "Biometric authentication failed"
        }
    }
}
