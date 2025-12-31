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
///
/// Note: This class is intentionally not @Observable as it has no published state.
/// It is a pure calculation engine used by @MainActor services like TDEEService.
final class TDEECalculationEngine {

    // MARK: - Constants

    /// Gender adjustment for male in Mifflin-St Jeor formula
    private static let maleAdjustment: Double = 5

    /// Gender adjustment for female in Mifflin-St Jeor formula
    private static let femaleAdjustment: Double = -161

    /// Average of male and female adjustments for unknown gender
    private static let averageAdjustment: Double = (maleAdjustment + femaleAdjustment) / 2  // -78

    /// Minimum valid activity multiplier (sedentary)
    private static let minActivityMultiplier: Double = 1.0

    /// Maximum valid activity multiplier (extra active)
    private static let maxActivityMultiplier: Double = 2.5

    private let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "TDEECalculationEngine"
    )

    init() {}

    // MARK: - BMR Calculation

    /// Calculate Basal Metabolic Rate using Mifflin-St Jeor equation
    /// - Parameters:
    ///   - weightKg: Weight in kilograms (must be in valid range)
    ///   - heightCm: Height in centimeters (must be in valid range)
    ///   - age: Age in years (must be in valid range)
    ///   - gender: Gender string ("male", "m", "female", "f", or other for average)
    /// - Returns: BMR in calories per day
    /// - Throws: ValidationError if inputs are outside valid ranges
    ///
    /// Formula:
    /// - Men: BMR = (10 x weight kg) + (6.25 x height cm) - (5 x age) + 5
    /// - Women: BMR = (10 x weight kg) + (6.25 x height cm) - (5 x age) - 161
    func calculateBMR(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        gender: String
    ) throws -> Double {
        // Validate inputs - throws ValidationError if invalid
        try validateBMRInputs(weightKg: weightKg, heightCm: heightCm, age: age)

        let baseBMR = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age))

        let adjustment: Double
        switch gender.lowercased() {
        case "male", "m":
            adjustment = Self.maleAdjustment
        case "female", "f":
            adjustment = Self.femaleAdjustment
        default:
            adjustment = Self.averageAdjustment
        }

        let bmr = baseBMR + adjustment
        logger.debug(
            """
            BMR calculated: \(bmr, format: .fixed(precision: 1)) kcal \
            (weight=\(weightKg)kg, height=\(heightCm)cm, age=\(age), gender=\(gender))
            """
        )
        return bmr
    }

    // MARK: - Initial TDEE Calculation

    /// Calculate initial TDEE estimate from BMR and activity level
    /// - Parameters:
    ///   - weightKg: Weight in kilograms
    ///   - heightCm: Height in centimeters
    ///   - age: Age in years
    ///   - gender: Gender string
    ///   - activityMultiplier: Activity multiplier (clamped to 1.0-2.5 range)
    /// - Returns: TDEE in calories per day
    /// - Throws: ValidationError if BMR inputs are invalid
    func calculateInitialTDEE(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        gender: String,
        activityMultiplier: Double
    ) throws -> Double {
        let bmr = try calculateBMR(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            gender: gender
        )

        // Clamp activity multiplier to valid range
        let clampedMultiplier = max(Self.minActivityMultiplier, min(activityMultiplier, Self.maxActivityMultiplier))
        if activityMultiplier != clampedMultiplier {
            logger.warning("Activity multiplier \(activityMultiplier) clamped to \(clampedMultiplier)")
        }

        let tdee = bmr * clampedMultiplier
        logger.debug(
            """
            TDEE calculated: \(tdee, format: .fixed(precision: 1)) kcal \
            (BMR=\(bmr, format: .fixed(precision: 1)), multiplier=\(clampedMultiplier))
            """
        )
        return tdee
    }

    /// Calculate initial TDEE using TrainingLevel enum for activity multiplier
    /// - Parameters:
    ///   - weightKg: Weight in kilograms
    ///   - heightCm: Height in centimeters
    ///   - age: Age in years
    ///   - gender: Gender string
    ///   - trainingLevel: Training level enum value
    /// - Returns: TDEE in calories per day
    /// - Throws: ValidationError if BMR inputs are invalid
    func calculateInitialTDEE(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        gender: String,
        trainingLevel: TrainingLevel
    ) throws -> Double {
        try calculateInitialTDEE(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            gender: gender,
            activityMultiplier: trainingLevel.tdeeMultiplier
        )
    }
}
