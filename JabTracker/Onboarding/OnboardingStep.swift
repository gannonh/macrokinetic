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
/// - Phase 27: Goal + Program (integrated steps, not separate wizard sheets)
/// - Phase 28: Permissions (faceID, notifications)
/// - Phase 29: Completion (completion)
///
/// Goal and Program setup steps reuse existing step view components from
/// GoalWizard and ProgramWizard for a seamless integrated experience.
enum OnboardingStep: String, CaseIterable {
    // MARK: - Phase 26: USP Showcase

    /// Welcome screen introducing the app
    case welcome

    /// Unique selling proposition showcase
    case uspShowcase

    // MARK: - Phase 27: HealthKit + Goal/Program Setup

    /// HealthKit integration permission (before goal setup to get weight)
    case healthKit

    /// Goal type selection (weight loss, maintain, muscle gain)
    /// Reuses GoalTypeSelectionView component
    case goalType

    /// Target weight configuration (current weight, target, weekly rate)
    /// Reuses TargetWeightStepView component
    case targetWeight

    /// Profile completion for TDEE calculation (height, sex, birthday)
    /// Uses OnboardingProfileCompletionView (design matches ProfileCompletionStepView for consistency)
    case profileCompletion

    /// Program style selection (coached, collaborative, manual)
    /// Reuses ProgramStyleStepView component
    case programStyle

    /// Diet preference selection (balanced, low-carb, high-protein, keto)
    /// Reuses DietPreferenceStepView component
    case dietPreference

    /// Calorie floor selection (standard, aggressive, very aggressive)
    /// Reuses CalorieFloorStepView component
    case calorieFloor

    /// Activity/training level selection
    /// Reuses TrainingLevelStepView component
    case activityLevel

    /// Weekly distribution mode (even or shifted to specific days)
    /// Reuses WeeklyDistributionStepView component
    case weeklyDistribution

    /// Shifted distribution: select which days have higher calories
    /// Only shown when weeklyDistributionMode is .shifted
    /// Reuses ShiftedDaySelectionStepView component
    case shiftedDaySelection

    /// Protein level selection (moderate, high, very high)
    /// Reuses ProteinLevelStepView component
    case proteinLevel

    /// Combined goal and program summary/confirmation
    case setupConfirmation

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
            return "Welcome to MacroKinetic"
        case .uspShowcase:
            return "Your GLP-1 Journey"
        case .healthKit:
            return "Connect Health Data"
        case .goalType:
            return "Choose Your Goal"
        case .targetWeight:
            return "Set Your Target"
        case .profileCompletion:
            return "Complete Your Profile"
        case .programStyle:
            return "Program Style"
        case .dietPreference:
            return "Diet Preference"
        case .calorieFloor:
            return "Calorie Floor"
        case .activityLevel:
            return "Activity Level"
        case .weeklyDistribution:
            return "Weekly Distribution"
        case .proteinLevel:
            return "Protein Level"
        case .shiftedDaySelection:
            return "High Calorie Days"
        case .setupConfirmation:
            return "Your Personalized Plan"
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
            return "Track your fitness journey with confidence"
        case .uspShowcase:
            return "Discover how MacroKinetic helps you succeed"
        case .healthKit:
            return "Sync your health metrics automatically"
        case .goalType:
            return "What are you working toward?"
        case .targetWeight:
            return "Configure your target weight and pace"
        case .profileCompletion:
            return "We need a few details to calculate your targets"
        case .programStyle:
            return "How do you want to manage your nutrition?"
        case .dietPreference:
            return "Choose a macro distribution that fits your lifestyle"
        case .calorieFloor:
            return "Set a minimum daily calorie intake"
        case .activityLevel:
            return "What's your typical activity level?"
        case .weeklyDistribution:
            return "How should calories be spread across the week?"
        case .proteinLevel:
            return "Higher protein helps preserve muscle"
        case .shiftedDaySelection:
            return "Which days would you like to have higher calories?"
        case .setupConfirmation:
            return "Review your customized nutrition targets"
        case .faceID:
            return "Protect your sensitive health information"
        case .notifications:
            return "Get reminders when it's time for your dose"
        case .completion:
            return "Let's start your journey together"
        }
    }
}
