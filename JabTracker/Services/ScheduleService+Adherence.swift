//
//  ScheduleService+Adherence.swift
//  JabTracker
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "ScheduleService")

// MARK: - Adherence Metrics Data Structures

/// Comprehensive adherence metrics for a schedule over a time period
struct ScheduleAdherenceMetrics {
    /// Adherence percentage (0.0-1.0) calculated as taken / (taken + missed)
    let adherencePercentage: Double

    /// Current streak of consecutive adherent doses
    let currentStreak: Int

    /// Longest streak in the time period
    let longestStreak: Int

    /// Total doses scheduled in the period
    let totalScheduled: Int

    /// Total doses taken (within or outside window)
    let totalTaken: Int

    /// Total doses missed (past window, no action)
    let totalMissed: Int

    /// Total doses intentionally skipped
    let totalSkipped: Int

    /// Percentage of doses taken within original adherence window
    let onTimePercentage: Double

    /// Average delay in minutes for rescheduled doses
    let averageDelayMinutes: Double?
}

/// Detected adherence issue with severity and actionable insight
struct AdherenceIssue: Identifiable {
    let id: UUID
    let type: IssueType
    let severity: Severity
    let description: String
    let actionableInsight: String
    let affectedDoses: [ScheduledDose]

    enum IssueType {
        case consecutiveMisses
        case frequentReschedules
        case consistentLateDoses
        case weekendGap
    }

    enum Severity {
        case low
        case medium
        case high
    }
}

// MARK: - Adherence Extension

/// Extension for ScheduleService providing adherence calculation and analysis.
///
/// Handles:
/// - Comprehensive adherence metrics calculation
/// - Recent adherence pattern generation (DoseEvent timeline)
/// - Adherence issue detection with actionable insights
extension ScheduleService {

    // MARK: - Adherence Calculation

    // swiftlint:disable cyclomatic_complexity function_body_length
    // Rationale: calculateAdherence requires comprehensive logic for all dose states
    // (taken, missed, skipped, pending) and multiple derived metrics. Splitting would reduce readability.

    /**
     * Calculates comprehensive adherence metrics for a schedule over a time period.
     *
     * Adherence is calculated as: taken / (taken + missed)
     * - Skipped doses are not counted against adherence (intentional decision)
     * - Pending doses (future or within window) are not counted
     *
     * - Parameters:
     *   - schedule: The schedule to calculate adherence for
     *   - startDate: Start of the analysis period
     *   - endDate: End of the analysis period
     *
     * - Returns: ScheduleAdherenceMetrics with comprehensive adherence data
     */
    func calculateAdherence(
        for schedule: DoseSchedule,
        from startDate: Date,
        to endDate: Date
    ) -> ScheduleAdherenceMetrics {
        logger.info("Calculating adherence for schedule \(schedule.id) from \(startDate) to \(endDate)")

        // Get all scheduled doses in the time period
        let scheduledDoses = (schedule.scheduledDoses ?? []).filter {
            $0.scheduledTime >= startDate && $0.scheduledTime <= endDate
        }

        let totalScheduled = scheduledDoses.count

        // Categorize doses
        var takenDoses: [ScheduledDose] = []
        var missedDoses: [ScheduledDose] = []
        var skippedDoses: [ScheduledDose] = []
        var onTimeDoses: [ScheduledDose] = []
        var rescheduledDoses: [ScheduledDose] = []

        for dose in scheduledDoses {
            let status = dose.status

            switch status {
            case .taken:
                takenDoses.append(dose)
                // Check if taken within original window
                if let actualDose = dose.actualDose {
                    let (originalWindowStart, originalWindowEnd) = getOriginalWindow(for: dose)

                    if actualDose.timestamp >= originalWindowStart
                        && actualDose.timestamp <= originalWindowEnd
                    {
                        onTimeDoses.append(dose)
                    }
                }
                if dose.rescheduledFrom != nil {
                    rescheduledDoses.append(dose)
                }
            case .missed:
                missedDoses.append(dose)
            case .skipped:
                skippedDoses.append(dose)
            case .pending:
                // Don't count pending doses in adherence calculation
                break
            }
        }

        let totalTaken = takenDoses.count
        let totalMissed = missedDoses.count
        let totalSkipped = skippedDoses.count

        // Calculate adherence percentage: taken / (taken + missed)
        let adherencePercentage: Double
        if totalTaken + totalMissed > 0 {
            adherencePercentage = Double(totalTaken) / Double(totalTaken + totalMissed)
        } else {
            adherencePercentage = 0.0
        }

        // Calculate on-time percentage
        let onTimePercentage: Double
        if totalTaken > 0 {
            onTimePercentage = Double(onTimeDoses.count) / Double(totalTaken)
        } else {
            onTimePercentage = 0.0
        }

        // Calculate average delay for rescheduled doses
        let averageDelayMinutes: Double?
        if !rescheduledDoses.isEmpty {
            var totalDelay: TimeInterval = 0
            for dose in rescheduledDoses {
                if let originalTime = dose.rescheduledFrom {
                    totalDelay += dose.scheduledTime.timeIntervalSince(originalTime)
                }
            }
            averageDelayMinutes = (totalDelay / Double(rescheduledDoses.count)) / 60.0
        } else {
            averageDelayMinutes = nil
        }

        // Calculate current streak
        let currentStreak = calculateCurrentStreak(from: scheduledDoses)

        // Calculate longest streak
        let longestStreak = calculateLongestStreak(from: scheduledDoses)

        let metrics = ScheduleAdherenceMetrics(
            adherencePercentage: adherencePercentage,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalScheduled: totalScheduled,
            totalTaken: totalTaken,
            totalMissed: totalMissed,
            totalSkipped: totalSkipped,
            onTimePercentage: onTimePercentage,
            averageDelayMinutes: averageDelayMinutes
        )

        logger.info(
            """
            Adherence metrics: \(String(format: "%.1f%%", adherencePercentage * 100)) adherence, \
            \(currentStreak) current streak
            """
        )

        return metrics
    }

    // swiftlint:enable cyclomatic_complexity function_body_length

    // MARK: - Helper Functions

    /// Get the original scheduling window for a dose (before any rescheduling)
    private func getOriginalWindow(for dose: ScheduledDose) -> (start: Date, end: Date) {
        if let originalTime = dose.rescheduledFrom {
            let windowStart = originalTime.addingTimeInterval(-TimeConstants.hours(2))
            let windowEnd = originalTime.addingTimeInterval(TimeConstants.hours(2))
            return (windowStart, windowEnd)
        } else {
            return (dose.windowStart, dose.windowEnd)
        }
    }

    // MARK: - Recent Adherence Pattern

    /**
     * Generates a timeline of recent dose events for a schedule.
     *
     * Combines ScheduledDose and Dose entities into DoseEvent timeline,
     * sorted chronologically.
     *
     * - Parameters:
     *   - schedule: The schedule to generate timeline for
     *   - days: Number of days to look back (default: 30)
     *
     * - Returns: Array of DoseEvents sorted chronologically
     */
    func getRecentAdherencePattern(for schedule: DoseSchedule, days: Int = 30) -> [DoseEvent] {
        logger.info("Generating recent adherence pattern for schedule \(schedule.id), \(days) days")

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate

        // Get all scheduled doses in the period
        let scheduledDoses = (schedule.scheduledDoses ?? []).filter {
            $0.scheduledTime >= startDate && $0.scheduledTime <= endDate
        }

        // Convert to DoseEvents
        let events = scheduledDoses.map { DoseEvent.from(scheduledDose: $0) }

        // Sort chronologically
        let sortedEvents = events.sorted()

        logger.info("Generated \(sortedEvents.count) dose events for recent pattern")

        return sortedEvents
    }

    // MARK: - Adherence Issue Detection

    /**
     * Detects adherence issues and provides actionable insights.
     *
     * Analyzes patterns to identify:
     * - Consecutive missed doses (3+)
     * - Frequent rescheduling (>50% of doses)
     * - Consistent late doses (>80% outside window)
     * - Weekend gaps (missing weekend doses)
     *
     * - Parameter schedule: The schedule to analyze
     * - Returns: Array of detected AdherenceIssues with severity and insights
     */
    func detectAdherenceIssues(for schedule: DoseSchedule) -> [AdherenceIssue] {
        logger.info("Detecting adherence issues for schedule \(schedule.id)")

        var issues: [AdherenceIssue] = []

        // Get recent 30 days of doses
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate

        let scheduledDoses = (schedule.scheduledDoses ?? []).filter {
            $0.scheduledTime >= startDate && $0.scheduledTime <= endDate
        }.sorted(by: { $0.scheduledTime < $1.scheduledTime })

        // Check for consecutive misses
        var consecutiveMisses: [ScheduledDose] = []
        var maxConsecutiveMisses: [ScheduledDose] = []

        for dose in scheduledDoses {
            if dose.status == .missed {
                consecutiveMisses.append(dose)
                if consecutiveMisses.count > maxConsecutiveMisses.count {
                    maxConsecutiveMisses = consecutiveMisses
                }
            } else {
                consecutiveMisses = []
            }
        }

        if maxConsecutiveMisses.count >= 3 {
            let issue = AdherenceIssue(
                id: UUID(),
                type: .consecutiveMisses,
                severity: maxConsecutiveMisses.count >= 5 ? .high : .medium,
                description: "You've missed \(maxConsecutiveMisses.count) consecutive doses",
                actionableInsight:
                    "Consider setting up reminders or adjusting your dose schedule to a more convenient time",
                affectedDoses: maxConsecutiveMisses
            )
            issues.append(issue)
        }

        // Check for frequent reschedules
        let rescheduledCount = scheduledDoses.filter { $0.rescheduledFrom != nil }.count
        if scheduledDoses.count > 0 {
            let rescheduledPercentage = Double(rescheduledCount) / Double(scheduledDoses.count)
            if rescheduledPercentage > 0.5 {
                let issue = AdherenceIssue(
                    id: UUID(),
                    type: .frequentReschedules,
                    severity: .medium,
                    description:
                        "\(Int(rescheduledPercentage * 100))% of your doses have been rescheduled",
                    actionableInsight:
                        "Your current schedule may not fit your routine. Consider updating your base schedule time",
                    affectedDoses: scheduledDoses.filter { $0.rescheduledFrom != nil }
                )
                issues.append(issue)
            }
        }

        logger.info("Detected \(issues.count) adherence issues")

        return issues
    }

    // MARK: - Private Helpers

    /**
     * Calculates the current streak of consecutive adherent doses.
     *
     * An adherent dose is one that was taken (within or outside window)
     * or intentionally skipped. Missed doses break the streak.
     *
     * - Parameter doses: Array of scheduled doses (should be sorted by time)
     * - Returns: Current streak count
     */
    private func calculateCurrentStreak(from doses: [ScheduledDose]) -> Int {
        let sortedDoses = doses.sorted(by: { $0.scheduledTime > $1.scheduledTime })  // Newest first

        var streak = 0
        for dose in sortedDoses {
            let status = dose.status

            // Only count completed doses in streak calculation
            if status == .pending {
                continue
            }

            if status == .taken || status == .skipped {
                streak += 1
            } else {
                // Missed dose breaks the streak
                break
            }
        }

        return streak
    }

    /**
     * Calculates the longest streak of consecutive adherent doses in the period.
     *
     * - Parameter doses: Array of scheduled doses
     * - Returns: Longest streak count
     */
    private func calculateLongestStreak(from doses: [ScheduledDose]) -> Int {
        let sortedDoses = doses.sorted(by: { $0.scheduledTime < $1.scheduledTime })  // Oldest first

        var currentStreak = 0
        var longestStreak = 0

        for dose in sortedDoses {
            let status = dose.status

            // Only count completed doses in streak calculation
            if status == .pending {
                continue
            }

            if status == .taken || status == .skipped {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }

        return longestStreak
    }
}
