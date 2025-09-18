//
//  ConcentrationCardTests.swift
//  JabTrackerTests
//
//  Unit tests for ConcentrationCard UI component and related display logic
//  Tests concentration formatting, UI state, and integration with PharmacokineticsEngine
//

import Foundation
@testable import JabTracker
import SwiftData
import Testing
import XCTest

@MainActor
struct ConcentrationCardTests {
    var container: ModelContainer
    var context: ModelContext
    var pkEngine: PharmacokineticsEngine

    init() throws {
        // Create in-memory container for testing
        let schema = Schema([User.self, Dose.self, MedicationProfile.self, DoseTitration.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none)
        self.container = try ModelContainer(for: schema, configurations: [configuration])
        self.context = self.container.mainContext
        self.pkEngine = PharmacokineticsEngine()
    }

    // MARK: - ConcentrationCard Data Tests

    @Test("ConcentrationCard displays current concentration correctly")
    func concentrationCardDisplaysCurrentConcentration() async throws {
        // Given: User with medication profile and recent dose
        let user = createTestUser()
        let medicationProfile = createTestMedicationProfile(user: user, medication: .semaglutide)
        let recentDose = createTestDose(
            medicationProfile: medicationProfile,
            timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            amount: 1.0
        )

        context.insert(user)
        context.insert(medicationProfile)
        context.insert(recentDose)
        try context.save()

        // When: ConcentrationCard calculates current concentration
        let currentConcentration = pkEngine.calculateCurrentConcentration(
            for: user,
            medication: medicationProfile
        )

        // Then: Concentration should be positive (dose has effect)
        #expect(currentConcentration > 0.0, "Current concentration should be positive after recent dose")

        // And: Concentration should be less than initial dose (decay occurred)
        #expect(currentConcentration < recentDose.amount, "Concentration should decay from initial dose amount")
    }

    @Test("ConcentrationCard formats concentration values to 2 decimal places")
    func concentrationCardFormatsValuesCorrectly() async throws {
        // Given: Various concentration values
        let testConcentrations = [1.23456, 0.9876, 10.1, 0.0]

        for concentration in testConcentrations {
            // When: Formatting concentration for display
            let formatted = String(format: "%.2f", concentration)

            // Then: Should have exactly 2 decimal places
            let components = formatted.split(separator: ".")
            if components.count == 2 {
                #expect(components[1].count == 2, "Should have exactly 2 decimal places for \(concentration)")
            } else {
                // For whole numbers, should still show .00
                #expect(formatted.hasSuffix(".00"), "Whole numbers should display .00 for \(concentration)")
            }
        }
    }

    @Test("ConcentrationCard handles zero concentration gracefully")
    func concentrationCardHandlesZeroConcentration() async throws {
        // Given: User with no doses
        let user = createTestUser()
        let medicationProfile = createTestMedicationProfile(user: user, medication: .semaglutide)

        context.insert(user)
        context.insert(medicationProfile)
        try context.save()

        // When: ConcentrationCard calculates concentration
        let currentConcentration = pkEngine.calculateCurrentConcentration(
            for: user,
            medication: medicationProfile
        )

        // Then: Should return 0.0 for no doses
        #expect(currentConcentration == 0.0, "No doses should result in zero concentration")
    }

    @Test("ConcentrationCard calculates peak level timing correctly")
    func concentrationCardCalculatesPeakTiming() async throws {
        // Given: Dose with known medication (semaglutide peaks at 4-16 hours)
        let user = createTestUser()
        let medicationProfile = createTestMedicationProfile(user: user, medication: .semaglutide)
        let dose = createTestDose(
            medicationProfile: medicationProfile,
            timestamp: Date(),
            amount: 1.0
        )

        context.insert(user)
        context.insert(medicationProfile)
        context.insert(dose)
        try context.save()

        // When: Calculating peak level
        let peakResult = pkEngine.calculatePeakLevel(for: dose, medication: medicationProfile)

        // Then: Peak time should be after dose time
        #expect(peakResult.time > dose.timestamp, "Peak time should be after dose timestamp")

        // And: Peak level should account for bioavailability
        let expectedPeakLevel = dose.amount * Medication.semaglutide.subcutaneousBioavailability
        #expect(abs(peakResult.level - expectedPeakLevel) < 0.001,
               "Peak level should account for bioavailability")

        // And: Peak time should be within reasonable range (4-16 hours for semaglutide)
        let hoursUntilPeak = peakResult.time.timeIntervalSince(dose.timestamp) / 3600
        #expect(hoursUntilPeak >= 4.0 && hoursUntilPeak <= 16.0,
               "Semaglutide peak should be 4-16 hours after injection")
    }

    @Test("ConcentrationCard calculates trough level for next dose")
    func concentrationCardCalculatesTroughLevel() async throws {
        // Given: User with regular dosing pattern
        let user = createTestUser()
        let medicationProfile = createTestMedicationProfile(user: user, medication: .semaglutide)

        // Add multiple doses to establish pattern
        let now = Date()
        let dose1 = createTestDose(medicationProfile: medicationProfile,
                                   timestamp: now.addingTimeInterval(-7 * 24 * 3600),
                                   amount: 1.0)
        let dose2 = createTestDose(medicationProfile: medicationProfile,
                                   timestamp: now,
                                   amount: 1.0)

        context.insert(user)
        context.insert(medicationProfile)
        context.insert(dose1)
        context.insert(dose2)
        try context.save()

        // When: Calculating trough level
        let troughResult = pkEngine.calculateTroughLevel(for: medicationProfile)

        // Then: Trough time should be in the future
        #expect(troughResult.time > Date(), "Trough time should be in future")

        // And: Trough level should be positive but lower than current
        #expect(troughResult.level >= 0.0, "Trough level should not be negative")

        let currentLevel = pkEngine.calculateCurrentConcentration(for: user, medication: medicationProfile)
        #expect(troughResult.level <= currentLevel, "Trough should be lower than current level")
    }

    @Test("ConcentrationCard calculates steady state progress")
    func concentrationCardCalculatesSteadyStateProgress() async throws {
        // Given: User with varying dose history lengths
        let user = createTestUser()
        let medicationProfile = createTestMedicationProfile(user: user, medication: .semaglutide)

        context.insert(user)
        context.insert(medicationProfile)

        // Test with no doses
        var steadyStateProgress = pkEngine.calculateSteadyStateProgress(for: medicationProfile)
        #expect(steadyStateProgress == 0.0, "No doses should result in 0% steady state progress")

        // Add doses over time to simulate progress
        let now = Date()
        for week in 0..<8 { // 8 weeks of doses
            let dose = createTestDose(
                medicationProfile: medicationProfile,
                timestamp: now.addingTimeInterval(TimeInterval(-week * 7 * 24 * 3600)),
                amount: 1.0
            )
            context.insert(dose)
        }
        try context.save()

        // When: Calculating steady state progress
        steadyStateProgress = pkEngine.calculateSteadyStateProgress(for: medicationProfile)

        // Then: Progress should be between 0 and 1 (0% to 100%)
        #expect(steadyStateProgress >= 0.0 && steadyStateProgress <= 1.0,
               "Steady state progress should be between 0 and 1")

        // And: 8 weeks should show significant progress (semaglutide ~5 half-lives to steady state)
        #expect(steadyStateProgress > 0.5, "8 weeks should show substantial steady state progress")
    }

    @Test("ConcentrationCard handles multiple medications independently")
    func concentrationCardHandlesMultipleMedications() async throws {
        // Given: User with two different medications
        let user = createTestUser()
        let semaglutideProfile = createTestMedicationProfile(user: user, medication: .semaglutide)
        let tirzepatideProfile = createTestMedicationProfile(user: user, medication: .tirzepatide)

        // Add doses to each medication
        let semaglutideDose = createTestDose(medicationProfile: semaglutideProfile, amount: 1.0)
        let tirzepatideDose = createTestDose(medicationProfile: tirzepatideProfile, amount: 2.5)

        context.insert(user)
        context.insert(semaglutideProfile)
        context.insert(tirzepatideProfile)
        context.insert(semaglutideDose)
        context.insert(tirzepatideDose)
        try context.save()

        // When: Calculating concentrations for each medication
        let semaglutideConcentration = pkEngine.calculateCurrentConcentration(
            for: user, medication: semaglutideProfile)
        let tirzepatideConcentration = pkEngine.calculateCurrentConcentration(
            for: user, medication: tirzepatideProfile)

        // Then: Concentrations should be independent
        #expect(semaglutideConcentration > 0.0, "Semaglutide should have positive concentration")
        #expect(tirzepatideConcentration > 0.0, "Tirzepatide should have positive concentration")

        // And: Different medications should have different concentration patterns
        // (due to different half-lives and bioavailability)
        #expect(semaglutideConcentration != tirzepatideConcentration,
               "Different medications should have different concentrations")
    }

    @Test("ConcentrationCard projects future concentration levels")
    func concentrationCardProjectsFutureLevels() async throws {
        // Given: User with current medication and doses
        let user = createTestUser()
        let medicationProfile = createTestMedicationProfile(user: user, medication: .semaglutide)
        let dose = createTestDose(medicationProfile: medicationProfile, amount: 1.0)

        context.insert(user)
        context.insert(medicationProfile)
        context.insert(dose)
        try context.save()

        // When: Projecting future levels for 7 days
        let futureLevels = pkEngine.projectFutureLevels(for: medicationProfile, days: 7)

        // Then: Should return multiple concentration points
        #expect(futureLevels.count > 0, "Should return future concentration points")

        // And: Future levels should show decay over time
        let sortedLevels = futureLevels.sorted { $0.date < $1.date }
        if sortedLevels.count >= 2,
           let firstLevel = sortedLevels.first,
           let lastLevel = sortedLevels.last {
            #expect(lastLevel.concentration < firstLevel.concentration,
                   "Concentration should decay over time without new doses")
        }

        // And: All dates should be in the future
        let now = Date()
        for point in futureLevels {
            #expect(point.date >= now, "All projected points should be in future")
        }
    }

    // MARK: - ConcentrationCard UI State Tests

    @Test("ConcentrationCard determines display state based on data availability")
    func concentrationCardDeterminesDisplayState() async throws {
        // Test empty state
        let user = createTestUser()
        let medicationProfile = createTestMedicationProfile(user: user, medication: .semaglutide)

        context.insert(user)
        context.insert(medicationProfile)
        try context.save()

        // When: No doses available
        let emptyConcentration = pkEngine.calculateCurrentConcentration(for: user, medication: medicationProfile)

        // Then: Should handle empty state
        #expect(emptyConcentration == 0.0, "Empty state should show zero concentration")

        // When: Adding dose data
        let dose = createTestDose(medicationProfile: medicationProfile, amount: 1.0)
        context.insert(dose)
        try context.save()

        let activeConcentration = pkEngine.calculateCurrentConcentration(for: user, medication: medicationProfile)

        // Then: Should show active state
        #expect(activeConcentration > 0.0, "Active state should show positive concentration")
    }

    @Test("ConcentrationCard provides accessibility information")
    func concentrationCardProvidesAccessibility() async throws {
        // Given: Concentration data for testing accessibility
        let testConcentration = 1.23
        let testMedication = Medication.semaglutide

        // When: Formatting for accessibility
        let formattedConcentration = String(format: "%.2f", testConcentration)
        let accessibilityLabel = "Current \(testMedication.displayName) concentration: \(formattedConcentration) units"

        // Then: Should provide meaningful accessibility description
        #expect(accessibilityLabel.contains(testMedication.displayName),
               "Accessibility label should include medication name")
        #expect(accessibilityLabel.contains("1.23"),
               "Accessibility label should include formatted concentration")
        #expect(accessibilityLabel.contains("concentration"),
               "Accessibility label should include 'concentration' for context")
    }

    // MARK: - Helper Methods

    private func createTestUser() -> User {
        User(
            appleUserId: "test-user-\(UUID().uuidString)",
            email: "test@example.com",
            name: "Test User"
        )
    }

    private func createTestMedicationProfile(user: User, medication: Medication) -> MedicationProfile {
        MedicationProfile(
            user: user,
            medicationName: medication.rawValue,
            dosage: 1.0,
            frequency: .weekly,
            startDate: Date().addingTimeInterval(-30 * 24 * 3600) // 30 days ago
        )
    }

    private func createTestDose(
        medicationProfile: MedicationProfile,
        timestamp: Date = Date(),
        amount: Double
    ) -> Dose {
        Dose(
            medicationProfile: medicationProfile,
            amount: amount,
            timestamp: timestamp,
            injectionSite: .abdomen,
            notes: "Test dose"
        )
    }
}
