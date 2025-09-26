//
//  AdherenceInsightsService.swift
//  JabTracker
//
//  Service for analyzing dose adherence patterns and generating actionable insights
//

import Foundation
import SwiftData

/// Service responsible for pattern recognition and insight generation from dose adherence data
@Observable
final class AdherenceInsightsService {
    // MARK: - Configuration

    /// Minimum confidence threshold for reporting patterns
    private let minimumPatternConfidence: Double = 0.7

    /// Minimum number of data points required for pattern detection
    private let minimumDataPoints: Int = 5

    /// Maximum age of data to consider for pattern analysis (days)
    private let maxAnalysisAgeDays: Int = 90

    /// Minimum adherence rate for positive insights
    private let excellentAdherenceThreshold: Double = 0.9

    /// Threshold for concerning adherence requiring provider consultation
    private let concerningAdherenceThreshold: Double = 0.6

    // MARK: - Core Analysis Methods

    /// Generate comprehensive adherence insights for a user
    func generateInsights(for user: User, context: ModelContext) -> [AdherenceInsight] {
        guard let medicationProfiles = user.medicationProfiles,
            !medicationProfiles.isEmpty
        else {
            return []
        }

        var insights: [AdherenceInsight] = []

        // Analyze each medication profile
        for profile in medicationProfiles {
            let profileInsights = generateInsights(for: profile, user: user, context: context)
            insights.append(contentsOf: profileInsights)
        }

        // Generate cross-medication insights
        let crossMedicationInsights = generateCrossMedicationInsights(
            for: medicationProfiles,
            user: user,
            context: context
        )
        insights.append(contentsOf: crossMedicationInsights)

        // Sort by importance and filter for display
        return
            insights
            .filter(\.shouldDisplay)
            .sorted { $0.importanceScore > $1.importanceScore }
            .prefix(8)  // Limit to top 8 insights
            .map { $0 }
    }

    /// Generate insights for a specific medication profile
    private func generateInsights(
        for profile: MedicationProfile,
        user: User,
        context: ModelContext
    ) -> [AdherenceInsight] {
        guard let doses = profile.doses, !doses.isEmpty else {
            return []
        }

        let analysisStartDate =
            Calendar.current.date(
                byAdding: .day,
                value: -maxAnalysisAgeDays,
                to: Date()
            ) ?? Date().addingTimeInterval(-90 * 24 * 3600)

        let recentDoses = doses.filter { $0.timestamp >= analysisStartDate }
        guard recentDoses.count >= minimumDataPoints else {
            return []
        }

        let dateRange = DateInterval(start: analysisStartDate, end: Date())
        var insights: [AdherenceInsight] = []

        // Detect patterns
        let patterns = detectPatterns(in: recentDoses, dateRange: dateRange)

        // Calculate basic metrics
        let adherenceRate = calculateAdherenceRate(doses: recentDoses, dateRange: dateRange)
        let streakInfo = calculateStreakInfo(doses: recentDoses)

        // Generate insights based on adherence rate
        if adherenceRate >= excellentAdherenceThreshold {
            insights.append(
                AdherenceInsight.excellentAdherence(
                    adherenceRate: adherenceRate,
                    streakDays: streakInfo.current,
                    dateRange: dateRange
                )
            )
        }

        // Generate pattern-based insights
        insights.append(contentsOf: generatePatternInsights(patterns: patterns))

        // Generate timing insights
        insights.append(contentsOf: generateTimingInsights(doses: recentDoses))

        // Generate medical insights
        insights.append(
            contentsOf: generateMedicalInsights(
                profile: profile,
                adherenceRate: adherenceRate,
                patterns: patterns
            ))

        return insights
    }

    // MARK: - Pattern Detection

    /// Detect adherence patterns in dose history
    func detectPatterns(in doses: [Dose], dateRange: DateInterval) -> [AdherencePattern] {
        guard doses.count >= minimumDataPoints else { return [] }

        var patterns: [AdherencePattern] = []

        // Detect weekend gaps only for daily medications
        // Weekly GLP-1 medications (semaglutide, tirzepatide) should not flag weekend gaps
        let isWeeklyMedication = doses.first?.medication?.medication?.frequency == .weekly
        if !isWeeklyMedication, let weekendPattern = detectWeekendGaps(doses: doses, dateRange: dateRange) {
            patterns.append(weekendPattern)
        }

        // Detect timing drift
        if let timingPattern = detectTimingDrift(doses: doses, dateRange: dateRange) {
            patterns.append(timingPattern)
        }

        // Detect perfect adherence
        if let perfectPattern = detectPerfectAdherence(doses: doses, dateRange: dateRange) {
            patterns.append(perfectPattern)
        }

        // Detect site rotation patterns
        if let sitePattern = detectSiteRotationPattern(doses: doses, dateRange: dateRange) {
            patterns.append(sitePattern)
        }

        return patterns.filter { $0.confidence >= minimumPatternConfidence }
    }

    /// Detect weekend gaps in dosing
    private func detectWeekendGaps(doses: [Dose], dateRange: DateInterval) -> AdherencePattern? {
        let calendar = Calendar.current
        var weekends: [DateInterval] = []

        // Generate all weekends in the date range
        var current = dateRange.start
        while current < dateRange.end {
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: current),
                let saturday = calendar.date(byAdding: .day, value: 5, to: weekInterval.start),
                let sunday = calendar.date(byAdding: .day, value: 6, to: weekInterval.start),
                let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: current)
            {

                if saturday <= dateRange.end {
                    weekends.append(DateInterval(start: saturday, duration: 24 * 3600))
                }
                if sunday <= dateRange.end {
                    weekends.append(DateInterval(start: sunday, duration: 24 * 3600))
                }

                current = nextWeek
            } else {
                break
            }
        }

        guard weekends.count >= 4 else { return nil }

        // Count missed weekends
        var missedWeekends = 0
        for weekend in weekends {
            let weekendDoses = doses.filter { dose in
                weekend.contains(dose.timestamp) && !dose.skipped
            }
            if weekendDoses.isEmpty {
                missedWeekends += 1
            }
        }

        let missedPercentage = Double(missedWeekends) / Double(weekends.count)
        guard missedPercentage >= 0.3 else { return nil }  // At least 30% missed weekends

        let confidence = min(1.0, missedPercentage * 1.5)
        let supportingDataPoints = weekends.count

        return AdherencePattern.weekendGapPattern(
            confidence: confidence,
            supportingDataPoints: supportingDataPoints,
            dateRange: dateRange,
            missedWeekends: missedWeekends,
            totalWeekends: weekends.count
        )
    }

    /// Detect timing drift patterns
    private func detectTimingDrift(doses: [Dose], dateRange: DateInterval) -> AdherencePattern? {
        // Get doses with both expected and actual timestamps
        let timedDoses = doses.compactMap { dose -> (Date, Date)? in
            guard let expected = dose.expectedTimestamp,
                let actual = dose.actualTimestamp
            else { return nil }
            return (expected, actual)
        }

        guard timedDoses.count >= 5 else { return nil }

        // Calculate timing differences
        let timingDifferences = timedDoses.map { $0.1.timeIntervalSince($0.0) }
        let averageDrift = timingDifferences.reduce(0, +) / Double(timingDifferences.count)

        // Check if there's consistent drift
        let absoluteAverageDrift = abs(averageDrift)
        guard absoluteAverageDrift > 3600 else { return nil }  // At least 1 hour average drift

        // Calculate confidence based on consistency
        let variance =
            timingDifferences.map { pow($0 - averageDrift, 2) }.reduce(0, +) / Double(timingDifferences.count)
        let standardDeviation = sqrt(variance)
        let consistency = max(0, 1.0 - (standardDeviation / (6 * 3600)))  // Less variance = higher confidence

        let driftDirection = averageDrift > 0 ? "later" : "earlier"

        return AdherencePattern.timingDriftPattern(
            confidence: consistency,
            supportingDataPoints: timedDoses.count,
            dateRange: dateRange,
            averageDrift: averageDrift,
            driftDirection: driftDirection
        )
    }

    /// Detect perfect adherence patterns
    private func detectPerfectAdherence(doses: [Dose], dateRange: DateInterval) -> AdherencePattern? {
        let takenDoses = doses.filter { !$0.skipped }
        let adherenceRate = calculateAdherenceRate(doses: doses, dateRange: dateRange)

        guard adherenceRate >= 0.95 else { return nil }

        return AdherencePattern(
            type: .perfectAdherence,
            name: "Perfect Adherence",
            description:
                "Excellent medication adherence with \(String(format: "%.1f%%", adherenceRate * 100)) compliance",
            confidence: adherenceRate,
            supportingDataPoints: takenDoses.count,
            dateRange: dateRange,
            frequency: .constant,
            patternData: ["adherence_rate": adherenceRate],
            statisticalSignificance: adherenceRate,
            isClinicallyRelevant: true,
            riskLevel: .low
        )
    }

    /// Detect site rotation patterns
    private func detectSiteRotationPattern(doses: [Dose], dateRange: DateInterval) -> AdherencePattern? {
        let dosesWithSites = doses.compactMap { dose -> String? in
            guard let site = dose.site, !site.isEmpty else { return nil }
            return site
        }

        guard dosesWithSites.count >= 5 else { return nil }

        let uniqueSites = Set(dosesWithSites)
        let rotationQuality = min(1.0, Double(uniqueSites.count) / 4.0)  // Ideal is 4+ sites

        guard rotationQuality >= 0.5 else { return nil }

        let patternType: AdherencePattern.PatternType =
            rotationQuality >= 0.75 ? .siteRotationGood : .inconsistentSites
        let riskLevel: AdherencePattern.RiskLevel =
            rotationQuality >= 0.75 ? .low : .medium

        return AdherencePattern(
            type: patternType,
            name: patternType.displayName,
            description: "Using \(uniqueSites.count) different injection sites",
            confidence: rotationQuality,
            supportingDataPoints: dosesWithSites.count,
            dateRange: dateRange,
            frequency: .consistent,
            patternData: [
                "unique_sites": uniqueSites.count,
                "rotation_quality": rotationQuality,
            ],
            statisticalSignificance: rotationQuality,
            isClinicallyRelevant: true,
            riskLevel: riskLevel
        )
    }

    // MARK: - Insight Generation

    /// Generate insights from detected patterns
    private func generatePatternInsights(patterns: [AdherencePattern]) -> [AdherenceInsight] {
        var insights: [AdherenceInsight] = []

        for pattern in patterns {
            switch pattern.type {
            case .weekendGaps:
                if let weekendInsight = createWeekendInsight(from: pattern) {
                    insights.append(weekendInsight)
                }

            case .timingDrift:
                if let timingInsight = createTimingInsight(from: pattern) {
                    insights.append(timingInsight)
                }

            case .perfectAdherence:
                // Handled in main generateInsights method
                break

            case .siteRotationGood:
                insights.append(createSiteRotationInsight(from: pattern))

            case .inconsistentSites:
                insights.append(createSiteImprovementInsight(from: pattern))

            default:
                // Handle other pattern types as needed
                break
            }
        }

        return insights
    }

    /// Create weekend-specific insight
    private func createWeekendInsight(from pattern: AdherencePattern) -> AdherenceInsight? {
        guard let missedWeekends = pattern.getPatternValue(for: "missed_weekends", as: Int.self),
            let totalWeekends = pattern.getPatternValue(for: "total_weekends", as: Int.self)
        else {
            return nil
        }

        return AdherenceInsight.weekendReminder(
            pattern: pattern,
            missedWeekends: missedWeekends,
            totalWeekends: totalWeekends
        )
    }

    /// Create timing drift insight
    private func createTimingInsight(from pattern: AdherencePattern) -> AdherenceInsight? {
        guard let driftHours = pattern.getPatternValue(for: "average_drift_hours", as: Double.self),
            let direction = pattern.getPatternValue(for: "drift_direction", as: String.self)
        else {
            return nil
        }

        let absHours = abs(driftHours)
        let title = absHours > 6 ? "Significant Timing Drift" : "Minor Timing Drift"
        let priority: AdherenceInsight.Priority = absHours > 6 ? .high : .medium

        return AdherenceInsight(
            type: .timingOptimization,
            title: title,
            description:
                "Your doses are trending \(direction) by an average of \(String(format: "%.1f", absHours)) hours.",
            actionableRecommendation:
                "Consider adjusting your dose schedule or setting reminders to maintain consistent timing.",
            priority: priority,
            supportingPatterns: [pattern],
            confidence: pattern.confidence,
            dateRange: pattern.dateRange,
            clinicalSignificance: absHours > 6 ? .significant : .moderate,
            treatmentImpact: .moderate
        )
    }

    /// Create site rotation positive insight
    private func createSiteRotationInsight(from pattern: AdherencePattern) -> AdherenceInsight {
        AdherenceInsight(
            type: .siteRotationReminder,
            title: "Excellent Site Rotation",
            description:
                "You're doing great with injection site rotation, which helps prevent "
                + "tissue damage and maintain absorption.",
            actionableRecommendation:
                "Continue your current site rotation practice to maintain healthy injection sites.",
            priority: .low,
            supportingPatterns: [pattern],
            confidence: pattern.confidence,
            dateRange: pattern.dateRange,
            clinicalSignificance: .moderate,
            treatmentImpact: .moderate,
            colorTheme: .green
        )
    }

    /// Create site improvement insight
    private func createSiteImprovementInsight(from pattern: AdherencePattern) -> AdherenceInsight {
        AdherenceInsight(
            type: .siteRotationReminder,
            title: "Improve Site Rotation",
            description:
                "Consider rotating between more injection sites to prevent tissue damage "
                + "and maintain consistent absorption.",
            actionableRecommendation:
                "Use at least 4 different injection sites: both thighs and both sides of abdomen. "
                + "Allow sites to heal between uses.",
            priority: .medium,
            supportingPatterns: [pattern],
            confidence: pattern.confidence,
            dateRange: pattern.dateRange,
            clinicalSignificance: .moderate,
            treatmentImpact: .moderate,
            colorTheme: .orange
        )
    }

    /// Generate timing-related insights
    private func generateTimingInsights(doses: [Dose]) -> [AdherenceInsight] {
        // Implementation for timing consistency insights
        // For now, return empty array - can be expanded later
        []
    }

    /// Generate medical insights
    private func generateMedicalInsights(
        profile: MedicationProfile,
        adherenceRate: Double,
        patterns: [AdherencePattern]
    ) -> [AdherenceInsight] {
        var insights: [AdherenceInsight] = []

        // Check for dose escalation readiness
        // Use the start date for the current dose, not the profile start date
        // For simplicity, we'll use the profile start date but in production this should track
        // the date when the current dose was started (last dose escalation date)
        let weeksOnCurrentDose =
            Calendar.current.dateComponents(
                [.weekOfYear],
                from: profile.startDate,
                to: Date()
            ).weekOfYear ?? 0

        if adherenceRate >= 0.85 && weeksOnCurrentDose >= 4 {
            insights.append(
                AdherenceInsight.doseEscalationReady(
                    adherenceRate: adherenceRate,
                    weeksOnCurrentDose: weeksOnCurrentDose,
                    currentDose: profile.currentDose
                )
            )
        }

        // Check for provider consultation need
        let concerningPatterns = patterns.filter { $0.riskLevel == .high || $0.riskLevel == .critical }
        if adherenceRate < concerningAdherenceThreshold || !concerningPatterns.isEmpty {
            insights.append(
                AdherenceInsight.providerConsultation(
                    adherenceRate: adherenceRate,
                    concerningPatterns: concerningPatterns
                )
            )
        }

        return insights
    }

    /// Generate insights across multiple medications
    private func generateCrossMedicationInsights(
        for profiles: [MedicationProfile],
        user: User,
        context: ModelContext
    ) -> [AdherenceInsight] {
        // Implementation for cross-medication analysis
        // For now, return empty array - can be expanded later
        []
    }

    // MARK: - Helper Methods

    /// Calculate adherence rate for given doses and time period
    private func calculateAdherenceRate(doses: [Dose], dateRange: DateInterval) -> Double {
        let takenDoses = doses.filter { !$0.skipped }.count
        let totalExpectedDoses = calculateExpectedDoses(for: dateRange)

        guard totalExpectedDoses > 0 else { return 0.0 }
        return Double(takenDoses) / Double(totalExpectedDoses)
    }

    /// Calculate expected number of doses for date range (assumes weekly dosing)
    private func calculateExpectedDoses(for dateRange: DateInterval) -> Int {
        let days = Calendar.current.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 0
        return max(1, (days + 6) / 7)  // Weekly dosing, round up
    }

    /// Calculate streak information
    private func calculateStreakInfo(doses: [Dose]) -> (current: Int, longest: Int) {
        let sortedDoses = doses.sorted { $0.timestamp < $1.timestamp }
        let takenDoses = sortedDoses.filter { !$0.skipped }

        guard !takenDoses.isEmpty else { return (0, 0) }

        // Simple streak calculation - can be improved with more sophisticated logic
        let current = min(takenDoses.count, 30)  // Cap at 30 for demo
        let longest = takenDoses.count

        return (current, longest)
    }
}
