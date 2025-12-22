//
//  ShortcutButtonTests.swift
//  JabTrackerTests
//
//  Tests for ShortcutButton and ShortcutRowButton components.
//

import SwiftUI
import Testing

@testable import JabTracker

@Suite("ShortcutButton Tests")
struct ShortcutButtonTests {

    // MARK: - ShortcutButton Initialization Tests

    @Test("ShortcutButton initializes with required parameters")
    @MainActor
    func shortcutButtonInitializesWithRequiredParameters() {
        var actionCalled = false
        let button = ShortcutButton(
            icon: "magnifyingglass",
            label: "Search",
            isEnabled: true,
            action: { actionCalled = true }
        )

        #expect(button.icon == "magnifyingglass")
        #expect(button.label == "Search")
        #expect(button.isEnabled == true)

        // Test action can be called
        button.action()
        #expect(actionCalled == true)
    }

    @Test("ShortcutButton disabled state")
    @MainActor
    func shortcutButtonDisabledState() {
        let button = ShortcutButton(
            icon: "barcode.viewfinder",
            label: "Barcode",
            isEnabled: false,
            action: {}
        )

        #expect(button.isEnabled == false)
    }

    @Test("ShortcutButton accessibility identifier follows pattern")
    @MainActor
    func shortcutButtonAccessibilityIdentifier() {
        let button = ShortcutButton(
            icon: "magnifyingglass",
            label: "Search",
            isEnabled: true,
            action: {}
        )

        #expect(button.accessibilityIdentifierValue == "shortcut-button-search")
    }

    @Test("ShortcutButton accessibility identifier handles multi-word labels")
    @MainActor
    func shortcutButtonAccessibilityIdentifierMultiWord() {
        let button = ShortcutButton(
            icon: "camera.fill",
            label: "Photo AI",
            isEnabled: false,
            action: {}
        )

        #expect(button.accessibilityIdentifierValue == "shortcut-button-photo ai")
    }

    // MARK: - All Shortcut Icons Tests

    @Test("ShortcutButton supports Search icon")
    @MainActor
    func supportsSearchIcon() {
        let button = ShortcutButton(
            icon: "magnifyingglass",
            label: "Search",
            isEnabled: true,
            action: {}
        )
        #expect(button.icon == "magnifyingglass")
    }

    @Test("ShortcutButton supports Barcode icon")
    @MainActor
    func supportsBarcodeIcon() {
        let button = ShortcutButton(
            icon: "barcode.viewfinder",
            label: "Barcode",
            isEnabled: false,
            action: {}
        )
        #expect(button.icon == "barcode.viewfinder")
    }

    @Test("ShortcutButton supports Photo icon")
    @MainActor
    func supportsPhotoIcon() {
        let button = ShortcutButton(
            icon: "camera.fill",
            label: "Photo",
            isEnabled: false,
            action: {}
        )
        #expect(button.icon == "camera.fill")
    }

    @Test("ShortcutButton supports Shots icon")
    @MainActor
    func supportsShotsIcon() {
        let button = ShortcutButton(
            icon: "syringe.fill",
            label: "Shots",
            isEnabled: true,
            action: {}
        )
        #expect(button.icon == "syringe.fill")
    }
}

@Suite("ShortcutRowButton Tests")
struct ShortcutRowButtonTests {

    // MARK: - ShortcutRowButton Initialization Tests

    @Test("ShortcutRowButton initializes with required parameters")
    @MainActor
    func shortcutRowButtonInitializesWithRequiredParameters() {
        var actionCalled = false
        let button = ShortcutRowButton(
            icon: "scalemass.fill",
            label: "Weight",
            isEnabled: false,
            action: { actionCalled = true }
        )

        #expect(button.icon == "scalemass.fill")
        #expect(button.label == "Weight")
        #expect(button.isEnabled == false)

        // Test action can be called
        button.action()
        #expect(actionCalled == true)
    }

    @Test("ShortcutRowButton accessibility identifier follows pattern")
    @MainActor
    func shortcutRowButtonAccessibilityIdentifier() {
        let button = ShortcutRowButton(
            icon: "scalemass.fill",
            label: "Weight",
            isEnabled: false,
            action: {}
        )

        #expect(button.accessibilityIdentifierValue == "shortcut-row-weight")
    }

    // MARK: - All Row Icons Tests

    @Test("ShortcutRowButton supports Weight icon")
    @MainActor
    func supportsWeightIcon() {
        let button = ShortcutRowButton(
            icon: "scalemass.fill",
            label: "Weight",
            isEnabled: false,
            action: {}
        )
        #expect(button.icon == "scalemass.fill")
    }

    @Test("ShortcutRowButton supports Quick Add icon")
    @MainActor
    func supportsQuickAddIcon() {
        let button = ShortcutRowButton(
            icon: "plus.circle.fill",
            label: "Quick Add",
            isEnabled: false,
            action: {}
        )
        #expect(button.icon == "plus.circle.fill")
    }

    @Test("ShortcutRowButton supports Metrics icon")
    @MainActor
    func supportsMetricsIcon() {
        let button = ShortcutRowButton(
            icon: "chart.bar.fill",
            label: "Metrics",
            isEnabled: false,
            action: {}
        )
        #expect(button.icon == "chart.bar.fill")
    }

    @Test("ShortcutRowButton supports Your Foods icon")
    @MainActor
    func supportsYourFoodsIcon() {
        let button = ShortcutRowButton(
            icon: "star.fill",
            label: "Your Foods",
            isEnabled: false,
            action: {}
        )
        #expect(button.icon == "star.fill")
    }

    @Test("ShortcutRowButton supports Recipes icon")
    @MainActor
    func supportsRecipesIcon() {
        let button = ShortcutRowButton(
            icon: "book.fill",
            label: "Recipes",
            isEnabled: false,
            action: {}
        )
        #expect(button.icon == "book.fill")
    }

    @Test("ShortcutRowButton supports Edit Days icon")
    @MainActor
    func supportsEditDaysIcon() {
        let button = ShortcutRowButton(
            icon: "calendar.badge.plus",
            label: "Edit Days",
            isEnabled: false,
            action: {}
        )
        #expect(button.icon == "calendar.badge.plus")
    }
}
