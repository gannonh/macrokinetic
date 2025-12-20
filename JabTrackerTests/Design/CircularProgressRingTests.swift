//
//  CircularProgressRingTests.swift
//  JabTrackerTests
//
//  Tests for the CircularProgressRing component.
//

import SwiftUI
import Testing

@testable import JabTracker

@Suite("CircularProgressRing Tests")
struct CircularProgressRingTests {

    // MARK: - Initialization Tests

    @Test("Ring initializes with required parameters")
    @MainActor
    func ringInitializesWithRequiredParameters() {
        let ring = CircularProgressRing(
            progress: 0.5,
            label: "Calories",
            valueText: "50%",
            color: .orange
        )

        #expect(ring.progress == 0.5)
        #expect(ring.label == "Calories")
        #expect(ring.valueText == "50%")
    }

    @Test("Ring uses default values for optional parameters")
    @MainActor
    func ringUsesDefaultValues() {
        let ring = CircularProgressRing(
            progress: 0.75,
            label: "Protein",
            valueText: "75%",
            color: .blue
        )

        #expect(ring.lineWidth == 8)
        #expect(ring.size == 60)
    }

    @Test("Ring accepts custom line width and size")
    @MainActor
    func ringAcceptsCustomDimensions() {
        let ring = CircularProgressRing(
            progress: 0.3,
            label: "Fat",
            valueText: "30%",
            color: .purple,
            lineWidth: 10,
            size: 80
        )

        #expect(ring.lineWidth == 10)
        #expect(ring.size == 80)
    }

    // MARK: - Progress Value Tests

    @Test("Ring handles zero progress")
    @MainActor
    func ringHandlesZeroProgress() {
        let ring = CircularProgressRing(
            progress: 0.0,
            label: "Carbs",
            valueText: "0%",
            color: .green
        )

        #expect(ring.progress == 0.0)
    }

    @Test("Ring handles full progress")
    @MainActor
    func ringHandlesFullProgress() {
        let ring = CircularProgressRing(
            progress: 1.0,
            label: "Calories",
            valueText: "100%",
            color: .orange
        )

        #expect(ring.progress == 1.0)
    }

    @Test("Ring handles overflow progress greater than 1.0")
    @MainActor
    func ringHandlesOverflowProgress() {
        let ring = CircularProgressRing(
            progress: 1.5,
            label: "Calories",
            valueText: "150%",
            color: .orange
        )

        // Ring should accept values > 1.0 for overflow display
        #expect(ring.progress == 1.5)
    }

    // MARK: - Macro Color Tests

    @Test("Ring supports standard macro colors")
    @MainActor
    func ringSupportsStandardMacroColors() {
        let caloriesRing = CircularProgressRing(
            progress: 0.5, label: "Calories", valueText: "50%", color: .orange)
        let proteinRing = CircularProgressRing(
            progress: 0.5, label: "Protein", valueText: "50%", color: .blue)
        let carbsRing = CircularProgressRing(
            progress: 0.5, label: "Carbs", valueText: "50%", color: .green)
        let fatRing = CircularProgressRing(
            progress: 0.5, label: "Fat", valueText: "50%", color: .purple)

        // All rings should initialize without error
        #expect(caloriesRing.label == "Calories")
        #expect(proteinRing.label == "Protein")
        #expect(carbsRing.label == "Carbs")
        #expect(fatRing.label == "Fat")
    }

    // MARK: - Accessibility Identifier Tests

    @Test("Ring generates correct accessibility identifier from label")
    @MainActor
    func ringGeneratesAccessibilityIdentifier() {
        let ring = CircularProgressRing(
            progress: 0.5,
            label: "Calories",
            valueText: "50%",
            color: .orange
        )

        // The accessibilityIdentifier should be "progress-ring-calories"
        #expect(ring.accessibilityIdentifierValue == "progress-ring-calories")
    }

    @Test("Ring accessibility identifier handles multi-word labels")
    @MainActor
    func ringAccessibilityIdentifierHandlesMultiWordLabels() {
        let ring = CircularProgressRing(
            progress: 0.5,
            label: "Net Carbs",
            valueText: "50%",
            color: .green
        )

        // Should lowercase and handle spaces
        #expect(ring.accessibilityIdentifierValue == "progress-ring-net carbs")
    }
}
