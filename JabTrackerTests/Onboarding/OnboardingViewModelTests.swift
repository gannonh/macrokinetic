//
//  OnboardingViewModelTests.swift
//  JabTrackerTests
//
//  Tests for OnboardingViewModel using strict TDD methodology.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

// MARK: - Test Utilities

/// Creates an in-memory test context and container for SwiftData testing.
/// CRITICAL: Both context AND container must be retained - container deallocation invalidates context.
@MainActor
private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
    let schema = Schema([
        User.self,
        Dose.self,
        MedicationProfile.self,
        DoseTitration.self,
        DoseSchedule.self,
        ScheduledDose.self,
        Food.self,
        FoodEntry.self,
        WeightEntry.self,
        MetricsEntry.self,
        ProgressPhoto.self,
        NutritionGoal.self,
        NutritionProgram.self,
    ])
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
    )
    let container = try! ModelContainer(for: schema, configurations: [config])
    return (container.mainContext, container)
}

/// Creates a test user in the given context
private func createTestUser(in context: ModelContext) -> User {
    let user = User(
        email: "test@example.com",
        name: "Test User",
        appleUserId: "test-apple-id",
        hasCompletedOnboarding: false
    )
    context.insert(user)
    try? context.save()
    return user
}

// MARK: - OnboardingStep Tests

@Suite("OnboardingStep Tests")
struct OnboardingStepTests {

    @Test("All steps are defined in correct order")
    func testAllStepsDefinedInOrder() {
        // Given: The OnboardingStep enum
        let allSteps = OnboardingStep.allCases

        // Then: Should have exactly 7 steps in the expected order
        // HealthKit comes before goalProgram so weight data is available for goal setup
        #expect(allSteps.count == 7)
        #expect(allSteps[0] == .welcome)
        #expect(allSteps[1] == .uspShowcase)
        #expect(allSteps[2] == .healthKit)
        #expect(allSteps[3] == .goalProgram)
        #expect(allSteps[4] == .faceID)
        #expect(allSteps[5] == .notifications)
        #expect(allSteps[6] == .completion)
    }

    @Test("Each step has a title")
    func testStepTitles() {
        // Given: All onboarding steps
        for step in OnboardingStep.allCases {
            // Then: Each step should have a non-empty title
            #expect(!step.title.isEmpty, "Step \(step) should have a title")
        }
    }

    @Test("Each step has a subtitle")
    func testStepSubtitles() {
        // Given: All onboarding steps
        for step in OnboardingStep.allCases {
            // Then: Each step should have a non-empty subtitle
            #expect(!step.subtitle.isEmpty, "Step \(step) should have a subtitle")
        }
    }
}

// MARK: - OnboardingViewModel Navigation Tests

@Suite("OnboardingViewModel Navigation Tests")
struct OnboardingViewModelNavigationTests {

    @Test("Initial state starts at welcome step")
    @MainActor
    func testInitialStateIsWelcome() {
        // Given: A new OnboardingViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: Current step should be welcome
        #expect(viewModel.currentStep == .welcome)
    }

    @Test("moveToNextStep advances to next step")
    @MainActor
    func testMoveToNextStepAdvances() {
        // Given: A ViewModel at welcome step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        #expect(viewModel.currentStep == .welcome)

        // When: Moving to next step
        viewModel.moveToNextStep()

        // Then: Should advance to uspShowcase
        #expect(viewModel.currentStep == .uspShowcase)
    }

    @Test("moveToPreviousStep goes back to previous step")
    @MainActor
    func testMoveToPreviousStepGoesBack() {
        // Given: A ViewModel at uspShowcase step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        viewModel.moveToNextStep()  // Move to uspShowcase
        #expect(viewModel.currentStep == .uspShowcase)

        // When: Moving to previous step
        viewModel.moveToPreviousStep()

        // Then: Should go back to welcome
        #expect(viewModel.currentStep == .welcome)
    }

    @Test("Cannot go before first step")
    @MainActor
    func testCannotGoBeyondFirstStep() {
        // Given: A ViewModel at welcome (first step)
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        #expect(viewModel.currentStep == .welcome)

        // When: Attempting to go to previous step
        viewModel.moveToPreviousStep()

        // Then: Should remain at welcome
        #expect(viewModel.currentStep == .welcome)
    }

    @Test("Cannot go past last step")
    @MainActor
    func testCannotGoBeyondLastStep() {
        // Given: A ViewModel at the last step (completion)
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Navigate to the last step
        while viewModel.currentStep != .completion {
            viewModel.moveToNextStep()
        }
        #expect(viewModel.currentStep == .completion)

        // When: Attempting to go to next step
        viewModel.moveToNextStep()

        // Then: Should remain at completion
        #expect(viewModel.currentStep == .completion)
    }
}

// MARK: - OnboardingViewModel Progress Tests

@Suite("OnboardingViewModel Progress Tests")
struct OnboardingViewModelProgressTests {

    @Test("Progress is 0 at first step")
    @MainActor
    func testProgressAtFirstStep() {
        // Given: A ViewModel at welcome step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: Progress should be 0.0
        #expect(viewModel.progress == 0.0)
    }

    @Test("Progress is 1.0 at last step")
    @MainActor
    func testProgressAtLastStep() {
        // Given: A ViewModel at completion step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Navigate to the last step
        while viewModel.currentStep != .completion {
            viewModel.moveToNextStep()
        }

        // Then: Progress should be 1.0
        #expect(viewModel.progress == 1.0)
    }

    @Test("Progress calculation is currentIndex / (totalSteps - 1)")
    @MainActor
    func testProgressCalculation() {
        // Given: A ViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // When: At second step (index 1)
        viewModel.moveToNextStep()  // uspShowcase (index 1)

        // Then: Progress = 1 / (7 - 1) = 1/6
        let expectedProgress = 1.0 / 6.0
        #expect(abs(viewModel.progress - expectedProgress) < 0.001)
    }

    @Test("totalSteps returns correct count")
    @MainActor
    func testTotalStepsCount() {
        // Given: A ViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: Total steps should be 7
        #expect(viewModel.totalSteps == 7)
    }

    @Test("currentStepIndex returns correct index")
    @MainActor
    func testCurrentStepIndex() {
        // Given: A ViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: At welcome, index should be 0
        #expect(viewModel.currentStepIndex == 0)

        // When: Move to next step
        viewModel.moveToNextStep()

        // Then: At uspShowcase, index should be 1
        #expect(viewModel.currentStepIndex == 1)
    }
}

// MARK: - OnboardingViewModel State Tests

@Suite("OnboardingViewModel State Tests")
struct OnboardingViewModelStateTests {

    @Test("isLastStep is false for non-final steps")
    @MainActor
    func testIsLastStepFalseForNonFinalSteps() {
        // Given: A ViewModel at welcome step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: isLastStep should be false
        #expect(viewModel.isLastStep == false)
    }

    @Test("isLastStep is true only at completion step")
    @MainActor
    func testIsLastStepTrueAtCompletion() {
        // Given: A ViewModel at completion step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Navigate to the last step
        while viewModel.currentStep != .completion {
            viewModel.moveToNextStep()
        }

        // Then: isLastStep should be true
        #expect(viewModel.isLastStep == true)
    }

    @Test("canProceedToNext is true for most steps except goalProgram")
    @MainActor
    func testCanProceedToNextBehavior() {
        // Given: A ViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: canProceedToNext varies by step
        // welcome -> true
        #expect(viewModel.canProceedToNext == true)
        viewModel.moveToNextStep()

        // uspShowcase -> true
        #expect(viewModel.canProceedToNext == true)
        viewModel.moveToNextStep()

        // healthKit -> true
        #expect(viewModel.canProceedToNext == true)
        viewModel.moveToNextStep()

        // goalProgram -> false until wizards complete
        #expect(viewModel.currentStep == .goalProgram)
        #expect(viewModel.canProceedToNext == false)

        // After marking wizards complete -> true
        viewModel.markGoalProgramComplete()
        #expect(viewModel.canProceedToNext == true)
        viewModel.moveToNextStep()

        // faceID -> true
        #expect(viewModel.canProceedToNext == true)
        viewModel.moveToNextStep()

        // notifications -> true
        #expect(viewModel.canProceedToNext == true)
        viewModel.moveToNextStep()

        // completion -> true
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("markGoalProgramComplete enables proceeding from goalProgram step")
    @MainActor
    func testMarkGoalProgramCompleteEnablesProceeding() {
        // Given: A ViewModel at goalProgram step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Navigate to goalProgram
        viewModel.moveToNextStep()  // uspShowcase
        viewModel.moveToNextStep()  // healthKit
        viewModel.moveToNextStep()  // goalProgram
        #expect(viewModel.currentStep == .goalProgram)
        #expect(viewModel.canProceedToNext == false)

        // When: Marking goal/program complete
        viewModel.markGoalProgramComplete()

        // Then: Can proceed to next
        #expect(viewModel.canProceedToNext == true)
        #expect(viewModel.goalProgramComplete == true)
    }

    @Test("Initial isLoading is false")
    @MainActor
    func testInitialIsLoadingFalse() {
        // Given: A new ViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: isLoading should be false
        #expect(viewModel.isLoading == false)
    }

    @Test("Initial errorMessage is nil")
    @MainActor
    func testInitialErrorMessageNil() {
        // Given: A new ViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: errorMessage should be nil
        #expect(viewModel.errorMessage == nil)
    }
}

// MARK: - OnboardingViewModel Completion Tests

@Suite("OnboardingViewModel Completion Tests")
struct OnboardingViewModelCompletionTests {

    @Test("completeOnboarding sets hasCompletedOnboarding to true")
    @MainActor
    func testCompleteOnboardingSetsFlag() async {
        // Given: A ViewModel with a user who hasn't completed onboarding
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext
        let user = createTestUser(in: context)
        authManager.currentUser = user
        #expect(user.hasCompletedOnboarding == false)

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // When: Completing onboarding
        let result = await viewModel.completeOnboarding()

        // Then: hasCompletedOnboarding should be true
        #expect(user.hasCompletedOnboarding == true)
        guard case .success = result else {
            Issue.record("Expected .success result but got \(result)")
            return
        }
    }

    @Test("completeOnboarding sets onboardingCompletedAt timestamp")
    @MainActor
    func testCompleteOnboardingSetsTimestamp() async {
        // Given: A ViewModel with a user
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext
        let user = createTestUser(in: context)
        authManager.currentUser = user
        #expect(user.onboardingCompletedAt == nil)

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // When: Completing onboarding
        _ = await viewModel.completeOnboarding()

        // Then: onboardingCompletedAt should be set
        #expect(user.onboardingCompletedAt != nil)
    }

    @Test("completeOnboarding stores backup in UserDefaults")
    @MainActor
    func testCompleteOnboardingStoresUserDefaults() async {
        // Given: A ViewModel with a user
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext
        let user = createTestUser(in: context)
        authManager.currentUser = user

        // Clear UserDefaults backup keys
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "onboardingCompletedAt")

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // When: Completing onboarding
        _ = await viewModel.completeOnboarding()

        // Then: UserDefaults should have backup values
        #expect(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") == true)
        #expect(UserDefaults.standard.object(forKey: "onboardingCompletedAt") != nil)
    }

    @Test("completeOnboarding returns alreadyCompleted for completed users")
    @MainActor
    func testCompleteOnboardingReturnsAlreadyCompleted() async {
        // Given: A ViewModel with a user who has already completed onboarding
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext
        let user = createTestUser(in: context)
        user.hasCompletedOnboarding = true
        user.onboardingCompletedAt = Date()
        try? context.save()
        authManager.currentUser = user

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // When: Attempting to complete onboarding again
        let result = await viewModel.completeOnboarding()

        // Then: Should return alreadyCompleted
        guard case .alreadyCompleted = result else {
            Issue.record("Expected .alreadyCompleted result but got \(result)")
            return
        }
    }

    @Test("completeOnboarding returns failed when no user")
    @MainActor
    func testCompleteOnboardingFailsWithoutUser() async {
        // Given: A ViewModel with no current user
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        authManager.currentUser = nil

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // When: Attempting to complete onboarding
        let result = await viewModel.completeOnboarding()

        // Then: Should return failed
        if case .failed = result {
            // Success - it failed as expected
        } else {
            Issue.record("Expected .failed result but got \(result)")
        }
    }
}
