import Foundation

enum OnboardingError: LocalizedError {
    case missingRequiredData
    case permissionsDenied
    case dataCreationFailed
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .missingRequiredData:
            return "Required onboarding data is missing"
        case .permissionsDenied:
            return "Required permissions were not granted"
        case .dataCreationFailed:
            return "Failed to save onboarding data"
        case .userNotFound:
            return "No authenticated user found"
        }
    }
}
