//
//  TDEECalculationEngine+Adaptive.swift
//  JabTracker
//
//  Adaptive TDEE calculation extension with confidence scoring and metabolic adaptation detection.
//

import Foundation
import os

extension TDEECalculationEngine {

    // MARK: - Constants

    /// Calories per kilogram of body weight change (1 lb fat ≈ 3500 kcal, metric conversion)
    private static let caloriesPerKgBodyWeight: Double = 7700

    /// Days at which duration confidence factor reaches maximum (1.0)
    private static let maxConfidenceDurationDays: Double = 28.0

    /// Weight change rate (kg/week) at which trend clarity factor reaches maximum
    private static let maxConfidenceWeightChangeRate: Double = 0.5

    // MARK: - Logging

    private static let adaptiveLogger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "TDEECalculationEngine.Adaptive"
    )

    // MARK: - Adaptive TDEE Calculations

    /// Calculate adaptive TDEE from actual intake and weight change
    ///
    /// The formula accounts for the energy balance equation:
    /// - Weight loss: TDEE > intake, so TDEE = intake + |deficit|
    /// - Weight gain: TDEE < intake, so TDEE = intake - surplus
    /// - Maintenance: TDEE = intake
    ///
    /// Formula: TDEE = Average Daily Intake - (Weight Change * 7700 kcal/kg / Days)
    /// - Parameters:
    ///   - averageDailyIntake: Average calories consumed per day
    ///   - weightChangeKg: Total weight change in kg (negative = loss, positive = gain)
    ///   - durationDays: Number of days in the analysis period
    /// - Returns: Calculated TDEE
    /// - Throws: ValidationError if inputs are invalid
    func calculateAdaptiveTDEE(
        averageDailyIntake: Double,
        weightChangeKg: Double,
        durationDays: Int
    ) throws -> Double {
        try validateAdaptiveTDEEInputs(averageDailyIntake: averageDailyIntake, durationDays: durationDays)

        let caloriesFromWeightChange = weightChangeKg * Self.caloriesPerKgBodyWeight
        let dailyCalorieChange = caloriesFromWeightChange / Double(durationDays)

        // TDEE = intake - (weightChange * 7700 / days)
        // If weightChange is negative (loss), this adds to intake (TDEE > intake)
        // If weightChange is positive (gain), this subtracts from intake (TDEE < intake)
        let tdee = averageDailyIntake - dailyCalorieChange

        Self.adaptiveLogger.debug(
            """
            Adaptive TDEE: intake=\(averageDailyIntake, format: .fixed(precision: 0)), \
            weightΔ=\(weightChangeKg, format: .fixed(precision: 2))kg, \
            days=\(durationDays) → TDEE=\(tdee, format: .fixed(precision: 0))
            """
        )

        if !isReasonableTDEE(tdee) {
            Self.adaptiveLogger.warning(
                "Adaptive TDEE calculation resulted in unreasonable value: \(tdee, format: .fixed(precision: 0)) kcal"
            )
        }

        return tdee
    }

    /// Calculate confidence score for adaptive TDEE (0-1)
    /// Higher confidence with longer duration, better consistency, clearer trend
    func calculateConfidenceScore(
        durationDays: Int,
        daysWithData: Int,
        weightChangeRateKgPerWeek: Double
    ) -> Double {
        // Duration factor (0-1): 14 days = 0.5, 28+ days = 1.0
        let durationFactor = min(Double(durationDays) / Self.maxConfidenceDurationDays, 1.0)

        // Consistency factor (0-1): % of days with logged data
        let consistencyFactor = Double(daysWithData) / Double(max(durationDays, 1))

        // Trend clarity factor (0-1): abs(rate) > 0.5 kg/week = high confidence
        let trendClarityFactor = min(abs(weightChangeRateKgPerWeek) / Self.maxConfidenceWeightChangeRate, 1.0)

        // Weighted average (consistency most important for accuracy)
        let confidence = (durationFactor * 0.3 + consistencyFactor * 0.5 + trendClarityFactor * 0.2)

        return max(0, min(1, confidence))
    }

    /// Detect potential metabolic adaptation
    /// Returns true if actual TDEE is significantly lower than expected
    func detectMetabolicAdaptation(
        actualTDEE: Double,
        expectedTDEE: Double,
        threshold: Double = 0.15
    ) -> Bool {
        guard expectedTDEE > 0 else { return false }
        let reduction = (expectedTDEE - actualTDEE) / expectedTDEE
        return reduction > threshold
    }
}
