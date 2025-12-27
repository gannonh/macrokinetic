//
//  ProgramWizard.swift
//  JabTracker
//
//  Multi-step wizard for configuring nutrition programs.
//  Separate from GoalWizard - handles Program domain (style, diet, training, etc.)
//

import SwiftData
import SwiftUI

// MARK: - Program Wizard Step Enum

/// Steps in the program configuration wizard
enum ProgramWizardStep: String, CaseIterable {
    case programStyle
    case dietPreference
    case calorieFloor
    case training
    case weeklyDistribution
    case proteinLevel
    case confirmation

    var title: String {
        switch self {
        case .programStyle: return "Program Style"
        case .dietPreference: return "Diet Preference"
        case .calorieFloor: return "Calorie Floor"
        case .training: return "Training Level"
        case .weeklyDistribution: return "Weekly Distribution"
        case .proteinLevel: return "Protein Level"
        case .confirmation: return "Review & Confirm"
        }
    }

    var subtitle: String {
        switch self {
        case .programStyle: return "How much guidance do you want?"
        case .dietPreference: return "Choose your macro balance"
        case .calorieFloor: return "Set your minimum daily calories"
        case .training: return "What's your activity level?"
        case .weeklyDistribution: return "How to spread calories across the week"
        case .proteinLevel: return "How much protein do you need?"
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

    // MARK: - Mode

    /// Whether we're editing an existing program (skips style selection)
    var isEditMode: Bool = false

    /// The existing program being edited
    var existingProgram: NutritionProgram?

    /// The goal this program belongs to
    var goal: NutritionGoal?

    // MARK: - Steps Configuration

    /// Steps available based on mode
    var availableSteps: [ProgramWizardStep] {
        if isEditMode {
            // Edit mode skips style selection
            return ProgramWizardStep.allCases.filter { $0 != .programStyle }
        }
        return ProgramWizardStep.allCases
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
        case .confirmation:
            return allSelectionsComplete
        }
    }

    /// Whether all selections are complete
    private var allSelectionsComplete: Bool {
        let hasStyle = isEditMode || programStyle != nil
        return hasStyle && dietPreference != nil && calorieFloorType != nil
            && trainingLevel != nil && weeklyDistributionMode != nil && proteinLevel != nil
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
}

// MARK: - Main Program Wizard View

/// Multi-step wizard for configuring nutrition programs
struct ProgramWizard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ProgramWizardViewModel()
    @State private var errorMessage: String?
    @State private var showingError = false

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
                HStack {
                    if !viewModel.isFirstStep {
                        SecondaryButton(title: "Back") {
                            withAnimation(.spring()) {
                                viewModel.goBack()
                            }
                        }
                        .accessibilityIdentifier("program-wizard-back-button")
                    }

                    Spacer()

                    if viewModel.isConfirmationStep {
                        PrimaryButton(title: viewModel.isEditMode ? "Save Program" : "Create Program") {
                            saveProgram()
                        }
                        .accessibilityIdentifier("program-wizard-save-button")
                    } else {
                        PrimaryButton(title: "Continue") {
                            withAnimation(.spring()) {
                                viewModel.advance()
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
            if let existingProgram {
                viewModel.configureForEdit(program: existingProgram)
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
        case .confirmation:
            ProgramConfirmationStepView(viewModel: viewModel)
                .accessibilityIdentifier("program-wizard-confirmation-step")
        }
    }

    private var stepNumber: Int {
        (viewModel.availableSteps.firstIndex(of: viewModel.currentStep) ?? 0) + 1
    }

    // MARK: - Actions

    private func saveProgram() {
        do {
            try viewModel.save(context: modelContext)
            onComplete?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Step Views

/// Program style selection step
private struct ProgramStyleStepView: View {
    @Binding var selection: ProgramStyle?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.programStyle.title,
                subtitle: ProgramWizardStep.programStyle.subtitle
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
                        .accessibilityIdentifier("program-wizard-programStyle-\(style.rawValue)")
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
                title: ProgramWizardStep.dietPreference.title,
                subtitle: ProgramWizardStep.dietPreference.subtitle
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
                        .accessibilityIdentifier("program-wizard-dietPreference-\(diet.rawValue)")
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
                title: ProgramWizardStep.calorieFloor.title,
                subtitle: ProgramWizardStep.calorieFloor.subtitle
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
                        .accessibilityIdentifier("program-wizard-calorieFloor-\(floorType.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

/// Training level selection step
private struct TrainingLevelStepView: View {
    @Binding var selection: TrainingLevel?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.training.title,
                subtitle: ProgramWizardStep.training.subtitle
            )

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(TrainingLevel.allCases, id: \.self) { level in
                        SelectionCard(
                            title: level.displayName,
                            description: level.description,
                            isSelected: selection == level
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = level
                            }
                        }
                        .accessibilityIdentifier("program-wizard-training-\(level.rawValue)")
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
                title: ProgramWizardStep.weeklyDistribution.title,
                subtitle: ProgramWizardStep.weeklyDistribution.subtitle
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
                        .accessibilityIdentifier("program-wizard-weeklyDistribution-\(mode.rawValue)")
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
                title: ProgramWizardStep.proteinLevel.title,
                subtitle: ProgramWizardStep.proteinLevel.subtitle
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
                        .accessibilityIdentifier("program-wizard-proteinLevel-\(level.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

/// Confirmation step showing all program selections
private struct ProgramConfirmationStepView: View {
    let viewModel: ProgramWizardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: ProgramWizardStep.confirmation.title,
                subtitle: ProgramWizardStep.confirmation.subtitle
            )

            ScrollView {
                VStack(spacing: 16) {
                    if !viewModel.isEditMode {
                        SummaryRow(label: "Program Style", value: viewModel.programStyle?.displayName ?? "—")
                    }
                    SummaryRow(label: "Diet Preference", value: viewModel.dietPreference?.displayName ?? "—")
                    SummaryRow(label: "Calorie Floor", value: viewModel.calorieFloorType?.displayName ?? "—")
                    SummaryRow(label: "Training Level", value: viewModel.trainingLevel?.displayName ?? "—")
                    SummaryRow(
                        label: "Weekly Distribution",
                        value: viewModel.weeklyDistributionMode?.displayName ?? "—"
                    )
                    SummaryRow(label: "Protein Level", value: viewModel.proteinLevel?.displayName ?? "—")

                    // Macro breakdown
                    if let diet = viewModel.dietPreference {
                        macroBreakdownCard(diet: diet)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func macroBreakdownCard(diet: DietPreference) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.blue)
                Text("Macro Breakdown")
                    .font(.headline)
                Spacer()
            }

            let macros = diet.macroPercentages
            HStack(spacing: 16) {
                macroItem(name: "Protein", percent: Int(macros.protein), color: .blue)
                macroItem(name: "Carbs", percent: Int(macros.carbs), color: .green)
                macroItem(name: "Fat", percent: Int(macros.fat), color: .orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }

    private func macroItem(name: String, percent: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(percent)%")
                .font(.headline)
                .foregroundColor(color)
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Reusable Step Header

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

// MARK: - Selection Card

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
