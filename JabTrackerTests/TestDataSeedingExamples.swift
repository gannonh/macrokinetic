//
//  TestDataSeedingExamples.swift
//  JabTrackerTests
//
//  Example tests demonstrating TestDataSeeding utility usage

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Example tests showing how to use TestDataSeeding for different scenarios
@Suite("TestDataSeeding Examples")
struct TestDataSeedingExamples {

    // MARK: - Small Dataset Examples

    @Test("Generate small dataset (7 days) for quick tests")
    @MainActor
    func generateSmallDataset() throws {
        // Create test container
        let container = try TestDataSeeding.createTestContainer()
        let context = container.mainContext

        // Seed small dataset
        let result = try TestDataSeeding.seedData(
            into: context,
            config: .small
        )

        // Verify results
        #expect(result.doses.count > 0, "Should create at least one dose")
        #expect(result.user.email == "test@example.com")
        #expect(result.medicationProfile.genericName == "semaglutide")
        #expect(result.adherenceRate == 1.0, "Small dataset has 100% adherence")

        print("✅ Small dataset: \(result.doses.count) doses over 7 days")
    }

    @Test("Generate medium dataset (30 days) for standard tests")
    @MainActor
    func generateMediumDataset() throws {
        let container = try TestDataSeeding.createTestContainer()
        let context = container.mainContext

        // Seed medium dataset
        let result = try TestDataSeeding.seedData(
            into: context,
            config: .medium
        )

        // Verify realistic adherence (note: with only ~4-5 doses, randomness can yield high adherence)
        #expect(result.adherenceRate >= 0.80, "Should have 80%+ adherence")
        #expect(result.adherenceRate <= 1.0, "Adherence cannot exceed 100%")

        // Note: With only 4-5 doses and 95% adherence rate, we may not get skipped doses every time

        print(
            """
            ✅ Medium dataset:
               - Total doses: \(result.expectedDoseCount)
               - Taken: \(result.actualDoseCount)
               - Skipped: \(result.skippedDoses.count)
               - Adherence: \(String(format: "%.1f%%", result.adherenceRate * 100))
            """)
    }

    // MARK: - Large Dataset Examples (Performance Testing)

    @Test("Generate large dataset (365 days) for performance tests")
    @MainActor
    func generateLargeDataset() throws {
        let container = try TestDataSeeding.createTestContainer()
        let context = container.mainContext

        // Measure seeding performance
        let startTime = Date()

        let result = try TestDataSeeding.seedData(
            into: context,
            config: .large
        )

        let seedingTime = Date().timeIntervalSince(startTime)

        // Verify large dataset (365 days weekly = ~52 scheduled, with 92% adherence = ~48 actual)
        #expect(result.doses.count >= 45, "Should have at least 45 doses for 365 days")
        #expect(seedingTime < 5.0, "Seeding should complete in under 5 seconds")

        print(
            """
            ✅ Large dataset (1 year):
               - Doses created: \(result.actualDoseCount)
               - Seeding time: \(String(format: "%.3f", seedingTime))s
               - Adherence: \(String(format: "%.1f%%", result.adherenceRate * 100))
            """)
    }

    @Test("Generate extra large dataset (2 years) for stress tests")
    @MainActor
    func generateExtraLargeDataset() throws {
        let container = try TestDataSeeding.createTestContainer()
        let context = container.mainContext

        // Measure seeding performance
        let startTime = Date()

        let result = try TestDataSeeding.seedData(
            into: context,
            config: .extraLarge
        )

        let seedingTime = Date().timeIntervalSince(startTime)

        // Verify extra large dataset (730 days weekly = ~104 scheduled, with 90% adherence = ~94 actual)
        #expect(result.doses.count >= 85, "Should have at least 85 doses for 2 years")
        #expect(seedingTime < 10.0, "Seeding should complete in under 10 seconds")

        print(
            """
            ✅ Extra large dataset (2 years):
               - Doses created: \(result.actualDoseCount)
               - Seeding time: \(String(format: "%.3f", seedingTime))s
               - Medication: \(result.medicationProfile.genericName)
            """)
    }

    // MARK: - Custom Configuration Examples

    @Test("Custom configuration for specific test scenario")
    @MainActor
    func customConfiguration() throws {
        let container = try TestDataSeeding.createTestContainer()
        let context = container.mainContext

        // Create custom config for tirzepatide with perfect adherence
        let customConfig = TestDataSeedingConfig(
            daysOfHistory: 90,
            medication: .tirzepatide,
            brandName: "Mounjaro",
            doseAmount: 5.0,
            injectionSites: ["Abdomen", "Thigh"],
            adherenceRate: 1.0,
            addTimingVariability: false,
            includeSkippedDoses: false
        )

        let result = try TestDataSeeding.seedData(
            into: context,
            config: customConfig
        )

        // Verify custom configuration
        #expect(result.medicationProfile.genericName == "tirzepatide")
        #expect(result.medicationProfile.brandName == "Mounjaro")
        #expect(result.doses.first?.amount == 5.0)
        #expect(result.adherenceRate == 1.0, "Perfect adherence")
        #expect(result.skippedDoses.isEmpty, "No skipped doses")

        print(
            """
            ✅ Custom configuration:
               - Medication: \(result.medicationProfile.brandName)
               - Dose amount: \(result.doses.first?.amount ?? 0) mg
               - Perfect adherence over 90 days
            """)
    }

    // MARK: - Quick Helper Examples

    @Test("Use quick helpers for simple test data")
    @MainActor
    func quickHelpers() throws {
        let container = try TestDataSeeding.createTestContainer()
        let context = container.mainContext

        // Create user and profile using quick helpers
        let user = TestDataSeeding.createTestUser()
        let profile = TestDataSeeding.createTestMedicationProfile()

        context.insert(user)
        context.insert(profile)

        // Create doses using quick helper
        let doses = TestDataSeeding.createTestDoses(
            count: 10,
            amount: 0.5,
            daysApart: 7,
            profile: profile
        )

        // Insert and save
        for dose in doses {
            context.insert(dose)
        }
        try context.save()

        // Verify
        #expect(doses.count == 10)
        #expect(doses.first?.amount == 0.5)

        print("✅ Quick helpers: Created user, profile, and \(doses.count) doses")
    }

    // MARK: - Dose Schedule Generation Examples

    @Test("Generate weekly dose schedule for semaglutide")
    func weeklySchedule() {
        let schedule = TestDataSeeding.generateDoseSchedule(
            for: .semaglutide,
            daysOfHistory: 30
        )

        // Semaglutide is weekly, so 30 days should have ~4-5 doses
        #expect(schedule.count >= 4 && schedule.count <= 5, "Should have 4-5 weekly doses in 30 days")

        print("✅ Weekly schedule: \(schedule.count) doses over 30 days")
    }

    @Test("Generate daily dose schedule for liraglutide")
    func dailySchedule() {
        let schedule = TestDataSeeding.generateDoseSchedule(
            for: .liraglutide,
            daysOfHistory: 14
        )

        // Liraglutide is daily, so 14 days should have ~14 doses
        #expect(schedule.count >= 13 && schedule.count <= 15, "Should have ~14 daily doses in 14 days")

        print("✅ Daily schedule: \(schedule.count) doses over 14 days")
    }
}
