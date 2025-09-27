//
//  AdherenceInsight.swift
//  JabTracker
//
//  Model for representing actionable adherence insights and recommendations
//

// swiftlint:disable file_length
import Foundation

/// Represents an actionable insight derived from adherence pattern analysis
struct AdherenceInsight {
    // MARK: - Basic Properties

    /// Unique identifier for the insight
    let id: UUID = UUID()

    /// Type of insight
    let type: InsightType

    /// Title of the insight
    let title: String

    /// Detailed description of the insight
    let description: String

    /// Actionable recommendation for the user
    let actionableRecommendation: String

    /// Priority level for displaying to user
    let priority: Priority

    // MARK: - Evidence and Context

    /// Patterns that support this insight
    let supportingPatterns: [AdherencePattern]

    /// Confidence level of this insight (0.0 to 1.0)
    let confidence: Double

    /// Date range for which this insight is relevant
    let dateRange: DateInterval

    /// Whether this insight is currently actionable
    let isActionable: Bool

    // MARK: - Medical Context

    /// Clinical significance of this insight
    let clinicalSignificance: ClinicalSignificance

    /// Potential impact on treatment outcomes
    let treatmentImpact: TreatmentImpact

    /// Medications this insight relates to
    let relatedMedications: [String]

    // MARK: - User Interface

    /// Icon name for displaying the insight
    let iconName: String

    /// Color theme for the insight
    let colorTheme: ColorTheme

    /// Whether insight should be prominently displayed
    let isHighlighted: Bool

    // MARK: - Initialization

    init(
        type: InsightType,
        title: String,
        description: String,
        actionableRecommendation: String,
        priority: Priority,
        supportingPatterns: [AdherencePattern] = [],
        confidence: Double = 1.0,
        dateRange: DateInterval = DateInterval(start: Date().addingTimeInterval(-30 * 24 * 3600), end: Date()),
        isActionable: Bool = true,
        clinicalSignificance: ClinicalSignificance = .moderate,
        treatmentImpact: TreatmentImpact = .moderate,
        relatedMedications: [String] = [],
        iconName: String? = nil,
        colorTheme: ColorTheme? = nil,
        isHighlighted: Bool = false
    ) {
        self.type = type
        self.title = title
        self.description = description
        self.actionableRecommendation = actionableRecommendation
        self.priority = priority
        self.supportingPatterns = supportingPatterns
        self.confidence = max(0.0, min(1.0, confidence))
        self.dateRange = dateRange
        self.isActionable = isActionable
        self.clinicalSignificance = clinicalSignificance
        self.treatmentImpact = treatmentImpact
        self.relatedMedications = relatedMedications
        self.iconName = iconName ?? type.defaultIconName
        self.colorTheme = colorTheme ?? priority.defaultColorTheme
        self.isHighlighted = isHighlighted
    }
}

// MARK: - Insight Types

extension AdherenceInsight {
    enum InsightType: String, CaseIterable {
        case excellentAdherence = "excellent_adherence"
        case consistentTiming = "consistent_timing"
        case weekendReminder = "weekend_reminder"
        case timingOptimization = "timing_optimization"
        case streakMotivation = "streak_motivation"
        case siteRotationReminder = "site_rotation_reminder"
        case scheduleAdjustment = "schedule_adjustment"
        case adherenceImprovement = "adherence_improvement"
        case missedDosePattern = "missed_dose_pattern"
        case doseEscalationReady = "dose_escalation_ready"
        case providerConsultation = "provider_consultation"
        case medicationEffectiveness = "medication_effectiveness"

        var displayName: String {
            switch self {
            case .excellentAdherence: return "Excellent Adherence"
            case .consistentTiming: return "Consistent Timing"
            case .weekendReminder: return "Weekend Reminder"
            case .timingOptimization: return "Timing Optimization"
            case .streakMotivation: return "Streak Achievement"
            case .siteRotationReminder: return "Site Rotation"
            case .scheduleAdjustment: return "Schedule Adjustment"
            case .adherenceImprovement: return "Adherence Improvement"
            case .missedDosePattern: return "Missed Dose Pattern"
            case .doseEscalationReady: return "Dose Escalation"
            case .providerConsultation: return "Provider Consultation"
            case .medicationEffectiveness: return "Medication Effectiveness"
            }
        }

        var defaultIconName: String {
            switch self {
            case .excellentAdherence: return "checkmark.circle.fill"
            case .consistentTiming: return "clock.fill"
            case .weekendReminder: return "calendar.badge.exclamationmark"
            case .timingOptimization: return "clock.arrow.circlepath"
            case .streakMotivation: return "flame.fill"
            case .siteRotationReminder: return "arrow.triangle.2.circlepath"
            case .scheduleAdjustment: return "calendar.badge.clock"
            case .adherenceImprovement: return "chart.line.uptrend.xyaxis"
            case .missedDosePattern: return "exclamationmark.triangle.fill"
            case .doseEscalationReady: return "arrow.up.circle.fill"
            case .providerConsultation: return "person.badge.shield.checkmark"
            case .medicationEffectiveness: return "cross.case.fill"
            }
        }
    }

    enum Priority: String, CaseIterable {
        case low
        case medium
        case high
        case critical

        var displayName: String {
            rawValue.capitalized
        }

        var sortOrder: Int {
            switch self {
            case .critical: return 0
            case .high: return 1
            case .medium: return 2
            case .low: return 3
            }
        }

        var defaultColorTheme: ColorTheme {
            switch self {
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            case .critical: return .purple
            }
        }
    }

    enum ClinicalSignificance: String, CaseIterable {
        case minimal
        case moderate
        case significant
        case critical

        var displayName: String {
            rawValue.capitalized
        }
    }

    enum TreatmentImpact: String, CaseIterable {
        case minimal
        case moderate
        case significant
        case critical

        var displayName: String {
            rawValue.capitalized
        }
    }

    enum ColorTheme: String, CaseIterable {
        case blue
        case green
        case orange
        case red
        case purple
        case gray

        var displayName: String {
            rawValue.capitalized
        }
    }
}

// MARK: - Insight Analysis

extension AdherenceInsight {
    /// Overall importance score for sorting insights
    var importanceScore: Double {
        let priorityWeight: Double
        switch priority {
        case .critical: priorityWeight = 4.0
        case .high: priorityWeight = 3.0
        case .medium: priorityWeight = 2.0
        case .low: priorityWeight = 1.0
        }

        let clinicalWeight: Double
        switch clinicalSignificance {
        case .critical: clinicalWeight = 2.0
        case .significant: clinicalWeight = 1.5
        case .moderate: clinicalWeight = 1.0
        case .minimal: clinicalWeight = 0.5
        }

        return priorityWeight * clinicalWeight * confidence
    }

    /// Whether this insight should be shown to the user
    var shouldDisplay: Bool {
        confidence >= 0.6 && isActionable
    }

    /// Short description for compact display
    var shortDescription: String {
        let words = description.components(separatedBy: " ")
        if words.count > 15 {
            return words.prefix(15).joined(separator: " ") + "..."
        }
        return description
    }

    /// Number of supporting patterns
    var patternCount: Int {
        supportingPatterns.count
    }

    /// Average confidence of supporting patterns
    var supportingPatternsConfidence: Double {
        guard !supportingPatterns.isEmpty else { return 0.0 }
        let totalConfidence = supportingPatterns.map(\.confidence).reduce(0, +)
        return totalConfidence / Double(supportingPatterns.count)
    }
}

// MARK: - Insight Creation Helpers

extension AdherenceInsight {
    /// Create an excellent adherence insight
    static func excellentAdherence(
        adherenceRate: Double,
        streakDays: Int,
        dateRange: DateInterval
    ) -> AdherenceInsight {
        let percentageString = String(format: "%.1f%%", adherenceRate * 100)

        return AdherenceInsight(
            type: .excellentAdherence,
            title: "Excellent Adherence!",
            description:
                "You've maintained \(percentageString) adherence with a \(streakDays)-day streak. "
                + "Outstanding medication management!",
            actionableRecommendation:
                "Continue your current approach and celebrate this achievement. "
                + "Your consistent adherence is supporting optimal treatment outcomes.",
            priority: .low,
            confidence: 1.0,
            dateRange: dateRange,
            clinicalSignificance: .significant,
            treatmentImpact: .significant,
            colorTheme: .green,
            isHighlighted: streakDays >= 14
        )
    }

    /// Create a weekend reminder insight
    static func weekendReminder(
        pattern: AdherencePattern,
        missedWeekends: Int,
        totalWeekends: Int
    ) -> AdherenceInsight {
        // Guard against division by zero
        guard totalWeekends > 0 else {
            return AdherenceInsight(
                type: .weekendReminder,
                title: "Weekend Dose Reminders",
                description: "No weekend data available yet. Track your doses for a few weekends to get insights.",
                actionableRecommendation: "Continue tracking your weekend doses to build a pattern.",
                priority: .low,
                supportingPatterns: [pattern],
                confidence: pattern.confidence,
                dateRange: pattern.dateRange,
                clinicalSignificance: .minimal,
                treatmentImpact: .minimal,
                colorTheme: .orange
            )
        }

        let percentage = Int((Double(missedWeekends) / Double(totalWeekends)) * 100)

        return AdherenceInsight(
            type: .weekendReminder,
            title: "Weekend Dose Reminders",
            description:
                "You've missed doses on \(percentage)% of weekends (\(missedWeekends) out of \(totalWeekends)). "
                + "Weekend routines can be different from weekdays.",
            actionableRecommendation:
                "Set weekend-specific reminders or link your dose to a consistent weekend activity "
                + "like morning coffee.",
            priority: .medium,
            supportingPatterns: [pattern],
            confidence: pattern.confidence,
            dateRange: pattern.dateRange,
            clinicalSignificance: .moderate,
            treatmentImpact: .moderate,
            colorTheme: .orange
        )
    }

    /// Create a dose escalation ready insight
    static func doseEscalationReady(
        adherenceRate: Double,
        weeksOnCurrentDose: Int,
        currentDose: Double
    ) -> AdherenceInsight {
        AdherenceInsight(
            type: .doseEscalationReady,
            title: "Ready for Dose Escalation",
            description:
                "You've maintained excellent adherence (\(String(format: "%.1f%%", adherenceRate * 100))) "
                + "on \(currentDose)mg for \(weeksOnCurrentDose) weeks.",
            actionableRecommendation:
                "Discuss dose escalation with your healthcare provider to optimize " + "treatment effectiveness.",
            priority: .high,
            confidence: 0.9,
            clinicalSignificance: .significant,
            treatmentImpact: .significant,
            colorTheme: .purple,
            isHighlighted: true
        )
    }

    /// Create a provider consultation insight
    static func providerConsultation(
        adherenceRate: Double,
        concerningPatterns: [AdherencePattern]
    ) -> AdherenceInsight {
        let patternNames = concerningPatterns.map(\.name).joined(separator: ", ")

        return AdherenceInsight(
            type: .providerConsultation,
            title: "Consider Provider Consultation",
            description:
                "Your adherence rate (\(String(format: "%.1f%%", adherenceRate * 100))) and "
                + "patterns (\(patternNames)) may benefit from professional guidance.",
            actionableRecommendation:
                "Schedule an appointment with your healthcare provider to discuss your "
                + "medication routine and any challenges you're experiencing.",
            priority: .high,
            supportingPatterns: concerningPatterns,
            confidence: 0.8,
            clinicalSignificance: .significant,
            treatmentImpact: .critical,
            colorTheme: .red
        )
    }
}

// MARK: - Equatable and Hashable

extension AdherenceInsight: Equatable, Hashable {
    static func == (lhs: AdherenceInsight, rhs: AdherenceInsight) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
