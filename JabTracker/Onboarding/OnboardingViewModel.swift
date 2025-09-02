import Foundation
import HealthKit
import SwiftData
import UserNotifications

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome {
        didSet {
            self.updateProgress()
        }
    }

    @Published var progress: Double = 0.0
    @Published var selectedMedication: Medication?
    @Published var selectedDose: Double = 0.0
    @Published var selectedStartDate: Date = .init()
    @Published var selectedSites: Set<String> = ["Thigh"] // Changed to Set for multiple sites
    @Published var notificationsGranted: Bool = false
    @Published var healthKitGranted: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let dataController: DataController
    private let authManager: AuthenticationManager

    // Test hooks (internal so testable with @testable import). In production these remain nil.
    // They allow unit tests to simulate HealthKit availability and forced authorization result
    // without invoking real HKHealthStore UI.
    var testIsHealthDataAvailable: Bool?
    var testForcedHealthAuthResult: Bool?

    init(dataController: DataController, authManager: AuthenticationManager) {
        self.dataController = dataController
        self.authManager = authManager
        self.updateProgress()
    }

    var totalSteps: Int {
        OnboardingStep.allCases.count
    }

    var currentStepIndex: Int {
        OnboardingStep.allCases.firstIndex(of: self.currentStep) ?? 0
    }

    var isLastStep: Bool {
        self.currentStep == OnboardingStep.allCases.last
    }

    var canProceedToNext: Bool {
        switch self.currentStep {
        case .welcome:
            return true
        case .medicationSelection:
            return self.selectedMedication != nil
        case .doseSetup:
            return self.selectedDose > 0 && !self.selectedSites.isEmpty // Require at least one site
        case .notifications, .healthKit, .subscription:
            return true
        }
    }

    func moveToNextStep() {
        guard !self.isLastStep, self.canProceedToNext else { return }

        if let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
           currentIndex + 1 < OnboardingStep.allCases.count
        {
            self.currentStep = OnboardingStep.allCases[currentIndex + 1]
        }
    }

    func moveToPreviousStep() {
        if let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
           currentIndex > 0
        {
            self.currentStep = OnboardingStep.allCases[currentIndex - 1]
        }
    }

    func selectMedication(_ medication: Medication) {
        self.selectedMedication = medication
        // Set default dose for selected medication
        if let firstDose = medication.availableDoses.first {
            self.selectedDose = firstDose
        }
    }

    func toggleInjectionSite(_ site: String) {
        if self.selectedSites.contains(site) {
            self.selectedSites.remove(site)
        } else {
            self.selectedSites.insert(site)
        }
    }

    func requestNotificationPermissions() async {
        self.isLoading = true
        defer { isLoading = false }

        do {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound]
                )
                self.notificationsGranted = granted
            } else {
                self.notificationsGranted = settings.authorizationStatus == .authorized
            }
        } catch {
            self.errorMessage = "Failed to request notification permissions: \(error.localizedDescription)"
            self.notificationsGranted = false
        }
    }

    func requestHealthKitPermissions() async {
        self.isLoading = true
        defer { isLoading = false }

        // Short-circuit during unit / snapshot / Swift Testing runs to avoid hanging on real
        // HealthKit permission UI (which requires user interaction that's not available in
        // non-UI test environments). We detect a test context via the presence of the
        // XCTest configuration environment variable. This keeps the production code path
        // untouched while allowing fast, deterministic tests.
    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil,
       self.testIsHealthDataAvailable == nil, self.testForcedHealthAuthResult == nil
        {
            // Default early-exit path (legacy behavior) when no explicit test override supplied.
            self.healthKitGranted = false
            return
        }

    let isAvailable = self.testIsHealthDataAvailable ?? HKHealthStore.isHealthDataAvailable()
        guard isAvailable else {
            self.healthKitGranted = false
            return
        }

        let healthStore = HKHealthStore()
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass),
              let bodyMassIndexType = HKObjectType.quantityType(forIdentifier: .bodyMassIndex)
        else {
            self.errorMessage = "Failed to create HealthKit types"
            self.healthKitGranted = false
            return
        }

        let typesToRead: Set<HKObjectType> = [bodyMassType, bodyMassIndexType]

    if let forced = testForcedHealthAuthResult {
            self.healthKitGranted = forced
        } else {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
                self.healthKitGranted = true
            } catch {
                self.errorMessage = "Failed to request HealthKit permissions: \(error.localizedDescription)"
                self.healthKitGranted = false
            }
        }
    }

    func completeOnboarding() async throws {
        guard let user = authManager.currentUser,
              let selectedMedication
        else {
            throw OnboardingError.missingRequiredData
        }

        self.isLoading = true
        defer { isLoading = false }

        let context = self.dataController.container.mainContext

        // Create medication profile
        let medicationProfile = MedicationProfile(
            genericName: selectedMedication.displayName,
            brandName: selectedMedication.brands.first ?? "",
            currentDose: self.selectedDose,
            startDate: self.selectedStartDate,
            medicationType: selectedMedication.rawValue)
        context.insert(medicationProfile)

        // Create initial dose record with first selected site
        let primarySite = self.selectedSites.first ?? "Thigh"
        let initialDose = Dose(
            amount: selectedDose,
            timestamp: selectedStartDate,
            site: primarySite,
            notes: "Initial dose - onboarding",
            user: user,
            medication: medicationProfile)
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
        self.progress = Double(self.currentStepIndex) / Double(self.totalSteps - 1)
    }
}

enum OnboardingStep: String, CaseIterable {
    case welcome
    case medicationSelection = "medication"
    case doseSetup = "dose"
    case notifications
    case healthKit = "health"
    case subscription

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
