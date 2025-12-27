//
//  ProgramConfiguration.swift
//  JabTracker
//
//  Enums and value types for nutrition program configuration.
//

import Foundation

// MARK: - MacroPercentages

/// Macro distribution as percentages (protein, carbs, fat)
struct MacroPercentages: Codable, Equatable {
    let protein: Double
    let carbs: Double
    let fat: Double

    /// Sum of all percentages (should equal 100 for valid distributions)
    var total: Double { protein + carbs + fat }
}

// MARK: - GoalType

/// Type of weight/nutrition goal the user is pursuing
enum GoalType: String, Codable, CaseIterable, Identifiable {
    case weightLoss = "weight_loss"
    case maintenance
    case muscleGain = "muscle_gain"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .maintenance: return "Maintenance"
        case .muscleGain: return "Muscle Gain"
        }
    }
}

// MARK: - ProgramStyle

/// How much the app guides the user's nutrition program
enum ProgramStyle: String, Codable, CaseIterable, Identifiable {
    case coached
    case collaborative
    case manual

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .coached: return "Coached"
        case .collaborative: return "Collaborative"
        case .manual: return "Manual"
        }
    }

    var description: String {
        switch self {
        case .coached:
            return "App designs your calorie and macro program based on your goal and preferences"
        case .collaborative:
            return "You set macro targets, app adjusts calorie budget based on your progress"
        case .manual:
            return "You set all targets manually with full control"
        }
    }
}

// MARK: - DietPreference

/// Macro distribution preference for the nutrition program
enum DietPreference: String, Codable, CaseIterable, Identifiable {
    case balanced
    case lowFat = "low_fat"
    case lowCarb = "low_carb"
    case keto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .balanced: return "Balanced"
        case .lowFat: return "Low Fat"
        case .lowCarb: return "Low Carb"
        case .keto: return "Keto"
        }
    }

    var description: String {
        switch self {
        case .balanced:
            return "Moderate amounts of all macronutrients"
        case .lowFat:
            return "Reduced fat intake with higher carbohydrates"
        case .lowCarb:
            return "Reduced carbohydrate intake with higher fat"
        case .keto:
            return "Very low carbohydrates, high fat for ketosis"
        }
    }

    /// Macro percentages for this diet preference
    var macroPercentages: MacroPercentages {
        switch self {
        case .balanced:
            return MacroPercentages(protein: 30, carbs: 40, fat: 30)
        case .lowFat:
            return MacroPercentages(protein: 30, carbs: 50, fat: 20)
        case .lowCarb:
            return MacroPercentages(protein: 30, carbs: 20, fat: 50)
        case .keto:
            return MacroPercentages(protein: 25, carbs: 5, fat: 70)
        }
    }
}

// MARK: - CalorieFloorType

/// Minimum calorie floor for safety
enum CalorieFloorType: String, Codable, CaseIterable, Identifiable {
    case standard
    case low

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .low: return "Low"
        }
    }

    var description: String {
        switch self {
        case .standard:
            return "Recommended minimum of 1,538 calories per day"
        case .low:
            return "Lower minimum of 1,025 calories (consult healthcare provider)"
        }
    }

    /// Minimum calories allowed per day
    var minimumCalories: Double {
        switch self {
        case .standard: return 1538
        case .low: return 1025
        }
    }

    /// Whether this floor type requires a health warning
    var requiresWarning: Bool {
        switch self {
        case .standard: return false
        case .low: return true
        }
    }
}

// MARK: - WeeklyDistributionMode

/// How calories are distributed across the week
enum WeeklyDistributionMode: String, Codable, CaseIterable, Identifiable {
    case even
    case shifted

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .even: return "Even"
        case .shifted: return "Shifted"
        }
    }

    var description: String {
        switch self {
        case .even:
            return "Same calorie target every day"
        case .shifted:
            return "Custom calorie targets for different days of the week"
        }
    }
}

// MARK: - ProteinLevel

/// Protein intake level relative to body weight
enum ProteinLevel: String, Codable, CaseIterable, Identifiable {
    case low
    case moderate
    case high
    case extraHigh = "extra_high"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .extraHigh: return "Extra High"
        }
    }

    var description: String {
        switch self {
        case .low:
            return "1.2g per kg body weight - minimal activity"
        case .moderate:
            return "1.6g per kg body weight - regular activity"
        case .high:
            return "2.0g per kg body weight - strength training"
        case .extraHigh:
            return "2.4g per kg body weight - intensive training"
        }
    }

    /// Grams of protein per kilogram of body weight
    var gramsPerKg: Double {
        switch self {
        case .low: return 1.2
        case .moderate: return 1.6
        case .high: return 2.0
        case .extraHigh: return 2.4
        }
    }
}

// MARK: - WeeklyCalorieDistribution

/// Custom calorie distribution across days of the week
struct WeeklyCalorieDistribution: Codable, Equatable {
    /// Multipliers for each day (1=Sunday, 2=Monday, ..., 7=Saturday)
    /// A multiplier of 1.0 means base calories, 1.2 means 20% more, 0.8 means 20% less
    /// Days without explicit multipliers default to 1.0
    var dayMultipliers: [Int: Double]

    /// Even distribution (all days at base calories)
    static var even: WeeklyCalorieDistribution {
        WeeklyCalorieDistribution(dayMultipliers: [:])
    }

    /// Calculate the calorie target for a specific day
    /// - Parameters:
    ///   - weekday: Day of week (1=Sunday through 7=Saturday)
    ///   - baseCalories: Base daily calorie target
    /// - Returns: Adjusted calorie target for that day
    func calorieTargetForDay(_ weekday: Int, baseCalories: Double) -> Double {
        let multiplier = dayMultipliers[weekday] ?? 1.0
        return baseCalories * multiplier
    }

    /// Validates that the weekly average equals base calories (sum of multipliers = 7.0)
    var isValid: Bool {
        // Calculate sum of all multipliers, using 1.0 for unspecified days
        var sum: Double = 0
        for day in 1...7 {
            sum += dayMultipliers[day] ?? 1.0
        }
        // Allow small floating point tolerance
        return abs(sum - 7.0) < 0.001
    }
}

// MARK: - ProgramConfiguration

/// Complete configuration for a nutrition program
struct ProgramConfiguration: Codable, Equatable {
    var programStyle: ProgramStyle
    var dietPreference: DietPreference
    var calorieFloorType: CalorieFloorType
    var weeklyDistributionMode: WeeklyDistributionMode
    var proteinLevel: ProteinLevel
    var metadata: [String: String]?

    init(
        programStyle: ProgramStyle,
        dietPreference: DietPreference,
        calorieFloorType: CalorieFloorType,
        weeklyDistributionMode: WeeklyDistributionMode,
        proteinLevel: ProteinLevel,
        metadata: [String: String]? = nil
    ) {
        self.programStyle = programStyle
        self.dietPreference = dietPreference
        self.calorieFloorType = calorieFloorType
        self.weeklyDistributionMode = weeklyDistributionMode
        self.proteinLevel = proteinLevel
        self.metadata = metadata
    }
}
