//
//  ScheduleService+Projection.swift
//  JabTracker
//
//  Created by Claude Code on 2025-10-06.
//

// swiftlint:disable force_unwrapping
// Rationale: All force unwraps are Calendar date operations with valid components
// These operations are guaranteed to succeed and cannot return nil

import Foundation
import SwiftData
import os

private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "ScheduleService")

// MARK: - Schedule Projection Extension

extension ScheduleService {

    // MARK: - Schedule Dose Generation

    /**
     * Generates scheduled doses for a given schedule within a date range.
     *
     * Supports multiple scheduling patterns:
     * - Weekly: Doses on specific day of week at configured time
     * - Split-dose: Multiple doses per scheduled day
     * - Custom: User-defined recurrence patterns
     *
     * - Parameters:
     *   - schedule: The DoseSchedule to generate doses for
     *   - from: Start date for dose generation (inclusive)
     *   - to: End date for dose generation (inclusive)
     *
     * - Returns: Array of ScheduledDose entities sorted chronologically
     *
     * - Note: Does not persist doses to SwiftData - returns in-memory entities
     * - Important: Must complete in <100ms for 365-day projections
     */
    func generateScheduledDoses(
        for schedule: DoseSchedule,
        from startDate: Date,
        to endDate: Date
    ) -> [ScheduledDose] {
        // Return empty if date range is entirely before schedule creation
        if endDate < schedule.createdAt {
            return []
        }

        // Decode schedule configuration
        guard
            let config: ScheduleConfiguration = {
                do {
                    return try decodeScheduleConfiguration(schedule)
                } catch {
                    logger.error("Failed to decode schedule configuration for schedule \(schedule.id): \(error)")
                    return nil
                }
            }()
        else {
            return []
        }

        // Adjust start date to schedule creation if needed
        let effectiveStartDate = max(startDate, schedule.createdAt)

        // Generate doses based on pattern type
        switch schedule.patternType {
        case .daily:
            // Daily doses use same logic as weekly but with interval of 1 day
            return generateWeeklyDoses(
                schedule: schedule,
                config: config,
                from: effectiveStartDate,
                to: endDate
            )

        case .weekly:
            return generateWeeklyDoses(
                schedule: schedule,
                config: config,
                from: effectiveStartDate,
                to: endDate
            )

        case .splitDose:
            return generateSplitDoses(
                schedule: schedule,
                config: config,
                from: effectiveStartDate,
                to: endDate
            )

        case .custom:
            return generateCustomDoses(
                schedule: schedule,
                config: config,
                from: effectiveStartDate,
                to: endDate
            )
        }
    }

    /**
     * Refreshes the upcomingDoses property with scheduled doses for the next N days.
     *
     * Updates the observable upcomingDoses array with all scheduled doses across
     * all active schedules within the specified time window.
     *
     * - Parameter daysAhead: Number of days to look ahead (default: 30)
     *
     * - Note: Updates observable property for SwiftUI binding
     */
    func refreshUpcomingDoses(daysAhead: Int = 30) {
        print("🔍 [ScheduleService] refreshUpcomingDoses() called")
        print("🔍 [ScheduleService] activeSchedules.count = \(activeSchedules.count)")

        let now = Date()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: daysAhead, to: now)!
        print("🔍 [ScheduleService] Looking for doses from \(now) to \(cutoffDate)")

        var allUpcomingDoses: [ScheduledDose] = []

        for schedule in activeSchedules {
            print("🔍 [ScheduleService] Generating doses for schedule \(schedule.id)")
            print("🔍 [ScheduleService] Schedule pattern: \(schedule.patternType)")
            print("🔍 [ScheduleService] Schedule createdAt: \(schedule.createdAt)")
            let doses = generateScheduledDoses(for: schedule, from: now, to: cutoffDate)
            print("🔍 [ScheduleService] Generated \(doses.count) doses for this schedule")
            allUpcomingDoses.append(contentsOf: doses)
        }

        print("🔍 [ScheduleService] Total upcoming doses generated: \(allUpcomingDoses.count)")

        // Sort chronologically
        upcomingDoses = allUpcomingDoses.sorted { $0.scheduledTime < $1.scheduledTime }
    }

    /**
     * Gets the next scheduled dose for a specific schedule.
     *
     * Calculates the next dose based on the last actually taken dose when available,
     * ensuring projections align with actual dosing behavior rather than schedule
     * creation date.
     *
     * - Parameter schedule: The schedule to find next dose for
     * - Returns: Next ScheduledDose after current time, or nil if none
     */
    func getNextScheduledDose(for schedule: DoseSchedule) -> ScheduledDose? {
        // Only look for next dose if schedule is active
        guard schedule.isActive else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()

        // Find the last taken dose from actual Dose records
        // (ScheduledDose records are not persisted, so use Dose model directly)
        let lastTakenDoseTimestamp: Date? = schedule.medicationProfile?.doses?
            .filter { !$0.skipped }
            .map { $0.timestamp }
            .max()

        // If there's a taken dose, calculate next from that
        if let lastTakenTime = lastTakenDoseTimestamp {
            // Get the interval from config
            guard
                let config: ScheduleConfiguration = {
                    do {
                        return try decodeScheduleConfiguration(schedule)
                    } catch {
                        logger.error("Failed to decode schedule configuration for schedule \(schedule.id): \(error)")
                        return nil
                    }
                }()
            else {
                return nil
            }

            // Calculate next dose: last taken time + interval
            // Use minutes for split dose (supports fractional days like 3.5 days = 5040 minutes)
            // Use days for other patterns
            let intervalMinutes =
                schedule.patternType == .splitDose
                ? (config.splitIntervalMinutes ?? 0)
                : config.interval * 24 * 60  // Convert days to minutes

            // Guard against infinite loop if interval is 0
            guard intervalMinutes > 0 else {
                return nil
            }

            var nextDoseDate = lastTakenTime

            // Keep adding intervals until we're past now
            while nextDoseDate <= now {
                nextDoseDate = calendar.date(byAdding: .minute, value: intervalMinutes, to: nextDoseDate)!
            }

            // Handle pause state: if next dose falls within paused period, advance or return nil
            if let pausedAt = schedule.pausedAt, nextDoseDate >= pausedAt {
                if let pausedUntil = schedule.pausedUntil {
                    // Finite pause: advance to pausedUntil if needed
                    if nextDoseDate < pausedUntil {
                        nextDoseDate = pausedUntil
                    }
                } else {
                    // Indefinite pause: no next dose
                    return nil
                }
            }

            // Create the scheduled dose for this time
            let windowStart = calendar.date(
                byAdding: .minute,
                value: -config.windowMinutesBefore,
                to: nextDoseDate
            )!
            let windowEnd = calendar.date(
                byAdding: .minute,
                value: config.windowMinutesAfter,
                to: nextDoseDate
            )!

            let scheduledDose = ScheduledDose(
                scheduledTime: nextDoseDate,
                doseAmount: config.doseAmount,
                windowStart: windowStart,
                windowEnd: windowEnd
            )
            scheduledDose.schedule = schedule
            return scheduledDose
        }

        // No doses taken yet - fall back to original projection logic
        let lookAheadDate = calendar.date(byAdding: .day, value: 90, to: now)!
        let upcomingDoses = generateScheduledDoses(for: schedule, from: now, to: lookAheadDate)
        return upcomingDoses.first { $0.scheduledTime > now }
    }

    // MARK: - Private Pattern Generators

    /**
     * Generates weekly scheduled doses.
     *
     * - Parameters:
     *   - schedule: Parent DoseSchedule
     *   - config: Decoded schedule configuration
     *   - from: Start date for generation
     *   - to: End date for generation
     *
     * - Returns: Array of ScheduledDose entities
     */
    private func generateWeeklyDoses(
        schedule: DoseSchedule,
        config: ScheduleConfiguration,
        from startDate: Date,
        to endDate: Date
    ) -> [ScheduledDose] {
        var doses: [ScheduledDose] = []
        let calendar = Calendar.current

        // Check for actual dose history to anchor projections correctly
        // This ensures future doses align with actual dosing behavior, not stored patterns
        let lastActualDoseTime: Date? = schedule.medicationProfile?.doses?
            .filter { !$0.skipped }
            .map { $0.timestamp }
            .max()

        // Start from the requested start date
        var currentDate = startDate

        // If we have actual dose history, calculate future doses from the last dose
        if let lastDoseTime = lastActualDoseTime {
            // Start from last dose and add intervals until we're past startDate
            var projectedDate = lastDoseTime

            // Set the time of day from config
            var components = calendar.dateComponents([.year, .month, .day], from: projectedDate)
            components.hour = config.timeOfDay.hour
            components.minute = config.timeOfDay.minute
            components.second = 0
            projectedDate = calendar.date(from: components) ?? projectedDate

            // Keep adding intervals until we reach or pass startDate
            while projectedDate < startDate {
                projectedDate = calendar.date(byAdding: .day, value: config.interval, to: projectedDate)!
            }
            currentDate = projectedDate
        } else if let targetWeekday = config.dayOfWeek {
            // No dose history - use pattern-based calculation
            // Find next occurrence of target weekday from currentDate
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)
            components.weekday = targetWeekday
            components.hour = config.timeOfDay.hour
            components.minute = config.timeOfDay.minute
            components.second = 0

            if let firstDose = calendar.date(from: components) {
                // If the calculated date is before our start, move to next week
                if firstDose < currentDate {
                    currentDate = calendar.date(byAdding: .day, value: 7, to: firstDose)!
                } else {
                    currentDate = firstDose
                }
            }
        } else {
            // No specific weekday - use start date with configured time
            var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
            components.hour = config.timeOfDay.hour
            components.minute = config.timeOfDay.minute
            components.second = 0
            currentDate = calendar.date(from: components)!
        }

        // Generate doses at interval until end date
        // Use tolerance to prevent boundary date inclusion due to floating-point precision
        let tolerance: TimeInterval = 60 * 60  // 1 hour tolerance
        while currentDate < endDate && (endDate.timeIntervalSince(currentDate) > tolerance) {
            // Skip if schedule is paused during this time
            if let pausedUntil = schedule.pausedUntil,
                let pausedAt = schedule.pausedAt,
                currentDate >= pausedAt && currentDate < pausedUntil
            {
                // Skip this dose and advance to next interval
                currentDate = calendar.date(byAdding: .day, value: config.interval, to: currentDate)!
                continue
            }

            // Calculate scheduling window
            let windowStart = calendar.date(
                byAdding: .minute,
                value: -config.windowMinutesBefore,
                to: currentDate
            )!

            let windowEnd = calendar.date(
                byAdding: .minute,
                value: config.windowMinutesAfter,
                to: currentDate
            )!

            // Create scheduled dose (not persisted to SwiftData)
            let scheduledDose = ScheduledDose(
                scheduledTime: currentDate,
                doseAmount: config.doseAmount,
                windowStart: windowStart,
                windowEnd: windowEnd
            )
            scheduledDose.schedule = schedule

            doses.append(scheduledDose)

            // Advance to next dose
            currentDate = calendar.date(byAdding: .day, value: config.interval, to: currentDate)!
        }

        return doses
    }

    /**
     * Generates split-dose scheduled doses.
     *
     * Creates doses at splitInterval apart (e.g., every 3.5 days for twice-weekly dosing).
     *
     * - Parameters:
     *   - schedule: Parent DoseSchedule
     *   - config: Decoded schedule configuration
     *   - from: Start date for generation
     *   - to: End date for generation
     *
     * - Returns: Array of ScheduledDose entities
     */
    private func generateSplitDoses(
        schedule: DoseSchedule,
        config: ScheduleConfiguration,
        from startDate: Date,
        to endDate: Date
    ) -> [ScheduledDose] {
        guard let splitInterval = config.splitIntervalMinutes else {
            return []
        }

        var doses: [ScheduledDose] = []
        let calendar = Calendar.current

        var currentDate = startDate

        // Align to start of day with configured time
        var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
        components.hour = config.timeOfDay.hour
        components.minute = config.timeOfDay.minute
        components.second = 0
        let alignedDate = calendar.date(from: components)!

        // For schedule projection, start from the aligned date for the first day.
        // This includes the scheduled dose even if the exact time has passed,
        // which is correct for projecting what the schedule produces.
        // Only skip forward if the aligned date is on a PREVIOUS calendar day.
        if alignedDate < startDate && !calendar.isDate(alignedDate, inSameDayAs: startDate) {
            // Aligned date is on a previous day, calculate intervals needed
            let intervalSeconds = TimeInterval(splitInterval * 60)
            let timeSinceAligned = startDate.timeIntervalSince(alignedDate)
            let intervalsNeeded = Int(ceil(timeSinceAligned / intervalSeconds))
            currentDate = calendar.date(
                byAdding: .minute,
                value: splitInterval * intervalsNeeded,
                to: alignedDate
            )!
        } else {
            // Same day or aligned is in the future - use aligned date
            currentDate = alignedDate
        }

        // Generate doses at splitInterval apart
        // Use tolerance to prevent boundary date inclusion due to floating-point precision
        let tolerance: TimeInterval = 60 * 60  // 1 hour tolerance
        while currentDate < endDate && (endDate.timeIntervalSince(currentDate) > tolerance) {
            // Skip if paused
            if let pausedUntil = schedule.pausedUntil,
                let pausedAt = schedule.pausedAt,
                currentDate >= pausedAt && currentDate < pausedUntil
            {
                currentDate = calendar.date(byAdding: .minute, value: splitInterval, to: currentDate)!
                continue
            }

            // Calculate scheduling window
            let windowStart = calendar.date(
                byAdding: .minute,
                value: -config.windowMinutesBefore,
                to: currentDate
            )!

            let windowEnd = calendar.date(
                byAdding: .minute,
                value: config.windowMinutesAfter,
                to: currentDate
            )!

            // Create scheduled dose
            let scheduledDose = ScheduledDose(
                scheduledTime: currentDate,
                doseAmount: config.doseAmount,
                windowStart: windowStart,
                windowEnd: windowEnd
            )
            scheduledDose.schedule = schedule

            doses.append(scheduledDose)

            // Advance by splitInterval (e.g., 3.5 days for twice-weekly)
            currentDate = calendar.date(byAdding: .minute, value: splitInterval, to: currentDate)!
        }

        return doses
    }

    /**
     * Generates custom recurrence pattern scheduled doses.
     *
     * - Parameters:
     *   - schedule: Parent DoseSchedule
     *   - config: Decoded schedule configuration
     *   - from: Start date for generation
     *   - to: End date for generation
     *
     * - Returns: Array of ScheduledDose entities
     */
    private func generateCustomDoses(
        schedule: DoseSchedule,
        config: ScheduleConfiguration,
        from startDate: Date,
        to endDate: Date
    ) -> [ScheduledDose] {
        // For custom patterns, use the interval from config
        // (customRecurrence provides metadata but we use interval for actual scheduling)
        var doses: [ScheduledDose] = []
        let calendar = Calendar.current

        var currentDate = startDate

        // Align to start date with configured time
        var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
        components.hour = config.timeOfDay.hour
        components.minute = config.timeOfDay.minute
        components.second = 0
        currentDate = calendar.date(from: components)!

        // Generate doses at configured interval
        // Use tolerance to prevent boundary date inclusion due to floating-point precision
        let tolerance: TimeInterval = 60 * 60  // 1 hour tolerance
        while currentDate < endDate && (endDate.timeIntervalSince(currentDate) > tolerance) {
            // Skip if paused
            if let pausedUntil = schedule.pausedUntil,
                let pausedAt = schedule.pausedAt,
                currentDate >= pausedAt && currentDate < pausedUntil
            {
                currentDate = calendar.date(byAdding: .day, value: config.interval, to: currentDate)!
                continue
            }

            let windowStart = calendar.date(
                byAdding: .minute,
                value: -config.windowMinutesBefore,
                to: currentDate
            )!

            let windowEnd = calendar.date(
                byAdding: .minute,
                value: config.windowMinutesAfter,
                to: currentDate
            )!

            let scheduledDose = ScheduledDose(
                scheduledTime: currentDate,
                doseAmount: config.doseAmount,
                windowStart: windowStart,
                windowEnd: windowEnd
            )
            scheduledDose.schedule = schedule

            doses.append(scheduledDose)

            // Advance by interval
            currentDate = calendar.date(byAdding: .day, value: config.interval, to: currentDate)!
        }

        return doses
    }
}

// swiftlint:enable force_unwrapping
