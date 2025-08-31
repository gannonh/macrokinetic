@testable import JabTracker
import Testing

@Suite("Medication Model Tests")
struct MedicationTests {
    // MARK: - Medical Properties Tests (Critical for pharmacokinetic calculations)

    @Test("Half-life days are medically accurate for all medications")
    func halfLifeDaysAccuracy() throws {
        // Test critical pharmacokinetic values - these must be medically accurate
        let semaHalfLife = Medication.semaglutide.halfLifeDays
        let tirzeHalfLife = Medication.tirzepatide.halfLifeDays
        let liraHalfLife = Medication.liraglutide.halfLifeDays
        let dulaHalfLife = Medication.dulaglutide.halfLifeDays

        #expect(semaHalfLife == 7.0, "Semaglutide half-life should be 7 days")
        #expect(tirzeHalfLife == 5.0, "Tirzepatide half-life should be 5 days")
        #expect(liraHalfLife == 0.54, "Liraglutide half-life should be 0.54 days")
        #expect(dulaHalfLife == 4.7, "Dulaglutide half-life should be 4.7 days")

        // Verify all values are positive (medical validation)
        for medication in Medication.allCases {
            let halfLife = medication.halfLifeDays
            #expect(halfLife > 0, "Half-life must be positive for \(medication.rawValue)")
        }
    }

    @Test("Dosing frequency is correct for each medication")
    func dosingFrequency() throws {
        // Test frequency - critical for dose timing calculations
        let semaFrequency = Medication.semaglutide.frequency
        let tirzeFrequency = Medication.tirzepatide.frequency
        let liraFrequency = Medication.liraglutide.frequency
        let dulaFrequency = Medication.dulaglutide.frequency

        #expect(semaFrequency == .weekly, "Semaglutide should be weekly")
        #expect(tirzeFrequency == .weekly, "Tirzepatide should be weekly")
        #expect(liraFrequency == .daily, "Liraglutide should be daily")
        #expect(dulaFrequency == .weekly, "Dulaglutide should be weekly")

        // Verify only valid frequencies are returned
        let validFrequencies: [DoseFrequency] = [.daily, .weekly]
        for medication in Medication.allCases {
            let freq = medication.frequency
            #expect(validFrequencies.contains(freq),
                    "Invalid frequency for \(medication.rawValue)")
        }
    }

    @Test("Available doses are medically accurate and properly ordered")
    func availableDoses() throws {
        // Test exact dose arrays - these are FDA-approved doses
        #expect(Medication.semaglutide.availableDoses == [0.25, 0.5, 1.0, 1.7, 2.0, 2.4])
        #expect(Medication.tirzepatide.availableDoses == [2.5, 5.0, 7.5, 10.0, 12.5, 15.0])
        #expect(Medication.liraglutide.availableDoses == [0.6, 1.2, 1.8, 2.4, 3.0])
        #expect(Medication.dulaglutide.availableDoses == [0.75, 1.5, 3.0, 4.5])

        // Verify doses are positive and ordered
        for medication in Medication.allCases {
            let doses = medication.availableDoses
            #expect(!doses.isEmpty, "Available doses should not be empty for \(medication.rawValue)")
            #expect(doses.allSatisfy { $0 > 0 }, "All doses must be positive for \(medication.rawValue)")
            #expect(doses == doses.sorted(), "Doses should be in ascending order for \(medication.rawValue)")
        }
    }

    @Test("Unit is consistent across all medications")
    func medicationUnit() throws {
        // All GLP-1 medications are measured in mg
        let semaUnit = Medication.semaglutide.unit
        let tirzeUnit = Medication.tirzepatide.unit
        let liraUnit = Medication.liraglutide.unit
        let dulaUnit = Medication.dulaglutide.unit

        #expect(semaUnit == "mg", "Semaglutide should use 'mg' as unit")
        #expect(tirzeUnit == "mg", "Tirzepatide should use 'mg' as unit")
        #expect(liraUnit == "mg", "Liraglutide should use 'mg' as unit")
        #expect(dulaUnit == "mg", "Dulaglutide should use 'mg' as unit")

        for medication in Medication.allCases {
            let unit = medication.unit
            #expect(unit == "mg", "All medications should use 'mg' as unit")
        }
    }

    // MARK: - Display Properties Tests

    @Test("Display names are properly formatted")
    func displayNames() throws {
        #expect(Medication.semaglutide.displayName == "Semaglutide")
        #expect(Medication.tirzepatide.displayName == "Tirzepatide")
        #expect(Medication.liraglutide.displayName == "Liraglutide")
        #expect(Medication.dulaglutide.displayName == "Dulaglutide")

        // Verify display names are proper case and not empty
        for medication in Medication.allCases {
            let displayName = medication.displayName
            #expect(!displayName.isEmpty, "Display name should not be empty for \(medication.rawValue)")
            #expect(
                displayName.first?.isUppercase == true,
                "Display name should be capitalized for \(medication.rawValue)")
        }
    }

    @Test("Brand names are complete and accurate")
    func brandNames() throws {
        // Test exact brand arrays - these are FDA-approved brand names
        #expect(Medication.semaglutide.brands == ["Ozempic", "Wegovy", "Rybelsus (oral)"])
        #expect(Medication.tirzepatide.brands == ["Mounjaro", "Zepbound"])
        #expect(Medication.liraglutide.brands == ["Victoza", "Saxenda"])
        #expect(Medication.dulaglutide.brands == ["Trulicity"])

        // Verify all medications have at least one brand
        for medication in Medication.allCases {
            #expect(!medication.brands.isEmpty, "Every medication should have at least one brand")
            #expect(medication.brands.allSatisfy { !$0.isEmpty },
                    "Brand names should not be empty for \(medication.rawValue)")
        }
    }

    @Test("Descriptions are informative and accurate")
    func medicationDescriptions() throws {
        let semaDescription = Medication.semaglutide.description
        let tirzeDescription = Medication.tirzepatide.description
        let liraDescription = Medication.liraglutide.description
        let dulaDescription = Medication.dulaglutide.description

        // Test key medical terms are present
        #expect(semaDescription.contains("GLP-1"), "Semaglutide description should mention GLP-1")
        #expect(semaDescription.contains("weekly"), "Semaglutide description should mention weekly dosing")

        #expect(tirzeDescription.contains("GIP/GLP-1"), "Tirzepatide description should mention dual mechanism")
        #expect(tirzeDescription.contains("weekly"), "Tirzepatide description should mention weekly dosing")

        #expect(liraDescription.contains("GLP-1"), "Liraglutide description should mention GLP-1")
        #expect(liraDescription.contains("daily"), "Liraglutide description should mention daily dosing")

        #expect(dulaDescription.contains("GLP-1"), "Dulaglutide description should mention GLP-1")
        #expect(dulaDescription.contains("weekly"), "Dulaglutide description should mention weekly dosing")

        // Verify descriptions are substantial and not empty
        for medication in Medication.allCases {
            let description = medication.description
            #expect(!description.isEmpty, "Description should not be empty for \(medication.rawValue)")
            #expect(description.count > 20, "Description should be substantial for \(medication.rawValue)")
        }
    }

    @Test("Color hex codes are valid and unique")
    func colorHexCodes() throws {
        // Test exact color values - these are used for UI theming
        let semaColor = Medication.semaglutide.colorHex
        let tirzeColor = Medication.tirzepatide.colorHex
        let liraColor = Medication.liraglutide.colorHex
        let dulaColor = Medication.dulaglutide.colorHex

        #expect(semaColor == "667eea", "Semaglutide should have color 667eea")
        #expect(tirzeColor == "764ba2", "Tirzepatide should have color 764ba2")
        #expect(liraColor == "4c5fbf", "Liraglutide should have color 4c5fbf")
        #expect(dulaColor == "8b9ff4", "Dulaglutide should have color 8b9ff4")

        // Verify hex codes are valid format and unique
        var seenColors = Set<String>()
        for medication in Medication.allCases {
            let colorHex = medication.colorHex
            #expect(colorHex.count == 6, "Color hex should be 6 characters for \(medication.rawValue)")

            // Check each character is a valid hex digit
            let isValidHex = colorHex.allSatisfy { char in
                ("0" ... "9").contains(char) || ("a" ... "f").contains(char) || ("A" ... "F").contains(char)
            }
            #expect(isValidHex, "Color hex should only contain hex digits for \(medication.rawValue)")

            #expect(!seenColors.contains(colorHex), "Color hex should be unique for \(medication.rawValue)")
            seenColors.insert(colorHex)
        }
    }

    // MARK: - Enum Conformance Tests

    @Test("All medications are identifiable with consistent IDs")
    func identifiableConformance() throws {
        // Test that id matches rawValue (required for Identifiable conformance)
        let semaId = Medication.semaglutide.id
        let tirzeId = Medication.tirzepatide.id
        let liraId = Medication.liraglutide.id
        let dulaId = Medication.dulaglutide.id

        #expect(semaId == "semaglutide", "Semaglutide ID should match raw value")
        #expect(tirzeId == "tirzepatide", "Tirzepatide ID should match raw value")
        #expect(liraId == "liraglutide", "Liraglutide ID should match raw value")
        #expect(dulaId == "dulaglutide", "Dulaglutide ID should match raw value")

        for medication in Medication.allCases {
            let id = medication.id
            let raw = medication.rawValue
            #expect(id == raw, "ID should match raw value for \(medication.rawValue)")
        }

        // Test that all IDs are unique
        let allIds = Medication.allCases.map(\.id)
        let uniqueIds = Set(allIds)
        #expect(allIds.count == uniqueIds.count, "All medication IDs should be unique")
    }

    @Test("CaseIterable provides all expected medications")
    func caseIterableConformance() throws {
        let allCases = Medication.allCases

        // Test we have all 4 expected medications
        #expect(allCases.count == 4, "Should have exactly 4 medications")
        #expect(allCases.contains(.semaglutide), "Should include semaglutide")
        #expect(allCases.contains(.tirzepatide), "Should include tirzepatide")
        #expect(allCases.contains(.liraglutide), "Should include liraglutide")
        #expect(allCases.contains(.dulaglutide), "Should include dulaglutide")
    }

    @Test("Raw values are consistent with case names")
    func rawValueConsistency() throws {
        #expect(Medication.semaglutide.rawValue == "semaglutide")
        #expect(Medication.tirzepatide.rawValue == "tirzepatide")
        #expect(Medication.liraglutide.rawValue == "liraglutide")
        #expect(Medication.dulaglutide.rawValue == "dulaglutide")

        // Test round-trip conversion
        for medication in Medication.allCases {
            let recreated = Medication(rawValue: medication.rawValue)
            #expect(recreated != nil, "Raw value should recreate medication for \(medication.rawValue)")
            #expect(recreated == medication, "Raw value round-trip should work for \(medication.rawValue)")
        }
    }

    // MARK: - Medical Validation Tests

    @Test("Pharmacokinetic properties are medically consistent")
    func pharmacokineticConsistency() throws {
        // Daily medications should have shorter half-lives
        let dailyMedications = Medication.allCases.filter { $0.frequency == .daily }
        let weeklyMedications = Medication.allCases.filter { $0.frequency == .weekly }

        #expect(!dailyMedications.isEmpty, "Should have at least one daily medication")
        #expect(!weeklyMedications.isEmpty, "Should have at least one weekly medication")

        // Verify liraglutide (daily) has the shortest half-life
        let liraHalfLife = Medication.liraglutide.halfLifeDays
        for medication in weeklyMedications {
            #expect(liraHalfLife < medication.halfLifeDays,
                    "Daily medication should have shorter half-life than \(medication.rawValue)")
        }
    }

    @Test("Dose ranges are medically appropriate")
    func doseRangesValidation() throws {
        // Verify dose ranges are within expected therapeutic ranges
        for medication in Medication.allCases {
            let doses = medication.availableDoses
            let minDose = doses.min() ?? 0
            let maxDose = doses.max() ?? 0

            // All medications should have reasonable dose ranges (not too tiny or huge)
            #expect(minDose >= 0.1, "Minimum dose should be at least 0.1mg for \(medication.rawValue)")
            #expect(maxDose <= 20.0, "Maximum dose should not exceed 20mg for \(medication.rawValue)")
            #expect(maxDose > minDose, "Max dose should be greater than min dose for \(medication.rawValue)")
        }
    }
}

// MARK: - Helper Extension

private extension Character {
    var isHexDigit: Bool {
        ("0" ... "9").contains(self) || ("a" ... "f").contains(self) || ("A" ... "F").contains(self)
    }
}
