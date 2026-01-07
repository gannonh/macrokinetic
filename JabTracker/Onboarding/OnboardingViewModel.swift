//
//  OnboardingViewModel.swift
//  JabTracker
//
//  ViewModel for the v0.6.0 onboarding flow.
//

import Foundation
import OSLog
import SwiftData

// MARK: - OnboardingViewModel

// Note: OnboardingCompletionResult is defined in LegacyOnboardingViewModel.swift
// and is shared between both implementations for API compatibility.

/// ViewModel for managing onboarding flow state and navigation.
///
/// Uses `@Observable` (iOS 17+) for automatic view updates.
/// Manages step navigation, progress calculation, goal/program configuration,
/// and completion logic.
@Observable
@MainActor
final class OnboardingViewModel {
    // MARK: - Properties

    /// Current step in the onboarding flow
    var currentStep: OnboardingStep = .welcome {
        didSet {
            updateProgress()
        }
    }

    /// Progress value from 0.0 to 1.0
    var progress: Double = 0.0

    /// Whether an async operation is in progress
    var isLoading: Bool = false

    /// Error message for display in UI
    var errorMessage: String?

    // MARK: - Goal Configuration (from GoalWizardViewModel)

    /// Goal wizard state for goal configuration steps
    let goalViewModel = GoalWizardViewModel()

    // MARK: - Profile Completion State

    /// Height in feet (for US users)
    var editHeightFeet: Int = 5

    /// Height in inches (remainder)
    var editHeightInches: Int = 7

    /// Biological sex for TDEE calculation
    var editSex: String = ""

    /// Date of birth for age calculation
    var editBirthday: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()

    /// Height in cm from feet/inches
    var editHeightCm: Double {
        let totalInches = Double(editHeightFeet * 12 + editHeightInches)
        return totalInches * 2.54
    }

    /// Whether profile data was populated from HealthKit (skip profileCompletion step)
    var hasProfileDataFromHealthKit: Bool = false

    // MARK: - Program Configuration State

    /// Selected program style (coached, collaborative, manual)
    var programStyle: ProgramStyle?

    /// Selected diet preference (balanced, low-carb, high-protein, keto)
    var dietPreference: DietPreference?

    /// Selected calorie floor type (standard, aggressive, very aggressive)
    var calorieFloorType: CalorieFloorType?

    /// Selected training/activity level
    var trainingLevel: TrainingLevel?

    /// Selected weekly distribution mode (even, front-loaded, back-loaded)
    var weeklyDistributionMode: WeeklyDistributionMode?

    /// Selected protein level (moderate, high, very high)
    var proteinLevel: ProteinLevel?

    /// Days with higher calorie targets for Shifted distribution (weekday numbers: 2=Mon through 1=Sun)
    var highCalorieDays: Set<Int> = []

    // MARK: - Calculated Targets (populated after setupConfirmation)

    /// Calculated daily calorie target
    var calculatedCalories: Double = 0

    /// Calculated daily protein target in grams
    var calculatedProtein: Double = 0

    /// Calculated daily fat target in grams
    var calculatedFat: Double = 0

    /// Calculated daily carbs target in grams
    var calculatedCarbs: Double = 0

    // MARK: - Private Properties

    private let dataController: DataController
    private let authManager: AuthenticationManager
    private let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "OnboardingViewModel"
    )

    // Services initialized lazily when context is available
    private var tdeeService: TDEEService?
    private var metricsService: MetricsService?

    // MARK: - Computed Properties

    /// Steps available in the onboarding flow (filters out skippable steps)
    var availableSteps: [OnboardingStep] {
        OnboardingStep.allCases.filter { step in
            switch step {
            case .profileCompletion:
                // Skip profileCompletion if HealthKit provided all profile data
                return !hasProfileDataFromHealthKit

            case .weeklyDistribution, .shiftedDaySelection:
                // Skip for Collaborative - they customize per-day in Strategy
                if programStyle == .collaborative {
                    return false
                }
                // shiftedDaySelection only shows when Shifted distribution is selected
                if step == .shiftedDaySelection {
                    return weeklyDistributionMode == .shifted
                }
                return true

            default:
                return true
            }
        }
    }

    /// Total number of steps in the onboarding flow
    var totalSteps: Int {
        availableSteps.count
    }

    /// Index of the current step (0-based)
    var currentStepIndex: Int {
        availableSteps.firstIndex(of: currentStep) ?? 0
    }

    /// Whether the current step is the last step
    var isLastStep: Bool {
        currentStep == availableSteps.last
    }

    /// Whether the user can proceed to the next step.
    var canProceedToNext: Bool {
        switch currentStep {
        case .welcome, .uspShowcase, .healthKit:
            return true
        case .goalType:
            return goalViewModel.goalType != nil
        case .targetWeight:
            return goalViewModel.canContinue  // Uses GoalWizardViewModel validation
        case .profileCompletion:
            return isProfileDataComplete
        case .programStyle:
            return programStyle != nil
        case .dietPreference:
            return dietPreference != nil
        case .calorieFloor:
            return calorieFloorType != nil
        case .activityLevel:
            return trainingLevel != nil
        case .weeklyDistribution:
            return weeklyDistributionMode != nil
        case .proteinLevel:
            return proteinLevel != nil
        case .shiftedDaySelection:
            return !highCalorieDays.isEmpty  // At least one day must be selected
        case .setupConfirmation:
            return true  // Summary step, always can proceed
        case .faceID, .notifications, .completion:
            return true
        }
    }

    /// Whether all profile fields are filled in
    private var isProfileDataComplete: Bool {
        let hasHeight = editHeightFeet >= 3 && editHeightFeet <= 7
        let hasSex = !editSex.isEmpty
        let hasBirthday = true  // DatePicker always has a value
        return hasHeight && hasSex && hasBirthday
    }

    // MARK: - Initialization

    init(dataController: DataController, authManager: AuthenticationManager) {
        self.dataController = dataController
        self.authManager = authManager
        updateProgress()

        // Initialize services
        let context = dataController.container.mainContext
        self.tdeeService = TDEEService(context: context)
        self.metricsService = MetricsService(context: context)
    }

    // MARK: - Permission Methods

    /// Enable HealthKit sync for the current user
    /// - Returns: True if authorization was granted and sync enabled
    func enableHealthKitSync() async -> Bool {
        logger.info("enableHealthKitSync() called")

        guard let user = authManager.currentUser else {
            logger.warning("Cannot enable HealthKit: no currentUser")
            return false
        }
        logger.info("Found user: \(user.email ?? "no email")")

        guard let service = metricsService else {
            logger.warning("Cannot enable HealthKit: no metricsService")
            return false
        }
        logger.info("Found metricsService, calling setHealthSyncEnabled...")

        do {
            let success = try await service.setHealthSyncEnabled(true, for: user)
            if success {
                logger.info("HealthKit sync enabled via onboarding")
                // After successful authorization, check for and populate profile data
                await populateProfileFromHealthKit(user: user, service: service)
            } else {
                logger.info("HealthKit authorization denied by user")
            }
            return success
        } catch {
            logger.error("Failed to enable HealthKit: \(error.localizedDescription)")
            return false
        }
    }

    /// Populate profile completion fields from HealthKit data if available.
    /// Sets `hasProfileDataFromHealthKit` to true if all required fields were populated.
    private func populateProfileFromHealthKit(user: User, service: MetricsService) async {
        logger.info("Checking HealthKit for profile data...")

        // Fetch height
        var hasHeight = false
        if let heightCm = await service.getCurrentHeight(for: user), heightCm > 0 {
            let totalInches = heightCm / 2.54
            editHeightFeet = Int(totalInches / 12)
            editHeightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            user.heightCm = heightCm
            hasHeight = true
            logger.info("Populated height from HealthKit: \(heightCm) cm")
        }

        // Fetch biological sex
        var hasSex = false
        let gender = await service.getCurrentGender(for: user)
        if !gender.isEmpty {
            editSex = gender
            user.gender = gender
            hasSex = true
            logger.info("Populated sex from HealthKit: \(gender)")
        }

        // Fetch date of birth
        var hasBirthday = false
        if let dob = await service.getCurrentDateOfBirth(for: user) {
            editBirthday = dob
            user.dateOfBirth = dob
            hasBirthday = true
            logger.info("Populated birthday from HealthKit")
        }

        // If all required profile data is available, skip the profileCompletion step
        if hasHeight && hasSex && hasBirthday {
            hasProfileDataFromHealthKit = true
            user.updatedAt = Date()
            try? dataController.container.mainContext.save()
            logger.info("All profile data populated from HealthKit - will skip profileCompletion step")
        } else {
            logger.info(
                "Incomplete profile data from HealthKit - height:\(hasHeight), sex:\(hasSex), birthday:\(hasBirthday)"
            )
        }
    }

    // MARK: - Configuration

    /// Configure goal view model with user's current weight and preferences
    func configureGoalViewModel() async {
        guard let user = authManager.currentUser else { return }

        // Get current weight from MetricsService (handles HealthKit if enabled)
        let currentWeightKg: Double
        if let service = metricsService {
            currentWeightKg = await service.getCurrentWeight(for: user)
        } else {
            // Fallback: Local weight is stored in user's preferred unit
            currentWeightKg =
                user.prefersMetricWeight
                ? user.weight
                : user.weight / WeightEntry.kgToLbsConversion
        }

        // Configure with weight in user's display unit
        let displayWeight =
            user.prefersMetricWeight
            ? currentWeightKg
            : currentWeightKg * WeightEntry.kgToLbsConversion

        goalViewModel.configureWithCurrentWeight(displayWeight, usesMetric: user.prefersMetricWeight)
    }

    // MARK: - Navigation Methods

    /// Move to the next step in the onboarding flow.
    /// Does nothing if already at the last step or cannot proceed.
    func moveToNextStep() {
        guard !isLastStep, canProceedToNext else { return }

        if let currentIndex = availableSteps.firstIndex(of: currentStep),
            currentIndex + 1 < availableSteps.count
        {
            currentStep = availableSteps[currentIndex + 1]
            logger.debug("Moved to step: \(self.currentStep.rawValue)")
        }
    }

    /// Move to the previous step in the onboarding flow.
    /// Does nothing if already at the first step.
    func moveToPreviousStep() {
        if let currentIndex = availableSteps.firstIndex(of: currentStep),
            currentIndex > 0
        {
            currentStep = availableSteps[currentIndex - 1]
            logger.debug("Moved back to step: \(self.currentStep.rawValue)")
        }
    }

    // MARK: - Goal & Program Creation

    /// Calculate TDEE and nutrition targets based on collected data
    func calculateTargets() async throws {
        guard let user = authManager.currentUser else {
            throw OnboardingError.userNotFound
        }

        guard let trainingLevel else {
            throw OnboardingError.dataCreationFailed
        }

        // Collaborative skips weeklyDistribution - default to even
        if programStyle == .collaborative && weeklyDistributionMode == nil {
            weeklyDistributionMode = .even
        }

        let context = dataController.container.mainContext

        // Save profile data and log starting weight
        try await saveProfileData(user: user, context: context)

        // Create goal and program
        let goal = try createGoalAndProgram(
            user: user,
            trainingLevel: trainingLevel,
            context: context
        )

        // Calculate TDEE and apply to goal
        guard let service = tdeeService else {
            throw OnboardingError.dataCreationFailed
        }

        try await service.calculateAndApplyFullTDEE(for: user, goal: goal)

        // Store calculated values for display
        calculatedCalories = goal.dailyCalorieTarget
        calculatedProtein = goal.dailyProteinTargetGrams
        calculatedFat = goal.dailyFatTargetGrams
        calculatedCarbs = goal.dailyCarbTargetGrams

        logger.info(
            "Calculated targets: \(Int(self.calculatedCalories)) cal, P:\(Int(self.calculatedProtein))g"
        )
    }

    /// Save user profile data and log initial weight
    private func saveProfileData(user: User, context: ModelContext) async throws {
        user.heightCm = editHeightCm
        user.gender = editSex
        user.dateOfBirth = editBirthday
        user.updatedAt = Date()

        // Log current weight as a WeightEntry (required for TDEE calculation)
        if let service = metricsService {
            do {
                _ = try await service.logWeight(
                    weightKg: goalViewModel.currentWeightKg,
                    for: user
                )
                logger.info("Logged starting weight: \(self.goalViewModel.currentWeightKg) kg")
            } catch {
                logger.warning("Failed to log weight entry: \(error.localizedDescription)")
            }
        }

        try context.save()
    }

    /// Create goal and program entities
    private func createGoalAndProgram(
        user: User,
        trainingLevel: TrainingLevel,
        context: ModelContext
    ) throws -> NutritionGoal {
        guard let goalType = goalViewModel.goalType else {
            throw OnboardingError.dataCreationFailed
        }

        let weeklyPace = goalType == .weightLoss ? -goalViewModel.weeklyRateKg : goalViewModel.weeklyRateKg
        let goal = NutritionGoal(
            goalType: goalType,
            startingWeightKg: goalViewModel.currentWeightKg,
            targetWeightKg: goalViewModel.targetWeightKg,
            weeklyWeightChangePaceKg: weeklyPace
        )
        goal.user = user
        context.insert(goal)

        // Create program with user-selected values (fallback to smart defaults)
        let program = NutritionProgram(
            style: programStyle ?? .coached,
            diet: dietPreference ?? .balanced,
            calorieFloor: calorieFloorType ?? .standard,
            trainingLevel: trainingLevel,
            distributionMode: weeklyDistributionMode ?? .even,
            proteinLevel: proteinLevel ?? .moderate
        )
        program.goal = goal
        goal.program = program
        context.insert(program)

        try context.save()
        return goal
    }

    // MARK: - Completion

    /// Complete the onboarding flow and mark the user as onboarded.
    ///
    /// - Returns: Result indicating success, already completed, or failure
    func completeOnboarding() async -> OnboardingCompletionResult {
        isLoading = true
        defer { isLoading = false }

        // User is required to complete onboarding
        guard let user = authManager.currentUser else {
            errorMessage = "No user found to complete onboarding"
            logger.error("Cannot complete onboarding: no current user")
            return .failed(OnboardingError.userNotFound)
        }

        // Check if already completed
        if user.hasCompletedOnboarding {
            logger.info("Onboarding already completed for user")
            return .alreadyCompleted
        }

        let context = dataController.container.mainContext

        do {
            try finalizeOnboarding(for: user, in: context)
            logger.info("Onboarding completed successfully")
            errorMessage = nil
            return .success
        } catch {
            errorMessage = "Failed to complete onboarding: \(error.localizedDescription)"
            logger.error("Failed to complete onboarding: \(error.localizedDescription)")
            return .failed(OnboardingError.dataCreationFailed)
        }
    }

    // MARK: - Private Methods

    /// Finalizes onboarding by marking user as complete.
    private func finalizeOnboarding(for user: User, in context: ModelContext) throws {
        user.hasCompletedOnboarding = true
        user.onboardingCompletedAt = Date()
        user.updatedAt = Date()

        try context.save()

        // Store completion in UserDefaults as backup
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(Date(), forKey: "onboardingCompletedAt")

        logger.info("User marked as onboarded")
    }

    /// Update progress based on current step
    private func updateProgress() {
        guard totalSteps > 1 else {
            progress = 0.0
            return
        }
        progress = Double(currentStepIndex) / Double(totalSteps - 1)
    }
}
