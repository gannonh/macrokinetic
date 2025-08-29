import Foundation
import SwiftData
import UserNotifications
import HealthKit

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome {
        didSet {
            updateProgress()
        }
    }
    @Published var progress: Double = 0.0
    @Published var selectedMedication: Medication?
    @Published var selectedDose: Double = 0.0
    @Published var selectedStartDate: Date = Date()
    @Published var selectedSite: String = "Thigh"
    @Published var notificationsGranted: Bool = false
    @Published var healthKitGranted: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let dataController: DataController
    private let authManager: AuthenticationManager
    
    init(dataController: DataController = DataController.shared, authManager: AuthenticationManager) {
        self.dataController = dataController
        self.authManager = authManager
        self.updateProgress()
    }
    
    var totalSteps: Int {
        OnboardingStep.allCases.count
    }
    
    var currentStepIndex: Int {
        OnboardingStep.allCases.firstIndex(of: currentStep) ?? 0
    }
    
    var isLastStep: Bool {
        currentStep == OnboardingStep.allCases.last
    }
    
    var canProceedToNext: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .medicationSelection:
            return selectedMedication != nil
        case .doseSetup:
            return selectedDose > 0
        case .notifications, .healthKit, .subscription:
            return true
        }
    }
    
    func moveToNextStep() {
        guard !isLastStep, canProceedToNext else { return }
        
        if let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
           currentIndex + 1 < OnboardingStep.allCases.count {
            currentStep = OnboardingStep.allCases[currentIndex + 1]
        }
    }
    
    func moveToPreviousStep() {
        if let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
           currentIndex > 0 {
            currentStep = OnboardingStep.allCases[currentIndex - 1]
        }
    }
    
    func selectMedication(_ medication: Medication) {
        selectedMedication = medication
        // Set default dose for selected medication
        if let firstDose = medication.availableDoses.first {
            selectedDose = firstDose
        }
    }
    
    func requestNotificationPermissions() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                notificationsGranted = granted
            } else {
                notificationsGranted = settings.authorizationStatus == .authorized
            }
        } catch {
            errorMessage = "Failed to request notification permissions: \(error.localizedDescription)"
            notificationsGranted = false
        }
    }
    
    func requestHealthKitPermissions() async {
        isLoading = true
        defer { isLoading = false }
        
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitGranted = false
            return
        }
        
        let healthStore = HKHealthStore()
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            healthKitGranted = true
        } catch {
            errorMessage = "Failed to request HealthKit permissions: \(error.localizedDescription)"
            healthKitGranted = false
        }
    }
    
    func completeOnboarding() async throws {
        guard let user = authManager.currentUser,
              let selectedMedication = selectedMedication else {
            throw OnboardingError.missingRequiredData
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let context = dataController.container.mainContext
        
        // Create medication profile
        let medicationProfile = MedicationProfile(
            genericName: selectedMedication.displayName,
            brandName: selectedMedication.brands.first ?? "",
            currentDose: selectedDose,
            startDate: selectedStartDate,
            medicationType: selectedMedication.rawValue
        )
        context.insert(medicationProfile)
        
        // Create initial dose record
        let initialDose = Dose(
            amount: selectedDose,
            timestamp: selectedStartDate,
            site: selectedSite,
            notes: "Initial dose - onboarding",
            user: user,
            medication: medicationProfile
        )
        context.insert(initialDose)
        
        // Mark user onboarding as complete
        user.hasCompletedOnboarding = true
        user.onboardingCompletedAt = Date()
        user.updatedAt = Date()
        
        try context.save()
        
        // Store completion in UserDefaults as backup
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(Date(), forKey: "onboardingCompletedAt")
    }
    
    private func updateProgress() {
        progress = Double(currentStepIndex) / Double(totalSteps - 1)
    }
}

enum OnboardingStep: String, CaseIterable {
    case welcome = "welcome"
    case medicationSelection = "medication"
    case doseSetup = "dose"
    case notifications = "notifications"
    case healthKit = "health"
    case subscription = "subscription"
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to JabTracker"
        case .medicationSelection:
            return "Select Your Medication"
        case .doseSetup:
            return "Set Up Your First Dose"
        case .notifications:
            return "Enable Notifications"
        case .healthKit:
            return "Connect Health Data"
        case .subscription:
            return "JabTracker Premium"
        }
    }
}

enum OnboardingError: LocalizedError {
    case missingRequiredData
    case permissionsDenied
    case dataCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .missingRequiredData:
            return "Required onboarding data is missing"
        case .permissionsDenied:
            return "Required permissions were not granted"
        case .dataCreationFailed:
            return "Failed to save onboarding data"
        }
    }
}