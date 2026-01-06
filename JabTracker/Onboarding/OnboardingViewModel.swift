//
//  OnboardingViewModel.swift
//  JabTracker
//
//  ViewModel for the v0.6.0 onboarding flow.
//

import Foundation
import OSLog
import SwiftData

// MARK: - OnboardingViewModel

// Note: OnboardingCompletionResult is defined in LegacyOnboardingViewModel.swift
// and is shared between both implementations for API compatibility.

/// ViewModel for managing onboarding flow state and navigation.
///
/// Uses `@Observable` (iOS 17+) for automatic view updates.
/// Manages step navigation, progress calculation, and completion logic.
///
/// Note: Goal and program creation is handled by GoalWizard and ProgramWizard
/// (presented as sheets from OnboardingView). This ViewModel only tracks
/// that the wizards have completed.
@Observable
@MainActor
final class OnboardingViewModel {
    // MARK: - Properties

    /// Current step in the onboarding flow
    var currentStep: OnboardingStep = .welcome {
        didSet {
            updateProgress()
        }
    }

    /// Progress value from 0.0 to 1.0
    var progress: Double = 0.0

    /// Whether an async operation is in progress
    var isLoading: Bool = false

    /// Error message for display in UI
    var errorMessage: String?

    /// Whether goal/program wizards have been completed
    /// Set by OnboardingView after ProgramWizard completes
    private(set) var goalProgramComplete: Bool = false

    // MARK: - Private Properties

    private let dataController: DataController
    private let authManager: AuthenticationManager
    private let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "OnboardingViewModel"
    )

    // MARK: - Computed Properties

    /// Total number of steps in the onboarding flow
    var totalSteps: Int {
        OnboardingStep.allCases.count
    }

    /// Index of the current step (0-based)
    var currentStepIndex: Int {
        OnboardingStep.allCases.firstIndex(of: currentStep) ?? 0
    }

    /// Whether the current step is the last step
    var isLastStep: Bool {
        currentStep == OnboardingStep.allCases.last
    }

    /// Whether the user can proceed to the next step.
    var canProceedToNext: Bool {
        switch currentStep {
        case .goalProgram:
            // Can only proceed if wizards have completed
            return goalProgramComplete
        default:
            // Other steps can proceed immediately
            return true
        }
    }

    // MARK: - Initialization

    init(dataController: DataController, authManager: AuthenticationManager) {
        self.dataController = dataController
        self.authManager = authManager
        updateProgress()
    }

    // MARK: - Navigation Methods

    /// Move to the next step in the onboarding flow.
    /// Does nothing if already at the last step or cannot proceed.
    func moveToNextStep() {
        guard !isLastStep, canProceedToNext else { return }

        if let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
            currentIndex + 1 < OnboardingStep.allCases.count
        {
            currentStep = OnboardingStep.allCases[currentIndex + 1]
            logger.debug("Moved to step: \(self.currentStep.rawValue)")
        }
    }

    /// Move to the previous step in the onboarding flow.
    /// Does nothing if already at the first step.
    func moveToPreviousStep() {
        if let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
            currentIndex > 0
        {
            currentStep = OnboardingStep.allCases[currentIndex - 1]
            logger.debug("Moved back to step: \(self.currentStep.rawValue)")
        }
    }

    /// Mark goal/program wizards as complete.
    /// Called by OnboardingView after ProgramWizard finishes.
    func markGoalProgramComplete() {
        goalProgramComplete = true
        logger.info("Goal and program wizards completed")
    }

    // MARK: - Completion

    /// Complete the onboarding flow and mark the user as onboarded.
    ///
    /// - Returns: Result indicating success, already completed, or failure
    func completeOnboarding() async -> OnboardingCompletionResult {
        isLoading = true
        defer { isLoading = false }

        // User is required to complete onboarding
        guard let user = authManager.currentUser else {
            errorMessage = "No user found to complete onboarding"
            logger.error("Cannot complete onboarding: no current user")
            return .failed(OnboardingError.userNotFound)
        }

        // Check if already completed
        if user.hasCompletedOnboarding {
            logger.info("Onboarding already completed for user")
            return .alreadyCompleted
        }

        let context = dataController.container.mainContext

        do {
            try finalizeOnboarding(for: user, in: context)
            logger.info("Onboarding completed successfully")
            errorMessage = nil
            return .success
        } catch {
            errorMessage = "Failed to complete onboarding: \(error.localizedDescription)"
            logger.error("Failed to complete onboarding: \(error.localizedDescription)")
            return .failed(OnboardingError.dataCreationFailed)
        }
    }

    // MARK: - Private Methods

    /// Finalizes onboarding by marking user as complete.
    /// Note: Goal/program are created by the wizards, not here.
    private func finalizeOnboarding(for user: User, in context: ModelContext) throws {
        user.hasCompletedOnboarding = true
        user.onboardingCompletedAt = Date()
        user.updatedAt = Date()

        try context.save()

        // Store completion in UserDefaults as backup
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(Date(), forKey: "onboardingCompletedAt")

        logger.info("User marked as onboarded")
    }

    /// Update progress based on current step
    private func updateProgress() {
        guard totalSteps > 1 else {
            progress = 0.0
            return
        }
        progress = Double(currentStepIndex) / Double(totalSteps - 1)
    }
}
