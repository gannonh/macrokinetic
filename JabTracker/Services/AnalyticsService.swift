import Foundation
import SwiftData

/// Centralized service for coordinating analytics calculations across User, Dose, and Medication models
@Observable
final class AnalyticsService {
    // MARK: - Dependencies

    private let pharmacokineticsEngine = PharmacokineticsEngine()

    // MARK: - Unified Analytics Data Structures

    struct UserAnalyticsSummary {
        let overallAdherence: Double
        let medicationEffectiveness: [MedicationEffectiveness]
        let concentrationTrends: [ConcentrationTrend]
        let adherenceInsights: [AdherenceInsight]
        let totalActiveDays: Int
        let longestStreak: Int
        let averageTimeBetweenDoses: TimeInterval
    }

    struct MedicationEffectiveness {
        let medicationProfile: MedicationProfile
        let effectivenessScore: Double
        let adherenceRate: Double
        let concentrationOptimality: Double
        let recommendedAdjustments: [String]
    }

    struct ConcentrationTrend {
        let medicationProfile: MedicationProfile
        let averageConcentration: Double
        let timeInTherapeuticRange: Double
        let peakToTroughVariability: Double
        let trend: ConcentrationTrendDirection
    }

    struct AdherenceInsight {
        let type: AdherenceInsightType
        let description: String
        let actionableRecommendation: String
        let priority: InsightPriority
    }

    enum ConcentrationTrendDirection {
        case improving
        case stable
        case declining
        case insufficientData
    }

    enum AdherenceInsightType {
        case excellentAdherence
        case missedDosesPattern
        case timingInconsistency
        case medicationInteraction
        case doseEscalationOpportunity
    }

    enum InsightPriority {
        case high
        case medium
        case low
    }

    // MARK: - Core Analytics Methods

    /// Calculate comprehensive analytics summary for a user
    func calculateUserAnalytics(user: User, context: ModelContext) -> UserAnalyticsSummary {
        let medicationProfiles = user.medicationProfiles ?? []

        // Calculate overall adherence across all medications
        let overallAdherence = self.calculateOverallAdherence(user: user, context: context)

        // Analyze effectiveness for each medication
        let medicationEffectiveness = medicationProfiles.map { profile in
            self.calculateMedicationEffectiveness(profile: profile, user: user, context: context)
        }

        // Generate concentration trends
        let concentrationTrends = medicationProfiles.map { profile in
            self.analyzeConcentrationTrend(profile: profile)
        }

        // Generate actionable insights
        let insights = self.generateAdherenceInsights(user: user, effectiveness: medicationEffectiveness)

        return UserAnalyticsSummary(
            overallAdherence: overallAdherence,
            medicationEffectiveness: medicationEffectiveness,
            concentrationTrends: concentrationTrends,
            adherenceInsights: insights,
            totalActiveDays: self.calculateTotalActiveDays(user: user),
            longestStreak: user.longestStreak,
            averageTimeBetweenDoses: user.averageTimeBetweenDoses)
    }

    /// Calculate overall adherence across all user medications
    func calculateOverallAdherence(user: User, context: ModelContext) -> Double {
        let medicationProfiles = user.medicationProfiles ?? []
        guard !medicationProfiles.isEmpty else { return 0.0 }

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let totalAdherence = medicationProfiles.reduce(0.0) { sum, profile in
            sum + profile.calculateAdherence(from: thirtyDaysAgo, to: Date(), context: context)
        }

        return totalAdherence / Double(medicationProfiles.count)
    }

    /// Calculate effectiveness score for a specific medication profile
    func calculateMedicationEffectiveness(
        profile: MedicationProfile,
        user: User,
        context: ModelContext) -> MedicationEffectiveness
    {
        // Base effectiveness from medication properties
        let baseEffectiveness = profile.medication?.baseEffectivenessScore ?? 0.0

        // Adherence factor (adherence rate affects effectiveness)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let adherenceFactor = profile.calculateAdherence(from: thirtyDaysAgo, to: Date(), context: context)

        // Concentration optimality (based on therapeutic range)
        let concentrationOptimality = self.calculateConcentrationOptimality(profile: profile, user: user)

        // Combined effectiveness score
        let effectivenessScore = baseEffectiveness * adherenceFactor * concentrationOptimality

        // Generate recommendations
        let recommendations = self.generateRecommendations(
            profile: profile,
            adherence: adherenceFactor,
            concentration: concentrationOptimality)

        return MedicationEffectiveness(
            medicationProfile: profile,
            effectivenessScore: min(effectivenessScore, 1.0),
            adherenceRate: adherenceFactor,
            concentrationOptimality: concentrationOptimality,
            recommendedAdjustments: recommendations)
    }

    /// Generate concentration timeline analysis combining pharmacokinetics with adherence patterns
    func generateConcentrationInsights(user: User, context: ModelContext) -> [ConcentrationInsight] {
        (user.medicationProfiles ?? []).compactMap { profile in
            guard !(profile.doses ?? []).isEmpty else {
                return nil
            }

            let currentConcentration = self.pharmacokineticsEngine.calculateCurrentConcentration(
                for: user,
                medication: profile)

            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let adherenceRate = profile.calculateAdherence(from: thirtyDaysAgo, to: Date(), context: context)
            let daysOnMedication = Calendar.current.dateComponents([.day], from: profile.startDate, to: Date()).day ?? 0
            let effectivenessScore = profile.calculateEffectivenessScore(
                adherence: adherenceRate,
                timeOnMedicationDays: daysOnMedication)

            return ConcentrationInsight(
                medication: profile.medication ?? .semaglutide,
                currentConcentration: currentConcentration,
                adherenceImpact: adherenceRate,
                effectivenessCorrelation: effectivenessScore,
                recommendation: self.generateConcentrationRecommendation(
                    concentration: currentConcentration,
                    adherence: adherenceRate,
                    medication: profile.medication ?? .semaglutide))
        }
    }

    // MARK: - Private Helper Methods

    private func calculateConcentrationOptimality(profile: MedicationProfile, user: User) -> Double {
        guard !(profile.doses ?? []).isEmpty else {
            return 0.0
        }

        let currentConcentration = self.pharmacokineticsEngine.calculateCurrentConcentration(
            for: user,
            medication: profile)

        let therapeuticWindow = (profile.medication ?? .semaglutide).therapeuticWindow

        // Calculate how well the current concentration fits within therapeutic range
        if currentConcentration >= therapeuticWindow.lowerBound, currentConcentration <= therapeuticWindow.upperBound {
            // Within range - calculate optimality based on position within range
            let rangePosition = (currentConcentration - therapeuticWindow.lowerBound) /
                (therapeuticWindow.upperBound - therapeuticWindow.lowerBound)
            // Optimal around 0.6-0.8 of the range
            return 1.0 - abs(rangePosition - 0.7) / 0.3
        } else if currentConcentration < therapeuticWindow.lowerBound {
            // Below range - effectiveness decreases with distance from minimum
            return max(0.0, currentConcentration / therapeuticWindow.lowerBound)
        } else {
            // Above range - potential for side effects, effectiveness may decrease
            return max(0.0, 1.0 - (currentConcentration - therapeuticWindow.upperBound) / therapeuticWindow.upperBound)
        }
    }

    private func analyzeConcentrationTrend(profile: MedicationProfile) -> ConcentrationTrend {
        let recentDoses = (profile.doses ?? [])
            .sorted(by: { $0.timestamp > $1.timestamp })
            .prefix(10)

        guard recentDoses.count >= 3 else {
            return ConcentrationTrend(
                medicationProfile: profile,
                averageConcentration: 0.0,
                timeInTherapeuticRange: 0.0,
                peakToTroughVariability: 0.0,
                trend: .insufficientData)
        }

        // For concentration timeline, we need a way to calculate at specific timestamps
        // For now, use current concentration as approximation
        let currentConcentration = self.pharmacokineticsEngine.calculateCurrentConcentration(
            for: profile.user ?? User(email: "temp", name: "temp", appleUserId: "temp"),
            medication: profile)
        let concentrations = Array(repeating: currentConcentration, count: recentDoses.count)

        let averageConcentration = concentrations.reduce(0.0, +) / Double(concentrations.count)
        let therapeuticWindow = (profile.medication ?? .semaglutide).therapeuticWindow

        // Calculate time in therapeutic range
        let concentrationsInRange = concentrations.filter { concentration in
            concentration >= therapeuticWindow.lowerBound && concentration <= therapeuticWindow.upperBound
        }
        let timeInTherapeuticRange = Double(concentrationsInRange.count) / Double(concentrations.count)

        // Calculate variability
        let maxConcentration = concentrations.max() ?? 0.0
        let minConcentration = concentrations.min() ?? 0.0
        let peakToTroughVariability = maxConcentration > 0 ?
            (maxConcentration - minConcentration) / maxConcentration : 0.0

        // Determine trend
        let trend = self.determineTrend(concentrations: Array(concentrations))

        return ConcentrationTrend(
            medicationProfile: profile,
            averageConcentration: averageConcentration,
            timeInTherapeuticRange: timeInTherapeuticRange,
            peakToTroughVariability: peakToTroughVariability,
            trend: trend)
    }

    private func determineTrend(concentrations: [Double]) -> ConcentrationTrendDirection {
        guard concentrations.count >= 3 else { return .insufficientData }

        let firstHalf = concentrations.prefix(concentrations.count / 2)
        let secondHalf = concentrations.suffix(concentrations.count / 2)

        let firstAverage = firstHalf.reduce(0.0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0.0, +) / Double(secondHalf.count)

        let change = (secondAverage - firstAverage) / firstAverage

        if change > 0.1 {
            return .improving
        } else if change < -0.1 {
            return .declining
        } else {
            return .stable
        }
    }

    private func generateAdherenceInsights(
        user _: User,
        effectiveness: [MedicationEffectiveness]) -> [AdherenceInsight]
    {
        var insights: [AdherenceInsight] = []

        // Overall adherence insight
        let overallAdherence = effectiveness.map(\.adherenceRate).reduce(0.0, +) / Double(effectiveness.count)

        if overallAdherence >= 0.9 {
            insights.append(AdherenceInsight(
                type: .excellentAdherence,
                description: "Excellent adherence across all medications",
                actionableRecommendation: "Continue current dosing schedule",
                priority: .low))
        } else if overallAdherence < 0.7 {
            insights.append(AdherenceInsight(
                type: .missedDosesPattern,
                description: "Frequent missed doses detected",
                actionableRecommendation: "Consider setting dose reminders or adjusting schedule",
                priority: .high))
        }

        // Medication-specific insights
        for medicationEffectiveness in effectiveness {
            if medicationEffectiveness.effectivenessScore < 0.6, medicationEffectiveness.adherenceRate > 0.8 {
                insights.append(AdherenceInsight(
                    type: .doseEscalationOpportunity,
                    description: "Good adherence but low effectiveness for " +
                        "\(medicationEffectiveness.medicationProfile.medication?.displayName ?? "medication")",
                    actionableRecommendation: "Discuss dose escalation with healthcare provider",
                    priority: .medium))
            }
        }

        return insights
    }

    private func generateRecommendations(
        profile _: MedicationProfile,
        adherence: Double,
        concentration: Double) -> [String]
    {
        var recommendations: [String] = []

        if adherence < 0.8 {
            recommendations.append("Improve dose adherence with reminders or schedule adjustments")
        }

        if concentration < 0.6 {
            recommendations.append("Current concentration below optimal range - consider dose timing optimization")
        } else if concentration > 0.9 {
            recommendations.append("High concentration detected - monitor for side effects")
        }

        if adherence > 0.9, concentration > 0.8 {
            recommendations.append("Excellent medication management - maintain current approach")
        }

        return recommendations
    }

    private func calculateTotalActiveDays(user: User) -> Int {
        let allDoses = (user.medicationProfiles ?? []).flatMap { profile in
            profile.doses ?? []
        }
        let uniqueDates = Set(allDoses.map { Calendar.current.startOfDay(for: $0.timestamp) })
        return uniqueDates.count
    }

    private func generateConcentrationRecommendation(
        concentration: Double,
        adherence _: Double,
        medication: Medication) -> String
    {
        let therapeuticWindow = medication.therapeuticWindow

        if concentration < therapeuticWindow.lowerBound {
            return "Concentration below therapeutic range. Consider dose timing optimization."
        } else if concentration > therapeuticWindow.upperBound {
            return "Concentration above therapeutic range. Monitor for side effects."
        } else {
            return "Concentration within therapeutic range. Continue current regimen."
        }
    }
}

// MARK: - ConcentrationInsight Support Structure

struct ConcentrationInsight {
    let medication: Medication
    let currentConcentration: Double
    let adherenceImpact: Double
    let effectivenessCorrelation: Double
    let recommendation: String
}
