//
//  MedicationAnalyticsTests.swift
//  JabTrackerTests
//
//  Tests for medication analytics enhancements, including effectiveness tracking,
//  concentration calculations, and pharmacokinetic properties.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("Medication Analytics Tests")
struct MedicationAnalyticsTests {
    // MARK: - Medication Analytics Properties Tests

    @Test("Medication should provide therapeutic window properties")
    func medicationTherapeuticWindow() async throws {
        for medication in Medication.allCases {
            // Test that all medications have valid therapeutic ranges
            #expect(
                medication.therapeuticMinConcentration > 0,
                "Medication \(medication.displayName) should have positive minimum therapeutic concentration"
            )
            #expect(
                medication.therapeuticMaxConcentration > medication.therapeuticMinConcentration,
                "Medication \(medication.displayName) should have max concentration greater than min")
            #expect(
                medication.therapeuticWindow.lowerBound >= 0,
                "Medication \(medication.displayName) should have non-negative therapeutic window lower bound"
            )
            #expect(
                medication.therapeuticWindow.upperBound > medication.therapeuticWindow.lowerBound,
                "Medication \(medication.displayName) should have valid therapeutic window range")
        }
    }

    @Test("Medication should provide effectiveness metrics")
    func medicationEffectivenessMetrics() async throws {
        for medication in Medication.allCases {
            // Test effectiveness calculation properties
            #expect(
                medication.effectivenessFactors.count > 0,
                "Medication \(medication.displayName) should have effectiveness factors")
            #expect(
                medication.baseEffectivenessScore >= 0.0 && medication.baseEffectivenessScore <= 1.0,
                "Medication \(medication.displayName) should have effectiveness score between 0.0 and 1.0")

            // Test that effectiveness can be calculated for a given concentration
            let testConcentration =
                medication.therapeuticMinConcentration
                + (medication.therapeuticMaxConcentration - medication.therapeuticMinConcentration) / 2
            let effectiveness = medication.calculateEffectiveness(concentration: testConcentration)
            #expect(
                effectiveness >= 0.0 && effectiveness <= 1.0,
                "Calculated effectiveness should be between 0.0 and 1.0")
        }
    }

    @Test("Medication should provide onset and duration properties")
    func medicationOnsetAndDuration() async throws {
        for medication in Medication.allCases {
            // Test onset time properties
            #expect(
                medication.onsetTimeHours > 0,
                "Medication \(medication.displayName) should have positive onset time")
            #expect(
                medication.onsetTimeHours < 72,  // 3 days max seems reasonable
                "Medication \(medication.displayName) should have reasonable onset time")

            // Test duration properties
            #expect(
                medication.effectiveDurationHours > 0,
                "Medication \(medication.displayName) should have positive effective duration")
            #expect(
                medication.effectiveDurationHours > medication.onsetTimeHours,
                "Medication \(medication.displayName) duration should be longer than onset time")
        }
    }

    // MARK: - MedicationProfile Analytics Tests

    @Test("MedicationProfile should calculate adherence metrics")
    @MainActor
    func medicationProfileAdherenceCalculation() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: User.self, MedicationProfile.self, Dose.self, configurations: config)
        let context = container.mainContext

        // Create test data
        let user = User(email: "test@example.com", name: "Test User", appleUserId: "test-user")
        context.insert(user)

        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            medicationType: "semaglutide")
        profile.user = user
        context.insert(profile)

        // Add test doses
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        for index in 0..<10 {
            let doseDate = Calendar.current.date(byAdding: .day, value: index * 7, to: startDate)!
            let dose = Dose(amount: 1.0, timestamp: doseDate)
            dose.user = user
            dose.medication = profile
            context.insert(dose)
        }

        try context.save()

        // Test adherence calculation
        let endDate = Date()
        let adherence = profile.calculateAdherence(
            from: startDate,
            to: endDate,
            context: context)

        #expect(
            adherence >= 0.0 && adherence <= 1.0,
            "Adherence should be between 0.0 and 1.0")
    }

    @Test("MedicationProfile should calculate effectiveness score")
    @MainActor
    func medicationProfileEffectivenessScore() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: User.self, MedicationProfile.self, Dose.self, configurations: config)
        let context = container.mainContext

        // Create test profile
        let user = User(email: "test@example.com", name: "Test User", appleUserId: "test-user")
        context.insert(user)

        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            medicationType: "semaglutide")
        profile.user = user
        context.insert(profile)

        try context.save()

        // Test effectiveness calculation with adherence factor
        let testAdherence = 0.85
        let effectiveness = profile.calculateEffectivenessScore(
            adherence: testAdherence,
            timeOnMedicationDays: 30)

        #expect(
            effectiveness >= 0.0 && effectiveness <= 1.0,
            "Effectiveness score should be between 0.0 and 1.0")
    }

    @Test("MedicationProfile should provide time-based effectiveness insights")
    @MainActor
    func medicationProfileTimeBasedEffectiveness() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: User.self, MedicationProfile.self, Dose.self, configurations: config)
        let context = container.mainContext

        // Create test profile
        let user = User(email: "test@example.com", name: "Test User", appleUserId: "test-user")
        context.insert(user)

        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            medicationType: "semaglutide")
        profile.user = user
        context.insert(profile)

        try context.save()

        // Test time-based effectiveness properties
        let timeBased = profile.timeBasedEffectivenessInsights
        #expect(timeBased.count > 0, "Should provide time-based effectiveness insights")

        // Test that insights are properly formatted
        for insight in timeBased {
            #expect(!insight.period.isEmpty, "Each insight should have a time period")
            #expect(
                insight.effectivenessChange != nil || insight.note != nil,
                "Each insight should provide either effectiveness change or note")
        }
    }

    @Test("MedicationProfile timeBasedEffectivenessInsights with nil medication")
    @MainActor
    func medicationProfileTimeBasedEffectivenessInsightsWithNilMedication() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: User.self, MedicationProfile.self, Dose.self, configurations: config)
        let context = container.mainContext

        // Create test profile
        let user = User(email: "test@example.com", name: "Test User", appleUserId: "test-user")
        context.insert(user)

        let profile = MedicationProfile(
            genericName: "unknown",
            brandName: "Unknown Brand",
            currentDose: 1.0,
            startDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
            medicationType: "unknown")
        profile.user = user
        // Do NOT set medication - this will be nil
        context.insert(profile)

        try context.save()

        // Test time-based effectiveness properties with nil medication
        let timeBased = profile.timeBasedEffectivenessInsights
        #expect(timeBased.count == 1, "Should provide one insight when medication is nil")

        let insight = timeBased.first!
        #expect(insight.period == "Unknown", "Period should be 'Unknown' when medication is nil")
        #expect(
            insight.effectivenessChange == nil,
            "Effectiveness change should be nil when medication is nil")
        #expect(
            insight.note == "Medication type not set", "Note should indicate medication type not set")
    }

    // MARK: - Concentration Timeline Tests

    @Test("MedicationProfile should generate concentration timeline")
    @MainActor
    func medicationProfileConcentrationTimeline() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: User.self, MedicationProfile.self, Dose.self, configurations: config)
        let context = container.mainContext

        // Create test data
        let user = User(email: "test@example.com", name: "Test User", appleUserId: "test-user")
        context.insert(user)

        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            medicationType: "semaglutide")
        profile.user = user
        context.insert(profile)

        // Add test doses
        let baseDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let dose1 = Dose(amount: 1.0, timestamp: baseDate)
        dose1.user = user
        dose1.medication = profile
        context.insert(dose1)

        let dose2 = Dose(
            amount: 1.0, timestamp: Calendar.current.date(byAdding: .day, value: 7, to: baseDate)!)
        dose2.user = user
        dose2.medication = profile
        context.insert(dose2)

        try context.save()

        // Test concentration timeline generation
        let timeline = profile.generateConcentrationTimeline(
            from: baseDate,
            to: Date(),
            context: context)

        #expect(timeline.count > 0, "Should generate concentration timeline points")

        // Verify timeline is sorted by date
        let sortedTimeline = timeline.sorted { $0.date < $1.date }
        #expect(timeline == sortedTimeline, "Timeline should be sorted by date")

        // Verify concentrations are reasonable
        for point in timeline {
            #expect(point.concentration >= 0, "Concentration should not be negative")
        }
    }

    // MARK: - Integration Tests

    @Test("Medication analytics should integrate with existing pharmacokinetics")
    func analyticsPharmacokineticIntegration() async throws {
        // Test that new analytics properties work with existing pharmacokinetic calculations
        let medication = Medication.semaglutide

        // Test that therapeutic window aligns with pharmacokinetic properties
        let therapeuticWindow = medication.therapeuticWindow

        // Verify that therapeutic window makes sense relative to half-life
        #expect(
            therapeuticWindow.lowerBound > 0,
            "Therapeutic window should have positive lower bound")

        // Test effectiveness calculation with pharmacokinetic data
        let testConcentration = medication.therapeuticMinConcentration
        let effectiveness = medication.calculateEffectiveness(concentration: testConcentration)

        // At minimum therapeutic concentration, effectiveness should be reasonable
        #expect(effectiveness > 0.3, "Effectiveness at therapeutic minimum should be meaningful")
        #expect(effectiveness <= 1.0, "Effectiveness should not exceed maximum")
    }
}

// MARK: - Test Data Structures

/// Test structure for time-based effectiveness insights
struct EffectivenessInsight {
    let period: String
    let effectivenessChange: Double?
    let note: String?
}
