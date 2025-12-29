//
//  TDEEService.swift
//  JabTracker
//
//  Orchestration service for TDEE calculation and persistence.
//  Coordinates data retrieval, engine calculations, and NutritionGoal updates.
//

import Foundation
import OSLog
import SwiftData

// MARK: - Types

/// Result of adaptive TDEE calculation
struct AdaptiveTDEEResult {
    let tdee: Double
    let confidence: Double
    let weightChangeRateKgPerWeek: Double
    let averageDailyIntake: Double
    let daysWithData: Int
    let hasMetabolicAdaptation: Bool

    var isHighConfidence: Bool { confidence >= 0.7 }
}

/// Errors that can occur during TDEE calculation
enum TDEEServiceError: LocalizedError {
    case missingUserData(String)
    case invalidUserData(String)
    case noWeightData
    case insufficientWeightData(required: Int, actual: Int)
    case insufficientFoodData(consistency: Double)
    case cannotDetermineWeightTrend
    case calculationFailed
    case dateCalculationFailed

    var errorDescription: String? {
        switch self {
        case .missingUserData(let field):
            return "Please add your \(field) in Settings to calculate TDEE."
        case .invalidUserData(let field):
            return "Please check your \(field) value in Settings."
        case .noWeightData:
            return "Please log your weight to calculate TDEE."
        case .insufficientWeightData(let required, let actual):
            return "Need at least \(required) days of weight data. You have \(actual) days."
        case .insufficientFoodData(let consistency):
            return "Need to log food on at least 70% of days. Current: \(Int(consistency * 100))%."
        case .cannotDetermineWeightTrend:
            return "Cannot determine weight trend from available data."
        case .calculationFailed:
            return "TDEE calculation failed. Please check your data."
        case .dateCalculationFailed:
            return "Unable to calculate date range. Please try again."
        }
    }
}

// MARK: - TDEEService

/// Orchestrates TDEE calculation and persistence.
/// Coordinates MetricsService and TDEECalculationEngine
/// to calculate initial and adaptive TDEE values, updating NutritionGoal.
@MainActor
final class TDEEService {

    // MARK: - Properties

    private let context: ModelContext
    private let engine: TDEECalculationEngine
    private let metricsService: MetricsService

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "TDEEService"
    )

    // Configuration (immutable after initialization)
    let ewmaAlpha: Double
    let minimumDaysForAdaptive: Int
    let minimumConsistencyForAdaptive: Double

    // MARK: - Initialization

    init(
        context: ModelContext,
        engine: TDEECalculationEngine = TDEECalculationEngine(),
        metricsService: MetricsService? = nil,
        ewmaAlpha: Double = 0.2,
        minimumDaysForAdaptive: Int = 14,
        minimumConsistencyForAdaptive: Double = 0.7
    ) {
        self.context = context
        self.engine = engine
        self.metricsService = metricsService ?? MetricsService(context: context)
        self.ewmaAlpha = ewmaAlpha
        self.minimumDaysForAdaptive = minimumDaysForAdaptive
        self.minimumConsistencyForAdaptive = minimumConsistencyForAdaptive
    }

    // MARK: - Initial TDEE

    /// Calculate initial TDEE estimate and save to NutritionGoal
    /// - Parameters:
    ///   - user: User with profile data (height, gender, dateOfBirth)
    ///   - goal: NutritionGoal to update
    /// - Throws: TDEEServiceError if required data is missing or invalid
    func calculateInitialTDEE(
        for user: User,
        goal: NutritionGoal
    ) async throws {
        // Get biometrics from MetricsService (reads from HealthKit if enabled)
        guard let heightCm = await metricsService.getCurrentHeight(for: user) else {
            throw TDEEServiceError.missingUserData("height")
        }
        guard heightCm > 0 else {
            throw TDEEServiceError.invalidUserData("height")
        }

        // Get date of birth from MetricsService (reads from HealthKit if enabled)
        guard let dateOfBirth = await metricsService.getCurrentDateOfBirth(for: user) else {
            throw TDEEServiceError.missingUserData("date of birth")
        }
        let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0

        // Get gender from MetricsService (reads from HealthKit if enabled)
        let gender = await metricsService.getCurrentGender(for: user)

        // Get training level from program
        let trainingLevel = goal.program?.training ?? .none

        // Get current weight from MetricsService (reads from HealthKit if enabled)
        guard let latestWeight = try await metricsService.getLatestWeightEntry() else {
            throw TDEEServiceError.noWeightData
        }

        // Validate inputs
        try engine.validateBMRInputs(
            weightKg: latestWeight.weightKg,
            heightCm: heightCm,
            age: age
        )

        // Calculate initial TDEE
        let tdee = engine.calculateInitialTDEE(
            weightKg: latestWeight.weightKg,
            heightCm: heightCm,
            age: age,
            gender: gender,
            trainingLevel: trainingLevel
        )

        // Update goal
        goal.initialEstimatedTDEE = tdee
        goal.lastCalculatedTDEE = tdee
        goal.lastTDEECalculationDate = Date()

        try context.save()

        Self.logger.debug(
            "Initial TDEE calculated: \(Int(tdee)) kcal/day for training level \(trainingLevel.displayName)"
        )
    }
}

// MARK: - Adaptive TDEE

extension TDEEService {

    /// Calculate adaptive TDEE from historical data
    /// - Parameters:
    ///   - goal: NutritionGoal with initial TDEE estimate
    ///   - lookbackDays: Number of days to analyze (default 28)
    /// - Returns: AdaptiveTDEEResult with calculated values
    /// - Throws: TDEEServiceError if insufficient data
    func calculateAdaptiveTDEE(
        goal: NutritionGoal,
        lookbackDays: Int = 28
    ) async throws -> AdaptiveTDEEResult {
        let (startDate, endDate) = try getDateRange(lookbackDays: lookbackDays)

        // Get and validate weight data
        let (smoothedWeights, changeRate) = try await getWeightTrendData(
            from: startDate, to: endDate
        )

        // Get and validate food data
        let (averageDailyIntake, uniqueDaysWithFood) = try await getFoodIntakeData(
            from: startDate, to: endDate, lookbackDays: lookbackDays
        )

        // Calculate adaptive TDEE
        let tdee = try calculateTDEEFromData(
            smoothedWeights: smoothedWeights,
            averageDailyIntake: averageDailyIntake,
            lookbackDays: lookbackDays
        )

        // Calculate confidence and adaptation
        let confidence = engine.calculateConfidenceScore(
            durationDays: lookbackDays,
            daysWithData: uniqueDaysWithFood,
            weightChangeRateKgPerWeek: changeRate
        )

        let expectedTDEE = goal.initialEstimatedTDEE ?? tdee
        let hasMetabolicAdaptation = engine.detectMetabolicAdaptation(
            actualTDEE: tdee,
            expectedTDEE: expectedTDEE
        )

        Self.logger.debug(
            "Adaptive TDEE: \(Int(tdee)) kcal, confidence: \(Int(confidence * 100))%"
        )

        return AdaptiveTDEEResult(
            tdee: tdee,
            confidence: confidence,
            weightChangeRateKgPerWeek: changeRate,
            averageDailyIntake: averageDailyIntake,
            daysWithData: uniqueDaysWithFood,
            hasMetabolicAdaptation: hasMetabolicAdaptation
        )
    }

    /// Update NutritionGoal with adaptive TDEE result
    /// - Parameters:
    ///   - goal: NutritionGoal to update
    ///   - result: AdaptiveTDEEResult from calculateAdaptiveTDEE
    func updateGoalWithAdaptiveTDEE(
        goal: NutritionGoal,
        result: AdaptiveTDEEResult
    ) throws {
        goal.lastCalculatedTDEE = result.tdee
        goal.lastTDEECalculationDate = Date()

        try context.save()

        Self.logger.debug("Goal updated with adaptive TDEE: \(Int(result.tdee)) kcal/day")
    }

    /// Check if TDEE should be recalculated (weekly)
    /// - Parameter goal: NutritionGoal to check
    /// - Returns: True if recalculation is needed
    func shouldRecalculateTDEE(goal: NutritionGoal) -> Bool {
        guard let lastCalcDate = goal.lastTDEECalculationDate else {
            return true  // Never calculated
        }

        let daysSinceLastCalc =
            Calendar.current.dateComponents(
                [.day],
                from: lastCalcDate,
                to: Date()
            ).day ?? 0

        return daysSinceLastCalc >= 7
    }
}

// MARK: - Private Helpers

extension TDEEService {

    private func getDateRange(lookbackDays: Int) throws -> (start: Date, end: Date) {
        let endDate = Date()
        guard
            let startDate = Calendar.current.date(
                byAdding: .day, value: -lookbackDays, to: endDate
            )
        else {
            Self.logger.error("Failed to calculate date range for \(lookbackDays) days lookback")
            throw TDEEServiceError.dateCalculationFailed
        }
        return (startDate, endDate)
    }

    private func getWeightTrendData(
        from startDate: Date,
        to endDate: Date
    ) async throws -> (smoothed: [(date: Date, smoothedWeight: Double)], changeRate: Double) {
        let weightEntries = try await metricsService.getWeightEntries(from: startDate, to: endDate)

        guard weightEntries.count >= minimumDaysForAdaptive else {
            throw TDEEServiceError.insufficientWeightData(
                required: minimumDaysForAdaptive,
                actual: weightEntries.count
            )
        }

        let weights =
            weightEntries
            .sorted { $0.timestamp < $1.timestamp }
            .map { ($0.timestamp, $0.weightKg) }

        let smoothedWeights = try engine.calculateEWMA(weights: weights, alpha: ewmaAlpha)

        let changeRate: Double
        do {
            changeRate = try engine.calculateWeightChangeRate(smoothedWeights: smoothedWeights)
        } catch let underlyingError {
            Self.logger.error("Weight trend calculation failed: \(underlyingError.localizedDescription)")
            throw TDEEServiceError.cannotDetermineWeightTrend
        }

        return (smoothedWeights, changeRate)
    }

    private func getFoodIntakeData(
        from startDate: Date,
        to endDate: Date,
        lookbackDays: Int
    ) async throws -> (averageIntake: Double, daysWithData: Int) {
        let foodEntries = try await getFoodEntries(from: startDate, to: endDate)

        let uniqueDaysWithFood = Set(
            foodEntries.map {
                Calendar.current.startOfDay(for: $0.loggedAt)
            }
        ).count

        let consistency = Double(uniqueDaysWithFood) / Double(lookbackDays)
        guard consistency >= minimumConsistencyForAdaptive else {
            throw TDEEServiceError.insufficientFoodData(consistency: consistency)
        }

        let totalCalories = foodEntries.reduce(0.0) { $0 + $1.calories }
        // Calculate average based on days with data, not total lookback days
        // This gives accurate per-day intake for TDEE calculation
        let averageDailyIntake =
            uniqueDaysWithFood > 0
            ? totalCalories / Double(uniqueDaysWithFood)
            : 0.0

        return (averageDailyIntake, uniqueDaysWithFood)
    }

    private func calculateTDEEFromData(
        smoothedWeights: [(date: Date, smoothedWeight: Double)],
        averageDailyIntake: Double,
        lookbackDays: Int
    ) throws -> Double {
        guard let firstWeight = smoothedWeights.first?.smoothedWeight,
            let lastWeight = smoothedWeights.last?.smoothedWeight
        else {
            throw TDEEServiceError.cannotDetermineWeightTrend
        }

        let weightChangeKg = lastWeight - firstWeight

        do {
            return try engine.calculateAdaptiveTDEE(
                averageDailyIntake: averageDailyIntake,
                weightChangeKg: weightChangeKg,
                durationDays: lookbackDays
            )
        } catch let underlyingError {
            Self.logger.error("Adaptive TDEE calculation failed: \(underlyingError.localizedDescription)")
            throw TDEEServiceError.calculationFailed
        }
    }

    /// Get food entries for a date range
    private func getFoodEntries(from startDate: Date, to endDate: Date) async throws -> [FoodEntry] {
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate { entry in
                entry.loggedAt >= startDate && entry.loggedAt <= endDate
            },
            sortBy: [SortDescriptor(\.loggedAt, order: .forward)]
        )

        return try context.fetch(descriptor)
    }
}

// MARK: - Calorie & Macro Calculations

extension TDEEService {

    /// Apply TDEE to derive calorie targets based on goal pace
    /// - Parameter goal: NutritionGoal with initialEstimatedTDEE set
    /// - Note: Enforces minimum calorie floor from program settings (default: 1200 kcal)
    func applyTDEEToGoal(_ goal: NutritionGoal) {
        guard let tdee = goal.initialEstimatedTDEE else { return }

        // Calculate daily calorie target from TDEE and weekly pace
        // 1 kg fat = ~7700 kcal, so daily adjustment = weeklyPaceKg * 7700 / 7 = weeklyPaceKg * 1100
        let dailyCalorieAdjustment = goal.weeklyWeightChangePaceKg * 1100
        let dailyCalorieTarget = tdee + dailyCalorieAdjustment

        // Apply calorie floor if configured in program
        let calorieFloor = goal.program?.calorieFloor.minimumCalories ?? 1200.0
        goal.dailyCalorieTarget = max(dailyCalorieTarget, calorieFloor)

        Self.logger.debug(
            "Applied TDEE to goal: TDEE=\(Int(tdee)), adjustment=\(Int(dailyCalorieAdjustment)), target=\(Int(goal.dailyCalorieTarget))"
        )
    }

    /// Calculate macros from program settings and apply to goal
    /// - Parameter goal: NutritionGoal with program and dailyCalorieTarget set
    func calculateAndApplyMacros(for goal: NutritionGoal) {
        guard let program = goal.program else { return }

        let macros = calculateMacros(
            calories: goal.dailyCalorieTarget,
            program: program,
            weightKg: goal.startingWeightKg
        )

        goal.dailyProteinTargetGrams = macros.protein
        goal.dailyFatTargetGrams = macros.fat
        goal.dailyCarbTargetGrams = macros.carbs

        Self.logger.debug(
            "Applied macros to goal: P=\(Int(macros.protein))g, F=\(Int(macros.fat))g, C=\(Int(macros.carbs))g"
        )
    }

    /// Calculate macros from program settings
    /// - Parameters:
    ///   - calories: Daily calorie target
    ///   - program: Nutrition program with diet and protein settings
    ///   - weightKg: User's weight in kg for protein calculation
    /// - Returns: Tuple of protein, fat, carbs in grams
    func calculateMacros(
        calories: Double,
        program: NutritionProgram,
        weightKg: Double
    ) -> (protein: Double, fat: Double, carbs: Double) {
        // Protein from program's protein level (g per kg body weight)
        let proteinGrams = program.protein.gramsPerKg * weightKg
        let proteinCalories = proteinGrams * 4

        // Remaining calories for fat and carbs
        let remainingCalories = calories - proteinCalories

        // Use diet preference macro split for remaining calories
        let macroSplit = program.diet.macroPercentages
        let fatPercent = macroSplit.fat / (macroSplit.fat + macroSplit.carbs)
        let carbPercent = macroSplit.carbs / (macroSplit.fat + macroSplit.carbs)

        let fatCalories = remainingCalories * fatPercent
        let carbCalories = remainingCalories * carbPercent

        return (
            protein: proteinGrams,
            fat: fatCalories / 9,  // 9 cal per gram fat
            carbs: carbCalories / 4  // 4 cal per gram carbs
        )
    }

    /// Full TDEE application: calculate TDEE, apply to goal, calculate macros
    /// Convenience method that orchestrates the full flow
    /// - Parameters:
    ///   - user: User with biometric data
    ///   - goal: NutritionGoal to update
    func calculateAndApplyFullTDEE(for user: User, goal: NutritionGoal) async throws {
        // Calculate initial TDEE
        try await calculateInitialTDEE(for: user, goal: goal)

        // Apply TDEE to get calorie target
        applyTDEEToGoal(goal)

        // Calculate and apply macros
        calculateAndApplyMacros(for: goal)

        try context.save()

        Self.logger.debug("Full TDEE calculation complete for goal")
    }
}
