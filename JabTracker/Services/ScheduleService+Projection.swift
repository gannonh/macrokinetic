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
     * Refreshes the upcomingDoses property with the nearest scheduled doses after `now`.
     *
     * Generating a dose for a stored schedule inserts it into the context, so this reconciles
     * persisted future doses: a projected time keeps its existing row (and id, which a delivered
     * reminder points to) but takes the projected amount and window, and unacted future rows the
     * projection no longer produces are deleted.
     *
     * - Parameters:
     *   - now: Start of the window (exclusive)
     *   - daysAhead: Number of days to look ahead (default: 30)
     *   - limit: Maximum number of doses to keep
     */
    func refreshUpcomingDoses(from now: Date = Date(), daysAhead: Int = 30, limit: Int = .max) {
        // Other ScheduleService instances may have changed schedules since this one loaded them
        loadActiveSchedules()
        let cutoffDate = calendar.date(byAdding: .day, value: daysAhead, to: now)!
        let persisted =
            (try? context.fetch(FetchDescriptor<ScheduledDose>(predicate: #Predicate { $0.scheduledTime > now })))
            ?? []
        let slot = { (dose: ScheduledDose) in "\(dose.schedule?.id.uuidString ?? "")|\(dose.scheduledTime)" }
        let persistedBySlot = Dictionary(persisted.map { (slot($0), $0) }, uniquingKeysWith: { first, _ in first })

        let unacted = { (dose: ScheduledDose) in
            dose.actualDose == nil && dose.skippedAt == nil && dose.rescheduledFrom == nil
        }

        let generated = activeSchedules.flatMap { generateScheduledDoses(for: $0, from: now, to: cutoffDate) }
        upcomingDoses = generated.filter { $0.scheduledTime > now }
            .sorted { $0.scheduledTime < $1.scheduledTime }
            .prefix(limit)
            .map { projected in
                guard let row = persistedBySlot[slot(projected)] else { return projected }
                // A taken or skipped dose keeps the amount and window it was recorded against
                guard unacted(row) else { return row }
                row.doseAmount = projected.doseAmount
                row.windowStart = projected.windowStart
                row.windowEnd = projected.windowEnd
                return row
            }

        let kept = Set(upcomingDoses.map(\.id))
        for dose in generated + persisted where !kept.contains(dose.id) && unacted(dose) {
            context.delete(dose)
        }
        do {
            try context.save()
        } catch {
            logger.error("Failed to save upcoming doses: \(error.localizedDescription)")
        }
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
            if let pausedAt = schedule.pausedAt,
                currentDate >= pausedAt && currentDate < schedule.pausedUntil ?? .distantFuture
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

        // Administration n falls n × splitInterval after the first one in local wall-clock time, so a
        // daylight-saving change keeps the chosen time of day. Aligned to the schedule's first day so every
        // refresh keeps the same cadence.
        let firstDay = calendar.dateComponents([.year, .month, .day], from: schedule.createdAt)
        let administration = { (index: Int) -> Date in
            let minutes = config.timeOfDay.hour * 60 + config.timeOfDay.minute + index * splitInterval
            var components = firstDay
            components.day! += minutes / 1440
            components.hour = minutes % 1440 / 60
            components.minute = minutes % 60
            components.second = 0
            return self.calendar.date(from: components)!
        }

        // For schedule projection, start from the first administration on the first day.
        // This includes the scheduled dose even if the exact time has passed,
        // which is correct for projecting what the schedule produces.
        // Only skip forward if the first administration is on a PREVIOUS calendar day.
        var index = 0
        let alignedDate = administration(0)
        if alignedDate < startDate && !calendar.isDate(alignedDate, inSameDayAs: startDate) {
            index = Int(startDate.timeIntervalSince(alignedDate) / TimeInterval(splitInterval * 60))
            while administration(index) < startDate { index += 1 }
        }
        var currentDate = administration(index)

        // Generate doses at splitInterval apart
        // Use tolerance to prevent boundary date inclusion due to floating-point precision
        let tolerance: TimeInterval = 60 * 60  // 1 hour tolerance
        while currentDate < endDate && (endDate.timeIntervalSince(currentDate) > tolerance) {
            // Skip if paused
            if let pausedAt = schedule.pausedAt,
                currentDate >= pausedAt && currentDate < schedule.pausedUntil ?? .distantFuture
            {
                index += 1
                currentDate = administration(index)
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
            index += 1
            currentDate = administration(index)
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

        // Align to the schedule's first day so every refresh keeps the same cadence
        var components = calendar.dateComponents([.year, .month, .day], from: schedule.createdAt)
        components.hour = config.timeOfDay.hour
        components.minute = config.timeOfDay.minute
        components.second = 0
        var currentDate = calendar.date(from: components)!
        while config.interval > 0 && currentDate < calendar.startOfDay(for: startDate) {
            currentDate = calendar.date(byAdding: .day, value: config.interval, to: currentDate)!
        }

        // Generate doses at configured interval
        // Use tolerance to prevent boundary date inclusion due to floating-point precision
        let tolerance: TimeInterval = 60 * 60  // 1 hour tolerance
        while currentDate < endDate && (endDate.timeIntervalSince(currentDate) > tolerance) {
            // Skip if paused
            if let pausedAt = schedule.pausedAt,
                currentDate >= pausedAt && currentDate < schedule.pausedUntil ?? .distantFuture
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
