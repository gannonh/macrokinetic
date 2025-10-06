//
//  ScheduleService+Titration.swift
//  JabTracker
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "ScheduleService")

/// Extension for ScheduleService providing titration integration functionality.
///
/// Handles:
/// - Detection of active titrations affecting schedules
/// - Schedule updates when titration completes
/// - User-friendly titration warning messages
/// - Logging of titration-triggered schedule modifications
extension ScheduleService {

    // MARK: - Titration Detection

    /**
     * Checks if a medication profile has an active titration affecting the schedule.
     *
     * A titration is considered "active" if its scheduledDate is within the next 30 days.
     * This determines whether to show warning messages and prepare for dose changes.
     *
     * - Parameter schedule: The dose schedule to check for titration impact
     * - Returns: The active DoseTitration if found, nil otherwise
     *
     * - Note: Only considers titrations with scheduledDate within next 30 days
     */
    func checkTitrationImpact(for schedule: DoseSchedule) -> DoseTitration? {
        logger.info("Checking titration impact for schedule \(schedule.id)")

        // Get medication profile from schedule
        guard let medicationProfile = schedule.medicationProfile else {
            logger.debug("No medication profile associated with schedule")
            return nil
        }

        // Calculate 30-day window
        let now = Date()
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now

        // Check if medication profile has an active titration within 30 days
        guard let titrations = medicationProfile.doseTitrations, !titrations.isEmpty else {
            logger.debug("No titrations for medication profile")
            return nil
        }

        // Find the most recent titration
        guard let titration = titrations.max(by: { $0.scheduledDate < $1.scheduledDate }) else {
            logger.debug("No current titration for medication profile")
            return nil
        }

        // Check if titration is within 30-day window
        if titration.scheduledDate >= now && titration.scheduledDate <= thirtyDaysFromNow {
            logger.info("Found active titration scheduled for \(titration.scheduledDate)")
            return titration
        }

        logger.debug("Titration exists but is beyond 30-day window")
        return nil
    }

    // MARK: - Titration Completion Handling

    /**
     * Handles a completed titration by updating the schedule and regenerating doses.
     *
     * This method:
     * 1. Updates schedule's baseSchedule doseAmount to titration's toDose
     * 2. Logs the titration-triggered modification in schedule history
     * 3. Regenerates upcoming ScheduledDose entities with new dose amount
     * 4. Preserves all other schedule properties (pattern, timing, windows)
     *
     * - Parameters:
     *   - titration: The completed titration containing dose change information
     *   - schedule: The schedule to update with new dose amount
     *
     * - Throws: ScheduleServiceError.contextSaveFailed if unable to save changes
     *
     * - Note: Only affects future scheduled doses, not historical doses
     */
    func handleCompletedTitration(_ titration: DoseTitration, schedule: DoseSchedule) throws {
        logger.info(
            "Handling completed titration for schedule \(schedule.id): \(titration.fromDose)mg → \(titration.toDose)mg")

        // TODO: Implement titration completion handling
    }

    // MARK: - Titration Warnings

    /**
     * Generates a user-friendly warning message about upcoming titration.
     *
     * Returns a formatted message if:
     * - Medication profile has an active titration
     * - Titration is scheduled within next 30 days
     *
     * Example: "Your dose will increase to 1.0mg on October 15 per your titration plan"
     *
     * - Parameter schedule: The schedule to check for upcoming titration
     * - Returns: Formatted warning message, or nil if no upcoming titration
     */
    func getTitrationWarning(for schedule: DoseSchedule) -> String? {
        logger.info("Generating titration warning for schedule \(schedule.id)")

        // TODO: Implement warning message generation
        return nil
    }

    // MARK: - Private Helpers

    /**
     * Formats a titration warning message for user display.
     *
     * - Parameters:
     *   - titration: The upcoming titration
     *   - scheduledDate: The date the dose will change
     *
     * - Returns: User-friendly warning message
     */
    private func formatTitrationWarning(titration: DoseTitration, scheduledDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none

        let formattedDate = formatter.string(from: scheduledDate)
        let changeDirection = titration.toDose > titration.fromDose ? "increase" : "decrease"

        return "Your dose will \(changeDirection) to \(titration.toDose)mg on \(formattedDate) per your titration plan"
    }
}
