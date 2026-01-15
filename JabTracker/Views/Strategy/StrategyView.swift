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
    @State private var showingProgramOptimization = false
    @State private var checkInError: String?
    @State private var dataQualityAssessment: DataQualityAssessment?
    @State private var isLoadingDataQuality = false

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "StrategyView"
    )

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Custom page header (handles its own padding)
                    PageHeader(title: "Strategy")

                    // Content with standard padding
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
            }
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
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
                    ProgramReadySheet(
                        goal: goal,
                        program: program,
                        onDone: {}
                    )
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
        // Program Optimization sheet
        .sheet(isPresented: $showingProgramOptimization) {
            if let goal = users.first?.activeNutritionGoal {
                ProgramOptimizationSheet(
                    goal: goal,
                    onAccept: { result in
                        applyOptimization(result, to: goal)
                        showingProgramOptimization = false
                    },
                    onModify: { result in
                        // Apply optimization first so new TDEE is saved, then let user modify settings
                        applyOptimization(result, to: goal)
                        showingProgramOptimization = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + SheetConstants.chainedSheetDelay) {
                            if let program = goal.program {
                                programToEdit = program
                            }
                        }
                    },
                    onDecline: {
                        declineOptimization(for: goal)
                        showingProgramOptimization = false
                    }
                )
            }
        }
        // Check-in error alert
        .alert(
            "Check-In Failed",
            isPresented: Binding(
                get: { checkInError != nil },
                set: { if !$0 { checkInError = nil } }
            )
        ) {
            Button("OK") {
                checkInError = nil
            }
        } message: {
            if let error = checkInError {
                Text(error)
            }
        }
        .accessibilityIdentifier("strategy-view")
    }

    // MARK: - Current Program Section

    @ViewBuilder
    private func currentProgramSection(goal: NutritionGoal, program: NutritionProgram?) -> some View {
        VStack(spacing: 16) {
            // Check-in countdown with inline day picker
            VStack(spacing: 0) {
                checkInCountdownCard(goal: goal)

                // Check-in day picker (only for non-Manual programs)
                if program?.style != .manual {
                    Divider()
                        .padding(.horizontal)
                    checkInDayPicker(goal: goal)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Current program display
            if let program {
                currentProgramCard(goal: goal, program: program)
            }

            // Goal summary card
            goalSummaryCard(goal: goal)
        }
    }

    @ViewBuilder
    private func checkInCountdownCard(goal: NutritionGoal) -> some View {
        // Hide for Manual programs (they manage their own adjustments)
        if goal.program?.style == .manual {
            EmptyView()
        } else {
            let checkInService = WeeklyCheckInService(context: modelContext)
            let daysUntil = checkInService.daysUntilCheckIn(for: goal)
            let isCheckInDue = checkInService.isCheckInDue(for: goal)
            let progress = max(0, min(1, Double(7 - daysUntil) / 7.0))

            // Check if data quality allows check-in
            let canCheckIn = dataQualityAssessment?.quality.allowsCheckIn ?? true

            // Main countdown card content
            let cardContent = HStack(spacing: 16) {
                // Countdown ring
                ZStack {
                    Circle()
                        .stroke(DesignTokens.Colors.inactive.opacity(0.5), lineWidth: 6)
                        .frame(width: 64, height: 64)

                    Circle()
                        .trim(from: 0, to: isCheckInDue ? 1.0 : progress)
                        .stroke(
                            checkInRingColor(isCheckInDue: isCheckInDue, canCheckIn: canCheckIn),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))

                    if isCheckInDue {
                        if canCheckIn {
                            Image(systemName: "checkmark")
                                .font(.title2.bold())
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "lock.fill")
                                .font(.title2.bold())
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack(spacing: 0) {
                            Text("\(daysUntil)")
                                .font(.title3.bold())
                            Text(daysUntil == 1 ? "day" : "days")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    if isCheckInDue {
                        if canCheckIn {
                            Text("Check-In Ready")
                                .font(.headline)
                                .foregroundColor(.green)
                            Text("Tap to optimize your program")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Weekly Check-In")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("More data needed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Next Check-In")
                            .font(.headline)
                        let dayName = dayOfWeekName(for: goal.checkInDayOfWeek)
                        Text("Every \(dayName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isCheckInDue && canCheckIn {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(DesignTokens.Colors.cardBackground)

            // Render card (tappable if check-in is available)
            if isCheckInDue && canCheckIn {
                Button {
                    showingProgramOptimization = true
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("check-in-countdown-card")
                .accessibilityLabel("Check-in ready. Tap to optimize your program.")
            } else {
                cardContent
                    .accessibilityIdentifier("check-in-countdown-card")
            }

            // Show improvement tips when check-in is due but data is insufficient
            if isCheckInDue, !canCheckIn, let assessment = dataQualityAssessment {
                improvementTipsCard(assessment: assessment)
                    .onAppear {
                        loadDataQuality()
                    }
            } else {
                // Invisible view to attach modifiers when tips aren't shown
                Color.clear
                    .frame(height: 0)
                    .onAppear {
                        if isCheckInDue {
                            loadDataQuality()
                        }
                    }
                    .onChange(of: isCheckInDue) { _, newValue in
                        if newValue {
                            loadDataQuality()
                        }
                    }
            }
        }
    }

    /// Color for the check-in ring based on state
    private func checkInRingColor(isCheckInDue: Bool, canCheckIn: Bool) -> Color {
        if isCheckInDue {
            return canCheckIn ? .green : .gray
        }
        return DesignTokens.Colors.accent
    }

    /// Card showing what users need to do to enable check-in
    private func improvementTipsCard(assessment: DataQualityAssessment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(DesignTokens.Colors.accent)
                Text("To Enable Check-In")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(assessment.improvementTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(DesignTokens.Colors.accent)
                            .padding(.top, 6)
                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.Colors.cardBackground)
        )
        .accessibilityIdentifier("improvement-tips-card")
    }

    /// Load data quality assessment asynchronously
    private func loadDataQuality() {
        guard !isLoadingDataQuality else { return }
        isLoadingDataQuality = true

        Task {
            let service = WeeklyCheckInService(context: modelContext)
            let assessment = await service.assessDataQuality()

            await MainActor.run {
                dataQualityAssessment = assessment
                isLoadingDataQuality = false
            }
        }
    }

    private func checkInDayPicker(goal: NutritionGoal) -> some View {
        HStack {
            Menu {
                ForEach(1...7, id: \.self) { day in
                    Button(dayOfWeekName(for: day)) {
                        goal.checkInDayOfWeek = day
                        goal.updatedAt = Date()
                        do {
                            try modelContext.save()
                        } catch {
                            Self.logger.error("Failed to save check-in day: \(error.localizedDescription)")
                            checkInError = "Unable to save check-in day. Please try again."
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Check-in day: \(dayOfWeekName(for: goal.checkInDayOfWeek))")
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(DesignTokens.Colors.cardBackground)
        .accessibilityIdentifier("check-in-day-picker")
    }

    private func dayOfWeekName(for weekday: Int) -> String {
        switch weekday {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return "Monday"
        }
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
                .fill(DesignTokens.Colors.cardBackground)
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

            // Calorie row
            weeklyMacroRow(
                values: dayMacros.map { Int($0.calories) },
                unit: "",
                color: DesignTokens.Colors.calories
            )

            // Protein row
            weeklyMacroRow(
                values: dayMacros.map { Int($0.proteinGrams) },
                unit: " P",
                color: DesignTokens.Colors.protein
            )

            // Fat row
            weeklyMacroRow(
                values: dayMacros.map { Int($0.fatGrams) },
                unit: " F",
                color: DesignTokens.Colors.fat
            )

            // Carbs row
            weeklyMacroRow(
                values: dayMacros.map { Int($0.carbsGrams) },
                unit: " C",
                color: DesignTokens.Colors.carbs
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
                .fill(DesignTokens.Colors.cardBackground)
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
                    color: DesignTokens.Colors.accent
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
                .foregroundStyle(DesignTokens.Colors.accent.gradient)

            VStack(spacing: 8) {
                Text("No Active Goal")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Create a goal to start tracking\nyour nutrition progress.")
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
                .fill(DesignTokens.Colors.cardBackground)
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

    // MARK: - Program Optimization

    /// Apply accepted optimization to goal/program
    private func applyOptimization(_ result: ProgramOptimizationResult, to goal: NutritionGoal) {
        let service = WeeklyCheckInService(context: modelContext)
        do {
            try service.applyOptimization(result, to: goal)
            Self.logger.info("Program optimization applied")
        } catch {
            Self.logger.error("Failed to apply optimization: \(error.localizedDescription)")
            checkInError = error.localizedDescription
        }
    }

    /// Mark check-in complete without applying changes (decline)
    private func declineOptimization(for goal: NutritionGoal) {
        let service = WeeklyCheckInService(context: modelContext)
        do {
            try service.declineOptimization(for: goal)
            Self.logger.info("Program optimization declined")
        } catch {
            Self.logger.error("Failed to decline optimization: \(error.localizedDescription)")
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
