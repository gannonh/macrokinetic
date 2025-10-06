//
//  ScheduleService+Modifications.swift
//  JabTracker
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "ScheduleService")

/// Extension for ScheduleService providing dose modification functionality.
///
/// Handles:
/// - Rescheduling doses within valid time ranges
/// - Skipping doses with optional reasons
/// - Marking doses as taken and linking to actual Dose entities
/// - Validation and adherence metric updates
extension ScheduleService {

    // MARK: - Dose Rescheduling

    /**
     * Reschedules a dose to a new time.
     *
     * Validates that the new time is within ±7 days of the original scheduled time.
     * Updates scheduledTime, windowStart, windowEnd, and preserves original time
     * in rescheduledFrom field.
     *
     * - Parameters:
     *   - scheduledDose: The dose to reschedule
     *   - newTime: The new scheduled time (must be within ±7 days)
     *
     * - Throws:
     *   - ScheduleServiceError.invalidTimeRange if new time is >7 days from original
     *   - ScheduleServiceError.doseNotModifiable if dose is already taken or skipped
     *   - ScheduleServiceError.contextSaveFailed if save fails
     */
    func rescheduleDose(_ scheduledDose: ScheduledDose, to newTime: Date) throws {
        logger.info("Rescheduling dose \(scheduledDose.id) to \(newTime)")

        // Validate dose is modifiable (not already taken or skipped)
        if scheduledDose.actualDose != nil {
            logger.warning("Cannot reschedule dose that has been taken")
            throw ScheduleServiceError.doseNotModifiable
        }
        if scheduledDose.skippedAt != nil {
            logger.warning("Cannot reschedule dose that has been skipped")
            throw ScheduleServiceError.doseNotModifiable
        }

        // Validate new time is within ±7 days of original
        let originalTime = scheduledDose.rescheduledFrom ?? scheduledDose.scheduledTime
        let maxShift: TimeInterval = 7 * 24 * 60 * 60  // 7 days in seconds
        let timeDifference = abs(newTime.timeIntervalSince(originalTime))

        guard timeDifference <= maxShift else {
            logger.warning("Reschedule rejected: \(timeDifference / 86400) days exceeds 7-day limit")
            throw ScheduleServiceError.invalidTimeRange
        }

        // Preserve original scheduled time if this is first reschedule
        if scheduledDose.rescheduledFrom == nil {
            scheduledDose.rescheduledFrom = scheduledDose.scheduledTime
        }

        // Update scheduled time
        scheduledDose.scheduledTime = newTime

        // Recalculate adherence window
        guard let schedule = scheduledDose.schedule else {
            logger.error("Scheduled dose has no parent schedule")
            throw ScheduleServiceError.scheduleNotFound
        }

        let config = try decodeScheduleConfiguration(schedule)
        let windowBefore = TimeInterval(config.windowMinutesBefore * 60)
        let windowAfter = TimeInterval(config.windowMinutesAfter * 60)

        scheduledDose.windowStart = newTime.addingTimeInterval(-windowBefore)
        scheduledDose.windowEnd = newTime.addingTimeInterval(windowAfter)

        // Update timestamp
        scheduledDose.updatedAt = Date()

        // Save changes
        do {
            try context.save()
            logger.info("Successfully rescheduled dose to \(newTime)")
        } catch {
            logger.error("Failed to save rescheduled dose: \(error)")
            throw ScheduleServiceError.contextSaveFailed(error)
        }
    }

    // MARK: - Skip Dose

    /**
     * Marks a dose as skipped with optional reason.
     *
     * Sets skippedAt timestamp and optional skipReason. Skipped doses are
     * considered adherent behavior (intentional decision) and don't count
     * as missed doses in adherence calculations.
     *
     * - Parameters:
     *   - scheduledDose: The dose to mark as skipped
     *   - reason: Optional reason for skipping
     *
     * - Throws:
     *   - ScheduleServiceError.doseNotModifiable if dose is already taken
     *   - ScheduleServiceError.contextSaveFailed if save fails
     */
    func skipDose(_ scheduledDose: ScheduledDose, reason: String?) throws {
        logger.info("Skipping dose \(scheduledDose.id)")

        // Validate dose is not already taken
        if scheduledDose.actualDose != nil {
            logger.warning("Cannot skip dose that has been taken")
            throw ScheduleServiceError.doseNotModifiable
        }

        // Mark as skipped
        scheduledDose.skippedAt = Date()
        scheduledDose.skipReason = reason

        // Update timestamp
        scheduledDose.updatedAt = Date()

        // Save changes
        do {
            try context.save()
            logger.info("Successfully skipped dose")
        } catch {
            logger.error("Failed to save skipped dose: \(error)")
            throw ScheduleServiceError.contextSaveFailed(error)
        }
    }

    // MARK: - Mark Dose Taken

    /**
     * Links a scheduled dose to an actual Dose entity.
     *
     * Creates the relationship between ScheduledDose and Dose to enable
     * adherence tracking. This should be called when a dose is logged
     * and matches a scheduled dose.
     *
     * - Parameters:
     *   - scheduledDose: The scheduled dose to link
     *   - actualDose: The actual Dose entity that was taken
     *
     * - Throws:
     *   - ScheduleServiceError.doseNotModifiable if dose is already linked or skipped
     *   - ScheduleServiceError.contextSaveFailed if save fails
     */
    func markDoseTaken(_ scheduledDose: ScheduledDose, actualDose: Dose) throws {
        logger.info("Marking dose \(scheduledDose.id) as taken")

        // Validate dose is not already taken or skipped
        if scheduledDose.actualDose != nil {
            logger.warning("Dose is already marked as taken")
            throw ScheduleServiceError.doseNotModifiable
        }
        if scheduledDose.skippedAt != nil {
            logger.warning("Cannot mark skipped dose as taken")
            throw ScheduleServiceError.doseNotModifiable
        }

        // Link actual dose
        scheduledDose.actualDose = actualDose
        actualDose.scheduledDose = scheduledDose

        // Update timestamp
        scheduledDose.updatedAt = Date()

        // Save changes
        do {
            try context.save()
            logger.info("Successfully marked dose as taken")
        } catch {
            logger.error("Failed to save dose taken status: \(error)")
            throw ScheduleServiceError.contextSaveFailed(error)
        }
    }
}
