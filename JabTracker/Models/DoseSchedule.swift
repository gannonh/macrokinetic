//
//  DoseSchedule.swift
//  JabTracker
//
//  SwiftData model for managing medication dose schedules.
//  Supports weekly, split-dose, and custom scheduling patterns.
//

import Foundation
import SwiftData

/// Defines the type of dose scheduling pattern
///
/// - weekly: Standard weekly dosing schedule (e.g., semaglutide once weekly)
/// - splitDose: Single dose amount split across multiple injections
/// - custom: Custom recurring pattern defined by customScheduleData
enum SchedulePatternType: String, Codable {
    case weekly
    case splitDose
    case custom
}

/// SwiftData model representing a medication dosing schedule
///
/// DoseSchedule manages the pattern and timing for medication administration.
/// It supports various scheduling patterns including:
/// - Weekly dosing (most GLP-1 medications)
/// - Split-dose protocols (dividing single dose across multiple injections)
/// - Custom recurring patterns (alternating doses, specific day sequences)
///
/// The schedule can be paused and resumed to accommodate treatment interruptions
/// without losing historical schedule data. All scheduled doses are maintained
/// through the `scheduledDoses` relationship for adherence tracking.
///
/// **Medical Context:**
/// - Scheduling windows define adherence boundaries (typically ±2 hours)
/// - Pause/resume functionality supports vacation, illness, or side effect management
/// - Base schedule stored as encoded JSON for flexibility
/// - Custom schedule data allows complex patterns while maintaining CloudKit sync
@Model
final class DoseSchedule {
    // MARK: - Identity

    /// Unique identifier for the schedule
    var id: UUID = UUID()

    // MARK: - Relationships

    /// Parent medication profile this schedule belongs to
    ///
    /// Child side of relationship - no @Relationship attribute per one-side rule
    var medicationProfile: MedicationProfile?

    /// All scheduled doses generated from this schedule
    ///
    /// Parent side of relationship with cascade delete - when schedule is deleted,
    /// all scheduled doses are removed to maintain data integrity
    @Relationship(deleteRule: .cascade, inverse: \ScheduledDose.schedule)
    var scheduledDoses: [ScheduledDose]?  // CloudKit requires optional relationships

    // MARK: - Schedule Configuration

    /// Type of scheduling pattern (weekly, splitDose, custom)
    var patternType: SchedulePatternType = SchedulePatternType.weekly

    /// Encoded JSON representation of the base schedule pattern
    ///
    /// **Format depends on patternType:**
    /// - Weekly: `{ "dayOfWeek": 1, "hour": 9, "minute": 0 }`
    /// - SplitDose: `{ "doses": [{"hour": 9, "minute": 0}, {"hour": 21, "minute": 0}] }`
    /// - Custom: Structure defined by customScheduleData
    ///
    /// Stored as Data for CloudKit compatibility
    var baseSchedule: Data = Data()

    /// Optional custom schedule data for complex patterns
    ///
    /// Used for patterns that don't fit standard weekly or split-dose models.
    /// Examples: alternating weekly doses, specific day sequences, dose escalation patterns
    ///
    /// Stored as encoded JSON Data for CloudKit compatibility
    var customScheduleData: Data?

    // MARK: - State Management

    /// Whether this schedule is currently active
    ///
    /// Inactive schedules don't generate new scheduled doses but maintain
    /// historical data for analytics and adherence tracking
    var isActive: Bool = true

    /// Timestamp when schedule was paused
    ///
    /// Used for tracking treatment interruptions. When set, new scheduled
    /// doses are not generated until schedule is resumed.
    var pausedAt: Date?

    /// Timestamp when schedule should automatically resume
    ///
    /// Optional - if nil, schedule remains paused until manually resumed.
    /// Useful for planned interruptions (vacation, travel, medical procedures)
    var pausedUntil: Date?

    // MARK: - Audit Trail

    /// Timestamp when schedule was created
    var createdAt: Date = Date()

    /// Timestamp when schedule was last modified
    ///
    /// Updated whenever schedule configuration changes
    var updatedAt: Date = Date()

    // MARK: - Initialization

    /// Initialize a new dose schedule
    ///
    /// - Parameters:
    ///   - medicationProfile: Parent medication profile (optional)
    ///   - patternType: Type of schedule pattern (default: .weekly)
    ///   - baseSchedule: Encoded JSON schedule data (default: empty)
    ///   - isActive: Whether schedule is active (default: true)
    ///   - customScheduleData: Optional custom pattern data (default: nil)
    init(
        medicationProfile: MedicationProfile? = nil,
        patternType: SchedulePatternType = .weekly,
        baseSchedule: Data = Data(),
        isActive: Bool = true,
        customScheduleData: Data? = nil
    ) {
        self.medicationProfile = medicationProfile
        self.patternType = patternType
        self.baseSchedule = baseSchedule
        self.isActive = isActive
        self.customScheduleData = customScheduleData
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Returns the next scheduled dose time, if any
    ///
    /// Finds the earliest pending scheduled dose from the `scheduledDoses` relationship.
    /// Returns nil if no pending doses exist or if schedule is paused.
    ///
    /// **Adherence Logic:**
    /// - Only considers doses with status == .pending
    /// - Ignores taken, skipped, or missed doses
    /// - Sorted by scheduledTime ascending
    ///
    /// - Returns: Date of next pending dose, or nil if none exist
    var nextScheduledDose: Date? {
        // Filter for pending doses only
        let pendingDoses =
            scheduledDoses?.filter { dose in
                dose.status == .pending
            } ?? []

        // Use min() to find earliest scheduled dose
        guard let nextDose = pendingDoses.min(by: { $0.scheduledTime < $1.scheduledTime }) else {
            return nil
        }

        return nextDose.scheduledTime
    }
}
