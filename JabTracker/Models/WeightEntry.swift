//
//  WeightEntry.swift
//  JabTracker
//
//  Weight log entry with optional body fat percentage.
//

import Foundation
import SwiftData

/// Weight log entry - stores weight and optional body fat
/// Note: No User relationship - entries are queried by date in a single-user app context
@Model
final class WeightEntry {
    // MARK: - Constants

    /// Conversion factor from kg to lbs
    static let kgToLbsConversion: Double = 2.20462

    /// Minimum valid weight in kg
    static let minWeightKg: Double = 20.0

    /// Maximum valid weight in kg
    static let maxWeightKg: Double = 500.0

    // MARK: - Identity

    var id: UUID = UUID()

    // MARK: - Measurement

    /// Timestamp of the weight entry
    var timestamp: Date = Date()

    /// Weight in kilograms (always stored in kg)
    var weightKg: Double = 70.0

    /// Optional body fat percentage (0-100 scale)
    var bodyFatPercentage: Double?

    // MARK: - Metadata

    /// Source of the entry: "manual" or "healthkit"
    var source: String = "manual"

    /// Optional notes
    var notes: String?

    // MARK: - Computed Properties

    /// Type-safe source accessor
    var sourceEnum: EntrySource {
        get { EntrySource(rawValue: source) ?? .manual }
        set { source = newValue.rawValue }
    }

    /// Weight converted to pounds
    var weightInLbs: Double {
        weightKg * Self.kgToLbsConversion
    }

    /// Formatted weight for display with unit
    func formattedWeight(useMetric: Bool) -> String {
        if useMetric {
            return String(format: "%.1f kg", weightKg)
        } else {
            return String(format: "%.1f lbs", weightInLbs)
        }
    }

    /// Check if the entry has valid data
    /// Weight must be between 20 kg (44 lbs) and 500 kg (1102 lbs) inclusive
    var isValid: Bool {
        weightKg >= Self.minWeightKg && weightKg <= Self.maxWeightKg
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        weightKg: Double = 70.0,
        bodyFatPercentage: Double? = nil,
        source: String = "manual",
        notes: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.weightKg = weightKg
        self.bodyFatPercentage = bodyFatPercentage
        self.source = source
        self.notes = notes
    }

    /// Convenience initializer for weight in pounds
    convenience init(
        weightLbs: Double,
        bodyFatPercentage: Double? = nil,
        timestamp: Date = Date(),
        source: String = "manual",
        notes: String? = nil
    ) {
        self.init(
            timestamp: timestamp,
            weightKg: weightLbs / Self.kgToLbsConversion,
            bodyFatPercentage: bodyFatPercentage,
            source: source,
            notes: notes
        )
    }
}
