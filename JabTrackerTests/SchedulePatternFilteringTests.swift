import Foundation
import Testing

@testable import JabTracker

@Suite("Schedule Pattern Filtering")
struct SchedulePatternFilteringTests {

    // MARK: - Helper Function for Pattern Filtering

    /// Returns available schedule patterns for a given medication
    /// This will be implemented in SchedulePatternPicker
    func availablePatterns(for medication: Medication) -> [SchedulePatternType] {
        switch medication.frequency {
        case .daily:
            return [.weekly]  // Daily meds can't split further
        case .weekly:
            return [.weekly, .splitDose]  // Weekly meds can split, no custom
        }
    }

    // MARK: - Weekly Medication Pattern Tests

    @Test("Semaglutide (weekly) returns weekly and split-dose patterns")
    func semaglutidePatterns() throws {
        // GIVEN: Semaglutide medication (weekly frequency)
        let medication = Medication.semaglutide

        // WHEN: Get available patterns
        let patterns = availablePatterns(for: medication)

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

        // WHEN: Get available patterns
        let patterns = availablePatterns(for: medication)

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

        // WHEN: Get available patterns
        let patterns = availablePatterns(for: medication)

        // THEN: Should return weekly and split-dose, but NOT custom
        #expect(patterns.contains(.weekly), "Weekly medication should support weekly pattern")
        #expect(patterns.contains(.splitDose), "Weekly medication should support split-dose pattern")
        #expect(!patterns.contains(.custom), "Custom pattern should be removed from all medications")
        #expect(patterns.count == 2, "Should only have 2 patterns (weekly and split-dose)")
    }

    // MARK: - Daily Medication Pattern Tests

    @Test("Liraglutide (daily) returns ONLY weekly pattern")
    func liraglutidePatterns() throws {
        // GIVEN: Liraglutide medication (daily frequency)
        let medication = Medication.liraglutide

        // WHEN: Get available patterns
        let patterns = availablePatterns(for: medication)

        // THEN: Should return ONLY weekly pattern (no split-dose, no custom)
        #expect(patterns.contains(.weekly), "Daily medication should support weekly pattern")
        #expect(!patterns.contains(.splitDose), "Daily medication should NOT support split-dose (already daily)")
        #expect(!patterns.contains(.custom), "Custom pattern should be removed from all medications")
        #expect(patterns.count == 1, "Should only have 1 pattern (weekly)")
    }

    // MARK: - Custom Pattern Removal Tests

    @Test("No medication returns custom pattern")
    func noCustomPattern() throws {
        // GIVEN: All available medications
        let allMedications = Medication.allCases

        // WHEN: Get available patterns for each medication
        for medication in allMedications {
            let patterns = availablePatterns(for: medication)

            // THEN: Custom pattern should NOT be in the list
            #expect(
                !patterns.contains(.custom),
                "Custom pattern should be removed from \(medication.genericName)")
        }
    }
}
