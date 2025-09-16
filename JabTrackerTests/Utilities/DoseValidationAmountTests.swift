//
//  DoseValidationAmountTests.swift
//  JabTrackerTests
//

import Foundation
@testable import JabTracker
import Testing

/// Comprehensive test suite for dose amount and precision validation
/// Safety-critical testing for GLP-1 medication dosing validation
@Suite("Dose Amount & Precision Validation Tests")
struct DoseValidationAmountTests {
    // MARK: - Dose Amount Validation Tests

    @Suite("Dose Amount Validation")
    struct DoseAmountValidationTests {
        @Test("Valid dose amounts for brand-specific medications")
        func validDoseAmountsByBrand() async throws {
            // Semaglutide - Ozempic
            #expect(DoseValidation.isValidDoseAmount(0.25, for: .semaglutide, brand: "Ozempic"))
            #expect(DoseValidation.isValidDoseAmount(0.5, for: .semaglutide, brand: "Ozempic"))
            #expect(DoseValidation.isValidDoseAmount(1.0, for: .semaglutide, brand: "Ozempic"))
            #expect(DoseValidation.isValidDoseAmount(2.0, for: .semaglutide, brand: "Ozempic"))

            // Semaglutide - Wegovy has different available doses
            #expect(DoseValidation.isValidDoseAmount(1.7, for: .semaglutide, brand: "Wegovy"))
            #expect(DoseValidation.isValidDoseAmount(2.4, for: .semaglutide, brand: "Wegovy"))

            // Tirzepatide - Mounjaro
            #expect(DoseValidation.isValidDoseAmount(2.5, for: .tirzepatide, brand: "Mounjaro"))
            #expect(DoseValidation.isValidDoseAmount(5.0, for: .tirzepatide, brand: "Mounjaro"))
            #expect(DoseValidation.isValidDoseAmount(15.0, for: .tirzepatide, brand: "Mounjaro"))

            // Liraglutide - Saxenda
            #expect(DoseValidation.isValidDoseAmount(0.6, for: .liraglutide, brand: "Saxenda"))
            #expect(DoseValidation.isValidDoseAmount(3.0, for: .liraglutide, brand: "Saxenda"))

            // Dulaglutide - Trulicity
            #expect(DoseValidation.isValidDoseAmount(0.75, for: .dulaglutide, brand: "Trulicity"))
            #expect(DoseValidation.isValidDoseAmount(4.5, for: .dulaglutide, brand: "Trulicity"))
        }

        @Test("Invalid dose amounts are rejected")
        func invalidDoseAmounts() async throws {
            // Zero and negative doses
            #expect(!DoseValidation.isValidDoseAmount(0.0, for: .semaglutide, brand: "Ozempic"))
            #expect(!DoseValidation.isValidDoseAmount(-0.5, for: .semaglutide, brand: "Ozempic"))

            // Doses not available for specific brands
            #expect(!DoseValidation.isValidDoseAmount(1.7, for: .semaglutide, brand: "Ozempic")) // Not available in Ozempic
            #expect(!DoseValidation.isValidDoseAmount(2.4, for: .semaglutide, brand: "Ozempic")) // Not available in Ozempic

            // Excessive doses (safety check)
            #expect(!DoseValidation.isValidDoseAmount(10.0, for: .semaglutide, brand: "Ozempic"))
            #expect(!DoseValidation.isValidDoseAmount(50.0, for: .tirzepatide, brand: "Mounjaro"))

            // Micro doses (too small)
            #expect(!DoseValidation.isValidDoseAmount(0.1, for: .semaglutide, brand: "Ozempic"))
            #expect(!DoseValidation.isValidDoseAmount(0.01, for: .tirzepatide, brand: "Mounjaro"))
        }

        @Test("Generic medication dose validation")
        func genericMedicationValidation() async throws {
            // Generic brands should allow broader dose ranges
            #expect(DoseValidation.isValidDoseAmount(1.5, for: .semaglutide, brand: "Generic"))
            #expect(DoseValidation.isValidDoseAmount(2.5, for: .semaglutide, brand: "Generic"))

            // But still reject invalid doses
            #expect(!DoseValidation.isValidDoseAmount(0.0, for: .semaglutide, brand: "Generic"))
            #expect(!DoseValidation.isValidDoseAmount(10.0, for: .semaglutide, brand: "Generic"))
        }

        @Test("Brand-agnostic dose validation")
        func brandAgnosticValidation() async throws {
            // Should accept any dose within medication's available range
            #expect(DoseValidation.isValidDoseAmount(0.25, for: .semaglutide))
            #expect(DoseValidation.isValidDoseAmount(1.7, for: .semaglutide))
            #expect(DoseValidation.isValidDoseAmount(2.4, for: .semaglutide))

            #expect(DoseValidation.isValidDoseAmount(2.5, for: .tirzepatide))
            #expect(DoseValidation.isValidDoseAmount(15.0, for: .tirzepatide))

            // Still reject invalid doses
            #expect(!DoseValidation.isValidDoseAmount(0.0, for: .semaglutide))
            #expect(!DoseValidation.isValidDoseAmount(50.0, for: .tirzepatide))
        }
    }

    // MARK: - Dose Precision Validation Tests

    @Suite("Dose Precision Validation")
    struct DosePrecisionValidationTests {
        @Test("Valid dose precision for each medication")
        func validDosePrecision() async throws {
            // Semaglutide - 0.01 mg precision (hundredths)
            #expect(DoseValidation.isValidDosePrecision(0.25, for: .semaglutide))
            #expect(DoseValidation.isValidDosePrecision(1.50, for: .semaglutide))
            #expect(DoseValidation.isValidDosePrecision(2.75, for: .semaglutide))

            // Tirzepatide - 0.1 mg precision (tenths)
            #expect(DoseValidation.isValidDosePrecision(2.5, for: .tirzepatide))
            #expect(DoseValidation.isValidDosePrecision(7.5, for: .tirzepatide))
            #expect(DoseValidation.isValidDosePrecision(12.5, for: .tirzepatide))

            // Liraglutide - 0.01 mg precision (hundredths)
            #expect(DoseValidation.isValidDosePrecision(0.60, for: .liraglutide))
            #expect(DoseValidation.isValidDosePrecision(1.20, for: .liraglutide))
            #expect(DoseValidation.isValidDosePrecision(3.00, for: .liraglutide))

            // Dulaglutide - 0.1 mg precision (tenths)
            #expect(DoseValidation.isValidDosePrecision(0.7, for: .dulaglutide)) // Should round to 0.8
            #expect(DoseValidation.isValidDosePrecision(1.5, for: .dulaglutide))
            #expect(DoseValidation.isValidDosePrecision(4.5, for: .dulaglutide))
        }

        @Test("Invalid dose precision is rejected")
        func invalidDosePrecision() async throws {
            // Semaglutide - too precise (beyond 0.01)
            #expect(!DoseValidation.isValidDosePrecision(0.251, for: .semaglutide))
            #expect(!DoseValidation.isValidDosePrecision(1.505, for: .semaglutide))

            // Tirzepatide - too precise (beyond 0.1)
            #expect(!DoseValidation.isValidDosePrecision(2.55, for: .tirzepatide))
            #expect(!DoseValidation.isValidDosePrecision(7.53, for: .tirzepatide))

            // Micro-dosing errors
            #expect(!DoseValidation.isValidDosePrecision(0.001, for: .semaglutide))
            #expect(!DoseValidation.isValidDosePrecision(0.01, for: .tirzepatide))
        }

        @Test("Floating point precision tolerance")
        func floatingPointTolerance() async throws {
            // Should handle floating point precision issues
            let impreciseValue = 0.1 + 0.2 // Typically 0.30000000000000004
            #expect(DoseValidation.isValidDosePrecision(impreciseValue, for: .liraglutide))

            // Very small floating point errors should be tolerated
            #expect(DoseValidation.isValidDosePrecision(2.5000000000001, for: .tirzepatide))
            #expect(DoseValidation.isValidDosePrecision(1.4999999999999, for: .semaglutide))
        }
    }

    // MARK: - Boundary Dose Amount Tests

    @Suite("Boundary Dose Amount Tests")
    struct BoundaryDoseAmountTests {
        @Test("Boundary dose amounts")
        func boundaryDoseAmounts() async throws {
            // Test smallest available doses
            #expect(DoseValidation.isValidDoseAmount(0.25, for: .semaglutide, brand: "Ozempic"))
            #expect(DoseValidation.isValidDoseAmount(2.5, for: .tirzepatide, brand: "Mounjaro"))
            #expect(DoseValidation.isValidDoseAmount(0.6, for: .liraglutide, brand: "Victoza"))
            #expect(DoseValidation.isValidDoseAmount(0.75, for: .dulaglutide, brand: "Trulicity"))

            // Test largest available doses
            #expect(DoseValidation.isValidDoseAmount(2.0, for: .semaglutide, brand: "Ozempic"))
            #expect(DoseValidation.isValidDoseAmount(15.0, for: .tirzepatide, brand: "Mounjaro"))
            #expect(DoseValidation.isValidDoseAmount(3.0, for: .liraglutide, brand: "Saxenda"))
            #expect(DoseValidation.isValidDoseAmount(4.5, for: .dulaglutide, brand: "Trulicity"))

            // Just below and above boundaries
            #expect(!DoseValidation.isValidDoseAmount(0.24, for: .semaglutide, brand: "Ozempic"))
            #expect(!DoseValidation.isValidDoseAmount(2.1, for: .semaglutide, brand: "Ozempic"))
        }

        @Test("Medication extension properties")
        func medicationExtensionProperties() async throws {
            // Minimum dose intervals
            #expect(Medication.liraglutide.minimumDoseInterval == 20 * 60 * 60) // 20 hours
            #expect(Medication.semaglutide.minimumDoseInterval == 6 * 24 * 60 * 60) // 6 days
            #expect(Medication.tirzepatide.minimumDoseInterval == 6 * 24 * 60 * 60) // 6 days
            #expect(Medication.dulaglutide.minimumDoseInterval == 6 * 24 * 60 * 60) // 6 days

            // Dose precision
            #expect(Medication.semaglutide.dosePrecision == 100) // 0.01 mg precision
            #expect(Medication.liraglutide.dosePrecision == 100) // 0.01 mg precision
            #expect(Medication.tirzepatide.dosePrecision == 10) // 0.1 mg precision
            #expect(Medication.dulaglutide.dosePrecision == 10) // 0.1 mg precision
        }
    }
}
