//
//  ProgramOptimizationSheet.swift
//  JabTracker
//
//  Multi-step weekly check-in flow with intro, calculation animation, and results summary.
//  Shows personalized program optimization based on real user data.
//

import SwiftUI

// MARK: - Optimization Step

/// Steps in the optimization flow
enum OptimizationStep {
    case intro
    case calculating
    case results
}

// MARK: - Program Optimization Sheet

/// Multi-step check-in sheet with intro, calculation animation, and results
struct ProgramOptimizationSheet: View {
    // MARK: - Properties

    let goal: NutritionGoal
    let onAccept: (ProgramOptimizationResult) -> Void
    let onModify: (ProgramOptimizationResult) -> Void  // Only for Collaborative
    let onDecline: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var step: OptimizationStep = .intro
    @State private var result: ProgramOptimizationResult?
    @State private var error: String?
    @State private var statusMessage: String = "Analyzing weight trend..."

    /// Minimum time to show calculation animation (seconds)
    private let minimumCalculationDisplayTime: TimeInterval = 2.0

    /// Status messages that rotate during calculation
    private let statusMessages = [
        "Analyzing weight trend...",
        "Calculating metabolic rate...",
        "Evaluating food consistency...",
        "Optimizing macro targets...",
    ]

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .intro:
                    introContent
                case .calculating:
                    calculatingContent
                case .results:
                    resultsContent
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if step == .intro || step == .results {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("program-optimization-sheet")
    }

    private var navigationTitle: String {
        switch step {
        case .intro: return "Weekly Check-In"
        case .calculating: return "Optimizing"
        case .results: return "Program Update"
        }
    }

    // MARK: - Intro Content

    private var introContent: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Hero icon
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)
                    .padding(.top, 40)

                // Title and subtitle
                VStack(spacing: 12) {
                    Text("Time to optimize your program")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("We'll analyze your weight trend and food logging to fine-tune your macro targets.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Key point
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill.checkmark")
                            .foregroundColor(.green)
                        Text("Using your real data, not generic formulas")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )

                Spacer()

                // Start button
                PrimaryButton(title: "Start Program Optimization") {
                    startOptimization()
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding()
        }
        .accessibilityIdentifier("optimization-intro-step")
    }

    // MARK: - Calculating Content

    private var calculatingContent: some View {
        VStack(spacing: 32) {
            Spacer()

            // Progress indicator
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))

            // Status messages
            VStack(spacing: 8) {
                Text("Optimizing Your Program")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .animation(.easeInOut(duration: 0.3), value: statusMessage)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startStatusMessageRotation()
        }
        .accessibilityIdentifier("optimization-calculating-step")
    }

    // MARK: - Results Content

    private var resultsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                Text("Your program update is here!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)

                // Weekly macro grid
                if let result = result {
                    weeklyMacroGridSection(result: result)
                }

                // What changed section
                whatChangedSection

                // What's next section
                whatsNextSection

                // Action buttons
                actionButtons
                    .padding(.top, 8)
            }
            .padding()
        }
        .accessibilityIdentifier("optimization-results-step")
    }

    // MARK: - Weekly Macro Grid

    private static let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    private static let weekdayNumbers = [2, 3, 4, 5, 6, 7, 1]  // Mon-Sun mapped to weekday numbers

    private func weeklyMacroGridSection(result: ProgramOptimizationResult) -> some View {
        // Use proposed macros if available, otherwise current
        let dayMacros: [DailyMacros]
        if result.hasChanges, let proposedMacros = result.proposedWeeklyMacros {
            dayMacros = Self.weekdayNumbers.map { proposedMacros.macrosForDay($0) ?? proposedMacros.defaultMacros }
        } else {
            dayMacros = Self.weekdayNumbers.map { goal.macroTargetsForDate(dateForWeekday($0)) }
        }

        return VStack(spacing: 0) {
            // Day headers
            HStack(spacing: 4) {
                ForEach(Array(Self.dayLabels.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)

            // Calorie row (blue pill style)
            macroRow(
                values: dayMacros.map { Int($0.calories) },
                unit: "",
                color: .blue,
                isPill: true
            )

            // Protein row (orange)
            macroRow(
                values: dayMacros.map { Int($0.proteinGrams) },
                unit: " P",
                color: .orange,
                isPill: false
            )

            // Fat row (yellow)
            macroRow(
                values: dayMacros.map { Int($0.fatGrams) },
                unit: " F",
                color: .yellow,
                isPill: false
            )

            // Carbs row (green)
            macroRow(
                values: dayMacros.map { Int($0.carbsGrams) },
                unit: " C",
                color: .green,
                isPill: false
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .accessibilityIdentifier("optimization-weekly-macro-grid")
    }

    private func macroRow(values: [Int], unit: String, color: Color, isPill: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                ZStack {
                    if isPill {
                        Capsule()
                            .fill(color.opacity(0.15))
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color.opacity(0.15))
                    }

                    Text("\(value)\(unit)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(color)
                }
                .frame(maxWidth: .infinity)
                .frame(height: isPill ? 28 : 32)
            }
        }
        .padding(.vertical, 2)
    }

    private func dateForWeekday(_ weekday: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = weekday
        return calendar.date(from: components) ?? Date()
    }

    // MARK: - What Changed Section

    private var whatChangedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What changed?")
                .font(.headline)

            Text(result?.changeDescription ?? "Analyzing your data...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .accessibilityIdentifier("what-changed-section")
    }

    // MARK: - What's Next Section

    private var whatsNextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's next?")
                .font(.headline)

            Text(result?.whatNextDescription ?? "We'll provide recommendations...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .accessibilityIdentifier("whats-next-section")
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        let programStyle = goal.program?.style ?? .coached

        switch programStyle {
        case .coached:
            coachedButtons
        case .collaborative:
            collaborativeButtons
        case .manual:
            // Manual programs shouldn't reach this flow, but handle gracefully
            EmptyView()
        }
    }

    private var coachedButtons: some View {
        VStack(spacing: 12) {
            // Secondary: Decline
            SecondaryButton(title: "Decline and Silence") {
                onDecline()
                dismiss()
            }
            .accessibilityIdentifier("decline-button")

            // Primary: Accept
            PrimaryButton(title: "Accept Program Changes") {
                if let result = result {
                    onAccept(result)
                }
                dismiss()
            }
            .accessibilityIdentifier("accept-button")
        }
    }

    private var collaborativeButtons: some View {
        VStack(spacing: 12) {
            // Secondary: Decline
            SecondaryButton(title: "Decline") {
                onDecline()
                dismiss()
            }
            .accessibilityIdentifier("decline-button")

            // Tertiary: Modify (styled as secondary but different action)
            Button("Modify Program") {
                if let result = result {
                    onModify(result)
                }
                // Don't dismiss - onModify callback handles sheet chaining
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("modify-button")

            // Primary: Accept
            PrimaryButton(title: "Accept Changes") {
                if let result = result {
                    onAccept(result)
                }
                dismiss()
            }
            .accessibilityIdentifier("accept-button")
        }
    }

    // MARK: - Private Methods

    private func startOptimization() {
        withAnimation {
            step = .calculating
        }

        let startTime = Date()

        // Perform optimization calculation
        Task {
            let service = WeeklyCheckInService(context: modelContext)

            do {
                let optimizationResult = try await service.generateOptimization(for: goal)
                result = optimizationResult

                // Ensure minimum display time
                let elapsed = Date().timeIntervalSince(startTime)
                let remainingDelay = max(0, minimumCalculationDisplayTime - elapsed)

                if remainingDelay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(remainingDelay * 1_000_000_000))
                }

                await MainActor.run {
                    withAnimation {
                        step = .results
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    // Still show results with error info
                    withAnimation {
                        step = .results
                    }
                }
            }
        }
    }

    private func startStatusMessageRotation() {
        // Rotate through status messages
        Task {
            var index = 0
            while step == .calculating {
                await MainActor.run {
                    statusMessage = statusMessages[index]
                }
                index = (index + 1) % statusMessages.count
                try? await Task.sleep(nanoseconds: 600_000_000)  // 0.6 seconds
            }
        }
    }
}

// MARK: - Preview

#Preview("Program Optimization - Intro") {
    let goal = NutritionGoal(
        goalType: .weightLoss,
        targetWeightKg: 80.0,
        weeklyWeightChangePaceKg: -0.5,
        dailyCalorieTarget: 1850,
        dailyProteinTargetGrams: 150,
        dailyCarbTargetGrams: 185,
        dailyFatTargetGrams: 62
    )
    let program = NutritionProgram(style: .coached, diet: .balanced)
    goal.program = program

    return ProgramOptimizationSheet(
        goal: goal,
        onAccept: { _ in },
        onModify: { _ in },
        onDecline: {}
    )
}

#Preview("Program Optimization - Collaborative") {
    let goal = NutritionGoal(
        goalType: .weightLoss,
        targetWeightKg: 80.0,
        weeklyWeightChangePaceKg: -0.5,
        dailyCalorieTarget: 1850,
        dailyProteinTargetGrams: 150,
        dailyCarbTargetGrams: 185,
        dailyFatTargetGrams: 62
    )
    let program = NutritionProgram(style: .collaborative, diet: .balanced)
    goal.program = program

    return ProgramOptimizationSheet(
        goal: goal,
        onAccept: { _ in },
        onModify: { _ in },
        onDecline: {}
    )
}
