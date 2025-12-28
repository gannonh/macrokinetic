//
//  TDEEService.swift
//  JabTracker
//
//  Orchestration service for TDEE calculation and persistence.
//  Coordinates data retrieval, engine calculations, and NutritionGoal updates.
//

import Foundation
import SwiftData
import os

/// Orchestrates TDEE calculation and persistence
@MainActor
@Observable
final class TDEEService {

    // MARK: - Properties

    private let context: ModelContext
    private let engine: TDEECalculationEngine
    private let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "TDEEService"
    )

    // Configuration
    var ewmaAlpha: Double = 0.2
    var minimumDaysForAdaptive: Int = 14
    var minimumConsistencyForAdaptive: Double = 0.7

    // MARK: - Initialization

    init(context: ModelContext, engine: TDEECalculationEngine = TDEECalculationEngine()) {
        self.context = context
        self.engine = engine
    }

    // MARK: - Initial TDEE

    /// Calculate initial TDEE estimate and save to NutritionGoal
    /// - Parameters:
    ///   - user: User with profile data (height, gender, dateOfBirth)
    ///   - goal: NutritionGoal to update
    /// - Throws: TDEEServiceError if required data is missing
    func calculateInitialTDEE(
        for user: User,
        goal: NutritionGoal
    ) async throws {
        // Validate user data
        guard let heightCm = user.heightCm, heightCm > 0 else {
            throw TDEEServiceError.missingUserData("height")
        }
        guard let age = user.age else {
            throw TDEEServiceError.missingUserData("date of birth")
        }

        // Get training level from program
        let trainingLevel = goal.program?.training ?? .none

        // Get current weight
        let weightService = WeightService(context: context)
        guard let latestWeight = try await weightService.getLatestEntry() else {
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
            gender: user.gender,
            trainingLevel: trainingLevel
        )

        // Update goal
        goal.initialEstimatedTDEE = tdee
        goal.lastCalculatedTDEE = tdee
        goal.lastTDEECalculationDate = Date()

        try context.save()

        logger.info(
            "Initial TDEE calculated: \(Int(tdee)) kcal/day for user with training level \(trainingLevel.displayName)"
        )
    }
}

// MARK: - Adaptive TDEE

extension TDEEService {

    /// Result of adaptive TDEE calculation
    struct AdaptiveTDEEResult {
        let tdee: Double
        let confidence: Double
        let weightChangeRateKgPerWeek: Double
        let averageDailyIntake: Double
        let daysAnalyzed: Int
        let daysWithData: Int
        let hasMetabolicAdaptation: Bool

        var isHighConfidence: Bool { confidence >= 0.7 }
    }

    /// Calculate adaptive TDEE from historical data
    /// - Parameters:
    ///   - user: User for context
    ///   - goal: NutritionGoal with initial TDEE estimate
    ///   - lookbackDays: Number of days to analyze (default 28)
    /// - Returns: AdaptiveTDEEResult with calculated values
    /// - Throws: TDEEServiceError if insufficient data
    func calculateAdaptiveTDEE(
        for user: User,
        goal: NutritionGoal,
        lookbackDays: Int = 28
    ) async throws -> AdaptiveTDEEResult {
        let (startDate, endDate) = getDateRange(lookbackDays: lookbackDays)

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

        logger.info(
            "Adaptive TDEE: \(Int(tdee)) kcal, confidence: \(Int(confidence * 100))%"
        )

        return AdaptiveTDEEResult(
            tdee: tdee,
            confidence: confidence,
            weightChangeRateKgPerWeek: changeRate,
            averageDailyIntake: averageDailyIntake,
            daysAnalyzed: lookbackDays,
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

        logger.info("Goal updated with adaptive TDEE: \(Int(result.tdee)) kcal/day")
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

    // MARK: - Private Helpers

    private func getDateRange(lookbackDays: Int) -> (start: Date, end: Date) {
        let endDate = Date()
        guard
            let startDate = Calendar.current.date(
                byAdding: .day, value: -lookbackDays, to: endDate
            )
        else {
            return (endDate, endDate)
        }
        return (startDate, endDate)
    }

    private func getWeightTrendData(
        from startDate: Date,
        to endDate: Date
    ) async throws -> (smoothed: [(date: Date, smoothedWeight: Double)], changeRate: Double) {
        let weightService = WeightService(context: context)
        let weightEntries = try await weightService.getEntries(from: startDate, to: endDate)

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
        } catch {
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
        let averageDailyIntake = totalCalories / Double(lookbackDays)

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
        } catch {
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

// MARK: - Errors

extension TDEEService {

    enum TDEEServiceError: LocalizedError {
        case missingUserData(String)
        case noWeightData
        case insufficientWeightData(required: Int, actual: Int)
        case insufficientFoodData(consistency: Double)
        case cannotDetermineWeightTrend
        case calculationFailed

        var errorDescription: String? {
            switch self {
            case .missingUserData(let field):
                return "Please add your \(field) in Settings to calculate TDEE."
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
            }
        }
    }
}
