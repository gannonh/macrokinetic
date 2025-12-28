//
//  TDEECalculationEngine+EWMA.swift
//  JabTracker
//
//  EWMA (Exponentially Weighted Moving Average) weight smoothing extension.
//

import Foundation

extension TDEECalculationEngine {

    // MARK: - EWMA Calculations

    /// Calculate exponentially weighted moving average weight trend
    /// - Parameters:
    ///   - weights: Array of (date, weightKg) tuples, sorted by date ascending
    ///   - alpha: Smoothing factor (0-1), higher = more responsive to recent changes
    /// - Returns: Array of (date, smoothedWeight) tuples
    func calculateEWMA(
        weights: [(date: Date, weightKg: Double)],
        alpha: Double = 0.2
    ) -> [(date: Date, smoothedWeight: Double)] {
        guard !weights.isEmpty else { return [] }
        let clampedAlpha = max(0.01, min(1.0, alpha))

        var result: [(Date, Double)] = []
        var ewma = weights[0].weightKg

        for weight in weights {
            ewma = (clampedAlpha * weight.weightKg) + ((1 - clampedAlpha) * ewma)
            result.append((weight.date, ewma))
        }

        return result
    }

    /// Calculate weight change rate (kg/week) from smoothed weights
    /// - Parameters:
    ///   - smoothedWeights: EWMA smoothed weights
    ///   - windowDays: Number of days to analyze (default 14)
    /// - Returns: Weight change rate in kg/week, nil if insufficient data
    func calculateWeightChangeRate(
        smoothedWeights: [(date: Date, smoothedWeight: Double)],
        windowDays: Int = 14
    ) -> Double? {
        guard smoothedWeights.count >= 2 else { return nil }

        let sorted = smoothedWeights.sorted { $0.date < $1.date }
        guard let first = sorted.first, let last = sorted.last else { return nil }

        let daysDelta = last.date.timeIntervalSince(first.date) / 86400
        guard daysDelta >= 7 else { return nil }  // Need at least 7 days

        let weightDelta = last.smoothedWeight - first.smoothedWeight
        return (weightDelta / daysDelta) * 7  // Convert to kg/week
    }

    /// Detect if weight trend is in a plateau (minimal change)
    func isWeightPlateau(
        changeRateKgPerWeek: Double,
        threshold: Double = 0.1
    ) -> Bool {
        abs(changeRateKgPerWeek) < threshold
    }
}
