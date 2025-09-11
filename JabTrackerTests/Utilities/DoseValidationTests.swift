//
//  DoseValidationTests.swift
//  JabTrackerTests
//

import Testing
import Foundation
@testable import JabTracker

/// Comprehensive test suite for medical dose validation
/// Safety-critical testing for GLP-1 medication dosing validation
@Suite("Dose Validation Tests - Medical Safety Critical")
struct DoseValidationTests {
    
    // MARK: - Dose Amount Validation Tests
    
    @Suite("Dose Amount Validation")
    struct DoseAmountValidationTests {
        
        @Test("Valid dose amounts for brand-specific medications")
        func testValidDoseAmountsByBrand() async throws {
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
        func testInvalidDoseAmounts() async throws {
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
        func testGenericMedicationValidation() async throws {
            // Generic brands should allow broader dose ranges
            #expect(DoseValidation.isValidDoseAmount(1.5, for: .semaglutide, brand: "Generic"))
            #expect(DoseValidation.isValidDoseAmount(2.5, for: .semaglutide, brand: "Generic"))
            
            // But still reject invalid doses
            #expect(!DoseValidation.isValidDoseAmount(0.0, for: .semaglutide, brand: "Generic"))
            #expect(!DoseValidation.isValidDoseAmount(10.0, for: .semaglutide, brand: "Generic"))
        }
        
        @Test("Brand-agnostic dose validation")
        func testBrandAgnosticValidation() async throws {
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
        func testValidDosePrecision() async throws {
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
            #expect(DoseValidation.isValidDosePrecision(0.7, for: .dulaglutide))  // Should round to 0.8
            #expect(DoseValidation.isValidDosePrecision(1.5, for: .dulaglutide))
            #expect(DoseValidation.isValidDosePrecision(4.5, for: .dulaglutide))
        }
        
        @Test("Invalid dose precision is rejected")
        func testInvalidDosePrecision() async throws {
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
        func testFloatingPointTolerance() async throws {
            // Should handle floating point precision issues
            let impreciseValue = 0.1 + 0.2  // Typically 0.30000000000000004
            #expect(DoseValidation.isValidDosePrecision(impreciseValue, for: .liraglutide))
            
            // Very small floating point errors should be tolerated
            #expect(DoseValidation.isValidDosePrecision(2.5000000000001, for: .tirzepatide))
            #expect(DoseValidation.isValidDosePrecision(1.4999999999999, for: .semaglutide))
        }
    }
    
    // MARK: - Injection Site Validation Tests
    
    @Suite("Injection Site Validation")
    struct InjectionSiteValidationTests {
        
        @Test("Valid injection sites are accepted")
        func testValidInjectionSites() async throws {
            let validSites = DoseValidation.AnatomicalSites.approved
            
            for site in validSites {
                #expect(DoseValidation.isValidInjectionSite(site), "Site '\(site)' should be valid")
            }
            
            // Case-insensitive validation
            #expect(DoseValidation.isValidInjectionSite("thigh"))
            #expect(DoseValidation.isValidInjectionSite("ABDOMEN"))
            #expect(DoseValidation.isValidInjectionSite("Upper Arm"))
            #expect(DoseValidation.isValidInjectionSite("buttocks"))
        }
        
        @Test("Invalid injection sites are rejected")
        func testInvalidInjectionSites() async throws {
            let invalidSites = [
                "Face",           // Dangerous - facial injection
                "Neck",           // Dangerous - vascular area
                "Hand",           // Inappropriate site
                "Foot",           // Inappropriate site
                "Back",           // Generally not recommended for self-injection
                "Chest",          // Not standard subcutaneous site
                "Wrist",          // Dangerous - vascular area
                "",               // Empty string
                "   ",            // Whitespace only
                "UnknownSite"     // Not in approved list
            ]
            
            for site in invalidSites {
                #expect(!DoseValidation.isValidInjectionSite(site), "Site '\(site)' should be invalid")
            }
        }
        
        @Test("Injection site with whitespace handling")
        func testInjectionSiteWhitespaceHandling() async throws {
            // Should handle leading/trailing whitespace
            #expect(DoseValidation.isValidInjectionSite("  Thigh  "))
            #expect(DoseValidation.isValidInjectionSite("\tAbdomen\n"))
            #expect(DoseValidation.isValidInjectionSite(" Upper Arm "))
            
            // But reject empty after trimming
            #expect(!DoseValidation.isValidInjectionSite("   "))
            #expect(!DoseValidation.isValidInjectionSite("\t\n"))
        }
    }
    
    // MARK: - Site Rotation Validation Tests
    
    @Suite("Site Rotation Validation")
    struct SiteRotationValidationTests {
        
        @Test("Valid site rotation patterns")
        func testValidSiteRotation() async throws {
            let previousSites = ["Thigh", "Abdomen", "Upper Arm", "Buttocks"]
            
            // Different site from last dose is valid
            #expect(DoseValidation.isValidSiteRotation("Abdomen", previousSites: ["Thigh"]))
            #expect(DoseValidation.isValidSiteRotation("Upper Arm", previousSites: ["Abdomen", "Thigh"]))
            
            // Using different sites in sequence
            #expect(DoseValidation.isValidSiteRotation("Buttocks", previousSites: previousSites))
            
            // Empty previous sites (first dose)
            #expect(DoseValidation.isValidSiteRotation("Thigh", previousSites: []))
        }
        
        @Test("Invalid site rotation patterns")
        func testInvalidSiteRotation() async throws {
            // Same site as last dose (consecutive use)
            #expect(!DoseValidation.isValidSiteRotation("Thigh", previousSites: ["Thigh"]))
            #expect(!DoseValidation.isValidSiteRotation("Abdomen", previousSites: ["Upper Arm", "Thigh", "Abdomen"]))
            
            // Case-insensitive consecutive site detection
            #expect(!DoseValidation.isValidSiteRotation("thigh", previousSites: ["Thigh"]))
            #expect(!DoseValidation.isValidSiteRotation("ABDOMEN", previousSites: ["abdomen"]))
        }
        
        @Test("Site rotation with invalid sites")
        func testSiteRotationWithInvalidSites() async throws {
            // Invalid new site should be rejected regardless of rotation
            #expect(!DoseValidation.isValidSiteRotation("Face", previousSites: ["Thigh"]))
            #expect(!DoseValidation.isValidSiteRotation("Neck", previousSites: ["Abdomen", "Thigh"]))
            
            // Valid site with invalid previous sites should still work
            #expect(DoseValidation.isValidSiteRotation("Thigh", previousSites: ["InvalidSite"]))
        }
        
        @Test("Site rotation window handling")
        func testSiteRotationWindow() async throws {
            let longHistory = ["Thigh", "Abdomen", "Upper Arm", "Buttocks", "Thigh", "Abdomen"]
            
            // Custom rotation window - should only check last 2 doses
            #expect(DoseValidation.isValidSiteRotation("Upper Arm", previousSites: longHistory, rotationWindow: 2))
            #expect(!DoseValidation.isValidSiteRotation("Abdomen", previousSites: longHistory, rotationWindow: 2))
            
            // Default window should check last 4 doses
            #expect(!DoseValidation.isValidSiteRotation("Abdomen", previousSites: longHistory)) // Same as 6th from last
        }
    }
    
    // MARK: - Temporal Validation Tests
    
    @Suite("Temporal Validation")
    struct TemporalValidationTests {
        
        @Test("Valid dose timing for different medications")
        func testValidDoseTiming() async throws {
            let now = Date()
            
            // Daily medication (liraglutide) - 24 hours apart
            let yesterday = now.addingTimeInterval(-25 * 60 * 60) // 25 hours ago
            #expect(DoseValidation.isValidDoseTiming(now, lastDoseDate: yesterday, for: .liraglutide))
            
            // Weekly medication (semaglutide) - 7 days apart
            let lastWeek = now.addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
            #expect(DoseValidation.isValidDoseTiming(now, lastDoseDate: lastWeek, for: .semaglutide))
            
            // First dose (no previous dose)
            #expect(DoseValidation.isValidDoseTiming(now, lastDoseDate: nil, for: .semaglutide))
            #expect(DoseValidation.isValidDoseTiming(now, lastDoseDate: nil, for: .liraglutide))
        }
        
        @Test("Invalid dose timing is rejected")
        func testInvalidDoseTiming() async throws {
            let now = Date()
            
            // Daily medication - too soon (less than 20 hours)
            let tooRecent = now.addingTimeInterval(-10 * 60 * 60) // 10 hours ago
            #expect(!DoseValidation.isValidDoseTiming(now, lastDoseDate: tooRecent, for: .liraglutide))
            
            // Weekly medication - too soon (less than 6 days)
            let tooRecentWeekly = now.addingTimeInterval(-5 * 24 * 60 * 60) // 5 days ago
            #expect(!DoseValidation.isValidDoseTiming(now, lastDoseDate: tooRecentWeekly, for: .semaglutide))
            #expect(!DoseValidation.isValidDoseTiming(now, lastDoseDate: tooRecentWeekly, for: .tirzepatide))
            #expect(!DoseValidation.isValidDoseTiming(now, lastDoseDate: tooRecentWeekly, for: .dulaglutide))
        }
        
        @Test("Dose date validation")
        func testDoseDateValidation() async throws {
            let now = Date()
            
            // Current time and recent past should be valid
            #expect(DoseValidation.isValidDoseDate(now))
            #expect(DoseValidation.isValidDoseDate(now.addingTimeInterval(-60))) // 1 minute ago
            #expect(DoseValidation.isValidDoseDate(now.addingTimeInterval(-3600))) // 1 hour ago
            
            // Future dates should be invalid
            #expect(!DoseValidation.isValidDoseDate(now.addingTimeInterval(60))) // 1 minute future
            #expect(!DoseValidation.isValidDoseDate(now.addingTimeInterval(3600))) // 1 hour future
            #expect(!DoseValidation.isValidDoseDate(now.addingTimeInterval(24 * 60 * 60))) // 1 day future
            
            // Small tolerance for clock skew (5 minutes)
            #expect(DoseValidation.isValidDoseDate(now.addingTimeInterval(300))) // 5 minutes future - should be valid
            #expect(!DoseValidation.isValidDoseDate(now.addingTimeInterval(301))) // Just over tolerance
        }
        
        @Test("Historical date validation")
        func testHistoricalDateValidation() async throws {
            let now = Date()
            
            // Recent dates should be valid
            #expect(DoseValidation.isReasonableHistoricalDate(now))
            #expect(DoseValidation.isReasonableHistoricalDate(now.addingTimeInterval(-30 * 24 * 60 * 60))) // 30 days ago
            #expect(DoseValidation.isReasonableHistoricalDate(now.addingTimeInterval(-365 * 24 * 60 * 60))) // 1 year ago
            
            // Very old dates should be invalid
            #expect(!DoseValidation.isReasonableHistoricalDate(now.addingTimeInterval(-366 * 24 * 60 * 60))) // Over 1 year ago
            #expect(!DoseValidation.isReasonableHistoricalDate(now.addingTimeInterval(-2 * 365 * 24 * 60 * 60))) // 2 years ago
            
            // Custom max past days
            #expect(DoseValidation.isReasonableHistoricalDate(now.addingTimeInterval(-90 * 24 * 60 * 60), maxPastDays: 90)) // 90 days ago with 90 day limit
            #expect(!DoseValidation.isReasonableHistoricalDate(now.addingTimeInterval(-91 * 24 * 60 * 60), maxPastDays: 90)) // Over 90 day limit
        }
    }
    
    // MARK: - Comprehensive Dose Validation Tests
    
    @Suite("Comprehensive Dose Validation")
    struct ComprehensiveDoseValidationTests {
        
        @Test("Valid complete dose entry")
        func testValidCompleteDoseEntry() async throws {
            let now = Date()
            let lastWeek = now.addingTimeInterval(-7 * 24 * 60 * 60)
            let previousSites = ["Abdomen", "Upper Arm", "Buttocks"]
            
            let result = DoseValidation.validateDose(
                amount: 1.0,
                date: now,
                site: "Thigh",
                medication: .semaglutide,
                brand: "Ozempic",
                lastDoseDate: lastWeek,
                previousSites: previousSites
            )
            
            #expect(result.isValid)
            #expect(result.errors.isEmpty)
            #expect(result.errorDescription == nil)
        }
        
        @Test("Invalid dose amount error")
        func testInvalidDoseAmountError() async throws {
            let now = Date()
            
            let result = DoseValidation.validateDose(
                amount: 3.0, // Not available for Ozempic
                date: now,
                site: "Thigh",
                medication: .semaglutide,
                brand: "Ozempic",
                lastDoseDate: nil,
                previousSites: []
            )
            
            #expect(!result.isValid)
            #expect(result.errors.count == 1)
            
            if case .invalidDoseAmount(let amount, let medication, let brand) = result.errors.first {
                #expect(amount == 3.0)
                #expect(medication == .semaglutide)
                #expect(brand == "Ozempic")
            } else {
                Issue.record("Expected invalidDoseAmount error")
            }
            
            #expect(result.errorDescription?.contains("3.0 mg is not available") == true)
        }
        
        @Test("Multiple validation errors")
        func testMultipleValidationErrors() async throws {
            let futureDate = Date().addingTimeInterval(24 * 60 * 60) // 1 day future
            let tooRecentDate = Date().addingTimeInterval(-1 * 60 * 60) // 1 hour ago
            
            let result = DoseValidation.validateDose(
                amount: 50.0, // Invalid amount
                date: futureDate, // Future date
                site: "Face", // Invalid site
                medication: .semaglutide,
                brand: "Ozempic",
                lastDoseDate: tooRecentDate, // Too recent
                previousSites: ["Thigh"]
            )
            
            #expect(!result.isValid)
            #expect(result.errors.count >= 3) // At least 3 errors expected
            
            // Check for specific error types
            let errorTypes = result.errors.map { type(of: $0) }
            #expect(result.errors.contains { if case .invalidDoseAmount = $0 { return true }; return false })
            #expect(result.errors.contains { if case .futureDate = $0 { return true }; return false })
            #expect(result.errors.contains { if case .invalidInjectionSite = $0 { return true }; return false })
            #expect(result.errors.contains { if case .invalidDoseTiming = $0 { return true }; return false })
        }
        
        @Test("Dose validation without injection site")
        func testDoseValidationWithoutInjectionSite() async throws {
            let now = Date()
            
            let result = DoseValidation.validateDose(
                amount: 1.0,
                date: now,
                site: nil, // No injection site provided
                medication: .semaglutide,
                brand: "Ozempic",
                lastDoseDate: nil,
                previousSites: []
            )
            
            #expect(result.isValid) // Should be valid - injection site is optional
            #expect(result.errors.isEmpty)
        }
        
        @Test("Error descriptions are user-friendly")
        func testErrorDescriptionsAreUserFriendly() async throws {
            let futureDate = Date().addingTimeInterval(3600)
            
            let result = DoseValidation.validateDose(
                amount: 100.0,
                date: futureDate,
                site: "InvalidSite",
                medication: .tirzepatide,
                brand: "Mounjaro",
                lastDoseDate: nil,
                previousSites: []
            )
            
            #expect(!result.isValid)
            let description = result.errorDescription
            #expect(description != nil)
            
            // Should contain helpful information
            #expect(description?.contains("100.0 mg is not available") == true)
            #expect(description?.contains("cannot be in the future") == true)
            #expect(description?.contains("InvalidSite") == true)
            #expect(description?.contains("safe injection site") == true)
        }
    }
    
    // MARK: - Edge Cases and Boundary Tests
    
    @Suite("Edge Cases and Boundary Conditions")
    struct EdgeCasesAndBoundaryTests {
        
        @Test("Medication extension properties")
        func testMedicationExtensionProperties() async throws {
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
        
        @Test("Boundary dose amounts")
        func testBoundaryDoseAmounts() async throws {
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
        
        @Test("Timing boundary conditions")
        func testTimingBoundaryConditions() async throws {
            let now = Date()
            
            // Exact minimum intervals
            let exactDailyInterval = now.addingTimeInterval(-20 * 60 * 60) // Exactly 20 hours
            #expect(DoseValidation.isValidDoseTiming(now, lastDoseDate: exactDailyInterval, for: .liraglutide))
            
            let exactWeeklyInterval = now.addingTimeInterval(-6 * 24 * 60 * 60) // Exactly 6 days
            #expect(DoseValidation.isValidDoseTiming(now, lastDoseDate: exactWeeklyInterval, for: .semaglutide))
            
            // Just under minimum intervals
            let justUnderDaily = now.addingTimeInterval(-20 * 60 * 60 + 1) // 1 second less than 20 hours
            #expect(!DoseValidation.isValidDoseTiming(now, lastDoseDate: justUnderDaily, for: .liraglutide))
            
            let justUnderWeekly = now.addingTimeInterval(-6 * 24 * 60 * 60 + 1) // 1 second less than 6 days
            #expect(!DoseValidation.isValidDoseTiming(now, lastDoseDate: justUnderWeekly, for: .semaglutide))
        }
        
        @Test("Empty and nil input handling")
        func testEmptyAndNilInputHandling() async throws {
            let now = Date()
            
            // Empty injection site array
            #expect(DoseValidation.isValidSiteRotation("Thigh", previousSites: []))
            
            // Nil injection site in comprehensive validation
            let result = DoseValidation.validateDose(
                amount: 1.0,
                date: now,
                site: nil,
                medication: .semaglutide,
                brand: "Ozempic",
                lastDoseDate: nil,
                previousSites: []
            )
            #expect(result.isValid)
            
            // Empty strings in site validation
            #expect(!DoseValidation.isValidInjectionSite(""))
            #expect(!DoseValidation.isValidInjectionSite("   "))
        }
    }
}