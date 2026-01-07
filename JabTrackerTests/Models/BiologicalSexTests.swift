//
//  BiologicalSexTests.swift
//  JabTrackerTests
//
//  Tests for BiologicalSex enum used for TDEE calculations.
//

import Foundation
import Testing

@testable import JabTracker

@Suite("BiologicalSex Tests")
struct BiologicalSexTests {

    // MARK: - Raw Value Tests

    @Test("Raw values are correct for each case")
    func testRawValues() {
        #expect(BiologicalSex.notSet.rawValue == "")
        #expect(BiologicalSex.female.rawValue == "female")
        #expect(BiologicalSex.male.rawValue == "male")
        #expect(BiologicalSex.other.rawValue == "other")
    }

    // MARK: - Display Name Tests

    @Test("displayName returns correct value for notSet")
    func testDisplayNameNotSet() {
        #expect(BiologicalSex.notSet.displayName == "Not Set")
    }

    @Test("displayName returns correct value for female")
    func testDisplayNameFemale() {
        #expect(BiologicalSex.female.displayName == "Female")
    }

    @Test("displayName returns correct value for male")
    func testDisplayNameMale() {
        #expect(BiologicalSex.male.displayName == "Male")
    }

    @Test("displayName returns correct value for other")
    func testDisplayNameOther() {
        #expect(BiologicalSex.other.displayName == "Other")
    }

    // MARK: - BMR Adjustment Tests

    @Test("bmrAdjustment returns nil for notSet")
    func testBmrAdjustmentNotSet() {
        #expect(BiologicalSex.notSet.bmrAdjustment == nil)
    }

    @Test("bmrAdjustment returns -161 for female (Mifflin-St Jeor formula)")
    func testBmrAdjustmentFemale() {
        #expect(BiologicalSex.female.bmrAdjustment == -161)
    }

    @Test("bmrAdjustment returns 5 for male (Mifflin-St Jeor formula)")
    func testBmrAdjustmentMale() {
        #expect(BiologicalSex.male.bmrAdjustment == 5)
    }

    @Test("bmrAdjustment returns -78 for other (average of male and female)")
    func testBmrAdjustmentOther() {
        // Average of male (5) and female (-161) = (5 + -161) / 2 = -78
        #expect(BiologicalSex.other.bmrAdjustment == -78)
    }

    // MARK: - Allows Calculation Tests

    @Test("allowsCalculation returns false for notSet")
    func testAllowsCalculationNotSet() {
        #expect(BiologicalSex.notSet.allowsCalculation == false)
    }

    @Test("allowsCalculation returns true for female")
    func testAllowsCalculationFemale() {
        #expect(BiologicalSex.female.allowsCalculation == true)
    }

    @Test("allowsCalculation returns true for male")
    func testAllowsCalculationMale() {
        #expect(BiologicalSex.male.allowsCalculation == true)
    }

    @Test("allowsCalculation returns true for other")
    func testAllowsCalculationOther() {
        #expect(BiologicalSex.other.allowsCalculation == true)
    }

    // MARK: - HealthKit Initializer Tests

    @Test("Init from HealthKit nil returns notSet")
    func testInitFromHealthKitNil() {
        let sex = BiologicalSex(fromHealthKit: nil)
        #expect(sex == .notSet)
    }

    @Test("Init from HealthKit 'male' returns male")
    func testInitFromHealthKitMale() {
        let sex = BiologicalSex(fromHealthKit: "male")
        #expect(sex == .male)
    }

    @Test("Init from HealthKit 'MALE' (uppercase) returns male")
    func testInitFromHealthKitMaleUppercase() {
        let sex = BiologicalSex(fromHealthKit: "MALE")
        #expect(sex == .male)
    }

    @Test("Init from HealthKit 'm' returns male")
    func testInitFromHealthKitMaleShort() {
        let sex = BiologicalSex(fromHealthKit: "m")
        #expect(sex == .male)
    }

    @Test("Init from HealthKit 'M' (uppercase short) returns male")
    func testInitFromHealthKitMaleShortUppercase() {
        let sex = BiologicalSex(fromHealthKit: "M")
        #expect(sex == .male)
    }

    @Test("Init from HealthKit 'female' returns female")
    func testInitFromHealthKitFemale() {
        let sex = BiologicalSex(fromHealthKit: "female")
        #expect(sex == .female)
    }

    @Test("Init from HealthKit 'FEMALE' (uppercase) returns female")
    func testInitFromHealthKitFemaleUppercase() {
        let sex = BiologicalSex(fromHealthKit: "FEMALE")
        #expect(sex == .female)
    }

    @Test("Init from HealthKit 'f' returns female")
    func testInitFromHealthKitFemaleShort() {
        let sex = BiologicalSex(fromHealthKit: "f")
        #expect(sex == .female)
    }

    @Test("Init from HealthKit 'F' (uppercase short) returns female")
    func testInitFromHealthKitFemaleShortUppercase() {
        let sex = BiologicalSex(fromHealthKit: "F")
        #expect(sex == .female)
    }

    @Test("Init from HealthKit 'other' returns other")
    func testInitFromHealthKitOther() {
        let sex = BiologicalSex(fromHealthKit: "other")
        #expect(sex == .other)
    }

    @Test("Init from HealthKit 'OTHER' (uppercase) returns other")
    func testInitFromHealthKitOtherUppercase() {
        let sex = BiologicalSex(fromHealthKit: "OTHER")
        #expect(sex == .other)
    }

    @Test("Init from HealthKit unknown value returns notSet")
    func testInitFromHealthKitUnknown() {
        let sex = BiologicalSex(fromHealthKit: "unknown")
        #expect(sex == .notSet)
    }

    @Test("Init from HealthKit empty string returns notSet")
    func testInitFromHealthKitEmptyString() {
        let sex = BiologicalSex(fromHealthKit: "")
        #expect(sex == .notSet)
    }

    @Test("Init from HealthKit garbage value returns notSet")
    func testInitFromHealthKitGarbage() {
        let sex = BiologicalSex(fromHealthKit: "xyz123")
        #expect(sex == .notSet)
    }

    // MARK: - Selectable Options Tests

    @Test("selectableOptions excludes notSet")
    func testSelectableOptionsExcludesNotSet() {
        let options = BiologicalSex.selectableOptions
        #expect(!options.contains(.notSet))
    }

    @Test("selectableOptions contains female, male, and other")
    func testSelectableOptionsContainsAllSelectable() {
        let options = BiologicalSex.selectableOptions
        #expect(options.contains(.female))
        #expect(options.contains(.male))
        #expect(options.contains(.other))
    }

    @Test("selectableOptions has exactly 3 options")
    func testSelectableOptionsCount() {
        #expect(BiologicalSex.selectableOptions.count == 3)
    }

    @Test("selectableOptions order is female, male, other")
    func testSelectableOptionsOrder() {
        let options = BiologicalSex.selectableOptions
        #expect(options[0] == .female)
        #expect(options[1] == .male)
        #expect(options[2] == .other)
    }

    // MARK: - CaseIterable Tests

    @Test("allCases contains all 4 cases")
    func testAllCasesCount() {
        #expect(BiologicalSex.allCases.count == 4)
    }

    @Test("allCases contains all expected values")
    func testAllCasesContainsAll() {
        let allCases = BiologicalSex.allCases
        #expect(allCases.contains(.notSet))
        #expect(allCases.contains(.female))
        #expect(allCases.contains(.male))
        #expect(allCases.contains(.other))
    }

    // MARK: - Codable Tests

    @Test("Encoding and decoding preserves value")
    func testCodable() throws {
        let original = BiologicalSex.female
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(BiologicalSex.self, from: data)

        #expect(decoded == original)
    }

    @Test("All cases round-trip correctly through JSON")
    func testAllCasesRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for sex in BiologicalSex.allCases {
            let data = try encoder.encode(sex)
            let decoded = try decoder.decode(BiologicalSex.self, from: data)
            #expect(decoded == sex, "Failed round-trip for \(sex)")
        }
    }
}
