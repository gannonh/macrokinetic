//
//  AdherencePatternTests.swift
//  JabTrackerTests
//
//  Comprehensive tests for AdherencePattern model and its associated types
//

import Foundation
import Testing

@testable import JabTracker

struct AdherencePatternTests {

    // MARK: - AdherencePattern Initialization Tests

    @Test("AdherencePattern creation with valid data")
    func testAdherencePatternCreation() {
        // Given
        let dateRange = DateInterval(start: Date(), duration: 7 * 24 * 60 * 60)  // 1 week

        // When
        let pattern = AdherencePattern(
            type: .weekendGaps,
            name: "Weekend Gaps",
            description: "Missing doses on weekends",
            confidence: 0.85,
            supportingDataPoints: 12,
            dateRange: dateRange,
            frequency: .frequent,
            patternData: ["weekends_missed": 3, "total_weekends": 4],
            statisticalSignificance: 0.75,
            isClinicallyRelevant: true,
            riskLevel: .medium,
            affectedMedications: ["semaglutide"]
        )

        // Then
        #expect(pattern.type == .weekendGaps)
        #expect(pattern.name == "Weekend Gaps")
        #expect(pattern.description == "Missing doses on weekends")
        #expect(pattern.confidence == 0.85)
        #expect(pattern.supportingDataPoints == 12)
        #expect(pattern.dateRange == dateRange)
        #expect(pattern.frequency == .frequent)
        #expect(pattern.statisticalSignificance == 0.75)
        #expect(pattern.isClinicallyRelevant == true)
        #expect(pattern.riskLevel == .medium)
        #expect(pattern.affectedMedications == ["semaglutide"])
        #expect(!pattern.id.uuidString.isEmpty)
    }

    @Test("AdherencePattern confidence clamping")
    func testConfidenceClamping() {
        // Given
        let dateRange = DateInterval(start: Date(), duration: 24 * 60 * 60)

        // When - confidence above 1.0
        let highPattern = AdherencePattern(
            type: .perfectAdherence,
            name: "Test",
            description: "Test",
            confidence: 1.5,
            supportingDataPoints: 5,
            dateRange: dateRange,
            frequency: .constant
        )

        // When - confidence below 0.0
        let lowPattern = AdherencePattern(
            type: .perfectAdherence,
            name: "Test",
            description: "Test",
            confidence: -0.5,
            supportingDataPoints: 5,
            dateRange: dateRange,
            frequency: .constant
        )

        // Then
        #expect(highPattern.confidence == 1.0)
        #expect(lowPattern.confidence == 0.0)
    }

    @Test("AdherencePattern statistical significance clamping")
    func testStatisticalSignificanceClamping() {
        // Given
        let dateRange = DateInterval(start: Date(), duration: 24 * 60 * 60)

        // When - statistical significance above 1.0
        let highPattern = AdherencePattern(
            type: .perfectAdherence,
            name: "Test",
            description: "Test",
            confidence: 0.8,
            supportingDataPoints: 5,
            dateRange: dateRange,
            frequency: .constant,
            statisticalSignificance: 1.5
        )

        // When - statistical significance below 0.0
        let lowPattern = AdherencePattern(
            type: .perfectAdherence,
            name: "Test",
            description: "Test",
            confidence: 0.8,
            supportingDataPoints: 5,
            dateRange: dateRange,
            frequency: .constant,
            statisticalSignificance: -0.3
        )

        // Then
        #expect(highPattern.statisticalSignificance == 1.0)
        #expect(lowPattern.statisticalSignificance == 0.0)
    }

    // MARK: - PatternType Tests

    @Test("PatternType display names")
    func testPatternTypeDisplayNames() {
        // Then
        #expect(AdherencePattern.PatternType.weekendGaps.displayName == "Weekend Gaps")
        #expect(AdherencePattern.PatternType.weekdayConsistency.displayName == "Weekday Consistency")
        #expect(AdherencePattern.PatternType.timingDrift.displayName == "Timing Drift")
        #expect(AdherencePattern.PatternType.doseSkipping.displayName == "Dose Skipping")
        #expect(AdherencePattern.PatternType.perfectAdherence.displayName == "Perfect Adherence")
        #expect(AdherencePattern.PatternType.seasonalVariation.displayName == "Seasonal Variation")
        #expect(AdherencePattern.PatternType.travelDisruption.displayName == "Travel Disruption")
        #expect(AdherencePattern.PatternType.doseForgetting.displayName == "Dose Forgetting")
        #expect(AdherencePattern.PatternType.earlyDosing.displayName == "Early Dosing")
        #expect(AdherencePattern.PatternType.lateDosing.displayName == "Late Dosing")
        #expect(AdherencePattern.PatternType.inconsistentSites.displayName == "Inconsistent Sites")
        #expect(AdherencePattern.PatternType.siteRotationGood.displayName == "Good Site Rotation")
    }

    @Test("PatternType default risk levels")
    func testPatternTypeDefaultRiskLevels() {
        // Low risk patterns
        #expect(AdherencePattern.PatternType.perfectAdherence.defaultRiskLevel == .low)
        #expect(AdherencePattern.PatternType.weekdayConsistency.defaultRiskLevel == .low)
        #expect(AdherencePattern.PatternType.siteRotationGood.defaultRiskLevel == .low)

        // Medium risk patterns
        #expect(AdherencePattern.PatternType.weekendGaps.defaultRiskLevel == .medium)
        #expect(AdherencePattern.PatternType.timingDrift.defaultRiskLevel == .medium)
        #expect(AdherencePattern.PatternType.earlyDosing.defaultRiskLevel == .medium)
        #expect(AdherencePattern.PatternType.lateDosing.defaultRiskLevel == .medium)
        #expect(AdherencePattern.PatternType.inconsistentSites.defaultRiskLevel == .medium)

        // High risk patterns
        #expect(AdherencePattern.PatternType.doseSkipping.defaultRiskLevel == .high)
        #expect(AdherencePattern.PatternType.seasonalVariation.defaultRiskLevel == .high)
        #expect(AdherencePattern.PatternType.travelDisruption.defaultRiskLevel == .high)
        #expect(AdherencePattern.PatternType.doseForgetting.defaultRiskLevel == .high)
    }

    @Test("PatternType CaseIterable conformance")
    func testPatternTypeCaseIterable() {
        // Given
        let allCases = AdherencePattern.PatternType.allCases

        // Then
        #expect(allCases.count == 12)
        #expect(allCases.contains(.weekendGaps))
        #expect(allCases.contains(.perfectAdherence))
        #expect(allCases.contains(.siteRotationGood))
    }

    // MARK: - PatternFrequency Tests

    @Test("PatternFrequency display names")
    func testPatternFrequencyDisplayNames() {
        // Then
        #expect(AdherencePattern.PatternFrequency.rare.displayName == "Rarely")
        #expect(AdherencePattern.PatternFrequency.occasional.displayName == "Occasionally")
        #expect(AdherencePattern.PatternFrequency.frequent.displayName == "Frequently")
        #expect(AdherencePattern.PatternFrequency.consistent.displayName == "Consistently")
        #expect(AdherencePattern.PatternFrequency.constant.displayName == "Almost Always")
    }

    @Test("PatternFrequency percentage ranges")
    func testPatternFrequencyPercentageRanges() {
        // Then
        #expect(AdherencePattern.PatternFrequency.rare.percentageRange == 0.0...0.1)
        #expect(AdherencePattern.PatternFrequency.occasional.percentageRange == 0.1...0.3)
        #expect(AdherencePattern.PatternFrequency.frequent.percentageRange == 0.3...0.7)
        #expect(AdherencePattern.PatternFrequency.consistent.percentageRange == 0.7...0.9)
        #expect(AdherencePattern.PatternFrequency.constant.percentageRange == 0.9...1.0)
    }

    @Test("PatternFrequency fromPercentage static method")
    func testPatternFrequencyFromPercentage() {
        // Then
        #expect(AdherencePattern.PatternFrequency.fromPercentage(0.05) == .rare)
        #expect(AdherencePattern.PatternFrequency.fromPercentage(0.2) == .occasional)
        #expect(AdherencePattern.PatternFrequency.fromPercentage(0.5) == .frequent)
        #expect(AdherencePattern.PatternFrequency.fromPercentage(0.8) == .consistent)
        #expect(AdherencePattern.PatternFrequency.fromPercentage(0.95) == .constant)

        // Edge cases - boundary values now map to correct buckets with half-open ranges
        #expect(AdherencePattern.PatternFrequency.fromPercentage(0.0) == .rare)
        #expect(AdherencePattern.PatternFrequency.fromPercentage(0.1) == .occasional)  // Boundary case - maps to second bucket
        #expect(AdherencePattern.PatternFrequency.fromPercentage(0.3) == .frequent)  // Boundary case - maps to third bucket
        #expect(AdherencePattern.PatternFrequency.fromPercentage(0.7) == .consistent)  // Boundary case - maps to fourth bucket
        #expect(AdherencePattern.PatternFrequency.fromPercentage(0.9) == .constant)  // Boundary case - maps to fifth bucket
        #expect(AdherencePattern.PatternFrequency.fromPercentage(1.0) == .constant)
        #expect(AdherencePattern.PatternFrequency.fromPercentage(1.5) == .constant)  // Over 1.0 (clamped to 1.0)
        #expect(AdherencePattern.PatternFrequency.fromPercentage(-0.5) == .rare)  // Below 0.0 (clamped to 0.0)
    }

    @Test("PatternFrequency CaseIterable conformance")
    func testPatternFrequencyCaseIterable() {
        // Given
        let allCases = AdherencePattern.PatternFrequency.allCases

        // Then
        #expect(allCases.count == 5)
        #expect(allCases.contains(.rare))
        #expect(allCases.contains(.occasional))
        #expect(allCases.contains(.frequent))
        #expect(allCases.contains(.consistent))
        #expect(allCases.contains(.constant))
    }

    // MARK: - RiskLevel Tests

    @Test("RiskLevel display names")
    func testRiskLevelDisplayNames() {
        // Then
        #expect(AdherencePattern.RiskLevel.low.displayName == "Low")
        #expect(AdherencePattern.RiskLevel.medium.displayName == "Medium")
        #expect(AdherencePattern.RiskLevel.high.displayName == "High")
        #expect(AdherencePattern.RiskLevel.critical.displayName == "Critical")
    }

    @Test("RiskLevel colors")
    func testRiskLevelColors() {
        // Then
        #expect(AdherencePattern.RiskLevel.low.color == "green")
        #expect(AdherencePattern.RiskLevel.medium.color == "yellow")
        #expect(AdherencePattern.RiskLevel.high.color == "orange")
        #expect(AdherencePattern.RiskLevel.critical.color == "red")
    }

    @Test("RiskLevel CaseIterable conformance")
    func testRiskLevelCaseIterable() {
        // Given
        let allCases = AdherencePattern.RiskLevel.allCases

        // Then
        #expect(allCases.count == 4)
        #expect(allCases.contains(.low))
        #expect(allCases.contains(.medium))
        #expect(allCases.contains(.high))
        #expect(allCases.contains(.critical))
    }

    // MARK: - Pattern Analysis Helpers Tests

    @Test("shouldReport property logic")
    func testShouldReportLogic() {
        // Given
        let dateRange = DateInterval(start: Date(), duration: 24 * 60 * 60)

        // When - should report (high confidence, enough data points)
        let reportablePattern = AdherencePattern(
            type: .weekendGaps,
            name: "Test",
            description: "Test",
            confidence: 0.8,
            supportingDataPoints: 5,
            dateRange: dateRange,
            frequency: .frequent
        )

        // When - should not report (low confidence)
        let lowConfidencePattern = AdherencePattern(
            type: .weekendGaps,
            name: "Test",
            description: "Test",
            confidence: 0.6,
            supportingDataPoints: 5,
            dateRange: dateRange,
            frequency: .frequent
        )

        // When - should not report (insufficient data points)
        let lowDataPattern = AdherencePattern(
            type: .weekendGaps,
            name: "Test",
            description: "Test",
            confidence: 0.8,
            supportingDataPoints: 2,
            dateRange: dateRange,
            frequency: .frequent
        )

        // Then
        #expect(reportablePattern.shouldReport == true)
        #expect(lowConfidencePattern.shouldReport == false)
        #expect(lowDataPattern.shouldReport == false)
    }

    @Test("priorityScore calculation")
    func testPriorityScoreCalculation() {
        // Given
        let dateRange = DateInterval(start: Date(), duration: 24 * 60 * 60)

        // When - high priority pattern
        let highPriorityPattern = AdherencePattern(
            type: .doseSkipping,
            name: "Critical Issue",
            description: "Test",
            confidence: 0.9,
            supportingDataPoints: 10,
            dateRange: dateRange,
            frequency: .frequent,
            statisticalSignificance: 0.8,
            isClinicallyRelevant: true,
            riskLevel: .high
        )

        // When - low priority pattern
        let lowPriorityPattern = AdherencePattern(
            type: .perfectAdherence,
            name: "Good News",
            description: "Test",
            confidence: 0.7,
            supportingDataPoints: 5,
            dateRange: dateRange,
            frequency: .consistent,
            statisticalSignificance: 0.6,
            isClinicallyRelevant: false,
            riskLevel: .low
        )

        // Then
        #expect(highPriorityPattern.priorityScore > lowPriorityPattern.priorityScore)

        // Verify specific calculations
        let expectedHighScore = 0.9 * 0.8 * 2.0 * 1.2  // confidence * significance * risk multiplier * clinical multiplier
        let expectedLowScore = 0.7 * 0.6 * 1.0 * 1.0

        #expect(abs(highPriorityPattern.priorityScore - expectedHighScore) < 0.01)
        #expect(abs(lowPriorityPattern.priorityScore - expectedLowScore) < 0.01)
    }

    @Test("shortSummary property")
    func testShortSummary() {
        // Given
        let dateRange = DateInterval(start: Date(), duration: 24 * 60 * 60)
        let pattern = AdherencePattern(
            type: .weekendGaps,
            name: "Weekend Issues",
            description: "Test",
            confidence: 0.847,
            supportingDataPoints: 8,
            dateRange: dateRange,
            frequency: .frequent
        )

        // When
        let summary = pattern.shortSummary

        // Then
        #expect(summary == "Weekend Issues: 84% confidence")
    }

    @Test("getPatternValue method")
    func testGetPatternValue() {
        // Given
        let dateRange = DateInterval(start: Date(), duration: 24 * 60 * 60)
        let patternData: [String: Any] = [
            "missed_weekends": 3,
            "total_weekends": 4,
            "percentage": 0.75,
            "description": "Weekend pattern",
        ]

        let pattern = AdherencePattern(
            type: .weekendGaps,
            name: "Test",
            description: "Test",
            confidence: 0.8,
            supportingDataPoints: 5,
            dateRange: dateRange,
            frequency: .frequent,
            patternData: patternData
        )

        // When & Then
        let missedWeekends: Int? = pattern.getPatternValue(for: "missed_weekends", as: Int.self)
        let percentage: Double? = pattern.getPatternValue(for: "percentage", as: Double.self)
        let description: String? = pattern.getPatternValue(for: "description", as: String.self)
        let nonExistent: String? = pattern.getPatternValue(for: "nonexistent", as: String.self)

        #expect(missedWeekends == 3)
        #expect(percentage == 0.75)
        #expect(description == "Weekend pattern")
        #expect(nonExistent == nil)
    }

    // MARK: - Equatable and Hashable Tests

    @Test("AdherencePattern Equatable conformance")
    func testAdherencePatternEquality() {
        // Given
        let dateRange = DateInterval(start: Date(), duration: 24 * 60 * 60)
        let pattern1 = AdherencePattern(
            type: .weekendGaps,
            name: "Test",
            description: "Test",
            confidence: 0.8,
            supportingDataPoints: 5,
            dateRange: dateRange,
            frequency: .frequent
        )

        let pattern2 = AdherencePattern(
            type: .weekendGaps,
            name: "Test",
            description: "Test",
            confidence: 0.8,
            supportingDataPoints: 5,
            dateRange: dateRange,
            frequency: .frequent
        )

        // Then - different patterns have different IDs, so they're not equal
        #expect(pattern1 != pattern2)
        #expect(pattern1 == pattern1)  // Same instance is equal to itself
    }

    @Test("AdherencePattern Hashable conformance")
    func testAdherencePatternHashable() {
        // Given
        let dateRange = DateInterval(start: Date(), duration: 24 * 60 * 60)
        let pattern = AdherencePattern(
            type: .weekendGaps,
            name: "Test",
            description: "Test",
            confidence: 0.8,
            supportingDataPoints: 5,
            dateRange: dateRange,
            frequency: .frequent
        )

        // When
        let set = Set([pattern])

        // Then
        #expect(set.count == 1)
        #expect(set.contains(pattern))
    }

    // MARK: - Factory Methods Tests

    @Test("weekendGapPattern factory method")
    func testWeekendGapPatternFactory() {
        // Given
        let dateRange = DateInterval(start: Date(), duration: 28 * 24 * 60 * 60)  // 4 weeks

        // When
        let pattern = AdherencePattern.weekendGapPattern(
            confidence: 0.85,
            supportingDataPoints: 12,
            dateRange: dateRange,
            missedWeekends: 3,
            totalWeekends: 4
        )

        // Then
        #expect(pattern.type == .weekendGaps)
        #expect(pattern.name == "Weekend Dose Gaps")
        #expect(pattern.description == "Tendency to miss doses on weekends (3/4 weekends)")
        #expect(pattern.confidence == 0.85)
        #expect(pattern.supportingDataPoints == 12)
        #expect(pattern.dateRange == dateRange)
        #expect(pattern.frequency == .consistent)  // 3/4 = 0.75 maps to consistent (0.7...0.9)
        #expect(pattern.statisticalSignificance == 0.85)
        #expect(pattern.isClinicallyRelevant == true)
        #expect(pattern.riskLevel == .medium)

        // Verify pattern data
        let missedWeekends: Int? = pattern.getPatternValue(for: "missed_weekends", as: Int.self)
        let totalWeekends: Int? = pattern.getPatternValue(for: "total_weekends", as: Int.self)
        let percentage: Double? = pattern.getPatternValue(for: "percentage", as: Double.self)

        #expect(missedWeekends == 3)
        #expect(totalWeekends == 4)
        #expect(percentage == 0.75)
    }

    @Test("timingDriftPattern factory method")
    func testTimingDriftPatternFactory() {
        // Given
        let dateRange = DateInterval(start: Date(), duration: 14 * 24 * 60 * 60)  // 2 weeks
        let driftHours: TimeInterval = 2.5 * 3600  // 2.5 hours

        // When
        let pattern = AdherencePattern.timingDriftPattern(
            confidence: 0.9,
            supportingDataPoints: 20,
            dateRange: dateRange,
            averageDrift: driftHours,
            driftDirection: "later"
        )

        // Then
        #expect(pattern.type == .timingDrift)
        #expect(pattern.name == "Dose Timing Drift")
        #expect(pattern.description == "Doses are trending later by 2.5 hours on average")
        #expect(pattern.confidence == 0.9)
        #expect(pattern.supportingDataPoints == 20)
        #expect(pattern.dateRange == dateRange)
        #expect(pattern.frequency == .frequent)
        #expect(pattern.statisticalSignificance == 0.9)
        #expect(pattern.isClinicallyRelevant == true)
        #expect(pattern.riskLevel == .medium)  // < 6 hours drift = medium risk

        // Verify pattern data
        let averageDriftHours: Double? = pattern.getPatternValue(for: "average_drift_hours", as: Double.self)
        let driftDirection: String? = pattern.getPatternValue(for: "drift_direction", as: String.self)

        #expect(averageDriftHours == 2.5)
        #expect(driftDirection == "later")
    }

    @Test("timingDriftPattern with high drift shows high risk")
    func testTimingDriftPatternHighRisk() {
        // Given
        let dateRange = DateInterval(start: Date(), duration: 14 * 24 * 60 * 60)
        let driftHours: TimeInterval = 8 * 3600  // 8 hours

        // When
        let pattern = AdherencePattern.timingDriftPattern(
            confidence: 0.8,
            supportingDataPoints: 15,
            dateRange: dateRange,
            averageDrift: driftHours,
            driftDirection: "earlier"
        )

        // Then
        #expect(pattern.riskLevel == .high)  // > 6 hours drift = high risk
        #expect(pattern.description == "Doses are trending earlier by 8.0 hours on average")
    }

    // MARK: - Integration Tests

    @Test("Pattern frequency mapping integration")
    func testPatternFrequencyMappingIntegration() {
        // Given various percentage scenarios
        let testCases: [(Double, AdherencePattern.PatternFrequency)] = [
            (0.02, .rare),
            (0.15, .occasional),
            (0.45, .frequent),
            (0.82, .consistent),
            (0.97, .constant),
        ]

        // When & Then
        for (percentage, expectedFrequency) in testCases {
            let frequency = AdherencePattern.PatternFrequency.fromPercentage(percentage)
            #expect(
                frequency == expectedFrequency,
                "Percentage \(percentage) should map to \(expectedFrequency), got \(frequency)")
        }
    }

    @Test("Pattern prioritization sorting")
    func testPatternPrioritizationSorting() {
        // Given
        let dateRange = DateInterval(start: Date(), duration: 24 * 60 * 60)

        let patterns = [
            AdherencePattern(
                type: .perfectAdherence,
                name: "Good",
                description: "Test",
                confidence: 0.7,
                supportingDataPoints: 5,
                dateRange: dateRange,
                frequency: .consistent,
                statisticalSignificance: 0.6,
                riskLevel: .low
            ),
            AdherencePattern(
                type: .doseSkipping,
                name: "Critical",
                description: "Test",
                confidence: 0.9,
                supportingDataPoints: 10,
                dateRange: dateRange,
                frequency: .frequent,
                statisticalSignificance: 0.8,
                riskLevel: .high
            ),
            AdherencePattern(
                type: .timingDrift,
                name: "Medium",
                description: "Test",
                confidence: 0.8,
                supportingDataPoints: 8,
                dateRange: dateRange,
                frequency: .frequent,
                statisticalSignificance: 0.7,
                riskLevel: .medium
            ),
        ]

        // When
        let sortedPatterns = patterns.sorted { $0.priorityScore > $1.priorityScore }

        // Then - should be sorted by priority score (highest first)
        #expect(sortedPatterns[0].type == .doseSkipping)  // Highest priority
        #expect(sortedPatterns[1].type == .timingDrift)  // Medium priority
        #expect(sortedPatterns[2].type == .perfectAdherence)  // Lowest priority
    }
}
