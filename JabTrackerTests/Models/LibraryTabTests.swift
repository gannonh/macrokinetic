//
//  LibraryTabTests.swift
//  JabTrackerTests
//
//  Tests for LibraryTab enum.
//

import Testing

@testable import JabTracker

@Suite("LibraryTab Tests")
struct LibraryTabTests {

    // MARK: - Raw Value Tests

    @Test("recipes has correct raw value")
    func testRecipesRawValue() {
        let tab = LibraryTab.recipes
        #expect(tab.rawValue == "recipes")
    }

    @Test("foods has correct raw value")
    func testFoodsRawValue() {
        let tab = LibraryTab.foods
        #expect(tab.rawValue == "foods")
    }

    @Test("favorites has correct raw value")
    func testFavoritesRawValue() {
        let tab = LibraryTab.favorites
        #expect(tab.rawValue == "favorites")
    }

    // MARK: - Display Name Tests

    @Test("recipes displays as 'Recipes'")
    func testRecipesDisplayName() {
        let tab = LibraryTab.recipes
        #expect(tab.displayName == "Recipes")
    }

    @Test("foods displays as 'Foods'")
    func testFoodsDisplayName() {
        let tab = LibraryTab.foods
        #expect(tab.displayName == "Foods")
    }

    @Test("favorites displays as 'Favorites'")
    func testFavoritesDisplayName() {
        let tab = LibraryTab.favorites
        #expect(tab.displayName == "Favorites")
    }

    // MARK: - isEnabled Tests

    @Test("foods tab is enabled")
    func testFoodsIsEnabled() {
        let tab = LibraryTab.foods
        #expect(tab.isEnabled == true)
    }

    @Test("recipes tab is disabled")
    func testRecipesIsDisabled() {
        let tab = LibraryTab.recipes
        #expect(tab.isEnabled == false)
    }

    @Test("favorites tab is disabled")
    func testFavoritesIsDisabled() {
        let tab = LibraryTab.favorites
        #expect(tab.isEnabled == false)
    }

    // MARK: - CaseIterable Tests

    @Test("allCases contains all tabs")
    func testAllCases() {
        let allCases = LibraryTab.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.recipes))
        #expect(allCases.contains(.foods))
        #expect(allCases.contains(.scheduled))
        #expect(allCases.contains(.favorites))
    }

    // MARK: - Initialization Tests

    @Test("Can initialize from raw value")
    func testInitFromRawValue() {
        #expect(LibraryTab(rawValue: "recipes") == .recipes)
        #expect(LibraryTab(rawValue: "foods") == .foods)
        #expect(LibraryTab(rawValue: "favorites") == .favorites)
    }

    @Test("Returns nil for invalid raw value")
    func testInitFromInvalidRawValue() {
        let tab = LibraryTab(rawValue: "invalid")
        #expect(tab == nil)
    }
}
