import Foundation
import HealthKit
import SwiftData
import UserNotifications

/// Result type for onboarding completion with explicit success, duplicate, and error states
enum OnboardingCompletionResult {
    case success
    case alreadyCompleted
    case failed(Error)
}

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

    // Time selection properties
    @Published var selectedDoseTime: Date  // For weekly/daily patterns
    @Published var selectedFirstDoseTime: Date  // For split-dose 1st time
    @Published var selectedSecondDoseTime: Date  // For split-dose 2nd time

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

        // Initialize time properties with defaults (8:00 AM and 8:00 PM)
        let calendar = Calendar.current
        let now = Date()

        // Default to 8:00 AM for dose time and first dose time
        self.selectedDoseTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
        self.selectedFirstDoseTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now

        // Default to 8:00 PM for second dose time
        self.selectedSecondDoseTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now

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

    /// Validates that split-dose times are 6-18 hours apart
    var areSplitDoseTimesValid: Bool {
        guard schedulePattern == .splitDose else {
            return true  // Not split-dose, so no validation needed
        }

        let calendar = Calendar.current
        let firstTime = calendar.dateComponents([.hour, .minute], from: selectedFirstDoseTime)
        let secondTime = calendar.dateComponents([.hour, .minute], from: selectedSecondDoseTime)

        let firstMinutes = (firstTime.hour ?? 0) * 60 + (firstTime.minute ?? 0)
        let secondMinutes = (secondTime.hour ?? 0) * 60 + (secondTime.minute ?? 0)

        let diff = abs(secondMinutes - firstMinutes)
        let actualDiff = min(diff, 1440 - diff)  // Handle midnight crossing

        return actualDiff >= 360 && actualDiff <= 1080  // 6-18 hours (360-1080 minutes)
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
        // Set appropriate schedule pattern based on medication frequency
        switch medication.frequency {
        case .daily:
            self.schedulePattern = .daily
        case .weekly:
            self.schedulePattern = .weekly
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
        case .daily, .weekly:
            return true
        case .splitDose:
            return areSplitDoseTimesValid
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
        // Validate reminder minutes input
        let validReminderMinutes = [15, 30, 60, 120]  // 15 min, 30 min, 1 hour, 2 hours
        guard validReminderMinutes.contains(reminderMinutes) else {
            self.errorMessage =
                "Invalid reminder time. Please select from available options (15, 30, 60, or 120 minutes)."
            return
        }

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

    func completeOnboarding() async -> OnboardingCompletionResult {
        guard let user = authManager.currentUser,
            let selectedMedication
        else {
            self.errorMessage = "Missing required onboarding data. Please complete all steps."
            return .failed(OnboardingError.missingRequiredData)
        }

        self.isLoading = true
        defer { isLoading = false }

        let context = self.dataController.container.mainContext

        // Check for existing profiles and prevent duplicates
        do {
            let alreadyCompleted = try checkAndPreventDuplicateProfiles(for: user, in: context)
            if alreadyCompleted {
                self.errorMessage = "Onboarding has already been completed for this account."
                return .alreadyCompleted
            }
        } catch {
            self.errorMessage = "Failed to check existing profiles: \(error.localizedDescription)"
            return .failed(error)
        }

        // Create and save medication profile
        let medicationProfile = createMedicationProfile(for: user, with: selectedMedication, in: context)
        do {
            try context.save()
        } catch {
            self.errorMessage = "Failed to save medication profile: \(error.localizedDescription)"
            return .failed(error)
        }

        // Create initial dose schedule
        do {
            try await createInitialSchedule(for: medicationProfile, in: context)
        } catch {
            self.errorMessage = "Failed to create dose schedule: \(error.localizedDescription)"
            return .failed(error)
        }

        // Finalize onboarding completion
        do {
            try finalizeOnboarding(for: user, in: context)
        } catch {
            self.errorMessage = "Failed to finalize onboarding: \(error.localizedDescription)"
            return .failed(error)
        }

        // Clear any error messages on success
        self.errorMessage = nil
        return .success
    }

    /// Creates medication profile for the user
    private func createMedicationProfile(
        for user: User,
        with medication: Medication,
        in context: ModelContext
    ) -> MedicationProfile {
        let medicationProfile = MedicationProfile(
            genericName: medication.displayName,
            brandName: medication.brands.first ?? "",
            currentDose: self.selectedDose,
            startDate: self.selectedStartDate,
            medicationType: medication.rawValue,
            preferredInjectionSites: Array(self.selectedSites))

        medicationProfile.user = user
        context.insert(medicationProfile)
        return medicationProfile
    }

    /// Finalizes onboarding by marking user as complete and persisting to UserDefaults
    private func finalizeOnboarding(for user: User, in context: ModelContext) throws {
        user.hasCompletedOnboarding = true
        user.onboardingCompletedAt = Date()
        user.updatedAt = Date()

        try context.save()

        // Store completion in UserDefaults as backup
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(Date(), forKey: "onboardingCompletedAt")
    }

    /// Checks for existing medication profiles and prevents duplicate creation
    /// - Parameters:
    ///   - user: The current user
    ///   - context: SwiftData model context
    /// - Returns: true if user already has profiles (onboarding marked complete), false otherwise
    /// - Throws: SwiftData fetch errors
    private func checkAndPreventDuplicateProfiles(for user: User, in context: ModelContext) throws -> Bool {
        let existingProfiles = user.medicationProfiles ?? []

        if !existingProfiles.isEmpty {
            // User already has profiles, mark onboarding as complete
            user.hasCompletedOnboarding = true
            user.onboardingCompletedAt = Date()
            user.updatedAt = Date()

            try context.save()

            // Store completion in UserDefaults as backup
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            UserDefaults.standard.set(Date(), forKey: "onboardingCompletedAt")
            return true
        }

        return false
    }

    /// Creates initial dose schedule for the medication profile
    private func createInitialSchedule(
        for medicationProfile: MedicationProfile,
        in context: ModelContext
    ) async throws {
        print("🔍 createInitialSchedule() called")
        print("🔍 Schedule pattern: \(schedulePattern)")
        print("🔍 Selected start date: \(selectedStartDate)")
        print("🔍 Selected dose time: \(selectedDoseTime)")
        print("🔍 Reminder minutes: \(reminderMinutes)")

        // Use shared schedule service (same instance used by NotificationService)
        guard let scheduleService = AppServices.shared.scheduleService else {
            print("❌ ERROR: AppServices.scheduleService not initialized!")
            print("❌ This should never happen - AppServices should be initialized in ContentView before onboarding")
            return
        }
        print("✅ Using AppServices.shared.scheduleService")

        // Build schedule configuration based on pattern
        let interval: Int
        let dayOfWeek: Int?

        switch schedulePattern {
        case .daily:
            interval = 1  // Daily dosing
            dayOfWeek = nil  // No specific day - every day
        case .weekly:
            interval = 7  // Weekly dosing
            dayOfWeek = Calendar.current.component(.weekday, from: selectedStartDate)
        case .splitDose:
            interval = 7  // Base interval for split-dose (actual split handled by splitIntervalMinutes)
            dayOfWeek = nil  // Split-dose doesn't use specific day
        case .custom:
            interval = 7  // Default for custom patterns
            dayOfWeek = Calendar.current.component(.weekday, from: selectedStartDate)
        }

        // Determine time components based on pattern
        let calendar = Calendar.current
        let timeOfDay: TimeComponents
        let secondTimeOfDay: TimeComponents?

        if schedulePattern == .splitDose {
            // Split-dose: Use both time pickers
            timeOfDay = TimeComponents(
                hour: calendar.component(.hour, from: selectedFirstDoseTime),
                minute: calendar.component(.minute, from: selectedFirstDoseTime)
            )
            secondTimeOfDay = TimeComponents(
                hour: calendar.component(.hour, from: selectedSecondDoseTime),
                minute: calendar.component(.minute, from: selectedSecondDoseTime)
            )
        } else {
            // Weekly/Daily: Use single time picker
            timeOfDay = TimeComponents(
                hour: calendar.component(.hour, from: selectedDoseTime),
                minute: calendar.component(.minute, from: selectedDoseTime)
            )
            secondTimeOfDay = nil
        }

        let scheduleConfig = ScheduleConfiguration(
            dayOfWeek: dayOfWeek,
            timeOfDay: timeOfDay,
            secondTimeOfDay: secondTimeOfDay,
            interval: interval,
            doseAmount: selectedDose,
            windowMinutesBefore: 120,  // 2 hours before
            windowMinutesAfter: 120,  // 2 hours after
            splitDoseCount: schedulePattern == .splitDose ? 2 : nil,
            // Medical accuracy: Weekly medications split into twice-weekly dosing
            // TimeConstants.splitDoseInterval = 3.5 days = 84 hours (e.g., Wed 8pm + Sun 8am)
            splitIntervalMinutes: schedulePattern == .splitDose ? TimeConstants.splitDoseInterval : nil,
            customRecurrence: nil  // Custom patterns not yet supported in onboarding
        )

        // Combine selectedStartDate (date component) with selected time (time component)
        let actualStartDate: Date
        if schedulePattern == .splitDose {
            // For split-dose, use the first dose time
            actualStartDate =
                calendar.date(
                    bySettingHour: timeOfDay.hour,
                    minute: timeOfDay.minute,
                    second: 0,
                    of: selectedStartDate
                ) ?? selectedStartDate
        } else {
            // For weekly/daily, use the selected dose time
            actualStartDate =
                calendar.date(
                    bySettingHour: timeOfDay.hour,
                    minute: timeOfDay.minute,
                    second: 0,
                    of: selectedStartDate
                ) ?? selectedStartDate
        }

        print("🔍 Actual start date (combined): \(actualStartDate)")
        print("🔍 Current date/time: \(Date())")

        // Create the schedule
        let schedule = try scheduleService.createSchedule(
            for: medicationProfile,
            pattern: schedulePattern,
            startDate: actualStartDate,
            baseSchedule: scheduleConfig
        )

        print("🔍 Schedule created with ID: \(schedule.id)")
        print("🔍 Schedule active: \(schedule.isActive)")

        // Configure NotificationService with reminder preferences
        print("🔍 Configuring notifications...")
        print("🔍 Notifications granted: \(notificationsGranted)")

        if let notificationService = AppServices.shared.notificationService {
            print("🔍 Setting reminderMinutesBefore to: \(reminderMinutes)")
            notificationService.reminderMinutesBefore = reminderMinutes

            // Enable notifications if user granted permission
            if notificationsGranted {
                print("🔍 Attempting to enable notifications...")
                do {
                    try await notificationService.enable()
                    print("✅ Notifications enabled successfully")
                } catch {
                    // Log the error but don't fail onboarding if notification setup fails
                    print("⚠️ Failed to enable notifications during onboarding: \(error.localizedDescription)")
                    // Continue with onboarding - user can enable notifications later in Settings
                }
            } else {
                print("⚠️ Notifications not granted, skipping enablement")
            }
        } else {
            print("⚠️ NotificationService not available")
        }
    }

    private func updateProgress() {
        self.progress = Double(self.currentStepIndex) / Double(self.totalSteps - 1)
    }
}
