//
//  FoodLibrarySortOptionTests.swift
//  JabTrackerTests
//
//  Tests for FoodLibrarySortOption enum.
//

import Testing

@testable import JabTracker

@Suite("FoodLibrarySortOption Tests")
struct FoodLibrarySortOptionTests {

    // MARK: - Raw Value Tests

    @Test("dateAdded has correct raw value")
    func testDateAddedRawValue() {
        let option = FoodLibrarySortOption.dateAdded
        #expect(option.rawValue == "dateAdded")
    }

    @Test("name has correct raw value")
    func testNameRawValue() {
        let option = FoodLibrarySortOption.name
        #expect(option.rawValue == "name")
    }

    // MARK: - Display Name Tests

    @Test("dateAdded displays as 'Date Added'")
    func testDateAddedDisplayName() {
        let option = FoodLibrarySortOption.dateAdded
        #expect(option.displayName == "Date Added")
    }

    @Test("name displays as 'Name'")
    func testNameDisplayName() {
        let option = FoodLibrarySortOption.name
        #expect(option.displayName == "Name")
    }

    // MARK: - CaseIterable Tests

    @Test("allCases contains all options")
    func testAllCases() {
        let allCases = FoodLibrarySortOption.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.dateAdded))
        #expect(allCases.contains(.name))
    }

    // MARK: - Initialization Tests

    @Test("Can initialize from raw value dateAdded")
    func testInitFromRawValueDateAdded() {
        let option = FoodLibrarySortOption(rawValue: "dateAdded")
        #expect(option == .dateAdded)
    }

    @Test("Can initialize from raw value name")
    func testInitFromRawValueName() {
        let option = FoodLibrarySortOption(rawValue: "name")
        #expect(option == .name)
    }

    @Test("Returns nil for invalid raw value")
    func testInitFromInvalidRawValue() {
        let option = FoodLibrarySortOption(rawValue: "invalid")
        #expect(option == nil)
    }
}
