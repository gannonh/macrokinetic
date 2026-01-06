//
//  OnboardingStep.swift
//  JabTracker
//
//  Defines the steps in the v0.6.0 onboarding flow.
//

import Foundation

/// Steps in the onboarding flow for new users.
///
/// The steps are organized into logical phases:
/// - Phase 26: USP Showcase (welcome, uspShowcase)
/// - Phase 27: Goal + Program (healthKit first for weight, then wizard sheets)
/// - Phase 28: Permissions (faceID, notifications)
/// - Phase 29: Completion (completion)
///
/// Note: Goal and Program setup use existing GoalWizard and ProgramWizard
/// presented as sheets after the healthKit step. This ensures HealthKit
/// weight data is available before goal configuration.
enum OnboardingStep: String, CaseIterable {
    // MARK: - Phase 26: USP Showcase

    /// Welcome screen introducing the app
    case welcome

    /// Unique selling proposition showcase
    case uspShowcase

    // MARK: - Phase 27: HealthKit + Goal/Program

    /// HealthKit integration permission (before goal setup to get weight)
    case healthKit

    /// Goal and program setup using GoalWizard + ProgramWizard sheets
    /// This step auto-presents the wizard sheets when reached
    case goalProgram

    // MARK: - Phase 28: Permissions

    /// Face ID/Touch ID biometric permission
    case faceID

    /// Push notification permission
    case notifications

    // MARK: - Phase 29: Completion

    /// Onboarding complete, ready to start
    case completion

    // MARK: - Display Properties

    /// Display title for the step
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to JabTracker"
        case .uspShowcase:
            return "Your GLP-1 Journey"
        case .healthKit:
            return "Connect Health Data"
        case .goalProgram:
            return "Set Your Goals"
        case .faceID:
            return "Secure Your Data"
        case .notifications:
            return "Stay On Track"
        case .completion:
            return "You're All Set!"
        }
    }

    /// Display subtitle for the step
    var subtitle: String {
        switch self {
        case .welcome:
            return "Track your GLP-1 medication with confidence"
        case .uspShowcase:
            return "Discover how JabTracker helps you succeed"
        case .healthKit:
            return "Sync your health metrics automatically"
        case .goalProgram:
            return "Configure your goal and program"
        case .faceID:
            return "Protect your sensitive health information"
        case .notifications:
            return "Get reminders when it's time for your dose"
        case .completion:
            return "Let's start your journey together"
        }
    }
}
