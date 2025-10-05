//
//  ScheduledDose.swift
//  JabTracker
//
//  SwiftData model representing a scheduled dose instance with adherence window tracking.
//  Part of the dose scheduling system for managing weekly, split-dose, and custom patterns.
//

import Foundation
import SwiftData

/// A scheduled dose instance representing when a medication dose should be taken.
///
/// ScheduledDose tracks individual scheduled medication doses with adherence windows,
/// supporting the dose scheduling system. It links scheduled intentions with actual
/// doses taken, enabling adherence analysis and missed dose detection.
///
/// ## Medical Context
///
/// Adherence windows define the acceptable time range for taking a scheduled dose:
/// - **windowStart**: Beginning of the adherence window (typically 2 hours before)
/// - **windowEnd**: End of the adherence window (typically 2 hours after)
/// - **scheduledTime**: Ideal time for the dose within the window
///
/// ## Status Transitions
///
/// A scheduled dose progresses through these states:
/// - **pending**: Within window, not yet taken or skipped
/// - **taken**: actualDose reference exists (taken within or outside window)
/// - **skipped**: Intentionally skipped with optional reason
/// - **missed**: Past window end with no action taken
///
/// ## Relationships
///
/// - **schedule**: Parent DoseSchedule defining the pattern (plain property, child side)
/// - **actualDose**: Linked Dose if taken (plain property, child side)
///
/// ## Example Usage
///
/// ```swift
/// let scheduledDose = ScheduledDose(
///     scheduledTime: nextWeeklyDose,
///     doseAmount: 0.5,
///     windowStart: nextWeeklyDose.addingTimeInterval(-2 * 60 * 60),
///     windowEnd: nextWeeklyDose.addingTimeInterval(2 * 60 * 60)
/// )
/// context.insert(scheduledDose)
/// scheduledDose.schedule = medicationSchedule
/// ```
@Model
final class ScheduledDose {

    // MARK: - Primary Fields

    /// Unique identifier for this scheduled dose
    var id: UUID = UUID()

    /// Parent schedule that generated this dose (child relationship - plain property)
    var schedule: DoseSchedule?

    /// Ideal time for taking this dose
    var scheduledTime: Date = Date()

    /// Amount of medication to administer (in mg)
    var doseAmount: Double = 0.0

    /// Start of the adherence window (typically 2 hours before scheduledTime)
    var windowStart: Date = Date()

    /// End of the adherence window (typically 2 hours after scheduledTime)
    var windowEnd: Date = Date()

    // MARK: - Optional Action Fields

    /// Actual dose taken (if completed)
    @Relationship(inverse: \Dose.scheduledDose)
    var actualDose: Dose?

    /// Timestamp when dose was intentionally skipped
    var skippedAt: Date?

    /// Reason for skipping (e.g., "Travel", "Feeling unwell")
    var skipReason: String?

    /// Original scheduled time if this dose was rescheduled
    var rescheduledFrom: Date?

    // MARK: - Audit Trail

    /// Timestamp when this scheduled dose was created
    var createdAt: Date = Date()

    /// Timestamp when this scheduled dose was last modified
    var updatedAt: Date = Date()

    // MARK: - Initialization

    /**
     Create a new ScheduledDose with required parameters.

     - Parameters:
       - scheduledTime: Ideal time for taking this dose
       - doseAmount: Amount of medication (in mg)
       - windowStart: Start of adherence window
       - windowEnd: End of adherence window

     - Note: All Date parameters use UTC. Timezone conversion handled in service layer.
     */
    init(
        scheduledTime: Date = Date(),
        doseAmount: Double = 0.0,
        windowStart: Date = Date(),
        windowEnd: Date = Date()
    ) {
        self.scheduledTime = scheduledTime
        self.doseAmount = doseAmount
        self.windowStart = windowStart
        self.windowEnd = windowEnd
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    /**
     Whether the current time falls within the adherence window.

     Returns `true` if the current time is between `windowStart` and `windowEnd` (inclusive).
     Uses a 1-second tolerance on the end boundary to handle timing precision and edge cases.
     Used to determine if a dose can be taken on time.

     - Returns: `true` if now is within the adherence window, `false` otherwise
     */
    var isInWindow: Bool {
        let now = Date()
        let tolerance: TimeInterval = 1.0  // 1 second tolerance for boundary conditions
        return now >= windowStart && now <= windowEnd.addingTimeInterval(tolerance)
    }

    /**
     Current status of this scheduled dose.

     Determines status based on the following priority:
     1. **taken**: If `actualDose` exists (dose was completed)
     2. **skipped**: If `skippedAt` is set (dose was intentionally skipped)
     3. **missed**: If current time is past `windowEnd` (dose was missed)
     4. **pending**: Otherwise (dose is awaiting action)

     - Returns: Current `ScheduledDoseStatus` enum value
     */
    var status: ScheduledDoseStatus {
        // Priority 1: Check if dose was taken
        if actualDose != nil {
            return .taken
        }

        // Priority 2: Check if dose was skipped
        if skippedAt != nil {
            return .skipped
        }

        // Priority 3: Check if dose was missed (past window)
        let now = Date()
        if now > windowEnd {
            return .missed
        }

        // Default: Dose is pending
        return .pending
    }
}

// MARK: - Supporting Enums

/// Status of a scheduled dose instance.
///
/// - **pending**: Awaiting action (within or before window)
/// - **taken**: Dose was completed (actualDose exists)
/// - **skipped**: Dose was intentionally skipped (skippedAt set)
/// - **missed**: Dose was not taken and window has passed
enum ScheduledDoseStatus: String, Codable {
    case pending
    case taken
    case skipped
    case missed
}
