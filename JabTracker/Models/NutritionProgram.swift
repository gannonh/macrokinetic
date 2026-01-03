//
//  NutritionProgram.swift
//  JabTracker
//
//  SwiftData model for nutrition program configuration.
//  Stores program style, diet preferences, and calorie distribution settings.
//

import Foundation
import SwiftData
import os

// MARK: - NutritionProgram Model

/// Logger for NutritionProgram JSON encoding/decoding operations
private let nutritionProgramLogger = Logger(
    subsystem: "com.gannonhall.JabTracker",
    category: "NutritionProgram"
)

/// SwiftData model representing a nutrition program configuration.
///
/// NutritionProgram stores the detailed configuration for how a user's
/// nutrition goals are implemented. It supports three program styles:
/// - **Coached**: App designs calorie/macro program based on goal and preferences
/// - **Collaborative**: User sets macro targets, app adjusts calorie budget based on progress
/// - **Manual**: User sets everything manually
///
/// **CloudKit Compatibility:**
/// - All properties have non-optional defaults
/// - Complex configuration stored as JSON-encoded Data
/// - Enums stored as String rawValue with computed type-safe accessors
@Model
final class NutritionProgram {
    // MARK: - Identity

    /// Unique identifier
    var id: UUID = UUID()

    // MARK: - Program Configuration (Stored as String rawValues)

    /// Program style stored as raw string
    var programStyleRaw: String = ProgramStyle.coached.rawValue

    /// Diet preference stored as raw string
    var dietPreferenceRaw: String = DietPreference.balanced.rawValue

    /// Calorie floor type stored as raw string
    var calorieFloorTypeRaw: String = CalorieFloorType.standard.rawValue

    /// Weekly distribution mode stored as raw string
    var weeklyDistributionModeRaw: String = WeeklyDistributionMode.even.rawValue

    /// Protein level stored as raw string
    var proteinLevelRaw: String = ProteinLevel.moderate.rawValue

    /// Training level stored as raw string
    var trainingLevelRaw: String = TrainingLevel.none.rawValue

    // MARK: - Configuration Data

    /// JSON-encoded ProgramConfiguration for complex settings
    var configurationData: Data = Data()

    /// JSON-encoded WeeklyCalorieDistribution for custom day multipliers
    var weeklyDistributionData: Data?

    /// JSON-encoded WeeklyMacroDistribution for per-day macro targets
    var weeklyMacroDistributionData: Data?

    /// JSON-encoded Collaborative day configurations (calories, proteinGramsPerLb, carbFatRatio, isLocked)
    /// Stores the user's actual input parameters for Collaborative mode editing
    var collaborativeConfigData: Data?

    // MARK: - Timestamps

    /// When this program was created
    var createdAt: Date = Date()

    /// When this program was last updated
    var updatedAt: Date = Date()

    // MARK: - Relationships

    /// Parent goal this program belongs to
    /// Child side of relationship - no @Relationship attribute per CloudKit pattern
    var goal: NutritionGoal?

    // MARK: - Initialization

    /// Initialize a new nutrition program with default values
    ///
    /// - Parameters:
    ///   - style: Program style (default: coached)
    ///   - diet: Diet preference (default: balanced)
    ///   - calorieFloor: Calorie floor type (default: standard)
    ///   - trainingLevel: Training level (default: none)
    ///   - distributionMode: Weekly distribution mode (default: even)
    ///   - proteinLevel: Protein level (default: moderate)
    init(
        style: ProgramStyle = .coached,
        diet: DietPreference = .balanced,
        calorieFloor: CalorieFloorType = .standard,
        trainingLevel: TrainingLevel = .none,
        distributionMode: WeeklyDistributionMode = .even,
        proteinLevel: ProteinLevel = .moderate
    ) {
        self.programStyleRaw = style.rawValue
        self.dietPreferenceRaw = diet.rawValue
        self.calorieFloorTypeRaw = calorieFloor.rawValue
        self.trainingLevelRaw = trainingLevel.rawValue
        self.weeklyDistributionModeRaw = distributionMode.rawValue
        self.proteinLevelRaw = proteinLevel.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()

        // Encode initial configuration
        self.configurationData = Self.encodeConfiguration(
            style: style,
            diet: diet,
            calorieFloor: calorieFloor,
            trainingLevel: trainingLevel,
            distributionMode: distributionMode,
            proteinLevel: proteinLevel
        )
        // Don't initialize optional relationships - let SwiftData handle them
    }

    /// Encode a ProgramConfiguration to Data
    private static func encodeConfiguration(
        style: ProgramStyle,
        diet: DietPreference,
        calorieFloor: CalorieFloorType,
        trainingLevel: TrainingLevel,
        distributionMode: WeeklyDistributionMode,
        proteinLevel: ProteinLevel
    ) -> Data {
        let config = ProgramConfiguration(
            programStyle: style,
            dietPreference: diet,
            calorieFloorType: calorieFloor,
            trainingLevel: trainingLevel,
            weeklyDistributionMode: distributionMode,
            proteinLevel: proteinLevel
        )
        do {
            return try JSONEncoder().encode(config)
        } catch {
            nutritionProgramLogger.error(
                "Failed to encode ProgramConfiguration: \(error.localizedDescription)"
            )
            return Data()
        }
    }
}

// MARK: - Type-Safe Accessors

extension NutritionProgram {
    /// Type-safe accessor for program style
    var style: ProgramStyle {
        get {
            ProgramStyle(rawValue: programStyleRaw) ?? .coached
        }
        set {
            programStyleRaw = newValue.rawValue
            updateConfiguration()
        }
    }

    /// Type-safe accessor for diet preference
    var diet: DietPreference {
        get {
            DietPreference(rawValue: dietPreferenceRaw) ?? .balanced
        }
        set {
            dietPreferenceRaw = newValue.rawValue
            updateConfiguration()
        }
    }

    /// Type-safe accessor for calorie floor type
    var calorieFloor: CalorieFloorType {
        get {
            CalorieFloorType(rawValue: calorieFloorTypeRaw) ?? .standard
        }
        set {
            calorieFloorTypeRaw = newValue.rawValue
            updateConfiguration()
        }
    }

    /// Type-safe accessor for weekly distribution mode
    var distributionMode: WeeklyDistributionMode {
        get {
            WeeklyDistributionMode(rawValue: weeklyDistributionModeRaw) ?? .even
        }
        set {
            weeklyDistributionModeRaw = newValue.rawValue
            updateConfiguration()
        }
    }

    /// Type-safe accessor for protein level
    var protein: ProteinLevel {
        get {
            ProteinLevel(rawValue: proteinLevelRaw) ?? .moderate
        }
        set {
            proteinLevelRaw = newValue.rawValue
            updateConfiguration()
        }
    }

    /// Type-safe accessor for training level
    var training: TrainingLevel {
        get {
            TrainingLevel(rawValue: trainingLevelRaw) ?? .none
        }
        set {
            trainingLevelRaw = newValue.rawValue
            updateConfiguration()
        }
    }

    /// Decoded ProgramConfiguration
    var configuration: ProgramConfiguration? {
        guard !configurationData.isEmpty else { return nil }
        do {
            return try JSONDecoder().decode(ProgramConfiguration.self, from: configurationData)
        } catch {
            nutritionProgramLogger.error(
                "Failed to decode ProgramConfiguration: \(error.localizedDescription)"
            )
            return nil
        }
    }

    /// Decoded WeeklyCalorieDistribution
    var weeklyDistribution: WeeklyCalorieDistribution? {
        guard let data = weeklyDistributionData else { return nil }
        do {
            return try JSONDecoder().decode(WeeklyCalorieDistribution.self, from: data)
        } catch {
            nutritionProgramLogger.error(
                "Failed to decode WeeklyCalorieDistribution: \(error.localizedDescription)"
            )
            return nil
        }
    }

    /// Decoded WeeklyMacroDistribution
    var weeklyMacros: WeeklyMacroDistribution? {
        guard let data = weeklyMacroDistributionData else { return nil }
        do {
            return try JSONDecoder().decode(WeeklyMacroDistribution.self, from: data)
        } catch {
            nutritionProgramLogger.error(
                "Failed to decode WeeklyMacroDistribution: \(error.localizedDescription)"
            )
            return nil
        }
    }
}

// MARK: - Computed Properties

extension NutritionProgram {
    /// Minimum calories allowed based on calorie floor type
    var minimumCalories: Double {
        calorieFloor.minimumCalories
    }

    /// Whether this program uses coached macros (app designs the program)
    var usesCoachedMacros: Bool {
        style == .coached
    }

    /// Whether this program adjusts calories based on progress
    var adjustsCaloriesWithProgress: Bool {
        style == .coached || style == .collaborative
    }

    /// Calculate calorie target for a specific day of the week
    ///
    /// - Parameter weekday: Day of week (1=Sunday through 7=Saturday)
    /// - Returns: Calorie target for that day, or nil if invalid weekday
    ///
    /// For even distribution, returns the goal's base calorie target.
    /// For shifted distribution, applies the day-specific multiplier.
    func calorieTargetForDay(_ weekday: Int) -> Double? {
        guard WeeklyCalorieDistribution.validWeekdayRange.contains(weekday) else {
            return nil
        }

        // Get base calories from goal
        guard let baseCalories = goal?.dailyCalorieTarget else {
            return nil
        }

        // For even distribution, return base calories
        if distributionMode == .even {
            return baseCalories
        }

        // For shifted distribution, apply multiplier
        if let distribution = weeklyDistribution {
            return distribution.calorieTargetForDay(weekday, baseCalories: baseCalories)
        }

        // Fallback to base calories
        return baseCalories
    }
}

// MARK: - Configuration Update

extension NutritionProgram {
    /// Re-encode configuration when properties change
    private func updateConfiguration() {
        configurationData = Self.encodeConfiguration(
            style: style,
            diet: diet,
            calorieFloor: calorieFloor,
            trainingLevel: training,
            distributionMode: distributionMode,
            proteinLevel: protein
        )
        updatedAt = Date()
    }

    /// Set weekly distribution with validation
    ///
    /// - Parameter distribution: The distribution to set
    /// - Returns: True if distribution was set, false if invalid
    @discardableResult
    func setWeeklyDistribution(_ distribution: WeeklyCalorieDistribution) -> Bool {
        guard distribution.isValid else { return false }

        if let encoded = try? JSONEncoder().encode(distribution) {
            weeklyDistributionData = encoded
            distributionMode = .shifted
            return true
        }
        return false
    }

    /// Set weekly macro distribution with validation
    ///
    /// - Parameter distribution: The macro distribution to set
    /// - Returns: True if distribution was set, false if invalid
    @discardableResult
    func setWeeklyMacros(_ distribution: WeeklyMacroDistribution) -> Bool {
        guard distribution.isValid else { return false }

        if let encoded = try? JSONEncoder().encode(distribution) {
            weeklyMacroDistributionData = encoded
            return true
        }
        return false
    }

    /// Get macro targets for a specific day of the week
    ///
    /// - Parameters:
    ///   - weekday: Day of week (1=Sunday through 7=Saturday)
    ///   - goal: Fallback goal for default macros
    /// - Returns: DailyMacros for that day, or goal defaults if no per-day config
    func macrosForDay(_ weekday: Int, goal: NutritionGoal?) -> DailyMacros? {
        // Check for per-day macros first (handles weekday validation internally)
        if let weeklyMacros = weeklyMacros {
            return weeklyMacros.macrosForDay(weekday)
        }

        // Fall back to goal's single daily targets
        guard WeeklyConstants.validWeekdayRange.contains(weekday),
            let goal
        else { return nil }
        return DailyMacros(
            calories: goal.dailyCalorieTarget,
            proteinGrams: goal.dailyProteinTargetGrams,
            fatGrams: goal.dailyFatTargetGrams,
            carbsGrams: goal.dailyCarbTargetGrams
        )
    }
}

// MARK: - Collaborative Configuration Storage

/// Codable structure for storing Collaborative mode day configurations
struct CollaborativeDayConfigStorage: Codable {
    var calories: Double
    var proteinGramsPerLb: Double
    var carbFatRatio: Double
    var isLocked: Bool
}

/// Wrapper for storing all Collaborative day configs
struct CollaborativeConfigStorage: Codable {
    /// Per-day configurations (weekday: 1=Sun, 2=Mon, ..., 7=Sat)
    var dayConfigs: [Int: CollaborativeDayConfigStorage]

    /// Weekly calorie budget
    var weeklyCalorieBudget: Double
}

extension NutritionProgram {
    /// Save Collaborative day configurations
    /// - Returns: True if configuration was saved successfully, false on encoding failure
    @discardableResult
    func setCollaborativeConfig(_ dayConfigs: [Int: CollaborativeDayConfigStorage], weeklyBudget: Double) -> Bool {
        let storage = CollaborativeConfigStorage(dayConfigs: dayConfigs, weeklyCalorieBudget: weeklyBudget)
        do {
            collaborativeConfigData = try JSONEncoder().encode(storage)
            return true
        } catch {
            nutritionProgramLogger.error(
                "Failed to encode CollaborativeConfigStorage: \(error.localizedDescription)"
            )
            return false
        }
    }

    /// Load Collaborative day configurations
    var collaborativeConfig: CollaborativeConfigStorage? {
        guard let data = collaborativeConfigData else { return nil }
        do {
            return try JSONDecoder().decode(CollaborativeConfigStorage.self, from: data)
        } catch {
            nutritionProgramLogger.error(
                "Failed to decode CollaborativeConfigStorage: \(error.localizedDescription)"
            )
            return nil
        }
    }
}
