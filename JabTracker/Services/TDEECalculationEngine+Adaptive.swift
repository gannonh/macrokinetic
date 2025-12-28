//
//  TDEECalculationEngine+Adaptive.swift
//  JabTracker
//
//  Adaptive TDEE calculation extension with confidence scoring and metabolic adaptation detection.
//

import Foundation

extension TDEECalculationEngine {

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
    /// - Returns: Calculated TDEE, or nil if parameters invalid
    func calculateAdaptiveTDEE(
        averageDailyIntake: Double,
        weightChangeKg: Double,
        durationDays: Int
    ) -> Double? {
        guard durationDays > 0, averageDailyIntake > 0 else { return nil }

        // 1 kg body weight = 7700 calories
        let caloriesFromWeightChange = weightChangeKg * 7700
        let dailyCalorieChange = caloriesFromWeightChange / Double(durationDays)

        // TDEE = intake - (weightChange * 7700 / days)
        // If weightChange is negative (loss), this adds to intake (TDEE > intake)
        // If weightChange is positive (gain), this subtracts from intake (TDEE < intake)
        let tdee = averageDailyIntake - dailyCalorieChange

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
        let durationFactor = min(Double(durationDays) / 28.0, 1.0)

        // Consistency factor (0-1): % of days with logged data
        let consistencyFactor = Double(daysWithData) / Double(max(durationDays, 1))

        // Trend clarity factor (0-1): abs(rate) > 0.5 kg/week = high confidence
        let trendClarityFactor = min(abs(weightChangeRateKgPerWeek) / 0.5, 1.0)

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
