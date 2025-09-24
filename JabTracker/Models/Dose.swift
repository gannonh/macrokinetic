//
//  Dose.swift
//  JabTracker
//

import Foundation
import SwiftData

@Model
final class Dose {
    var id: UUID = UUID()
    var amount: Double = 0.0  // CloudKit requires default value
    var timestamp: Date = Date()  // CloudKit requires default value
    var site: String?  // Optional - injection site
    var notes: String?  // Optional - user notes
    var imageData: Data?  // Optional - photo attachment
    var skipped: Bool = false  // Required with default

    // Analytics metadata fields
    var expectedTimestamp: Date?  // When dose was scheduled/expected
    var actualTimestamp: Date?  // When dose was actually taken
    var analyticsTags: [String] = []  // Tags for analytics categorization
    var analyticsContext: [String: String] = [:]  // Key-value context data

    var user: User?
    var medication: MedicationProfile?

    init(
        amount: Double = 0.0,
        timestamp: Date = Date(),
        site: String? = nil,
        notes: String? = nil,
        imageData: Data? = nil,
        skipped: Bool = false,
        expectedTimestamp: Date? = nil,
        actualTimestamp: Date? = nil,
        analyticsTags: [String] = [],
        analyticsContext: [String: String] = [:],
        user: User? = nil,
        medication: MedicationProfile? = nil
    ) {
        #if DEBUG
            print("🔍 Dose.init called with amount: [REDACTED], site: [REDACTED], notes: [REDACTED]")
            print("🔍 Dose.init stacktrace:")
            Thread.callStackSymbols.prefix(5).forEach { print("🔍   \($0)") }
        #endif

        self.amount = amount
        self.timestamp = timestamp
        self.site = site
        self.notes = notes
        self.imageData = imageData
        self.skipped = skipped
        self.expectedTimestamp = expectedTimestamp
        self.actualTimestamp = actualTimestamp
        self.analyticsTags = analyticsTags
        self.analyticsContext = analyticsContext
        self.user = user
        self.medication = medication

        #if DEBUG
            print("🔍 Dose.init completed - ID: \(self.id)")
        #endif
    }
}

// MARK: - Analytics Extensions

extension Dose {
    // MARK: - Adherence Tracking

    /// Whether the dose was taken within the adherence window (default 2 hours)
    var isOnTime: Bool {
        guard let expected = expectedTimestamp,
            let actual = actualTimestamp
        else {
            return false
        }

        let timeDifference = abs(actual.timeIntervalSince(expected))
        return timeDifference <= (2 * 60 * 60)  // 2 hours in seconds
    }

    /// Check if dose is within a custom adherence window
    func isWithinAdherenceWindow(hours: Double) -> Bool {
        guard let expected = expectedTimestamp,
            let actual = actualTimestamp
        else {
            return false
        }

        let timeDifference = abs(actual.timeIntervalSince(expected))
        return timeDifference <= (hours * 60 * 60)
    }

    /// Adherence status classification
    var adherenceStatus: String {
        if self.skipped {
            return "skipped"
        }

        guard let expected = expectedTimestamp else {
            return "unknown"
        }

        guard let actual = actualTimestamp else {
            return "unknown"
        }

        let timeDifference = actual.timeIntervalSince(expected)
        let twoHours: TimeInterval = 2 * 60 * 60

        if abs(timeDifference) <= twoHours {
            return "on_time"
        } else if timeDifference > twoHours {
            return "late"
        } else {
            return "early"
        }
    }

    // MARK: - Dose Timing Analysis

    /// Timing delay in minutes (positive = late, negative = early)
    var timingDelayInMinutes: Int? {
        guard let expected = expectedTimestamp,
            let actual = actualTimestamp
        else {
            return nil
        }

        let timeDifference = actual.timeIntervalSince(expected)
        return Int(timeDifference / 60)  // Convert to minutes
    }

    // MARK: - Day and Week Analysis

    /// Days since the last dose for this user/medication combination
    var daysSinceLastDose: Int? {
        guard let user,
            let medication,
            let userDoses = user.doses,
            medication.doses != nil
        else {
            return nil
        }

        // Find all doses for this user/medication combination before this dose
        let relevantDoses = userDoses.filter { dose in
            dose.medication?.id == medication.id && dose.timestamp < self.timestamp && !dose.skipped
        }

        guard let lastDose = relevantDoses.max(by: { $0.timestamp < $1.timestamp }) else {
            return nil  // This is the first dose
        }

        let calendar = Calendar.current
        let daysBetween = calendar.dateComponents([.day], from: lastDose.timestamp, to: self.timestamp)
            .day
        return daysBetween
    }

    /// Whether this is the first dose of the week for this medication
    var isFirstDoseOfWeek: Bool {
        guard let user,
            let medication,
            let userDoses = user.doses,
            medication.doses != nil
        else {
            return true  // Default to true if no relationship data
        }

        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: self.timestamp) else {
            return true
        }

        // Find all doses for this user/medication in the same week before this dose
        let sameMedicationThisWeek = userDoses.filter { dose in
            dose.medication?.id == medication.id && dose.timestamp >= weekInterval.start
                && dose.timestamp < self.timestamp && !dose.skipped
        }

        return sameMedicationThisWeek.isEmpty
    }

    // MARK: - Streak Analysis

    /// Current streak of consecutive doses (ending with this dose)
    var currentStreak: Int {
        guard let user,
            let medication,
            let userDoses = user.doses,
            medication.doses != nil
        else {
            return 1  // Default to 1 for isolated dose
        }

        // Get all doses for this medication, sorted by date descending
        let relevantDoses =
            userDoses
            .filter { $0.medication?.id == medication.id }
            .sorted { $0.timestamp > $1.timestamp }

        guard let currentDoseIndex = relevantDoses.firstIndex(where: { $0.id == self.id }) else {
            return 1
        }

        let calendar = Calendar.current
        var streak = 0

        // Count consecutive doses starting from current dose
        for doseIndex in currentDoseIndex..<relevantDoses.count {
            let dose = relevantDoses[doseIndex]

            if dose.skipped {
                break  // Streak broken by skipped dose
            }

            streak += 1

            // Check if next dose is consecutive (within expected interval)
            if doseIndex + 1 < relevantDoses.count {
                let nextDose = relevantDoses[doseIndex + 1]
                let daysBetween =
                    calendar.dateComponents([.day], from: nextDose.timestamp, to: dose.timestamp).day ?? 0

                // For weekly medications, expect ~7 days; for daily, expect ~1 day
                // Allow some flexibility in scheduling
                if daysBetween > 10 {  // More than 10 days gap breaks streak
                    break
                }
            }
        }

        return max(streak, 1)
    }

    /// Longest streak in the dose history for this medication
    var longestStreak: Int {
        guard let user,
            let medication,
            let userDoses = user.doses,
            medication.doses != nil
        else {
            return 1  // Default to 1 for isolated dose
        }

        // Get all doses for this medication, sorted by date descending
        let relevantDoses =
            userDoses
            .filter { $0.medication?.id == medication.id }
            .sorted { $0.timestamp > $1.timestamp }

        guard !relevantDoses.isEmpty else {
            return 1
        }

        let calendar = Calendar.current
        var maxStreak = 0
        var currentStreak = 0

        for doseIndex in 0..<relevantDoses.count {
            let dose = relevantDoses[doseIndex]

            if dose.skipped {
                maxStreak = max(maxStreak, currentStreak)
                currentStreak = 0
            } else {
                currentStreak += 1

                // Check if next dose breaks the streak
                if doseIndex + 1 < relevantDoses.count {
                    let nextDose = relevantDoses[doseIndex + 1]
                    let daysBetween =
                        calendar.dateComponents(
                            [.day], from: nextDose.timestamp, to: dose.timestamp
                        ).day ?? 0

                    if daysBetween > 10 {  // More than 10 days gap breaks streak
                        maxStreak = max(maxStreak, currentStreak)
                        currentStreak = 0
                    }
                }
            }
        }

        return max(maxStreak, currentStreak, 1)
    }
}
