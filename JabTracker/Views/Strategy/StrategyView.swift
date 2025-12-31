//
//  StrategyView.swift
//  JabTracker
//
//  Main view for managing nutrition goals and programs.
//  Provides entry points for New Goal, Edit Goal, Edit Program, New Program flows.
//

import OSLog
import SwiftData
import SwiftUI

// MARK: - Constants

private enum SheetConstants {
    /// Delay between chained sheet presentations to ensure smooth animations
    static let chainedSheetDelay: TimeInterval = 0.35
}

// MARK: - Strategy View

/// Main view for managing nutrition strategy (goals and programs)
struct StrategyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    @State private var showingNewGoalWizard = false
    @State private var showingNewProgramWizard = false
    @State private var showingProgramSummary = false
    @State private var showingProgramReady = false
    @State private var createdGoal: NutritionGoal?
    @State private var goalToEdit: NutritionGoal?
    @State private var programToEdit: NutritionProgram?
    @State private var recalculationError: String?

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "StrategyView"
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let user = users.first {
                        if let activeGoal = user.activeNutritionGoal {
                            // Access program through goal's forward relationship
                            currentProgramSection(goal: activeGoal, program: activeGoal.program)
                            actionButtonsSection(user: user, activeGoal: activeGoal)
                        } else {
                            emptyStateSection(user: user)
                        }
                    } else {
                        noUserSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Strategy")
            .navigationBarTitleDisplayMode(.large)
        }
        // Edit Goal sheet - uses sheet(item:) to ensure goal is passed directly
        .sheet(item: $goalToEdit) { goal in
            if let user = users.first {
                GoalWizard(
                    user: user,
                    existingGoal: goal,
                    showIntro: false
                ) { savedGoal in
                    createdGoal = savedGoal
                    goalToEdit = nil

                    // Delay chained sheet presentation for Edit Goal → Program Summary
                    DispatchQueue.main.asyncAfter(deadline: .now() + SheetConstants.chainedSheetDelay) {
                        showingProgramSummary = true
                    }
                }
            }
        }
        // New Goal sheet - uses sheet(isPresented:)
        .sheet(isPresented: $showingNewGoalWizard) {
            if let user = users.first {
                GoalWizard(
                    user: user,
                    existingGoal: nil,
                    showIntro: true
                ) { goal in
                    createdGoal = goal
                    showingNewGoalWizard = false

                    // Delay chained sheet presentation for New Goal → Program Wizard
                    DispatchQueue.main.asyncAfter(deadline: .now() + SheetConstants.chainedSheetDelay) {
                        showingNewProgramWizard = true
                    }
                }
            }
        }
        // Edit Program sheet - uses sheet(item:) to pass program directly
        .sheet(item: $programToEdit) { program in
            if let goal = program.goal {
                ProgramWizard(
                    goal: goal,
                    existingProgram: program
                ) {
                    programToEdit = nil
                    createdGoal = nil
                }
            }
        }
        // New Program sheet - uses sheet(isPresented:)
        .sheet(isPresented: $showingNewProgramWizard) {
            if let goal = createdGoal ?? users.first?.activeNutritionGoal {
                ProgramWizard(
                    goal: goal,
                    existingProgram: nil
                ) {
                    showingNewProgramWizard = false

                    // Show Program Ready sheet for new programs
                    DispatchQueue.main.asyncAfter(deadline: .now() + SheetConstants.chainedSheetDelay) {
                        showingProgramReady = true
                    }
                }
            }
        }
        .sheet(
            isPresented: $showingProgramReady,
            onDismiss: {
                // Clean up state when sheet is dismissed (via Done button or swipe)
                createdGoal = nil
            },
            content: {
                // Access program through goal's forward relationship
                if let goal = createdGoal ?? users.first?.activeNutritionGoal,
                    let program = goal.program
                {
                    ProgramReadySheet(goal: goal, program: program) {}
                }
            }
        )
        .sheet(isPresented: $showingProgramSummary) {
            // Access program through goal's forward relationship
            if let goal = users.first?.activeNutritionGoal,
                let program = goal.program
            {
                ProgramSummarySheet(program: program) {
                    // Looks Good - recalculate targets with existing program settings
                    Task {
                        await recalculateProgramTargets(for: goal)
                    }
                    showingProgramSummary = false
                    createdGoal = nil
                } onSetNewProgram: {
                    // Set New Program - launch Program Wizard
                    showingProgramSummary = false
                    showingNewProgramWizard = true
                }
            } else {
                // Fallback: show loading or dismiss if no program found
                ProgressView("Loading...")
                    .onAppear {
                        // If no program found after a moment, dismiss and show error
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if users.first?.activeNutritionGoal?.program == nil {
                                showingProgramSummary = false
                            }
                        }
                    }
            }
        }
        .alert(
            "Update Failed",
            isPresented: Binding(
                get: { recalculationError != nil },
                set: { if !$0 { recalculationError = nil } }
            )
        ) {
            Button("OK") {
                recalculationError = nil
            }
        } message: {
            if let error = recalculationError {
                Text(error)
            }
        }
        .accessibilityIdentifier("strategy-view")
    }

    // MARK: - Current Program Section

    @ViewBuilder
    private func currentProgramSection(goal: NutritionGoal, program: NutritionProgram?) -> some View {
        VStack(spacing: 16) {
            // Check-in countdown (placeholder for Phase 16)
            checkInCountdownCard(goal: goal)

            // Current program display
            if let program {
                currentProgramCard(goal: goal, program: program)
            }

            // Goal summary card
            goalSummaryCard(goal: goal)
        }
    }

    private func checkInCountdownCard(goal: NutritionGoal) -> some View {
        HStack(spacing: 16) {
            // Countdown ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 64, height: 64)

                Circle()
                    .trim(from: 0, to: 0.7)  // Placeholder progress
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("7")
                        .font(.title3.bold())
                    Text("days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Next Check-In")
                    .font(.headline)
                // Placeholder - will be calculated in Phase 16
                Text("Weekly progress review")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .accessibilityIdentifier("check-in-countdown-card")
    }

    private func currentProgramCard(goal: NutritionGoal, program: NutritionProgram) -> some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let startDate = dateFormatter.string(from: program.createdAt)

        return VStack(alignment: .leading, spacing: 16) {
            // Header with date range
            VStack(alignment: .leading, spacing: 4) {
                Text("In Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(program.style.displayName) Program")
                    .font(.headline)
                Text("\(startDate) – Now")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Always show weekly grid for all program types
            weeklyMacroGrid(goal: goal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .accessibilityIdentifier("current-program-card")
    }

    // MARK: - Weekly Macro Grid (Collaborative/Manual)

    private static let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    private static let weekdayNumbers = [2, 3, 4, 5, 6, 7, 1]  // Mon-Sun mapped to weekday numbers

    private func weeklyMacroGrid(goal: NutritionGoal) -> some View {
        let dayMacros = Self.weekdayNumbers.map { goal.macroTargetsForDate(dateForWeekday($0)) }

        return VStack(spacing: 0) {
            // Day headers
            HStack(spacing: 2) {
                ForEach(Array(Self.dayLabels.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            // Calorie row (blue)
            weeklyMacroRow(
                values: dayMacros.map { Int($0.calories) },
                unit: "",
                color: .blue
            )

            // Protein row (orange)
            weeklyMacroRow(
                values: dayMacros.map { Int($0.proteinGrams) },
                unit: " P",
                color: .orange
            )

            // Fat row (yellow)
            weeklyMacroRow(
                values: dayMacros.map { Int($0.fatGrams) },
                unit: " F",
                color: .yellow
            )

            // Carbs row (green)
            weeklyMacroRow(
                values: dayMacros.map { Int($0.carbsGrams) },
                unit: " C",
                color: .green
            )
        }
    }

    private func weeklyMacroRow(values: [Int], unit: String, color: Color) -> some View {
        HStack(spacing: 2) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                Text("\(value)\(unit)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(color)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.15))
                    )
            }
        }
        .padding(.vertical, 1)
    }

    private func dateForWeekday(_ weekday: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = weekday
        return calendar.date(from: components) ?? Date()
    }

    private func targetRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Goal Summary Card

    private func goalSummaryCard(goal: NutritionGoal) -> some View {
        let user = users.first
        let usesMetric = user?.prefersMetricWeight ?? false
        let weightUnit = usesMetric ? "kg" : "lbs"
        let kgToLbs = 2.20462

        // Target weight in display units
        let targetWeight = usesMetric ? goal.targetWeightKg : goal.targetWeightKg * kgToLbs

        // Weekly rate in display units (absolute value for display, sign handled separately)
        let weeklyRateKg = goal.weeklyWeightChangePaceKg
        let weeklyRateDisplay = usesMetric ? weeklyRateKg : weeklyRateKg * kgToLbs

        // Weekly rate as percentage of body weight
        let currentWeightKg = goal.startingWeightKg > 0 ? goal.startingWeightKg : 80.0
        let ratePercent = (weeklyRateKg / currentWeightKg) * 100

        // Format date range
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let startDate = dateFormatter.string(from: goal.createdAt)

        return VStack(alignment: .leading, spacing: 16) {
            // Header - matches program card style
            VStack(alignment: .leading, spacing: 4) {
                Text("In Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(goal.goalType.displayName) Goal")
                    .font(.headline)
                Text("\(startDate) – Now")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Stats grid
            HStack(spacing: 0) {
                // Goal Weight
                goalStatColumn(
                    value: String(format: "%.0f", targetWeight),
                    unit: weightUnit,
                    label: "Goal Weight"
                )

                Spacer()

                // Goal Rate (absolute)
                goalStatColumn(
                    value: String(format: "%+.2f", weeklyRateDisplay),
                    unit: "\(weightUnit)/wk",
                    label: "Goal Rate"
                )

                Spacer()

                // Goal Rate (percentage)
                goalStatColumn(
                    value: String(format: "%+.1f", ratePercent),
                    unit: "%/wk",
                    label: "Goal Rate"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .accessibilityIdentifier("goal-summary-card")
    }

    private func goalStatColumn(value: String, unit: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title)
                    .fontWeight(.medium)
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Action Buttons Section

    @ViewBuilder
    private func actionButtonsSection(user: User, activeGoal: NutritionGoal) -> some View {
        VStack(spacing: 12) {
            // Has existing goal - show edit options
            HStack(spacing: 12) {
                actionButton(
                    title: "Edit Goal",
                    icon: "target",
                    color: .blue
                ) {
                    // Setting goalToEdit triggers sheet(item:) presentation
                    goalToEdit = activeGoal
                }
                .accessibilityIdentifier("edit-goal-button")

                actionButton(
                    title: "Edit Program",
                    icon: "slider.horizontal.3",
                    color: .purple
                ) {
                    // Setting programToEdit triggers sheet(item:) presentation
                    if let program = activeGoal.program {
                        programToEdit = program
                    } else {
                        Self.logger.warning("Edit Program tapped but activeGoal.program is nil")
                    }
                }
                .accessibilityIdentifier("edit-program-button")
            }

            HStack(spacing: 12) {
                actionButton(
                    title: "New Goal",
                    icon: "plus.circle",
                    color: .green
                ) {
                    // Use showingNewGoalWizard for new goal flow
                    showingNewGoalWizard = true
                }
                .accessibilityIdentifier("new-goal-button")

                actionButton(
                    title: "New Program",
                    icon: "arrow.triangle.2.circlepath",
                    color: .orange
                ) {
                    createdGoal = activeGoal
                    showingNewProgramWizard = true
                }
                .accessibilityIdentifier("new-program-button")
            }
        }
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
            .foregroundColor(color)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State Section

    @ViewBuilder
    private func emptyStateSection(user: User) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "target")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)

            VStack(spacing: 8) {
                Text("No Active Goal")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Create a goal to start tracking your nutrition progress.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(title: "Create Goal") {
                showingNewGoalWizard = true
            }
            .padding(.horizontal, 40)
            .accessibilityIdentifier("create-goal-button")
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - No User Section

    private var noUserSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Set up your profile")
                .font(.headline)

            Text("Complete onboarding to start setting nutrition goals.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .accessibilityIdentifier("no-user-section")
    }

    // MARK: - Recalculation

    /// Recalculate program targets after goal edit using existing program settings
    @MainActor
    private func recalculateProgramTargets(for goal: NutritionGoal) async {
        guard let user = users.first else {
            Self.logger.error("No user found for target recalculation")
            recalculationError = "Unable to update targets: user profile not found."
            return
        }

        let tdeeService = TDEEService(context: modelContext)

        do {
            // Recalculate TDEE and apply calorie/macro targets
            try await tdeeService.calculateAndApplyFullTDEE(for: user, goal: goal)
            Self.logger.info("Successfully recalculated program targets after goal edit")
        } catch {
            Self.logger.error("Failed to recalculate program targets: \(error.localizedDescription)")
            recalculationError = "Unable to update calorie targets. Please try editing your goal again."
        }
    }
}

// MARK: - Preview

#Preview("Strategy - With Goal") {
    StrategyView()
        .modelContainer(DataController.preview.container)
}

#Preview("Strategy - Empty") {
    StrategyView()
        .modelContainer(DataController.preview.container)
}
