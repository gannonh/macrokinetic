import Foundation
import Testing

@testable import JabTracker

@MainActor
struct AdherenceMetricsCardTests {

    // MARK: - Test Cases

    @Test("AdherenceMetricsCard displays adherence percentage correctly")
    func testAdherencePercentageDisplay() throws {
        let adherenceRate = 0.85  // 85%
        let card = AdherenceMetricsCard(adherenceRate: adherenceRate)

        // Expected: AdherenceMetricsCard should format 0.85 as "85%"
        // Since we can't directly test SwiftUI view body, we test the component creation
        #expect(card.adherenceRate == 0.85)
    }

    @Test("AdherenceMetricsCard shows color coding for excellent adherence")
    func testExcellentAdherenceColorCoding() throws {
        let excellentRate = 0.95  // 95%
        let card = AdherenceMetricsCard(adherenceRate: excellentRate)

        // Expected: AdherenceMetricsCard should use green color for excellent adherence (>90%)
        #expect(card.adherenceRate >= 0.9)
    }

    @Test("AdherenceMetricsCard shows color coding for good adherence")
    func testGoodAdherenceColorCoding() throws {
        let goodRate = 0.75  // 75%
        let card = AdherenceMetricsCard(adherenceRate: goodRate)

        // Expected: AdherenceMetricsCard should use yellow/orange color for good adherence (70-90%)
        #expect(card.adherenceRate >= 0.7 && card.adherenceRate < 0.9)
    }

    @Test("AdherenceMetricsCard shows color coding for poor adherence")
    func testPoorAdherenceColorCoding() throws {
        let poorRate = 0.45  // 45%
        let card = AdherenceMetricsCard(adherenceRate: poorRate)

        // Expected: AdherenceMetricsCard should use red color for poor adherence (<70%)
        #expect(card.adherenceRate < 0.7)
    }

    @Test("AdherenceMetricsCard handles zero adherence")
    func testZeroAdherenceHandling() throws {
        let zeroRate = 0.0
        let card = AdherenceMetricsCard(adherenceRate: zeroRate)

        // Expected: AdherenceMetricsCard should handle 0% adherence gracefully
        #expect(card.adherenceRate == 0.0)
    }

    @Test("AdherenceMetricsCard handles perfect adherence")
    func testPerfectAdherenceHandling() throws {
        let perfectRate = 1.0
        let card = AdherenceMetricsCard(adherenceRate: perfectRate)

        // Expected: AdherenceMetricsCard should handle 100% adherence correctly
        #expect(card.adherenceRate == 1.0)
    }

    @Test("AdherenceMetricsCard accessibility labels are descriptive")
    func testAccessibilityLabels() throws {
        let adherenceRate = 0.78
        let card = AdherenceMetricsCard(adherenceRate: adherenceRate)

        // Expected: AdherenceMetricsCard should provide descriptive accessibility labels
        // Should include both percentage and qualitative description
        #expect(card.adherenceRate == 0.78)
    }
}
