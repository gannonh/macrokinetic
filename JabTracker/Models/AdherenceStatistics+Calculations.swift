//
//  AdherenceStatistics+Calculations.swift
//  JabTracker
//
//  Extension containing private calculation methods for AdherenceStatisticsCalculator
//

import Foundation

// MARK: - Private Calculation Methods

extension AdherenceStatisticsCalculator {
    static func calculateScheduledDoses(
        periodStart: Date,
        periodEnd: Date,
        frequency: DoseFrequency
    ) -> Int {
        let calendar = Calendar.current
        let dayCount =
            calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: periodStart),
                to: calendar.startOfDay(for: periodEnd)
            ).day ?? 0

        switch frequency {
        case .daily:
            return dayCount
        case .weekly:
            // One dose per week, so days divided by 7, rounded up
            return max(1, (dayCount + 6) / 7)
        }
    }

    static func calculateSiteDistribution(doses: [Dose]) -> [String: Int] {
        let sites = doses.compactMap(\.site)
        return Dictionary(grouping: sites) { $0 }.mapValues { $0.count }
    }

    static func calculateStreaks(
        doses: [Dose],
        periodStart: Date,
        periodEnd: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> StreakResult {
        // Sort doses by date
        let sortedDoses = doses.sorted { $0.timestamp < $1.timestamp }

        // Group doses by day
        let dosesByDay = Dictionary(grouping: sortedDoses) { dose in
            calendar.startOfDay(for: dose.timestamp)
        }

        // Get all days in the period that have doses
        let daysWithDoses = Set(dosesByDay.keys)

        // Calculate streaks
        var longestStreak = 0
        var tempStreak = 0

        // Track the most recent streak (for current streak calculation)
        var mostRecentStreakCount = 0
        var mostRecentStreakEndsToday = false
        var mostRecentStreakEndsYesterday = false

        // Iterate through each day in the period
        var currentDate = calendar.startOfDay(for: periodStart)
        let endDate = calendar.startOfDay(for: periodEnd)
        let today = calendar.startOfDay(for: now)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            return StreakResult(current: 0, longest: 0, isActive: false)
        }

        while currentDate <= endDate {
            if daysWithDoses.contains(currentDate) {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)

                // Track if this streak includes today or yesterday
                if currentDate == today {
                    mostRecentStreakCount = tempStreak
                    mostRecentStreakEndsToday = true
                    mostRecentStreakEndsYesterday = false
                } else if currentDate == yesterday {
                    mostRecentStreakCount = tempStreak
                    mostRecentStreakEndsYesterday = true
                    mostRecentStreakEndsToday = false  // Will be updated if today also has a dose
                }
            } else {
                // Streak broken - reset
                tempStreak = 0
                // If we hit today without a dose, clear the recent streak flags
                if currentDate == today {
                    if !mostRecentStreakEndsYesterday {
                        mostRecentStreakCount = 0
                    }
                    mostRecentStreakEndsToday = false
                }
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        // Determine current streak and active status
        let currentStreak =
            (mostRecentStreakEndsToday || mostRecentStreakEndsYesterday) ? mostRecentStreakCount : 0
        let isActive = mostRecentStreakEndsToday

        return StreakResult(current: currentStreak, longest: longestStreak, isActive: isActive)
    }
}

extension AdherenceStatisticsCalculator {
    /// Current streak of consecutive dosed days ending today (active) or yesterday. When the context
    /// carries the full dose history the count runs across month and year boundaries; otherwise the
    /// period-scoped `fallback` is used.
    static func calculateCurrentStreak(context: StreakContext, fallback: StreakResult) -> StreakResult {
        guard let history = context.history?.filter({ !$0.skipped }),
            let earliest = history.map(\.timestamp).min()
        else { return fallback }
        return self.calculateStreaks(
            doses: history,
            periodStart: earliest,
            periodEnd: context.now,
            now: context.now,
            calendar: context.calendar)
    }
}
