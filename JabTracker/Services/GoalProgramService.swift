//
//  GoalProgramService.swift
//  JabTracker
//
//  Service for creating NutritionGoal and NutritionProgram with smart defaults.
//  Used during onboarding to create initial goal/program from simplified selections.
//

import Foundation
import OSLog
import SwiftData

/// Service for creating NutritionGoal and NutritionProgram with smart defaults.
///
/// This service takes simplified user selections (GoalType + ProgramStyle) and
/// creates complete NutritionGoal and NutritionProgram entities with sensible
/// default values for macros, target weight, and weekly pace.
@MainActor
final class GoalProgramService {
    // MARK: - Properties

    private let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "GoalProgramService"
    )

    // MARK: - Smart Default Constants

    /// Default base calories for smart defaults (2000 kcal)
    private static let defaultBaseCalories: Double = 2000.0

    /// Default protein target in grams (150g - moderate protein level)
    private static let defaultProteinGrams: Double = 150.0

    /// Default carb target in grams (200g - balanced diet)
    private static let defaultCarbGrams: Double = 200.0

    /// Default fat target in grams (67g - balanced diet)
    private static let defaultFatGrams: Double = 67.0

    /// Weight change for weight loss goal (lose 10 kg)
    private static let weightLossTargetChange: Double = -10.0

    /// Weight change for muscle gain goal (gain 5 kg)
    private static let muscleGainTargetChange: Double = 5.0

    /// Weekly rate for weight loss (-0.5 kg/week)
    private static let weightLossWeeklyRate: Double = -0.5

    /// Weekly rate for muscle gain (+0.25 kg/week)
    private static let muscleGainWeeklyRate: Double = 0.25

    // MARK: - Public Interface

    /// Create NutritionGoal and NutritionProgram with smart defaults.
    ///
    /// - Parameters:
    ///   - user: The user to associate the goal with
    ///   - goalType: Selected goal type (weight loss, maintenance, muscle gain)
    ///   - programStyle: Selected program style (coached, collaborative, manual)
    ///   - startingWeightKg: User's starting weight in kg
    ///   - context: SwiftData model context for persistence
    /// - Returns: Tuple containing the created goal and program
    /// - Throws: Error if context save fails
    func createGoalAndProgram(
        for user: User,
        goalType: GoalType,
        programStyle: ProgramStyle,
        startingWeightKg: Double,
        in context: ModelContext
    ) throws -> (goal: NutritionGoal, program: NutritionProgram) {
        logger.debug("Creating goal/program: type=\(goalType.rawValue), style=\(programStyle.rawValue)")

        // Calculate smart defaults based on goal type
        let defaults = calculateDefaults(for: goalType, startingWeight: startingWeightKg)

        // Create NutritionGoal
        let goal = NutritionGoal(
            goalType: goalType,
            isActive: true,
            startingWeightKg: startingWeightKg,
            targetWeightKg: defaults.targetWeight,
            targetDate: defaults.targetDate,
            weeklyWeightChangePaceKg: defaults.weeklyRate,
            dailyCalorieTarget: defaults.calories,
            dailyProteinTargetGrams: defaults.protein,
            dailyCarbTargetGrams: defaults.carbs,
            dailyFatTargetGrams: defaults.fat
        )

        // Create NutritionProgram with default settings
        let program = NutritionProgram(
            style: programStyle,
            diet: .balanced,
            calorieFloor: .standard,
            trainingLevel: .none,
            distributionMode: .even,
            proteinLevel: .moderate
        )

        // Establish relationships
        goal.user = user
        goal.program = program
        program.goal = goal

        // Insert into context
        context.insert(goal)
        context.insert(program)

        // Save
        try context.save()

        logger.info("Goal and program created successfully for user: \(user.email ?? "unknown")")
        return (goal, program)
    }

    // MARK: - Smart Defaults Calculation

    /// Calculated defaults for a goal
    struct GoalDefaults {
        let targetWeight: Double
        let weeklyRate: Double
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let targetDate: Date
    }

    /// Calculate smart defaults based on goal type and starting weight.
    ///
    /// - Parameters:
    ///   - goalType: The selected goal type
    ///   - startingWeight: User's starting weight in kg
    /// - Returns: Calculated default values
    func calculateDefaults(for goalType: GoalType, startingWeight: Double) -> GoalDefaults {
        let targetWeight: Double
        let weeklyRate: Double

        switch goalType {
        case .weightLoss:
            targetWeight = startingWeight + Self.weightLossTargetChange
            weeklyRate = Self.weightLossWeeklyRate
        case .maintenance:
            targetWeight = startingWeight
            weeklyRate = 0.0
        case .muscleGain:
            targetWeight = startingWeight + Self.muscleGainTargetChange
            weeklyRate = Self.muscleGainWeeklyRate
        }

        // Calculate target date based on weight change and weekly rate
        let targetDate: Date
        if weeklyRate != 0 {
            let weightChange = abs(targetWeight - startingWeight)
            let weeksToGoal = weightChange / abs(weeklyRate)
            targetDate =
                Calendar.current.date(
                    byAdding: .day,
                    value: Int(weeksToGoal * 7),
                    to: Date()
                ) ?? Date()
        } else {
            // Maintenance: ongoing, set target 1 year out
            targetDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        }

        return GoalDefaults(
            targetWeight: targetWeight,
            weeklyRate: weeklyRate,
            calories: Self.defaultBaseCalories,
            protein: Self.defaultProteinGrams,
            carbs: Self.defaultCarbGrams,
            fat: Self.defaultFatGrams,
            targetDate: targetDate
        )
    }
}
