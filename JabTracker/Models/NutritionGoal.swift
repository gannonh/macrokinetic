//
//  NutritionGoal.swift
//  JabTracker
//
//  SwiftData model for user nutrition and weight goals.
//  Supports weight loss, maintenance, and muscle gain programs.
//

import Foundation
import SwiftData

// MARK: - NutritionGoal Model

/// SwiftData model representing a user's nutrition and weight goal.
///
/// NutritionGoal captures the user's target weight, pace of change, and daily macro targets.
/// It serves as the foundation for the three-tier program system:
/// - **Coached**: App designs calorie/macro program based on goal and preferences
/// - **Collaborative**: User sets macro targets, app adjusts calorie budget based on progress
/// - **Manual**: User sets everything manually
///
/// **CloudKit Compatibility:**
/// - All properties have non-optional defaults
/// - Parent-child relationship uses plain property for child side
/// - Enum stored as String rawValue with computed type-safe accessor
///
/// **TDEE Foundation:**
/// - `initialEstimatedTDEE`, `lastCalculatedTDEE`, `lastTDEECalculationDate` fields
///   support adaptive TDEE calculations
@Model
final class NutritionGoal {
    // MARK: - Identity

    /// Unique identifier
    var id: UUID = UUID()

    // MARK: - Goal Configuration

    /// Goal type stored as raw string for CloudKit compatibility
    /// Use `goalType` computed property for type-safe access
    var goalTypeRaw: String = GoalType.weightLoss.rawValue

    /// Whether this goal is currently active
    var isActive: Bool = true

    // MARK: - Weight Targets

    /// Starting weight in kilograms when goal was created
    var startingWeightKg: Double = 70.0

    /// Target weight in kilograms
    var targetWeightKg: Double = 70.0

    /// Target date to reach goal
    var targetDate: Date = Date()

    /// Weekly weight change pace in kg (negative for loss, positive for gain)
    /// Common values: -0.5 (moderate loss), -1.0 (aggressive loss), +0.25 (lean gain)
    var weeklyWeightChangePaceKg: Double = -0.5

    // MARK: - Daily Macro Targets

    /// Daily calorie target
    var dailyCalorieTarget: Double = 2000.0

    /// Daily protein target in grams
    var dailyProteinTargetGrams: Double = 150.0

    /// Daily carbohydrate target in grams
    var dailyCarbTargetGrams: Double = 200.0

    /// Daily fat target in grams
    var dailyFatTargetGrams: Double = 65.0

    // MARK: - TDEE Tracking

    /// Last calculated TDEE based on actual weight changes
    /// Nil until adaptive TDEE calculation runs
    var lastCalculatedTDEE: Double?

    /// Date of last TDEE calculation
    var lastTDEECalculationDate: Date?

    /// Initial TDEE estimate from formula (before adaptive adjustments)
    var initialEstimatedTDEE: Double?

    // MARK: - Timestamps

    /// When this goal was created
    var createdAt: Date = Date()

    /// When this goal was last updated
    var updatedAt: Date = Date()

    // MARK: - Relationships

    /// Parent user who owns this goal
    /// Child side of relationship - no @Relationship attribute per CloudKit pattern
    var user: User?

    /// Associated nutrition program with configuration details
    /// Parent side with cascade delete
    @Relationship(deleteRule: .cascade, inverse: \NutritionProgram.goal)
    var program: NutritionProgram?

    // MARK: - Initialization

    /// Initialize a new nutrition goal
    ///
    /// - Parameters:
    ///   - goalType: Type of goal (weight loss, maintenance, muscle gain)
    ///   - isActive: Whether this goal is active (default: true)
    ///   - startingWeightKg: Starting weight in kg (default: 70.0)
    ///   - targetWeightKg: Target weight in kg (default: 70.0)
    ///   - targetDate: Target date for goal (default: now)
    ///   - weeklyWeightChangePaceKg: Weekly change pace (default: -0.5)
    ///   - dailyCalorieTarget: Daily calorie target (default: 2000)
    ///   - dailyProteinTargetGrams: Daily protein in grams (default: 150)
    ///   - dailyCarbTargetGrams: Daily carbs in grams (default: 200)
    ///   - dailyFatTargetGrams: Daily fat in grams (default: 65)
    init(
        goalType: GoalType = .weightLoss,
        isActive: Bool = true,
        startingWeightKg: Double = 70.0,
        targetWeightKg: Double = 70.0,
        targetDate: Date = Date(),
        weeklyWeightChangePaceKg: Double = -0.5,
        dailyCalorieTarget: Double = 2000.0,
        dailyProteinTargetGrams: Double = 150.0,
        dailyCarbTargetGrams: Double = 200.0,
        dailyFatTargetGrams: Double = 65.0
    ) {
        self.goalTypeRaw = goalType.rawValue
        self.isActive = isActive
        self.startingWeightKg = startingWeightKg
        self.targetWeightKg = targetWeightKg
        self.targetDate = targetDate
        self.weeklyWeightChangePaceKg = weeklyWeightChangePaceKg
        self.dailyCalorieTarget = dailyCalorieTarget
        self.dailyProteinTargetGrams = dailyProteinTargetGrams
        self.dailyCarbTargetGrams = dailyCarbTargetGrams
        self.dailyFatTargetGrams = dailyFatTargetGrams
        self.createdAt = Date()
        self.updatedAt = Date()
        // Don't initialize optional relationships - let SwiftData handle them
    }
}

// MARK: - Computed Properties

extension NutritionGoal {
    /// Type-safe accessor for goal type
    var goalType: GoalType {
        get {
            GoalType(rawValue: goalTypeRaw) ?? .weightLoss
        }
        set {
            goalTypeRaw = newValue.rawValue
        }
    }

    /// Total weight change from starting to target (negative for loss, positive for gain)
    var totalWeightChangeKg: Double {
        targetWeightKg - startingWeightKg
    }

    /// Estimated weeks to reach goal based on pace
    /// Returns 0 if no change needed or pace is zero
    var estimatedWeeksToGoal: Double {
        guard weeklyWeightChangePaceKg != 0 else { return 0 }
        let change = abs(totalWeightChangeKg)
        let pace = abs(weeklyWeightChangePaceKg)
        return change / pace
    }

    /// Whether the goal is on track (target date is in the future)
    var isOnTrack: Bool {
        targetDate > Date()
    }

    /// Projected end date based on starting weight, target, and weekly pace
    /// Returns nil for maintenance goals (no weight change) or zero pace
    var projectedEndDate: Date? {
        guard weeklyWeightChangePaceKg != 0,
            abs(totalWeightChangeKg) > 0.01
        else { return nil }
        let weeks = estimatedWeeksToGoal
        return createdAt.addingTimeInterval(weeks * 7 * 24 * 60 * 60)
    }

    /// Calories per kg of body weight (fat tissue energy density)
    private static let caloriesPerKgBodyWeight: Double = 7700

    /// Daily calorie adjustment per kg of weekly weight change
    /// Derived from: 7700 kcal/kg ÷ 7 days = 1100 kcal/day per kg/week
    private static var dailyCaloriesPerKgWeeklyChange: Double {
        caloriesPerKgBodyWeight / 7.0
    }

    /// Initial daily calorie budget estimate based on TDEE and weekly pace
    /// Uses formula: TDEE ± (weekly rate × 7700 kcal/kg ÷ 7 days)
    /// Returns nil if no TDEE estimate is available
    var initialDailyBudget: Int? {
        guard let tdee = initialEstimatedTDEE ?? lastCalculatedTDEE else { return nil }
        let dailyAdjustment = weeklyWeightChangePaceKg * Self.dailyCaloriesPerKgWeeklyChange
        return Int(tdee + dailyAdjustment)
    }

    /// Calculate progress toward goal as percentage (0.0 to 1.0+)
    /// - Parameter currentWeightKg: Current weight in kg
    /// - Returns: Progress percentage (0 = at start, 1 = at target, >1 = past target)
    ///
    /// For maintenance goals (no weight change target), returns 1.0 since the user
    /// is already at their target weight by definition.
    func progressPercentage(currentWeightKg: Double) -> Double {
        let totalChange = totalWeightChangeKg
        // For maintenance goals, user is already at target
        guard totalChange != 0 else { return 1.0 }

        let actualChange = currentWeightKg - startingWeightKg
        return actualChange / totalChange
    }

    /// Formatted display string for weight change goal
    var weightChangeDisplay: String {
        let change = totalWeightChangeKg
        let prefix = change > 0 ? "+" : ""
        return String(format: "%@%.1f kg", prefix, change)
    }
}

// MARK: - Per-Day Macro Targets

extension NutritionGoal {
    /// Get macro targets for a specific date, considering per-day distribution
    ///
    /// This method supports three sources of macro values (in priority order):
    /// 1. Per-day macros from WeeklyMacroDistribution (for Manual/Collaborative)
    /// 2. Shifted calorie distribution applied to base macros (for Coached/Shifted)
    /// 3. Goal's single daily targets (fallback)
    ///
    /// - Parameter date: The date to get targets for
    /// - Returns: DailyMacros for that date
    func macroTargetsForDate(_ date: Date) -> DailyMacros {
        let weekday = Calendar.current.component(.weekday, from: date)

        // Try per-day macros from program first (Manual, Collaborative)
        if let program = program,
            let dayMacros = program.weeklyMacros?.macrosForDay(weekday)
        {
            // Apply shifted calorie distribution if also set
            var macros = dayMacros
            if let distribution = program.weeklyDistribution,
                let multiplier = distribution.calorieTargetForDay(weekday, baseCalories: 1.0)
            {
                macros.calories *= multiplier
            }
            return macros
        }

        // Try shifted calorie distribution on base macros (Coached/Shifted)
        if let program = program,
            let distribution = program.weeklyDistribution
        {
            let multiplier = distribution.calorieTargetForDay(weekday, baseCalories: 1.0) ?? 1.0
            return DailyMacros(
                calories: dailyCalorieTarget * multiplier,
                proteinGrams: dailyProteinTargetGrams,
                fatGrams: dailyFatTargetGrams,
                carbsGrams: dailyCarbTargetGrams
            )
        }

        // Fall back to goal's single daily targets
        return DailyMacros(
            calories: dailyCalorieTarget,
            proteinGrams: dailyProteinTargetGrams,
            fatGrams: dailyFatTargetGrams,
            carbsGrams: dailyCarbTargetGrams
        )
    }
}
