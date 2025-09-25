//
//  AdherencePattern.swift
//  JabTracker
//
//  Model for representing detected adherence patterns in dose history
//

import Foundation

/// Represents a detected pattern in dose adherence behavior
struct AdherencePattern {
    // MARK: - Pattern Identification

    /// Unique identifier for the pattern
    let id: UUID = UUID()

    /// Type of adherence pattern detected
    let type: PatternType

    /// Descriptive name of the pattern
    let name: String

    /// Detailed description of what was detected
    let description: String

    // MARK: - Pattern Confidence and Quality

    /// Confidence level of the pattern detection (0.0 to 1.0)
    let confidence: Double

    /// Number of data points supporting this pattern
    let supportingDataPoints: Int

    /// Date range over which pattern was detected
    let dateRange: DateInterval

    /// Frequency of the pattern occurrence
    let frequency: PatternFrequency

    // MARK: - Pattern-Specific Data

    /// Specific details about the pattern (varies by type)
    let patternData: [String: Any]

    /// Statistical significance of the pattern
    let statisticalSignificance: Double

    // MARK: - Medical Context

    /// Whether this pattern has clinical significance
    let isClinicallyRelevant: Bool

    /// Risk level associated with this pattern
    let riskLevel: RiskLevel

    /// Medications affected by this pattern
    let affectedMedications: [String]

    // MARK: - Initialization

    init(
        type: PatternType,
        name: String,
        description: String,
        confidence: Double,
        supportingDataPoints: Int,
        dateRange: DateInterval,
        frequency: PatternFrequency,
        patternData: [String: Any] = [:],
        statisticalSignificance: Double = 0.0,
        isClinicallyRelevant: Bool = true,
        riskLevel: RiskLevel = .low,
        affectedMedications: [String] = []
    ) {
        self.type = type
        self.name = name
        self.description = description
        self.confidence = max(0.0, min(1.0, confidence))
        self.supportingDataPoints = supportingDataPoints
        self.dateRange = dateRange
        self.frequency = frequency
        self.patternData = patternData
        self.statisticalSignificance = max(0.0, min(1.0, statisticalSignificance))
        self.isClinicallyRelevant = isClinicallyRelevant
        self.riskLevel = riskLevel
        self.affectedMedications = affectedMedications
    }
}

// MARK: - Pattern Types

extension AdherencePattern {
    enum PatternType: String, CaseIterable {
        case weekendGaps = "weekend_gaps"
        case weekdayConsistency = "weekday_consistency"
        case timingDrift = "timing_drift"
        case doseSkipping = "dose_skipping"
        case perfectAdherence = "perfect_adherence"
        case seasonalVariation = "seasonal_variation"
        case travelDisruption = "travel_disruption"
        case doseForgetting = "dose_forgetting"
        case earlyDosing = "early_dosing"
        case lateDosing = "late_dosing"
        case inconsistentSites = "inconsistent_sites"
        case siteRotationGood = "site_rotation_good"

        var displayName: String {
            switch self {
            case .weekendGaps: return "Weekend Gaps"
            case .weekdayConsistency: return "Weekday Consistency"
            case .timingDrift: return "Timing Drift"
            case .doseSkipping: return "Dose Skipping"
            case .perfectAdherence: return "Perfect Adherence"
            case .seasonalVariation: return "Seasonal Variation"
            case .travelDisruption: return "Travel Disruption"
            case .doseForgetting: return "Dose Forgetting"
            case .earlyDosing: return "Early Dosing"
            case .lateDosing: return "Late Dosing"
            case .inconsistentSites: return "Inconsistent Sites"
            case .siteRotationGood: return "Good Site Rotation"
            }
        }

        var defaultRiskLevel: RiskLevel {
            switch self {
            case .perfectAdherence, .weekdayConsistency, .siteRotationGood:
                return .low
            case .weekendGaps, .timingDrift, .earlyDosing, .lateDosing, .inconsistentSites:
                return .medium
            case .doseSkipping, .seasonalVariation, .travelDisruption, .doseForgetting:
                return .high
            }
        }
    }

    enum PatternFrequency: String, CaseIterable {
        case rare  // Occurs < 10% of opportunities
        case occasional  // 10-30%
        case frequent  // 30-70%
        case consistent  // 70-90%
        case constant  // > 90%

        var displayName: String {
            switch self {
            case .rare: return "Rarely"
            case .occasional: return "Occasionally"
            case .frequent: return "Frequently"
            case .consistent: return "Consistently"
            case .constant: return "Almost Always"
            }
        }

        var percentageRange: ClosedRange<Double> {
            switch self {
            case .rare: return 0.0...0.1
            case .occasional: return 0.1...0.3
            case .frequent: return 0.3...0.7
            case .consistent: return 0.7...0.9
            case .constant: return 0.9...1.0
            }
        }
    }

    enum RiskLevel: String, CaseIterable {
        case low
        case medium
        case high
        case critical

        var displayName: String {
            rawValue.capitalized
        }

        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }
}

// MARK: - Pattern Analysis Helpers

extension AdherencePattern {
    /// Whether this pattern should be reported to the user
    var shouldReport: Bool {
        confidence >= 0.7 && supportingDataPoints >= 3
    }

    /// Priority score for ordering patterns (higher = more important)
    var priorityScore: Double {
        let baseScore = confidence * statisticalSignificance
        let riskMultiplier: Double

        switch riskLevel {
        case .low: riskMultiplier = 1.0
        case .medium: riskMultiplier = 1.5
        case .high: riskMultiplier = 2.0
        case .critical: riskMultiplier = 3.0
        }

        let clinicalMultiplier = isClinicallyRelevant ? 1.2 : 1.0

        return baseScore * riskMultiplier * clinicalMultiplier
    }

    /// Short summary suitable for UI display
    var shortSummary: String {
        "\(name): \(Int(confidence * 100))% confidence"
    }

    /// Extract specific pattern data with type safety
    func getPatternValue<T>(for key: String, as type: T.Type) -> T? {
        patternData[key] as? T
    }
}

// MARK: - Equatable and Hashable

extension AdherencePattern: Equatable, Hashable {
    static func == (lhs: AdherencePattern, rhs: AdherencePattern) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Pattern Creation Helpers

extension AdherencePattern {
    /// Create a weekend gap pattern
    static func weekendGapPattern(
        confidence: Double,
        supportingDataPoints: Int,
        dateRange: DateInterval,
        missedWeekends: Int,
        totalWeekends: Int
    ) -> AdherencePattern {
        let frequency = PatternFrequency.fromPercentage(Double(missedWeekends) / Double(totalWeekends))
        let patternData: [String: Any] = [
            "missed_weekends": missedWeekends,
            "total_weekends": totalWeekends,
            "percentage": Double(missedWeekends) / Double(totalWeekends),
        ]

        return AdherencePattern(
            type: .weekendGaps,
            name: "Weekend Dose Gaps",
            description: "Tendency to miss doses on weekends (\(missedWeekends)/\(totalWeekends) weekends)",
            confidence: confidence,
            supportingDataPoints: supportingDataPoints,
            dateRange: dateRange,
            frequency: frequency,
            patternData: patternData,
            statisticalSignificance: confidence,
            isClinicallyRelevant: true,
            riskLevel: .medium,
            affectedMedications: []
        )
    }

    /// Create a timing drift pattern
    static func timingDriftPattern(
        confidence: Double,
        supportingDataPoints: Int,
        dateRange: DateInterval,
        averageDrift: TimeInterval,
        driftDirection: String
    ) -> AdherencePattern {
        let driftHours = averageDrift / 3600
        let patternData: [String: Any] = [
            "average_drift_hours": driftHours,
            "drift_direction": driftDirection,
        ]

        return AdherencePattern(
            type: .timingDrift,
            name: "Dose Timing Drift",
            description:
                "Doses are trending \(driftDirection) by \(String(format: "%.1f", abs(driftHours))) hours on average",
            confidence: confidence,
            supportingDataPoints: supportingDataPoints,
            dateRange: dateRange,
            frequency: .frequent,
            patternData: patternData,
            statisticalSignificance: confidence,
            isClinicallyRelevant: true,
            riskLevel: abs(driftHours) > 6 ? .high : .medium
        )
    }
}

// MARK: - Pattern Frequency Helpers

extension AdherencePattern.PatternFrequency {
    static func fromPercentage(_ percentage: Double) -> AdherencePattern.PatternFrequency {
        switch percentage {
        case 0.0...0.1: return .rare
        case 0.1...0.3: return .occasional
        case 0.3...0.7: return .frequent
        case 0.7...0.9: return .consistent
        default: return .constant
        }
    }
}
