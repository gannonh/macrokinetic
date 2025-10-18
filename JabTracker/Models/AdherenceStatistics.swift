//
//  AdherenceStatistics.swift
//  JabTracker
//
//  Model for calculating and representing adherence statistics, streak information,
//  and monthly dose summaries for calendar integration
//

import Foundation

/// Result of streak calculations
struct StreakResult {
    let current: Int
    let longest: Int
    let isActive: Bool
}

/// Comprehensive adherence statistics for a given time period
struct AdherenceStatistics {
    // MARK: - Basic Statistics

    /// Total number of doses taken in the period
    let totalDoses: Int

    /// Number of doses marked as skipped
    let skippedDoses: Int

    /// Number of scheduled doses (based on medication frequency)
    let scheduledDoses: Int

    /// Adherence rate as percentage (0.0 to 1.0)
    var adherenceRate: Double {
        guard self.scheduledDoses > 0 else { return 0.0 }
        let takenDoses = self.totalDoses - self.skippedDoses
        return Double(takenDoses) / Double(self.scheduledDoses)
    }

    /// Adherence rate as percentage string (0% to 100%)
    var adherenceRatePercentage: String {
        let percentage = self.adherenceRate * 100
        return String(format: "%.1f%%", percentage)
    }

    // MARK: - Dose Information

    /// Average dose amount for taken doses
    let averageDose: Double

    /// Total medication amount administered in the period
    let totalMedicationAmount: Double

    /// Range of dose amounts (min, max)
    let doseRange: (min: Double, max: Double)?

    // MARK: - Streak Information

    /// Current consecutive days with taken doses
    let currentStreak: Int

    /// Longest streak of consecutive days with doses in the period
    let longestStreak: Int

    /// Whether the current streak is still active (most recent day has dose)
    let isCurrentStreakActive: Bool

    // MARK: - Site Distribution

    /// Distribution of injection sites used
    let siteDistribution: [String: Int]

    /// Most frequently used injection site
    var mostUsedSite: String? {
        self.siteDistribution.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - Time Period

    /// Start date of the statistics period
    let periodStart: Date

    /// End date of the statistics period
    let periodEnd: Date

    /// Duration of the period in days
    var periodDays: Int {
        let components = Calendar.current.dateComponents(
            [.day], from: self.periodStart, to: self.periodEnd)
        return max(1, components.day ?? 1)
    }

    // MARK: - Stream C: Schedule Adherence Statistics (Issue #178)

    /// Total scheduled doses from DoseSchedule
    let totalScheduledDoses: Int

    /// Scheduled doses that were taken
    let takenScheduledDoses: Int

    /// Scheduled doses that were missed
    let missedScheduledDoses: Int

    /// Scheduled doses that were intentionally skipped
    let skippedScheduledDoses: Int

    /// Schedule adherence rate (taken / (taken + missed))
    /// Skipped doses are not counted against adherence
    var scheduleAdherenceRate: Double {
        let denominator = self.takenScheduledDoses + self.missedScheduledDoses
        guard denominator > 0 else { return 0.0 }
        return Double(self.takenScheduledDoses) / Double(denominator)
    }

    /// Schedule adherence rate as percentage string (0% to 100%)
    var scheduleAdherenceRatePercentage: String {
        let percentage = self.scheduleAdherenceRate * 100
        return String(format: "%.1f%%", percentage)
    }

    // MARK: - Initialization

    init(
        totalDoses: Int,
        skippedDoses: Int,
        scheduledDoses: Int,
        averageDose: Double,
        totalMedicationAmount: Double,
        doseRange: (min: Double, max: Double)?,
        currentStreak: Int,
        longestStreak: Int,
        isCurrentStreakActive: Bool,
        siteDistribution: [String: Int],
        periodStart: Date,
        periodEnd: Date,
        // Stream C: Schedule adherence parameters
        totalScheduledDoses: Int = 0,
        takenScheduledDoses: Int = 0,
        missedScheduledDoses: Int = 0,
        skippedScheduledDoses: Int = 0
    ) {
        self.totalDoses = totalDoses
        self.skippedDoses = skippedDoses
        self.scheduledDoses = scheduledDoses
        self.averageDose = averageDose
        self.totalMedicationAmount = totalMedicationAmount
        self.doseRange = doseRange
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.isCurrentStreakActive = isCurrentStreakActive
        self.siteDistribution = siteDistribution
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        // Stream C: Schedule adherence assignments
        self.totalScheduledDoses = totalScheduledDoses
        self.takenScheduledDoses = takenScheduledDoses
        self.missedScheduledDoses = missedScheduledDoses
        self.skippedScheduledDoses = skippedScheduledDoses
    }
}

// MARK: - Empty State

extension AdherenceStatistics {
    /// Empty statistics for periods with no data
    static func empty(periodStart: Date, periodEnd: Date) -> AdherenceStatistics {
        AdherenceStatistics(
            totalDoses: 0,
            skippedDoses: 0,
            scheduledDoses: 0,
            averageDose: 0.0,
            totalMedicationAmount: 0.0,
            doseRange: nil,
            currentStreak: 0,
            longestStreak: 0,
            isCurrentStreakActive: false,
            siteDistribution: [:],
            periodStart: periodStart,
            periodEnd: periodEnd)
    }
}

// MARK: - Stream C: Schedule Metrics Helper (Issue #178)

/// Helper struct for schedule adherence metrics to avoid tuple complexity
private struct ScheduleMetricsHelper {
    let totalScheduled: Int
    let taken: Int
    let missed: Int
    let skipped: Int
}

// MARK: - Statistics Calculator

enum AdherenceStatisticsCalculator {
    // MARK: - Stream C: Schedule Integration (Issue #178)

    /// Calculate comprehensive adherence statistics with schedule integration
    static func calculate(
        doses: [Dose],
        periodStart: Date,
        periodEnd: Date,
        medicationFrequency: DoseFrequency = .weekly,
        scheduleService: ScheduleService? = nil,
        schedule: DoseSchedule? = nil
    ) -> AdherenceStatistics {
        // Calculate schedule adherence if schedule provided
        var scheduleMetrics: ScheduleMetricsHelper?

        if let scheduleService = scheduleService, let schedule = schedule {
            let adherenceMetrics = scheduleService.calculateAdherence(
                for: schedule,
                from: periodStart,
                to: periodEnd
            )

            scheduleMetrics = ScheduleMetricsHelper(
                totalScheduled: adherenceMetrics.totalScheduled,
                taken: adherenceMetrics.totalTaken - adherenceMetrics.totalSkipped,  // Only count taken, not skipped
                missed: adherenceMetrics.totalMissed,
                skipped: adherenceMetrics.totalSkipped
            )
        }

        return self.calculateInternal(
            doses: doses,
            periodStart: periodStart,
            periodEnd: periodEnd,
            medicationFrequency: medicationFrequency,
            scheduleMetrics: scheduleMetrics
        )
    }

    /// Internal calculation method
    private static func calculateInternal(
        doses: [Dose],
        periodStart: Date,
        periodEnd: Date,
        medicationFrequency: DoseFrequency = .weekly,
        scheduleMetrics: ScheduleMetricsHelper?
    ) -> AdherenceStatistics {
        // Filter doses to the specified period
        let periodDoses = doses.filter { dose in
            dose.timestamp >= periodStart && dose.timestamp <= periodEnd
        }

        // Basic counts
        let totalDoses = periodDoses.count
        let skippedDoses = periodDoses.filter(\.skipped).count
        let takenDoses = periodDoses.filter { !$0.skipped }

        // Calculate scheduled doses based on frequency and period
        let scheduledDoses = self.calculateScheduledDoses(
            periodStart: periodStart,
            periodEnd: periodEnd,
            frequency: medicationFrequency)

        // Dose amount calculations
        let doseAmounts = takenDoses.map(\.amount)
        let averageDose =
            doseAmounts.isEmpty ? 0.0 : doseAmounts.reduce(0, +) / Double(doseAmounts.count)
        let totalMedicationAmount = doseAmounts.reduce(0, +)
        let doseRange: (min: Double, max: Double)? = {
            guard !doseAmounts.isEmpty,
                let minDose = doseAmounts.min(),
                let maxDose = doseAmounts.max()
            else {
                return nil
            }
            return (min: minDose, max: maxDose)
        }()

        // Site distribution
        let siteDistribution = self.calculateSiteDistribution(doses: takenDoses)

        // Streak calculations
        let streakResult = self.calculateStreaks(
            doses: takenDoses,
            periodStart: periodStart,
            periodEnd: periodEnd)
        let currentStreak = streakResult.current
        let longestStreak = streakResult.longest
        let isCurrentStreakActive = streakResult.isActive

        // MARK: - Stream C: Include Schedule Metrics
        return AdherenceStatistics(
            totalDoses: totalDoses,
            skippedDoses: skippedDoses,
            scheduledDoses: scheduledDoses,
            averageDose: averageDose,
            totalMedicationAmount: totalMedicationAmount,
            doseRange: doseRange,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            isCurrentStreakActive: isCurrentStreakActive,
            siteDistribution: siteDistribution,
            periodStart: periodStart,
            periodEnd: periodEnd,
            // Stream C: Schedule adherence metrics
            totalScheduledDoses: scheduleMetrics?.totalScheduled ?? 0,
            takenScheduledDoses: scheduleMetrics?.taken ?? 0,
            missedScheduledDoses: scheduleMetrics?.missed ?? 0,
            skippedScheduledDoses: scheduleMetrics?.skipped ?? 0)
    }

    // MARK: - Note
    // Private calculation methods are in extension:
    // - AdherenceStatistics+Calculations.swift
}
