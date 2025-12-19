//
//  FoodSourceTests.swift
//  JabTrackerTests
//
//  Tests for FoodSource enum - identifies the source of food data.
//

import Foundation
import Testing

@testable import JabTracker

struct FoodSourceTests {

    // MARK: - Case Existence Tests

    @Test("All food source cases exist - should have exactly 3 cases")
    func testAllCasesCount() {
        #expect(FoodSource.allCases.count == 3)
    }

    @Test("Local case exists for bundled USDA database")
    func testLocalCaseExists() {
        let source = FoodSource.local
        #expect(source == .local)
    }

    @Test("OpenFoodFacts case exists for API data")
    func testOpenFoodFactsCaseExists() {
        let source = FoodSource.openFoodFacts
        #expect(source == .openFoodFacts)
    }

    @Test("UserCreated case exists for custom foods")
    func testUserCreatedCaseExists() {
        let source = FoodSource.userCreated
        #expect(source == .userCreated)
    }

    // MARK: - Raw Value Tests

    @Test("Local raw value is 'local'")
    func testLocalRawValue() {
        #expect(FoodSource.local.rawValue == "local")
    }

    @Test("OpenFoodFacts raw value is 'openFoodFacts'")
    func testOpenFoodFactsRawValue() {
        #expect(FoodSource.openFoodFacts.rawValue == "openFoodFacts")
    }

    @Test("UserCreated raw value is 'userCreated'")
    func testUserCreatedRawValue() {
        #expect(FoodSource.userCreated.rawValue == "userCreated")
    }

    // MARK: - Display Name Tests

    @Test("Local displayName returns 'USDA'")
    func testLocalDisplayName() {
        #expect(FoodSource.local.displayName == "USDA")
    }

    @Test("OpenFoodFacts displayName returns 'Open Food Facts'")
    func testOpenFoodFactsDisplayName() {
        #expect(FoodSource.openFoodFacts.displayName == "Open Food Facts")
    }

    @Test("UserCreated displayName returns 'Custom'")
    func testUserCreatedDisplayName() {
        #expect(FoodSource.userCreated.displayName == "Custom")
    }

    // MARK: - Codable Conformance Tests

    @Test("Local case encodes and decodes correctly")
    func testLocalCodableRoundTrip() throws {
        let original = FoodSource.local
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(original)
        let decoded = try decoder.decode(FoodSource.self, from: encoded)

        #expect(decoded == original)
    }

    @Test("OpenFoodFacts case encodes and decodes correctly")
    func testOpenFoodFactsCodableRoundTrip() throws {
        let original = FoodSource.openFoodFacts
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(original)
        let decoded = try decoder.decode(FoodSource.self, from: encoded)

        #expect(decoded == original)
    }

    @Test("UserCreated case encodes and decodes correctly")
    func testUserCreatedCodableRoundTrip() throws {
        let original = FoodSource.userCreated
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let encoded = try encoder.encode(original)
        let decoded = try decoder.decode(FoodSource.self, from: encoded)

        #expect(decoded == original)
    }

    @Test("Encoded JSON contains expected raw value string")
    func testEncodedJSONFormat() throws {
        let encoder = JSONEncoder()

        let localData = try encoder.encode(FoodSource.local)
        let localString = String(data: localData, encoding: .utf8)
        #expect(localString == "\"local\"")

        let openFoodFactsData = try encoder.encode(FoodSource.openFoodFacts)
        let openFoodFactsString = String(data: openFoodFactsData, encoding: .utf8)
        #expect(openFoodFactsString == "\"openFoodFacts\"")

        let userCreatedData = try encoder.encode(FoodSource.userCreated)
        let userCreatedString = String(data: userCreatedData, encoding: .utf8)
        #expect(userCreatedString == "\"userCreated\"")
    }

    @Test("Decodes from valid JSON string")
    func testDecodeFromJSONString() throws {
        let decoder = JSONDecoder()

        let localData = Data("\"local\"".utf8)
        let local = try decoder.decode(FoodSource.self, from: localData)
        #expect(local == .local)

        let openFoodFactsData = Data("\"openFoodFacts\"".utf8)
        let openFoodFacts = try decoder.decode(FoodSource.self, from: openFoodFactsData)
        #expect(openFoodFacts == .openFoodFacts)

        let userCreatedData = Data("\"userCreated\"".utf8)
        let userCreated = try decoder.decode(FoodSource.self, from: userCreatedData)
        #expect(userCreated == .userCreated)
    }

    @Test("Decoding invalid value throws error")
    func testDecodeInvalidValueThrows() {
        let decoder = JSONDecoder()
        let invalidData = Data("\"invalid\"".utf8)

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(FoodSource.self, from: invalidData)
        }
    }
}
