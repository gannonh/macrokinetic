//
//  TDEECalculationEngine+Validation.swift
//  JabTracker
//
//  Input validation extension with typed errors for TDEE calculations.
//

import Foundation

extension TDEECalculationEngine {

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
                return "Weight must be between 20-500 kg. You entered \(Int(weight)) kg."
            case .invalidHeight(let height):
                return "Height must be between 100-250 cm. You entered \(Int(height)) cm."
            case .invalidAge(let age):
                return "Age must be between 10-120 years. You entered \(age) years."
            case .invalidAlpha(let alpha):
                return "Smoothing factor must be between 0-1. Got \(alpha)."
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
        guard weightKg >= 20, weightKg <= 500 else {
            throw ValidationError.invalidWeight(weightKg)
        }
        guard heightCm >= 100, heightCm <= 250 else {
            throw ValidationError.invalidHeight(heightCm)
        }
        guard age >= 10, age <= 120 else {
            throw ValidationError.invalidAge(age)
        }
    }

    func validateEWMAInputs(
        weights: [(date: Date, weightKg: Double)],
        alpha: Double,
        minimumEntries: Int = 2
    ) throws {
        guard weights.count >= minimumEntries else {
            throw ValidationError.insufficientData(required: minimumEntries, actual: weights.count)
        }
        guard alpha > 0, alpha <= 1 else {
            throw ValidationError.invalidAlpha(alpha)
        }
    }

    func validateAdaptiveTDEEInputs(
        averageDailyIntake: Double,
        durationDays: Int
    ) throws {
        guard averageDailyIntake > 0 else {
            throw ValidationError.invalidIntake(averageDailyIntake)
        }
        guard durationDays > 0 else {
            throw ValidationError.invalidDuration(durationDays)
        }
    }

    /// Check if calculated TDEE is within reasonable bounds
    func isReasonableTDEE(_ tdee: Double) -> Bool {
        tdee >= 800 && tdee <= 6000
    }
}
