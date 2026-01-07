//
//  BiologicalSex.swift
//  JabTracker
//
//  Biological sex enum matching HealthKit's HKBiologicalSex options.
//  Used for TDEE calculations and profile data.
//

import Foundation

/// Biological sex options matching HealthKit's HKBiologicalSex.
/// Used for BMR/TDEE calculations which require sex-based adjustments.
enum BiologicalSex: String, CaseIterable, Codable {
    case notSet = ""
    case female = "female"
    case male = "male"
    case other = "other"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .notSet: return "Not Set"
        case .female: return "Female"
        case .male: return "Male"
        case .other: return "Other"
        }
    }

    /// Short display name for compact UI (e.g., segmented controls)
    var shortName: String {
        switch self {
        case .notSet: return "Not Set"
        case .female: return "Female"
        case .male: return "Male"
        case .other: return "Other"
        }
    }

    /// BMR adjustment for Mifflin-St Jeor formula.
    /// Returns nil for notSet (calculation should be blocked).
    /// Returns average of male/female for other.
    var bmrAdjustment: Double? {
        switch self {
        case .notSet:
            return nil  // Block calculation - require selection
        case .female:
            return -161
        case .male:
            return 5
        case .other:
            return -78  // Average of male (5) and female (-161)
        }
    }

    /// Whether this value allows TDEE calculations to proceed
    var allowsCalculation: Bool {
        self != .notSet
    }

    /// Initialize from HealthKit biological sex string
    /// Maps HealthKit values to our enum
    init(fromHealthKit healthKitValue: String?) {
        guard let value = healthKitValue?.lowercased() else {
            self = .notSet
            return
        }
        switch value {
        case "male", "m":
            self = .male
        case "female", "f":
            self = .female
        case "other":
            self = .other
        default:
            self = .notSet
        }
    }

    /// Options available for selection (excludes notSet for active selection)
    static var selectableOptions: [BiologicalSex] {
        [.female, .male, .other]
    }
}
