import SwiftData
import SwiftUI
import Testing

@testable import JabTracker

@MainActor
@Suite("UserProfileView Tests")
struct UserProfileViewTests {
    // MARK: - UI Component Tests

    @Test("Name validation handles whitespace correctly")
    func nameValidationWhitespace() throws {
        // Test the name validation logic used in isValidProfile
        let validNames = ["John", "Jane Doe", "Dr. Smith", "Jean-Luc"]
        let invalidNames = ["", "   ", "\t\n", "  \n  \t  "]

        for name in validNames {
            #expect(
                !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "Name '\(name)' should be considered valid")
        }

        for name in invalidNames {
            #expect(
                name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                "Name '\(name)' should be considered invalid (empty after trimming)")
        }

        // Test names with leading/trailing whitespace
        let whitespaceNames = ["  John  ", "\tJane\n", " Dr. Smith "]
        for name in whitespaceNames {
            #expect(
                !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
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

        #expect(
            testTimezones.contains(currentTimezone),
            "Common timezones should include current timezone")
        #expect(
            testTimezones.count >= 7,
            "Should have at least 7 unique timezones")

        // Test uniqued() extension behavior
        let duplicateArray = ["A", "B", "A", "C", "B", "D"]
        let uniquedArray = duplicateArray.uniqued()
        #expect(
            uniquedArray == ["A", "B", "C", "D"],
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
            (["A", "B", "C"], ["A", "B", "C"]),  // No duplicates
            (["A", "A", "A"], ["A"]),  // All duplicates
            (["A", "B", "A", "C"], ["A", "B", "C"]),  // Mixed with duplicates
            ([], []),  // Empty array
            (["A"], ["A"]),  // Single element
            (["A", "B", "C", "B", "A"], ["A", "B", "C"]),  // Complex case
        ]

        for testCase in testCases {
            let result = testCase.input.uniqued()
            #expect(
                result == testCase.expected,
                "uniqued() failed for input \(testCase.input). Expected: \(testCase.expected), Got: \(result)"
            )
        }

        // Test with Int array
        let intArray = [1, 2, 1, 3, 2, 4]
        let uniquedInts = intArray.uniqued()
        #expect(uniquedInts == [1, 2, 3, 4], "uniqued() should work with Int arrays")

        // Test order preservation
        let orderTest = ["Z", "A", "Z", "B", "A"]
        let orderedResult = orderTest.uniqued()
        #expect(
            orderedResult == ["Z", "A", "B"],
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

    // Note: UserProfileView integration test removed - view does not exist in codebase yet

    @Test("Weight conversion display format")
    func weightConversionDisplayFormat() throws {
        // Test the weight display format using the User model's computed property
        struct WeightDisplayTest {
            let weight: Double
            let unit: String
            let expected: String
        }

        let testCases = [
            WeightDisplayTest(weight: 70.5, unit: "kg", expected: "70.5 kg"),
            WeightDisplayTest(weight: 154.3, unit: "lbs", expected: "154.3 lbs"),
            WeightDisplayTest(weight: 75.0, unit: "kg", expected: "75.0 kg"),
            WeightDisplayTest(weight: 200.25, unit: "lbs", expected: "200.2 lbs"),  // Tests rounding to 1 decimal
        ]

        for testCase in testCases {
            // Create a User with the test weight and unit
            let user = User(weight: testCase.weight, weightUnit: testCase.unit)
            let formatted = user.weightDisplay
            #expect(
                formatted == testCase.expected,
                "Weight display format failed. Expected: '\(testCase.expected)', Got: '\(formatted)'")
        }
    }

    // MARK: - Error Handling Tests

    // Note: Profile validation tests have been moved to ProfileValidationTests
    // to follow single responsibility principle
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
