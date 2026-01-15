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

        // Then: Should have exactly 18 steps in the expected order
        // Full onboarding flow with goal/program configuration steps
        #expect(allSteps.count == 18)
        #expect(allSteps[0] == .welcome)
        #expect(allSteps[1] == .uspShowcase)
        #expect(allSteps[2] == .healthKit)
        #expect(allSteps[3] == .goalType)
        #expect(allSteps[4] == .targetWeight)
        #expect(allSteps[5] == .profileCompletion)
        #expect(allSteps[6] == .programStyle)
        #expect(allSteps[7] == .dietPreference)
        #expect(allSteps[8] == .calorieFloor)
        #expect(allSteps[9] == .activityLevel)
        #expect(allSteps[10] == .weeklyDistribution)
        #expect(allSteps[11] == .shiftedDaySelection)
        #expect(allSteps[12] == .proteinLevel)
        #expect(allSteps[13] == .collaborativeDistribution)
        #expect(allSteps[14] == .setupConfirmation)
        #expect(allSteps[15] == .faceID)
        #expect(allSteps[16] == .notifications)
        #expect(allSteps[17] == .completion)
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

        // Configure ALL required state to proceed through ALL steps
        // Goal setup
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0

        // Profile completion (editSex, editHeightFeet must be valid)
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5

        // Program setup
        viewModel.programStyle = .coached
        viewModel.dietPreference = .balanced
        viewModel.calorieFloorType = .standard
        viewModel.trainingLevel = .lifting
        viewModel.weeklyDistributionMode = .even
        viewModel.proteinLevel = .moderate

        // Navigate to the last step
        var iterations = 0
        let maxIterations = 50  // Safety limit
        while viewModel.currentStep != .completion && iterations < maxIterations {
            viewModel.moveToNextStep()
            iterations += 1
        }
        #expect(viewModel.currentStep == .completion, "Should reach completion step")

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

        // Configure ALL required state to proceed through ALL steps
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5
        viewModel.programStyle = .coached
        viewModel.dietPreference = .balanced
        viewModel.calorieFloorType = .standard
        viewModel.trainingLevel = .lifting
        viewModel.weeklyDistributionMode = .even
        viewModel.proteinLevel = .moderate

        // Navigate to the last step with safety limit
        var iterations = 0
        while viewModel.currentStep != .completion && iterations < 50 {
            viewModel.moveToNextStep()
            iterations += 1
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

        // Then: Progress = 1 / (16 - 1) = 1/15
        let expectedProgress = 1.0 / 15.0
        #expect(abs(viewModel.progress - expectedProgress) < 0.001)
    }

    @Test("totalSteps returns correct count")
    @MainActor
    func testTotalStepsCount() {
        // Given: A ViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: Total steps should be 16 (17 total minus shiftedDaySelection which is skipped by default)
        #expect(viewModel.totalSteps == 16)
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

        // Configure ALL required state to proceed through ALL steps
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5
        viewModel.editHeightInches = 9
        viewModel.editBirthday = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        viewModel.programStyle = .coached
        viewModel.dietPreference = .balanced
        viewModel.calorieFloorType = .standard
        viewModel.trainingLevel = .lifting
        viewModel.weeklyDistributionMode = .even
        viewModel.proteinLevel = .moderate

        // Navigate to the last step with safety limit
        var iterations = 0
        while viewModel.currentStep != .completion && iterations < 50 {
            viewModel.moveToNextStep()
            iterations += 1
        }

        // Then: isLastStep should be true
        #expect(viewModel.isLastStep == true)
    }

    @Test("canProceedToNext requires goal type selection at goalType step")
    @MainActor
    func testCanProceedRequiresGoalType() {
        // Given: A ViewModel at goalType step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Navigate to goalType step
        viewModel.moveToNextStep()  // uspShowcase
        viewModel.moveToNextStep()  // healthKit
        viewModel.moveToNextStep()  // goalType
        #expect(viewModel.currentStep == .goalType)

        // Then: Cannot proceed without goal type
        #expect(viewModel.canProceedToNext == false)

        // When: Setting goal type
        viewModel.goalViewModel.goalType = .weightLoss

        // Then: Can proceed
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("canProceedToNext requires profile completion at profileCompletion step")
    @MainActor
    func testCanProceedRequiresProfileCompletion() {
        // Given: A ViewModel at profileCompletion step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Configure goal type to proceed
        viewModel.goalViewModel.goalType = .weightLoss

        // Navigate to profileCompletion step
        viewModel.moveToNextStep()  // uspShowcase
        viewModel.moveToNextStep()  // healthKit
        viewModel.moveToNextStep()  // goalType
        viewModel.moveToNextStep()  // targetWeight
        viewModel.moveToNextStep()  // profileCompletion
        #expect(viewModel.currentStep == .profileCompletion)

        // Then: Cannot proceed without sex (editSex starts empty)
        #expect(viewModel.canProceedToNext == false)

        // When: Setting sex
        viewModel.editSex = "male"

        // Then: Can proceed
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("canProceedToNext requires activity level at activityLevel step")
    @MainActor
    func testCanProceedRequiresActivityLevel() {
        // Given: A ViewModel at activityLevel step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Configure required state to navigate through all prerequisite steps
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5
        viewModel.editHeightInches = 9
        viewModel.editBirthday = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        viewModel.programStyle = .coached
        viewModel.dietPreference = .balanced
        viewModel.calorieFloorType = .standard

        // Navigate to activityLevel step
        viewModel.moveToNextStep()  // uspShowcase
        viewModel.moveToNextStep()  // healthKit
        viewModel.moveToNextStep()  // goalType
        viewModel.moveToNextStep()  // targetWeight
        viewModel.moveToNextStep()  // profileCompletion
        viewModel.moveToNextStep()  // programStyle
        viewModel.moveToNextStep()  // dietPreference
        viewModel.moveToNextStep()  // calorieFloor
        viewModel.moveToNextStep()  // activityLevel
        #expect(viewModel.currentStep == .activityLevel)

        // Reset trainingLevel to verify validation
        viewModel.trainingLevel = nil

        // Then: Cannot proceed without activity level
        #expect(viewModel.canProceedToNext == false)

        // When: Setting activity level
        viewModel.trainingLevel = .lifting

        // Then: Can proceed
        #expect(viewModel.canProceedToNext == true)
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

// MARK: - OnboardingViewModel Skip Tests

@Suite("OnboardingViewModel Skip Tests")
struct OnboardingViewModelSkipTests {

    @Test("skipOnboarding sets onboardingSkippedAt timestamp")
    @MainActor
    func testSkipOnboardingSetsTimestamp() {
        // Given: A ViewModel with a user
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext
        let user = createTestUser(in: context)
        authManager.currentUser = user
        #expect(user.onboardingSkippedAt == nil)

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // When: Skipping onboarding
        viewModel.skipOnboarding()

        // Then: onboardingSkippedAt should be set
        #expect(user.onboardingSkippedAt != nil)
    }

    @Test("skipOnboarding stores flag in UserDefaults")
    @MainActor
    func testSkipOnboardingStoresUserDefaults() {
        // Given: A ViewModel with a user
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext
        let user = createTestUser(in: context)
        authManager.currentUser = user

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "hasSkippedOnboarding")
        UserDefaults.standard.removeObject(forKey: "onboardingSkippedAt")

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // When: Skipping onboarding
        viewModel.skipOnboarding()

        // Then: UserDefaults should have skip values
        #expect(UserDefaults.standard.bool(forKey: "hasSkippedOnboarding") == true)
        #expect(UserDefaults.standard.object(forKey: "onboardingSkippedAt") != nil)
    }

    @Test("skipOnboarding does nothing without user")
    @MainActor
    func testSkipOnboardingNoUser() {
        // Given: A ViewModel without a current user
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        authManager.currentUser = nil

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "hasSkippedOnboarding")

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // When: Skipping onboarding (should not crash)
        viewModel.skipOnboarding()

        // Then: UserDefaults should not be set (no crash occurred)
        #expect(UserDefaults.standard.bool(forKey: "hasSkippedOnboarding") == false)
    }

    @Test("canSkip is true for goalType step")
    @MainActor
    func testCanSkipTrueForGoalType() {
        // Given: A ViewModel at goalType step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Navigate to goalType step
        viewModel.moveToNextStep()  // uspShowcase
        viewModel.moveToNextStep()  // healthKit
        viewModel.moveToNextStep()  // goalType
        #expect(viewModel.currentStep == .goalType)

        // Then: canSkip should be true
        #expect(viewModel.canSkip == true)
    }

    @Test("canSkip is false for welcome step")
    @MainActor
    func testCanSkipFalseForWelcome() {
        // Given: A ViewModel at welcome step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        #expect(viewModel.currentStep == .welcome)

        // Then: canSkip should be false
        #expect(viewModel.canSkip == false)
    }

    @Test("canSkip is false for completion step")
    @MainActor
    func testCanSkipFalseForCompletion() {
        // Given: A ViewModel at completion step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Configure required state and navigate to completion
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5
        viewModel.programStyle = .coached
        viewModel.dietPreference = .balanced
        viewModel.calorieFloorType = .standard
        viewModel.trainingLevel = .lifting
        viewModel.weeklyDistributionMode = .even
        viewModel.proteinLevel = .moderate

        // Navigate to completion
        var iterations = 0
        while viewModel.currentStep != .completion && iterations < 50 {
            viewModel.moveToNextStep()
            iterations += 1
        }
        #expect(viewModel.currentStep == .completion)

        // Then: canSkip should be false for completion step
        #expect(viewModel.canSkip == false)
    }
}

// MARK: - OnboardingViewModel Available Steps Tests

@Suite("OnboardingViewModel Available Steps Tests")
struct OnboardingViewModelAvailableStepsTests {

    @Test("availableSteps excludes profileCompletion when hasProfileDataFromHealthKit is true")
    @MainActor
    func testAvailableStepsExcludesProfileCompletionWithHealthKit() {
        // Given: A ViewModel with profile data from HealthKit
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        viewModel.hasProfileDataFromHealthKit = true

        // Then: profileCompletion should not be in availableSteps
        #expect(!viewModel.availableSteps.contains(.profileCompletion))
    }

    @Test("availableSteps includes profileCompletion when hasProfileDataFromHealthKit is false")
    @MainActor
    func testAvailableStepsIncludesProfileCompletion() {
        // Given: A ViewModel without profile data from HealthKit
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        viewModel.hasProfileDataFromHealthKit = false

        // Then: profileCompletion should be in availableSteps
        #expect(viewModel.availableSteps.contains(.profileCompletion))
    }

    @Test("availableSteps excludes weeklyDistribution for collaborative program style")
    @MainActor
    func testAvailableStepsExcludesWeeklyDistributionForCollaborative() {
        // Given: A ViewModel with collaborative program style
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        viewModel.programStyle = .collaborative

        // Then: weeklyDistribution should not be in availableSteps
        #expect(!viewModel.availableSteps.contains(.weeklyDistribution))
    }

    @Test("availableSteps excludes shiftedDaySelection for collaborative program style")
    @MainActor
    func testAvailableStepsExcludesShiftedDaySelectionForCollaborative() {
        // Given: A ViewModel with collaborative program style
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        viewModel.programStyle = .collaborative

        // Then: shiftedDaySelection should not be in availableSteps
        #expect(!viewModel.availableSteps.contains(.shiftedDaySelection))
    }

    @Test("availableSteps includes shiftedDaySelection when shifted distribution is selected")
    @MainActor
    func testAvailableStepsIncludesShiftedDaySelectionWhenShifted() {
        // Given: A ViewModel with shifted weekly distribution
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        viewModel.programStyle = .coached
        viewModel.weeklyDistributionMode = .shifted

        // Then: shiftedDaySelection should be in availableSteps
        #expect(viewModel.availableSteps.contains(.shiftedDaySelection))
    }

    @Test("availableSteps excludes shiftedDaySelection when even distribution is selected")
    @MainActor
    func testAvailableStepsExcludesShiftedDaySelectionWhenEven() {
        // Given: A ViewModel with even weekly distribution
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        viewModel.programStyle = .coached
        viewModel.weeklyDistributionMode = .even

        // Then: shiftedDaySelection should not be in availableSteps
        #expect(!viewModel.availableSteps.contains(.shiftedDaySelection))
    }
}

// MARK: - OnboardingViewModel Profile Data Tests

@Suite("OnboardingViewModel Profile Data Tests")
struct OnboardingViewModelProfileDataTests {

    @Test("editHeightCm computes correctly from feet and inches")
    @MainActor
    func testEditHeightCmComputation() {
        // Given: A ViewModel with height in feet and inches
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // When: Setting height to 5 feet 10 inches
        viewModel.editHeightFeet = 5
        viewModel.editHeightInches = 10

        // Then: Should compute to approximately 177.8 cm
        let expectedCm = Double(5 * 12 + 10) * 2.54  // 70 inches * 2.54 = 177.8 cm
        #expect(abs(viewModel.editHeightCm - expectedCm) < 0.01)
    }

    @Test("canProceedToNext is false when high calorie days empty at shiftedDaySelection step")
    @MainActor
    func testCanProceedRequiresHighCalorieDays() {
        // Given: A ViewModel at shiftedDaySelection step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Configure required state to navigate to shiftedDaySelection
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5
        viewModel.programStyle = .coached
        viewModel.dietPreference = .balanced
        viewModel.calorieFloorType = .standard
        viewModel.trainingLevel = .lifting
        viewModel.weeklyDistributionMode = .shifted
        viewModel.proteinLevel = .moderate

        // Navigate to shiftedDaySelection step
        var iterations = 0
        while viewModel.currentStep != .shiftedDaySelection && iterations < 50 {
            viewModel.moveToNextStep()
            iterations += 1
        }

        // Verify we reached the step (with shifted distribution, this step should be available)
        #expect(
            viewModel.currentStep == .shiftedDaySelection,
            "Expected to reach shiftedDaySelection step but got \(viewModel.currentStep)"
        )

        // Clear high calorie days
        viewModel.highCalorieDays = []

        // Then: Cannot proceed without high calorie days
        #expect(viewModel.canProceedToNext == false)

        // When: Adding a high calorie day
        viewModel.highCalorieDays = [2]  // Monday

        // Then: Can proceed
        #expect(viewModel.canProceedToNext == true)
    }
}

// MARK: - OnboardingViewModel Collaborative Distribution Tests

@Suite("OnboardingViewModel Collaborative Distribution Tests")
struct OnboardingViewModelCollaborativeDistributionTests {

    @Test("initializeCollaborativeDays creates entries for all 7 days")
    @MainActor
    func testInitializeCollaborativeDaysCreatesSevenDays() {
        // Given: A ViewModel with no collaborative days set
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Set required values for calculation
        viewModel.goalViewModel.currentWeightKg = 80.0
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.trainingLevel = .lifting
        viewModel.proteinLevel = .moderate

        #expect(viewModel.collaborativeDays.isEmpty)

        // When: Initializing collaborative days
        viewModel.initializeCollaborativeDays()

        // Then: Should have entries for days 1-7
        #expect(viewModel.collaborativeDays.count == 7)
        for weekday in 1...7 {
            #expect(viewModel.collaborativeDays[weekday] != nil, "Day \(weekday) should exist")
        }
    }

    @Test("initializeCollaborativeDays does not reinitialize if already set")
    @MainActor
    func testInitializeCollaborativeDaysDoesNotReinitialize() {
        // Given: A ViewModel with collaborative days already set
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Set a custom value for day 2
        viewModel.collaborativeDays[2] = CollaborativeDayConfigStorage(
            calories: 1500,
            proteinGramsPerLb: 0.8,
            carbFatRatio: 0.5,
            isLocked: true
        )

        // When: Calling initialize again
        viewModel.initializeCollaborativeDays()

        // Then: Original values should be preserved
        #expect(viewModel.collaborativeDays[2]?.calories == 1500)
        #expect(viewModel.collaborativeDays[2]?.isLocked == true)
    }

    @Test("adjustCollaborativeCalories updates target day")
    @MainActor
    func testAdjustCollaborativeCaloriesUpdatesTargetDay() {
        // Given: A ViewModel with initialized collaborative days
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Initialize with equal distribution
        viewModel.goalViewModel.currentWeightKg = 80.0
        viewModel.proteinLevel = .moderate
        viewModel.calculatedCalories = 2000
        viewModel.weeklyCalorieBudget = 14000
        for weekday in 1...7 {
            viewModel.collaborativeDays[weekday] = CollaborativeDayConfigStorage(
                calories: 2000,
                proteinGramsPerLb: 0.8,
                carbFatRatio: 0.5,
                isLocked: false
            )
        }

        // When: Adjusting calories for Monday (day 2)
        viewModel.adjustCollaborativeCalories(forDay: 2, newCalories: 2500)

        // Then: Monday should have new calories
        #expect(viewModel.collaborativeDays[2]?.calories == 2500)
    }

    @Test("adjustCollaborativeCalories redistributes delta to unlocked days")
    @MainActor
    func testAdjustCollaborativeCaloriesRedistributesDelta() {
        // Given: A ViewModel with initialized collaborative days
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Initialize with equal distribution
        for weekday in 1...7 {
            viewModel.collaborativeDays[weekday] = CollaborativeDayConfigStorage(
                calories: 2000,
                proteinGramsPerLb: 0.8,
                carbFatRatio: 0.5,
                isLocked: false
            )
        }

        // When: Increasing Monday calories by 600 (delta = +600)
        viewModel.adjustCollaborativeCalories(forDay: 2, newCalories: 2600)

        // Then: Other 6 days should have ~100 fewer calories each
        // 600 / 6 = 100, so each should be 2000 - 100 = 1900
        for weekday in [1, 3, 4, 5, 6, 7] {
            let calories = viewModel.collaborativeDays[weekday]?.calories ?? 0
            #expect(abs(calories - 1900) < 1, "Day \(weekday) should be ~1900 cal")
        }
    }

    @Test("adjustCollaborativeCalories respects locked days")
    @MainActor
    func testAdjustCollaborativeCaloriesRespectsLockedDays() {
        // Given: A ViewModel with some locked days
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Initialize with day 1 (Sunday) locked
        for weekday in 1...7 {
            viewModel.collaborativeDays[weekday] = CollaborativeDayConfigStorage(
                calories: 2000,
                proteinGramsPerLb: 0.8,
                carbFatRatio: 0.5,
                isLocked: weekday == 1  // Only Sunday is locked
            )
        }

        // When: Increasing Monday calories by 500
        viewModel.adjustCollaborativeCalories(forDay: 2, newCalories: 2500)

        // Then: Sunday (locked) should not change
        #expect(viewModel.collaborativeDays[1]?.calories == 2000)

        // Other unlocked days should have reduced calories
        // 500 / 5 = 100 reduction per unlocked day
        for weekday in [3, 4, 5, 6, 7] {
            let calories = viewModel.collaborativeDays[weekday]?.calories ?? 0
            #expect(abs(calories - 1900) < 1, "Day \(weekday) should be ~1900 cal")
        }
    }

    @Test("resetCollaborativeDaysToEven distributes evenly")
    @MainActor
    func testResetCollaborativeDaysToEven() {
        // Given: A ViewModel with uneven calorie distribution
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        viewModel.weeklyCalorieBudget = 14000  // 2000/day average
        viewModel.proteinLevel = .moderate

        // Set uneven distribution
        viewModel.collaborativeDays[1] = CollaborativeDayConfigStorage(
            calories: 1500, proteinGramsPerLb: 0.8, carbFatRatio: 0.5, isLocked: true)
        viewModel.collaborativeDays[2] = CollaborativeDayConfigStorage(
            calories: 2500, proteinGramsPerLb: 0.8, carbFatRatio: 0.5, isLocked: false)

        // When: Resetting to even distribution
        viewModel.resetCollaborativeDaysToEven()

        // Then: All days should have equal calories (2000)
        for weekday in 1...7 {
            let calories = viewModel.collaborativeDays[weekday]?.calories ?? 0
            #expect(abs(calories - 2000) < 0.01, "Day \(weekday) should be 2000 cal")
            #expect(viewModel.collaborativeDays[weekday]?.isLocked == false, "Day \(weekday) should be unlocked")
        }
    }

    @Test("availableSteps includes collaborativeDistribution for collaborative program style")
    @MainActor
    func testAvailableStepsIncludesCollaborativeDistribution() {
        // Given: A ViewModel with collaborative program style
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        viewModel.programStyle = .collaborative

        // Then: collaborativeDistribution should be in availableSteps
        #expect(viewModel.availableSteps.contains(.collaborativeDistribution))
    }

    @Test("availableSteps excludes collaborativeDistribution for coached program style")
    @MainActor
    func testAvailableStepsExcludesCollaborativeDistributionForCoached() {
        // Given: A ViewModel with coached program style
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        viewModel.programStyle = .coached

        // Then: collaborativeDistribution should not be in availableSteps
        #expect(!viewModel.availableSteps.contains(.collaborativeDistribution))
    }

    @Test("canProceedToNext requires all days configured for collaborativeDistribution step")
    @MainActor
    func testCanProceedRequiresAllCollaborativeDaysConfigured() {
        // Given: A ViewModel at collaborativeDistribution step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Configure required state for collaborative flow
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5
        viewModel.programStyle = .collaborative
        viewModel.dietPreference = .balanced
        viewModel.calorieFloorType = .standard
        viewModel.trainingLevel = .lifting
        viewModel.proteinLevel = .moderate

        // Navigate to collaborativeDistribution step
        var iterations = 0
        while viewModel.currentStep != .collaborativeDistribution && iterations < 50 {
            viewModel.moveToNextStep()
            iterations += 1
        }

        // Verify we reached the step
        #expect(viewModel.currentStep == .collaborativeDistribution)

        // Clear all collaborative days
        viewModel.collaborativeDays = [:]

        // Then: Cannot proceed without all days configured
        #expect(viewModel.canProceedToNext == false)

        // When: Setting all days with valid calories
        for weekday in 1...7 {
            viewModel.collaborativeDays[weekday] = CollaborativeDayConfigStorage(
                calories: 2000,
                proteinGramsPerLb: 0.8,
                carbFatRatio: 0.5,
                isLocked: false
            )
        }

        // Then: Can proceed
        #expect(viewModel.canProceedToNext == true)
    }
}

// MARK: - OnboardingViewModel canProceed Validation Tests

@Suite("OnboardingViewModel canProceed Validation Tests")
struct OnboardingViewModelCanProceedValidationTests {

    @Test("canProceedToNext requires program style at programStyle step")
    @MainActor
    func testCanProceedRequiresProgramStyle() {
        // Given: A ViewModel at programStyle step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Configure required state
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5

        // Navigate to programStyle step
        var iterations = 0
        while viewModel.currentStep != .programStyle && iterations < 50 {
            viewModel.moveToNextStep()
            iterations += 1
        }
        #expect(viewModel.currentStep == .programStyle)

        // Clear program style
        viewModel.programStyle = nil

        // Then: Cannot proceed without program style
        #expect(viewModel.canProceedToNext == false)

        // When: Setting program style
        viewModel.programStyle = .coached

        // Then: Can proceed
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("canProceedToNext requires diet preference at dietPreference step")
    @MainActor
    func testCanProceedRequiresDietPreference() {
        // Given: A ViewModel at dietPreference step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Configure required state
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5
        viewModel.programStyle = .coached

        // Navigate to dietPreference step
        var iterations = 0
        while viewModel.currentStep != .dietPreference && iterations < 50 {
            viewModel.moveToNextStep()
            iterations += 1
        }
        #expect(viewModel.currentStep == .dietPreference)

        // Clear diet preference
        viewModel.dietPreference = nil

        // Then: Cannot proceed without diet preference
        #expect(viewModel.canProceedToNext == false)

        // When: Setting diet preference
        viewModel.dietPreference = .balanced

        // Then: Can proceed
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("canProceedToNext requires calorie floor at calorieFloor step")
    @MainActor
    func testCanProceedRequiresCalorieFloor() {
        // Given: A ViewModel at calorieFloor step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Configure required state
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5
        viewModel.programStyle = .coached
        viewModel.dietPreference = .balanced

        // Navigate to calorieFloor step
        var iterations = 0
        while viewModel.currentStep != .calorieFloor && iterations < 50 {
            viewModel.moveToNextStep()
            iterations += 1
        }
        #expect(viewModel.currentStep == .calorieFloor)

        // Clear calorie floor
        viewModel.calorieFloorType = nil

        // Then: Cannot proceed without calorie floor
        #expect(viewModel.canProceedToNext == false)

        // When: Setting calorie floor
        viewModel.calorieFloorType = .standard

        // Then: Can proceed
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("canProceedToNext requires weekly distribution at weeklyDistribution step")
    @MainActor
    func testCanProceedRequiresWeeklyDistribution() {
        // Given: A ViewModel at weeklyDistribution step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Configure required state
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5
        viewModel.programStyle = .coached
        viewModel.dietPreference = .balanced
        viewModel.calorieFloorType = .standard
        viewModel.trainingLevel = .lifting

        // Navigate to weeklyDistribution step
        var iterations = 0
        while viewModel.currentStep != .weeklyDistribution && iterations < 50 {
            viewModel.moveToNextStep()
            iterations += 1
        }
        #expect(viewModel.currentStep == .weeklyDistribution)

        // Clear weekly distribution
        viewModel.weeklyDistributionMode = nil

        // Then: Cannot proceed without weekly distribution
        #expect(viewModel.canProceedToNext == false)

        // When: Setting weekly distribution
        viewModel.weeklyDistributionMode = .even

        // Then: Can proceed
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("canProceedToNext requires protein level at proteinLevel step")
    @MainActor
    func testCanProceedRequiresProteinLevel() {
        // Given: A ViewModel at proteinLevel step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Configure required state
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5
        viewModel.programStyle = .coached
        viewModel.dietPreference = .balanced
        viewModel.calorieFloorType = .standard
        viewModel.trainingLevel = .lifting
        viewModel.weeklyDistributionMode = .even

        // Navigate to proteinLevel step
        var iterations = 0
        while viewModel.currentStep != .proteinLevel && iterations < 50 {
            viewModel.moveToNextStep()
            iterations += 1
        }
        #expect(viewModel.currentStep == .proteinLevel)

        // Clear protein level
        viewModel.proteinLevel = nil

        // Then: Cannot proceed without protein level
        #expect(viewModel.canProceedToNext == false)

        // When: Setting protein level
        viewModel.proteinLevel = .moderate

        // Then: Can proceed
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("canProceedToNext is true for setupConfirmation step")
    @MainActor
    func testCanProceedTrueForSetupConfirmation() {
        // Given: A ViewModel at setupConfirmation step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Configure required state
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5
        viewModel.programStyle = .coached
        viewModel.dietPreference = .balanced
        viewModel.calorieFloorType = .standard
        viewModel.trainingLevel = .lifting
        viewModel.weeklyDistributionMode = .even
        viewModel.proteinLevel = .moderate

        // Navigate to setupConfirmation step
        var iterations = 0
        while viewModel.currentStep != .setupConfirmation && iterations < 50 {
            viewModel.moveToNextStep()
            iterations += 1
        }
        #expect(viewModel.currentStep == .setupConfirmation)

        // Then: Can always proceed at setupConfirmation
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("canProceedToNext is true for faceID step")
    @MainActor
    func testCanProceedTrueForFaceID() {
        // Given: A ViewModel at faceID step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Configure required state
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5
        viewModel.programStyle = .coached
        viewModel.dietPreference = .balanced
        viewModel.calorieFloorType = .standard
        viewModel.trainingLevel = .lifting
        viewModel.weeklyDistributionMode = .even
        viewModel.proteinLevel = .moderate

        // Navigate to faceID step
        var iterations = 0
        while viewModel.currentStep != .faceID && iterations < 50 {
            viewModel.moveToNextStep()
            iterations += 1
        }
        #expect(viewModel.currentStep == .faceID)

        // Then: Can always proceed at faceID
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("canProceedToNext is true for notifications step")
    @MainActor
    func testCanProceedTrueForNotifications() {
        // Given: A ViewModel at notifications step
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Configure required state
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5
        viewModel.programStyle = .coached
        viewModel.dietPreference = .balanced
        viewModel.calorieFloorType = .standard
        viewModel.trainingLevel = .lifting
        viewModel.weeklyDistributionMode = .even
        viewModel.proteinLevel = .moderate

        // Navigate to notifications step
        var iterations = 0
        while viewModel.currentStep != .notifications && iterations < 50 {
            viewModel.moveToNextStep()
            iterations += 1
        }
        #expect(viewModel.currentStep == .notifications)

        // Then: Can always proceed at notifications
        #expect(viewModel.canProceedToNext == true)
    }
}

// MARK: - OnboardingViewModel Computed Properties Tests

@Suite("OnboardingViewModel Computed Properties Tests")
struct OnboardingViewModelComputedPropertiesTests {

    @Test("collaborativeSelectedDay defaults to Monday (weekday 2)")
    @MainActor
    func testCollaborativeSelectedDayDefaultsToMonday() {
        // Given: A new ViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: Default selected day should be Monday (2)
        #expect(viewModel.collaborativeSelectedDay == 2)
    }

    @Test("weeklyCalorieBudget defaults to 14000")
    @MainActor
    func testWeeklyCalorieBudgetDefault() {
        // Given: A new ViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: Default weekly budget should be 14000
        #expect(viewModel.weeklyCalorieBudget == 14000)
    }

    @Test("calculatedCalories starts at 0")
    @MainActor
    func testCalculatedCaloriesStartsAtZero() {
        // Given: A new ViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: Calculated calories should start at 0
        #expect(viewModel.calculatedCalories == 0)
    }

    @Test("calculatedDailyCalories starts empty")
    @MainActor
    func testCalculatedDailyCaloriesStartsEmpty() {
        // Given: A new ViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: Daily calories dictionary should be empty
        #expect(viewModel.calculatedDailyCalories.isEmpty)
    }

    @Test("highCalorieDays starts empty")
    @MainActor
    func testHighCalorieDaysStartsEmpty() {
        // Given: A new ViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: High calorie days should be empty
        #expect(viewModel.highCalorieDays.isEmpty)
    }

    @Test("hasProfileDataFromHealthKit starts false")
    @MainActor
    func testHasProfileDataFromHealthKitStartsFalse() {
        // Given: A new ViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Then: Should start as false
        #expect(viewModel.hasProfileDataFromHealthKit == false)
    }

    @Test("canSkip returns true for various skipAllowedSteps")
    @MainActor
    func testCanSkipForVariousSteps() {
        // Given: A ViewModel
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Configure for navigation
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.targetWeightKg = 70.0
        viewModel.editSex = "male"
        viewModel.editHeightFeet = 5
        viewModel.programStyle = .coached
        viewModel.dietPreference = .balanced
        viewModel.calorieFloorType = .standard
        viewModel.trainingLevel = .lifting
        viewModel.weeklyDistributionMode = .even
        viewModel.proteinLevel = .moderate

        // Test canSkip at various steps
        let skipAllowedSteps: [OnboardingStep] = [
            .goalType, .targetWeight, .profileCompletion, .programStyle,
            .dietPreference, .calorieFloor, .activityLevel, .weeklyDistribution,
            .proteinLevel, .setupConfirmation, .faceID, .notifications,
        ]

        for step in skipAllowedSteps where viewModel.availableSteps.contains(step) {
            // Navigate to the step
            var iterations = 0
            while viewModel.currentStep != step && iterations < 50 {
                viewModel.moveToNextStep()
                iterations += 1
            }
            if viewModel.currentStep == step {
                #expect(viewModel.canSkip == true, "canSkip should be true at \(step)")
            }
        }
    }
}
