//
//  WeeklyCheckInService.swift
//  JabTracker
//
//  Service for weekly check-in logic and program optimization.
//  Uses adaptive TDEE calculations from real user data to optimize programs.
//

import Foundation
import OSLog
import SwiftData

// MARK: - ProgramOptimizationResult

/// Result of program optimization calculation
struct ProgramOptimizationResult {
    let periodStart: Date
    let periodEnd: Date

    // Current vs Proposed TDEE
    let currentTDEE: Double
    let proposedTDEE: Double?  // nil if insufficient data
    let tdeeConfidence: Double  // 0-1 from adaptive calculation

    // Data quality for progressive accuracy
    let dataQuality: DataQualityAssessment

    // Weight analysis
    let actualWeightChangeKg: Double?
    let goalWeightChangeKg: Double  // From goal pace
    let isOnTrack: Bool

    // Proposed new targets (nil if no change recommended)
    let proposedDailyCalories: Double?
    let proposedWeeklyMacros: WeeklyMacroDistribution?

    // Explanation
    let changeDescription: String
    let whatNextDescription: String

    /// Whether there are actionable changes to apply
    var hasChanges: Bool {
        proposedTDEE != nil && proposedTDEE != currentTDEE
    }

    /// Whether the result has high enough confidence for strong recommendations
    var isHighConfidence: Bool {
        dataQuality.quality == .excellent || dataQuality.quality == .good
    }
}

// MARK: - WeeklyCheckInServiceError

/// Errors from weekly check-in operations
enum WeeklyCheckInServiceError: LocalizedError {
    case goalNotActive
    case noProgramFound
    case contextSaveError(Error)

    var errorDescription: String? {
        switch self {
        case .goalNotActive:
            return "Goal is not active"
        case .noProgramFound:
            return "No program found for goal"
        case .contextSaveError(let error):
            return "Failed to save: \(error.localizedDescription)"
        }
    }
}

// MARK: - WeeklyCheckInService

/// Service for weekly check-in logic and program optimization.
///
/// Determines when check-ins are due, generates optimization recommendations
/// based on real user data, and applies accepted changes.
@MainActor
@Observable
final class WeeklyCheckInService {

    // MARK: - Properties

    private let context: ModelContext
    private let tdeeService: TDEEService
    private let metricsService: MetricsService
    private let mealLogService: MealLogService

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "WeeklyCheckInService"
    )

    /// Minimum days since last check-in before a new one is due
    private let checkInIntervalDays = 7

    /// Tolerance for being "on track" (kg/week difference from goal)
    private let onTrackToleranceKgPerWeek = 0.1

    // MARK: - Initialization

    init(context: ModelContext) {
        self.context = context
        self.tdeeService = TDEEService(context: context)
        self.metricsService = MetricsService(context: context)
        self.mealLogService = MealLogService(context: context)
    }

    // MARK: - Check-In Due Logic

    /// Check if check-in is due for this goal
    ///
    /// Returns false for Manual programs (they manage their own adjustments).
    /// Returns true if:
    /// - It's the configured check-in day of week
    /// - At least 7 days have passed since last check-in (or never checked in)
    ///
    /// - Parameters:
    ///   - goal: The nutrition goal to check
    ///   - date: The date to check against (defaults to today)
    /// - Returns: True if check-in is due
    func isCheckInDue(for goal: NutritionGoal, on date: Date = Date()) -> Bool {
        // Manual programs skip check-ins entirely
        guard goal.program?.style != .manual else {
            Self.logger.debug("Manual program - check-in not applicable")
            return false
        }

        // Get the day of week for the given date
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)

        // Check if it's the configured check-in day
        guard currentWeekday == goal.checkInDayOfWeek else {
            Self.logger.debug("Not check-in day: current=\(currentWeekday), configured=\(goal.checkInDayOfWeek)")
            return false
        }

        // Check if enough time has passed since last check-in
        let referenceDate = goal.lastCheckInDate ?? goal.createdAt
        let daysSinceReference = calendar.dateComponents([.day], from: referenceDate, to: date).day ?? 0

        let isDue = daysSinceReference >= checkInIntervalDays
        Self.logger.debug("Check-in due: \(isDue) (\(daysSinceReference) days since reference)")

        return isDue
    }

    /// Calculate days until next check-in
    ///
    /// - Parameter goal: The nutrition goal
    /// - Returns: Days until next check-in (0 if due now)
    func daysUntilCheckIn(for goal: NutritionGoal) -> Int {
        let calendar = Calendar.current
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)
        let checkInDay = goal.checkInDayOfWeek

        // Calculate days until check-in day of week
        var daysUntilDay = (checkInDay - currentWeekday + 7) % 7
        if daysUntilDay == 0 {
            // Same day - check if we've already done check-in this week
            let referenceDate = goal.lastCheckInDate ?? goal.createdAt
            let daysSinceReference = calendar.dateComponents([.day], from: referenceDate, to: today).day ?? 0
            if daysSinceReference < checkInIntervalDays {
                daysUntilDay = 7  // Next week
            }
        }

        return daysUntilDay
    }

    // MARK: - Data Quality Check

    /// Check data quality before attempting check-in
    /// - Returns: DataQualityAssessment for UI display
    func assessDataQuality() async -> DataQualityAssessment {
        await tdeeService.assessDataQuality()
    }

    /// Check if there's enough data to perform a check-in
    /// - Returns: True if data quality is at least minimum
    func canPerformCheckIn() async -> Bool {
        let assessment = await assessDataQuality()
        return assessment.quality.allowsCheckIn
    }

    // MARK: - Generate Optimization

    /// Generate optimized program based on real user data.
    ///
    /// Uses adaptive TDEE calculation from weight trends + food logs.
    /// Returns with data quality tier - always provides results if minimum data exists.
    ///
    /// - Parameter goal: The nutrition goal to optimize
    /// - Returns: ProgramOptimizationResult with analysis and recommendations
    func generateOptimization(for goal: NutritionGoal) async throws -> ProgramOptimizationResult {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -28, to: endDate) else {
            let emptyAssessment = DataQualityAssessment(
                quality: .insufficient,
                weightEntryCount: 0,
                foodConsistency: 0,
                daySpan: 0,
                improvementTips: ["Unable to calculate date range"]
            )
            return createInsufficientDataResult(goal: goal, dataQuality: emptyAssessment)
        }

        let currentTDEE = goal.lastCalculatedTDEE ?? goal.initialEstimatedTDEE ?? 2000

        // Try to get adaptive TDEE
        do {
            let adaptiveResult = try await tdeeService.calculateAdaptiveTDEE(goal: goal)
            let dataQuality = adaptiveResult.dataQuality

            // Calculate weight change
            let actualWeightChangeKg = try await calculateActualWeightChange(from: startDate, to: endDate)
            let goalWeightChangeKg = goal.weeklyWeightChangePaceKg * 4  // 4 weeks

            // Check if on track
            let weeklyActual = (actualWeightChangeKg ?? 0) / 4.0
            let weeklyGoal = goal.weeklyWeightChangePaceKg
            let isOnTrack = abs(weeklyActual - weeklyGoal) <= onTrackToleranceKgPerWeek

            // Generate descriptions based on data quality
            let qualityPrefix =
                dataQuality.quality == .minimum
                ? "Based on limited data: "
                : ""

            if isOnTrack {
                return ProgramOptimizationResult(
                    periodStart: startDate,
                    periodEnd: endDate,
                    currentTDEE: currentTDEE,
                    proposedTDEE: nil,
                    tdeeConfidence: adaptiveResult.confidence,
                    dataQuality: dataQuality,
                    actualWeightChangeKg: actualWeightChangeKg,
                    goalWeightChangeKg: goalWeightChangeKg,
                    isOnTrack: true,
                    proposedDailyCalories: nil,
                    proposedWeeklyMacros: nil,
                    changeDescription: "\(qualityPrefix)You're on track! Your weight is changing at the expected pace.",
                    whatNextDescription: generateWhatNextDescription(dataQuality: dataQuality, isOnTrack: true)
                )
            }

            // Calculate new targets
            let proposedCalories = calculateProposedCalories(
                tdee: adaptiveResult.tdee,
                weeklyPaceKg: goal.weeklyWeightChangePaceKg,
                calorieFloor: goal.program?.calorieFloor.minimumCalories ?? 1200
            )

            let proposedMacros = calculateProposedMacros(
                calories: proposedCalories,
                program: goal.program,
                weightKg: goal.startingWeightKg
            )

            let changeDescription =
                qualityPrefix
                + generateChangeDescription(
                    currentTDEE: currentTDEE,
                    proposedTDEE: adaptiveResult.tdee,
                    isOnTrack: isOnTrack,
                    actualWeightChangeKg: actualWeightChangeKg,
                    goalWeightChangeKg: goalWeightChangeKg
                )

            return ProgramOptimizationResult(
                periodStart: startDate,
                periodEnd: endDate,
                currentTDEE: currentTDEE,
                proposedTDEE: adaptiveResult.tdee,
                tdeeConfidence: adaptiveResult.confidence,
                dataQuality: dataQuality,
                actualWeightChangeKg: actualWeightChangeKg,
                goalWeightChangeKg: goalWeightChangeKg,
                isOnTrack: isOnTrack,
                proposedDailyCalories: proposedCalories,
                proposedWeeklyMacros: proposedMacros,
                changeDescription: changeDescription,
                whatNextDescription: generateWhatNextDescription(dataQuality: dataQuality, isOnTrack: false)
            )
        } catch let error as TDEEServiceError {
            // Handle insufficient data with quality assessment
            if let assessment = error.dataQualityAssessment {
                Self.logger.info("Check-in blocked due to insufficient data: \(assessment.quality.displayName)")
                return createInsufficientDataResult(goal: goal, dataQuality: assessment)
            }
            Self.logger.warning("Adaptive TDEE calculation failed: \(error.localizedDescription)")
            let fallbackAssessment = await tdeeService.assessDataQuality()
            return createInsufficientDataResult(goal: goal, dataQuality: fallbackAssessment)
        } catch {
            Self.logger.warning("Adaptive TDEE calculation failed: \(error.localizedDescription)")
            let fallbackAssessment = await tdeeService.assessDataQuality()
            return createInsufficientDataResult(goal: goal, dataQuality: fallbackAssessment)
        }
    }

    /// Generate "what's next" description based on data quality
    private func generateWhatNextDescription(dataQuality: DataQualityAssessment, isOnTrack: Bool) -> String {
        var description =
            isOnTrack
            ? "Keep doing what you're doing. "
            : "Accept these changes to adjust your targets, or decline to keep current values. "

        // Add improvement tip if not excellent
        if let tip = dataQuality.improvementTips.first, dataQuality.quality != .excellent {
            description += tip
        }

        return description
    }

    // MARK: - Apply Optimization

    /// Apply accepted optimization to goal/program
    ///
    /// Updates the goal's TDEE, calorie targets, and macro distribution.
    /// Also updates lastCheckInDate.
    ///
    /// - Parameters:
    ///   - result: The optimization result to apply
    ///   - goal: The goal to update
    func applyOptimization(_ result: ProgramOptimizationResult, to goal: NutritionGoal) throws {
        guard result.hasChanges else { return }

        // Update TDEE
        if let proposedTDEE = result.proposedTDEE {
            goal.lastCalculatedTDEE = proposedTDEE
            goal.lastTDEECalculationDate = Date()
        }

        // Update calorie target
        if let proposedCalories = result.proposedDailyCalories {
            goal.dailyCalorieTarget = proposedCalories
        }

        // Update macros
        if let proposedMacros = result.proposedWeeklyMacros {
            goal.dailyProteinTargetGrams = proposedMacros.defaultMacros.proteinGrams
            goal.dailyFatTargetGrams = proposedMacros.defaultMacros.fatGrams
            goal.dailyCarbTargetGrams = proposedMacros.defaultMacros.carbsGrams

            // Also update program's weekly macros if it uses per-day distribution
            goal.program?.setWeeklyMacros(proposedMacros)
        }

        // Mark check-in complete
        goal.lastCheckInDate = Date()
        goal.updatedAt = Date()

        do {
            try context.save()
            let tdee = result.proposedTDEE ?? 0
            let calories = result.proposedDailyCalories ?? 0
            Self.logger.info("Applied optimization - TDEE: \(tdee), Calories: \(calories)")

            // Notify ContentView to refresh badge
            NotificationCenter.default.post(name: .checkInCompleted, object: nil)
        } catch {
            throw WeeklyCheckInServiceError.contextSaveError(error)
        }
    }

    /// Mark check-in complete without applying changes (decline)
    ///
    /// Updates lastCheckInDate but keeps current targets.
    ///
    /// - Parameter goal: The goal to update
    func declineOptimization(for goal: NutritionGoal) throws {
        goal.lastCheckInDate = Date()
        goal.updatedAt = Date()

        do {
            try context.save()
            Self.logger.info("Declined optimization - keeping current targets")

            // Notify ContentView to refresh badge
            NotificationCenter.default.post(name: .checkInCompleted, object: nil)
        } catch {
            throw WeeklyCheckInServiceError.contextSaveError(error)
        }
    }

    // MARK: - Private Helpers

    private func createInsufficientDataResult(
        goal: NutritionGoal,
        dataQuality: DataQualityAssessment
    ) -> ProgramOptimizationResult {
        let currentTDEE = goal.lastCalculatedTDEE ?? goal.initialEstimatedTDEE ?? 2000
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -28, to: endDate) ?? endDate

        // Build description from improvement tips
        let changeDescription: String
        if dataQuality.improvementTips.isEmpty {
            changeDescription = "Not enough data to analyze your progress yet."
        } else {
            changeDescription = "To unlock check-in:\n• " + dataQuality.improvementTips.joined(separator: "\n• ")
        }

        return ProgramOptimizationResult(
            periodStart: startDate,
            periodEnd: endDate,
            currentTDEE: currentTDEE,
            proposedTDEE: nil,
            tdeeConfidence: 0,
            dataQuality: dataQuality,
            actualWeightChangeKg: nil,
            goalWeightChangeKg: goal.weeklyWeightChangePaceKg * 4,
            isOnTrack: false,
            proposedDailyCalories: nil,
            proposedWeeklyMacros: nil,
            changeDescription: changeDescription,
            whatNextDescription: dataQuality.nextTierRequirements
                ?? "Log your weight and food consistently to get personalized recommendations."
        )
    }

    private func calculateActualWeightChange(from startDate: Date, to endDate: Date) async throws -> Double? {
        let entries = try await metricsService.getWeightEntries(from: startDate, to: endDate)
        guard entries.count >= 2 else { return nil }

        let sorted = entries.sorted { $0.timestamp < $1.timestamp }
        guard let first = sorted.first, let last = sorted.last else { return nil }

        return last.weightKg - first.weightKg
    }

    private func calculateProposedCalories(tdee: Double, weeklyPaceKg: Double, calorieFloor: Double) -> Double {
        // 1 kg fat = ~7700 kcal
        let dailyAdjustment = weeklyPaceKg * 7700 / 7
        let proposedCalories = tdee + dailyAdjustment
        return max(proposedCalories, calorieFloor)
    }

    private func calculateProposedMacros(
        calories: Double,
        program: NutritionProgram?,
        weightKg: Double
    ) -> WeeklyMacroDistribution {
        let proteinGrams = (program?.protein.gramsPerKg ?? 1.6) * weightKg
        let proteinCalories = proteinGrams * 4

        let remainingCalories = calories - proteinCalories
        let macroSplit = program?.diet.macroPercentages ?? DietPreference.balanced.macroPercentages
        let fatPercent = macroSplit.fat / (macroSplit.fat + macroSplit.carbs)
        let carbPercent = macroSplit.carbs / (macroSplit.fat + macroSplit.carbs)

        let fatGrams = (remainingCalories * fatPercent) / 9
        let carbsGrams = (remainingCalories * carbPercent) / 4

        let dailyMacros = DailyMacros(
            calories: calories,
            proteinGrams: proteinGrams,
            fatGrams: fatGrams,
            carbsGrams: carbsGrams
        )

        return WeeklyMacroDistribution.even(macros: dailyMacros)
    }

    private func generateChangeDescription(
        currentTDEE: Double,
        proposedTDEE: Double,
        isOnTrack: Bool,
        actualWeightChangeKg: Double?,
        goalWeightChangeKg: Double
    ) -> String {
        let tdeeDiff = proposedTDEE - currentTDEE
        let tdeeDiffText = tdeeDiff > 0 ? "+\(Int(tdeeDiff))" : "\(Int(tdeeDiff))"

        if let actual = actualWeightChangeKg {
            let actualWeekly = actual / 4.0
            let goalWeekly = goalWeightChangeKg / 4.0
            let diff = actualWeekly - goalWeekly

            if diff < -0.1 {
                return "You're losing weight faster than planned. "
                    + "Your TDEE is \(tdeeDiffText) calories from estimate. "
                    + "Adjusting targets to keep you on a healthy pace."
            } else if diff > 0.1 {
                return "Weight loss is slower than planned. " + "Your TDEE is \(tdeeDiffText) calories from estimate. "
                    + "Adjusting targets to get back on track."
            }
        }

        return "Based on your data, your TDEE is \(tdeeDiffText) calories from the estimate. "
            + "Recommending adjusted targets."
    }
}
