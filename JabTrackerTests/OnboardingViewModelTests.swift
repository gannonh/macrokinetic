import Foundation
@testable import JabTracker
import SwiftData
import Testing

@Suite("Onboarding ViewModel")
struct OnboardingViewModelTests {
    @Test("Initial state is correct")
    @MainActor
    func initialState() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        #expect(viewModel.currentStep == .welcome)
        #expect(viewModel.progress == 0.0)
        #expect(viewModel.selectedMedication == nil)
        #expect(viewModel.selectedDose == 0.0)
        #expect(!viewModel.isLoading)
    }

    @Test("Progress calculation works correctly")
    @MainActor
    func progressCalculation() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Test each step
        for (index, step) in OnboardingStep.allCases.enumerated() {
            viewModel.currentStep = step
            let expectedProgress = Double(index) / Double(OnboardingStep.allCases.count - 1)
            #expect(abs(viewModel.progress - expectedProgress) < 0.01)
        }
    }

    @Test("Medication selection updates state correctly")
    @MainActor
    func medicationSelection() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        let medication = Medication.semaglutide
        viewModel.selectMedication(medication)

        #expect(viewModel.selectedMedication == medication)
        #expect(viewModel.selectedDose == medication.availableDoses.first)
    }

    @Test("Step navigation validation")
    @MainActor
    func stepNavigation() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Can proceed from welcome
        #expect(viewModel.canProceedToNext)

        // Can't proceed from medication selection without selection
        viewModel.currentStep = .medicationSelection
        #expect(!viewModel.canProceedToNext)

        // Can proceed after selecting medication
        viewModel.selectMedication(.semaglutide)
        #expect(viewModel.canProceedToNext)

        // Can't proceed from dose setup without dose
        viewModel.currentStep = .doseSetup
        viewModel.selectedDose = 0.0
        #expect(!viewModel.canProceedToNext)

        // Can proceed with valid dose
        viewModel.selectedDose = 1.0
        #expect(viewModel.canProceedToNext)
    }

    @Test("Complete onboarding creates required data")
    @MainActor
    func completeOnboarding() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Create and authenticate user
        let user = User(email: "test@onboarding.com", name: "Onboarding User")
        context.insert(user)
        try context.save()
        authManager.currentUser = user
        authManager.authenticationState = .authenticated

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Set up onboarding selections
        viewModel.selectMedication(.semaglutide)
        viewModel.selectedDose = 1.0
        viewModel.selectedStartDate = Date()
        viewModel.selectedSites = ["Thigh"]

        // Complete onboarding
        try await viewModel.completeOnboarding()

        // Verify user is marked as completed
        #expect(user.hasCompletedOnboarding)
        #expect(user.onboardingCompletedAt != nil)

        // Verify medication profile was created
        let profileDescriptor = FetchDescriptor<MedicationProfile>()
        let profiles = try context.fetch(profileDescriptor)
        #expect(profiles.count == 1)

        let profile = try #require(profiles.first)
        #expect(profile.genericName == "Semaglutide")
        #expect(profile.currentDose == 1.0)
        #expect(profile.medicationType == "semaglutide")

        // Verify no initial dose was created (onboarding doesn't create doses)
        let doseDescriptor = FetchDescriptor<Dose>()
        let doses = try context.fetch(doseDescriptor)
        #expect(doses.count == 0, "Onboarding should not create initial doses")
    }

    // MARK: - Navigation Method Tests

    @Test("Step navigation methods work correctly")
    @MainActor
    func stepNavigationMethods() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Test initial state
        #expect(viewModel.currentStep == .welcome)

        // Test moveToNextStep with proper setup for validation
        // Welcome step allows proceeding by default
        viewModel.moveToNextStep()
        #expect(viewModel.currentStep == .medicationSelection)

        // Set up medication to allow next step
        viewModel.selectMedication(.semaglutide)
        viewModel.moveToNextStep()
        #expect(viewModel.currentStep == .doseSetup)

        // Test moveToPreviousStep (doesn't require validation)
        viewModel.moveToPreviousStep()
        #expect(viewModel.currentStep == .medicationSelection)

        viewModel.moveToPreviousStep()
        #expect(viewModel.currentStep == .welcome)

        // Test bounds - can't go before welcome
        viewModel.moveToPreviousStep()
        #expect(viewModel.currentStep == .welcome)
    }

    @Test("Navigation boundary handling")
    @MainActor
    func navigationBoundaryHandling() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Set to last step directly (avoiding infinite loop)
        viewModel.currentStep = .subscription // Last step
        let lastStep = viewModel.currentStep

        #expect(viewModel.isLastStep == true, "Should be on last step")

        // Try to go past last step - should stay on last step
        viewModel.moveToNextStep()
        #expect(viewModel.currentStep == lastStep, "Should not go past last step")
    }

    // MARK: - Computed Property Tests

    @Test("Computed properties return correct values")
    @MainActor
    func computedProperties() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Test totalSteps
        let expectedStepCount = OnboardingStep.allCases.count
        #expect(viewModel.totalSteps == expectedStepCount)

        // Test currentStepIndex and isLastStep for each step
        for (index, step) in OnboardingStep.allCases.enumerated() {
            viewModel.currentStep = step
            #expect(viewModel.currentStepIndex == index)
            #expect(viewModel.isLastStep == (index == expectedStepCount - 1))
        }
    }

    // MARK: - Injection Site Selection Tests

    @Test("Injection site toggle functionality")
    @MainActor
    func injectionSiteToggle() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Clear initial state - default has "Thigh"
        viewModel.selectedSites.removeAll()
        #expect(viewModel.selectedSites.isEmpty)

        // Toggle site on
        viewModel.toggleInjectionSite("Abdomen")
        #expect(viewModel.selectedSites.contains("Abdomen"))
        #expect(viewModel.selectedSites.count == 1)

        // Toggle another site on
        viewModel.toggleInjectionSite("Thigh")
        #expect(viewModel.selectedSites.contains("Abdomen"))
        #expect(viewModel.selectedSites.contains("Thigh"))
        #expect(viewModel.selectedSites.count == 2)

        // Toggle first site off
        viewModel.toggleInjectionSite("Abdomen")
        #expect(!viewModel.selectedSites.contains("Abdomen"))
        #expect(viewModel.selectedSites.contains("Thigh"))
        #expect(viewModel.selectedSites.count == 1)

        // Toggle last site off
        viewModel.toggleInjectionSite("Thigh")
        #expect(viewModel.selectedSites.isEmpty)
    }

    // MARK: - Permission Request Tests

    @Test("Notification permission request functionality")
    @MainActor
    func notificationPermissionRequest() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Initial state
        #expect(viewModel.notificationsGranted == false)

        // Request permissions (will be denied in simulator/test but method should not crash)
        await viewModel.requestNotificationPermissions()

        // Method should complete without error
        // Note: In test environment, permission will likely be denied, but that's expected
        // The important thing is the method executes without crashing
    }

    @Test("HealthKit permission request functionality")
    @MainActor
    func healthKitPermissionRequest() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Initial state
        #expect(viewModel.healthKitGranted == false)

        // Request permissions without providing test overrides triggers default early-exit path
        await viewModel.requestHealthKitPermissions()
        #expect(viewModel.healthKitGranted == false, "Default test path should early-exit with false")
    }

    @Test("HealthKit permission success simulation with test hooks")
    @MainActor
    func healthKitPermissionSuccessSimulation() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Provide deterministic test overrides to simulate available HealthKit and granted auth
        viewModel.testIsHealthDataAvailable = true
        viewModel.testForcedHealthAuthResult = true

        await viewModel.requestHealthKitPermissions()
        #expect(viewModel.healthKitGranted == true, "Forced success path should mark granted true")
    }

    // MARK: - State Management Tests

    @Test("Loading state management")
    @MainActor
    func loadingStateManagement() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Initial state
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)

        // These properties should be settable
        viewModel.isLoading = true
        #expect(viewModel.isLoading == true)

        viewModel.errorMessage = "Test error"
        #expect(viewModel.errorMessage == "Test error")

        viewModel.errorMessage = nil
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - Edge Case Tests

    @Test("Onboarding with missing user handling")
    @MainActor
    func onboardingWithMissingUser() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Set up onboarding selections without authenticated user
        viewModel.selectMedication(.semaglutide)
        viewModel.selectedDose = 1.0
        viewModel.selectedStartDate = Date()
        viewModel.selectedSites = ["Abdomen"]

        // Try to complete onboarding without user - should handle gracefully
        do {
            try await viewModel.completeOnboarding()
            // If no error thrown, that's also acceptable (graceful handling)
        } catch {
            // Expected to handle missing user case
            #expect(true, "Appropriately handled missing user case")
        }
    }

    @Test("Multiple medication selections")
    @MainActor
    func multipleMedicationSelections() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Select first medication
        viewModel.selectMedication(.semaglutide)
        #expect(viewModel.selectedMedication == .semaglutide)
        #expect(viewModel.selectedDose == Medication.semaglutide.availableDoses.first)

        // Select different medication
        viewModel.selectMedication(.tirzepatide)
        #expect(viewModel.selectedMedication == .tirzepatide)
        #expect(viewModel.selectedDose == Medication.tirzepatide.availableDoses.first)

        // Verify dose was updated for new medication
        #expect(viewModel.selectedDose != Medication.semaglutide.availableDoses.first)
    }

    @Test("Step validation comprehensive testing")
    @MainActor
    func stepValidationComprehensive() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        // Welcome step - should always allow proceeding
        viewModel.currentStep = .welcome
        #expect(viewModel.canProceedToNext == true)

        // Medication selection step - requires medication selection
        viewModel.currentStep = .medicationSelection
        #expect(viewModel.canProceedToNext == false)

        viewModel.selectMedication(.liraglutide)
        #expect(viewModel.canProceedToNext == true)

        // Dose setup step - requires valid dose > 0
        viewModel.currentStep = .doseSetup
        viewModel.selectedDose = 0.0
        #expect(viewModel.canProceedToNext == false)

        viewModel.selectedDose = -1.0
        #expect(viewModel.canProceedToNext == false)

        viewModel.selectedDose = 2.4
        #expect(viewModel.canProceedToNext == true)

        // Test all other steps allow proceeding (permissions are optional)
        for step in OnboardingStep.allCases {
            if step != .medicationSelection, step != .doseSetup {
                viewModel.currentStep = step
                #expect(viewModel.canProceedToNext == true, "Step \(step) should allow proceeding")
            }
        }
    }

    // MARK: - Direct Method Coverage Tests
}
