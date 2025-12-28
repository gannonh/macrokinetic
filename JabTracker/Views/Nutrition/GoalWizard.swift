//
//  GoalWizard.swift
//  JabTracker
//
//  Standalone wizard for creating/editing nutrition goals.
//  Separate from ProgramWizard - handles Goal domain (type, target, rate).
//

import SwiftData
import SwiftUI

// MARK: - Goal Wizard Step Enum

/// Steps in the goal wizard
enum GoalWizardStep: String, CaseIterable {
    case goalType
    case targetWeight
    case summary

    var title: String {
        switch self {
        case .goalType: return "Choose Your Goal"
        case .targetWeight: return "Set Your Target"
        case .summary: return "Goal Summary"
        }
    }

    var subtitle: String {
        switch self {
        case .goalType: return "What are you working toward?"
        case .targetWeight: return "Configure your target weight and pace"
        case .summary: return "Review your goal before continuing"
        }
    }
}

// MARK: - Goal Wizard Error

/// Errors that can occur during goal wizard completion
enum GoalWizardError: LocalizedError {
    case incompleteData
    case saveFailed(Error)
    case noUser

    var errorDescription: String? {
        switch self {
        case .incompleteData:
            return "Please complete all wizard steps before saving."
        case .saveFailed(let error):
            return "Failed to save goal: \(error.localizedDescription)"
        case .noUser:
            return "No user found. Please sign in and try again."
        }
    }
}

// MARK: - Goal Wizard ViewModel

/// ViewModel for managing goal wizard state
@Observable
@MainActor
final class GoalWizardViewModel {
    // MARK: - Constants

    private static let kgToLbs = 2.20462

    // MARK: - Step Navigation

    var currentStep: GoalWizardStep = .goalType

    // MARK: - Selections

    var goalType: GoalType?
    var targetWeightKg: Double = 70.0
    var currentWeightKg: Double = 70.0
    var weeklyRateKg: Double = 0.5

    // MARK: - Unit Preference

    /// Whether user prefers metric (kg) or imperial (lbs)
    var usesMetricWeight: Bool = false

    /// Unit label for display
    var weightUnitLabel: String {
        usesMetricWeight ? "kg" : "lbs"
    }

    // MARK: - Display Conversions

    /// Current weight in user's preferred unit (editable)
    var currentWeightDisplay: Double {
        get { usesMetricWeight ? currentWeightKg : currentWeightKg * Self.kgToLbs }
        set {
            let newWeightKg = usesMetricWeight ? newValue : newValue / Self.kgToLbs

            // Ignore invalid values (user is mid-edit, e.g., backspaced to clear)
            guard newWeightKg >= 30 else { return }

            currentWeightKg = newWeightKg

            // Clamp target weight to stay within valid range for the goal type
            switch goalType {
            case .weightLoss:
                if targetWeightKg >= newWeightKg {
                    targetWeightKg = newWeightKg - 0.5
                }
            case .muscleGain:
                if targetWeightKg <= newWeightKg {
                    targetWeightKg = newWeightKg + 0.5
                }
            case .maintenance, .none:
                targetWeightKg = newWeightKg
            }
        }
    }

    /// Target weight in user's preferred unit
    var targetWeightDisplay: Double {
        get { usesMetricWeight ? targetWeightKg : targetWeightKg * Self.kgToLbs }
        set {
            targetWeightKg = usesMetricWeight ? newValue : newValue / Self.kgToLbs
        }
    }

    /// Weekly rate in user's preferred unit
    var weeklyRateDisplay: Double {
        get { usesMetricWeight ? weeklyRateKg : weeklyRateKg * Self.kgToLbs }
        set {
            weeklyRateKg = usesMetricWeight ? newValue : newValue / Self.kgToLbs
        }
    }

    /// Total weight change in user's preferred unit
    var totalWeightChangeDisplay: Double {
        usesMetricWeight ? totalWeightChange : totalWeightChange * Self.kgToLbs
    }

    // MARK: - Mode

    /// Whether we're editing an existing goal
    var isEditMode: Bool = false

    /// The existing goal being edited (nil for new goal)
    var existingGoal: NutritionGoal?

    // MARK: - Computed Properties

    /// Progress through the wizard (0.0 to 1.0)
    var progressPercent: Double {
        guard let currentIndex = GoalWizardStep.allCases.firstIndex(of: currentStep) else {
            return 0
        }
        return Double(currentIndex) / Double(GoalWizardStep.allCases.count - 1)
    }

    /// Whether user can continue to next step
    var canContinue: Bool {
        switch currentStep {
        case .goalType:
            return goalType != nil
        case .targetWeight:
            return isValidTargetConfiguration
        case .summary:
            return goalType != nil && isValidTargetConfiguration
        }
    }

    /// Whether target weight and rate configuration is valid
    private var isValidTargetConfiguration: Bool {
        guard let goalType else { return false }

        switch goalType {
        case .weightLoss:
            return targetWeightKg < currentWeightKg && weeklyRateKg > 0
        case .muscleGain:
            return targetWeightKg > currentWeightKg && weeklyRateKg > 0
        case .maintenance:
            return true  // No weight change needed
        }
    }

    /// Whether this is the first step
    var isFirstStep: Bool {
        currentStep == GoalWizardStep.allCases.first
    }

    /// Whether this is the summary step
    var isSummaryStep: Bool {
        currentStep == .summary
    }

    /// Total weight change (negative for loss, positive for gain)
    var totalWeightChange: Double {
        targetWeightKg - currentWeightKg
    }

    /// Estimated weeks to reach goal
    var estimatedWeeks: Double {
        guard weeklyRateKg > 0 else { return 0 }
        return abs(totalWeightChange) / weeklyRateKg
    }

    /// Projected end date based on current pace
    var projectedEndDate: Date? {
        guard estimatedWeeks > 0 else { return nil }
        return Date().addingTimeInterval(estimatedWeeks * 7 * 24 * 60 * 60)
    }

    /// Formatted duration string (e.g., "12 weeks" or "3 months")
    var durationDisplay: String {
        let weeks = Int(ceil(estimatedWeeks))
        if weeks >= 8 {
            let months = weeks / 4
            return "\(months) month\(months == 1 ? "" : "s")"
        }
        return "\(weeks) week\(weeks == 1 ? "" : "s")"
    }

    // MARK: - Navigation

    func advance() {
        guard let currentIndex = GoalWizardStep.allCases.firstIndex(of: currentStep),
            currentIndex + 1 < GoalWizardStep.allCases.count
        else {
            return
        }
        currentStep = GoalWizardStep.allCases[currentIndex + 1]
    }

    func goBack() {
        guard let currentIndex = GoalWizardStep.allCases.firstIndex(of: currentStep),
            currentIndex > 0
        else {
            return
        }
        currentStep = GoalWizardStep.allCases[currentIndex - 1]
    }

    // MARK: - Initialization

    /// Configure for editing an existing goal
    func configureForEdit(goal: NutritionGoal, usesMetric: Bool) {
        isEditMode = true
        existingGoal = goal
        goalType = goal.goalType
        targetWeightKg = goal.targetWeightKg
        currentWeightKg = goal.startingWeightKg
        weeklyRateKg = abs(goal.weeklyWeightChangePaceKg)
        usesMetricWeight = usesMetric
    }

    /// Configure with user's current weight and unit preference
    func configureWithCurrentWeight(_ weight: Double, usesMetric: Bool) {
        currentWeightKg = weight
        targetWeightKg = weight  // Start at same weight, user adjusts
        usesMetricWeight = usesMetric
    }

    // MARK: - Save

    /// Create or update the goal
    /// - Parameters:
    ///   - context: SwiftData model context
    ///   - user: User to associate goal with
    /// - Returns: The created or updated NutritionGoal
    func save(context: ModelContext, user: User) throws -> NutritionGoal {
        guard let goalType else {
            throw GoalWizardError.incompleteData
        }

        let goal: NutritionGoal

        if isEditMode, let existing = existingGoal {
            // Update existing goal
            goal = existing
            goal.goalTypeRaw = goalType.rawValue
            goal.targetWeightKg = targetWeightKg
            goal.weeklyWeightChangePaceKg = goalType == .weightLoss ? -weeklyRateKg : weeklyRateKg
            goal.updatedAt = Date()
        } else {
            // Deactivate existing active goals
            if let existingGoals = user.nutritionGoals {
                for existingGoal in existingGoals where existingGoal.isActive {
                    existingGoal.isActive = false
                }
            }

            // Create new goal
            let weeklyPace = goalType == .weightLoss ? -weeklyRateKg : weeklyRateKg
            goal = NutritionGoal(
                goalType: goalType,
                startingWeightKg: currentWeightKg,
                targetWeightKg: targetWeightKg,
                weeklyWeightChangePaceKg: weeklyPace
            )
            goal.user = user
            context.insert(goal)
        }

        do {
            try context.save()
        } catch {
            throw GoalWizardError.saveFailed(error)
        }

        return goal
    }
}

// MARK: - Main Goal Wizard View

/// Wizard for creating or editing nutrition goals
struct GoalWizard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = GoalWizardViewModel()
    @State private var errorMessage: String?
    @State private var showingError = false

    let user: User

    /// Callback when goal is created/updated - passes the goal to chain to ProgramWizard
    var onComplete: ((NutritionGoal) -> Void)?

    /// Whether to show the intro screen first (for new goal flow)
    var showIntro: Bool = true

    /// Existing goal for edit mode (nil for new goal)
    var existingGoal: NutritionGoal?

    @State private var showingIntro: Bool

    init(
        user: User,
        existingGoal: NutritionGoal? = nil,
        showIntro: Bool = true,
        onComplete: ((NutritionGoal) -> Void)? = nil
    ) {
        self.user = user
        self.existingGoal = existingGoal
        self.showIntro = showIntro
        self.onComplete = onComplete
        self._showingIntro = State(initialValue: showIntro)
    }

    var body: some View {
        NavigationStack {
            Group {
                if showingIntro {
                    introView
                } else {
                    wizardContent
                }
            }
            .background(DesignTokens.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("goal-wizard-cancel-button")
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
            // Configure for edit mode if editing existing goal
            if let existingGoal {
                viewModel.configureForEdit(goal: existingGoal, usesMetric: user.prefersMetricWeight)
            } else {
                // Set current weight from user's profile weight for new goals
                viewModel.configureWithCurrentWeight(user.weight, usesMetric: user.prefersMetricWeight)
            }
        }
        .accessibilityIdentifier("goal-wizard")
    }

    // MARK: - Intro View

    private var introView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Rocket illustration placeholder
            Image(systemName: "rocket.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
                .accessibilityHidden(true)

            VStack(spacing: 16) {
                Text("Let's Set Your Goal")
                    .font(.title)
                    .fontWeight(.bold)

                Text("We'll help you create a personalized goal in 2 easy steps:")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 16) {
                stepIndicator(number: 1, title: "Set Your Goal", description: "Choose your target and pace")
                stepIndicator(number: 2, title: "Build Your Program", description: "Configure how you'll get there")
            }
            .padding(.horizontal, 32)

            Spacer()

            PrimaryButton(title: "Get Started") {
                withAnimation(.spring()) {
                    showingIntro = false
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .accessibilityIdentifier("goal-wizard-get-started-button")
        }
        .padding()
    }

    private func stepIndicator(number: Int, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 36, height: 36)
                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Wizard Content

    private var wizardContent: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressView(value: viewModel.progressPercent)
                .tint(.blue)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .accessibilityLabel(
                    "Step \(stepNumber) of \(GoalWizardStep.allCases.count)"
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
                    .accessibilityIdentifier("goal-wizard-back-button")
                }

                if viewModel.isSummaryStep {
                    PrimaryButton(title: viewModel.isEditMode ? "Save Goal" : "Continue to Program") {
                        saveGoal()
                    }
                    .accessibilityIdentifier("goal-wizard-save-button")
                } else {
                    PrimaryButton(title: "Continue") {
                        withAnimation(.spring()) {
                            viewModel.advance()
                        }
                    }
                    .disabled(!viewModel.canContinue)
                    .accessibilityIdentifier("goal-wizard-continue-button")
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .goalType:
            GoalTypeSelectionView(selection: $viewModel.goalType)
                .accessibilityIdentifier("goal-wizard-goalType-step")
        case .targetWeight:
            TargetWeightStepView(viewModel: viewModel)
                .accessibilityIdentifier("goal-wizard-targetWeight-step")
        case .summary:
            GoalSummaryStepView(viewModel: viewModel)
                .accessibilityIdentifier("goal-wizard-summary-step")
        }
    }

    private var stepNumber: Int {
        (GoalWizardStep.allCases.firstIndex(of: viewModel.currentStep) ?? 0) + 1
    }

    // MARK: - Actions

    private func saveGoal() {
        do {
            let goal = try viewModel.save(context: modelContext, user: user)
            if let onComplete {
                onComplete(goal)
            } else {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Preview

#Preview("Goal Wizard - New Goal") {
    GoalWizard(user: User(email: "test@example.com", name: "Test User"))
}

#Preview("Goal Wizard - No Intro") {
    GoalWizard(user: User(email: "test@example.com", name: "Test User"), showIntro: false)
}
