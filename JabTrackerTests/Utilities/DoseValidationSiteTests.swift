//
//  DoseValidationSiteTests.swift
//  JabTrackerTests
//

import Testing
import Foundation
@testable import JabTracker

/// Test suite for injection site validation and rotation safety
@Suite("Injection Site Validation Tests")
struct DoseValidationSiteTests {
    
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
            
            // Using different site from last in sequence (Thigh is different from last site Buttocks)
            #expect(DoseValidation.isValidSiteRotation("Thigh", previousSites: previousSites))
            
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
}
