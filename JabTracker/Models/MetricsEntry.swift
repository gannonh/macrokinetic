//
//  MetricsEntry.swift
//  JabTracker
//
//  Body measurements log entry with support for waist, hip, chest, and neck circumferences.
//

import Foundation
import SwiftData

/// Body measurements log entry - stores circumference measurements
/// Note: No User relationship - entries are queried by date in a single-user app context
@Model
final class MetricsEntry {
    // MARK: - Constants

    /// Conversion factor from cm to inches
    static let cmToInchesConversion: Double = 0.393701

    /// Minimum valid circumference in cm
    static let minCircumferenceCm: Double = 10.0

    /// Maximum valid circumference in cm
    static let maxCircumferenceCm: Double = 300.0

    /// Validate a circumference measurement is within acceptable range
    /// - Parameter cm: Circumference in centimeters
    /// - Returns: True if within valid range (10-300 cm)
    static func isValidCircumference(_ cm: Double) -> Bool {
        cm >= minCircumferenceCm && cm <= maxCircumferenceCm
    }

    // MARK: - Identity

    var id: UUID = UUID()

    // MARK: - Measurement

    /// Timestamp of the metrics entry
    var timestamp: Date = Date()

    /// Waist circumference in centimeters
    var waistCm: Double?

    /// Hip circumference in centimeters
    var hipCm: Double?

    /// Chest circumference in centimeters
    var chestCm: Double?

    /// Neck circumference in centimeters
    var neckCm: Double?

    // MARK: - Metadata

    /// Source of the entry: "manual" or "healthkit"
    var source: String = "manual"

    /// Optional notes
    var notes: String?

    // MARK: - Computed Properties

    /// Waist converted to inches
    var waistInInches: Double? {
        waistCm.map { $0 * Self.cmToInchesConversion }
    }

    /// Hip converted to inches
    var hipInInches: Double? {
        hipCm.map { $0 * Self.cmToInchesConversion }
    }

    /// Chest converted to inches
    var chestInInches: Double? {
        chestCm.map { $0 * Self.cmToInchesConversion }
    }

    /// Neck converted to inches
    var neckInInches: Double? {
        neckCm.map { $0 * Self.cmToInchesConversion }
    }

    /// Check if entry has at least one measurement
    var hasAnyMetrics: Bool {
        waistCm != nil || hipCm != nil || chestCm != nil || neckCm != nil
    }

    /// Check if the entry has valid data
    /// At least one measurement must be present and within valid range (10-300 cm)
    var isValid: Bool {
        guard hasAnyMetrics else { return false }

        let measurements = [waistCm, hipCm, chestCm, neckCm].compactMap { $0 }
        return measurements.allSatisfy { Self.isValidCircumference($0) }
    }

    /// Formatted measurement for display with unit
    func formattedMeasurement(_ value: Double?, useMetric: Bool) -> String? {
        guard let value = value else { return nil }

        if useMetric {
            return String(format: "%.1f cm", value)
        } else {
            let inches = value * Self.cmToInchesConversion
            return String(format: "%.1f in", inches)
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        waistCm: Double? = nil,
        hipCm: Double? = nil,
        chestCm: Double? = nil,
        neckCm: Double? = nil,
        source: String = "manual",
        notes: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.waistCm = waistCm
        self.hipCm = hipCm
        self.chestCm = chestCm
        self.neckCm = neckCm
        self.source = source
        self.notes = notes
    }

    /// Convenience initializer for measurements in inches
    convenience init(
        waistInches: Double? = nil,
        hipInches: Double? = nil,
        chestInches: Double? = nil,
        neckInches: Double? = nil,
        timestamp: Date = Date(),
        source: String = "manual",
        notes: String? = nil
    ) {
        self.init(
            timestamp: timestamp,
            waistCm: waistInches.map { $0 / Self.cmToInchesConversion },
            hipCm: hipInches.map { $0 / Self.cmToInchesConversion },
            chestCm: chestInches.map { $0 / Self.cmToInchesConversion },
            neckCm: neckInches.map { $0 / Self.cmToInchesConversion },
            source: source,
            notes: notes
        )
    }
}
