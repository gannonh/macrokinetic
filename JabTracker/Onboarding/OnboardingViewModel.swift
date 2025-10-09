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
    @Published var selectedSites: Set<String> = ["Thigh"]  // Changed to Set for multiple sites
    @Published var notificationsGranted: Bool = false
    @Published var healthKitGranted: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Schedule configuration properties
    @Published var schedulePattern: SchedulePatternType = .weekly
    @Published var reminderMinutes: Int = 60  // 1 hour before
    @Published var enableMultipleReminders: Bool = false
    @Published var customScheduleValid: Bool = false

    private let dataController: DataController
    private let authManager: AuthenticationManager
    let pkEngine = PharmacokineticsEngine()  // Internal for ScheduleSetupView access

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
            return self.selectedDose > 0 && !self.selectedSites.isEmpty  // Require at least one site
        case .scheduleSetup:
            return validateScheduleConfiguration()
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
            self.errorMessage =
                "Failed to request notification permissions: \(error.localizedDescription)"
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
        let typesToShare: Set<HKSampleType> = [bodyMassType, bodyMassIndexType]

        if let forced = testForcedHealthAuthResult {
            self.healthKitGranted = forced
        } else {
            do {
                try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
                // Check authorization status for the weight type
                let authStatus = healthStore.authorizationStatus(for: bodyMassType)
                self.healthKitGranted = authStatus == .sharingAuthorized
                if !self.healthKitGranted {
                    self.errorMessage =
                        "HealthKit permissions were denied. You can enable them later in Settings."
                } else {
                    self.errorMessage = nil
                }
            } catch {
                self.errorMessage = "Failed to request HealthKit permissions: \(error.localizedDescription)"
                self.healthKitGranted = false
            }
        }
    }

    // MARK: - Schedule Configuration Methods

    /// Validates the current schedule configuration
    /// - Returns: true if configuration is valid, false otherwise
    func validateScheduleConfiguration() -> Bool {
        switch schedulePattern {
        case .weekly, .splitDose:
            return true
        case .custom:
            return customScheduleValid
        }
    }

    /// Saves schedule configuration and proceeds to next onboarding step if valid
    func saveScheduleConfiguration(
        pattern: SchedulePatternType,
        reminderMinutes: Int,
        enableMultiple: Bool
    ) {
        // Temporarily save pattern to validate
        let originalPattern = self.schedulePattern
        self.schedulePattern = pattern

        // Validate configuration
        guard validateScheduleConfiguration() else {
            // Restore original pattern on validation failure
            self.schedulePattern = originalPattern
            self.errorMessage = "Invalid schedule configuration. Please check your custom schedule settings."
            return
        }

        // Update remaining configuration properties
        self.reminderMinutes = reminderMinutes
        self.enableMultipleReminders = enableMultiple

        // Clear any previous errors
        self.errorMessage = nil

        // Proceed to next step
        moveToNextStep()
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

        // Check for existing profiles and prevent duplicates
        if try checkAndPreventDuplicateProfiles(for: user, in: context) {
            return  // User already has profiles, onboarding marked complete
        }

        // Create medication profile
        let medicationProfile = MedicationProfile(
            genericName: selectedMedication.displayName,
            brandName: selectedMedication.brands.first ?? "",
            currentDose: self.selectedDose,
            startDate: self.selectedStartDate,
            medicationType: selectedMedication.rawValue,
            preferredInjectionSites: Array(self.selectedSites))

        // Link medication profile to user
        medicationProfile.user = user
        context.insert(medicationProfile)

        #if DEBUG
            print("   ✅ Created new profile: \(medicationProfile.genericName) - \(medicationProfile.brandName)")
        #endif

        // Save medication profile first
        try context.save()

        // Create initial dose schedule
        try await createInitialSchedule(for: medicationProfile, in: context)

        // Mark user onboarding as complete
        user.hasCompletedOnboarding = true
        user.onboardingCompletedAt = Date()
        user.updatedAt = Date()

        try context.save()

        // Store completion in UserDefaults as backup
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(Date(), forKey: "onboardingCompletedAt")

        #if DEBUG
            print("   ✅ Onboarding completed successfully")
        #endif
    }

    /// Checks for existing medication profiles and prevents duplicate creation
    /// - Parameters:
    ///   - user: The current user
    ///   - context: SwiftData model context
    /// - Returns: true if user already has profiles (onboarding marked complete), false otherwise
    /// - Throws: SwiftData fetch errors
    private func checkAndPreventDuplicateProfiles(for user: User, in context: ModelContext) throws -> Bool {
        // Use the user's medicationProfiles relationship to check for existing profiles
        let existingProfiles = user.medicationProfiles ?? []

        #if DEBUG
            print("   🔍 Checking for existing profiles...")
            print("   Found \(existingProfiles.count) existing profile(s) for user")
            for (index, profile) in existingProfiles.enumerated() {
                print("   Profile \(index + 1): \(profile.genericName) - \(profile.brandName)")
            }
        #endif

        if !existingProfiles.isEmpty {
            // User already has profiles, mark onboarding as complete
            user.hasCompletedOnboarding = true
            user.onboardingCompletedAt = Date()
            user.updatedAt = Date()

            try context.save()

            // Store completion in UserDefaults as backup
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(Date(), forKey: "onboardingCompletedAt")

            #if DEBUG
                print("   ⚠️ User already has profiles, skipping duplicate creation")
                print("   ✅ Onboarding marked as complete")
            #endif

            return true
        }

        return false
    }

    /// Creates initial dose schedule for the medication profile
    private func createInitialSchedule(
        for medicationProfile: MedicationProfile,
        in context: ModelContext
    ) async throws {
        // Create schedule service
        let scheduleService = ScheduleService(context: context)

        // Build schedule configuration
        let scheduleConfig = ScheduleConfiguration(
            dayOfWeek: Calendar.current.component(.weekday, from: selectedStartDate),
            timeOfDay: TimeComponents(
                hour: Calendar.current.component(.hour, from: selectedStartDate),
                minute: Calendar.current.component(.minute, from: selectedStartDate)
            ),
            interval: 7,  // Weekly by default
            doseAmount: selectedDose,
            windowMinutesBefore: 120,  // 2 hours before
            windowMinutesAfter: 120,  // 2 hours after
            splitDoseCount: schedulePattern == .splitDose ? 2 : nil,
            splitIntervalMinutes: schedulePattern == .splitDose ? 720 : nil,  // 12 hours
            customRecurrence: nil  // Custom patterns not yet supported in onboarding
        )

        // Create the schedule
        _ = try scheduleService.createSchedule(
            for: medicationProfile,
            pattern: schedulePattern,
            startDate: selectedStartDate,
            baseSchedule: scheduleConfig
        )

        // Note: Notification scheduling will be handled by NotificationService
        // in a future update when the user grants notification permissions
    }

    private func updateProgress() {
        self.progress = Double(self.currentStepIndex) / Double(self.totalSteps - 1)
    }
}
