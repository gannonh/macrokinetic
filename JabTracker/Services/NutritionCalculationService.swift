//
//  NutritionCalculationService.swift
//  JabTracker
//
//  SINGLE SOURCE OF TRUTH for all nutrition-related calculations.
//  All formulas, constants, and calculation logic live here.
//  Views and other services should NEVER duplicate these calculations.
//

import Foundation

// MARK: - Nutrition Calculation Constants

/// All nutrition-related constants in one place
enum NutritionConstants {
    /// Calories per kilogram of body fat (energy density)
    /// Used for calculating calorie adjustments from weight change goals
    static let caloriesPerKgBodyFat: Double = 7700

    /// Daily calorie adjustment per kg of weekly weight change
    /// Derived from: 7700 kcal/kg ÷ 7 days = 1100 kcal/day per kg/week
    static let dailyCaloriesPerKgWeeklyChange: Double = caloriesPerKgBodyFat / 7.0

    /// Conversion factor from kg to lbs
    static let kgToLbs: Double = 2.20462

    /// Conversion factor from lbs to kg
    static let lbsToKg: Double = 1.0 / kgToLbs

    /// Minimum reasonable TDEE (kcal/day)
    static let minimumReasonableTDEE: Double = 1000

    /// Maximum reasonable TDEE (kcal/day)
    static let maximumReasonableTDEE: Double = 6000

    /// Default calorie floor for safety
    static let defaultCalorieFloor: Double = 1200
}

// MARK: - Nutrition Calculation Service

/// Centralized service for all nutrition calculations.
/// This is the SINGLE SOURCE OF TRUTH for:
/// - Weekly pace calculations (weight loss/gain/maintenance)
/// - Daily calorie target calculations
/// - Macro calculations (protein, fat, carbs)
/// - TDEE adjustments
///
/// **IMPORTANT**: All views, wizards, and other services MUST use this service
/// for calculations instead of implementing their own formulas.
enum NutritionCalculationService {

    // MARK: - Weekly Pace Calculations

    /// Calculate the weekly weight change pace based on goal type and rate.
    ///
    /// This is the ONLY place this logic should exist. Do not duplicate.
    ///
    /// - Parameters:
    ///   - goalType: The type of goal (weight loss, maintenance, muscle gain)
    ///   - weeklyRateKg: The absolute rate of change in kg/week (always positive input)
    /// - Returns: Signed weekly pace (negative for loss, zero for maintenance, positive for gain)
    static func weeklyPace(for goalType: GoalType, weeklyRateKg: Double) -> Double {
        switch goalType {
        case .weightLoss:
            return -abs(weeklyRateKg)
        case .maintenance:
            return 0.0
        case .muscleGain:
            return abs(weeklyRateKg)
        }
    }

    /// Calculate the daily calorie adjustment from weekly pace.
    ///
    /// Formula: weeklyPaceKg × 7700 kcal/kg ÷ 7 days = weeklyPaceKg × 1100
    ///
    /// - Parameter weeklyPaceKg: Signed weekly pace (negative for deficit, positive for surplus)
    /// - Returns: Daily calorie adjustment (negative for deficit, positive for surplus)
    static func dailyCalorieAdjustment(from weeklyPaceKg: Double) -> Double {
        weeklyPaceKg * NutritionConstants.dailyCaloriesPerKgWeeklyChange
    }

    // MARK: - Daily Calorie Target Calculations

    /// Calculate daily calorie target from TDEE and weekly pace.
    ///
    /// Formula: TDEE + (weeklyPaceKg × 1100)
    ///
    /// - Parameters:
    ///   - tdee: Total Daily Energy Expenditure
    ///   - weeklyPaceKg: Signed weekly pace (negative for loss, positive for gain)
    ///   - calorieFloor: Minimum allowed calories (optional safety floor)
    /// - Returns: Daily calorie target, clamped to floor if specified
    static func dailyCalorieTarget(
        tdee: Double,
        weeklyPaceKg: Double,
        calorieFloor: Double? = nil
    ) -> Double {
        let adjustment = dailyCalorieAdjustment(from: weeklyPaceKg)
        let target = tdee + adjustment

        if let floor = calorieFloor {
            return max(target, floor)
        }
        return target
    }

    /// Calculate daily calorie target directly from goal type and rate.
    /// Convenience method that combines pace calculation with target calculation.
    ///
    /// - Parameters:
    ///   - tdee: Total Daily Energy Expenditure
    ///   - goalType: The type of goal
    ///   - weeklyRateKg: Absolute weekly rate in kg (always positive)
    ///   - calorieFloor: Minimum allowed calories (optional)
    /// - Returns: Daily calorie target
    static func dailyCalorieTarget(
        tdee: Double,
        goalType: GoalType,
        weeklyRateKg: Double,
        calorieFloor: Double? = nil
    ) -> Double {
        let pace = weeklyPace(for: goalType, weeklyRateKg: weeklyRateKg)
        return dailyCalorieTarget(tdee: tdee, weeklyPaceKg: pace, calorieFloor: calorieFloor)
    }

    // MARK: - Macro Calculations

    /// Calculate protein target in grams from body weight and protein level.
    ///
    /// - Parameters:
    ///   - weightKg: Body weight in kilograms
    ///   - proteinLevel: Selected protein level (provides g/kg multiplier)
    /// - Returns: Daily protein target in grams
    static func proteinGrams(weightKg: Double, proteinLevel: ProteinLevel) -> Double {
        weightKg * proteinLevel.gramsPerKg
    }

    /// Calculate protein target in grams using g/lb multiplier.
    ///
    /// - Parameters:
    ///   - weightKg: Body weight in kilograms
    ///   - gramsPerLb: Protein grams per pound of body weight
    /// - Returns: Daily protein target in grams
    static func proteinGrams(weightKg: Double, gramsPerLb: Double) -> Double {
        let weightLb = weightKg * NutritionConstants.kgToLbs
        return weightLb * gramsPerLb
    }

    /// Convert protein level's g/kg to g/lb for UI display.
    ///
    /// - Parameter proteinLevel: The protein level to convert
    /// - Returns: Grams per pound equivalent
    static func gramsPerLb(from proteinLevel: ProteinLevel) -> Double {
        proteinLevel.gramsPerKg / NutritionConstants.kgToLbs
    }

    /// Calculate macro distribution from calories, protein, and carb/fat ratio.
    ///
    /// - Parameters:
    ///   - totalCalories: Total daily calories
    ///   - proteinGrams: Protein in grams (fixed first)
    ///   - carbFatRatio: Ratio of remaining calories as carbs (0.0 = all fat, 1.0 = all carbs)
    /// - Returns: Tuple of (protein, fat, carbs) in grams
    static func macroDistribution(
        totalCalories: Double,
        proteinGrams: Double,
        carbFatRatio: Double
    ) -> MacroGrams {
        let proteinCalories = proteinGrams * MacroCalorieConstants.proteinCaloriesPerGram
        let remainingCalories = max(0, totalCalories - proteinCalories)

        let carbCalories = remainingCalories * carbFatRatio
        let fatCalories = remainingCalories * (1 - carbFatRatio)

        let carbGrams = carbCalories / MacroCalorieConstants.carbsCaloriesPerGram
        let fatGrams = fatCalories / MacroCalorieConstants.fatCaloriesPerGram

        return MacroGrams(protein: proteinGrams, fat: fatGrams, carbs: carbGrams)
    }

    /// Calculate macro distribution from diet preference percentages.
    ///
    /// - Parameters:
    ///   - totalCalories: Total daily calories
    ///   - dietPreference: Diet preference with macro percentages
    /// - Returns: Macro grams based on percentage distribution
    static func macroDistribution(
        totalCalories: Double,
        dietPreference: DietPreference
    ) -> MacroGrams {
        let percentages = dietPreference.macroPercentages

        let proteinCalories = totalCalories * (percentages.protein / 100)
        let carbCalories = totalCalories * (percentages.carbs / 100)
        let fatCalories = totalCalories * (percentages.fat / 100)

        return MacroGrams(
            protein: proteinCalories / MacroCalorieConstants.proteinCaloriesPerGram,
            fat: fatCalories / MacroCalorieConstants.fatCaloriesPerGram,
            carbs: carbCalories / MacroCalorieConstants.carbsCaloriesPerGram
        )
    }

    // MARK: - TDEE Calculations

    /// Calculate TDEE from intake and weight change (adaptive TDEE).
    ///
    /// Formula: TDEE = Average Daily Intake - (Weight Change × 7700 kcal/kg ÷ Days)
    ///
    /// - Parameters:
    ///   - averageDailyIntake: Average calories consumed per day
    ///   - weightChangeKg: Total weight change over the period (positive = gain, negative = loss)
    ///   - days: Number of days in the measurement period
    /// - Returns: Calculated TDEE, or nil if result is unreasonable
    static func adaptiveTDEE(
        averageDailyIntake: Double,
        weightChangeKg: Double,
        days: Int
    ) -> Double? {
        guard days > 0 else { return nil }

        let dailyWeightChangeCalories = (weightChangeKg * NutritionConstants.caloriesPerKgBodyFat) / Double(days)
        let tdee = averageDailyIntake - dailyWeightChangeCalories

        // Validate result is reasonable
        guard tdee >= NutritionConstants.minimumReasonableTDEE,
            tdee <= NutritionConstants.maximumReasonableTDEE
        else {
            return nil
        }

        return tdee
    }

    // MARK: - Display Helpers

    /// Format weekly pace for display (e.g., "0.5 kg/week deficit")
    ///
    /// - Parameters:
    ///   - weeklyPaceKg: Signed weekly pace
    ///   - usesMetric: Whether to display in metric (kg) or imperial (lbs)
    /// - Returns: Formatted string for display
    static func weeklyPaceDisplayString(weeklyPaceKg: Double, usesMetric: Bool) -> String {
        let absValue = abs(weeklyPaceKg)
        let displayValue = usesMetric ? absValue : absValue * NutritionConstants.kgToLbs
        let unit = usesMetric ? "kg" : "lbs"

        let formattedValue = String(format: "%.1f", displayValue)

        if weeklyPaceKg < 0 {
            return "\(formattedValue) \(unit)/week deficit"
        } else if weeklyPaceKg > 0 {
            return "\(formattedValue) \(unit)/week surplus"
        } else {
            return "Maintenance"
        }
    }

    /// Calculate daily calorie adjustment for display.
    ///
    /// - Parameter weeklyPaceKg: Signed weekly pace
    /// - Returns: Absolute daily calorie adjustment for display
    static func dailyCalorieAdjustmentDisplay(weeklyPaceKg: Double) -> Int {
        Int(abs(dailyCalorieAdjustment(from: weeklyPaceKg)))
    }
}
