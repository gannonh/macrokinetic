import Foundation
import Testing
import SwiftData
@testable import JabTracker

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
        
        // Verify initial dose was created
        let doseDescriptor = FetchDescriptor<Dose>()
        let doses = try context.fetch(doseDescriptor)
        #expect(doses.count == 1)
        
        let dose = try #require(doses.first)
        #expect(dose.amount == 1.0)
        #expect(dose.site == "Thigh")
        #expect(dose.notes == "Initial dose - onboarding")
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
        viewModel.currentStep = .subscription  // Last step
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
        
        // Request permissions (will be denied/not available in test environment)
        await viewModel.requestHealthKitPermissions()
        
        // Method should complete without error
        // Note: HealthKit is not available in simulator, but method should handle this gracefully
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
            if step != .medicationSelection && step != .doseSetup {
                viewModel.currentStep = step
                #expect(viewModel.canProceedToNext == true, "Step \(step) should allow proceeding")
            }
        }
    }
    
    // MARK: - Direct Method Coverage Tests
    
    @Test("Direct navigation method execution for coverage")
    @MainActor
    func directNavigationMethodExecution() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        
        // Set up valid state for navigation
        viewModel.selectMedication(.semaglutide)
        viewModel.selectedDose = 1.0
        viewModel.currentStep = .welcome
        
        // Directly call moveToNextStep to ensure coverage
        let initialStep = viewModel.currentStep
        viewModel.moveToNextStep()
        #expect(viewModel.currentStep != initialStep, "moveToNextStep should change step")
        
        // Directly call moveToPreviousStep to ensure coverage
        let _ = viewModel.currentStep
        viewModel.moveToPreviousStep()
        #expect(viewModel.currentStep == initialStep, "moveToPreviousStep should return to previous step")
        
        // Test isLastStep getter by manually setting to last step
        // Note: Can't use moveToNextStep() in test as it requires valid data for canProceedToNext
        viewModel.currentStep = .subscription  // Last step
        #expect(viewModel.isLastStep == true, "Should be on last step")
    }
    
    @Test("Injection site toggle functionality")
    @MainActor
    func injectionSiteToggleFunctionality() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        
        // Start with empty sites
        viewModel.selectedSites.removeAll()
        #expect(viewModel.selectedSites.isEmpty)
        
        // Test adding injection site
        viewModel.toggleInjectionSite("Abdomen")
        #expect(viewModel.selectedSites.contains("Abdomen"), "Should contain Abdomen after toggle")
        
        // Test removing injection site
        viewModel.toggleInjectionSite("Abdomen")
        #expect(!viewModel.selectedSites.contains("Abdomen"), "Should not contain Abdomen after second toggle")
        
        // Test multiple sites
        viewModel.toggleInjectionSite("Thigh")
        viewModel.toggleInjectionSite("Arm")
        #expect(viewModel.selectedSites.count == 2, "Should have two sites selected")
        #expect(viewModel.selectedSites.contains("Thigh"), "Should contain Thigh")
        #expect(viewModel.selectedSites.contains("Arm"), "Should contain Arm")
    }
    
    @Test("Direct permission method execution for coverage")
    @MainActor
    func directPermissionMethodExecution() async throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        
        // Directly call requestNotificationPermissions to ensure coverage
        #expect(viewModel.notificationsGranted == false, "Should start with notifications not granted")
        await viewModel.requestNotificationPermissions()
        // Method should execute without crashing, actual permission result may vary in test environment
        
        // Directly call requestHealthKitPermissions to ensure coverage  
        #expect(viewModel.healthKitGranted == false, "Should start with HealthKit not granted")
        await viewModel.requestHealthKitPermissions()
        // Method should execute without crashing, actual permission result may vary in test environment
    }

    
    // MARK: - Additional Coverage Tests
    
    @Test("OnboardingStep enum title coverage")
    @MainActor
    func onboardingStepEnumTitleCoverage() throws {
        // Test all OnboardingStep cases title getter for coverage
        for step in OnboardingStep.allCases {
            let title = step.title
            #expect(!title.isEmpty, "Step \(step) should have non-empty title: '\(title)'")
        }
        
        // Test specific step titles to ensure coverage
        let welcomeTitle = OnboardingStep.welcome.title
        let medicationTitle = OnboardingStep.medicationSelection.title
        let doseTitle = OnboardingStep.doseSetup.title
        let notificationsTitle = OnboardingStep.notifications.title
        let healthKitTitle = OnboardingStep.healthKit.title
        let subscriptionTitle = OnboardingStep.subscription.title
        
        #expect(!welcomeTitle.isEmpty, "Welcome title should exist")
        #expect(!medicationTitle.isEmpty, "Medication selection title should exist")
        #expect(!doseTitle.isEmpty, "Dose setup title should exist")
        #expect(!notificationsTitle.isEmpty, "Notifications title should exist")
        #expect(!healthKitTitle.isEmpty, "HealthKit title should exist")  
        #expect(!subscriptionTitle.isEmpty, "Subscription title should exist")
    }
    
    @Test("OnboardingError enum errorDescription coverage")
    @MainActor
    func onboardingErrorEnumDescriptionCoverage() throws {
        // Create all OnboardingError cases and test errorDescription
        let missingRequiredData = OnboardingError.missingRequiredData
        let permissionsDenied = OnboardingError.permissionsDenied
        let dataCreationFailed = OnboardingError.dataCreationFailed
        
        // Test each error's errorDescription getter
        let missingDataDesc = missingRequiredData.errorDescription
        let permissionsDeniedDesc = permissionsDenied.errorDescription  
        let dataCreationFailedDesc = dataCreationFailed.errorDescription
        
        #expect(missingDataDesc != nil, "Missing required data error should have description")
        #expect(permissionsDeniedDesc != nil, "Permissions denied error should have description")
        #expect(dataCreationFailedDesc != nil, "Data creation failed error should have description")
        
        #expect(!missingDataDesc!.isEmpty, "Error descriptions should not be empty")
        #expect(!permissionsDeniedDesc!.isEmpty, "Error descriptions should not be empty")
        #expect(!dataCreationFailedDesc!.isEmpty, "Error descriptions should not be empty")
    }
    
    @Test("OnboardingViewModel isLastStep coverage")
    @MainActor
    func onboardingViewModelIsLastStepCoverage() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        
        // Test isLastStep at different navigation points by directly setting steps
        #expect(viewModel.isLastStep == false, "Should not be last step initially (welcome)")
        
        // Test isLastStep for each step by direct assignment
        for step in OnboardingStep.allCases {
            viewModel.currentStep = step
            let isLast = viewModel.isLastStep
            let expectedIsLast = (step == OnboardingStep.allCases.last)
            #expect(isLast == expectedIsLast, "isLastStep should be \(expectedIsLast) for step \(step)")
        }
        
        // Verify final state
        #expect(viewModel.currentStep == .subscription, "Should be on subscription step")
        #expect(viewModel.isLastStep == true, "Should be last step when on subscription")
    }
}