//
//  DoseEvent.swift
//  JabTracker
//
//  Calculated timeline entity combining scheduled and actual doses for unified presentation
//

import Foundation

/// Type of dose event for timeline display
enum DoseEventType: String, Codable {
    case scheduled  // Scheduled but not yet taken
    case taken  // Dose was taken
    case skipped  // Dose was intentionally skipped
    case missed  // Dose was missed (past window, not taken)
}

/// Adherence status for dose event timeline
enum DoseAdherenceStatus: String, Codable {
    case adherent  // Dose taken within window or validly skipped
    case nonAdherent  // Dose missed or taken outside window
    case pending  // Scheduled but not yet due
}

/// Calculated entity combining scheduled and actual dose information for unified timeline presentation
///
/// `DoseEvent` is a lightweight struct (not persisted) that combines `ScheduledDose` and `Dose` entities
/// to provide a unified view for timeline displays and adherence calculations. It supports three creation patterns:
/// - From a scheduled dose only (shows upcoming or past schedule)
/// - From an actual dose only (shows unscheduled dose entries)
/// - Combined from both (shows adherence to schedule)
struct DoseEvent: Identifiable, Comparable {
    // MARK: - Properties

    /// Unique identifier for this event
    let id: UUID

    /// Timestamp of the event (scheduled time or actual time)
    let timestamp: Date

    /// Type of event (scheduled, taken, skipped, missed)
    let type: DoseEventType

    /// Reference to scheduled dose if applicable
    let scheduledDose: ScheduledDose?

    /// Reference to actual dose if applicable
    let actualDose: Dose?

    /// Dose amount in mg
    let doseAmount: Double

    /// Adherence status for this event
    let adherenceStatus: DoseAdherenceStatus

    /// Medication brand name (e.g., "Ozempic", "Mounjaro")
    let medicationBrandName: String?

    /// Medication generic name (e.g., "semaglutide", "tirzepatide")
    let medicationGenericName: String?

    // MARK: - Computed Properties

    /// Whether this event represents adherent behavior
    ///
    /// Returns `true` only if the dose was actually taken AND adherence status is adherent.
    /// Skipped doses, even if validly skipped, do not count as adherent for this property.
    var isAdherent: Bool {
        adherenceStatus == .adherent && type == .taken
    }

    // MARK: - Factory Methods

    /// Create a DoseEvent from a ScheduledDose
    ///
    /// Determines event type and adherence status based on the scheduled dose's current status:
    /// - `.pending`: Not yet in window → type: scheduled, adherence: pending
    /// - `.taken`: Has actual dose → type: taken, adherence: adherent
    /// - `.skipped`: Intentionally skipped → type: skipped, adherence: adherent (valid skip)
    /// - `.missed`: Past window without dose → type: missed, adherence: non-adherent
    ///
    /// - Parameters:
    ///   - scheduledDose: The scheduled dose to convert
    ///   - medicationBrandName: Optional medication brand name (e.g., "Ozempic")
    ///   - medicationGenericName: Optional medication generic name (e.g., "semaglutide")
    /// - Returns: DoseEvent representing the scheduled dose
    static func from(
        scheduledDose: ScheduledDose,
        medicationBrandName: String? = nil,
        medicationGenericName: String? = nil
    ) -> DoseEvent {
        let status = scheduledDose.status

        let type: DoseEventType
        let adherenceStatus: DoseAdherenceStatus

        switch status {
        case .pending:
            type = .scheduled
            adherenceStatus = .pending
        case .taken:
            type = .taken
            adherenceStatus = .adherent
        case .skipped:
            type = .skipped
            adherenceStatus = .adherent  // Valid skip is adherent
        case .missed:
            type = .missed
            adherenceStatus = .nonAdherent
        }

        return DoseEvent(
            id: UUID(),
            timestamp: scheduledDose.scheduledTime,
            type: type,
            scheduledDose: scheduledDose,
            actualDose: scheduledDose.actualDose,
            doseAmount: scheduledDose.doseAmount,
            adherenceStatus: adherenceStatus,
            medicationBrandName: medicationBrandName,
            medicationGenericName: medicationGenericName
        )
    }

    /// Create a DoseEvent from an actual Dose (no scheduled dose)
    ///
    /// Used for doses that were not scheduled (manual entries). These are considered adherent
    /// as they represent proactive medication management.
    ///
    /// - Parameter actualDose: The actual dose to convert
    /// - Returns: DoseEvent representing the unscheduled dose
    static func from(actualDose: Dose) -> DoseEvent {
        DoseEvent(
            id: UUID(),
            timestamp: actualDose.timestamp,
            type: .taken,
            scheduledDose: nil,
            actualDose: actualDose,
            doseAmount: actualDose.amount,
            adherenceStatus: .adherent,  // Unscheduled doses are adherent
            medicationBrandName: actualDose.medication?.brandName,
            medicationGenericName: actualDose.medication?.genericName
        )
    }

    /// Create a combined DoseEvent from both scheduled and actual doses
    ///
    /// Determines adherence by checking if the actual dose was taken within the scheduling window.
    /// The adherence window is defined by `ScheduledDose.windowStart` and `ScheduledDose.windowEnd`.
    ///
    /// - Parameters:
    ///   - scheduled: The scheduled dose
    ///   - actual: The actual dose taken
    /// - Returns: DoseEvent combining both scheduled and actual information
    static func combined(scheduled: ScheduledDose, actual: Dose) -> DoseEvent {
        // Handle skipped doses - these are intentional skips marked via swipe action
        if actual.skipped {
            return DoseEvent(
                id: UUID(),
                timestamp: actual.timestamp,
                type: .skipped,
                scheduledDose: scheduled,
                actualDose: actual,
                doseAmount: actual.amount,
                adherenceStatus: .adherent,  // Intentional skip is adherent
                medicationBrandName: actual.medication?.brandName,
                medicationGenericName: actual.medication?.genericName
            )
        }

        // Check if dose was taken within the adherence window
        let wasWithinWindow =
            actual.timestamp >= scheduled.windowStart
            && actual.timestamp <= scheduled.windowEnd

        let adherenceStatus: DoseAdherenceStatus = wasWithinWindow ? .adherent : .nonAdherent

        return DoseEvent(
            id: UUID(),
            timestamp: actual.timestamp,  // Use actual time for combined events
            type: .taken,
            scheduledDose: scheduled,
            actualDose: actual,
            doseAmount: actual.amount,
            adherenceStatus: adherenceStatus,
            medicationBrandName: actual.medication?.brandName,
            medicationGenericName: actual.medication?.genericName
        )
    }

    // MARK: - Comparable

    /// Compare two DoseEvents by timestamp
    ///
    /// Events are sorted chronologically (oldest first) for timeline display.
    ///
    /// - Parameters:
    ///   - lhs: Left-hand side event
    ///   - rhs: Right-hand side event
    /// - Returns: `true` if lhs timestamp is earlier than rhs timestamp
    static func < (lhs: DoseEvent, rhs: DoseEvent) -> Bool {
        lhs.timestamp < rhs.timestamp
    }
}
