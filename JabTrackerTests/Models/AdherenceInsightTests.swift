//
//  AdherenceInsightTests.swift
//  JabTrackerTests
//
//  Tests for AdherenceInsight model
//

import Foundation
import Testing

@testable import JabTracker

struct AdherenceInsightTests {

    // MARK: - Basic Initialization Tests

    @Test("AdherenceInsight initializes with required properties")
    func testBasicInitialization() {
        let insight = AdherenceInsight(
            type: .excellentAdherence,
            title: "Test Insight",
            description: "Test description",
            actionableRecommendation: "Test recommendation",
            priority: .medium
        )

        #expect(insight.type == .excellentAdherence)
        #expect(insight.title == "Test Insight")
        #expect(insight.description == "Test description")
        #expect(insight.actionableRecommendation == "Test recommendation")
        #expect(insight.priority == .medium)
        #expect(insight.confidence == 1.0)
        #expect(insight.isActionable == true)
        #expect(insight.supportingPatterns.isEmpty)
    }

    @Test("AdherenceInsight confidence is clamped between 0.0 and 1.0")
    func testConfidenceClamping() {
        let lowConfidence = AdherenceInsight(
            type: .excellentAdherence,
            title: "Low Confidence",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .low,
            confidence: -0.5
        )
        #expect(lowConfidence.confidence == 0.0)

        let highConfidence = AdherenceInsight(
            type: .excellentAdherence,
            title: "High Confidence",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .low,
            confidence: 1.5
        )
        #expect(highConfidence.confidence == 1.0)

        let normalConfidence = AdherenceInsight(
            type: .excellentAdherence,
            title: "Normal Confidence",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .low,
            confidence: 0.75
        )
        #expect(normalConfidence.confidence == 0.75)
    }

    // MARK: - Insight Type Tests

    @Test("InsightType display names are correct")
    func testInsightTypeDisplayNames() {
        #expect(AdherenceInsight.InsightType.excellentAdherence.displayName == "Excellent Adherence")
        #expect(AdherenceInsight.InsightType.weekendReminder.displayName == "Weekend Reminder")
        #expect(AdherenceInsight.InsightType.timingOptimization.displayName == "Timing Optimization")
        #expect(AdherenceInsight.InsightType.providerConsultation.displayName == "Provider Consultation")
    }

    @Test("InsightType default icons are assigned")
    func testInsightTypeDefaultIcons() {
        #expect(AdherenceInsight.InsightType.excellentAdherence.defaultIconName == "checkmark.circle.fill")
        #expect(AdherenceInsight.InsightType.weekendReminder.defaultIconName == "calendar.badge.exclamationmark")
        #expect(AdherenceInsight.InsightType.streakMotivation.defaultIconName == "flame.fill")
        #expect(AdherenceInsight.InsightType.providerConsultation.defaultIconName == "person.badge.shield.checkmark")
    }

    // MARK: - Priority Tests

    @Test("Priority sort order is correct")
    func testPrioritySortOrder() {
        #expect(AdherenceInsight.Priority.critical.sortOrder == 0)
        #expect(AdherenceInsight.Priority.high.sortOrder == 1)
        #expect(AdherenceInsight.Priority.medium.sortOrder == 2)
        #expect(AdherenceInsight.Priority.low.sortOrder == 3)
    }

    @Test("Priority default color themes are assigned")
    func testPriorityDefaultColors() {
        #expect(AdherenceInsight.Priority.low.defaultColorTheme == .blue)
        #expect(AdherenceInsight.Priority.medium.defaultColorTheme == .orange)
        #expect(AdherenceInsight.Priority.high.defaultColorTheme == .red)
        #expect(AdherenceInsight.Priority.critical.defaultColorTheme == .purple)
    }

    // MARK: - Importance Score Tests

    @Test("Importance score calculation works correctly")
    func testImportanceScoreCalculation() {
        let lowPriorityInsight = AdherenceInsight(
            type: .excellentAdherence,
            title: "Low Priority",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .low,
            confidence: 0.8,
            clinicalSignificance: .minimal
        )

        let highPriorityInsight = AdherenceInsight(
            type: .providerConsultation,
            title: "High Priority",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .critical,
            confidence: 0.9,
            clinicalSignificance: .critical
        )

        #expect(highPriorityInsight.importanceScore > lowPriorityInsight.importanceScore)
    }

    @Test("Clinical significance affects importance score")
    func testClinicalSignificanceImportance() {
        let minimalSignificance = AdherenceInsight(
            type: .excellentAdherence,
            title: "Minimal",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .medium,
            confidence: 0.8,
            clinicalSignificance: .minimal
        )

        let criticalSignificance = AdherenceInsight(
            type: .excellentAdherence,
            title: "Critical",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .medium,
            confidence: 0.8,
            clinicalSignificance: .critical
        )

        #expect(criticalSignificance.importanceScore > minimalSignificance.importanceScore)
    }

    // MARK: - Display Logic Tests

    @Test("shouldDisplay returns correct values")
    func testShouldDisplay() {
        let highConfidenceActionable = AdherenceInsight(
            type: .excellentAdherence,
            title: "High Confidence",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .medium,
            confidence: 0.8,
            isActionable: true
        )
        #expect(highConfidenceActionable.shouldDisplay == true)

        let lowConfidenceActionable = AdherenceInsight(
            type: .excellentAdherence,
            title: "Low Confidence",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .medium,
            confidence: 0.5,
            isActionable: true
        )
        #expect(lowConfidenceActionable.shouldDisplay == false)

        let highConfidenceNotActionable = AdherenceInsight(
            type: .excellentAdherence,
            title: "Not Actionable",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .medium,
            confidence: 0.8,
            isActionable: false
        )
        #expect(highConfidenceNotActionable.shouldDisplay == false)
    }

    @Test("shortDescription truncates long descriptions")
    func testShortDescription() {
        let shortDescription = "This is a short description"
        let shortInsight = AdherenceInsight(
            type: .excellentAdherence,
            title: "Short",
            description: shortDescription,
            actionableRecommendation: "Test",
            priority: .medium
        )
        #expect(shortInsight.shortDescription == shortDescription)

        let longDescription =
            "This is a very long description that contains more than fifteen words and should be truncated by the short description method"
        let longInsight = AdherenceInsight(
            type: .excellentAdherence,
            title: "Long",
            description: longDescription,
            actionableRecommendation: "Test",
            priority: .medium
        )
        #expect(longInsight.shortDescription.hasSuffix("..."))
        #expect(longInsight.shortDescription.count < longDescription.count)
    }

    // MARK: - Supporting Pattern Tests

    @Test("supportingPatternsConfidence calculates correctly")
    func testSupportingPatternsConfidence() {
        let pattern1 = AdherencePattern(
            type: .weekendGaps,
            name: "Weekend Gaps",
            description: "Test pattern 1",
            confidence: 0.8,
            supportingDataPoints: 5,
            dateRange: DateInterval(start: Date().addingTimeInterval(-7 * 24 * 3600), end: Date()),
            frequency: .frequent
        )

        let pattern2 = AdherencePattern(
            type: .timingDrift,
            name: "Timing Drift",
            description: "Test pattern 2",
            confidence: 0.6,
            supportingDataPoints: 4,
            dateRange: DateInterval(start: Date().addingTimeInterval(-7 * 24 * 3600), end: Date()),
            frequency: .occasional
        )

        let insightWithPatterns = AdherenceInsight(
            type: .weekendReminder,
            title: "With Patterns",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .medium,
            supportingPatterns: [pattern1, pattern2]
        )

        let expectedConfidence = (0.8 + 0.6) / 2.0
        #expect(insightWithPatterns.supportingPatternsConfidence == expectedConfidence)
        #expect(insightWithPatterns.patternCount == 2)

        let insightNoPatterns = AdherenceInsight(
            type: .excellentAdherence,
            title: "No Patterns",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .medium
        )
        #expect(insightNoPatterns.supportingPatternsConfidence == 0.0)
        #expect(insightNoPatterns.patternCount == 0)
    }

    // MARK: - Factory Method Tests

    @Test("excellentAdherence factory creates correct insight")
    func testExcellentAdherenceFactory() {
        let dateRange = DateInterval(start: Date().addingTimeInterval(-30 * 24 * 3600), end: Date())
        let insight = AdherenceInsight.excellentAdherence(
            adherenceRate: 0.95,
            streakDays: 21,
            dateRange: dateRange
        )

        #expect(insight.type == .excellentAdherence)
        #expect(insight.title == "Excellent Adherence!")
        #expect(insight.description.contains("95.0%"))
        #expect(insight.description.contains("21-day"))
        #expect(insight.priority == .low)
        #expect(insight.confidence == 1.0)
        #expect(insight.colorTheme == .green)
        #expect(insight.clinicalSignificance == .significant)
        #expect(insight.isHighlighted == true)  // streak >= 14
    }

    @Test("weekendReminder factory creates correct insight")
    func testWeekendReminderFactory() {
        let pattern = AdherencePattern(
            type: .weekendGaps,
            name: "Weekend Gaps",
            description: "Weekend pattern",
            confidence: 0.85,
            supportingDataPoints: 8,
            dateRange: DateInterval(start: Date().addingTimeInterval(-30 * 24 * 3600), end: Date()),
            frequency: .frequent
        )

        let insight = AdherenceInsight.weekendReminder(
            pattern: pattern,
            missedWeekends: 3,
            totalWeekends: 4
        )

        #expect(insight.type == .weekendReminder)
        #expect(insight.title == "Weekend Dose Reminders")
        #expect(insight.description.contains("75%"))
        #expect(insight.description.contains("3 out of 4"))
        #expect(insight.priority == .medium)
        #expect(insight.confidence == 0.85)
        #expect(insight.supportingPatterns.count == 1)
        #expect(insight.colorTheme == .orange)
    }

    @Test("doseEscalationReady factory creates correct insight")
    func testDoseEscalationReadyFactory() {
        let insight = AdherenceInsight.doseEscalationReady(
            adherenceRate: 0.92,
            weeksOnCurrentDose: 6,
            currentDose: 1.0
        )

        #expect(insight.type == .doseEscalationReady)
        #expect(insight.title == "Ready for Dose Escalation")
        #expect(insight.description.contains("92.0%"))
        #expect(insight.description.contains("1.0mg"))
        #expect(insight.description.contains("6 weeks"))
        #expect(insight.priority == .high)
        #expect(insight.confidence == 0.9)
        #expect(insight.colorTheme == .purple)
        #expect(insight.isHighlighted == true)
    }

    @Test("providerConsultation factory creates correct insight")
    func testProviderConsultationFactory() {
        let pattern1 = AdherencePattern(
            type: .doseSkipping,
            name: "Dose Skipping",
            description: "Frequent dose skipping",
            confidence: 0.75,
            supportingDataPoints: 10,
            dateRange: DateInterval(start: Date().addingTimeInterval(-30 * 24 * 3600), end: Date()),
            frequency: .frequent
        )

        let pattern2 = AdherencePattern(
            type: .timingDrift,
            name: "Timing Issues",
            description: "Inconsistent timing",
            confidence: 0.68,
            supportingDataPoints: 8,
            dateRange: DateInterval(start: Date().addingTimeInterval(-30 * 24 * 3600), end: Date()),
            frequency: .occasional
        )

        let insight = AdherenceInsight.providerConsultation(
            adherenceRate: 0.55,
            concerningPatterns: [pattern1, pattern2]
        )

        #expect(insight.type == .providerConsultation)
        #expect(insight.title == "Consider Provider Consultation")
        #expect(insight.description.contains("55.0%"))
        #expect(insight.description.contains("Dose Skipping"))
        #expect(insight.description.contains("Timing Issues"))
        #expect(insight.priority == .high)
        #expect(insight.supportingPatterns.count == 2)
        #expect(insight.confidence == 0.8)
        #expect(insight.colorTheme == .red)
    }

    // MARK: - Equatable and Hashable Tests

    @Test("AdherenceInsight equality works correctly")
    func testEquality() {
        let insight1 = AdherenceInsight(
            type: .excellentAdherence,
            title: "Test 1",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .medium
        )

        let insight2 = AdherenceInsight(
            type: .weekendReminder,
            title: "Test 2",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .high
        )

        // Same instance should be equal to itself
        #expect(insight1 == insight1)

        // Different instances should not be equal (different IDs)
        #expect(insight1 != insight2)
    }

    @Test("AdherenceInsight hashing works correctly")
    func testHashing() {
        let insight1 = AdherenceInsight(
            type: .excellentAdherence,
            title: "Test 1",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .medium
        )

        let insight2 = AdherenceInsight(
            type: .weekendReminder,
            title: "Test 2",
            description: "Test",
            actionableRecommendation: "Test",
            priority: .high
        )

        // Can be used in sets
        let insightSet: Set<AdherenceInsight> = [insight1, insight2]
        #expect(insightSet.count == 2)

        // Same insight shouldn't duplicate in set
        let duplicateSet: Set<AdherenceInsight> = [insight1, insight1]
        #expect(duplicateSet.count == 1)
    }
}
