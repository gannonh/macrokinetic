//
//  ProgramWizard.swift
//  JabTracker
//
//  Multi-step wizard for configuring nutrition programs.
//  Separate from GoalWizard - handles Program domain (style, diet, training, etc.)
//

import OSLog
import SwiftData
import SwiftUI

// MARK: - Program Wizard Step Enum

/// Steps in the program configuration wizard
enum ProgramWizardStep: String, CaseIterable {
    case programStyle
    case profileCompletion  // Only shown for Coached when profile data missing
    case dietPreference
    case calorieFloor
    case training
    case weeklyDistribution
    case proteinLevel
    case macroCustomization  // Legacy: single sliders for protein g/lb, carb:fat ratio
    case collaborativeDistribution  // For Collaborative: per-day distribution editor with auto-adjust
    case targetMode  // For Manual: Same all week vs Different per day
    case singleWeekMacros  // For Manual with same targets: single macro entry form
    case perDayMacros  // For Manual with different targets: edit each day
    case shiftedDaySelection  // For Coached/Shifted: select which days have higher calories
    case confirmation

    var title: String {
        switch self {
        case .programStyle: return "Program Style"
        case .profileCompletion: return "Complete Your Profile"
        case .dietPreference: return "Diet Preference"
        case .calorieFloor: return "Calorie Floor"
        case .training: return "Training Level"
        case .weeklyDistribution: return "Weekly Distribution"
        case .proteinLevel: return "Protein Level"
        case .macroCustomization: return "Customize Macros"
        case .collaborativeDistribution: return "Weekly Distribution"
        case .targetMode: return "Target Mode"
        case .singleWeekMacros: return "Weekly Targets"
        case .perDayMacros: return "Daily Targets"
        case .shiftedDaySelection: return "High Calorie Days"
        case .confirmation: return "Review & Confirm"
        }
    }

    var subtitle: String {
        switch self {
        case .programStyle: return "How much guidance do you want?"
        case .profileCompletion: return "We need a few details to calculate your targets"
        case .dietPreference: return "Choose your macro balance"
        case .calorieFloor: return "Set your minimum daily calories"
        case .training: return "What's your activity level?"
        case .weeklyDistribution: return "How to spread calories across the week"
        case .proteinLevel: return "How much protein do you need?"
        case .macroCustomization: return "Adjust your daily macro ratios"
        case .collaborativeDistribution: return "Customize calories and macros for each day"
        case .targetMode: return "Same targets all week or different each day?"
        case .singleWeekMacros: return "Set your targets for the week"
        case .perDayMacros: return "Set macros for each day of the week"
        case .shiftedDaySelection: return "Which days would you like to have higher Calories?"
        case .confirmation: return "Ready to start your program"
        }
    }
}

// MARK: - Program Wizard Error

/// Errors that can occur during program wizard completion
enum ProgramWizardError: LocalizedError {
    case incompleteData
    case saveFailed(Error)
    case noGoal

    var errorDescription: String? {
        switch self {
        case .incompleteData:
            return "Please complete all wizard steps before saving."
        case .saveFailed(let error):
            return "Failed to save program: \(error.localizedDescription)"
        case .noGoal:
            return "No goal found. Please create a goal first."
        }
    }
}

// MARK: - Program Wizard ViewModel

/// ViewModel for managing program configuration wizard state
@Observable
@MainActor
final class ProgramWizardViewModel {
    // MARK: - Step Navigation

    var currentStep: ProgramWizardStep = .programStyle

    // MARK: - Selections

    var programStyle: ProgramStyle?
    var dietPreference: DietPreference?
    var calorieFloorType: CalorieFloorType?
    var trainingLevel: TrainingLevel?
    var weeklyDistributionMode: WeeklyDistributionMode?
    var proteinLevel: ProteinLevel?

    // MARK: - Macro Customization State (Collaborative - Legacy)

    /// Protein target in grams per pound of body weight (legacy single-value)
    var proteinGramsPerLb: Double = 0.8

    /// Carb to fat ratio (0.0 = all fat, 1.0 = all carbs) (legacy single-value)
    var carbFatRatio: Double = 0.5

    // MARK: - Collaborative Distribution State

    /// Selected day for editing (weekday: 1=Sun, 2=Mon, ..., 7=Sat)
    var collaborativeSelectedDay: Int = 2  // Default to Monday

    /// Per-day configuration for Collaborative mode
    struct CollaborativeDayConfig: Equatable {
        var calories: Double
        var proteinGramsPerLb: Double
        var carbFatRatio: Double
        var isLocked: Bool

        /// Calculate actual protein grams from body weight in pounds
        func proteinGrams(bodyWeightLb: Double) -> Double {
            proteinGramsPerLb * bodyWeightLb
        }

        /// Calculate fat grams from remaining calories after protein
        func fatGrams(bodyWeightLb: Double) -> Double {
            let proteinCals = MacroCalorieConstants.proteinCalories(proteinGrams(bodyWeightLb: bodyWeightLb))
            let remaining = calories - proteinCals
            let fatCalories = remaining * (1 - carbFatRatio)
            return fatCalories / MacroCalorieConstants.fatCaloriesPerGram
        }

        /// Calculate carb grams from remaining calories after protein
        func carbGrams(bodyWeightLb: Double) -> Double {
            let proteinCals = MacroCalorieConstants.proteinCalories(proteinGrams(bodyWeightLb: bodyWeightLb))
            let remaining = calories - proteinCals
            let carbCalories = remaining * carbFatRatio
            return carbCalories / MacroCalorieConstants.carbsCaloriesPerGram
        }
    }

    /// Per-day configurations for Collaborative mode (weekday: 1=Sun, 2=Mon, ..., 7=Sat)
    var collaborativeDays: [Int: CollaborativeDayConfig] = [:]

    /// Weekly calorie budget (from goal)
    var weeklyCalorieBudget: Double = 14000

    // MARK: - Target Mode State (Manual)

    /// Whether Manual mode uses same targets all week
    var useSameTargetsAllWeek: Bool = true

    /// Per-day macro targets for Manual mode
    var perDayMacros: [Int: DailyMacros] = [:]

    // MARK: - Single Week Macros State (Manual - Same All Week)

    var singleWeekCalories: Double = 2000
    var singleWeekProtein: Double = 150
    var singleWeekFat: Double = 65
    var singleWeekCarbs: Double = 200

    // MARK: - Shifted Distribution State (Coached)

    /// Days with higher calorie targets (weekday numbers: 2=Mon through 1=Sun)
    /// See mock: mocks/goal-program/Coached-Shift/IMG_2102.PNG
    var highCalorieDays: Set<Int> = []

    // MARK: - Profile Completion State

    /// Missing profile fields for TDEE calculation
    var missingHeight: Bool = false
    var missingSex: Bool = false
    var missingBirthday: Bool = false

    /// Edit values for profile completion
    var editHeightFeet: Int = 5
    var editHeightInches: Int = 7
    var editSex: String = ""
    var editBirthday: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()

    /// Whether profile completion step is needed
    /// Both Coached and Collaborative modes need profile data for TDEE calculations
    var needsProfileCompletion: Bool {
        let requiresProfile = programStyle == .coached || programStyle == .collaborative
        return requiresProfile && (missingHeight || missingSex || missingBirthday)
    }

    /// Height in cm from feet/inches
    var editHeightCm: Double {
        let totalInches = Double(editHeightFeet * 12 + editHeightInches)
        return totalInches * 2.54
    }

    // MARK: - Mode

    /// Whether we're editing an existing program (skips style selection)
    var isEditMode: Bool = false

    /// The existing program being edited
    var existingProgram: NutritionProgram?

    /// The goal this program belongs to
    var goal: NutritionGoal?

    // MARK: - Steps Configuration

    /// Steps available based on mode, program style, and profile completion needs
    var availableSteps: [ProgramWizardStep] {
        switch programStyle {
        case .coached:
            return coachedSteps
        case .collaborative:
            return collaborativeSteps
        case .manual:
            return manualSteps
        case nil:
            // Before style is selected, show minimal steps
            return isEditMode ? [.confirmation] : [.programStyle, .confirmation]
        }
    }

    /// Base steps included in all program styles (handles edit mode)
    private var baseSteps: [ProgramWizardStep] {
        isEditMode ? [] : [.programStyle]
    }

    /// Steps for Coached mode
    private var coachedSteps: [ProgramWizardStep] {
        var steps = baseSteps

        // profileCompletion (only if needed)
        if needsProfileCompletion {
            steps.append(.profileCompletion)
        }

        // Coached-specific steps
        steps.append(contentsOf: [.dietPreference, .calorieFloor, .training, .weeklyDistribution])

        // shiftedDaySelection (only if Shifted distribution selected)
        if weeklyDistributionMode == .shifted {
            steps.append(.shiftedDaySelection)
        }

        steps.append(contentsOf: [.proteinLevel, .confirmation])
        return steps
    }

    /// Steps for Collaborative mode (skips weeklyDistribution - they customize per-day in Strategy)
    private var collaborativeSteps: [ProgramWizardStep] {
        var steps = baseSteps

        // profileCompletion (only if needed - same as Coached)
        if needsProfileCompletion {
            steps.append(.profileCompletion)
        }

        // Collaborative uses collaborativeDistribution for per-day editing with lock/auto-adjust
        steps.append(contentsOf: [
            .dietPreference, .calorieFloor, .training, .proteinLevel, .collaborativeDistribution, .confirmation,
        ])
        return steps
    }

    /// Steps for Manual mode
    private var manualSteps: [ProgramWizardStep] {
        var steps = baseSteps

        // Manual shows: targetMode, then singleWeekMacros OR perDayMacros
        steps.append(.targetMode)

        if useSameTargetsAllWeek {
            steps.append(.singleWeekMacros)
        } else {
            steps.append(.perDayMacros)
        }

        steps.append(.confirmation)
        return steps
    }

    // MARK: - Computed Properties

    /// Progress through the wizard (0.0 to 1.0)
    var progressPercent: Double {
        guard let currentIndex = availableSteps.firstIndex(of: currentStep) else {
            return 0
        }
        guard availableSteps.count > 1 else {
            return 1.0
        }
        return Double(currentIndex) / Double(availableSteps.count - 1)
    }

    /// Whether user can continue to next step
    var canContinue: Bool {
        switch currentStep {
        case .programStyle:
            return programStyle != nil
        case .profileCompletion:
            return isProfileDataComplete
        case .dietPreference:
            return dietPreference != nil
        case .calorieFloor:
            return calorieFloorType != nil
        case .training:
            return trainingLevel != nil
        case .weeklyDistribution:
            return weeklyDistributionMode != nil
        case .proteinLevel:
            return proteinLevel != nil
        case .macroCustomization:
            return proteinGramsPerLb > 0 && carbFatRatio >= 0 && carbFatRatio <= 1
        case .collaborativeDistribution:
            // All 7 days must have valid calories > 0
            return WeeklyConstants.validWeekdayRange.allSatisfy { weekday in
                guard let config = collaborativeDays[weekday] else { return false }
                return config.calories > 0
            }
        case .targetMode:
            return true  // Always can continue, just choosing mode
        case .singleWeekMacros:
            return singleWeekCalories > 0 && singleWeekProtein >= 0
        case .perDayMacros:
            // All 7 days must have valid macros with calories > 0
            return WeeklyConstants.validWeekdayRange.allSatisfy { weekday in
                guard let macros = perDayMacros[weekday] else { return false }
                return macros.calories > 0
            }
        case .shiftedDaySelection:
            return !highCalorieDays.isEmpty  // At least one day must be selected
        case .confirmation:
            return allSelectionsComplete
        }
    }

    /// Whether all required profile data is filled in (for profile completion step)
    private var isProfileDataComplete: Bool {
        let hasHeight = !missingHeight || (editHeightFeet >= 3 && editHeightFeet <= 7)
        let hasSex = !missingSex || !editSex.isEmpty
        let hasBirthday = !missingBirthday || true  // DatePicker always has a value
        return hasHeight && hasSex && hasBirthday
    }

    /// Whether all selections are complete for current program style
    private var allSelectionsComplete: Bool {
        let hasStyle = isEditMode || programStyle != nil
        guard hasStyle else { return false }

        switch programStyle {
        case .coached:
            let base =
                dietPreference != nil && calorieFloorType != nil
                && trainingLevel != nil && weeklyDistributionMode != nil && proteinLevel != nil
            // If shifted, must have selected days
            if weeklyDistributionMode == .shifted {
                return base && !highCalorieDays.isEmpty
            }
            return base
        case .collaborative:
            // All 7 days must have valid configurations
            return WeeklyConstants.validWeekdayRange.allSatisfy { weekday in
                guard let config = collaborativeDays[weekday] else { return false }
                return config.calories > 0 && config.proteinGramsPerLb > 0
                    && config.carbFatRatio >= 0 && config.carbFatRatio <= 1
            }
        case .manual:
            if useSameTargetsAllWeek {
                return singleWeekCalories > 0 && singleWeekProtein >= 0
            } else {
                // All 7 days must have valid macros
                return WeeklyConstants.validWeekdayRange.allSatisfy { weekday in
                    guard let macros = perDayMacros[weekday] else { return false }
                    return macros.calories > 0
                }
            }
        case nil:
            return false
        }
    }

    /// Whether this is the first step
    var isFirstStep: Bool {
        currentStep == availableSteps.first
    }

    /// Whether this is the confirmation step
    var isConfirmationStep: Bool {
        currentStep == .confirmation
    }

    /// Whether the next step is the confirmation step
    var isNextStepConfirmation: Bool {
        guard let currentIndex = availableSteps.firstIndex(of: currentStep),
            currentIndex + 1 < availableSteps.count
        else {
            return false
        }
        return availableSteps[currentIndex + 1] == .confirmation
    }

    /// Title for edit mode navigation bar
    var editModeTitle: String {
        guard let style = programStyle ?? existingProgram?.style else {
            return "Edit Program"
        }
        return "Edit \(style.displayName) Program"
    }

    // MARK: - Navigation

    func advance() {
        guard let currentIndex = availableSteps.firstIndex(of: currentStep) else {
            return
        }
        guard currentIndex + 1 < availableSteps.count else {
            return
        }
        currentStep = availableSteps[currentIndex + 1]
    }

    func goBack() {
        guard let currentIndex = availableSteps.firstIndex(of: currentStep),
            currentIndex > 0
        else {
            return
        }
        currentStep = availableSteps[currentIndex - 1]
    }

    // MARK: - Collaborative Distribution Methods

    /// Initialize collaborative days with even distribution from goal
    func initializeCollaborativeDaysFromGoal() {
        guard let goal else { return }

        weeklyCalorieBudget = goal.dailyCalorieTarget * 7
        let dailyCals = goal.dailyCalorieTarget

        // Initialize all 7 days with even distribution
        for weekday in WeeklyConstants.validWeekdayRange {
            collaborativeDays[weekday] = CollaborativeDayConfig(
                calories: dailyCals,
                proteinGramsPerLb: proteinGramsPerLb,
                carbFatRatio: carbFatRatio,
                isLocked: false
            )
        }
    }

    /// Adjust calories for a specific day with auto-redistribution to unlocked days
    ///
    /// When user changes Day X's calories:
    /// - Calculate delta (new - old)
    /// - Distribute -delta across all UNLOCKED days (not X, not locked)
    /// - Maintain total weekly budget
    ///
    /// - Parameters:
    ///   - weekday: The day being edited (1=Sun through 7=Sat)
    ///   - newCalories: The new calorie value for that day
    func adjustCollaborativeCalories(forDay weekday: Int, newCalories: Double) {
        guard var dayConfig = collaborativeDays[weekday] else { return }

        let oldCalories = dayConfig.calories
        let delta = newCalories - oldCalories

        // Update the edited day
        dayConfig.calories = newCalories
        collaborativeDays[weekday] = dayConfig

        // Find unlocked days that aren't the edited day
        let unlockedDays = WeeklyConstants.validWeekdayRange.filter { day in
            day != weekday && !(collaborativeDays[day]?.isLocked ?? false)
        }

        // Distribute the negative delta across unlocked days
        guard !unlockedDays.isEmpty else { return }

        let adjustmentPerDay = -delta / Double(unlockedDays.count)

        for day in unlockedDays {
            guard var config = collaborativeDays[day] else { continue }
            // Ensure calories don't go negative
            config.calories = max(0, config.calories + adjustmentPerDay)
            collaborativeDays[day] = config
        }
    }

    /// Reset all collaborative days to even distribution
    func resetCollaborativeDaysToEven() {
        let dailyCals = weeklyCalorieBudget / 7

        for weekday in WeeklyConstants.validWeekdayRange {
            collaborativeDays[weekday] = CollaborativeDayConfig(
                calories: dailyCals,
                proteinGramsPerLb: proteinGramsPerLb,
                carbFatRatio: carbFatRatio,
                isLocked: false
            )
        }
    }

    /// Get body weight in pounds from goal
    var bodyWeightLb: Double {
        (goal?.startingWeightKg ?? 70) * 2.205
    }

    // MARK: - Initialization

    /// Configure for editing an existing program
    func configureForEdit(program: NutritionProgram) {
        isEditMode = true
        existingProgram = program
        goal = program.goal
        programStyle = program.style
        dietPreference = program.diet
        calorieFloorType = program.calorieFloor
        trainingLevel = program.training
        weeklyDistributionMode = program.distributionMode
        proteinLevel = program.protein

        // Load Collaborative per-day configurations from saved program
        if program.style == .collaborative {
            loadCollaborativeConfig(from: program)
        }

        // Load Manual per-day macros from saved program
        if program.style == .manual, let weeklyMacros = program.weeklyMacros {
            loadManualDaysFromMacros(weeklyMacros)
        }

        // Start at the first available step for this program style
        // (different styles have different step sequences)
        currentStep = availableSteps.first ?? .confirmation
    }

    /// Load collaborative config from saved program's weeklyMacros (single source of truth)
    private func loadCollaborativeConfig(from program: NutritionProgram) {
        guard let weeklyMacros = program.weeklyMacros else {
            return
        }

        let weightLb = (goal?.startingWeightKg ?? 70) * 2.205

        for weekday in WeeklyConstants.validWeekdayRange {
            guard let macros = weeklyMacros.macrosForDay(weekday) else { continue }

            // Derive UI parameters from stored macro values
            let proteinGramsPerLb = weightLb > 0 ? macros.proteinGrams / weightLb : 0.8
            let proteinCalories = MacroCalorieConstants.proteinCalories(macros.proteinGrams)
            let remainingCalories = macros.calories - proteinCalories
            let carbCalories = MacroCalorieConstants.carbsCalories(macros.carbsGrams)
            let carbFatRatio = remainingCalories > 0 ? carbCalories / remainingCalories : 0.5

            collaborativeDays[weekday] = CollaborativeDayConfig(
                calories: macros.calories,
                proteinGramsPerLb: proteinGramsPerLb,
                carbFatRatio: min(1, max(0, carbFatRatio)),
                isLocked: macros.isLocked
            )
        }

        weeklyCalorieBudget = collaborativeDays.values.reduce(0) { $0 + $1.calories }
    }

    /// Load manual per-day macros from saved weekly macros
    private func loadManualDaysFromMacros(_ weeklyMacros: WeeklyMacroDistribution) {
        for weekday in WeeklyConstants.validWeekdayRange {
            if let macros = weeklyMacros.macrosForDay(weekday) {
                perDayMacros[weekday] = macros
            }
        }

        // Check if all days are the same (same targets all week)
        let uniqueMacros = Set(perDayMacros.values.map { "\($0.calories)-\($0.proteinGrams)" })
        useSameTargetsAllWeek = uniqueMacros.count <= 1

        // If same all week, populate single week values
        if useSameTargetsAllWeek, let first = perDayMacros.values.first {
            singleWeekCalories = first.calories
            singleWeekProtein = first.proteinGrams
            singleWeekFat = first.fatGrams
            singleWeekCarbs = first.carbsGrams
        }
    }

    /// Configure for new program with a goal
    func configureWithGoal(_ goal: NutritionGoal) {
        self.goal = goal
        isEditMode = false
    }

    // MARK: - Save

    /// Build WeeklyCalorieDistribution from highCalorieDays selection
    /// See mock: mocks/goal-program/Coached-Shift/IMG_2103.PNG
    private func buildWeeklyCalorieDistribution() -> WeeklyCalorieDistribution? {
        guard weeklyDistributionMode == .shifted else { return nil }
        return WeeklyCalorieDistribution.shifted(highCalorieDays: highCalorieDays)
    }

    /// Build WeeklyMacroDistribution from wizard selections
    private func buildWeeklyMacroDistribution(goal: NutritionGoal) -> WeeklyMacroDistribution? {
        guard let style = programStyle ?? existingProgram?.style else { return nil }

        switch style {
        case .coached:
            // Coached mode uses TDEE-calculated macros with optional shifted calories
            // WeeklyCalorieDistribution handled separately
            return nil

        case .collaborative:
            // Collaborative: build per-day macros from collaborativeDays
            guard !collaborativeDays.isEmpty else { return nil }

            let weightLb = goal.startingWeightKg * 2.205
            var dayMacros: [Int: DailyMacros] = [:]

            for weekday in WeeklyConstants.validWeekdayRange {
                guard let config = collaborativeDays[weekday] else { continue }

                let proteinGrams = config.proteinGramsPerLb * weightLb
                let proteinCalories = MacroCalorieConstants.proteinCalories(proteinGrams)
                let remainingCalories = config.calories - proteinCalories
                let fatCalories = remainingCalories * (1 - config.carbFatRatio)
                let carbCalories = remainingCalories * config.carbFatRatio

                dayMacros[weekday] = DailyMacros(
                    calories: config.calories,
                    proteinGrams: proteinGrams,
                    fatGrams: fatCalories / MacroCalorieConstants.fatCaloriesPerGram,
                    carbsGrams: carbCalories / MacroCalorieConstants.carbsCaloriesPerGram,
                    isLocked: config.isLocked
                )
            }

            // Use first day as default (should always exist)
            let defaultMacros = dayMacros.values.first ?? .zero
            return WeeklyMacroDistribution(dayMacros: dayMacros, defaultMacros: defaultMacros)

        case .manual:
            if useSameTargetsAllWeek {
                // Same all week - use single week macros from wizard
                let defaultMacros = DailyMacros(
                    calories: singleWeekCalories,
                    proteinGrams: singleWeekProtein,
                    fatGrams: singleWeekFat,
                    carbsGrams: singleWeekCarbs
                )
                return .even(macros: defaultMacros)
            } else {
                // Different per day - use perDayMacros
                guard !perDayMacros.isEmpty else { return nil }
                let first = perDayMacros.values.first ?? .zero
                return WeeklyMacroDistribution(dayMacros: perDayMacros, defaultMacros: first)
            }
        }
    }

    /// Save the program configuration
    /// - Parameter context: SwiftData model context
    func save(context: ModelContext) throws {
        guard let goal else {
            throw ProgramWizardError.noGoal
        }

        // Get style - from selection or existing program in edit mode
        let style = programStyle ?? existingProgram?.style
        guard let style else {
            throw ProgramWizardError.incompleteData
        }

        // Validate required fields based on style
        let diet = dietPreference ?? (isEditMode ? existingProgram?.diet : nil) ?? .balanced
        let floor = calorieFloorType ?? (isEditMode ? existingProgram?.calorieFloor : nil) ?? .standard
        let training = trainingLevel ?? (isEditMode ? existingProgram?.training : nil) ?? .none
        let distribution = weeklyDistributionMode ?? (isEditMode ? existingProgram?.distributionMode : nil) ?? .even
        let protein = proteinLevel ?? (isEditMode ? existingProgram?.protein : nil) ?? .moderate

        let program: NutritionProgram
        if isEditMode, let existing = existingProgram {
            // Update existing program
            existing.style = style
            existing.diet = diet
            existing.calorieFloor = floor
            existing.training = training
            existing.distributionMode = distribution
            existing.protein = protein
            existing.updatedAt = Date()
            program = existing
        } else {
            // Create new program
            let newProgram = NutritionProgram(
                style: style,
                diet: diet,
                calorieFloor: floor,
                trainingLevel: training,
                distributionMode: distribution,
                proteinLevel: protein
            )
            // Set both sides of the relationship explicitly for SwiftData
            newProgram.goal = goal
            goal.program = newProgram
            context.insert(newProgram)
            program = newProgram
        }

        // Store per-day macros (Collaborative, Manual) - single source of truth including isLocked
        if let macroDistribution = buildWeeklyMacroDistribution(goal: goal) {
            program.setWeeklyMacros(macroDistribution)
        } else {
            // Clear per-day macros if not applicable (e.g., switching from Collaborative to Coached)
            program.weeklyMacroDistributionData = nil
        }

        // Store shifted calorie distribution if applicable (Coached/Shifted)
        if let calorieDistribution = buildWeeklyCalorieDistribution() {
            program.setWeeklyDistribution(calorieDistribution)
        } else {
            // Clear shifted distribution if not applicable (e.g., switching to Even mode)
            program.weeklyDistributionData = nil
        }

        do {
            try context.save()
        } catch {
            throw ProgramWizardError.saveFailed(error)
        }
    }

    // MARK: - Profile Completion

    /// Check which profile fields are missing for TDEE calculation
    /// - Parameters:
    ///   - user: User to check
    ///   - metricsService: Service to check HealthKit values
    func checkMissingProfileFields(user: User, metricsService: MetricsService) async {
        // Check height
        let height = await metricsService.getCurrentHeight(for: user)
        missingHeight = height == nil || height == 0

        // Check sex
        let sex = await metricsService.getCurrentGender(for: user)
        missingSex = sex.isEmpty

        // Check birthday
        let birthday = await metricsService.getCurrentDateOfBirth(for: user)
        missingBirthday = birthday == nil

        // Pre-populate edit fields with current values (or defaults)
        if let height, height > 0 {
            let totalInches = height / 2.54
            editHeightFeet = Int(totalInches / 12)
            editHeightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        }
        if !sex.isEmpty {
            editSex = sex
        }
        if let birthday {
            editBirthday = birthday
        }
    }

    /// Save profile completion data
    /// - Parameters:
    ///   - user: User to update
    ///   - metricsService: Service to save to HealthKit
    ///   - context: Model context for saving
    func saveProfileData(user: User, metricsService: MetricsService, context: ModelContext) async throws {
        // Capture flags before clearing (we need to save based on what was missing)
        let savingHeight = missingHeight
        let savingSex = missingSex
        let savingBirthday = missingBirthday

        // Save all profile data locally first (single context.save to avoid SwiftData observation conflicts)
        if savingHeight {
            user.heightCm = editHeightCm
        }

        if savingSex {
            user.gender = editSex
        }

        if savingBirthday {
            user.dateOfBirth = editBirthday
        }

        user.updatedAt = Date()
        try context.save()

        // Write height to HealthKit after local save (non-blocking, won't cause view issues)
        if savingHeight, user.healthSyncEnabled {
            Task {
                await metricsService.writeHeightToHealthKitIfEnabled(editHeightCm, for: user)
            }
        }

        // NOTE: Don't clear missing flags here - doing so causes UI to re-render
        // while currentStep is still .profileCompletion, breaking the view.
        // Flags will be reset when wizard is dismissed/completed.
    }
}

// MARK: - Main Program Wizard View

/// Multi-step wizard for configuring nutrition programs
struct ProgramWizard: View {
    // MARK: - Properties

    /// The goal this program belongs to
    let goal: NutritionGoal

    /// Optional existing program to edit
    let existingProgram: NutritionProgram?

    /// Callback when program is created/updated
    var onComplete: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ProgramWizardViewModel()
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var tdeeService: TDEEService?
    @State private var metricsService: MetricsService?
    @State private var isCalculatingTargets = false

    // MARK: - Static Properties

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "ProgramWizard"
    )

    // MARK: - Initialization

    init(goal: NutritionGoal, existingProgram: NutritionProgram? = nil, onComplete: (() -> Void)? = nil) {
        self.goal = goal
        self.existingProgram = existingProgram
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Progress indicator
                    ProgressView(value: viewModel.progressPercent)
                        .tint(DesignTokens.Colors.accent)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .accessibilityLabel(
                            "Step \(stepNumber) of \(viewModel.availableSteps.count)"
                        )

                    // Step content
                    stepContent
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            )
                        )

                    Spacer()

                    // Navigation buttons
                    HStack(spacing: 12) {
                        if !viewModel.isFirstStep {
                            SecondaryButton(title: "Back") {
                                withAnimation(.spring()) {
                                    viewModel.goBack()
                                }
                            }
                            .accessibilityIdentifier("program-wizard-back-button")
                        }

                        if viewModel.isConfirmationStep {
                            PrimaryButton(title: viewModel.isEditMode ? "Save Program" : "Create Program") {
                                Task {
                                    await saveProgram()
                                }
                            }
                            .accessibilityIdentifier("program-wizard-save-button")
                        } else {
                            PrimaryButton(title: isCalculatingTargets ? "Calculating..." : "Continue") {
                                Task {
                                    await handleContinue()
                                }
                            }
                            .disabled(!viewModel.canContinue || isCalculatingTargets)
                            .accessibilityIdentifier("program-wizard-continue-button")
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }

                // Calculating overlay
                if isCalculatingTargets {
                    CalculatingOverlayView()
                        .transition(.opacity)
                }
            }
            .background(DesignTokens.Colors.groupedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(viewModel.isEditMode ? viewModel.editModeTitle : "New Program")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("program-wizard-cancel-button")
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    showingError = false
                    errorMessage = nil
                }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .onAppear {
            viewModel.goal = goal
            tdeeService = TDEEService(context: modelContext)
            metricsService = MetricsService(context: modelContext)
            if let existingProgram {
                Self.logger.info("Configuring for edit mode - program style: \(existingProgram.style.rawValue)")
                viewModel.configureForEdit(program: existingProgram)
            } else {
                let hasProgram = goal.program != nil
                Self.logger.info("Configuring for new program mode - goal.program: \(hasProgram)")
            }
        }
        .onChange(of: viewModel.programStyle) { _, newStyle in
            // Check for missing profile fields when Coached or Collaborative is selected
            if newStyle == .coached || newStyle == .collaborative,
                let user = goal.user,
                let service = metricsService
            {
                Task {
                    await viewModel.checkMissingProfileFields(user: user, metricsService: service)

                    // For Collaborative, calculate TDEE now if profile is complete
                    // This ensures distribution editor shows real values even if profileCompletion step is skipped
                    // BUT skip this in edit mode - we already loaded the saved config
                    if newStyle == .collaborative, !viewModel.needsProfileCompletion, !viewModel.isEditMode {
                        await calculateAndApplyTDEE()
                        viewModel.initializeCollaborativeDaysFromGoal()
                    }
                }
            }
            // Initialize collaborative days when Collaborative is selected
            // (will be re-initialized with real values after TDEE calculation)
            // Skip in edit mode - we already loaded the saved config
            if newStyle == .collaborative, !viewModel.isEditMode {
                viewModel.initializeCollaborativeDaysFromGoal()
            }
        }
        .accessibilityIdentifier("program-wizard")
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .programStyle:
            ProgramStyleStepView(selection: $viewModel.programStyle)
                .accessibilityIdentifier("program-wizard-programStyle-step")
        case .profileCompletion:
            ProfileCompletionStepView(viewModel: viewModel)
                .accessibilityIdentifier("program-wizard-profileCompletion-step")
        case .dietPreference:
            DietPreferenceStepView(selection: $viewModel.dietPreference)
                .accessibilityIdentifier("program-wizard-dietPreference-step")
        case .calorieFloor:
            CalorieFloorStepView(selection: $viewModel.calorieFloorType)
                .accessibilityIdentifier("program-wizard-calorieFloor-step")
        case .training:
            TrainingLevelStepView(selection: $viewModel.trainingLevel)
                .accessibilityIdentifier("program-wizard-training-step")
        case .weeklyDistribution:
            WeeklyDistributionStepView(selection: $viewModel.weeklyDistributionMode)
                .accessibilityIdentifier("program-wizard-weeklyDistribution-step")
        case .proteinLevel:
            ProteinLevelStepView(selection: $viewModel.proteinLevel)
                .accessibilityIdentifier("program-wizard-proteinLevel-step")
        case .macroCustomization:
            MacroCustomizationStepView(viewModel: viewModel)
                .accessibilityIdentifier("program-wizard-macroCustomization-step")
        case .collaborativeDistribution:
            CollaborativeDistributionStepView(viewModel: viewModel)
                .accessibilityIdentifier("program-wizard-collaborativeDistribution-step")
        case .targetMode:
            TargetModeStepView(useSameTargetsAllWeek: $viewModel.useSameTargetsAllWeek)
                .accessibilityIdentifier("program-wizard-targetMode-step")
        case .singleWeekMacros:
            SingleWeekMacrosStepView(viewModel: viewModel)
                .accessibilityIdentifier("program-wizard-singleWeekMacros-step")
        case .perDayMacros:
            PerDayMacrosStepView(viewModel: viewModel)
                .accessibilityIdentifier("program-wizard-perDayMacros-step")
        case .shiftedDaySelection:
            ShiftedDaySelectionStepView(highCalorieDays: $viewModel.highCalorieDays)
                .accessibilityIdentifier("program-wizard-shiftedDaySelection-step")
        case .confirmation:
            ProgramConfirmationStepView(viewModel: viewModel)
                .accessibilityIdentifier("program-wizard-confirmation-step")
        }
    }

    private var stepNumber: Int {
        (viewModel.availableSteps.firstIndex(of: viewModel.currentStep) ?? 0) + 1
    }

    // MARK: - Actions

    private func handleContinue() async {
        // Save profile data when leaving profileCompletion step
        if viewModel.currentStep == .profileCompletion {
            guard let user = goal.user else {
                Self.logger.warning("Profile completion skipped: user is nil")
                withAnimation(.spring()) {
                    viewModel.advance()
                }
                return
            }
            guard let service = metricsService else {
                Self.logger.warning("Profile completion skipped: MetricsService not initialized")
                withAnimation(.spring()) {
                    viewModel.advance()
                }
                return
            }

            do {
                try await viewModel.saveProfileData(user: user, metricsService: service, context: modelContext)

                // For Collaborative mode, calculate TDEE now so distribution editor shows real values
                // Skip in edit mode - we already have the saved values
                if viewModel.programStyle == .collaborative, !viewModel.isEditMode {
                    await calculateAndApplyTDEE()
                    // Re-initialize collaborative days with calculated values
                    viewModel.initializeCollaborativeDaysFromGoal()
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                return
            }
        }

        // Check if next step is confirmation - show calculating overlay and calculate TDEE
        if viewModel.isNextStepConfirmation && !viewModel.isEditMode {
            await showCalculatingThenConfirmation()
            return
        }

        withAnimation(.spring()) {
            viewModel.advance()
        }
    }

    /// Show calculation overlay, calculate TDEE, then advance to confirmation step
    private func showCalculatingThenConfirmation() async {
        // Show calculating overlay
        withAnimation(.easeIn(duration: 0.2)) {
            isCalculatingTargets = true
        }

        // Calculate TDEE
        await calculateAndApplyTDEE()

        // Show overlay long enough for user to see the animation (at least 3 seconds)
        try? await Task.sleep(nanoseconds: 3_000_000_000)

        // Hide overlay and advance to confirmation
        withAnimation(.spring()) {
            isCalculatingTargets = false
            viewModel.advance()
        }
    }

    private func saveProgram() async {
        do {
            try viewModel.save(context: modelContext)
            onComplete?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func calculateAndApplyTDEE() async {
        guard let goal = viewModel.goal else {
            Self.logger.error("TDEE calculation skipped: goal is nil")
            return
        }
        guard let user = goal.user else {
            Self.logger.error("TDEE calculation skipped: user is nil")
            errorMessage = "Could not calculate personalized targets: User profile not found."
            showingError = true
            return
        }
        guard let service = tdeeService else {
            Self.logger.error("TDEE calculation skipped: TDEEService not initialized")
            return
        }

        do {
            // Use TDEEService for all calculations (TDEE, calories, macros)
            try await service.calculateAndApplyFullTDEE(for: user, goal: goal)
        } catch {
            // Log error and show user feedback - they need to know why targets aren't calculated
            Self.logger.error("TDEE calculation failed: \(error.localizedDescription)")
            errorMessage = "Could not calculate personalized targets: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// MARK: - Preview

#Preview("Program Wizard - New") {
    let goal = NutritionGoal()
    return ProgramWizard(goal: goal)
}

#Preview("Program Wizard - Edit") {
    let goal = NutritionGoal()
    let program = NutritionProgram(style: .coached, diet: .balanced)
    program.goal = goal
    return ProgramWizard(goal: goal, existingProgram: program)
}
