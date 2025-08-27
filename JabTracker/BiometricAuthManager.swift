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
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "JabTracker", category: "BiometricAuthManager")

    @Published var isBiometricEnabled: Bool {
        willSet {
            Self.logger.info("🔐 BiometricAuthManager: isBiometricEnabled will change from \(isBiometricEnabled, privacy: .public) to \(newValue, privacy: .public)")
            objectWillChange.send()
        }
        didSet {
            Self.logger.info("🔐 BiometricAuthManager: isBiometricEnabled did change to \(isBiometricEnabled, privacy: .public)")
            // In UI testing mode, just store in memory since UserDefaults can be unreliable
            let isUITesting = ProcessInfo.processInfo.environment["UI_TESTING"] == "true" ||
                ProcessInfo.processInfo.arguments.contains("--ui-testing")

            if !isUITesting {
                UserDefaults.standard.set(isBiometricEnabled, forKey: "biometricAuthEnabled")
            }
        }
    }

    @Published var biometricType: BiometricType = .none
    @Published var isAvailable: Bool = false

    init() {
        // In UI testing mode, start with a default value since UserDefaults can be unreliable
        let isUITesting = ProcessInfo.processInfo.environment["UI_TESTING"] == "true" ||
            ProcessInfo.processInfo.arguments.contains("--ui-testing")

        if isUITesting {
            isBiometricEnabled = false // Start with disabled state for predictable testing
        } else {
            isBiometricEnabled = UserDefaults.standard.bool(forKey: "biometricAuthEnabled")
        }

        checkBiometricAvailability()
    }

    private func checkBiometricAvailability() {
        // In UI testing mode, always make biometrics available
        let isUITesting = ProcessInfo.processInfo.environment["UI_TESTING"] == "true" ||
            ProcessInfo.processInfo.arguments.contains("--ui-testing")

        if isUITesting {
            self.isAvailable = true
            biometricType = .faceID
            return
        }

        let context = LAContext()
        var error: NSError?

        let isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

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

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if canEvaluate {
            let type: BiometricType
            switch context.biometryType {
            case .faceID:
                type = .faceID
            case .touchID:
                type = .touchID
            case .opticID:
                type = .opticID
            case .none:
                type = .none
            @unknown default:
                type = .none
            }
            return .available(type)
        } else {
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
    }

    func authenticateWithBiometrics(reason: String) async throws -> Bool {
        guard isAvailable else {
            throw BiometricError.notAvailable
        }

        guard isBiometricEnabled else {
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
        isBiometricEnabled = enabled
    }

    // Force objectWillChange for testing
    func toggleBiometric() {
        objectWillChange.send()
        isBiometricEnabled.toggle()
    }

    var biometricTypeDisplayName: String {
        switch biometricType {
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
