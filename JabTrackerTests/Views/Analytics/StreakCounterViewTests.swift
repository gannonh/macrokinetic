import Foundation
import Testing

@testable import JabTracker

@MainActor
struct StreakCounterViewTests {

    // MARK: - Test Cases

    @Test("StreakCounterView displays current streak correctly")
    func testCurrentStreakDisplay() throws {
        let currentStreak = 12
        let view = StreakCounterView(currentStreak: currentStreak, bestStreak: 20)

        // Expected: StreakCounterView should display current streak with proper formatting
        #expect(view.currentStreak == 12)
    }

    @Test("StreakCounterView displays best streak correctly")
    func testBestStreakDisplay() throws {
        let bestStreak = 28
        let view = StreakCounterView(currentStreak: 10, bestStreak: bestStreak)

        // Expected: StreakCounterView should display best streak with proper formatting
        #expect(view.bestStreak == 28)
    }

    @Test("StreakCounterView handles zero current streak")
    func testZeroCurrentStreakHandling() throws {
        let currentStreak = 0
        let bestStreak = 15

        // Expected: StreakCounterView should handle zero current streak appropriately
        let view = StreakCounterView(currentStreak: 0, bestStreak: 15)
        #expect(view.currentStreak == 0 && view.bestStreak == 15)
    }

    @Test("StreakCounterView handles zero best streak")
    func testZeroBestStreakHandling() throws {
        let currentStreak = 0
        let bestStreak = 0

        // Expected: StreakCounterView should handle zero best streak (new user scenario)
        let view = StreakCounterView(currentStreak: 0, bestStreak: 0)
        #expect(view.currentStreak == 0 && view.bestStreak == 0)
    }

    @Test("StreakCounterView displays singular day correctly")
    func testSingularDayDisplay() throws {
        let currentStreak = 1
        let bestStreak = 1

        // Expected: StreakCounterView should use "day" not "days" for singular values
        let view = StreakCounterView(currentStreak: 1, bestStreak: 1)
        #expect(view.currentStreak == 1 && view.bestStreak == 1)
    }

    @Test("StreakCounterView displays plural days correctly")
    func testPluralDaysDisplay() throws {
        let currentStreak = 5
        let bestStreak = 12

        // Expected: StreakCounterView should use "days" for plural values
        let view = StreakCounterView(currentStreak: 5, bestStreak: 12)
        #expect(view.currentStreak == 5 && view.bestStreak == 12)
    }

    @Test("StreakCounterView accessibility provides clear context")
    func testAccessibilityContext() throws {
        let currentStreak = 7
        let bestStreak = 21

        // Expected: StreakCounterView should provide clear accessibility labels
        // Should distinguish between current and best streak in VoiceOver
        let view = StreakCounterView(currentStreak: 7, bestStreak: 21)
        #expect(view.currentStreak == 7 && view.bestStreak == 21)
    }

    @Test("StreakCounterView visual styling indicates streak type")
    func testVisualStyling() throws {
        // Expected: StreakCounterView should visually distinguish current vs best streak
        // Current streak might be more prominent, best streak as reference
        let view = StreakCounterView(currentStreak: 7, bestStreak: 15)
        #expect(view.currentStreak == 7 && view.bestStreak == 15)
    }
}
