import Foundation
import Testing

@testable import JabTracker

@Suite("Schedule Pattern Filtering")
struct SchedulePatternFilteringTests {

    // MARK: - Weekly Medication Pattern Tests

    @Test("Semaglutide (weekly) returns weekly and split-dose patterns")
    func semaglutidePatterns() throws {
        // GIVEN: Semaglutide medication (weekly frequency)
        let medication = Medication.semaglutide

        // WHEN: Get available patterns from production code
        let patterns = medication.availableSchedulePatterns()

        // THEN: Should return weekly and split-dose, but NOT custom
        #expect(patterns.contains(.weekly), "Weekly medication should support weekly pattern")
        #expect(patterns.contains(.splitDose), "Weekly medication should support split-dose pattern")
        #expect(!patterns.contains(.custom), "Custom pattern should be removed from all medications")
        #expect(patterns.count == 2, "Should only have 2 patterns (weekly and split-dose)")
    }

    @Test("Tirzepatide (weekly) returns weekly and split-dose patterns")
    func tirzepatidePatterns() throws {
        // GIVEN: Tirzepatide medication (weekly frequency)
        let medication = Medication.tirzepatide

        // WHEN: Get available patterns from production code
        let patterns = medication.availableSchedulePatterns()

        // THEN: Should return weekly and split-dose, but NOT custom
        #expect(patterns.contains(.weekly), "Weekly medication should support weekly pattern")
        #expect(patterns.contains(.splitDose), "Weekly medication should support split-dose pattern")
        #expect(!patterns.contains(.custom), "Custom pattern should be removed from all medications")
        #expect(patterns.count == 2, "Should only have 2 patterns (weekly and split-dose)")
    }

    @Test("Dulaglutide (weekly) returns weekly and split-dose patterns")
    func dulaglutidePatterns() throws {
        // GIVEN: Dulaglutide medication (weekly frequency)
        let medication = Medication.dulaglutide

        // WHEN: Get available patterns from production code
        let patterns = medication.availableSchedulePatterns()

        // THEN: Should return weekly and split-dose, but NOT custom
        #expect(patterns.contains(.weekly), "Weekly medication should support weekly pattern")
        #expect(patterns.contains(.splitDose), "Weekly medication should support split-dose pattern")
        #expect(!patterns.contains(.custom), "Custom pattern should be removed from all medications")
        #expect(patterns.count == 2, "Should only have 2 patterns (weekly and split-dose)")
    }

    // MARK: - Daily Medication Pattern Tests

    @Test("Liraglutide (daily) returns ONLY daily pattern")
    func liraglutidePatterns() throws {
        // GIVEN: Liraglutide medication (daily frequency)
        let medication = Medication.liraglutide

        // WHEN: Get available patterns from production code
        let patterns = medication.availableSchedulePatterns()

        // THEN: Should return ONLY daily pattern (no split-dose, no custom)
        #expect(patterns.contains(.daily), "Daily medication should support daily pattern")
        #expect(!patterns.contains(.splitDose), "Daily medication should NOT support split-dose (already daily)")
        #expect(!patterns.contains(.custom), "Custom pattern should be removed from all medications")
        #expect(patterns.count == 1, "Should only have 1 pattern (daily)")
    }

    // MARK: - Custom Pattern Removal Tests

    @Test("No medication returns custom pattern")
    func noCustomPattern() throws {
        // GIVEN: All available medications
        let allMedications = Medication.allCases

        // WHEN: Get available patterns from production code for each medication
        for medication in allMedications {
            let patterns = medication.availableSchedulePatterns()

            // THEN: Custom pattern should NOT be in the list
            #expect(
                !patterns.contains(.custom),
                "Custom pattern should be removed from \(medication.displayName)")
        }
    }
}
