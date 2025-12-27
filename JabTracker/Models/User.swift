//
//  User.swift
//  JabTracker
//

import Foundation
import SwiftData

// MARK: - Metric Key Constants

/// Type-safe keys for body metrics visibility preferences
enum MetricKey: String, CaseIterable {
    // Upper Body
    case neck, shoulders, bust, chest, waist, hip
    // Arms
    case leftBicep, rightBicep, leftForearm, rightForearm, leftWrist, rightWrist
    // Legs
    case leftThigh, rightThigh, leftCalf, rightCalf, leftAnkle, rightAnkle
    // Ratios
    case waistToHeight, waistToHip
}

/// Type-safe keys for photo type visibility preferences
enum PhotoTypeKey: String, CaseIterable {
    case front, side, back
}

@Model
final class User {
    // MARK: - Static Defaults

    /// Default enabled body metrics for new users
    static let defaultEnabledMetrics: Set<String> = [MetricKey.waist.rawValue]

    /// Default enabled photo types for new users
    static let defaultEnabledPhotoTypes: Set<String> = [PhotoTypeKey.front.rawValue]

    var id: UUID = UUID()
    var email: String?  // Optional - genuinely no email vs empty string ambiguity resolved
    var name: String?  // Optional - Apple might not provide
    var dateOfBirth: Date?  // Optional - user may choose not to provide
    var weight: Double = 70.0  // Required with default for medical app
    var weightUnit: String = "kg"  // Required with default
    var measurementUnit: String = "cm"  // Required with default: cm or in
    var timezone: String = TimeZone.current.identifier  // Required with default
    var appleUserId: String?  // For Sign in with Apple linking
    var createdAt: Date = Date()  // Required - auto-generated
    var updatedAt: Date = Date()  // Required - auto-generated

    // Onboarding tracking
    var hasCompletedOnboarding: Bool = false  // Track onboarding completion
    var onboardingCompletedAt: Date?  // When onboarding was completed

    // Analytics preferences and settings
    var analyticsEnabled: Bool = true  // User preference for analytics features
    var adherenceGoalDays: Int = 7  // Target adherence period (default: weekly)
    var analyticsReportingEnabled: Bool = true  // User preference for report generation
    var preferredReportingFrequency: String = "weekly"  // "daily", "weekly", "monthly", "quarterly"

    // Nutrition goals
    var dailyCalorieGoal: Double = 2000.0
    var dailyProteinGoal: Double = 150.0
    var dailyCarbGoal: Double = 200.0
    var dailyFatGoal: Double = 65.0

    // Body metrics visibility preferences
    // Stores metric keys that are enabled (default: waist only)
    var enabledBodyMetrics: [String] = ["waist"]
    var enabledPhotoTypes: [String] = ["front"]

    @Relationship(deleteRule: .cascade, inverse: \Dose.user)
    var doses: [Dose]?  // CloudKit requires optional relationships

    @Relationship(deleteRule: .cascade, inverse: \MedicationProfile.user)
    var medicationProfiles: [MedicationProfile]?  // CloudKit requires optional relationships

    @Relationship(deleteRule: .cascade, inverse: \NutritionGoal.user)
    var nutritionGoals: [NutritionGoal]?  // CloudKit requires optional relationships

    // Note: FoodEntry does not have a User relationship - entries are queried by date
    // This avoids schema complexity while nutrition is user-scoped by app context

    init(
        email: String? = nil,
        name: String? = nil,
        dateOfBirth: Date? = nil,
        weight: Double = 70.0,
        weightUnit: String = "kg",
        measurementUnit: String = "cm",
        timezone: String = TimeZone.current.identifier,
        appleUserId: String? = nil,
        hasCompletedOnboarding: Bool = false,
        analyticsEnabled: Bool = true,
        adherenceGoalDays: Int = 7,
        analyticsReportingEnabled: Bool = true,
        preferredReportingFrequency: String = "weekly",
        dailyCalorieGoal: Double = 2000.0,
        dailyProteinGoal: Double = 150.0,
        dailyCarbGoal: Double = 200.0,
        dailyFatGoal: Double = 65.0,
        enabledBodyMetrics: [String] = ["waist"],
        enabledPhotoTypes: [String] = ["front"]
    ) {
        self.email = email
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.weight = weight
        self.weightUnit = weightUnit
        self.measurementUnit = measurementUnit
        self.timezone = timezone
        self.appleUserId = appleUserId
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.analyticsEnabled = analyticsEnabled
        self.adherenceGoalDays = adherenceGoalDays
        self.analyticsReportingEnabled = analyticsReportingEnabled
        self.preferredReportingFrequency = preferredReportingFrequency
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyProteinGoal = dailyProteinGoal
        self.dailyCarbGoal = dailyCarbGoal
        self.dailyFatGoal = dailyFatGoal
        self.enabledBodyMetrics = enabledBodyMetrics
        self.enabledPhotoTypes = enabledPhotoTypes
        self.createdAt = Date()
        self.updatedAt = Date()
        // Don't initialize optional relationship - let SwiftData handle it
    }
}

// MARK: - Computed Properties

extension User {
    /// Formatted weight display for UI presentation
    var weightDisplay: String {
        String(format: "%.1f %@", self.weight, self.weightUnit)
    }

    /// The user's currently active nutrition goal, if any
    var activeNutritionGoal: NutritionGoal? {
        nutritionGoals?.first(where: { $0.isActive })
    }

    /// CloudKit-compatible email field - returns empty string if email is nil
    /// This handles CloudKit's requirement for non-nil values while preserving semantic meaning
    var emailForCloudKit: String {
        self.email ?? ""
    }

    /// Display email - handles nil email gracefully for UI presentation
    var displayEmail: String {
        self.email ?? "No email"
    }
}

// MARK: - Analytics Computed Properties

extension User {
    /// Current adherence rate based on the user's adherence goal period
    var currentAdherenceRate: Double {
        guard let doses = self.doses, !doses.isEmpty else { return 0.0 }

        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -adherenceGoalDays, to: now) else {
            return 0.0
        }

        // Filter doses within the adherence goal period that are not skipped
        let recentDoses = doses.filter { dose in
            dose.timestamp >= startDate && dose.timestamp <= now && !dose.skipped
        }

        // Calculate adherence rate: actual doses taken / expected doses
        let expectedDoses = self.adherenceGoalDays
        let actualDoses = recentDoses.count

        return Double(actualDoses) / Double(expectedDoses)
    }

    /// Current streak of consecutive days with doses (not skipped)
    var currentStreak: Int {
        guard let doses = self.doses, !doses.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedDoses =
            doses
            .filter { !$0.skipped }
            .sorted { $0.timestamp > $1.timestamp }  // Most recent first

        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        for dose in sortedDoses {
            let doseDate = calendar.startOfDay(for: dose.timestamp)

            if calendar.isDate(doseDate, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if doseDate < currentDate {
                // Gap found, streak broken
                break
            }
        }

        return streak
    }

    /// Longest streak of consecutive days with doses (not skipped)
    var longestStreak: Int {
        guard let doses = self.doses, !doses.isEmpty else { return 0 }

        let calendar = Calendar.current
        let sortedDoses =
            doses
            .filter { !$0.skipped }
            .sorted { $0.timestamp < $1.timestamp }  // Oldest first

        var longestStreak = 0
        var currentStreak = 0
        var lastDoseDate: Date?

        for dose in sortedDoses {
            let doseDate = calendar.startOfDay(for: dose.timestamp)

            if let lastDate = lastDoseDate {
                let daysBetween = calendar.dateComponents([.day], from: lastDate, to: doseDate).day ?? 0

                if daysBetween == 1 {
                    // Consecutive day
                    currentStreak += 1
                } else if daysBetween > 1 {
                    // Gap found, reset streak
                    longestStreak = max(longestStreak, currentStreak)
                    currentStreak = 1
                }
                // daysBetween == 0 means same day, don't change streak
            } else {
                // First dose
                currentStreak = 1
            }

            lastDoseDate = doseDate
        }

        return max(longestStreak, currentStreak)
    }

    /// Average time between doses in seconds
    var averageTimeBetweenDoses: Double {
        guard let doses = self.doses, doses.count >= 2 else { return 0.0 }

        let sortedDoses =
            doses
            .filter { !$0.skipped }
            .sorted { $0.timestamp < $1.timestamp }

        guard sortedDoses.count >= 2 else { return 0.0 }

        var totalInterval: TimeInterval = 0
        let intervals = sortedDoses.count - 1

        for index in 1..<sortedDoses.count {
            let interval = sortedDoses[index].timestamp.timeIntervalSince(
                sortedDoses[index - 1].timestamp)
            totalInterval += interval
        }

        return totalInterval / Double(intervals)
    }
}

// MARK: - Metrics Visibility Helpers

extension User {
    /// Check if a specific body metric is enabled
    func isMetricEnabled(_ metric: String) -> Bool {
        enabledBodyMetrics.contains(metric)
    }

    /// Check if a specific photo type is enabled
    func isPhotoTypeEnabled(_ photoType: String) -> Bool {
        enabledPhotoTypes.contains(photoType)
    }

    /// Toggle a body metric's visibility
    func toggleMetric(_ metric: String) {
        toggleItem(metric, in: &enabledBodyMetrics)
    }

    /// Toggle a photo type's visibility
    func togglePhotoType(_ photoType: String) {
        toggleItem(photoType, in: &enabledPhotoTypes)
    }

    // MARK: - Private Helpers

    /// Toggle an item in an array (add if missing, remove if present)
    private func toggleItem(_ item: String, in array: inout [String]) {
        if array.contains(item) {
            array.removeAll { $0 == item }
        } else {
            array.append(item)
        }
    }
}

// MARK: - Unit Preferences Helpers

extension User {
    /// Returns true if user prefers metric units for measurements (cm)
    var prefersMetricMeasurements: Bool {
        measurementUnit == "cm"
    }

    /// Returns true if user prefers metric units for weight (kg)
    var prefersMetricWeight: Bool {
        weightUnit == "kg"
    }
}
