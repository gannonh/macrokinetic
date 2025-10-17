import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("Onboarding ViewModel Coverage Tests")
struct OnboardingViewModelCoverageTests {
    @Test("Direct navigation method execution for coverage")
    @MainActor
    func directNavigationMethodExecution() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Test initial state
        #expect(viewModel.currentStep == .welcome, "Should start at welcome step")

        // Call moveToNextStep() directly to improve coverage
        viewModel.moveToNextStep()
        #expect(viewModel.currentStep == .medicationSelection, "Should move to medication selection")

        // Call moveToPreviousStep() directly
        viewModel.moveToPreviousStep()
        #expect(viewModel.currentStep == .welcome, "Should move back to welcome")

        // Test boundary - try to go before first step
        viewModel.moveToPreviousStep()
        #expect(
            viewModel.currentStep == .welcome, "Should stay at welcome when trying to go before first")

        // Navigate to last step
        viewModel.currentStep = .subscription
        #expect(viewModel.isLastStep == true, "Should be at last step")

        // Try to go past last step
        viewModel.moveToNextStep()
        #expect(viewModel.currentStep == .subscription, "Should stay at last step")
    }

    @Test("Injection site toggle functionality")
    @MainActor
    func injectionSiteToggleFunctionality() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Initial state - Thigh is pre-selected
        #expect(viewModel.selectedSites.contains("Thigh"), "Thigh should be pre-selected")
        #expect(viewModel.selectedSites.count == 1, "Should have one site initially")

        // Toggle off the pre-selected site
        viewModel.toggleInjectionSite("Thigh")
        #expect(!viewModel.selectedSites.contains("Thigh"), "Thigh should be deselected")
        #expect(viewModel.selectedSites.isEmpty, "Should have no sites selected")

        // Toggle on a new site
        viewModel.toggleInjectionSite("Abdomen")
        #expect(viewModel.selectedSites.contains("Abdomen"), "Abdomen should be selected")
        #expect(viewModel.selectedSites.count == 1, "Should have one site selected")

        // Add another site
        viewModel.toggleInjectionSite("Arm")
        #expect(viewModel.selectedSites.contains("Arm"), "Arm should be selected")
        #expect(viewModel.selectedSites.count == 2, "Should have two sites selected")

        // Toggle off one of the selected sites
        viewModel.toggleInjectionSite("Abdomen")
        #expect(!viewModel.selectedSites.contains("Abdomen"), "Abdomen should be deselected")
        #expect(viewModel.selectedSites.count == 1, "Should have one site selected")
    }

    @Test("OnboardingStep enum title coverage")
    @MainActor
    func onboardingStepEnumTitleCoverage() throws {
        // Test all OnboardingStep title properties for coverage
        #expect(
            OnboardingStep.welcome.title == "Welcome to JabTracker",
            "Welcome step should have correct title")
        #expect(
            OnboardingStep.medicationSelection.title == "Select Your Medication",
            "Medication selection step should have correct title")
        #expect(
            OnboardingStep.doseSetup.title == "Set Up Your First Dose",
            "Dose setup step should have correct title")
        #expect(
            OnboardingStep.scheduleSetup.title == "Set Up Your Schedule",
            "Schedule setup step should have correct title")
        #expect(
            OnboardingStep.notifications.title == "Enable Notifications",
            "Notifications step should have correct title")
        #expect(
            OnboardingStep.healthKit.title == "Connect Health Data",
            "HealthKit step should have correct title")
        #expect(
            OnboardingStep.subscription.title == "JabTracker Premium",
            "Subscription step should have correct title")

        // Test allCases
        let allSteps = OnboardingStep.allCases
        #expect(allSteps.count == 7, "Should have 7 onboarding steps")
        #expect(allSteps.first == .welcome, "First step should be welcome")
        #expect(allSteps.last == .subscription, "Last step should be subscription")
    }

    @Test("OnboardingError enum errorDescription coverage")
    @MainActor
    func onboardingErrorEnumCoverage() throws {
        // Test all OnboardingError errorDescription properties for coverage
        let missingDataDesc = OnboardingError.missingRequiredData.errorDescription
        let permissionsDeniedDesc = OnboardingError.permissionsDenied.errorDescription
        let dataCreationFailedDesc = OnboardingError.dataCreationFailed.errorDescription

        #expect(missingDataDesc != nil, "Missing required data error should have description")
        #expect(permissionsDeniedDesc != nil, "Permissions denied error should have description")
        #expect(dataCreationFailedDesc != nil, "Data creation failed error should have description")

        #expect(missingDataDesc?.isEmpty == false, "Error descriptions should not be empty")
        #expect(permissionsDeniedDesc?.isEmpty == false, "Error descriptions should not be empty")
        #expect(dataCreationFailedDesc?.isEmpty == false, "Error descriptions should not be empty")
    }

    @Test("OnboardingViewModel isLastStep coverage")
    @MainActor
    func onboardingViewModelIsLastStepCoverage() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Test isLastStep for all steps
        for step in OnboardingStep.allCases {
            viewModel.currentStep = step
            let expectedIsLast = step == OnboardingStep.allCases.last
            #expect(
                viewModel.isLastStep == expectedIsLast,
                "isLastStep should be \(expectedIsLast) for step \(step)")
        }
    }

    @Test("completeOnboarding prevents duplicate profiles")
    @MainActor
    func completeOnboardingPreventsDuplicates() async throws {
        let dataController = DataController.testContainer()
        let context = dataController.container.mainContext

        // Create a user with an existing medication profile
        let user = User(email: "test@example.com", name: "Test User")
        context.insert(user)

        let existingProfile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 0.5,
            startDate: Date(),
            medicationType: "semaglutide",
            preferredInjectionSites: ["Thigh"]
        )
        existingProfile.user = user
        context.insert(existingProfile)

        try context.save()

        // Setup auth manager and viewmodel
        let authManager = AuthenticationManager(dataController: dataController)
        authManager.currentUser = user

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Select medication for onboarding
        viewModel.selectMedication(.semaglutide)
        viewModel.selectedDose = 1.0
        viewModel.selectedStartDate = Date()
        viewModel.toggleInjectionSite("Abdomen")

        // Try to complete onboarding - should detect existing profile and return alreadyCompleted
        let result = await viewModel.completeOnboarding()

        // Should return alreadyCompleted result
        guard case .alreadyCompleted = result else {
            Issue.record("Expected .alreadyCompleted result, got \(result)")
            return
        }

        // User should have onboarding marked complete
        #expect(user.hasCompletedOnboarding == true, "User should have onboarding marked complete")
        #expect(user.onboardingCompletedAt != nil, "Onboarding completion date should be set")

        // Should still only have 1 profile (no duplicate created)
        let profilesCount = (user.medicationProfiles ?? []).count
        #expect(profilesCount == 1, "Should have exactly 1 profile (no duplicate created)")

        // Verify error message was set
        #expect(viewModel.errorMessage != nil, "Error message should be set for already completed")
    }

    @Test("currentStepIndex returns correct index for all steps")
    @MainActor
    func currentStepIndexReturnsCorrectIndex() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Test currentStepIndex for all steps to trigger implicit closure
        for (expectedIndex, step) in OnboardingStep.allCases.enumerated() {
            viewModel.currentStep = step
            let actualIndex = viewModel.currentStepIndex
            #expect(
                actualIndex == expectedIndex,
                "currentStepIndex should be \(expectedIndex) for step \(step), got \(actualIndex)")
        }
    }

    @Test("saveScheduleConfiguration validates reminder minutes")
    @MainActor
    func saveScheduleConfigurationValidatesReminderMinutes() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Navigate to schedule setup step
        viewModel.currentStep = .scheduleSetup

        // Try to save with invalid reminder minutes (not in [15, 30, 60, 120])
        viewModel.saveScheduleConfiguration(pattern: .weekly, reminderMinutes: 45, enableMultiple: false)

        // Should set error message
        #expect(viewModel.errorMessage != nil, "Error message should be set for invalid reminder minutes")
        #expect(
            viewModel.errorMessage?.contains("Invalid reminder time") == true,
            "Error should mention invalid reminder time")

        // Should not have moved to next step
        #expect(viewModel.currentStep == .scheduleSetup, "Should stay on schedule setup step after error")
    }

    @Test("saveScheduleConfiguration with valid parameters")
    @MainActor
    func saveScheduleConfigurationWithValidParameters() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Navigate to schedule setup step
        viewModel.currentStep = .scheduleSetup

        // Save with valid parameters
        viewModel.saveScheduleConfiguration(pattern: .weekly, reminderMinutes: 30, enableMultiple: true)

        // Should have no error
        #expect(viewModel.errorMessage == nil, "Should have no error message with valid parameters")

        // Should have updated configuration
        #expect(viewModel.schedulePattern == .weekly, "Schedule pattern should be updated")
        #expect(viewModel.reminderMinutes == 30, "Reminder minutes should be updated")
        #expect(viewModel.enableMultipleReminders == true, "Multiple reminders should be enabled")

        // Should have moved to next step
        #expect(viewModel.currentStep == .notifications, "Should move to notifications step")
    }

    @Test("completeOnboarding with missing user")
    @MainActor
    func completeOnboardingWithMissingUser() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Don't set current user - authManager.currentUser will be nil
        viewModel.selectMedication(.semaglutide)
        viewModel.selectedDose = 0.5

        // Try to complete onboarding
        let result = await viewModel.completeOnboarding()

        // Should fail with missing required data
        guard case .failed(let error) = result,
            let onboardingError = error as? OnboardingError
        else {
            Issue.record("Expected .failed result with OnboardingError, got \(result)")
            return
        }

        #expect(onboardingError == .missingRequiredData, "Should fail with missing required data error")
        #expect(viewModel.errorMessage != nil, "Should have error message")
        #expect(
            viewModel.errorMessage?.contains("Missing required") == true,
            "Error should mention missing required data")
    }

    @Test("completeOnboarding with missing medication")
    @MainActor
    func completeOnboardingWithMissingMedication() async throws {
        let dataController = DataController.testContainer()
        let context = dataController.container.mainContext
        let authManager = AuthenticationManager(dataController: dataController)

        // Create and set user
        let user = User(email: "test@example.com", name: "Test User")
        context.insert(user)
        try context.save()
        authManager.currentUser = user

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Don't select medication - selectedMedication will be nil
        viewModel.selectedDose = 0.5

        // Try to complete onboarding
        let result = await viewModel.completeOnboarding()

        // Should fail with missing required data
        guard case .failed(let error) = result,
            let onboardingError = error as? OnboardingError
        else {
            Issue.record("Expected .failed result with OnboardingError, got \(result)")
            return
        }

        #expect(onboardingError == .missingRequiredData, "Should fail with missing required data error")
    }
}
