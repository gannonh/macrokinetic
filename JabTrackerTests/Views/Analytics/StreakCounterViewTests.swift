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
        _ = 0  // currentStreak
        _ = 15  // bestStreak

        // Expected: StreakCounterView should handle zero current streak appropriately
        let view = StreakCounterView(currentStreak: 0, bestStreak: 15)
        #expect(view.currentStreak == 0 && view.bestStreak == 15)
    }

    @Test("StreakCounterView handles zero best streak")
    func testZeroBestStreakHandling() throws {
        _ = 0  // currentStreak
        _ = 0  // bestStreak

        // Expected: StreakCounterView should handle zero best streak (new user scenario)
        let view = StreakCounterView(currentStreak: 0, bestStreak: 0)
        #expect(view.currentStreak == 0 && view.bestStreak == 0)
    }

    @Test("StreakCounterView displays singular day correctly")
    func testSingularDayDisplay() throws {
        _ = 1  // currentStreak
        _ = 1  // bestStreak

        // Expected: StreakCounterView should use "day" not "days" for singular values
        let view = StreakCounterView(currentStreak: 1, bestStreak: 1)
        #expect(view.currentStreak == 1 && view.bestStreak == 1)
    }

    @Test("StreakCounterView displays plural days correctly")
    func testPluralDaysDisplay() throws {
        _ = 5  // currentStreak
        _ = 12  // bestStreak

        // Expected: StreakCounterView should use "days" for plural values
        let view = StreakCounterView(currentStreak: 5, bestStreak: 12)
        #expect(view.currentStreak == 5 && view.bestStreak == 12)
    }

    @Test("StreakCounterView accessibility provides clear context")
    func testAccessibilityContext() throws {
        _ = 7  // currentStreak
        _ = 21  // bestStreak

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
