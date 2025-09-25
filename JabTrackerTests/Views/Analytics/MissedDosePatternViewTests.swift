import Foundation
import SwiftUI
import Testing

@testable import JabTracker

@MainActor
struct MissedDosePatternViewTests {

    // MARK: - Test Cases

    @Test("MissedDosePatternView initializes with missed dose data")
    func testMissedDosePatternViewInitialization() throws {
        let missedDoses = [
            MissedDosePattern(date: Date(), dayOfWeek: "Monday", missedCount: 2),
            MissedDosePattern(date: Date().addingTimeInterval(-7 * 24 * 3600), dayOfWeek: "Tuesday", missedCount: 1),
        ]
        let patternView = MissedDosePatternView(missedDoses: missedDoses)

        // Expected: MissedDosePatternView should store missed dose data
        #expect(patternView.missedDoses.count == 2)
        #expect(patternView.missedDoses[0].missedCount == 2)
        #expect(patternView.missedDoses[1].missedCount == 1)
    }

    @Test("MissedDosePatternView handles empty data gracefully")
    func testMissedDosePatternViewEmptyData() throws {
        let emptyData: [MissedDosePattern] = []
        let patternView = MissedDosePatternView(missedDoses: emptyData)

        // Expected: MissedDosePatternView should handle empty data without crashing
        #expect(patternView.missedDoses.isEmpty)
    }

    @Test("MissedDosePatternView identifies worst day pattern")
    func testWorstDayIdentification() throws {
        let missedDoses = [
            MissedDosePattern(date: Date(), dayOfWeek: "Monday", missedCount: 3),
            MissedDosePattern(date: Date(), dayOfWeek: "Tuesday", missedCount: 1),
            MissedDosePattern(date: Date(), dayOfWeek: "Wednesday", missedCount: 2),
        ]
        let patternView = MissedDosePatternView(missedDoses: missedDoses)

        // Expected: MissedDosePatternView should identify Monday as worst day
        #expect(patternView.worstDay == "Monday")
    }

    @Test("MissedDosePatternView calculates total missed doses")
    func testTotalMissedDosesCalculation() throws {
        let missedDoses = [
            MissedDosePattern(date: Date(), dayOfWeek: "Monday", missedCount: 2),
            MissedDosePattern(date: Date(), dayOfWeek: "Tuesday", missedCount: 3),
            MissedDosePattern(date: Date(), dayOfWeek: "Wednesday", missedCount: 1),
        ]
        let patternView = MissedDosePatternView(missedDoses: missedDoses)

        // Expected: MissedDosePatternView should calculate total missed doses as 6
        #expect(patternView.totalMissedDoses == 6)
    }

    @Test("MissedDosePatternView provides accessibility support")
    func testAccessibilitySupport() throws {
        let missedDoses = [
            MissedDosePattern(date: Date(), dayOfWeek: "Monday", missedCount: 2)
        ]
        let patternView = MissedDosePatternView(missedDoses: missedDoses)

        // Expected: MissedDosePatternView should have accessibility identifier
        #expect(patternView.accessibilityIdentifier == "missed-dose-pattern-view")
    }

    @Test("MissedDosePatternView handles no missed doses")
    func testNoMissedDoses() throws {
        let noMissedDoses = [
            MissedDosePattern(date: Date(), dayOfWeek: "Monday", missedCount: 0),
            MissedDosePattern(date: Date(), dayOfWeek: "Tuesday", missedCount: 0),
        ]
        let patternView = MissedDosePatternView(missedDoses: noMissedDoses)

        // Expected: MissedDosePatternView should handle zero missed doses
        #expect(patternView.totalMissedDoses == 0)
        #expect(patternView.worstDay == nil)  // No worst day if no missed doses
    }

    @Test("MissedDosePatternView generates pattern insights")
    func testPatternInsightGeneration() throws {
        let missedDoses = [
            MissedDosePattern(date: Date(), dayOfWeek: "Monday", missedCount: 4),
            MissedDosePattern(date: Date(), dayOfWeek: "Tuesday", missedCount: 1),
            MissedDosePattern(date: Date(), dayOfWeek: "Wednesday", missedCount: 1),
        ]
        let patternView = MissedDosePatternView(missedDoses: missedDoses)

        // Expected: MissedDosePatternView should generate insights about Monday pattern
        #expect(patternView.hasSignificantPattern == true)
        #expect(patternView.patternInsight.contains("Monday"))
    }

    @Test("MissedDosePatternView supports different visualization styles")
    func testVisualizationStyles() throws {
        let missedDoses = [
            MissedDosePattern(date: Date(), dayOfWeek: "Monday", missedCount: 2)
        ]
        let patternView = MissedDosePatternView(missedDoses: missedDoses, style: .heatmap)

        // Expected: MissedDosePatternView should support different visualization styles
        #expect(patternView.style == .heatmap)
    }
}
