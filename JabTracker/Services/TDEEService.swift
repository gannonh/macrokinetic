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
    private let dayStatusService: DayStatusService?

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
        dayStatusService: DayStatusService? = nil,
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
        self.dayStatusService = dayStatusService
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

        // Save TDEE snapshot for historical tracking
        try saveTDEESnapshot(tdee: tdee, confidence: 1.0, source: .initial)

        Self.logger.debug(
            "Initial TDEE calculated: \(Int(tdee)) kcal/day for training level \(trainingLevel.displayName)"
        )
    }

    // MARK: - Snapshot Methods

    /// Get TDEE snapshots within date range
    /// - Parameters:
    ///   - startDate: Start of date range (inclusive)
    ///   - endDate: End of date range (inclusive)
    /// - Returns: Array of TDEESnapshot sorted by timestamp ascending
    func getTDEESnapshots(from startDate: Date, to endDate: Date) throws -> [TDEESnapshot] {
        let descriptor = FetchDescriptor<TDEESnapshot>(
            predicate: #Predicate { snapshot in
                snapshot.timestamp >= startDate && snapshot.timestamp <= endDate
            },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return try context.fetch(descriptor)
    }
}

// MARK: - Adaptive TDEE

extension TDEEService {

    /// Assess data quality for check-in without attempting full calculation
    /// - Parameter lookbackDays: Number of days to analyze (default uses service's lookbackDays)
    /// - Returns: DataQualityAssessment with tier and improvement tips
    func assessDataQuality(lookbackDays: Int? = nil) async -> DataQualityAssessment {
        let days = lookbackDays ?? self.lookbackDays

        let startDate: Date
        let endDate: Date
        do {
            (startDate, endDate) = try getDateRange(lookbackDays: days)
        } catch {
            Self.logger.error(
                "Failed to calculate date range for data quality assessment: \(error.localizedDescription)")
            return createInsufficientAssessment(weightCount: 0, foodConsistency: 0, daySpan: 0)
        }

        // Get raw data counts with proper error handling
        let weightEntries: [WeightEntry]
        do {
            weightEntries = try await metricsService.getWeightEntries(from: startDate, to: endDate)
        } catch {
            Self.logger.error("Failed to fetch weight entries for quality assessment: \(error.localizedDescription)")
            weightEntries = []
        }

        let foodEntries: [FoodEntry]
        do {
            foodEntries = try await getFoodEntries(from: startDate, to: endDate)
        } catch {
            Self.logger.error("Failed to fetch food entries for quality assessment: \(error.localizedDescription)")
            foodEntries = []
        }

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
    /// - Note: Fasting days are excluded from calorie calculations
    func calculateAdaptiveTDEE(
        goal: NutritionGoal,
        lookbackDays: Int? = nil
    ) async throws -> AdaptiveTDEEResult {
        let days = lookbackDays ?? self.lookbackDays
        let (startDate, endDate) = try getDateRange(lookbackDays: days)

        // Gather data
        let weightEntries = try await metricsService.getWeightEntries(from: startDate, to: endDate)
        let foodEntries = try await getFoodEntries(from: startDate, to: endDate)
        let fastingDates: Set<Date>
        if let service = dayStatusService {
            fastingDates = try service.getFastingDates(from: startDate, to: endDate)
        } else {
            fastingDates = []
        }

        // Calculate metrics excluding fasting days
        let intakeMetrics = calculateIntakeMetrics(
            foodEntries: foodEntries, fastingDates: fastingDates, weightEntries: weightEntries
        )

        // Assess data quality
        let dataQuality = createDataQualityAssessment(
            weightCount: weightEntries.count,
            foodConsistency: intakeMetrics.foodConsistency,
            daySpan: intakeMetrics.daySpan
        )

        guard dataQuality.quality != .insufficient else {
            throw TDEEServiceError.insufficientData(assessment: dataQuality)
        }

        // Calculate weight trend and TDEE
        return try buildAdaptiveResult(
            goal: goal, days: days, weightEntries: weightEntries, intakeMetrics: intakeMetrics, dataQuality: dataQuality
        )
    }

    /// Metrics for intake calculations
    private struct IntakeMetrics {
        let averageDailyIntake: Double
        let uniqueDaysWithFood: Int
        let foodConsistency: Double
        let daySpan: Int
    }

    /// Calculate intake metrics excluding fasting days
    private func calculateIntakeMetrics(
        foodEntries: [FoodEntry], fastingDates: Set<Date>, weightEntries: [WeightEntry]
    ) -> IntakeMetrics {
        let daysWithFood = Set(foodEntries.map { Calendar.current.startOfDay(for: $0.loggedAt) })
        let daysWithFoodExcludingFasting = daysWithFood.subtracting(fastingDates)
        let uniqueDaysWithFood = daysWithFoodExcludingFasting.count

        let daySpan = calculateDaySpan(from: weightEntries)
        let effectiveDaySpan = max(1, daySpan - fastingDates.count)
        let foodConsistency = effectiveDaySpan > 0 ? Double(uniqueDaysWithFood) / Double(effectiveDaySpan) : 0

        let nonFastingEntries = foodEntries.filter { entry in
            !fastingDates.contains(Calendar.current.startOfDay(for: entry.loggedAt))
        }
        let totalCalories = nonFastingEntries.reduce(0.0) { $0 + $1.calories }
        let averageDailyIntake = uniqueDaysWithFood > 0 ? totalCalories / Double(uniqueDaysWithFood) : 0

        if !fastingDates.isEmpty {
            Self.logger.debug("Excluded \(fastingDates.count) fasting days from TDEE calculation")
        }

        return IntakeMetrics(
            averageDailyIntake: averageDailyIntake, uniqueDaysWithFood: uniqueDaysWithFood,
            foodConsistency: foodConsistency, daySpan: daySpan
        )
    }

    /// Calculate day span from weight entries
    private func calculateDaySpan(from weightEntries: [WeightEntry]) -> Int {
        guard let first = weightEntries.min(by: { $0.timestamp < $1.timestamp }),
            let last = weightEntries.max(by: { $0.timestamp < $1.timestamp })
        else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: first.timestamp, to: last.timestamp).day ?? 0)
    }

    /// Build the adaptive result from calculated metrics
    private func buildAdaptiveResult(
        goal: NutritionGoal, days: Int, weightEntries: [WeightEntry],
        intakeMetrics: IntakeMetrics, dataQuality: DataQualityAssessment
    ) throws -> AdaptiveTDEEResult {
        let weights = weightEntries.sorted { $0.timestamp < $1.timestamp }.map { ($0.timestamp, $0.weightKg) }
        let smoothedWeights = try engine.calculateEWMA(weights: weights, alpha: ewmaAlpha)

        let changeRate = (try? engine.calculateWeightChangeRate(smoothedWeights: smoothedWeights)) ?? 0

        guard let firstWeight = smoothedWeights.first?.smoothedWeight,
            let lastWeight = smoothedWeights.last?.smoothedWeight
        else { throw TDEEServiceError.cannotDetermineWeightTrend }

        let weightChangeKg = lastWeight - firstWeight
        let tdee = try engine.calculateAdaptiveTDEE(
            averageDailyIntake: intakeMetrics.averageDailyIntake, weightChangeKg: weightChangeKg, durationDays: days
        )

        let rawConfidence = engine.calculateConfidenceScore(
            durationDays: days, daysWithData: intakeMetrics.uniqueDaysWithFood, weightChangeRateKgPerWeek: changeRate
        )
        let confidence = min(rawConfidence, dataQuality.quality.confidenceCeiling)

        let hasMetabolicAdaptation = engine.detectMetabolicAdaptation(
            actualTDEE: tdee, expectedTDEE: goal.initialEstimatedTDEE ?? tdee
        )

        Self.logger.debug("Adaptive TDEE: \(Int(tdee)) kcal, confidence: \(Int(confidence * 100))%")

        return AdaptiveTDEEResult(
            tdee: tdee, confidence: confidence, weightChangeRateKgPerWeek: changeRate,
            averageDailyIntake: intakeMetrics.averageDailyIntake, daysWithData: intakeMetrics.uniqueDaysWithFood,
            hasMetabolicAdaptation: hasMetabolicAdaptation, dataQuality: dataQuality
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

        // Save TDEE snapshot for historical tracking
        try saveTDEESnapshot(tdee: result.tdee, confidence: result.confidence, source: .adaptive)

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
        let dailyCalorieAdjustment = NutritionCalculationService.dailyCalorieAdjustment(
            from: goal.weeklyWeightChangePaceKg
        )
        let dailyCalorieTarget = tdee + dailyCalorieAdjustment

        // Apply calorie floor if configured in program
        let calorieFloor = goal.program?.calorieFloor.minimumCalories ?? 1200.0
        goal.dailyCalorieTarget = max(dailyCalorieTarget, calorieFloor)

        Self.logger.debug(
            "Applied TDEE: \(Int(tdee)), adj=\(Int(dailyCalorieAdjustment)), target=\(Int(goal.dailyCalorieTarget))"
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
    /// - Returns: MacroGrams with protein, fat, carbs in grams
    func calculateMacros(
        calories: Double,
        program: NutritionProgram,
        weightKg: Double
    ) -> MacroGrams {
        // Protein from program's protein level (g per kg body weight)
        let proteinGrams = program.protein.gramsPerKg * weightKg
        let proteinCalories = MacroCalorieConstants.proteinCalories(proteinGrams)

        // Remaining calories for fat and carbs
        let remainingCalories = calories - proteinCalories

        // Use diet preference macro split for remaining calories
        let macroSplit = program.diet.macroPercentages
        let fatPercent = macroSplit.fat / (macroSplit.fat + macroSplit.carbs)
        let carbPercent = macroSplit.carbs / (macroSplit.fat + macroSplit.carbs)

        let fatCalories = remainingCalories * fatPercent
        let carbCalories = remainingCalories * carbPercent

        return MacroGrams(
            protein: proteinGrams,
            fat: fatCalories / MacroCalorieConstants.fatCaloriesPerGram,
            carbs: carbCalories / MacroCalorieConstants.carbsCaloriesPerGram
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

// MARK: - Daily Snapshot Backfill

extension TDEEService {

    // MARK: - Data Sufficiency Check

    /// Check if sufficient data exists to recalculate TDEE as of a specific date
    /// Requires 3+ days of food logging and 1+ day of weight logging in the 7-day window
    /// - Parameter date: The date to check (uses 7-day lookback window ending on this date)
    /// - Returns: True if sufficient data exists for adaptive TDEE calculation
    func hasSufficientData(asOf date: Date) -> Bool {
        let calendar = Calendar.current
        guard let windowStart = calendar.date(byAdding: .day, value: -7, to: date) else {
            return false
        }

        let foodDays = countFoodDays(from: windowStart, to: date)
        let weightDays = countWeightDays(from: windowStart, to: date)

        return foodDays >= 3 && weightDays >= 1
    }

    /// Count unique days with food entries in date range
    private func countFoodDays(from start: Date, to end: Date) -> Int {
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate { entry in
                entry.loggedAt >= start && entry.loggedAt <= end
            }
        )
        do {
            let entries = try context.fetch(descriptor)
            return Set(entries.map { Calendar.current.startOfDay(for: $0.loggedAt) }).count
        } catch {
            Self.logger.error("Failed to fetch food entries for day count: \(error.localizedDescription)")
            return 0
        }
    }

    /// Count unique days with weight entries in date range
    private func countWeightDays(from start: Date, to end: Date) -> Int {
        let descriptor = FetchDescriptor<WeightEntry>(
            predicate: #Predicate { entry in
                entry.timestamp >= start && entry.timestamp <= end
            }
        )
        do {
            let entries = try context.fetch(descriptor)
            return Set(entries.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
        } catch {
            Self.logger.error("Failed to fetch weight entries for day count: \(error.localizedDescription)")
            return 0
        }
    }

    // MARK: - Snapshot Helpers

    /// Get the date of the most recent TDEE snapshot
    /// - Returns: Date of most recent snapshot, or nil if no snapshots exist
    func getLastSnapshotDate() throws -> Date? {
        var descriptor = FetchDescriptor<TDEESnapshot>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.timestamp
    }

    /// Get the TDEE value from the most recent snapshot
    /// - Returns: TDEE value from most recent snapshot, or nil if no snapshots exist
    func getLastTDEEValue() throws -> Double? {
        var descriptor = FetchDescriptor<TDEESnapshot>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.tdeeValue
    }

    /// Get the confidence from the most recent snapshot
    /// - Returns: Confidence value from most recent snapshot, or nil if no snapshots exist
    func getLastConfidence() throws -> Double? {
        var descriptor = FetchDescriptor<TDEESnapshot>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.confidence
    }

    // MARK: - Backfill

    /// Ensure daily TDEE snapshots exist from last snapshot to today
    /// Creates "holding" snapshots when data is insufficient, "adaptive" when sufficient
    /// - Parameter goal: The NutritionGoal to use for backfill calculations
    func ensureDailySnapshots(for goal: NutritionGoal) async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get last snapshot date (or goal creation date)
        let lastSnapshotDate =
            try getLastSnapshotDate()
            .map { calendar.startOfDay(for: $0) }
            ?? calendar.startOfDay(for: goal.createdAt)

        // If already up to date, nothing to do
        if lastSnapshotDate >= today {
            Self.logger.debug("TDEE snapshots already up to date")
            return
        }

        // Start from day after last snapshot
        guard var currentDate = calendar.date(byAdding: .day, value: 1, to: lastSnapshotDate) else {
            return
        }

        var lastTDEE = try getLastTDEEValue() ?? goal.initialEstimatedTDEE ?? 2000
        var lastConfidence = try getLastConfidence() ?? 1.0

        Self.logger.debug("Backfilling TDEE snapshots from \(lastSnapshotDate) to \(today)")

        while currentDate <= today {
            if hasSufficientData(asOf: currentDate) {
                // Sufficient data: attempt adaptive calculation
                // For now, we'll use the existing TDEE since historical calculation is complex
                // TODO: Implement calculateTDEEAsOf for true historical calculation
                try saveTDEESnapshot(
                    tdee: lastTDEE,
                    confidence: lastConfidence,
                    source: .adaptive,
                    timestamp: currentDate
                )
                Self.logger.debug("Created adaptive snapshot for \(currentDate)")
            } else {
                // Insufficient: hold previous value with decayed confidence
                let decayedConfidence = max(0.3, lastConfidence * 0.98)
                try saveTDEESnapshot(
                    tdee: lastTDEE,
                    confidence: decayedConfidence,
                    source: .holding,
                    timestamp: currentDate
                )
                lastConfidence = decayedConfidence
                Self.logger.debug("Created holding snapshot for \(currentDate)")
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        Self.logger.info("Completed TDEE snapshot backfill")
    }

    /// Save a TDEE snapshot with custom timestamp
    /// - Parameters:
    ///   - tdee: TDEE value in kcal
    ///   - confidence: Confidence score (0.0-1.0)
    ///   - source: Source type for the calculation
    ///   - timestamp: Timestamp for the snapshot (defaults to now)
    func saveTDEESnapshot(
        tdee: Double,
        confidence: Double,
        source: TDEESourceType,
        timestamp: Date = Date()
    ) throws {
        let snapshot = TDEESnapshot(
            timestamp: timestamp,
            tdeeValue: tdee,
            confidence: confidence,
            source: source
        )
        context.insert(snapshot)
        try context.save()
        Self.logger.debug("Saved TDEE snapshot: \(Int(tdee)) kcal (\(source.rawValue)) at \(timestamp)")
    }
}
