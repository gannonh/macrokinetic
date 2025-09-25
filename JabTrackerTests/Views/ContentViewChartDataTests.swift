//
//  ContentViewChartDataTests.swift
//  JabTrackerTests
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Tests for ChartDatasetService functionality
/// Covers multiple profile handling, safe error handling, and time range logic
@Suite("ChartDataset Service Tests")
@MainActor
struct ContentViewChartDataTests {

    // MARK: - Test Setup

    /// Create test container with in-memory storage
    private func createTestContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            return try ModelContainer(
                for: User.self, Dose.self, MedicationProfile.self, configurations: config)
        } catch {
            Issue.record("Failed to create test container: \(error)")
            fatalError("Test container creation failed")
        }
    }

    /// Create test user for testing
    private func createTestUser(in container: ModelContainer) -> User {
        let context = container.mainContext

        let user = User(
            email: "test@contentview.com",
            name: "ContentView Test User",
            appleUserId: "test-user-contentview"
        )
        context.insert(user)

        try! context.save()
        return user
    }

    /// Create test medication profile
    private func createTestProfile(
        genericName: String = "semaglutide",
        brandName: String = "Ozempic",
        dose: Double = 1.0,
        user: User,
        container: ModelContainer
    ) -> MedicationProfile {
        let context = container.mainContext

        let profile = MedicationProfile(
            genericName: genericName,
            brandName: brandName,
            currentDose: dose,
            startDate: Date().addingTimeInterval(-30 * 24 * 3600),
            medicationType: genericName
        )
        profile.user = user
        context.insert(profile)

        try! context.save()
        return profile
    }

    /// Create test dose
    private func createTestDose(
        amount: Double,
        timestamp: Date,
        profile: MedicationProfile,
        container: ModelContainer,
        skipped: Bool = false
    ) -> Dose {
        let context = container.mainContext

        let dose = Dose(
            amount: amount,
            timestamp: timestamp,
            site: "arm"
        )
        dose.skipped = skipped
        dose.medication = profile
        dose.user = profile.user
        context.insert(dose)

        try! context.save()
        return dose
    }

    // MARK: - Tests

    @Test("generateChartDataset returns nil for empty profiles")
    func testGenerateChartDatasetEmptyProfiles() {
        let container = createTestContainer()
        let user = createTestUser(in: container)
        let chartDatasetService = ChartDatasetService()

        let result = chartDatasetService.generateChartDataset(for: user, profiles: [])

        #expect(result == nil)
    }

    @Test("generateChartDataset returns nil for profiles without doses")
    func testGenerateChartDatasetProfilesWithoutDoses() {
        let container = createTestContainer()
        let user = createTestUser(in: container)
        let profile = createTestProfile(user: user, container: container)
        let chartDatasetService = ChartDatasetService()

        let result = chartDatasetService.generateChartDataset(for: user, profiles: [profile])

        #expect(result == nil)
    }

    @Test("generateChartDataset handles single profile with doses")
    func testGenerateChartDatasetSingleProfile() {
        let container = createTestContainer()
        let user = createTestUser(in: container)
        let profile = createTestProfile(user: user, container: container)

        // Add some test doses
        let now = Date()
        _ = createTestDose(
            amount: 1.0, timestamp: now.addingTimeInterval(-7 * 24 * 3600), profile: profile, container: container)
        _ = createTestDose(
            amount: 1.0, timestamp: now.addingTimeInterval(-3 * 24 * 3600), profile: profile, container: container)

        let chartDatasetService = ChartDatasetService()
        let result = chartDatasetService.generateChartDataset(for: user, profiles: [profile])

        #expect(result != nil)
        #expect(result?.concentrationCurves.count == 1)
        #expect(result?.doseMarkers.count == 2)
        #expect(result?.concentrationCurves.first?.medication == "semaglutide")
    }

    @Test("generateChartDataset handles multiple profiles")
    func testGenerateChartDatasetMultipleProfiles() {
        let container = createTestContainer()
        let user = createTestUser(in: container)

        let profile1 = createTestProfile(
            genericName: "semaglutide", brandName: "Ozempic", user: user, container: container)
        let profile2 = createTestProfile(
            genericName: "tirzepatide", brandName: "Mounjaro", user: user, container: container)

        // Add doses to both profiles
        let now = Date()
        _ = createTestDose(
            amount: 1.0, timestamp: now.addingTimeInterval(-7 * 24 * 3600), profile: profile1, container: container)
        _ = createTestDose(
            amount: 2.5, timestamp: now.addingTimeInterval(-5 * 24 * 3600), profile: profile2, container: container)

        let chartDatasetService = ChartDatasetService()
        let result = chartDatasetService.generateChartDataset(for: user, profiles: [profile1, profile2])

        #expect(result != nil)
        #expect(result?.concentrationCurves.count == 2)
        #expect(result?.doseMarkers.count == 2)

        let medications = result?.concentrationCurves.map { $0.medication }.sorted()
        #expect(medications == ["semaglutide", "tirzepatide"])
    }

    @Test("generateChartDataset filters invalid dose amounts")
    func testGenerateChartDatasetFiltersInvalidDoses() {
        let container = createTestContainer()
        let user = createTestUser(in: container)
        let profile = createTestProfile(user: user, container: container)

        let now = Date()
        // Add valid and invalid doses
        _ = createTestDose(
            amount: 1.0, timestamp: now.addingTimeInterval(-7 * 24 * 3600), profile: profile, container: container)

        // Create a dose with invalid amount manually
        let context = container.mainContext
        let invalidDose = Dose(amount: -1.0, timestamp: now.addingTimeInterval(-3 * 24 * 3600), site: "arm")
        invalidDose.medication = profile
        invalidDose.user = user
        context.insert(invalidDose)
        try! context.save()

        let chartDatasetService = ChartDatasetService()
        let result = chartDatasetService.generateChartDataset(for: user, profiles: [profile])

        #expect(result != nil)
        // Should only include the valid dose marker
        #expect(result?.doseMarkers.count == 1)
        #expect(result?.doseMarkers.first?.amount == 1.0)
    }

    @Test("generateChartDataset handles mixed valid and invalid profiles")
    func testGenerateChartDatasetMixedProfiles() {
        let container = createTestContainer()
        let user = createTestUser(in: container)

        let validProfile = createTestProfile(genericName: "semaglutide", user: user, container: container)
        let emptyProfile = createTestProfile(genericName: "tirzepatide", user: user, container: container)

        // Only add dose to the first profile
        let now = Date()
        _ = createTestDose(
            amount: 1.0, timestamp: now.addingTimeInterval(-7 * 24 * 3600), profile: validProfile, container: container)

        let chartDatasetService = ChartDatasetService()
        let result = chartDatasetService.generateChartDataset(for: user, profiles: [validProfile, emptyProfile])

        #expect(result != nil)
        // Should only include data from the valid profile
        #expect(result?.concentrationCurves.count == 1)
        #expect(result?.concentrationCurves.first?.medication == "semaglutide")
        #expect(result?.doseMarkers.count == 1)
    }

    @Test("generateChartDataset creates proper time range")
    func testGenerateChartDatasetTimeRange() {
        let container = createTestContainer()
        let user = createTestUser(in: container)
        let profile = createTestProfile(user: user, container: container)

        // Create doses with specific timestamps
        let now = Date()
        let oldestDose = now.addingTimeInterval(-14 * 24 * 3600)  // 14 days ago
        let newestDose = now.addingTimeInterval(-1 * 24 * 3600)  // 1 day ago

        _ = createTestDose(amount: 1.0, timestamp: oldestDose, profile: profile, container: container)
        _ = createTestDose(amount: 1.0, timestamp: newestDose, profile: profile, container: container)

        let chartDatasetService = ChartDatasetService()
        let result = chartDatasetService.generateChartDataset(for: user, profiles: [profile])

        #expect(result != nil)
        #expect(result?.concentrationCurves.count == 1)
        #expect(result?.doseMarkers.count == 2)

        // Verify the concentration curve includes points spanning the expected range
        let points = result?.concentrationCurves.first?.points
        #expect(points?.isEmpty == false)

        // The curve should include points from the earliest dose to at least now
        let earliestPoint = points?.min { $0.date < $1.date }?.date
        let latestPoint = points?.max { $0.date < $1.date }?.date

        #expect(earliestPoint != nil)
        #expect(latestPoint != nil)
    }

    @Test("generateChartDataset returns nil when all data is invalid")
    func testGenerateChartDatasetAllInvalidData() {
        let container = createTestContainer()
        let user = createTestUser(in: container)
        let profile = createTestProfile(user: user, container: container)

        let now = Date()
        let context = container.mainContext

        // Create doses with invalid amounts (negative and infinite)
        let invalidDose1 = Dose(amount: -1.0, timestamp: now.addingTimeInterval(-7 * 24 * 3600), site: "arm")
        invalidDose1.medication = profile
        invalidDose1.user = user
        context.insert(invalidDose1)

        let invalidDose2 = Dose(amount: Double.infinity, timestamp: now.addingTimeInterval(-3 * 24 * 3600), site: "arm")
        invalidDose2.medication = profile
        invalidDose2.user = user
        context.insert(invalidDose2)

        try! context.save()

        let chartDatasetService = ChartDatasetService()
        let result = chartDatasetService.generateChartDataset(for: user, profiles: [profile])

        // Should return nil when no valid data remains
        #expect(result == nil)
    }
}
