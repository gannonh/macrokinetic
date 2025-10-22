//
//  DoseDefaults.swift
//  JabTracker
//

import Foundation

/// Smart defaults system and business logic helpers for dose management
/// Provides medication-specific recommendations for injection sites, timing, and scheduling
enum DoseDefaults {
    // MARK: - Injection Site Recommendations

    /// Default injection sites for all medications, in recommended rotation order
    static let allInjectionSites: [String] = [
        "Thigh",
        "Abdomen",
        "Upper arm",
        "Lower back",
        "Buttocks",
    ]

    /// Get recommended injection sites for a specific medication
    /// Based on clinical guidelines and medication characteristics
    static func recommendedInjectionSites(for medication: Medication) -> [String] {
        switch medication {
        case .semaglutide:
            // Weekly injection - rotate between all major sites
            return ["Thigh", "Abdomen", "Upper arm"]
        case .tirzepatide:
            // Weekly injection - similar to semaglutide but may prefer larger injection sites
            return ["Thigh", "Abdomen", "Upper arm", "Lower back"]
        case .liraglutide:
            // Daily injection - focus on easily accessible sites for frequent injections
            return ["Thigh", "Abdomen"]
        case .dulaglutide:
            // Weekly auto-injector - all sites suitable for auto-injector mechanism
            return ["Thigh", "Abdomen", "Upper arm", "Lower back", "Buttocks"]
        }
    }

    /// Get next recommended injection site based on recent dose history
    /// Implements site rotation to prevent lipodystrophy
    static func nextRecommendedSite(
        for medication: Medication,
        recentDoses: [Dose],
        preferredSites: [String]? = nil
    ) -> String {
        let sites = preferredSites ?? self.recommendedInjectionSites(for: medication)
        guard !sites.isEmpty else { return self.allInjectionSites.first ?? "Abdomen" }

        // Get recent injection sites from last few doses
        let recentSites =
            recentDoses
            .prefix(sites.count)  // Look at last N doses where N is number of available sites
            .compactMap(\.site)

        // Find first site in rotation that wasn't recently used
        for site in sites where !recentSites.contains(site) {
            return site
        }

        // If all sites were recently used, return first in rotation
        return sites.first ?? "Abdomen"
    }

    // MARK: - Dose Timing Recommendations

    /// Get recommended time of day for medication doses
    static func recommendedDoseTime(for medication: Medication) -> DateComponents {
        var components = DateComponents()

        switch medication {
        case .semaglutide, .tirzepatide, .dulaglutide:
            // Weekly medications - recommend same day/time each week
            // Default to Sunday morning (easier to remember)
            components.weekday = 1  // Sunday
            components.hour = 9
            components.minute = 0
        case .liraglutide:
            // Daily medication - recommend consistent daily time
            // Morning is preferred for GLP-1 medications
            components.hour = 8
            components.minute = 0
        }

        return components
    }

    /// Calculate next scheduled dose date for a medication profile
    static func nextScheduledDose(
        for profile: MedicationProfile,
        from _: Date = Date(),
        doses: [Dose]? = nil
    ) -> Date? {
        guard let medication = profile.medication else { return nil }

        let calendar = Calendar.current
        let frequency = medication.frequency

        // Use provided doses array for testing, or profile.doses for production
        let dosesArray = doses ?? (profile.doses ?? [])

        // Get most recent dose or use start date
        let lastDoseDate =
            dosesArray.max(by: { $0.timestamp < $1.timestamp })?.timestamp ?? profile.startDate

        switch frequency {
        case .daily:
            // Add 1 day to last dose
            return calendar.date(byAdding: .day, value: 1, to: lastDoseDate)
        case .weekly:
            // Add 7 days to last dose
            return calendar.date(byAdding: .day, value: 7, to: lastDoseDate)
        }
    }

    /// Check if a dose is overdue based on medication frequency
    static func isDoseOverdue(
        for profile: MedicationProfile,
        currentDate: Date = Date(),
        gracePeriodHours: Int = 2,
        doses: [Dose]? = nil
    ) -> Bool {
        guard let medication = profile.medication else { return false }

        let calendar = Calendar.current
        let frequency = medication.frequency

        // Use provided doses array for testing, or profile.doses for production
        let dosesArray = doses ?? (profile.doses ?? [])

        // Get most recent dose or use start date
        let lastDoseDate =
            dosesArray.max(by: { $0.timestamp < $1.timestamp })?.timestamp ?? profile.startDate

        // Calculate when the next dose should have been taken
        let scheduledNextDose: Date
        switch frequency {
        case .daily:
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: lastDoseDate) else {
                return false
            }
            scheduledNextDose = nextDay
        case .weekly:
            guard let nextWeek = calendar.date(byAdding: .day, value: 7, to: lastDoseDate) else {
                return false
            }
            scheduledNextDose = nextWeek
        }

        // Add grace period to scheduled dose time
        guard
            let gracePeriodEnd = calendar.date(
                byAdding: .hour, value: gracePeriodHours, to: scheduledNextDose)
        else {
            return false
        }

        return currentDate > gracePeriodEnd
    }

    // MARK: - Dose History Analytics Helpers

    /// Calculate adherence percentage for a medication profile over a time period
    static func calculateAdherence(
        for profile: MedicationProfile,
        in timeRange: DateInterval,
        currentDate _: Date = Date(),
        doses: [Dose]? = nil
    ) -> Double {
        guard let medication = profile.medication else { return 0.0 }

        let calendar = Calendar.current
        let frequency = medication.frequency

        // Calculate expected number of doses in time range
        let daysBetween =
            calendar.dateComponents([.day], from: timeRange.start, to: timeRange.end).day ?? 0
        let expectedDoses: Int

        switch frequency {
        case .daily:
            expectedDoses = daysBetween
        case .weekly:
            expectedDoses = max(1, daysBetween / 7)
        }

        // Use provided doses array for testing, or profile.doses for production
        let dosesArray = doses ?? (profile.doses ?? [])

        // Count actual doses in time range (excluding skipped doses)
        let actualDoses = dosesArray.filter { dose in
            timeRange.contains(dose.timestamp) && !dose.skipped
        }.count

        guard expectedDoses > 0 else { return 0.0 }

        // Cap at 100% to handle cases where user took extra doses
        return min(1.0, Double(actualDoses) / Double(expectedDoses))
    }

    /// Get dose streak (consecutive days/weeks with doses taken)
    static func calculateDoseStreak(
        for profile: MedicationProfile,
        currentDate: Date = Date(),
        doses: [Dose]? = nil
    ) -> Int {
        guard let medication = profile.medication else { return 0 }
        // Use provided doses array for testing, or profile.doses for production
        let dosesArray = doses ?? (profile.doses ?? [])
        let sortedDoses = dosesArray.sorted(by: { $0.timestamp > $1.timestamp })

        let calendar = Calendar.current
        let frequency = medication.frequency

        var streak = 0
        var checkDate = currentDate

        // Work backwards from current date checking for doses
        while true {
            let hasDoseInPeriod = self.checkForDoseInPeriod(
                frequency: frequency,
                checkDate: checkDate,
                sortedDoses: sortedDoses,
                calendar: calendar)

            if hasDoseInPeriod {
                streak += 1
                guard
                    let newDate = moveToPreviousPeriod(
                        frequency: frequency,
                        currentDate: checkDate,
                        calendar: calendar)
                else { break }
                checkDate = newDate
            } else {
                break
            }
        }

        return streak
    }

    /// Check if there's a dose in the current period based on frequency
    private static func checkForDoseInPeriod(
        frequency: DoseFrequency,
        checkDate: Date,
        sortedDoses: [Dose],
        calendar: Calendar
    ) -> Bool {
        switch frequency {
        case .daily:
            let startOfDay = calendar.startOfDay(for: checkDate)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                return false
            }
            let dateRange = DateInterval(start: startOfDay, end: endOfDay)
            return sortedDoses.contains { dose in
                dateRange.contains(dose.timestamp) && !dose.skipped
            }

        case .weekly:
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: checkDate) else {
                return false
            }
            return sortedDoses.contains { dose in
                weekInterval.contains(dose.timestamp) && !dose.skipped
            }
        }
    }

    /// Move to the previous period based on frequency
    private static func moveToPreviousPeriod(
        frequency: DoseFrequency,
        currentDate: Date,
        calendar: Calendar
    ) -> Date? {
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: -1, to: currentDate)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate)
        }
    }

    /// Get summary statistics for a medication profile
    static func getDoseSummary(
        for profile: MedicationProfile,
        in timeRange: DateInterval? = nil,
        doses: [Dose]? = nil
    ) -> DoseSummary {
        // Use provided doses array for testing, or profile.doses for production
        let dosesArray = doses ?? (profile.doses ?? [])
        let filteredDoses =
            timeRange.map { range in
                dosesArray.filter { range.contains($0.timestamp) }
            } ?? dosesArray

        let totalDoses = filteredDoses.count
        let completedDoses = filteredDoses.filter { !$0.skipped }.count
        let skippedDoses = filteredDoses.filter(\.skipped).count

        let averageDose =
            completedDoses > 0
            ? filteredDoses.filter { !$0.skipped }.map(\.amount).reduce(0, +) / Double(completedDoses)
            : 0.0

        let mostUsedSite = self.getMostUsedInjectionSite(from: filteredDoses)

        let adherence =
            timeRange.map { range in
                self.calculateAdherence(for: profile, in: range, doses: dosesArray)
            } ?? 0.0

        let currentStreak = self.calculateDoseStreak(for: profile, doses: dosesArray)

        return DoseSummary(
            totalDoses: totalDoses,
            completedDoses: completedDoses,
            skippedDoses: skippedDoses,
            averageDose: averageDose,
            adherencePercentage: adherence,
            currentStreak: currentStreak,
            mostUsedInjectionSite: mostUsedSite)
    }

    /// Get most frequently used injection site from dose history
    private static func getMostUsedInjectionSite(from doses: [Dose]) -> String? {
        let sites = doses.compactMap(\.site)
        guard !sites.isEmpty else { return nil }

        let siteCounts = Dictionary(grouping: sites, by: { $0 })
            .mapValues(\.count)

        return siteCounts.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - Medication-Specific Defaults

    /// Get default starting dose for a medication and brand combination
    static func defaultStartingDose(for medication: Medication, brand: String) -> Double {
        let availableDoses = medication.availableDoses(for: brand)
        guard !availableDoses.isEmpty else { return 0.0 }

        switch medication {
        case .semaglutide:
            return 0.25  // Standard starting dose for both Ozempic and Wegovy
        case .tirzepatide:
            return 2.5  // Standard starting dose for Mounjaro and Zepbound
        case .liraglutide:
            return 0.6  // Standard starting dose for Victoza and Saxenda
        case .dulaglutide:
            return 0.75  // Standard starting dose for Trulicity
        }
    }

    /// Get recommended escalation schedule for a medication
    static func recommendedEscalationSchedule(
        for medication: Medication,
        brand: String,
        startingDose: Double
    ) -> [Double] {
        let availableDoses = medication.availableDoses(for: brand).sorted()
        guard let startIndex = availableDoses.firstIndex(of: startingDose) else {
            return availableDoses
        }

        // Return doses from starting dose onwards
        return Array(availableDoses[startIndex...])
    }

    /// Get typical escalation interval (weeks between dose increases)
    static func escalationInterval(for medication: Medication) -> Int {
        switch medication {
        case .semaglutide, .tirzepatide:
            return 4  // Increase every 4 weeks
        case .liraglutide:
            return 1  // Can increase weekly for daily medication
        case .dulaglutide:
            return 4  // Increase every 4 weeks
        }
    }
}

// MARK: - Supporting Types

/// Summary statistics for a medication profile's dose history
struct DoseSummary {
    let totalDoses: Int
    let completedDoses: Int
    let skippedDoses: Int
    let averageDose: Double
    let adherencePercentage: Double
    let currentStreak: Int
    let mostUsedInjectionSite: String?

    /// Computed convenience properties
    var completionRate: Double {
        guard self.totalDoses > 0 else { return 0.0 }
        return Double(self.completedDoses) / Double(self.totalDoses)
    }

    var skipRate: Double {
        guard self.totalDoses > 0 else { return 0.0 }
        return Double(self.skippedDoses) / Double(self.totalDoses)
    }
}
