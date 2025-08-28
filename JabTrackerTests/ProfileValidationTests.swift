//
//  ProfileValidationTests.swift
//  JabTrackerTests
//

@testable import JabTracker
import Testing

@Suite("Profile Validation Tests")
struct ProfileValidationTests {
    // MARK: - Weight String Validation Tests

    @Test("Weight validation accepts valid string ranges")
    func weightStringValidationValidRanges() throws {
        // Test valid weights as strings
        #expect(ProfileValidation.isValidWeight("70.5") == true, "Valid decimal weight should be accepted")
        #expect(ProfileValidation.isValidWeight("10") == true, "Minimum valid weight should be accepted")
        #expect(ProfileValidation.isValidWeight("500") == true, "Maximum valid weight should be accepted")
        #expect(ProfileValidation.isValidWeight("100") == true, "Typical weight should be accepted")
        #expect(ProfileValidation.isValidWeight("75.0") == true, "Weight with .0 should be accepted")
    }

    @Test("Weight validation rejects invalid string inputs")
    func weightStringValidationInvalidInputs() throws {
        // Test invalid weights as strings
        #expect(ProfileValidation.isValidWeight("9.9") == false, "Weight below minimum should be rejected")
        #expect(ProfileValidation.isValidWeight("500.1") == false, "Weight above maximum should be rejected")
        #expect(ProfileValidation.isValidWeight("") == false, "Empty string should be rejected")
        #expect(ProfileValidation.isValidWeight("abc") == false, "Non-numeric string should be rejected")
        #expect(ProfileValidation.isValidWeight("-50") == false, "Negative weight should be rejected")
        #expect(ProfileValidation.isValidWeight("0") == false, "Zero weight should be rejected")
    }

    @Test("Weight validation edge cases for strings")
    func weightStringValidationEdgeCases() throws {
        // Test edge cases
        #expect(ProfileValidation.isValidWeight("10.0") == true, "Exact minimum with decimal should be accepted")
        #expect(ProfileValidation.isValidWeight("500.0") == true, "Exact maximum with decimal should be accepted")
        #expect(ProfileValidation.isValidWeight("50.123456") == true, "High precision decimal should be accepted")
        #expect(ProfileValidation.isValidWeight("  75  ") == false,
                "Weight with spaces should be rejected (no trimming)")
        #expect(ProfileValidation.isValidWeight("1e2") == true,
                "Scientific notation (100.0) should be accepted as valid")
    }

    // MARK: - Weight Double Validation Tests

    @Test("Weight validation accepts valid double ranges")
    func weightDoubleValidationValidRanges() throws {
        // Test valid weights as doubles
        #expect(ProfileValidation.isValidWeight(70.5) == true, "Valid decimal weight should be accepted")
        #expect(ProfileValidation.isValidWeight(10.0) == true, "Minimum valid weight should be accepted")
        #expect(ProfileValidation.isValidWeight(500.0) == true, "Maximum valid weight should be accepted")
        #expect(ProfileValidation.isValidWeight(100.0) == true, "Typical weight should be accepted")
        #expect(ProfileValidation.isValidWeight(75.0) == true, "Weight with .0 should be accepted")
    }

    @Test("Weight validation rejects invalid double inputs")
    func weightDoubleValidationInvalidInputs() throws {
        // Test invalid weights as doubles
        #expect(ProfileValidation.isValidWeight(9.9) == false, "Weight below minimum should be rejected")
        #expect(ProfileValidation.isValidWeight(500.1) == false, "Weight above maximum should be rejected")
        #expect(ProfileValidation.isValidWeight(-50.0) == false, "Negative weight should be rejected")
        #expect(ProfileValidation.isValidWeight(0.0) == false, "Zero weight should be rejected")
    }

    // MARK: - Name Validation Tests

    @Test("Name validation accepts valid names")
    func nameValidationValid() throws {
        let validNames = ["John", "Jane Doe", "Dr. Smith", "Jean-Luc"]

        for name in validNames {
            #expect(ProfileValidation.isValidName(name) == true,
                    "Name '\(name)' should be considered valid")
        }
    }

    @Test("Name validation rejects invalid names")
    func nameValidationInvalid() throws {
        let invalidNames = ["", "   ", "\t\n", "  \n  \t  "]

        for name in invalidNames {
            #expect(ProfileValidation.isValidName(name) == false,
                    "Name '\(name)' should be considered invalid (empty after trimming)")
        }
    }

    @Test("Name validation handles whitespace correctly")
    func nameValidationWhitespace() throws {
        // Test names with leading/trailing whitespace
        let whitespaceNames = ["  John  ", "\tJane\n", " Dr. Smith "]
        for name in whitespaceNames {
            #expect(ProfileValidation.isValidName(name) == true,
                    "Name '\(name)' should be valid after trimming whitespace")
        }
    }

    // MARK: - Combined Profile Validation Tests

    @Test("Profile validation requires valid name and weight")
    func profileValidationRequirements() throws {
        // Test combined validation logic
        let validName = "Test User"
        let validWeight = "70.5"
        let invalidWeight = "abc"
        let emptyName = ""

        #expect(ProfileValidation.isValidProfile(name: validName, weight: validWeight) == true,
                "Valid name and weight should result in valid profile")
        #expect(ProfileValidation.isValidProfile(name: validName, weight: invalidWeight) == false,
                "Invalid weight should result in invalid profile")
        #expect(ProfileValidation.isValidProfile(name: emptyName, weight: validWeight) == false,
                "Empty name should result in invalid profile")
        #expect(ProfileValidation.isValidProfile(name: emptyName, weight: invalidWeight) == false,
                "Both invalid should result in invalid profile")
    }

    // MARK: - Constants Tests

    @Test("Weight limits constants are correctly defined")
    func weightLimitsConstants() throws {
        #expect(ProfileValidation.WeightLimits.minimum == 10.0, "Minimum weight limit should be 10.0")
        #expect(ProfileValidation.WeightLimits.maximum == 500.0, "Maximum weight limit should be 500.0")
        #expect(ProfileValidation.WeightLimits.minimum < ProfileValidation.WeightLimits.maximum,
                "Minimum should be less than maximum")
    }

    // MARK: - Edge Cases and Error Handling Tests

    @Test("Profile validation handles edge cases gracefully")
    func profileValidationEdgeCases() throws {
        // Test weight validation with various edge cases
        struct WeightValidationTest {
            let input: String
            let expected: Bool
            let description: String
        }

        let edgeCases = [
            WeightValidationTest(input: "10.0", expected: true, description: "Exact minimum boundary"),
            WeightValidationTest(input: "500.0", expected: true, description: "Exact maximum boundary"),
            WeightValidationTest(input: "9.999999", expected: false, description: "Just below minimum"),
            WeightValidationTest(input: "500.000001", expected: false, description: "Just above maximum"),
            WeightValidationTest(input: ".", expected: false, description: "Just decimal point"),
            WeightValidationTest(input: "10.", expected: true, description: "Number with trailing decimal"),
            WeightValidationTest(input: ".5", expected: false, description: "Decimal without leading zero"),
            WeightValidationTest(input: "12.34567890", expected: true, description: "High precision decimal"),
            WeightValidationTest(input: "100,5", expected: false, description: "Comma as decimal separator"),
            WeightValidationTest(input: "∞", expected: false, description: "Infinity symbol"),
            WeightValidationTest(input: "NaN", expected: false, description: "NaN string"),
        ]

        for testCase in edgeCases {
            let result = ProfileValidation.isValidWeight(testCase.input)
            #expect(result == testCase.expected,
                    """
                    Weight validation failed for '\(testCase.input)' (\(testCase.description)). \
                    Expected: \(testCase.expected), Got: \(result)
                    """)
        }
    }
}
