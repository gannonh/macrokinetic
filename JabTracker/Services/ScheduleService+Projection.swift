//
//  ScheduleService+Projection.swift
//  JabTracker
//
//  Created by Claude Code on 2025-10-06.
//

// swiftlint:disable force_unwrapping
// Rationale: All force unwraps are Calendar date operations with valid components
// These operations are guaranteed to succeed and cannot return nil
//
// swiftlint:disable function_parameter_count
// Rationale: Split-dose generation requires all schedule configuration parameters

import Foundation
import SwiftData

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
        // Decode schedule configuration
        guard let config = try? decodeScheduleConfiguration(schedule) else {
            return []
        }

        // Generate doses based on pattern type
        switch schedule.patternType {
        case .weekly:
            return generateWeeklyDoses(
                schedule: schedule,
                config: config,
                from: startDate,
                to: endDate
            )

        case .splitDose:
            return generateSplitDoses(
                schedule: schedule,
                config: config,
                from: startDate,
                to: endDate
            )

        case .custom:
            return generateCustomDoses(
                schedule: schedule,
                config: config,
                from: startDate,
                to: endDate
            )

        default:
            return []
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
        let now = Date()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: daysAhead, to: now)!

        var allUpcomingDoses: [ScheduledDose] = []

        for schedule in activeSchedules {
            let doses = generateScheduledDoses(for: schedule, from: now, to: cutoffDate)
            allUpcomingDoses.append(contentsOf: doses)
        }

        // Sort chronologically
        upcomingDoses = allUpcomingDoses.sorted { $0.scheduledTime < $1.scheduledTime }
    }

    /**
     * Gets the next scheduled dose for a specific schedule.
     *
     * - Parameter schedule: The schedule to find next dose for
     * - Returns: Next ScheduledDose after current time, or nil if none
     */
    func getNextScheduledDose(for schedule: DoseSchedule) -> ScheduledDose? {
        // Only look for next dose if schedule is active
        guard schedule.isActive else {
            return nil
        }

        let now = Date()
        let lookAheadDate = Calendar.current.date(byAdding: .day, value: 90, to: now)!

        let upcomingDoses = generateScheduledDoses(for: schedule, from: now, to: lookAheadDate)

        // Return first dose in future
        return upcomingDoses.first { $0.scheduledTime > now }
    }

    // MARK: - Private Pattern Generators

    // swiftlint:disable function_body_length
    // Rationale: generateWeeklyDoses algorithm requires complete pattern handling
    // (weekday alignment, pause periods, window calculations) in single coherent flow.

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

        // Start from the requested start date
        var currentDate = startDate

        // If dayOfWeek is specified, find the first occurrence of that weekday
        if let targetWeekday = config.dayOfWeek {
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
        while currentDate <= endDate {
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

    // swiftlint:enable function_body_length

    /**
     * Generates split-dose scheduled doses.
     *
     * Creates multiple doses per scheduled day with configured intervals between them.
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
        guard let splitCount = config.splitDoseCount,
            let splitInterval = config.splitIntervalMinutes
        else {
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
        currentDate = calendar.date(from: components)!

        // Generate doses at daily interval
        while currentDate <= endDate {
            // Skip if paused
            if let pausedUntil = schedule.pausedUntil,
                let pausedAt = schedule.pausedAt,
                currentDate >= pausedAt && currentDate < pausedUntil
            {
                currentDate = calendar.date(byAdding: .day, value: config.interval, to: currentDate)!
                continue
            }

            // Generate split doses for this day
            let splitDoses = generateSplitDosesForDay(
                baseTime: currentDate,
                splitCount: splitCount,
                splitInterval: splitInterval,
                config: config,
                schedule: schedule,
                endDate: endDate
            )
            doses.append(contentsOf: splitDoses)

            // Advance to next day
            currentDate = calendar.date(byAdding: .day, value: config.interval, to: currentDate)!
        }

        return doses
    }

    /**
     * Helper to generate split doses for a single day.
     */
    private func generateSplitDosesForDay(
        baseTime: Date,
        splitCount: Int,
        splitInterval: Int,
        config: ScheduleConfiguration,
        schedule: DoseSchedule,
        endDate: Date
    ) -> [ScheduledDose] {
        var doses: [ScheduledDose] = []
        let calendar = Calendar.current

        for splitIndex in 0..<splitCount {
            let doseTime = calendar.date(
                byAdding: .minute,
                value: splitInterval * splitIndex,
                to: baseTime
            )!

            // Only add if within date range
            if doseTime <= endDate {
                let windowStart = calendar.date(
                    byAdding: .minute,
                    value: -config.windowMinutesBefore,
                    to: doseTime
                )!

                let windowEnd = calendar.date(
                    byAdding: .minute,
                    value: config.windowMinutesAfter,
                    to: doseTime
                )!

                let scheduledDose = ScheduledDose(
                    scheduledTime: doseTime,
                    doseAmount: config.doseAmount,
                    windowStart: windowStart,
                    windowEnd: windowEnd
                )
                scheduledDose.schedule = schedule

                doses.append(scheduledDose)
            }
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
        while currentDate <= endDate {
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

// swiftlint:enable force_unwrapping function_parameter_count
