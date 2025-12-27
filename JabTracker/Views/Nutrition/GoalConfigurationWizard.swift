//
//  GoalConfigurationWizard.swift
//  JabTracker
//
//  Multi-step wizard for creating nutrition goals and programs.
//

import SwiftData
import SwiftUI

// MARK: - Wizard Step Enum

/// Steps in the goal configuration wizard
enum GoalWizardStep: String, CaseIterable {
    case goalType
    case programStyle
    case dietPreference
    case calorieFloor
    case weeklyDistribution
    case proteinLevel
    case confirmation

    var title: String {
        switch self {
        case .goalType: return "Choose Your Goal"
        case .programStyle: return "Program Style"
        case .dietPreference: return "Diet Preference"
        case .calorieFloor: return "Calorie Floor"
        case .weeklyDistribution: return "Weekly Distribution"
        case .proteinLevel: return "Protein Level"
        case .confirmation: return "Review & Confirm"
        }
    }

    var subtitle: String {
        switch self {
        case .goalType: return "What are you working toward?"
        case .programStyle: return "How much guidance do you want?"
        case .dietPreference: return "Choose your macro balance"
        case .calorieFloor: return "Set your minimum daily calories"
        case .weeklyDistribution: return "How to spread calories across the week"
        case .proteinLevel: return "How much protein do you need?"
        case .confirmation: return "Ready to start your program"
        }
    }
}

// MARK: - Wizard Error

/// Errors that can occur during wizard completion
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

// MARK: - Wizard ViewModel

/// ViewModel for managing goal configuration wizard state
@Observable
@MainActor
final class GoalWizardViewModel {
    // MARK: - Step Navigation

    var currentStep: GoalWizardStep = .goalType

    // MARK: - Selections

    var goalType: GoalType?
    var programStyle: ProgramStyle?
    var dietPreference: DietPreference?
    var calorieFloorType: CalorieFloorType?
    var weeklyDistributionMode: WeeklyDistributionMode?
    var proteinLevel: ProteinLevel?

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
        case .programStyle:
            return programStyle != nil
        case .dietPreference:
            return dietPreference != nil
        case .calorieFloor:
            return calorieFloorType != nil
        case .weeklyDistribution:
            return weeklyDistributionMode != nil
        case .proteinLevel:
            return proteinLevel != nil
        case .confirmation:
            return allSelectionsComplete
        }
    }

    /// Whether all selections are complete
    private var allSelectionsComplete: Bool {
        goalType != nil && programStyle != nil && dietPreference != nil && calorieFloorType != nil
            && weeklyDistributionMode != nil && proteinLevel != nil
    }

    /// Whether this is the first step
    var isFirstStep: Bool {
        currentStep == GoalWizardStep.allCases.first
    }

    /// Whether this is the confirmation step
    var isConfirmationStep: Bool {
        currentStep == .confirmation
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

    // MARK: - Save

    /// Save the goal and program configuration
    /// - Parameters:
    ///   - context: SwiftData model context
    ///   - user: User to associate goal with
    func save(context: ModelContext, user: User) throws {
        guard let goalType,
            let programStyle,
            let dietPreference,
            let calorieFloorType,
            let weeklyDistributionMode,
            let proteinLevel
        else {
            throw GoalWizardError.incompleteData
        }

        // Create NutritionGoal
        let goal = NutritionGoal(goalType: goalType)
        goal.user = user
        context.insert(goal)

        // Create NutritionProgram
        let program = NutritionProgram(
            style: programStyle,
            diet: dietPreference,
            calorieFloor: calorieFloorType,
            distributionMode: weeklyDistributionMode,
            proteinLevel: proteinLevel
        )
        program.goal = goal
        context.insert(program)

        do {
            try context.save()
        } catch {
            throw GoalWizardError.saveFailed(error)
        }
    }
}

// MARK: - Main Wizard View

/// Multi-step wizard for configuring nutrition goals and programs
struct GoalConfigurationWizard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = GoalWizardViewModel()
    @State private var errorMessage: String?

    let user: User

    var body: some View {
        NavigationStack {
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
                HStack {
                    if !viewModel.isFirstStep {
                        SecondaryButton(title: "Back") {
                            withAnimation(.spring()) {
                                viewModel.goBack()
                            }
                        }
                        .accessibilityIdentifier("wizard-back-button")
                    }

                    Spacer()

                    if viewModel.isConfirmationStep {
                        PrimaryButton(title: "Create Goal") {
                            saveGoal()
                        }
                        .accessibilityIdentifier("wizard-save-button")
                    } else {
                        PrimaryButton(title: "Continue") {
                            withAnimation(.spring()) {
                                viewModel.advance()
                            }
                        }
                        .disabled(!viewModel.canContinue)
                        .accessibilityIdentifier("wizard-continue-button")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(DesignTokens.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("wizard-cancel-button")
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .accessibilityIdentifier("goal-configuration-wizard")
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .goalType:
            GoalTypeStepView(selection: $viewModel.goalType)
                .accessibilityIdentifier("goal-wizard-goalType-step")
        case .programStyle:
            ProgramStyleStepView(selection: $viewModel.programStyle)
                .accessibilityIdentifier("goal-wizard-programStyle-step")
        case .dietPreference:
            DietPreferenceStepView(selection: $viewModel.dietPreference)
                .accessibilityIdentifier("goal-wizard-dietPreference-step")
        case .calorieFloor:
            CalorieFloorStepView(selection: $viewModel.calorieFloorType)
                .accessibilityIdentifier("goal-wizard-calorieFloor-step")
        case .weeklyDistribution:
            WeeklyDistributionStepView(selection: $viewModel.weeklyDistributionMode)
                .accessibilityIdentifier("goal-wizard-weeklyDistribution-step")
        case .proteinLevel:
            ProteinLevelStepView(selection: $viewModel.proteinLevel)
                .accessibilityIdentifier("goal-wizard-proteinLevel-step")
        case .confirmation:
            ConfirmationStepView(viewModel: viewModel)
                .accessibilityIdentifier("goal-wizard-confirmation-step")
        }
    }

    private var stepNumber: Int {
        (GoalWizardStep.allCases.firstIndex(of: viewModel.currentStep) ?? 0) + 1
    }

    // MARK: - Actions

    private func saveGoal() {
        do {
            try viewModel.save(context: modelContext, user: user)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Step Views

/// Goal type selection step
private struct GoalTypeStepView: View {
    @Binding var selection: GoalType?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: GoalWizardStep.goalType.title,
                subtitle: GoalWizardStep.goalType.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(GoalType.allCases, id: \.self) { goalType in
                        SelectionCard(
                            title: goalType.displayName,
                            description: goalType.description,
                            isSelected: selection == goalType
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = goalType
                            }
                        }
                        .accessibilityIdentifier("wizard-goalType-\(goalType.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

/// Program style selection step
private struct ProgramStyleStepView: View {
    @Binding var selection: ProgramStyle?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: GoalWizardStep.programStyle.title,
                subtitle: GoalWizardStep.programStyle.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ProgramStyle.allCases, id: \.self) { style in
                        SelectionCard(
                            title: style.displayName,
                            description: style.description,
                            isSelected: selection == style
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = style
                            }
                        }
                        .accessibilityIdentifier("wizard-programStyle-\(style.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

/// Diet preference selection step
private struct DietPreferenceStepView: View {
    @Binding var selection: DietPreference?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: GoalWizardStep.dietPreference.title,
                subtitle: GoalWizardStep.dietPreference.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(DietPreference.allCases, id: \.self) { diet in
                        SelectionCard(
                            title: diet.displayName,
                            description: diet.description,
                            detail: macroDetail(for: diet),
                            isSelected: selection == diet
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = diet
                            }
                        }
                        .accessibilityIdentifier("wizard-dietPreference-\(diet.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func macroDetail(for diet: DietPreference) -> String {
        let macros = diet.macroPercentages
        return "P: \(Int(macros.protein))% C: \(Int(macros.carbs))% F: \(Int(macros.fat))%"
    }
}

/// Calorie floor selection step
private struct CalorieFloorStepView: View {
    @Binding var selection: CalorieFloorType?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: GoalWizardStep.calorieFloor.title,
                subtitle: GoalWizardStep.calorieFloor.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(CalorieFloorType.allCases, id: \.self) { floorType in
                        SelectionCard(
                            title: floorType.displayName,
                            description: floorType.description,
                            detail: "\(Int(floorType.minimumCalories)) cal/day minimum",
                            isSelected: selection == floorType,
                            showWarning: floorType.requiresWarning
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = floorType
                            }
                        }
                        .accessibilityIdentifier("wizard-calorieFloor-\(floorType.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

/// Weekly distribution selection step
private struct WeeklyDistributionStepView: View {
    @Binding var selection: WeeklyDistributionMode?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: GoalWizardStep.weeklyDistribution.title,
                subtitle: GoalWizardStep.weeklyDistribution.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(WeeklyDistributionMode.allCases, id: \.self) { mode in
                        SelectionCard(
                            title: mode.displayName,
                            description: mode.description,
                            isSelected: selection == mode
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = mode
                            }
                        }
                        .accessibilityIdentifier("wizard-weeklyDistribution-\(mode.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

/// Protein level selection step
private struct ProteinLevelStepView: View {
    @Binding var selection: ProteinLevel?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: GoalWizardStep.proteinLevel.title,
                subtitle: GoalWizardStep.proteinLevel.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ProteinLevel.allCases, id: \.self) { level in
                        SelectionCard(
                            title: level.displayName,
                            description: level.description,
                            detail: "\(level.gramsPerKg)g per kg body weight",
                            isSelected: selection == level
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = level
                            }
                        }
                        .accessibilityIdentifier("wizard-proteinLevel-\(level.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

/// Confirmation step showing all selections
private struct ConfirmationStepView: View {
    let viewModel: GoalWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: GoalWizardStep.confirmation.title,
                subtitle: GoalWizardStep.confirmation.subtitle
            )

            ScrollView {
                VStack(spacing: 16) {
                    SummaryRow(label: "Goal", value: viewModel.goalType?.displayName ?? "—")
                    SummaryRow(label: "Program Style", value: viewModel.programStyle?.displayName ?? "—")
                    SummaryRow(label: "Diet Preference", value: viewModel.dietPreference?.displayName ?? "—")
                    SummaryRow(label: "Calorie Floor", value: viewModel.calorieFloorType?.displayName ?? "—")
                    SummaryRow(
                        label: "Weekly Distribution",
                        value: viewModel.weeklyDistributionMode?.displayName ?? "—"
                    )
                    SummaryRow(label: "Protein Level", value: viewModel.proteinLevel?.displayName ?? "—")
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Helper Views

/// Step header with title and subtitle
private struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
}

/// Selection card for wizard options
private struct SelectionCard: View {
    let title: String
    let description: String
    var detail: String?
    let isSelected: Bool
    var showWarning: Bool = false
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if showWarning {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let detail {
                        Text(detail)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(description)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

/// Summary row for confirmation step
private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Preview

#Preview("Goal Type Step") {
    GoalConfigurationWizard(user: User(email: "test@example.com", name: "Test User"))
}
