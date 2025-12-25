//
//  ShortcutsSheetTests.swift
//  JabTrackerTests
//
//  Tests for the ShortcutsSheet view.
//

import SwiftUI
import Testing

@testable import JabTracker

@Suite("ShortcutsSheet Tests")
struct ShortcutsSheetTests {

    // MARK: - Initialization Tests

    @Test("ShortcutsSheet initializes with bindings")
    @MainActor
    func shortcutsSheetInitializesWithBindings() {
        var showingFoodSearch = false
        var showingQuickDose = false
        var showingFoodSearchWithScan = false
        var showingFoodLibrary = false
        var showingQuickAdd = false

        let sheet = ShortcutsSheet(
            showingFoodSearch: Binding(
                get: { showingFoodSearch },
                set: { showingFoodSearch = $0 }
            ),
            showingQuickDose: Binding(
                get: { showingQuickDose },
                set: { showingQuickDose = $0 }
            ),
            showingFoodSearchWithScan: Binding(
                get: { showingFoodSearchWithScan },
                set: { showingFoodSearchWithScan = $0 }
            ),
            showingFoodLibrary: Binding(
                get: { showingFoodLibrary },
                set: { showingFoodLibrary = $0 }
            ),
            showingQuickAdd: Binding(
                get: { showingQuickAdd },
                set: { showingQuickAdd = $0 }
            )
        )

        // Bindings should be set
        #expect(sheet.showingFoodSearch == false)
        #expect(sheet.showingQuickDose == false)
        #expect(sheet.showingFoodSearchWithScan == false)
        #expect(sheet.showingFoodLibrary == false)
        #expect(sheet.showingQuickAdd == false)
    }

    // MARK: - Top Row Shortcut Tests

    @Test("ShortcutsSheet has Search shortcut enabled")
    @MainActor
    func hasSearchShortcutEnabled() {
        let shortcuts = ShortcutsSheet.topRowShortcuts

        let searchShortcut = shortcuts.first { $0.label == "Search" }
        #expect(searchShortcut != nil)
        #expect(searchShortcut?.isEnabled == true)
        #expect(searchShortcut?.icon == "magnifyingglass")
    }

    @Test("ShortcutsSheet has Barcode shortcut enabled")
    @MainActor
    func hasBarcodeShortcutEnabled() {
        let shortcuts = ShortcutsSheet.topRowShortcuts

        let barcodeShortcut = shortcuts.first { $0.label == "Barcode" }
        #expect(barcodeShortcut != nil)
        #expect(barcodeShortcut?.isEnabled == true)
        #expect(barcodeShortcut?.icon == "barcode.viewfinder")
    }

    @Test("ShortcutsSheet has Photo shortcut disabled")
    @MainActor
    func hasPhotoShortcutDisabled() {
        let shortcuts = ShortcutsSheet.topRowShortcuts

        let photoShortcut = shortcuts.first { $0.label == "Photo" }
        #expect(photoShortcut != nil)
        #expect(photoShortcut?.isEnabled == false)
        #expect(photoShortcut?.icon == "camera.fill")
    }

    @Test("ShortcutsSheet has Shots shortcut enabled")
    @MainActor
    func hasShotsShortcutEnabled() {
        let shortcuts = ShortcutsSheet.topRowShortcuts

        let shotsShortcut = shortcuts.first { $0.label == "Shots" }
        #expect(shotsShortcut != nil)
        #expect(shotsShortcut?.isEnabled == true)
        #expect(shotsShortcut?.icon == "syringe.fill")
    }

    @Test("ShortcutsSheet top row has 4 shortcuts in correct order")
    @MainActor
    func topRowHasFourShortcutsInOrder() {
        let shortcuts = ShortcutsSheet.topRowShortcuts

        #expect(shortcuts.count == 4)
        #expect(shortcuts[0].label == "Search")
        #expect(shortcuts[1].label == "Barcode")
        #expect(shortcuts[2].label == "Photo")
        #expect(shortcuts[3].label == "Shots")
    }

    // MARK: - List Row Shortcut Tests

    @Test("ShortcutsSheet has Your Foods shortcut enabled")
    @MainActor
    func hasYourFoodsShortcutEnabled() {
        let shortcuts = ShortcutsSheet.listRowShortcuts

        let yourFoodsShortcut = shortcuts.first { $0.label == "Your Foods" }
        #expect(yourFoodsShortcut != nil)
        #expect(yourFoodsShortcut?.isEnabled == true)
    }

    @Test("ShortcutsSheet list rows have 6 shortcuts")
    @MainActor
    func listRowsHaveSixShortcuts() {
        let shortcuts = ShortcutsSheet.listRowShortcuts

        #expect(shortcuts.count == 6)
    }

    @Test("ShortcutsSheet list rows include Weight")
    @MainActor
    func listRowsIncludeWeight() {
        let shortcuts = ShortcutsSheet.listRowShortcuts

        let weightShortcut = shortcuts.first { $0.label == "Weight" }
        #expect(weightShortcut != nil)
        #expect(weightShortcut?.icon == "scalemass.fill")
    }

    @Test("ShortcutsSheet list rows include Quick Add")
    @MainActor
    func listRowsIncludeQuickAdd() {
        let shortcuts = ShortcutsSheet.listRowShortcuts

        let quickAddShortcut = shortcuts.first { $0.label == "Quick Add" }
        #expect(quickAddShortcut != nil)
        #expect(quickAddShortcut?.icon == "plus.circle.fill")
        #expect(quickAddShortcut?.isEnabled == true)
    }

    @Test("ShortcutsSheet list rows include Metrics")
    @MainActor
    func listRowsIncludeMetrics() {
        let shortcuts = ShortcutsSheet.listRowShortcuts

        let metricsShortcut = shortcuts.first { $0.label == "Metrics" }
        #expect(metricsShortcut != nil)
        #expect(metricsShortcut?.icon == "chart.bar.fill")
    }

    @Test("ShortcutsSheet list rows include Your Foods")
    @MainActor
    func listRowsIncludeYourFoods() {
        let shortcuts = ShortcutsSheet.listRowShortcuts

        let yourFoodsShortcut = shortcuts.first { $0.label == "Your Foods" }
        #expect(yourFoodsShortcut != nil)
        #expect(yourFoodsShortcut?.icon == "star.fill")
    }

    @Test("ShortcutsSheet list rows include Recipes")
    @MainActor
    func listRowsIncludeRecipes() {
        let shortcuts = ShortcutsSheet.listRowShortcuts

        let recipesShortcut = shortcuts.first { $0.label == "Recipes" }
        #expect(recipesShortcut != nil)
        #expect(recipesShortcut?.icon == "book.fill")
    }

    @Test("ShortcutsSheet list rows include Edit Days")
    @MainActor
    func listRowsIncludeEditDays() {
        let shortcuts = ShortcutsSheet.listRowShortcuts

        let editDaysShortcut = shortcuts.first { $0.label == "Edit Days" }
        #expect(editDaysShortcut != nil)
        #expect(editDaysShortcut?.icon == "calendar.badge.plus")
    }

    // MARK: - Accessibility Tests

    @Test("ShortcutsSheet has correct accessibility identifier")
    @MainActor
    func hasCorrectAccessibilityIdentifier() {
        #expect(ShortcutsSheet.accessibilityIdentifierValue == "shortcuts-sheet")
    }
}

// MARK: - ShortcutItem Model Tests

@Suite("ShortcutItem Tests")
struct ShortcutItemTests {

    @Test("ShortcutItem initializes correctly")
    @MainActor
    func shortcutItemInitializesCorrectly() {
        let item = ShortcutItem(
            icon: "magnifyingglass",
            label: "Search",
            isEnabled: true
        )

        #expect(item.icon == "magnifyingglass")
        #expect(item.label == "Search")
        #expect(item.isEnabled == true)
    }

    @Test("ShortcutItem is identifiable by label")
    @MainActor
    func shortcutItemIsIdentifiableByLabel() {
        let item = ShortcutItem(
            icon: "magnifyingglass",
            label: "Search",
            isEnabled: true
        )

        #expect(item.id == "Search")
    }
}
