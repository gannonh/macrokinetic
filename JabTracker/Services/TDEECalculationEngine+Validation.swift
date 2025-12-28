//
//  TDEECalculationEngine+Validation.swift
//  JabTracker
//
//  Input validation extension with typed errors for TDEE calculations.
//

import Foundation
import os

extension TDEECalculationEngine {

    // MARK: - Validation Constants

    /// Valid weight range in kilograms
    static let weightRange = 20.0...500.0

    /// Valid height range in centimeters
    static let heightRange = 100.0...250.0

    /// Valid age range in years
    static let ageRange = 10...120

    /// Valid alpha range for EWMA (matches clamping in +EWMA)
    static let alphaRange = 0.01...1.0

    /// Reasonable TDEE bounds (severe restriction to extreme athlete)
    static let reasonableTDEERange = 800.0...6000.0

    // MARK: - Logging

    private static let validationLogger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "TDEECalculationEngine.Validation"
    )

    // MARK: - Validation Errors

    enum ValidationError: LocalizedError {
        case invalidWeight(Double)
        case invalidHeight(Double)
        case invalidAge(Int)
        case invalidAlpha(Double)
        case invalidDuration(Int)
        case invalidIntake(Double)
        case insufficientData(required: Int, actual: Int)

        var errorDescription: String? {
            switch self {
            case .invalidWeight(let weight):
                let min = Int(TDEECalculationEngine.weightRange.lowerBound)
                let max = Int(TDEECalculationEngine.weightRange.upperBound)
                return "Weight must be between \(min)-\(max) kg. You entered \(Int(weight)) kg."
            case .invalidHeight(let height):
                let min = Int(TDEECalculationEngine.heightRange.lowerBound)
                let max = Int(TDEECalculationEngine.heightRange.upperBound)
                return "Height must be between \(min)-\(max) cm. You entered \(Int(height)) cm."
            case .invalidAge(let age):
                let min = TDEECalculationEngine.ageRange.lowerBound
                let max = TDEECalculationEngine.ageRange.upperBound
                return "Age must be between \(min)-\(max) years. You entered \(age) years."
            case .invalidAlpha(let alpha):
                let min = TDEECalculationEngine.alphaRange.lowerBound
                let max = TDEECalculationEngine.alphaRange.upperBound
                return "Smoothing factor must be between \(min)-\(max). Got \(alpha)."
            case .invalidDuration(let days):
                return "Duration must be positive. Got \(days) days."
            case .invalidIntake(let intake):
                return "Calorie intake must be positive. Got \(Int(intake)) calories."
            case .insufficientData(let required, let actual):
                return "Need at least \(required) data points. You have \(actual)."
            }
        }
    }

    // MARK: - Validation Methods

    func validateBMRInputs(
        weightKg: Double,
        heightCm: Double,
        age: Int
    ) throws {
        guard Self.weightRange.contains(weightKg) else {
            Self.validationLogger.warning("BMR validation failed: weight \(weightKg) outside \(Self.weightRange)")
            throw ValidationError.invalidWeight(weightKg)
        }
        guard Self.heightRange.contains(heightCm) else {
            Self.validationLogger.warning("BMR validation failed: height \(heightCm) outside \(Self.heightRange)")
            throw ValidationError.invalidHeight(heightCm)
        }
        guard Self.ageRange.contains(age) else {
            Self.validationLogger.warning("BMR validation failed: age \(age) outside \(Self.ageRange)")
            throw ValidationError.invalidAge(age)
        }
    }

    func validateEWMAInputs(
        weights: [(date: Date, weightKg: Double)],
        alpha: Double,
        minimumEntries: Int = 2
    ) throws {
        guard weights.count >= minimumEntries else {
            Self.validationLogger.debug("EWMA validation failed: \(weights.count) entries < minimum \(minimumEntries)")
            throw ValidationError.insufficientData(required: minimumEntries, actual: weights.count)
        }
        guard Self.alphaRange.contains(alpha) else {
            Self.validationLogger.warning("EWMA validation failed: alpha \(alpha) outside \(Self.alphaRange)")
            throw ValidationError.invalidAlpha(alpha)
        }
    }

    func validateAdaptiveTDEEInputs(
        averageDailyIntake: Double,
        durationDays: Int
    ) throws {
        guard averageDailyIntake > 0 else {
            Self.validationLogger.warning("Adaptive TDEE validation failed: intake \(averageDailyIntake) <= 0")
            throw ValidationError.invalidIntake(averageDailyIntake)
        }
        guard durationDays > 0 else {
            Self.validationLogger.warning("Adaptive TDEE validation failed: duration \(durationDays) <= 0")
            throw ValidationError.invalidDuration(durationDays)
        }
    }

    /// Check if calculated TDEE is within reasonable bounds
    func isReasonableTDEE(_ tdee: Double) -> Bool {
        Self.reasonableTDEERange.contains(tdee)
    }
}
