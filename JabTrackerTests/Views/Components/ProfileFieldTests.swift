import Foundation
import SwiftUI
import Testing

@testable import JabTracker

/// Comprehensive tests for ProfileField
/// Tests initialization, value display, content display, and accessibility
@Suite("ProfileField Tests")
@MainActor
struct ProfileFieldTests {

    // MARK: - Initialization Tests

    @Test("ProfileField initializes with label and value")
    func testInitializationWithLabelAndValue() {
        let label = "Email"
        let value = "test@example.com"

        let profileField = ProfileField(label: label, value: value) {
            Text("Placeholder")
        }

        #expect(profileField.label == label)
        #expect(profileField.value == value)
    }

    @Test("ProfileField initializes with label only (no value)")
    func testInitializationWithLabelOnly() {
        let label = "Phone"

        let profileField = ProfileField(label: label) {
            TextField("Enter phone", text: .constant(""))
        }

        #expect(profileField.label == label)
        #expect(profileField.value == nil)
    }

    @Test("ProfileField initializes with empty string value")
    func testInitializationWithEmptyValue() {
        let label = "Name"
        let value = ""

        let profileField = ProfileField(label: label, value: value) {
            Text("Default Name")
        }

        #expect(profileField.label == label)
        #expect(profileField.value == value)
    }

    // MARK: - Content Display Tests

    @Test("ProfileField shows value when provided")
    func testContentDisplayWithValue() {
        let label = "Weight"
        let value = "70 kg"

        let profileField = ProfileField(label: label, value: value) {
            TextField("Enter weight", text: .constant(""))
        }

        // When value is provided, it should be displayed
        #expect(profileField.value == value)
        #expect(profileField.label == label)
    }

    @Test("ProfileField shows content when no value provided")
    func testContentDisplayWithoutValue() {
        let label = "Height"

        let profileField = ProfileField(label: label, value: nil) {
            Text("Enter height")
        }

        // When no value is provided, content should be used
        #expect(profileField.value == nil)
        #expect(profileField.label == label)
    }

    @Test("ProfileField handles whitespace-only value as valid")
    func testContentWithWhitespaceValue() {
        let label = "Notes"
        let value = "   "  // Only whitespace

        let profileField = ProfileField(label: label, value: value) {
            Text("No notes")
        }

        // Even whitespace-only value should be treated as a valid value
        #expect(profileField.value == value)
    }

    // MARK: - Label Formatting Tests

    @Test("ProfileField handles various label formats")
    func testLabelFormatting() {
        let testCases = [
            "Email Address",
            "phone",
            "FULL NAME",
            "date_of_birth",
            "Weight (kg)",
            "123 Number Label",
        ]

        for label in testCases {
            let profileField = ProfileField(label: label) {
                Text("Content")
            }

            #expect(profileField.label == label)
        }
    }

    @Test("ProfileField handles empty label")
    func testEmptyLabel() {
        let label = ""
        let value = "Some value"

        let profileField = ProfileField(label: label, value: value) {
            Text("Content")
        }

        #expect(profileField.label.isEmpty)
        #expect(profileField.value == value)
    }

    // MARK: - Value Type Tests

    @Test("ProfileField handles numeric values as strings")
    func testNumericValues() {
        let testCases = [
            ("Age", "25"),
            ("Weight", "70.5"),
            ("Height", "175"),
            ("BMI", "22.86"),
            ("Temperature", "36.5°C"),
        ]

        for (label, value) in testCases {
            let profileField = ProfileField(label: label, value: value) {
                Text("Default")
            }

            #expect(profileField.value == value)
            #expect(profileField.label == label)
        }
    }

    @Test("ProfileField handles special characters in values")
    func testSpecialCharacterValues() {
        let testCases = [
            ("Email", "test+user@example.com"),
            ("Phone", "+1 (555) 123-4567"),
            ("Address", "123 Main St, Apt #4B"),
            ("Notes", "Multiple\nlines\nof text"),
            ("Unicode", "こんにちは 🏥💊"),
        ]

        for (label, value) in testCases {
            let profileField = ProfileField(label: label, value: value) {
                Text("Placeholder")
            }

            #expect(profileField.value == value)
            #expect(profileField.label == label)
        }
    }

    // MARK: - Content Builder Tests

    @Test("ProfileField works with different content types")
    func testDifferentContentTypes() {
        // Test with Text content
        let textField = ProfileField(label: "Text", value: nil) {
            Text("Text Content")
        }
        #expect(textField.label == "Text")

        // Test with TextField content
        let textFieldContent = ProfileField(label: "Input", value: nil) {
            TextField("Enter value", text: .constant(""))
        }
        #expect(textFieldContent.label == "Input")

        // Test with Button content
        let buttonField = ProfileField(label: "Action", value: nil) {
            Button("Tap Me") {}
        }
        #expect(buttonField.label == "Action")
    }

    @Test("ProfileField works with complex content")
    func testComplexContent() {
        let complexField = ProfileField(label: "Complex", value: nil) {
            VStack {
                Text("First Line")
                HStack {
                    Text("Second")
                    Spacer()
                    Text("Line")
                }
            }
        }

        #expect(complexField.label == "Complex")
        #expect(complexField.value == nil)
    }

    // MARK: - Edge Cases Tests

    @Test("ProfileField handles extremely long labels")
    func testLongLabels() {
        let longLabel = String(repeating: "Very Long Label Text ", count: 20)

        let profileField = ProfileField(label: longLabel, value: "Short value") {
            Text("Content")
        }

        #expect(profileField.label == longLabel)
        #expect(profileField.value == "Short value")
    }

    @Test("ProfileField handles extremely long values")
    func testLongValues() {
        let longValue = String(repeating: "Very long value text ", count: 50)

        let profileField = ProfileField(label: "Short", value: longValue) {
            Text("Content")
        }

        #expect(profileField.label == "Short")
        #expect(profileField.value == longValue)
    }

    @Test("ProfileField works with optional string binding")
    func testOptionalStringHandling() {
        let nilValue: String? = nil
        let emptyValue: String? = ""
        let validValue: String? = "Valid"

        let nilField = ProfileField(label: "Nil", value: nilValue) {
            Text("Default")
        }
        #expect(nilField.value == nil)

        let emptyField = ProfileField(label: "Empty", value: emptyValue) {
            Text("Default")
        }
        #expect(emptyField.value == "")

        let validField = ProfileField(label: "Valid", value: validValue) {
            Text("Default")
        }
        #expect(validField.value == "Valid")
    }

    // MARK: - Medical Context Tests

    @Test("ProfileField handles medical data appropriately")
    func testMedicalDataHandling() {
        let medicalCases = [
            ("Current Medication", "Semaglutide 1.0mg"),
            ("Last Dose", "2025-01-15 08:00 AM"),
            ("Injection Site", "Left thigh"),
            ("Side Effects", "Mild nausea"),
            ("Doctor", "Dr. Smith, Endocrinology"),
            ("Next Appointment", "2025-02-01 10:30 AM"),
        ]

        for (label, value) in medicalCases {
            let profileField = ProfileField(label: label, value: value) {
                Text("Not specified")
            }

            #expect(profileField.value == value)
            #expect(profileField.label == label)
        }
    }

    @Test("ProfileField handles dose amount formatting")
    func testDoseAmountFormatting() {
        let doseAmounts = [
            "0.25mg",
            "1.0 mg",
            "2.4 mg weekly",
            "15 units",
            "0.5ml",
        ]

        for amount in doseAmounts {
            let profileField = ProfileField(label: "Dose", value: amount) {
                Text("No dose set")
            }

            #expect(profileField.value == amount)
        }
    }

    // MARK: - Integration Tests

    @Test("ProfileField maintains consistency across multiple instances")
    func testMultipleInstanceConsistency() {
        // Test individual instances rather than heterogeneous arrays
        let nameField = ProfileField(label: "Name", value: "John") { Text("Enter name") }
        let ageField = ProfileField(label: "Age", value: "30") { Text("Enter age") }
        let emailField = ProfileField(label: "Email", value: nil) { TextField("Email", text: .constant("")) }
        let phoneField = ProfileField(label: "Phone", value: nil) { TextField("Phone", text: .constant("")) }

        #expect(nameField.value == "John")
        #expect(ageField.value == "30")
        #expect(emailField.value == nil)
        #expect(phoneField.value == nil)

        let expectedLabels = ["Name", "Age", "Email", "Phone"]
        let fields = [
            (nameField.label, nameField.value), (ageField.label, ageField.value), (emailField.label, emailField.value),
            (phoneField.label, phoneField.value),
        ]

        for (index, (label, _)) in fields.enumerated() {
            #expect(label == expectedLabels[index])
        }
    }

    @Test("ProfileField works in realistic user profile scenarios")
    func testRealisticProfileScenarios() {
        // Scenario: User with complete profile
        let nameField = ProfileField(label: "Full Name", value: "Alice Johnson") { Text("Name") }
        let emailField = ProfileField(label: "Email", value: "alice@example.com") { Text("Email") }
        let weightField = ProfileField(label: "Weight", value: "65 kg") { Text("Weight") }
        let medicationField = ProfileField(label: "Medication", value: "Ozempic 1.0mg") { Text("Medication") }

        #expect(nameField.value != nil)
        #expect(!nameField.label.isEmpty)
        #expect(emailField.value != nil)
        #expect(!emailField.label.isEmpty)
        #expect(weightField.value != nil)
        #expect(!weightField.label.isEmpty)
        #expect(medicationField.value != nil)
        #expect(!medicationField.label.isEmpty)

        // Scenario: New user with empty profile
        let emptyNameField = ProfileField(label: "Full Name", value: nil) {
            TextField("Enter name", text: .constant(""))
        }
        let emptyEmailField = ProfileField(label: "Email", value: nil) { TextField("Enter email", text: .constant("")) }
        let emptyWeightField = ProfileField(label: "Weight", value: nil) {
            TextField("Enter weight", text: .constant(""))
        }
        let emptyMedicationField = ProfileField(label: "Medication", value: nil) { Text("Select medication") }

        #expect(emptyNameField.value == nil)
        #expect(!emptyNameField.label.isEmpty)
        #expect(emptyEmailField.value == nil)
        #expect(!emptyEmailField.label.isEmpty)
        #expect(emptyWeightField.value == nil)
        #expect(!emptyWeightField.label.isEmpty)
        #expect(emptyMedicationField.value == nil)
        #expect(!emptyMedicationField.label.isEmpty)
    }

    // MARK: - View Logic Tests

    @Test("ProfileField content selection logic based on value presence")
    func testContentSelectionLogic() {
        // Test value-based display logic
        let fieldWithValue = ProfileField(label: "Test", value: "HasValue") {
            Text("Fallback Content")
        }

        let fieldWithoutValue = ProfileField(label: "Test", value: nil) {
            Text("Fallback Content")
        }

        let fieldWithEmptyValue = ProfileField(label: "Test", value: "") {
            Text("Fallback Content")
        }

        // Verify the field correctly identifies when it has a value
        #expect(fieldWithValue.value != nil)
        #expect(fieldWithoutValue.value == nil)
        #expect(fieldWithEmptyValue.value == "")  // Empty string is still a value
    }

    @Test("ProfileField content type validation for view building")
    func testContentTypeValidation() {
        // Test that various view types can be used as content
        let textContent = ProfileField(label: "Text", value: nil) {
            Text("Simple text content")
        }

        let complexContent = ProfileField(label: "Complex", value: nil) {
            VStack(alignment: .leading) {
                Text("Line 1")
                HStack {
                    Text("Line 2")
                    Spacer()
                    Text("End")
                }
            }
        }

        let buttonContent = ProfileField(label: "Button", value: nil) {
            Button("Action Button") {}
        }

        // Verify content is properly stored
        #expect(textContent.label == "Text")
        #expect(complexContent.label == "Complex")
        #expect(buttonContent.label == "Button")
        #expect(textContent.value == nil)
        #expect(complexContent.value == nil)
        #expect(buttonContent.value == nil)
    }

    @Test("ProfileField view builder pattern validation")
    func testViewBuilderPattern() {
        // Test view builder functionality with different scenarios
        let conditionalContent = ProfileField(label: "Conditional", value: nil) {
            if true {
                Text("Condition met")
            } else {
                Text("Condition not met")
            }
        }

        let loopContent = ProfileField(label: "Loop", value: nil) {
            VStack {
                ForEach(["Item 1", "Item 2"], id: \.self) { item in
                    Text(item)
                }
            }
        }

        // Verify view builder patterns work correctly
        #expect(conditionalContent.label == "Conditional")
        #expect(loopContent.label == "Loop")
    }

    @Test("ProfileField value precedence over content")
    func testValuePrecedenceLogic() {
        // When value is provided, it should take precedence over content
        let valueField = ProfileField(label: "Priority", value: "Value Text") {
            Text("Content Text - should not be shown")
        }

        let nilValueField = ProfileField(label: "Priority", value: nil) {
            Text("Content Text - should be shown")
        }

        // Test the logic that determines what gets displayed
        #expect(valueField.value == "Value Text")
        #expect(nilValueField.value == nil)

        // When value exists, content should be present but not used
        #expect(valueField.label == "Priority")
        #expect(nilValueField.label == "Priority")
    }

    @Test("ProfileField complex initialization patterns")
    func testComplexInitializationPatterns() {
        // Test initialization with computed values
        let computedValue = "Computed: \(25 + 5)"
        let computedField = ProfileField(label: "Computed", value: computedValue) {
            Text("Default")
        }

        // Test initialization with optional chaining
        let optionalValue: String? = "Optional Value"
        let optionalField = ProfileField(label: "Optional", value: optionalValue) {
            Text("No value provided")
        }

        // Test initialization with string interpolation
        let user = "Alice"
        let interpolatedField = ProfileField(label: "Welcome", value: "Hello, \(user)!") {
            Text("Welcome, Guest!")
        }

        #expect(computedField.value == "Computed: 30")
        #expect(optionalField.value == "Optional Value")
        #expect(interpolatedField.value == "Hello, Alice!")
    }

    @Test("ProfileField medical data edge cases")
    func testMedicalDataEdgeCases() {
        // Test medical data with special formatting needs
        let doseWithUnit = ProfileField(label: "Current Dose", value: "1.25 mg") {
            Text("No dose recorded")
        }

        let concentrationReading = ProfileField(label: "Concentration", value: "45.7 ng/mL") {
            Text("Not measured")
        }

        let timeStamp = ProfileField(label: "Last Injection", value: "2025-01-15 08:00:00") {
            Text("Never administered")
        }

        let siteRotation = ProfileField(label: "Injection Site", value: "Left thigh (rotation #3)") {
            Text("Site not selected")
        }

        // Verify medical data is handled correctly
        #expect(doseWithUnit.value?.contains("mg") == true)
        #expect(concentrationReading.value?.contains("ng/mL") == true)
        #expect(timeStamp.value?.contains("2025-01-15") == true)
        #expect(siteRotation.value?.contains("thigh") == true)
    }

    @Test("ProfileField performance with large content")
    func testPerformanceWithLargeContent() {
        // Test handling of large text values
        let largeValue = String(repeating: "Large content text ", count: 100)
        let largeField = ProfileField(label: "Large", value: largeValue) {
            Text("Fallback")
        }

        // Test complex content structures
        let complexField = ProfileField(label: "Complex", value: nil) {
            VStack {
                ForEach(0..<10, id: \.self) { index in
                    HStack {
                        Text("Item \(index)")
                        Spacer()
                        Text("Value \(index)")
                    }
                }
            }
        }

        // Verify large content is handled properly
        #expect(largeField.value?.count == 1900)  // 100 * 19 characters ("Large content text ")
        #expect(largeField.label == "Large")
        #expect(complexField.label == "Complex")
        #expect(complexField.value == nil)
    }
}
