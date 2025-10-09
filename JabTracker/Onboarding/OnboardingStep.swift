import Foundation

enum OnboardingStep: String, CaseIterable {
    case welcome
    case medicationSelection = "medication"
    case doseSetup = "dose"
    case scheduleSetup = "schedule"
    case notifications
    case healthKit = "health"
    case subscription

    var title: String {
        switch self {
        case .welcome:
            return "Welcome to JabTracker"
        case .medicationSelection:
            return "Select Your Medication"
        case .doseSetup:
            return "Set Up Your First Dose"
        case .scheduleSetup:
            return "Set Up Your Schedule"
        case .notifications:
            return "Enable Notifications"
        case .healthKit:
            return "Connect Health Data"
        case .subscription:
            return "JabTracker Premium"
        }
    }
}
