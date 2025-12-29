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
    case macroCustomization  // For Collaborative: weekly grid + sliders for protein g/lb, carb:fat ratio
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

    // MARK: - Macro Customization State (Collaborative)

    /// Protein target in grams per pound of body weight
    var proteinGramsPerLb: Double = 0.8

    /// Carb to fat ratio (0.0 = all fat, 1.0 = all carbs)
    var carbFatRatio: Double = 0.5

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
    var needsProfileCompletion: Bool {
        programStyle == .coached && (missingHeight || missingSex || missingBirthday)
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

    /// Steps for Collaborative mode
    private var collaborativeSteps: [ProgramWizardStep] {
        var steps = baseSteps

        // Collaborative shows: training, weeklyDistribution, macroCustomization
        steps.append(contentsOf: [.training, .weeklyDistribution, .macroCustomization, .confirmation])
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
            return trainingLevel != nil && weeklyDistributionMode != nil
                && proteinGramsPerLb > 0 && carbFatRatio >= 0 && carbFatRatio <= 1
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

    /// Title for edit mode navigation bar
    var editModeTitle: String {
        guard let style = programStyle ?? existingProgram?.style else {
            return "Edit Program"
        }
        return "Edit \(style.displayName) Program"
    }

    // MARK: - Navigation

    func advance() {
        guard let currentIndex = availableSteps.firstIndex(of: currentStep),
            currentIndex + 1 < availableSteps.count
        else {
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

        // Start at diet preference (skip style in edit mode)
        currentStep = .dietPreference
    }

    /// Configure for new program with a goal
    func configureWithGoal(_ goal: NutritionGoal) {
        self.goal = goal
        isEditMode = false
    }

    // MARK: - Save

    /// Save the program configuration
    /// - Parameter context: SwiftData model context
    func save(context: ModelContext) throws {
        guard let goal else {
            throw ProgramWizardError.noGoal
        }

        // Get style - from selection or existing program in edit mode
        let style = programStyle ?? existingProgram?.style

        guard let style,
            let dietPreference,
            let calorieFloorType,
            let trainingLevel,
            let weeklyDistributionMode,
            let proteinLevel
        else {
            throw ProgramWizardError.incompleteData
        }

        if isEditMode, let existing = existingProgram {
            // Update existing program
            existing.style = style
            existing.diet = dietPreference
            existing.calorieFloor = calorieFloorType
            existing.training = trainingLevel
            existing.distributionMode = weeklyDistributionMode
            existing.protein = proteinLevel
            existing.updatedAt = Date()
        } else {
            // Create new program
            let program = NutritionProgram(
                style: style,
                diet: dietPreference,
                calorieFloor: calorieFloorType,
                trainingLevel: trainingLevel,
                distributionMode: weeklyDistributionMode,
                proteinLevel: proteinLevel
            )
            program.goal = goal
            context.insert(program)
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
        // Save height if it was missing
        if missingHeight {
            try await metricsService.saveHeight(editHeightCm, for: user)
        }

        // Save sex if it was missing (local only - HealthKit sex is read-only)
        if missingSex {
            user.gender = editSex
        }

        // Save birthday if it was missing (local only - HealthKit DOB is read-only)
        if missingBirthday {
            user.dateOfBirth = editBirthday
        }

        user.updatedAt = Date()
        try context.save()

        // Clear missing flags
        missingHeight = false
        missingSex = false
        missingBirthday = false
    }
}

// MARK: - Main Program Wizard View

/// Multi-step wizard for configuring nutrition programs
struct ProgramWizard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "ProgramWizard"
    )

    @State private var viewModel = ProgramWizardViewModel()
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var tdeeService: TDEEService?
    @State private var metricsService: MetricsService?

    /// The goal this program belongs to
    let goal: NutritionGoal

    /// Optional existing program to edit
    let existingProgram: NutritionProgram?

    /// Callback when program is created/updated
    var onComplete: (() -> Void)?

    init(goal: NutritionGoal, existingProgram: NutritionProgram? = nil, onComplete: (() -> Void)? = nil) {
        self.goal = goal
        self.existingProgram = existingProgram
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: viewModel.progressPercent)
                    .tint(.blue)
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
                        PrimaryButton(title: "Continue") {
                            Task {
                                await handleContinue()
                            }
                        }
                        .disabled(!viewModel.canContinue)
                        .accessibilityIdentifier("program-wizard-continue-button")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(DesignTokens.Colors.background)
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
                viewModel.configureForEdit(program: existingProgram)
            }
        }
        .onChange(of: viewModel.programStyle) { _, newStyle in
            // Check for missing profile fields when Coached is selected
            if newStyle == .coached, let user = goal.user, let service = metricsService {
                Task {
                    await viewModel.checkMissingProfileFields(user: user, metricsService: service)
                }
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
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                return
            }
        }

        withAnimation(.spring()) {
            viewModel.advance()
        }
    }

    private func saveProgram() async {
        do {
            try viewModel.save(context: modelContext)

            // Calculate TDEE for Coached programs (await to ensure it completes before dismiss)
            if viewModel.programStyle == .coached {
                await calculateAndApplyTDEE()
            }

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
