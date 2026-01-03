//
//  TDEECalculationEngine+EWMA.swift
//  JabTracker
//
//  EWMA (Exponentially Weighted Moving Average) weight smoothing extension.
//

import Foundation
import os

extension TDEECalculationEngine {

    // MARK: - Constants

    /// Minimum alpha value for EWMA smoothing
    private static let minimumAlpha: Double = 0.01

    /// Seconds per day for time calculations
    private static let secondsPerDay: Double = 86400

    /// Minimum days required for reliable weight change rate
    private static let minimumDaysForRate: Double = 7

    // MARK: - Logging

    private static let ewmaLogger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "TDEECalculationEngine.EWMA"
    )

    // MARK: - EWMA Calculations

    /// Calculate exponentially weighted moving average weight trend
    /// - Parameters:
    ///   - weights: Array of (date, weightKg) tuples, sorted by date ascending
    ///   - alpha: Smoothing factor (0.01-1.0), higher = more responsive to recent changes
    /// - Returns: Array of (date, smoothedWeight) tuples
    /// - Throws: ValidationError if inputs are invalid
    func calculateEWMA(
        weights: [(date: Date, weightKg: Double)],
        alpha: Double = 0.2
    ) throws -> [(date: Date, smoothedWeight: Double)] {
        try validateEWMAInputs(weights: weights, alpha: alpha, minimumEntries: 1)

        let clampedAlpha = max(Self.minimumAlpha, min(1.0, alpha))
        if alpha != clampedAlpha {
            Self.ewmaLogger.warning("EWMA alpha \(alpha) clamped to \(clampedAlpha)")
        }

        var result: [(Date, Double)] = []
        var ewma = weights[0].weightKg

        for weight in weights {
            ewma = (clampedAlpha * weight.weightKg) + ((1 - clampedAlpha) * ewma)
            result.append((weight.date, ewma))
        }

        Self.ewmaLogger.debug("EWMA calculated: \(weights.count) weights, alpha=\(clampedAlpha)")
        return result
    }

    /// Calculate weight change rate (kg/week) from smoothed weights
    /// - Parameters:
    ///   - smoothedWeights: EWMA smoothed weights
    ///   - windowDays: Number of days to analyze (default 14)
    /// - Returns: Weight change rate in kg/week
    /// - Throws: ValidationError if insufficient data
    func calculateWeightChangeRate(
        smoothedWeights: [(date: Date, smoothedWeight: Double)],
        windowDays: Int = 14
    ) throws -> Double {
        guard smoothedWeights.count >= 2 else {
            Self.ewmaLogger.debug("Weight change rate: insufficient data points (\(smoothedWeights.count) < 2)")
            throw ValidationError.insufficientData(required: 2, actual: smoothedWeights.count)
        }

        let sorted = smoothedWeights.sorted { $0.date < $1.date }
        guard let first = sorted.first, let last = sorted.last else {
            Self.ewmaLogger.error("Weight change rate: sorted array unexpectedly empty")
            throw ValidationError.insufficientData(required: 2, actual: 0)
        }

        let daysDelta = last.date.timeIntervalSince(first.date) / Self.secondsPerDay
        guard daysDelta >= Self.minimumDaysForRate else {
            let span = String(format: "%.1f", daysDelta)
            let minDays = Int(Self.minimumDaysForRate)
            Self.ewmaLogger.debug("Weight change rate: insufficient time span (\(span) < \(minDays) days)")
            throw ValidationError.insufficientData(required: minDays, actual: Int(daysDelta))
        }

        let weightDelta = last.smoothedWeight - first.smoothedWeight
        let rate = (weightDelta / daysDelta) * 7  // Convert to kg/week

        let rateStr = String(format: "%.2f", rate)
        let daysStr = String(format: "%.0f", daysDelta)
        Self.ewmaLogger.debug("Weight change rate: \(rateStr) kg/week over \(daysStr) days")
        return rate
    }

    /// Detect if weight trend is in a plateau (minimal change)
    func isWeightPlateau(
        changeRateKgPerWeek: Double,
        threshold: Double = 0.1
    ) -> Bool {
        abs(changeRateKgPerWeek) < threshold
    }
}
