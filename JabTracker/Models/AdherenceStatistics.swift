//
//  AdherenceStatistics.swift
//  JabTracker
//
//  Model for calculating and representing adherence statistics, streak information,
//  and monthly dose summaries for calendar integration
//

import Foundation

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
        guard scheduledDoses > 0 else { return 0.0 }
        let takenDoses = totalDoses - skippedDoses
        return Double(takenDoses) / Double(scheduledDoses)
    }

    /// Adherence rate as percentage string (0% to 100%)
    var adherenceRatePercentage: String {
        let percentage = adherenceRate * 100
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
        siteDistribution.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - Time Period

    /// Start date of the statistics period
    let periodStart: Date

    /// End date of the statistics period
    let periodEnd: Date

    /// Duration of the period in days
    var periodDays: Int {
        let components = Calendar.current.dateComponents([.day], from: periodStart, to: periodEnd)
        return max(1, components.day ?? 1)
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
        periodEnd: Date
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
            periodEnd: periodEnd
        )
    }
}

// MARK: - Statistics Calculator

struct AdherenceStatisticsCalculator {

    /// Calculate comprehensive adherence statistics for given doses and time period
    static func calculate(
        doses: [Dose],
        periodStart: Date,
        periodEnd: Date,
        medicationFrequency: DoseFrequency = .weekly
    ) -> AdherenceStatistics {

        // Filter doses to the specified period
        let periodDoses = doses.filter { dose in
            dose.timestamp >= periodStart && dose.timestamp <= periodEnd
        }

        guard !periodDoses.isEmpty else {
            return .empty(periodStart: periodStart, periodEnd: periodEnd)
        }

        // Basic counts
        let totalDoses = periodDoses.count
        let skippedDoses = periodDoses.filter { $0.skipped }.count
        let takenDoses = periodDoses.filter { !$0.skipped }

        // Calculate scheduled doses based on frequency and period
        let scheduledDoses = calculateScheduledDoses(
            periodStart: periodStart,
            periodEnd: periodEnd,
            frequency: medicationFrequency
        )

        // Dose amount calculations
        let doseAmounts = takenDoses.map { $0.amount }
        let averageDose = doseAmounts.isEmpty ? 0.0 : doseAmounts.reduce(0, +) / Double(doseAmounts.count)
        let totalMedicationAmount = doseAmounts.reduce(0, +)
        let doseRange = doseAmounts.isEmpty ? nil : (min: doseAmounts.min()!, max: doseAmounts.max()!)

        // Site distribution
        let siteDistribution = calculateSiteDistribution(doses: takenDoses)

        // Streak calculations
        let (currentStreak, longestStreak, isCurrentStreakActive) = calculateStreaks(
            doses: takenDoses,
            periodStart: periodStart,
            periodEnd: periodEnd
        )

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
            periodEnd: periodEnd
        )
    }

    // MARK: - Private Calculation Methods

    private static func calculateScheduledDoses(
        periodStart: Date,
        periodEnd: Date,
        frequency: DoseFrequency
    ) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: periodStart, to: periodEnd)
        let dayCount = max(1, components.day ?? 1)

        switch frequency {
        case .daily:
            return dayCount
        case .weekly:
            // One dose per week, so days divided by 7, rounded up
            return max(1, (dayCount + 6) / 7)
        }
    }

    private static func calculateSiteDistribution(doses: [Dose]) -> [String: Int] {
        let sites = doses.compactMap { $0.site }
        return Dictionary(grouping: sites) { $0 }.mapValues { $0.count }
    }

    private static func calculateStreaks(
        doses: [Dose],
        periodStart: Date,
        periodEnd: Date
    ) -> (current: Int, longest: Int, isActive: Bool) {

        // Sort doses by date
        let sortedDoses = doses.sorted { $0.timestamp < $1.timestamp }

        // Group doses by day
        let calendar = Calendar.current
        let dosesByDay = Dictionary(grouping: sortedDoses) { dose in
            calendar.startOfDay(for: dose.timestamp)
        }

        // Get all days in the period that have doses
        let daysWithDoses = Set(dosesByDay.keys)

        // Calculate streaks
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var isActive = false

        // Iterate through each day in the period
        var currentDate = calendar.startOfDay(for: periodStart)
        let endDate = calendar.startOfDay(for: periodEnd)

        while currentDate <= endDate {
            if daysWithDoses.contains(currentDate) {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)

                // Check if this is part of current streak (ending today)
                if calendar.isDateInToday(currentDate) {
                    currentStreak = tempStreak
                    isActive = true
                } else if calendar.isDateInYesterday(currentDate) {
                    currentStreak = tempStreak
                }
            } else {
                // Streak broken
                tempStreak = 0
                if calendar.isDateInToday(currentDate) {
                    currentStreak = 0
                    isActive = false
                }
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return (currentStreak, longestStreak, isActive)
    }
}

// MARK: - Supporting Types

enum DoseFrequency {
    case daily
    case weekly

    var description: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
}
