//
//  TDEECalculationEngine.swift
//  JabTracker
//
//  Stateless TDEE calculation engine using Mifflin-St Jeor formula.
//

import Foundation
import os

/// Stateless TDEE calculation engine
/// Provides foundational TDEE calculations using Mifflin-St Jeor formula
@MainActor
@Observable
final class TDEECalculationEngine {

    private let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "TDEECalculationEngine"
    )

    init() {}

    // MARK: - BMR Calculation

    /// Calculate Basal Metabolic Rate using Mifflin-St Jeor equation
    /// - Parameters:
    ///   - weightKg: Weight in kilograms
    ///   - heightCm: Height in centimeters
    ///   - age: Age in years
    ///   - gender: Gender string ("male", "m", "female", "f", or other for average)
    /// - Returns: BMR in calories per day
    ///
    /// Formula:
    /// - Men: BMR = (10 x weight kg) + (6.25 x height cm) - (5 x age) + 5
    /// - Women: BMR = (10 x weight kg) + (6.25 x height cm) - (5 x age) - 161
    func calculateBMR(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        gender: String
    ) -> Double {
        let baseBMR = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age))

        switch gender.lowercased() {
        case "male", "m":
            return baseBMR + 5
        case "female", "f":
            return baseBMR - 161
        default:
            // Default to average of both formulas for unknown gender
            // Male adjustment: +5, Female adjustment: -161
            // Average: (5 + (-161)) / 2 = -78
            return baseBMR - 78
        }
    }

    // MARK: - Initial TDEE Calculation

    /// Calculate initial TDEE estimate from BMR and activity level
    /// - Parameters:
    ///   - weightKg: Weight in kilograms
    ///   - heightCm: Height in centimeters
    ///   - age: Age in years
    ///   - gender: Gender string
    ///   - activityMultiplier: Activity multiplier (1.2 sedentary to 1.9 extra active)
    /// - Returns: TDEE in calories per day
    func calculateInitialTDEE(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        gender: String,
        activityMultiplier: Double
    ) -> Double {
        let bmr = calculateBMR(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            gender: gender
        )
        return bmr * activityMultiplier
    }

    /// Calculate initial TDEE using TrainingLevel enum for activity multiplier
    /// - Parameters:
    ///   - weightKg: Weight in kilograms
    ///   - heightCm: Height in centimeters
    ///   - age: Age in years
    ///   - gender: Gender string
    ///   - trainingLevel: Training level enum value
    /// - Returns: TDEE in calories per day
    func calculateInitialTDEE(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        gender: String,
        trainingLevel: TrainingLevel
    ) -> Double {
        calculateInitialTDEE(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            gender: gender,
            activityMultiplier: trainingLevel.tdeeMultiplier
        )
    }
}
