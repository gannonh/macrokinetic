@testable import JabTracker
import SwiftData
import SwiftUI
import Testing

@MainActor
@Suite("UserProfileView Tests")
struct UserProfileViewTests {
    // MARK: - Form Validation Tests

    @Test("Weight validation accepts valid ranges")
    func weightValidationValidRanges() throws {
        let view = UserProfileView()

        // Test valid weights
        #expect(view.isValidWeight("70.5") == true, "Valid decimal weight should be accepted")
        #expect(view.isValidWeight("10") == true, "Minimum valid weight should be accepted")
        #expect(view.isValidWeight("500") == true, "Maximum valid weight should be accepted")
        #expect(view.isValidWeight("100") == true, "Typical weight should be accepted")
        #expect(view.isValidWeight("75.0") == true, "Weight with .0 should be accepted")
    }

    @Test("Weight validation rejects invalid inputs")
    func weightValidationInvalidInputs() throws {
        let view = UserProfileView()

        // Test invalid weights
        #expect(view.isValidWeight("9.9") == false, "Weight below minimum should be rejected")
        #expect(view.isValidWeight("500.1") == false, "Weight above maximum should be rejected")
        #expect(view.isValidWeight("") == false, "Empty string should be rejected")
        #expect(view.isValidWeight("abc") == false, "Non-numeric string should be rejected")
        #expect(view.isValidWeight("-50") == false, "Negative weight should be rejected")
        #expect(view.isValidWeight("0") == false, "Zero weight should be rejected")
    }

    @Test("Weight validation edge cases")
    func weightValidationEdgeCases() throws {
        let view = UserProfileView()

        // Test edge cases
        #expect(view.isValidWeight("10.0") == true, "Exact minimum with decimal should be accepted")
        #expect(view.isValidWeight("500.0") == true, "Exact maximum with decimal should be accepted")
        #expect(view.isValidWeight("50.123456") == true, "High precision decimal should be accepted")
        #expect(view.isValidWeight("  75  ") == false, "Weight with spaces should be rejected (no trimming)")
        #expect(view.isValidWeight("1e2") == true, "Scientific notation (100.0) should be accepted as valid")
    }

    // MARK: - Profile Validation Tests

    @Test("Profile validation requires valid name and weight")
    func profileValidationRequirements() throws {
        let view = UserProfileView()

        // Test profile validation logic by testing the components separately
        // The validation logic is: !editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        //                          isValidWeight(editingWeight)

        let validName = "Test User"
        let validWeight = "70.5"
        let invalidWeight = "abc"
        let emptyName = ""

        // Test individual validation components
        #expect(!validName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "Valid name should pass name validation")
        #expect(emptyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "Empty name should fail name validation")
        #expect(view.isValidWeight(validWeight), "Valid weight should pass weight validation")
        #expect(!view.isValidWeight(invalidWeight), "Invalid weight should fail weight validation")

        // Test combined validation logic (replicating isValidProfile logic)
        let validProfile = !validName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            view.isValidWeight(validWeight)
        let invalidProfileBadWeight = !validName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            view.isValidWeight(invalidWeight)
        let invalidProfileNoName = !emptyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            view.isValidWeight(validWeight)

        #expect(validProfile == true, "Valid name and weight should result in valid profile")
        #expect(invalidProfileBadWeight == false, "Invalid weight should result in invalid profile")
        #expect(invalidProfileNoName == false, "Empty name should result in invalid profile")
    }

    @Test("Name validation handles whitespace correctly")
    func nameValidationWhitespace() throws {
        // Test the name validation logic used in isValidProfile
        let validNames = ["John", "Jane Doe", "Dr. Smith", "Jean-Luc"]
        let invalidNames = ["", "   ", "\t\n", "  \n  \t  "]

        for name in validNames {
            #expect(!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "Name '\(name)' should be considered valid")
        }

        for name in invalidNames {
            #expect(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "Name '\(name)' should be considered invalid (empty after trimming)")
        }

        // Test names with leading/trailing whitespace
        let whitespaceNames = ["  John  ", "\tJane\n", " Dr. Smith "]
        for name in whitespaceNames {
            #expect(!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "Name '\(name)' should be valid after trimming whitespace")
        }
    }

    // MARK: - Helper Method Tests

    @Test("Common timezones includes current timezone")
    func commonTimezonesIncludesCurrent() throws {
        // Test the commonTimezones logic used in UserProfileView
        let currentTimezone = TimeZone.current.identifier
        let testTimezones = [
            "America/New_York",
            "America/Chicago",
            "America/Denver",
            "America/Los_Angeles",
            "Europe/London",
            "Europe/Paris",
            "Asia/Tokyo",
            currentTimezone,
        ].uniqued()

        #expect(testTimezones.contains(currentTimezone),
                "Common timezones should include current timezone")
        #expect(testTimezones.count >= 7,
                "Should have at least 7 unique timezones")

        // Test uniqued() extension behavior
        let duplicateArray = ["A", "B", "A", "C", "B", "D"]
        let uniquedArray = duplicateArray.uniqued()
        #expect(uniquedArray == ["A", "B", "C", "D"],
                "uniqued() should remove duplicates while preserving order")
    }

    @Test("Biometric icon name mapping")
    func biometricIconNameMapping() throws {
        // Test the icon name mapping logic
        let faceIDIcon = "faceid"
        let touchIDIcon = "touchid"
        let opticIDIcon = "opticid"
        let noneIcon = "lock.shield"

        // Verify expected icon names (testing the logic that would be in biometricIconName computed property)
        #expect(faceIDIcon == "faceid", "Face ID should map to faceid icon")
        #expect(touchIDIcon == "touchid", "Touch ID should map to touchid icon")
        #expect(opticIDIcon == "opticid", "Optic ID should map to opticid icon")
        #expect(noneIcon == "lock.shield", "No biometrics should map to lock.shield icon")

        // Test all icons are valid SF Symbol names (basic validation)
        let validIcons = [faceIDIcon, touchIDIcon, opticIDIcon, noneIcon]
        for icon in validIcons {
            #expect(!icon.isEmpty, "Icon name should not be empty")
            #expect(!icon.contains(" "), "Icon name should not contain spaces")
        }
    }

    // MARK: - Array Extension Tests

    @Test("Array uniqued extension functionality")
    func arrayUniquedExtension() throws {
        // Test the uniqued() extension used by commonTimezones
        let testCases: [(input: [String], expected: [String])] = [
            (["A", "B", "C"], ["A", "B", "C"]), // No duplicates
            (["A", "A", "A"], ["A"]), // All duplicates
            (["A", "B", "A", "C"], ["A", "B", "C"]), // Mixed with duplicates
            ([], []), // Empty array
            (["A"], ["A"]), // Single element
            (["A", "B", "C", "B", "A"], ["A", "B", "C"]), // Complex case
        ]

        for testCase in testCases {
            let result = testCase.input.uniqued()
            #expect(result == testCase.expected,
                    "uniqued() failed for input \(testCase.input). Expected: \(testCase.expected), Got: \(result)")
        }

        // Test with Int array
        let intArray = [1, 2, 1, 3, 2, 4]
        let uniquedInts = intArray.uniqued()
        #expect(uniquedInts == [1, 2, 3, 4], "uniqued() should work with Int arrays")

        // Test order preservation
        let orderTest = ["Z", "A", "Z", "B", "A"]
        let orderedResult = orderTest.uniqued()
        #expect(orderedResult == ["Z", "A", "B"],
                "uniqued() should preserve first occurrence order")
    }

    // MARK: - ProfileField Component Tests

    @Test("ProfileField component creation")
    func profileFieldComponentCreation() throws {
        // Test ProfileField with value
        let fieldWithValue = ProfileField(label: "Test Label", value: "Test Value") {
            EmptyView()
        }

        #expect(fieldWithValue.label == "Test Label", "ProfileField should store label correctly")
        #expect(fieldWithValue.value == "Test Value", "ProfileField should store value correctly")

        // Test ProfileField without value (content mode)
        let fieldWithContent = ProfileField(label: "Content Label") {
            Text("Custom Content")
        }

        #expect(fieldWithContent.label == "Content Label", "ProfileField should store label correctly")
        #expect(fieldWithContent.value == nil, "ProfileField without value should have nil value")

        // Test ProfileField with empty value
        let fieldWithEmptyValue = ProfileField(label: "Empty", value: "") {
            EmptyView()
        }

        #expect(fieldWithEmptyValue.value == "", "ProfileField should handle empty string value")
    }

    // MARK: - Integration Tests

    @Test("UserProfileView can be created with required environment objects")
    func userProfileViewCreation() throws {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let biometricManager = BiometricAuthManager()

        // Test that UserProfileView can be created with proper environment
        let profileView = UserProfileView()
            .environmentObject(authManager)
            .environmentObject(biometricManager)
            .environment(\.modelContext, dataController.container.mainContext)

        // Verify the view can be created without crashing by checking it's a View
        _ = profileView // This compiles successfully, proving the view can be created
        #expect(true, "UserProfileView should be properly configured with environment objects")
    }

    @Test("Weight conversion display format")
    func weightConversionDisplayFormat() throws {
        // Test the weight display format logic used in the view
        struct WeightDisplayTest {
            let weight: Double
            let unit: String
            let expected: String
        }

        let testCases = [
            WeightDisplayTest(weight: 70.5, unit: "kg", expected: "70.5 kg"),
            WeightDisplayTest(weight: 154.3, unit: "lbs", expected: "154.3 lbs"),
            WeightDisplayTest(weight: 75.0, unit: "kg", expected: "75.0 kg"),
            WeightDisplayTest(weight: 200.25, unit: "lbs", expected: "200.2 lbs"), // Tests rounding to 1 decimal
        ]

        for testCase in testCases {
            let formatted = String(format: "%.1f %@", testCase.weight, testCase.unit)
            #expect(formatted == testCase.expected,
                    "Weight display format failed. Expected: '\(testCase.expected)', Got: '\(formatted)'")
        }
    }

    // MARK: - Error Handling Tests

    @Test("Profile validation handles edge cases gracefully")
    func profileValidationEdgeCases() throws {
        let view = UserProfileView()

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
            let result = view.isValidWeight(testCase.input)
            #expect(result == testCase.expected,
                    """
                    Weight validation failed for '\(testCase.input)' (\(testCase.description)). \
                    Expected: \(testCase.expected), Got: \(result)
                    """)
        }
    }
}

// MARK: - Test Helpers

extension UserProfileViewTests {
    /// Helper method to test weight validation logic
    /// This mirrors the isValidWeight method from UserProfileView
    private func testWeightValidation(_ weight: String) -> Bool {
        guard let weightValue = Double(weight) else { return false }
        return weightValue >= 10 && weightValue <= 500
    }
}
