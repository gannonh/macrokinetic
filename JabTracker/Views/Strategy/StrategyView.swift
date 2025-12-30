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

    @State private var showingGoalWizard = false
    @State private var showingProgramWizard = false
    @State private var showingProgramSummary = false
    @State private var showingProgramReady = false
    @State private var isEditingGoal = false
    @State private var isEditingProgram = false
    @State private var createdGoal: NutritionGoal?

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
                            currentProgramSection(goal: activeGoal)
                            actionButtonsSection(user: user, hasGoal: true)
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
        .sheet(isPresented: $showingGoalWizard) {
            if let user = users.first {
                GoalWizard(
                    user: user,
                    existingGoal: isEditingGoal ? user.activeNutritionGoal : nil,
                    showIntro: !isEditingGoal
                ) { goal in
                    createdGoal = goal
                    showingGoalWizard = false

                    // Delay chained sheet presentation to ensure:
                    // 1. GoalWizard dismissal animation completes
                    // 2. createdGoal state propagates to child views
                    DispatchQueue.main.asyncAfter(deadline: .now() + SheetConstants.chainedSheetDelay) {
                        if isEditingGoal {
                            // Edit Goal flow → Show Program Summary
                            showingProgramSummary = true
                        } else {
                            // New Goal flow → Chain to Program Wizard
                            showingProgramWizard = true
                        }
                        isEditingGoal = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingProgramWizard) {
            if let goal = createdGoal ?? users.first?.activeNutritionGoal {
                ProgramWizard(
                    goal: goal,
                    existingProgram: isEditingProgram ? goal.program : nil
                ) {
                    showingProgramWizard = false

                    // Show Program Ready sheet for new Coached programs
                    if !isEditingProgram, goal.program?.style == .coached {
                        DispatchQueue.main.asyncAfter(deadline: .now() + SheetConstants.chainedSheetDelay) {
                            showingProgramReady = true
                        }
                    } else {
                        isEditingProgram = false
                        createdGoal = nil
                    }
                }
            }
        }
        .sheet(
            isPresented: $showingProgramReady,
            onDismiss: {
                // Clean up state when sheet is dismissed (via Done button or swipe)
                isEditingProgram = false
                createdGoal = nil
            },
            content: {
                if let goal = createdGoal ?? users.first?.activeNutritionGoal {
                    ProgramReadySheet(goal: goal) {}
                }
            }
        )
        .sheet(isPresented: $showingProgramSummary) {
            // Use queried user's active goal - @Query ensures relationships are loaded
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
                    showingProgramWizard = true
                }
            }
        }
        .accessibilityIdentifier("strategy-view")
    }

    // MARK: - Current Program Section

    @ViewBuilder
    private func currentProgramSection(goal: NutritionGoal) -> some View {
        VStack(spacing: 16) {
            // Check-in countdown (placeholder for Phase 16)
            checkInCountdownCard(goal: goal)

            // Current program display
            if let program = goal.program {
                currentProgramCard(goal: goal, program: program)
            }
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("In Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(program.style.displayName) Program")
                        .font(.headline)
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.blue)
            }

            Divider()

            // Daily targets
            VStack(spacing: 12) {
                targetRow(
                    icon: "flame.fill",
                    label: "Daily Calories",
                    value: "\(Int(goal.dailyCalorieTarget)) kcal",
                    color: .orange
                )
                targetRow(
                    icon: "p.circle.fill",
                    label: "Protein",
                    value: "\(Int(goal.dailyProteinTargetGrams))g",
                    color: .blue
                )
                targetRow(
                    icon: "c.circle.fill",
                    label: "Carbs",
                    value: "\(Int(goal.dailyCarbTargetGrams))g",
                    color: .green
                )
                targetRow(
                    icon: "f.circle.fill",
                    label: "Fat",
                    value: "\(Int(goal.dailyFatTargetGrams))g",
                    color: .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .accessibilityIdentifier("current-program-card")
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

    // MARK: - Action Buttons Section

    @ViewBuilder
    private func actionButtonsSection(user: User, hasGoal: Bool) -> some View {
        VStack(spacing: 12) {
            if hasGoal {
                // Has existing goal - show edit options
                HStack(spacing: 12) {
                    actionButton(
                        title: "Edit Goal",
                        icon: "target",
                        color: .blue
                    ) {
                        isEditingGoal = true
                        showingGoalWizard = true
                    }
                    .accessibilityIdentifier("edit-goal-button")

                    actionButton(
                        title: "Edit Program",
                        icon: "slider.horizontal.3",
                        color: .purple
                    ) {
                        isEditingProgram = true
                        showingProgramWizard = true
                    }
                    .accessibilityIdentifier("edit-program-button")
                }

                HStack(spacing: 12) {
                    actionButton(
                        title: "New Goal",
                        icon: "plus.circle",
                        color: .green
                    ) {
                        isEditingGoal = false
                        showingGoalWizard = true
                    }
                    .accessibilityIdentifier("new-goal-button")

                    actionButton(
                        title: "New Program",
                        icon: "arrow.triangle.2.circlepath",
                        color: .orange
                    ) {
                        isEditingProgram = false
                        createdGoal = user.activeNutritionGoal
                        showingProgramWizard = true
                    }
                    .accessibilityIdentifier("new-program-button")
                }
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
                isEditingGoal = false
                showingGoalWizard = true
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
            return
        }

        let tdeeService = TDEEService(context: modelContext)

        do {
            // Recalculate TDEE and apply calorie/macro targets
            try await tdeeService.calculateAndApplyFullTDEE(for: user, goal: goal)
            Self.logger.info("Successfully recalculated program targets after goal edit")
        } catch {
            Self.logger.error("Failed to recalculate program targets: \(error.localizedDescription)")
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
