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
}