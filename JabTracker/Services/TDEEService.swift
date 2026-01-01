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

// MARK: - Data Quality Types

/// Data quality tier for progressive accuracy
enum DataQuality: String, Codable, CaseIterable {
    case insufficient
    case minimum
    case good
    case excellent

    var displayName: String {
        switch self {
        case .insufficient: return "Insufficient"
        case .minimum: return "Limited"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }

    /// Maximum confidence score for this tier
    var confidenceCeiling: Double {
        switch self {
        case .insufficient: return 0.0
        case .minimum: return 0.5
        case .good: return 0.7
        case .excellent: return 1.0
        }
    }

    /// Whether check-in is available at this tier
    var allowsCheckIn: Bool {
        self != .insufficient
    }

    /// Color name for UI indicator
    var indicatorColor: String {
        switch self {
        case .insufficient: return "gray"
        case .minimum: return "yellow"
        case .good: return "blue"
        case .excellent: return "green"
        }
    }

    /// SF Symbol for UI
    var iconName: String {
        switch self {
        case .insufficient: return "exclamationmark.circle"
        case .minimum: return "exclamationmark.triangle"
        case .good: return "checkmark.circle"
        case .excellent: return "checkmark.seal.fill"
        }
    }
}

/// Assessment of current data quality with improvement tips
struct DataQualityAssessment {
    let quality: DataQuality
    let weightEntryCount: Int
    let foodConsistency: Double
    let daySpan: Int
    let improvementTips: [String]

    /// What the user needs to reach the next tier
    var nextTierRequirements: String? {
        switch quality {
        case .insufficient:
            return "Log weight 3+ times and track meals on 50%+ of days"
        case .minimum:
            return "Log weight daily and track meals on 60%+ of days"
        case .good:
            return "Continue for 2 more weeks with 75%+ meal tracking"
        case .excellent:
            return nil  // Already at max
        }
    }
}

// MARK: - Types

/// Result of adaptive TDEE calculation
struct AdaptiveTDEEResult {
    let tdee: Double
    let confidence: Double
    let weightChangeRateKgPerWeek: Double
    let averageDailyIntake: Double
    let daysWithData: Int
    let hasMetabolicAdaptation: Bool
    let dataQuality: DataQualityAssessment

    var isHighConfidence: Bool { confidence >= 0.7 }
}

/// Errors that can occur during TDEE calculation
enum TDEEServiceError: LocalizedError {
    case missingUserData(String)
    case invalidUserData(String)
    case noWeightData
    case insufficientData(assessment: DataQualityAssessment)
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
        case .insufficientData(let assessment):
            return assessment.nextTierRequirements ?? "Need more tracking data."
        case .cannotDetermineWeightTrend:
            return "Cannot determine weight trend from available data."
        case .calculationFailed:
            return "TDEE calculation failed. Please check your data."
        case .dateCalculationFailed:
            return "Unable to calculate date range. Please try again."
        }
    }

    /// Get the data quality assessment if this is an insufficient data error
    var dataQualityAssessment: DataQualityAssessment? {
        if case .insufficientData(let assessment) = self {
            return assessment
        }
        return nil
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

    // Tiered thresholds for progressive accuracy
    let absoluteMinimumWeightEntries: Int
    let absoluteMinimumFoodConsistency: Double
    let absoluteMinimumDaySpan: Int
    let optimalWeightEntries: Int
    let optimalFoodConsistency: Double
    let lookbackDays: Int

    // MARK: - Initialization

    init(
        context: ModelContext,
        engine: TDEECalculationEngine = TDEECalculationEngine(),
        metricsService: MetricsService? = nil,
        ewmaAlpha: Double = 0.2,
        absoluteMinimumWeightEntries: Int = 3,
        absoluteMinimumFoodConsistency: Double = 0.5,
        absoluteMinimumDaySpan: Int = 7,
        optimalWeightEntries: Int = 14,
        optimalFoodConsistency: Double = 0.75,
        lookbackDays: Int = 28
    ) {
        self.context = context
        self.engine = engine
        self.metricsService = metricsService ?? MetricsService(context: context)
        self.ewmaAlpha = ewmaAlpha
        self.absoluteMinimumWeightEntries = absoluteMinimumWeightEntries
        self.absoluteMinimumFoodConsistency = absoluteMinimumFoodConsistency
        self.absoluteMinimumDaySpan = absoluteMinimumDaySpan
        self.optimalWeightEntries = optimalWeightEntries
        self.optimalFoodConsistency = optimalFoodConsistency
        self.lookbackDays = lookbackDays
    }

    // MARK: - Initial TDEE

    /// Calculate initial TDEE estimate and save to NutritionGoal
    /// - Parameters:
    ///   - user: User with profile data (height, gender, dateOfBirth)
    ///   - goal: NutritionGoal to update
    ///   - trainingLevelOverride: Optional training level to use instead of program's value.
    ///     Use this when program doesn't exist yet (e.g., during Collaborative setup).
    /// - Throws: TDEEServiceError if required data is missing or invalid
    func calculateInitialTDEE(
        for user: User,
        goal: NutritionGoal,
        trainingLevelOverride: TrainingLevel? = nil
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

        // Get training level from override, program, or default to lifting (moderate activity)
        // Default to .lifting instead of .none because most users setting nutrition goals
        // have at least moderate activity levels
        let trainingLevel = trainingLevelOverride ?? goal.program?.training ?? .lifting

        // Get current weight from MetricsService (reads from HealthKit if enabled)
        guard let latestWeight = try await metricsService.getLatestWeightEntry() else {
            throw TDEEServiceError.noWeightData
        }

        // Calculate initial TDEE (validates inputs internally)
        let tdee = try engine.calculateInitialTDEE(
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

    /// Assess data quality for check-in without attempting full calculation
    /// - Parameter lookbackDays: Number of days to analyze (default uses service's lookbackDays)
    /// - Returns: DataQualityAssessment with tier and improvement tips
    func assessDataQuality(lookbackDays: Int? = nil) async -> DataQualityAssessment {
        let days = lookbackDays ?? self.lookbackDays
        guard let (startDate, endDate) = try? getDateRange(lookbackDays: days) else {
            return createInsufficientAssessment(weightCount: 0, foodConsistency: 0, daySpan: 0)
        }

        // Get raw data counts
        let weightEntries = (try? await metricsService.getWeightEntries(from: startDate, to: endDate)) ?? []
        let foodEntries = (try? await getFoodEntries(from: startDate, to: endDate)) ?? []

        let weightCount = weightEntries.count
        let uniqueDaysWithFood = Set(foodEntries.map { Calendar.current.startOfDay(for: $0.loggedAt) }).count

        // Calculate actual day span from weight entries
        let daySpan: Int
        if let first = weightEntries.min(by: { $0.timestamp < $1.timestamp }),
            let last = weightEntries.max(by: { $0.timestamp < $1.timestamp })
        {
            daySpan = max(
                1, Calendar.current.dateComponents([.day], from: first.timestamp, to: last.timestamp).day ?? 0)
        } else {
            daySpan = 0
        }

        // Calculate food consistency based on actual tracking span, not full lookback window
        // This ensures users with shorter data spans are fairly assessed
        let foodConsistency = daySpan > 0 ? Double(uniqueDaysWithFood) / Double(daySpan) : 0

        return createDataQualityAssessment(
            weightCount: weightCount,
            foodConsistency: foodConsistency,
            daySpan: daySpan
        )
    }

    /// Calculate adaptive TDEE from historical data with progressive accuracy
    /// - Parameters:
    ///   - goal: NutritionGoal with initial TDEE estimate
    ///   - lookbackDays: Number of days to analyze (default uses service's lookbackDays)
    /// - Returns: AdaptiveTDEEResult with calculated values and data quality
    /// - Throws: TDEEServiceError only for truly unrecoverable errors (not data thresholds)
    func calculateAdaptiveTDEE(
        goal: NutritionGoal,
        lookbackDays: Int? = nil
    ) async throws -> AdaptiveTDEEResult {
        let days = lookbackDays ?? self.lookbackDays
        let (startDate, endDate) = try getDateRange(lookbackDays: days)

        // Get weight data (without throwing for threshold)
        let weightEntries = try await metricsService.getWeightEntries(from: startDate, to: endDate)

        // Get food data
        let foodEntries = try await getFoodEntries(from: startDate, to: endDate)
        let uniqueDaysWithFood = Set(foodEntries.map { Calendar.current.startOfDay(for: $0.loggedAt) }).count

        // Calculate day span first (needed for food consistency)
        let daySpan: Int
        if let first = weightEntries.min(by: { $0.timestamp < $1.timestamp }),
            let last = weightEntries.max(by: { $0.timestamp < $1.timestamp })
        {
            daySpan = max(
                1, Calendar.current.dateComponents([.day], from: first.timestamp, to: last.timestamp).day ?? 0)
        } else {
            daySpan = 0
        }

        // Calculate food consistency based on actual tracking span, not full lookback window
        let foodConsistency = daySpan > 0 ? Double(uniqueDaysWithFood) / Double(daySpan) : 0

        // Assess data quality
        let dataQuality = createDataQualityAssessment(
            weightCount: weightEntries.count,
            foodConsistency: foodConsistency,
            daySpan: daySpan
        )

        // If insufficient, throw with helpful message
        guard dataQuality.quality != .insufficient else {
            throw TDEEServiceError.insufficientData(assessment: dataQuality)
        }

        // Calculate weight trend (may still throw if data is corrupted)
        let weights = weightEntries.sorted { $0.timestamp < $1.timestamp }.map { ($0.timestamp, $0.weightKg) }
        let smoothedWeights = try engine.calculateEWMA(weights: weights, alpha: ewmaAlpha)

        let changeRate: Double
        do {
            changeRate = try engine.calculateWeightChangeRate(smoothedWeights: smoothedWeights)
        } catch {
            // If we can't determine trend, use 0 (maintenance assumption)
            Self.logger.warning("Could not determine weight trend, assuming maintenance")
            changeRate = 0
        }

        // Calculate average intake
        let totalCalories = foodEntries.reduce(0.0) { $0 + $1.calories }
        let averageDailyIntake = uniqueDaysWithFood > 0 ? totalCalories / Double(uniqueDaysWithFood) : 0

        // Calculate TDEE
        guard let firstWeight = smoothedWeights.first?.smoothedWeight,
            let lastWeight = smoothedWeights.last?.smoothedWeight
        else {
            throw TDEEServiceError.cannotDetermineWeightTrend
        }

        let weightChangeKg = lastWeight - firstWeight
        let tdee = try engine.calculateAdaptiveTDEE(
            averageDailyIntake: averageDailyIntake,
            weightChangeKg: weightChangeKg,
            durationDays: days
        )

        // Calculate raw confidence, then cap by tier
        let rawConfidence = engine.calculateConfidenceScore(
            durationDays: days,
            daysWithData: uniqueDaysWithFood,
            weightChangeRateKgPerWeek: changeRate
        )
        let confidence = min(rawConfidence, dataQuality.quality.confidenceCeiling)

        let expectedTDEE = goal.initialEstimatedTDEE ?? tdee
        let hasMetabolicAdaptation = engine.detectMetabolicAdaptation(
            actualTDEE: tdee,
            expectedTDEE: expectedTDEE
        )

        Self.logger.debug(
            """
            Adaptive TDEE: \(Int(tdee)) kcal, confidence: \(Int(confidence * 100))%, \
            quality: \(dataQuality.quality.displayName)
            """
        )

        return AdaptiveTDEEResult(
            tdee: tdee,
            confidence: confidence,
            weightChangeRateKgPerWeek: changeRate,
            averageDailyIntake: averageDailyIntake,
            daysWithData: uniqueDaysWithFood,
            hasMetabolicAdaptation: hasMetabolicAdaptation,
            dataQuality: dataQuality
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

    // MARK: - Data Quality Assessment

    /// Determine data quality tier based on thresholds
    private func createDataQualityAssessment(
        weightCount: Int,
        foodConsistency: Double,
        daySpan: Int
    ) -> DataQualityAssessment {
        let quality = determineDataQualityTier(
            weightCount: weightCount,
            foodConsistency: foodConsistency,
            daySpan: daySpan
        )

        let tips = generateImprovementTips(
            quality: quality,
            weightCount: weightCount,
            foodConsistency: foodConsistency,
            daySpan: daySpan
        )

        return DataQualityAssessment(
            quality: quality,
            weightEntryCount: weightCount,
            foodConsistency: foodConsistency,
            daySpan: daySpan,
            improvementTips: tips
        )
    }

    /// Convenience for creating insufficient assessment
    private func createInsufficientAssessment(
        weightCount: Int,
        foodConsistency: Double,
        daySpan: Int
    ) -> DataQualityAssessment {
        let tips = generateImprovementTips(
            quality: .insufficient,
            weightCount: weightCount,
            foodConsistency: foodConsistency,
            daySpan: daySpan
        )

        return DataQualityAssessment(
            quality: .insufficient,
            weightEntryCount: weightCount,
            foodConsistency: foodConsistency,
            daySpan: daySpan,
            improvementTips: tips
        )
    }

    /// Determine which quality tier the data falls into
    private func determineDataQualityTier(
        weightCount: Int,
        foodConsistency: Double,
        daySpan: Int
    ) -> DataQuality {
        // Must meet ALL minimum thresholds to proceed
        guard weightCount >= absoluteMinimumWeightEntries,
            foodConsistency >= absoluteMinimumFoodConsistency,
            daySpan >= absoluteMinimumDaySpan
        else {
            return .insufficient
        }

        // Excellent: optimal weight + optimal food + 14+ days
        if weightCount >= optimalWeightEntries && foodConsistency >= optimalFoodConsistency && daySpan >= 14 {
            return .excellent
        }

        // Good: 7+ weights OR 60%+ food consistency
        if weightCount >= 7 || foodConsistency >= 0.6 {
            return .good
        }

        // Minimum: meets absolute minimums but not good
        return .minimum
    }

    /// Generate improvement tips based on current state
    private func generateImprovementTips(
        quality: DataQuality,
        weightCount: Int,
        foodConsistency: Double,
        daySpan: Int
    ) -> [String] {
        var tips: [String] = []

        switch quality {
        case .insufficient:
            if weightCount < absoluteMinimumWeightEntries {
                let needed = absoluteMinimumWeightEntries - weightCount
                tips.append("Log your weight \(needed) more time\(needed == 1 ? "" : "s")")
            }
            if foodConsistency < absoluteMinimumFoodConsistency {
                let percentNeeded = Int((absoluteMinimumFoodConsistency - foodConsistency) * 100)
                tips.append("Track meals \(percentNeeded)% more consistently")
            }
            if daySpan < absoluteMinimumDaySpan {
                let daysNeeded = absoluteMinimumDaySpan - daySpan
                tips.append("Continue tracking for \(daysNeeded) more day\(daysNeeded == 1 ? "" : "s")")
            }

        case .minimum:
            tips.append("Log weight daily for better accuracy")
            if foodConsistency < 0.6 {
                tips.append("Track meals on more days to improve results")
            }

        case .good:
            if weightCount < optimalWeightEntries {
                tips.append("Keep tracking - \(optimalWeightEntries - weightCount) more days for best accuracy")
            }
            if foodConsistency < optimalFoodConsistency {
                let percentNeeded = Int((optimalFoodConsistency - foodConsistency) * 100)
                tips.append("Increase meal tracking by \(percentNeeded)% for optimal results")
            }

        case .excellent:
            tips.append("Great job! Your data quality is excellent")
        }

        return tips
    }

    // MARK: - Data Fetching

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
    /// - Returns: True if targets were applied, false if TDEE was missing
    /// - Note: Enforces minimum calorie floor from program settings (default: 1200 kcal)
    @discardableResult
    func applyTDEEToGoal(_ goal: NutritionGoal) -> Bool {
        guard let tdee = goal.initialEstimatedTDEE else {
            Self.logger.warning("applyTDEEToGoal called but initialEstimatedTDEE is nil - calorie targets not updated")
            return false
        }

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
        return true
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
    ///   - trainingLevelOverride: Optional training level to use instead of program's value.
    ///     Use this when program doesn't exist yet (e.g., during Collaborative setup).
    func calculateAndApplyFullTDEE(
        for user: User,
        goal: NutritionGoal,
        trainingLevelOverride: TrainingLevel? = nil
    ) async throws {
        // Calculate initial TDEE
        try await calculateInitialTDEE(for: user, goal: goal, trainingLevelOverride: trainingLevelOverride)

        // Apply TDEE to get calorie target
        applyTDEEToGoal(goal)

        // Calculate and apply macros
        calculateAndApplyMacros(for: goal)

        try context.save()

        Self.logger.debug("Full TDEE calculation complete for goal")
    }
}
