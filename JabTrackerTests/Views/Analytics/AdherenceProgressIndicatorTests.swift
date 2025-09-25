import Foundation
import SwiftUI
import Testing

@testable import JabTracker

@MainActor
struct AdherenceProgressIndicatorTests {

    // MARK: - Test Cases

    @Test("AdherenceProgressIndicator initializes with progress values")
    func testAdherenceProgressIndicatorInitialization() throws {
        let currentAdherence = 0.75
        let targetAdherence = 0.8
        let indicator = AdherenceProgressIndicator(
            currentAdherence: currentAdherence,
            targetAdherence: targetAdherence,
            periodLabel: "This month"
        )

        // Expected: AdherenceProgressIndicator should store progress values
        #expect(indicator.currentAdherence == 0.75)
        #expect(indicator.targetAdherence == 0.8)
        #expect(indicator.periodLabel == "This month")
    }

    @Test("AdherenceProgressIndicator calculates progress percentage correctly")
    func testProgressPercentageCalculation() throws {
        let indicator = AdherenceProgressIndicator(
            currentAdherence: 0.6,
            targetAdherence: 0.8
        )

        // Expected: Progress percentage should be 0.6 / 0.8 = 0.75 (with tolerance for floating point precision)
        let expectedProgress = 0.75
        let tolerance = 0.001
        #expect(abs(indicator.progressPercentage - expectedProgress) < tolerance)
    }

    @Test("AdherenceProgressIndicator identifies goal achieved")
    func testGoalAchieved() throws {
        let indicator = AdherenceProgressIndicator(
            currentAdherence: 0.85,
            targetAdherence: 0.8
        )

        // Expected: Goal should be achieved when current >= target
        #expect(indicator.goalAchieved == true)
        #expect(indicator.progressPercentage >= 1.0)
    }

    @Test("AdherenceProgressIndicator identifies goal not achieved")
    func testGoalNotAchieved() throws {
        let indicator = AdherenceProgressIndicator(
            currentAdherence: 0.65,
            targetAdherence: 0.8
        )

        // Expected: Goal should not be achieved when current < target
        #expect(indicator.goalAchieved == false)
        #expect(indicator.progressPercentage < 1.0)
    }

    @Test("AdherenceProgressIndicator provides correct adherence color for success")
    func testAdherenceColorSuccess() throws {
        let indicator = AdherenceProgressIndicator(
            currentAdherence: 0.9,
            targetAdherence: 0.8
        )

        // Expected: Success color when goal is achieved
        #expect(indicator.adherenceColor == DesignTokens.Colors.success)
    }

    @Test("AdherenceProgressIndicator provides correct adherence color for warning")
    func testAdherenceColorWarning() throws {
        let indicator = AdherenceProgressIndicator(
            currentAdherence: 0.68,  // 68% of 80% target = 0.85 progress (>= 0.8)
            targetAdherence: 0.8
        )

        // Expected: Warning color when progress >= 0.8 but < 1.0
        #expect(indicator.adherenceColor == DesignTokens.Colors.warning)
    }

    @Test("AdherenceProgressIndicator provides correct adherence color for danger")
    func testAdherenceColorDanger() throws {
        let indicator = AdherenceProgressIndicator(
            currentAdherence: 0.5,
            targetAdherence: 0.8
        )

        // Expected: Danger color when progress < 0.8
        #expect(indicator.adherenceColor == DesignTokens.Colors.danger)
    }

    @Test("AdherenceProgressIndicator formats adherence text correctly")
    func testAdherenceTextFormatting() throws {
        let indicator = AdherenceProgressIndicator(
            currentAdherence: 0.856,  // Should round to 85%
            targetAdherence: 0.8
        )

        // Expected: Percentage should be formatted as integer
        #expect(indicator.currentAdherenceText == "85%")
        #expect(indicator.targetAdherenceText == "80%")
    }

    @Test("AdherenceProgressIndicator provides correct status messages")
    func testStatusMessages() throws {
        // Goal achieved
        let achievedIndicator = AdherenceProgressIndicator(
            currentAdherence: 0.9,
            targetAdherence: 0.8
        )
        #expect(achievedIndicator.statusMessage == "Goal achieved!")

        // Goal not achieved
        let notAchievedIndicator = AdherenceProgressIndicator(
            currentAdherence: 0.6,
            targetAdherence: 0.8
        )
        #expect(notAchievedIndicator.statusMessage == "20% to goal")
    }

    @Test("AdherenceProgressIndicator handles edge cases")
    func testEdgeCases() throws {
        // Zero target adherence
        let zeroTargetIndicator = AdherenceProgressIndicator(
            currentAdherence: 0.5,
            targetAdherence: 0.0
        )
        #expect(zeroTargetIndicator.progressPercentage == 0)

        // Values out of range are clamped
        let outOfRangeIndicator = AdherenceProgressIndicator(
            currentAdherence: 1.5,  // Should be clamped to 1.0
            targetAdherence: 0.8
        )
        #expect(outOfRangeIndicator.currentAdherence == 1.0)

        // Negative values are clamped to 0
        let negativeIndicator = AdherenceProgressIndicator(
            currentAdherence: -0.1,  // Should be clamped to 0.0
            targetAdherence: 0.8
        )
        #expect(negativeIndicator.currentAdherence == 0.0)
    }

    @Test("AdherenceProgressIndicator provides accessibility support")
    func testAccessibilitySupport() throws {
        let indicator = AdherenceProgressIndicator(
            currentAdherence: 0.75,
            targetAdherence: 0.8
        )

        // Expected: AdherenceProgressIndicator should have accessibility identifier
        #expect(indicator.accessibilityIdentifier == "adherence-progress-indicator")
    }

    @Test("AdherenceProgressIndicator uses default values correctly")
    func testDefaultValues() throws {
        let indicator = AdherenceProgressIndicator(currentAdherence: 0.7)

        // Expected: Default target should be 0.8 (80%)
        #expect(indicator.targetAdherence == 0.8)
        #expect(indicator.periodLabel == "This month")
    }
}
